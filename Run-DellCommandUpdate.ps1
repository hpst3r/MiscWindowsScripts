
$Reboot = if ($env:Reboot) { $true } else { $false }

$DcuPath = (Resolve-Path "C:\Program Files*\Dell\CommandUpdate\dcu-cli.exe")

if (Test-Path $DcuPath) {
  
  Write-Host "Dell Command | Update found at: $($DcuPath)"
  Write-Host "Launching DC|U CLI with arguments: /applyUpdates -reboot=$(if ($Reboot) { 'enable' } else { 'disable' })"
  
  Start-Process $DcuPath `
  	-ArgumentList "/applyUpdates -reboot=$(if ($Reboot) { 'enable' } else { 'disable' })" `
  	-NoNewWindow `
    -Wait
  
}
