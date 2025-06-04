<#
.SYNOPSIS
Replaces the UserPrincipalName (UPN) suffix (domain)
for all users with a specific suffix in an OU.

.EXAMPLE
Replace-UpnSuffix `
  -OldSuffix domain.local `
  -NewSuffix domain.com `
  -TargetOU "Employees" `
  -BackupFile "Users.csv"

.DESCRIPTION
Replaces the User Principal Name (UPN) suffix for all users in a specified
Organizational Unit (OU) in Active Directory.

This script will find all users in the specified OU whose UPN ends with
the old suffix, export their ADUser objects to a CSV file, then modify
their UPN to the new suffix.

There should be no impact on the users. Logging out is required for the changes
to take effect in the user's session.

This might be useful when rolling out Entra Hybrid Join or similar scenarios
where the UPN needs to be updated to match the new domain structure.

.PARAMETER OldSuffix
The old UPN suffix to be replaced (e.g., "domain.local").

.PARAMETER NewSuffix
The new UPN suffix to replace the old one with (e.g., "domain.com").

.PARAMETER TargetOU
The name of the Organizational Unit (OU) where the users are located
(e.g., "Employees"). This will be used as a filter on the DistinguishedName
property of user objects (like "*OU=Employees*"), so if you have a more complex
OU structure, it may require adjustment to ensure you are targeting the correct OU.

.PARAMETER BackupFile
The name of the file where the user objects will be backed up before modification
(default is "Users.csv").
#>
function Set-UpnSuffix {
  param (
    [Parameter(Mandatory = $true)]
    [string]$OldSuffix,

    [Parameter(Mandatory = $true)]
    [string]$NewSuffix,

    [Parameter(Mandatory = $true)]
    [string]$TargetOU,

    [string]$BackupFile = "Users.csv"
  )

  $Users = Get-ADUser -Filter * -Properties UserPrincipalName |
    Where-Object {
      ($_.UserPrincipalName -like "*$($OldSuffix)") -and
      ($_.DistinguishedName -like "*OU=$($TargetOU)*") -and
      ($_.Enabled -eq 'True')
    }

  # export a backup of users to be modified to a file on disk
  New-Item $BackupFile -ItemType File
  Set-Content $BackupFile ($Users | ConvertTo-CSV)

  $Users | ForEach-Object {
    
    # modify the UPN
    $NewUPN = $_.UserPrincipalName.Replace($OldSuffix, $NewSuffix)

    Write-Host "Modifying UPN $($_.UserPrincipalName) to $($NewUPN)."

    # whatif for log
    Set-ADUser -Identity $_.DistinguishedName -UserPrincipalName $NewUPN -WhatIf
    
    # real command - set the modified UPN
    Set-ADUser -Identity $_.DistinguishedName -UserPrincipalName $NewUPN

  }

}