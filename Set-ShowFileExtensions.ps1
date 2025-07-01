function Load-UserHives {
  [CmdletBinding()]
  param(
    [System.Security.Principal.SecurityIdentifier[]]$Users
  )

  # collect profile information from HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList
  # We're after the ProfileImagePath property of each child, which are named by the SID of the profile
  $ProfileList = Get-ChildItem -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList'

  # load user hives for each user profile we've found
  foreach ($User in $Users) {

    # find our user's profile in the ProfileList
    try {
      $UserProfileKey = ($ProfileList | Where-Object PSChildName -eq $User).PSPath
    }
    catch {
      Write-Warning "Load-UserHives: Could not find user profile for SID $($User). Skipping."
      continue
    }

    # get the ProfileImagePath property to find the path to the user's NTUSER.DAT file
    $ProfileImagePath = Get-ItemPropertyValue -Path $UserProfileKey -Name ProfileImagePath

    Write-Host "Load-UserHives: Loading user hive for SID $($User) with profile $($ProfileImagePath)\NTUSER.DAT."

    $Load = (& reg.exe LOAD "HKU\$($User)" "$($ProfileImagePath)\NTUSER.DAT")

    if ($Load -ne 'The operation completed successfully.') {
      Write-Error "Load-UserHives: Failed to load user hive for SID $($User)."
      Write-Error "Load-UserHives: REG.exe error: $($Load)"
      continue
    }

    Write-Host "Load-UserHives: Loaded user hive for SID $($User)."
    Write-Host "Load-UserHives: REG.exe output: $($Load)"

  }

}

function Unload-UserHives {
  [CmdletBinding()]
  param(
    [System.Security.Principal.SecurityIdentifier[]]$Users
  )

  if ($Users.Count -eq 0) {
    Write-Host "Unload-UserHives: No users provided to unload."
    return
  }

  # run the garbage collector to release handles before unloading hives
  [System.GC]::Collect()

  Write-Host "Unload-UserHives: Getting users with active processes so we do not attempt to unload an active user."
  # so we do not attempt to unload an active user, get users who have processes running
  $LoggedOnUsers = Get-Process -IncludeUserName |
  Where-Object { $_.UserName } |
  Select-Object -ExpandProperty UserName -Unique
  
  Write-Host "Unload-UserHives: Mapping $($LoggedOnUsers.Count) active users to SIDs."

  # get SIDs from the users
  $LoggedOnSIDs = foreach ($User in $LoggedOnUsers) {
    try {
      $NTAccount = New-Object System.Security.Principal.NTAccount($User)
      $SID = $NTAccount.Translate([System.Security.Principal.SecurityIdentifier])
      $SID.Value
    }
    catch {
      Write-Warning "Unload-UserHives: Could not resolve SID for user $User"
    }
  }

  Write-Host "Unload-UserHives: Found $($LoggedOnUsers.Count) users with active processes: `n $($LoggedOnUsers -join "`n ")"

  # filter out anything but revision 5 or 12 SIDs with subauthority #1 values of 21

  foreach ($User in $Users) {

    if ($User -in $LoggedOnSIDs) {
      Write-Host "Unload-UserHives: Will not attempt to unload hive for SID $($User) as the user has active processes."
      continue
    }

    Write-Host "Unload-UserHives: Unloading user hive for SID $($User)."

    $Unload = (& reg.exe UNLOAD "HKU\$($User)")

    if ($Unload -ne 'The operation completed successfully.') {
      Write-Error "Unload-UserHives: Failed to unload user hive for SID $($User). REG.exe error: '$($Unload)'"
    }
    else {
      Write-Host "Unload-UserHives: Unloaded user hive for SID $($User). REG.exe output: '$($Unload)'"
    }

  }

}

function Set-RegistryKey {
  [CmdletBinding()]
  param(
    [string]$RootPath = 'HKCU:\',
    [string]$Path = 'Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced',
    [string]$Name = 'HideFileExt',
    $Value = 0,
    [string]$Type = 'DWORD'
  )

  # example: set ShowFileExtensions in File Explorer
  $Path = Join-Path -Path $RootPath -ChildPath $Path

  Write-Verbose "Set-RegistryKey: Setting registry key $($Path) $($Name) to value $($Value) of type $($Type)."

  try {
    New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $Type -Force | Out-Null
    Write-Verbose "Set-RegistryKey: Successfully set registry key $($Path) $($Name) to value $($Value) of type $($Type)."
  }
  catch {
    Write-Error "Set-RegistryKey: Failed to set registry key $($Path) $($Name). Error: $_"
    throw $_
  }

}

function Set-HKUKeyInner {
  param (
    [switch]$SetDefault
  )
  # map HKU as a PSDrive to enable us to access all user profiles
  New-PSDrive -Name 'HKU' -PSProvider Registry -Root HKEY_USERS | Out-Null

  Write-Host "Set-HKUKey: Setting registry key for all user profiles, $(if ($SetDefault) { 'including the default profile'} else { 'excluding the default profile' })."

  Write-Verbose "Set-HKUKey: Getting SIDs of all user profiles."

  # get the SIDs of all AAD, domain, or local users on the device
  # Select UserProfile SIDs with 1-5 (AD or local) or 12 (AAD)
  $Users = (
    Get-CimInstance -ClassName 'Win32_UserProfile' |
    Where-Object SID -match '^S-1-(5|12)-\d{1,2}-\d+-\d+-\d+-.*'
  ).SID

  # translate SIDs to friendly names for logging
  $FriendlyUsers = (
    $Users |
    ForEach-Object {
      $SID = [System.Security.Principal.SecurityIdentifier]$_
      try {
        $SID.Translate([System.Security.Principal.NTAccount]).Value
      }
      catch {
        $SID.Value
      }
    }
  )
  
  # debug verbose output showing affected user profiles
  Write-Host "Set-HKUKey: Found the following user profiles: `n $($FriendlyUsers -join "`n ")"

  Write-Host "Set-HKUKey: Loading user hives for found user profiles."

  Load-UserHives -Users $Users

  Write-Host "Set-HKUKey: Finding HKU:\ paths for loaded users."

  $Profiles = (
    Get-ChildItem -Path 'HKU:\' |
    Where-Object {
      $_.PSChildName -in $Users
    }
  )

  Write-Host ("Set-HKUKey: Found user profiles:`n{0}" -f ($Profiles.PSChildName -join "`n "))
  
  Write-Host "Set-HKUKey: Setting registry key for $($Profiles.Count) user profiles."

  foreach ($User in $Profiles) {

    Write-Host "Set-HKUKeyInner: Setting registry key at path HKU:\$($User)\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced HideFileExt to DWORD 0."

    Set-RegistryKey -RootPath "HKU:\$($User)\" -Path 'Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'HideFileExt' -Value 0 -Type 'DWORD'

  }

}

<#
.SYNOPSIS
  Sets a registry key in the HKCU hive for all user profiles on the device.
.EXAMPLE
  Set-HKUKey -AllUsers
#>
Function Set-HKUKey {
  [CmdletBinding()]
  param(
    [switch]$AllUsers,
    [switch]$SetDefault,
    [string]$RootPath = 'HKCU:\'
  )

  # load all users' hives, set key for each user profile
  if ($AllUsers) {

    Write-Verbose "Set-HKUKey: Starting a new PowerShell process to set registry keys for all user profiles."

    try {

      $Users = (
        Get-CimInstance -ClassName 'Win32_UserProfile' |
        Where-Object SID -match '^S-1-(5|12)-\d{1,2}-\d+-\d+-\d+-.*'
      ).SID

      # Extract only the required functions using regex
      $FunctionNames = @(
        'Load-UserHives',
        'Set-RegistryKey',
        'Set-HKUKeyInner'
      )
      $FunctionBlocks = foreach ($Name in $FunctionNames) {
        $Function = Get-Command $Name -CommandType Function
        if ($Function) { # rebuild the function
          "function $($Function.Name) {$($Function.Definition)}`n"
        }
      }

      # build the scriptblock we'll encode and pass to a subprocess
      $SubprocessScript = @"
$($FunctionBlocks -join "`n`n")

Set-HKUKeyInner -SetDefault:`$$($SetDefault) -Verbose:`$$($null -ne $VerbosePreference)
"@

      # encode the scriptblock so it doesn't get screwed
      $Encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($SubprocessScript))

      powershell.exe -NoProfile -EncodedCommand $Encoded

    }
    finally {

      Write-Verbose "Set-HKUKey: Cleaning up loaded user hives."

      Write-Verbose "Set-HKUKey: Removing HKU PSDrive."

      # remove the variable to close any open handles
      Remove-PSDrive -Name 'HKU' -Force -ErrorAction SilentlyContinue

      Write-Verbose "Set-HKUKey: Clearing Profiles variable."

      $Profiles = $null

      Write-Verbose "Set-HKUKey: Running garbage collector to release handles."

      [System.GC]::Collect()
      [System.GC]::WaitForPendingFinalizers()

      Write-Verbose "Set-HKUKey: Unloading user hives."

      Unload-UserHives -Users $Users

    }

  }

  if ($SetDefault) {

    $DEFAULT = '.DEFAULT'

    if ($SetDefault) {
      Write-Verbose "Set-HKUKey: Setting registry key for the default user profile."
      $Profiles = (Get-ChildItem -Path 'HKU:\') | Where-Object { $_.PSChildName -eq $DEFAULT } 
    }

  }

  if (-not $AllUsers -and -not $SetDefault) {

    Set-RegistryKey -Path 'Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'HideFileExt' -Value 0 -Type 'DWORD'

  }

}

Set-HKUKey -AllUsers -Verbose