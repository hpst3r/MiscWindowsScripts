<#
.SYNOPSIS
Register an application to run at startup for a user by creating a shortcut in
their "$env:USERPROFILE\Start Menu\Programs\Startup" directory.

.PARAMETER Target
The full path to the executable you would like to register as an application to run at startup.

.NOTES
Run as the logged-on user, not System. This does not require elevation.
The application will appear in the Task Manager Startup tab.
Autolaunch can be disabled from Task Manager as with any other normal app.

.EXAMPLE
New-StartupApp -Target 'C:\Program Files\CPUID\CPU-Z\cpuz.exe'
#>
function New-StartupApp {
  param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    $Target
  )

  $TargetName = ((Split-Path -Path $Target -Leaf) -split '\.')[0] # get file name

  $Shortcut = (New-Object -COM WScript.Shell).CreateShortcut("$($env:USERPROFILE)\Start Menu\Programs\Startup\$($TargetName).lnk")

  $Shortcut.TargetPath = $Target

  $Shortcut.Save()

}