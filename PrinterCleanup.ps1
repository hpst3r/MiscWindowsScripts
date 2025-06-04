# run as user
$RetiredServerName = ""

# remove printer connection registry keys
$PrinterConnections = Get-ChildItem HKCU:\Printers\Connections | Where-Object {$_.Name -like "*$($RetiredServerName)*"}

if ($PrinterConnections) {

  $PrinterConnections | ForEach-Object {
    
    if (Test-Path $_) {

      Write-Host "Removing $($_)"
      Remove-Item $_

    }
  }
}

# restart the print spooler service
Write-Host "Restarting print spooler"
net stop spooler
net start spooler

# remove printers
$PrinterObjects = Get-Printer | Where-Object {$_.Name -like "*$($RetiredServerName)*"}
if ($PrinterObjects) {
  
  Write-Host "Printers found, removing printers"

  $PrinterObjects | ForEach-Object { Remove-Printer -Name $_.Name }

} else { Write-Host "Printers not found" }