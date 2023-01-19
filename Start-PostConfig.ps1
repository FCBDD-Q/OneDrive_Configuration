###########################
# ! Post Config settings ! #
###########################

#Set

if ((Test-Path 'HKLM:\SOFTWARE\ODCComplete') -eq $false) {
    New-Item -Path HKLM:\SOFTWARE\ODCComplete 
    New-ItemProperty -Path HKLM:\SOFTWARE\ODCComplete\ -Name 'Done' -PropertyType DWord -Value 1
}

for ($icounter = 0; $icounter -lt 3; $icounter++) {
    $Redirection = $null
    $OfflineFiles = $null
    #
    $Redirection = Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\' -Recurse | Select-Object -ExpandProperty Name | Where-Object { $_ -like '*fdeploy' } 
    $OfflineFiles = Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\' -Recurse | Select-Object -ExpandProperty Name | Where-Object { $_ -like '*SyncItemLog' } 
    #
    if ($null -ne $Redirection -or $null -ne $OfflineFiles) {
        foreach ($FKey in $redirection) {
            Remove-Item -LiteralPath ($FKey).Replace('HKEY_LOCAL_MACHINE', 'HKLM:') -Recurse -Force -Confirm:$false -ea Stop
        }
    
        foreach ($SKey in $OfflineFiles) {
            Remove-Item -LiteralPath ($SKey).Replace('HKEY_LOCAL_MACHINE', 'HKLM:') -Recurse -Force -Confirm:$false -ea Stop
        }
    }
    
    else {
        # exit the loop do NOT run the admin script again
        $icounter = 50000
    }
}