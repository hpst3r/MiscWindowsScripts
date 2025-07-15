# install Teams systemwide with the Teams Bootstrapper utility
# https://learn.microsoft.com/en-us/microsoftteams/new-teams-bulk-install-client

$Path = (Join-Path -Path $($env:TEMP) -ChildPath 'teamsbootstrapper.exe')

Invoke-WebRequest -Method Get `
  -Uri "https://go.microsoft.com/fwlink/?linkid=2243204&clcid=0x409" `
  -OutFile $Path

& $Path -p