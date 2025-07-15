<#
.SYNOPSIS
Runs the SentinelOne Cleaner to remove a broken installation of SentinelOne.

.DESCRIPTION
Downlaods and runs the SentinelOne Cleaner to remove a broken installation of SentinelOne.

This is useful when the SentinelOne agent is not functioning correctly and cannot be uninstalled normally.

.EXAMPLE
Remove-SentinelOne
Remove-SentinelOne -c

.PARAMETER CallC
Call the executable with the -c flag rather than using the Cleaner directly.
This is necessary when Uninstall Confirmation is enabled in the SentinelOne console.

#>
function Remove-SentinelOne {
  param (
  [Switch] $CallC,
  [string] $SiteToken
  )

  $WorkingDirectory = (
  New-Item `
    -Path "$($env:TEMP)\$(Get-Date -UFormat %s)" `
    -ItemType Directory
  )

  if ($CallC) {
  
  Write-Host '-CallC set: Running SentinelOne executable with -c flag.'

  # download the SentinelOne installer executable

  $S1DownloadUri = 'https://deployment.wporter.org/files/s1/SentinelOneInstaller_windows_64bit_v24_2_3_471.exe'

  Write-Host "Downloading SentinelOne Installer from $($S1DownloadUri)..."

  Invoke-WebRequest `
    -Uri $S1DownloadUri `
    -OutFile "$($WorkingDirectory)\s1.exe" `
    -Method GET

  Write-Host "Wrote installer to '$($WorkingDirectory)\s1.exe'."

  Write-Host 'Running SentinelOne Installer with -c -t flags...'

  $Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

  Start-Process -FilePath "$($WorkingDirectory)\s1.exe" -ArgumentList '-c',"-t $($SiteToken)" -Wait

  $Stopwatch.Stop()

  Write-Host "SentinelOne -c completed in $($Stopwatch.Elapsed.TotalSeconds) seconds."

  }

  if (-not $CallC) {

  Write-Host 'No -CallC argument: running SentinelOne Cleaner directly.'

  $S1DownloadUri = 'https://deployment.wporter.org/files/s1/s1-24-2-3-471-win-amd64.zip'

  # download the SentinelOne installer executable

  Write-Host "Downloading SentinelOne Cleaner from $($S1DownloadUri)..."

  Invoke-WebRequest `
    -Uri $S1DownloadUri `
    -OutFile "$($WorkingDirectory)\s1.zip" `
    -Method GET

  # extract the contents of the executable from the archive

  Write-Host 'Extracting SentinelOne Cleaner...'

  Expand-Archive `
    -Path "$($WorkingDirectory)\s1.zip" `
    -DestinationPath $WorkingDirectory `
    -Force

  # run the SentinelCleaner to remove the broken installation
  Write-Host 'Running SentinelOne Cleaner... Please be patient, this may take a while.'

  $Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

  & "$($WorkingDirectory)\SentinelCleaner.exe"

  $Stopwatch.Stop()

  Write-Host "SentinelOne Cleaner completed in $($Stopwatch.Elapsed.TotalSeconds) seconds."

  }

  # remove the working directory to avoid leaving the S1 Cleaner around
  try {
  
  Remove-Item `
    -Path $WorkingDirectory `
    -Force `
    -Recurse

  Write-Host 'SentinelOne Cleaner removed successfully.'

  } catch {

  Write-Error "Failed to remove SentinelOne Cleaner working directory: $($_.Exception.Message)"

  }

}

Write-Host "Calling S1 cleaner with token: $($env:SITETOKEN)"

Remove-SentinelOne -CallC -SiteToken $env:SITETOKEN