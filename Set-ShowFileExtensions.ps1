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
    } catch {
      Write-Warning "Set-ShowFileExtensions: Could not find user profile for SID $($User). Skipping."
      continue
    }

    # get the ProfileImagePath property to find the path to the user's NTUSER.DAT file
    $ProfileImagePath = Get-ItemPropertyValue -Path $UserProfileKey -Name ProfileImagePath

    Write-Host "Set-ShowFileExtensions: Loading user hive for SID $($User) with profile $($ProfileImagePath)."

    $Load = (& reg.exe LOAD "HKU\$($User)" "$($ProfileImagePath)\NTUSER.DAT")

    if ($Load -ne 'The operation completed successfully.') {
      Write-Error "Set-ShowFileExtensions: Failed to load user hive for SID $($User). REG.exe error: $($Load)"
      continue
    }

    Write-Host "Set-ShowFileExtensions: Loaded user hive for SID $($User). REG.exe output: $($Load)"

  }

}

function Unload-UserHives {
  [CmdletBinding()]
  param(
    [System.Security.Principal.SecurityIdentifier[]]$Users
  )

  # run the garbage collector to release handles before unloading hives
  [System.GC]::Collect()

  # so we do not attempt to unload an active user, get users who have processes running
  $LoggedOnUsers = Get-Process -IncludeUserName |
    Where-Object { $_.UserName } |
    Select-Object -ExpandProperty UserName -Unique

  # get SIDs from the users
  $LoggedOnSIDs = foreach ($User in $LoggedOnUsers) {
    try {
      $NTAccount = New-Object System.Security.Principal.NTAccount($User)
      $SID = $NTAccount.Translate([System.Security.Principal.SecurityIdentifier])
      $SID.Value
    } catch {
      Write-Warning "Could not resolve SID for user $User"
    }
  }

  # filter out anything but revision 5 or 12 SIDs with subauthority #1 values of 21

  foreach ($User in $Users) {

    Write-Host "Set-ShowFileExtensions: Unloading user hive for SID $($User)."

    $Unload = (& reg.exe UNLOAD "HKU\$($User)")

    if ($Unload -ne 'The operation completed successfully.') {
      Write-Error "Set-ShowFileExtensions: Failed to unload user hive for SID $($User). REG.exe error: $($Unload)"
    } else {
      Write-Host "Set-ShowFileExtensions: Unloaded user hive for SID $($User). REG.exe output: $($Unload)"
    }

  }

}

<#
.SYNOPSIS
  Sets the Windows Explorer setting to show file extensions.
.DESCRIPTION
  This script modifies the Windows Registry to ensure that file extensions are visible in Windows Explorer.
.EXAMPLE
  Set-ShowFileExtensions -AllUsers
#>
Function Set-ShowFileExtensions {
  [CmdletBinding()]
  param(
    [switch]$AllUsers,
    [switch]$SetDefault,
    [string]$RootPath = 'HKCU:\'
  )

  $DEFAULT = '.DEFAULT'

  # only set for the default profile
  if ($SetDefault) { # TODO: load default hive
    Write-Verbose "Set-ShowFileExtensions: Setting registry key for the default user profile."
    $Profiles = (Get-ChildItem -Path 'HKU:\') | Where-Object { $_.PSChildName -eq $DEFAULT } 
  }

  # load all users' hives, set key for each user profile
  if ($AllUsers) {

    try {
      # recursively set the registry key by calling the function for each user profile
      
      # map HKU as a PSDrive to enable us to access all user profiles
      New-PSDrive -Name 'HKU' -PSProvider Registry -Root HKEY_USERS | Out-Null

      if ($AllUsers) {
        Write-Verbose "Set-ShowFileExtensions: Setting registry key for all user profiles, $(if ($SetDefault) { 'including the default profile'} else { 'excluding the default profile' })."

        Write-Verbose "Set-ShowFileExtensions: Getting SIDs of all user profiles."

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
            } catch {
                $SID.Value
            }
          }
        )
        
        # debug verbose output showing affected user profiles
        Write-Verbose "Set-ShowFileExtensions: Found the following user profiles: `n $($FriendlyUsers -join "`n ")"

        Write-Verbose "Set-ShowFileExtensions: Loading user hives for found user profiles."
      
        Load-UserHives -Users $Users

        Write-Verbose "Set-ShowFileExtensions: Finding HKU:\ paths for loaded users."

        $Profiles = (
          Get-ChildItem -Path 'HKU:\' |
          Where-Object {
            $_.PSChildName -in $Users
          }
        )

        Write-Verbose "Set-ShowFileExtensions: Found $($Profiles.Count) user profiles with loaded hives: `n $($Profiles.PSChildName -join "`n ")"

      }
      
      Write-Verbose "Set-ShowFileExtensions: Profiles: $($Profiles -join "`n " )"

      Write-Verbose "Set-ShowFileExtensions: Setting registry key for $($Profiles.Count) user profiles."

      foreach ($User in $Profiles) {

        $SID = $User.PSChildName
        $User = try { Get-LocalUser -SID $SID -ErrorAction Stop } catch { if ($SID -eq $DEFAULT) { '.DEFAULT' } else { throw $_ } }

        Set-ShowFileExtensions -RootPath "HKU:\$($SID)\"

        [System.GC]::Collect() # force garbage collection to release handles so hive can be unloaded

        $Unload = (& reg.exe UNLOAD "HKU\$($SID)")

      }

    } catch {

      throw $_

    } finally {

      Remove-PSDrive -Name 'HKU' -Force -ErrorAction SilentlyContinue

    }

  } else {

      [String]$KeyPath = "$($RootPath)Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
      [String]$ValueName = 'HideFileExt'
      [String]$ValueType = 'DWORD'
      [Int32]$Value = 0

      Write-Verbose "Setting registry key: $($KeyPath) $($ValueName) to $($ValueType) $($Value)"

      if (-not (Test-Path -Path $KeyPath)) {
        New-Item `
          -Path $KeyPath `
          -Force
      }

      if (Get-ItemProperty -Path $KeyPath -Name $ValueName 2>$null) { # if exists update value

        Set-ItemProperty -Path $KeyPath -Name $ValueName -Value $Value -Force

      } else { # if not exists create value

        New-ItemProperty -Path $KeyPath -Name $ValueName -Type $ValueType -Value $Value 1>$null

      }

  }

}