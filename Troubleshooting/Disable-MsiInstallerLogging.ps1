param (
  [switch]$Verbose,
  [switch]$Debug
)

$LoggingString = "$(if ($Verbose) {'v'})oicewarmup$(if ($Debug) {'x'})"

$InstallerPolicyPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Installer'

if (Test-Path $InstallerPolicyPath) {

  if (Get-ItemProperty $InstallerPolicyPath 'Logging') {

  Remove-ItemProperty `
    -Path $InstallerPolicyPath `
    -Name 'Logging' `
    -Force
  }

}