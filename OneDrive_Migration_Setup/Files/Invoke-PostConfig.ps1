<#
################################################################################
#                                                                              #
# Tag registry with Key                                                        #
#   Prevents continuous running of app.                                        #
#                                                                              #
#                                                                              #
################################################################################
#>
$OD = Get-Process OneDrive -ErrorAction SilentlyContinue -ErrorVariable ODnone
$DoneKey = Test-Path 'HKLM:\SOFTWARE\ODCComplete'

switch ($DoneKey) {
    $true { continue }
    $false { New-Item -Path HKLM:\SOFTWARE\ODCComplete | Out-Null }
}

if ([bool]$od) {
    try {
        Set-ItemProperty -Path HKLM:\SOFTWARE\ODCComplete\ -Name 'Done' -Value 0 -ea Stop 
    }
    catch {
        New-ItemProperty -Path HKLM:\SOFTWARE\ODCComplete\ -Name 'Done' -PropertyType DWord -Value 0
    }
}    
else {
    try {
        Set-ItemProperty -Path HKLM:\SOFTWARE\ODCComplete\ -Name 'Done' -Value 1 -ea Stop 
    }    
    catch {
        New-ItemProperty -Path HKLM:\SOFTWARE\ODCComplete\ -Name 'Done' -PropertyType DWord -Value 1
    }
}


Start-Sleep 1
EXIT 0