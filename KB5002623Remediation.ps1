$Fileserver = "https://deployment.wporter.org/files"

$Office2016x86 = [bool](
  Get-ChildItem HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall |
  Get-Item |
  Get-ItemProperty |
  Where-Object DisplayName -match "^Microsoft Office (Standard|Professional.*) 2016$"
)

$Office2016x64 = [bool](
  Get-ChildItem HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall |
  Get-Item |
  Get-ItemProperty |
  Where-Object DisplayName -match "^Microsoft Office (Standard|Professional.*) 2016$"
)

if (-not ($Office2016x64 -or $Office2016x86)) {
  Write-Host 'Office 2016 is not detected. No action is required.'
  return
}

$PatchesPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Products\*\Patches\*'

$KB5002700Installed = [bool](Get-ItemProperty -Path $PatchesPath | Where-Object DisplayName -like *KB5002700*)

$KB5002623Installed = [bool](Get-ItemProperty -Path $PatchesPath | Where-Object DisplayName -like *KB5002623*)

Write-Host "KB5002700 installed: $($KB5002700Installed)"

Write-Host "KB5002623 installed: $($KB5002623Installed)"

function Install-Patch {
  param(
    [Parameter(Position = 0, Mandatory=$true)]
    [string]$PatchFileName
  )

  Write-Host "Attempting to install patch $($PatchFileName)"

  $Update = (Join-Path -Path $env:TEMP -ChildPath $PatchFileName)

  try {
    
    Invoke-WebRequest `
      -Uri "$($Fileserver)/$($PatchFileName)" `
      -Method GET `
      -OutFile $Update

  } catch {

    throw "Failed to download update $($PatchFileName) from $($Fileserver). Response: $($_)"

  }

  & $Update /quiet

}

if (-not $KB5002700Installed) {

  Write-Host 'Attempting to install KB5002700.'

  if ($Office2016x86) { Install-Patch 'mso2016-kb5002700-fullfile-x86-glb.exe' }

  if ($Office2016x64) { Install-Patch 'mso2016-kb5002700-fullfile-x64-glb.exe' }

  Write-Host 'Waiting for 720 seconds to allow Office patch KB5002700 to install.'

  Start-Sleep -Seconds 720

} else {

  Write-Host 'KB5002700 is already installed. No changes were made.'

}

if (-not $KB5002623Installed) {

  Write-Host 'Attempting to install KB5002623.'

  if ($Office2016x86) { Install-Patch 'msodll202016-kb5002623-fullfile-x86-glb.exe' }

  if ($Office2016x64) { Install-Patch 'msodll202016-kb5002623-fullfile-x64-glb.exe' }

  Write-Host 'Waiting for 720 seconds to allow Office patch KB5002623 to install.'

  Start-Sleep -Seconds 720

} else {
  
  Write-Host 'KB5002623 is already installed. No changes were made.'

}

$KB5002700Installed = [bool](Get-ItemProperty -Path $PatchesPath | Where-Object DisplayName -like *KB5002700*)

$KB5002623Installed = [bool](Get-ItemProperty -Path $PatchesPath | Where-Object DisplayName -like *KB5002623*)

if ($KB5002623Installed -and $KB5002700Installed) {
  
  Write-Host "Success: KB5002623 and KB5002700 patches are installed."

} else {

  throw "Remediation failed: KB5002623 installation state: $($KB5002623Installed), KB5002700 installation state: $($KB5002700Installed)."

}