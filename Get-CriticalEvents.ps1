Function Get-CriticalEvents {

  $Events = Get-WinEvent -FilterHashTable @{ LogName = 'System'; Level = 1; } 2> $null

  "Total count: $($Events.Count) events.`n"

$Events | ForEach-Object {
    $CurrentEvent = $_
    @"
Timestamp: $($CurrentEvent.TimeCreated)
Event ID: $($CurrentEvent.Id)
Provider: $($CurrentEvent.ProviderName)
$($CurrentEvent.LevelDisplayName): $($CurrentEvent.Message)`n
"@
  }

}

Ninja-Property-Set -Name 'criticalEvents' -Value (Get-CriticalEvents)
