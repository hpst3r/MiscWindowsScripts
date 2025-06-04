$RecordsToModify = @{
  'my-first-record' = '1.1.1.1';
  'mailserver' = '10.10.10.10';
}
$ZoneToModify = "internal.mydomain.com"
function Update-DnsARecord {
  param(
    $RecordName,
    $IPv4Address,
    $ZoneName
  )

  $OldRecord = Get-DnsServerResourceRecord -ZoneName $ZoneName -Name $RecordName

  Write-Host "Existing DNS record for $($RecordName): $($OldRecord.RecordType) $($OldRecord.Name) $($OldRecord.IPAddress)"

  $NewRecord = $OldRecord.Clone()

  $NewRecord.RecordData.IPv4Address = [IPAddress] $IPv4Address

  Set-DnsServerResourceRecord -NewInputObject $NewRecord -OldInputObject $OldRecord -ZoneName $ZoneName -PassThru
   
}

Foreach ($Record in $RecordsToModify.GetEnumerator()) {

  $RecordFromZone = Get-DNSServerResourcerecord -Name $Record.Name -ZoneName $ZoneToModify

  if ($null -ne $RecordFromZone) {

    if ($RecordFromZone.RecordType -ne "A") {

      Write-Host "RecordType for this record, $($Record.Name), is not A. I do not modify non-A records. Exiting."

      exit 1

    } else {

      Write-Host "RecordType for $($Record.Name) is A. OK!"

      Write-Host "Setting $($Record.Name) DNS record to IP $($Record.Value)"

      Update-DnsARecord -RecordName $Record.Name -IPv4Address $Record.Value -ZoneName $ZoneToModify

    }
  } else {

    Write-Host "Record $($Record.Name) does not exist. Creating it."
    Add-DnsServerResourceRecord -ZoneName $ZoneToModify -Name $Record.Name -IPv4Address $Record.Value -A

  }

}

Write-Host "Done modifying DNS records."
