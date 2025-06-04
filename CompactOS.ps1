function Compact-OS {

  Write-Host "Enabling CompactOS..."

  & compact.exe /compactos:always 1> $null
  
  Write-Host "Done!"
  
}

Compact-OS
