[String]$KeyPath = 'HKLM:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32'
[String]$ValueName = '(Default)'
[String]$ValueType = 'String'
[String]$Value = ''

if (-not (Test-Path -Path $KeyPath)) {
  New-Item `
    -Path $KeyPath `
    -Force
}

if (Get-ItemProperty -Path $KeyPath -Name $ValueName) {
  Set-ItemProperty -Path $KeyPath -Name $ValueName -Value $Value -Force
} else { # if not exists create value
  New-ItemProperty -Path $KeyPath -Name $ValueName -Type $ValueType -Value $Value
}