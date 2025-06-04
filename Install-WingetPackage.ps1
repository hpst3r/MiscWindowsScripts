# script to install Winget packages as System (from RMM)
# https://learn.microsoft.com/en-us/windows/package-manager/winget/#install-winget

# this *WAS* the MS recommendation a long, long time ago (21H2 - 23H2) but does not work on some 23H2 machines that have it installed, but broken
<#
function Install-Winget {
  $progressPreference = 'silentlyContinue'
  Write-Information "Downloading WinGet and its dependencies..."
  Invoke-WebRequest -Uri https://aka.ms/getwinget -OutFile Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle
  Invoke-WebRequest -Uri https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx -OutFile Microsoft.VCLibs.x64.14.00.Desktop.appx
  Invoke-WebRequest -Uri https://github.com/microsoft/microsoft-ui-xaml/releases/download/v2.8.6/Microsoft.UI.Xaml.2.8.x64.appx -OutFile Microsoft.UI.Xaml.2.8.x64.appx
  Add-AppxPackage Microsoft.VCLibs.x64.14.00.Desktop.appx
  Add-AppxPackage Microsoft.UI.Xaml.2.8.x64.appx
  Add-AppxPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle
}
#>

# this is the current MS recommendation for installing Winget as of 6/25, seems to work.. sometimes
function Install-Winget {
  $progressPreference = 'silentlyContinue'
  Write-Host "Installing WinGet PowerShell module from PSGallery..."
  Install-PackageProvider -Name NuGet -Force | Out-Null
  Install-Module -Name Microsoft.WinGet.Client -Force -Repository PSGallery | Out-Null
  Write-Host "Using Repair-WinGetPackageManager cmdlet to bootstrap WinGet..."
  Repair-WinGetPackageManager
  Write-Host "Done."
}

# on my system: C:\Program Files\WindowsApps\Microsoft.DesktopAppInstaller_1.25.390.0_x64__8wekyb3d8bbwe\winget.exe
$WingetPath = Resolve-Path "C:\Program Files\WindowsApps\Microsoft.DesktopAppInstaller*\winget.exe"

if (-not (Test-Path $WingetPath) -or ( -not (Get-Command winget) ) ) {

	Write-Error -Message "Winget path not found. Installing Winget."
	Install-Winget

  $WingetPath = Resolve-Path "C:\Program Files\WindowsApps\Microsoft.DesktopAppInstaller*\winget.exe"

  if (!$WingetPath) {

    Write-Error -Message "Winget path not found after installation. Failure. Exiting."
    return 1

  }

}

& $WingetPath @("install", "--exact", "$($env:WingetPackageId)", "--silent", "--accept-package-agreements", "--accept-source-agreements")

return 0