#Requires -RunAsAdministrator

$LogPath = "$($env:TEMP)\DellCleanup.log"

Start-Transcript -Path $LogPath -Append -Force

$DellApps = @(
    'Dell SupportAssist',
    'Dell Digital Delivery',
    'Dell Customer Connect',
    'Dell Mobile Connect',
    'Dell Update',
    'Dell Optimizer',
    'Dell Power Manager',
    #'Dell Watchdog Timer', InstallShield
    'Dell Peripheral Manager',
    'Dell Core Services',
    'My Dell',
    'PartnerPromo'
)

Write-Host 'Beginning to remove software.'

$Products = (Get-CimInstance -ClassName Win32_Product)

foreach ($AppName in $DellApps) {
    Write-Host "`nChecking for MSI '$($AppName)'..."

    $ApplicationCimInstances = $Products | Where-Object {
        $_.Name -like "*$($AppName)*"
    }

    if ($ApplicationCimInstances) {
        foreach ($App in $ApplicationCimInstances) {
            $ProductCode = $App.IdentifyingNumber
            Write-Host "Found: $($App.Name)"
            Write-Host "ProductCode: $($ProductCode)"
            Write-Host 'Attempting to uninstall with msiexec...'

            $Arguments = "/x $($ProductCode) /qn /norestart"
            $Process = Start-Process -FilePath 'msiexec.exe' -ArgumentList $Arguments -Wait -PassThru

            if ($Process.ExitCode -eq 0) {
                Write-Host "Successfully uninstalled: $($App.Name)"
            } else {
                Write-Host "Uninstall failed for: $($App.Name) with exit code: $($Process.ExitCode)"
            }
        }
    } else {
        Write-Host "`nNot found: $($AppName)"
    }
}

$DellAppXPackages = Get-AppxPackage -AllUsers -Name '*Dell*'

foreach ($Package in $DellAppXPackages) {
    Write-Host "`nFound AppX package: $($Package.Name)"
    Write-Host "Attempting to remove AppX package: $($Package.Name)..."
    
    try {
        Remove-AppxPackage -Package $Package.PackageFullName -AllUsers -ErrorAction Stop
        Write-Host "Successfully removed AppX package: $($Package.Name)"
    } catch {
        Write-Host "Failed to remove AppX package: $($Package.Name) with error: $_"
    }
}

Write-Host 'Dell software removal complete.'

Stop-Transcript
