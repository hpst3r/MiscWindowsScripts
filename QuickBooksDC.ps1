<#
Intended for Windows Servers running DNS and QuickBooks DB servers.
The DNS service binds to nearly all ephemeral UDP ports,
which are ports that are used by QuickBooks.
The QuickBooks database server will fail to start if it cannot bind to its ports.
Stop and restart the DNS service to prevent the QuickBooks DB service from failing.
#>

$DatabaseManager = (Get-Service "QuickBooksDB*")

if (-not $DatabaseManager) {
  Write-Warning "No QuickBooks database service found. Nothing for me to do. Terminating."
  return 0
}

Write-Verbose "QuickBooks database servers on this machine:"
Write-Verbose $DatabaseManager

$StoppedServices = ($DatabaseManager | Where-Object Status -eq Stopped)

if ([bool]($StoppedServices)) {

  Write-Verbose "Found stopped QuickBooks DB servers:"
  Write-Verbose ($StoppedServices.Name)

} else {

  Write-Verbose "Found no stopped QuickBooks database servers. Nothing for me to do. Terminating."
  return 0

}

$DNSService = (Get-Service dns)

if (($DNSService) -and ($DNSService.Status -eq 'Running')) {

  Write-Warning "DNS service is running, and QuickBooks database services are stopped. Raising alert."

  try {
    Write-Host "Attempting to stop dns.exe..."
    Stop-Service dns -ErrorAction Stop

    Write-Host "Attempting to start stopped QuickBooks DB services..."
    Start-Service $StoppedServices -ErrorAction Stop

    Write-Host "Attempting to start dns.exe..."
    Start-Service dns -ErrorAction Stop
  }
  catch {
    Write-Warning "Something went wrong. Failed to stop or restart QuickBooks or DNS service."
    return 1
  }
  finally {
    Write-Host "Attempting to ensure that dns.exe is running..."
    Start-Service dns
  }

}

if (($DNSService) -and ($DNSService.Status -ne 'Running')) {

  Write-Warning "DNS service is not running. Unexpected state, raising alert."
  return 1

}