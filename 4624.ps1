param (
  [string]$Username
)
Get-WinEvent `
  -FilterHashtable @{
    LogName = 'Security'
    ID = 4624 } |
ForEach-Object {
  $LogonType = $_.Properties[8].Value
  $SID = $_.Properties[4].Value
  $RID = [int64]($SID.Value.Split("-")[-1])
  if ($RID -gt 0x400) {
    (Get-ADUser -Identity $SID).Name
  }
}

<#
$Events = @()
[string]$Username = "jdoe"
[int32]$Count = 0
Get-WinEvent `
  -FilterHashtable @{
    LogName = 'Security'
    ID = 4624 } |
ForEach-Object {
  if (($_.Properties[5].Value) -eq $Username) {
    $Events += $_
    $Count++
  } # if
} # foreach
$Count

#>