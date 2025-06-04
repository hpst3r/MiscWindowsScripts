# one component of local admin reporting via NinjaRMM
# I think WYSIWYG fields will let you skip the base64 junk
# cannot recall why I didn't use them

function Set-NinjaProperties {
  param (
  [string]$GroupName,
  [string]$ValueName
  )

  $Group = (Get-LocalGroup -Name $GroupName)

  if ($Group) {

  $GroupMembers = (Get-LocalGroupMember -Name $GroupName)

  if ($GroupMembers) {

    $JSON = ($GroupMembers | Select-Object Name,SID,PrincipalSource | ConvertTo-Json -Depth 1 -Compress)
  
    Ninja-Property-Set -Name "$($ValueName)EncodedMinifiedJson" -Value $(
    [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($JSON))
    )
  
    Ninja-Property-Set -Name "$($ValueName)HumanReadable" -Value $($GroupMembers.Name | Out-String)

    Write-Host "Info: Pushed $($GroupName) group members to RMM"

  } else {
    
    Ninja-Property-Set -Name "$($ValueName)EncodedMinifiedJson" -Value ''
  
    Ninja-Property-Set -Name "$($ValueName)HumanReadable" -Value ''

    Write-Host "Info: Pushed empty $($GroupName) membership to RMM"

  }

  } else {

  Write-Host "Info: Group $($GroupName) does not exist on this machine"

  }
  
}

Set-NinjaProperties -GroupName 'Administrators' -ValueName 'localAdministrators'

Set-NinjaProperties -GroupName 'Remote Desktop Users' -ValueName 'rdpUsers'

Set-NinjaProperties -GroupName 'OpenSSH Users' -ValueName 'sshUsers'

Set-NinjaProperties -GroupName 'Hyper-V Administrators' -ValueName 'hvAdministrators'

Set-NinjaProperties -GroupName 'IIS_IUSRS' -ValueName 'IISUsers'

Set-NinjaProperties -GroupName 'Remote Management Users' -ValueName 'winrmUsers'

<#
sample output - JSON -Depth 1

[
  {
  "Name": "WP25-P14SG5I\\Administrator",
  "SID": "S-1-5-21-98111195-3049186222-2150619400-500",
  "PrincipalSource": 1
  },
  {
  "Name": "WP25-P14SG5I\\liam",
  "SID": "S-1-5-21-98111195-3049186222-2150619400-1000",
  "PrincipalSource": 1
  }
]

sample output - minified JSON -D 1

[{"Name":"WP25-P14SG5I\\Administrator","SID":"S-1-5-21-98111195-3049186222-2150619400-500","PrincipalSource":1},{"Name":"WP25-P14SG5I\\liam","SID":"S-1-5-21-98111195-3049186222-2150619400-1000","PrincipalSource":1}]

usage: minified JSON is encoded base64 to preserve JSON objects and pushed to RMM

$base64 = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($JSON))

sample output - base64 encoded UTF8 minified JSON

W3siTmFtZSI6IldQMjUtUDE0U0c1SVxcQWRtaW5pc3RyYXRvciIsIlNJRCI6IlMtMS01LTIxLTk4MTExMTk1LTMwNDkxODYyMjItMjE1MDYxOTQwMC01MDAiLCJQcmluY2lwYWxTb3VyY2UiOjF9LHsiTmFtZSI6IldQMjUtUDE0U0c1SVxcbGlhbSIsIlNJRCI6IlMtMS01LTIxLTk4MTExMTk1LTMwNDkxODYyMjItMjE1MDYxOTQwMC0xMDAwIiwiUHJpbmNpcGFsU291cmNlIjoxfV0=

minified, encoded JSON is pulled from RMM via API and decoded:

[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($base64))

Once it's back on your system, ConvertFrom-Json and you have your PowerShell object.

PS C:\Users\liam> [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String(($CustomFieldResponse.Content | ConvertFrom-Json).localAdministratorsEncodedMinifiedJson)) | ConvertFrom-Json

Name                       SID                                          PrincipalSource
----                       ---                                          ---------------
WP25-P14SG5I\Administrator S-1-5-21-98111195-3049186222-2150619400-500                1
WP25-P14SG5I\liam          S-1-5-21-98111195-3049186222-2150619400-1000               1

#>

<#
$JSON = ($AdministratorsMembers | Select-Object Name,SID,PrincipalSource | ConvertTo-Json -Compress -Depth 1)



PS C:\Users\liam> [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String(($CustomFieldResponse.Content | ConvertFrom-Json).localAdministratorsEncodedMinifiedJson)) | ConvertFrom-Json

Name                       SID                                          PrincipalSource
----                       ---                                          ---------------
WP25-P14SG5I\Administrator S-1-5-21-98111195-3049186222-2150619400-500                1
WP25-P14SG5I\liam          S-1-5-21-98111195-3049186222-2150619400-1000               1
#>