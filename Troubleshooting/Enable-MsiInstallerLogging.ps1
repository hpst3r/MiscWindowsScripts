param (
  [switch]$Verbose,
  [switch]$Debug
)

$LoggingString = "$(if ($Verbose) {'v'})oicewarmup$(if ($Debug) {'x'})"

$InstallerPolicyPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Installer'

if (-not (Test-Path $InstallerPolicyPath)) {
  New-Item $InstallerPolicyPath -Force
}

if (-not ((Get-ItemProperty $InstallerPolicyPath 'Logging' 2> $null) -eq $LoggingString)) {

  New-ItemProperty `
    -Path $InstallerPolicyPath `
    -Name 'Logging' `
    -Value $LoggingString `
    -Force

}