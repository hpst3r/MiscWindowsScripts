# script to remove Winget packages as System
# used from RMM that doesn't natively do UAC/elevation to "Administrator" context

try {
  $WingetPath = Resolve-Path "C:\Program Files\WindowsApps\Microsoft.DesktopAppInstaller*\winget.exe"
}
catch {
  Write-Error -Message "Winget path not found. Cannot complete request."
  return 1
}
try {
  & $WingetPath @("remove", "--exact", "$($env:WingetPackageId)", "--silent")
}
catch{
  Write-Error -Message "Failed to remove Winget application with error:"
  Write-Error -Message $_
}
return 0
