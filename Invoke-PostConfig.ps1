if ((Test-Path 'HKLM:\SOFTWARE\ODCComplete') -eq $false) {
    New-Item -Path HKLM:\SOFTWARE\ODCComplete 
    New-ItemProperty -Path HKLM:\SOFTWARE\ODCComplete\ -Name 'Done' -PropertyType DWord -Value 1
}

Start-Sleep 1
EXIT 0