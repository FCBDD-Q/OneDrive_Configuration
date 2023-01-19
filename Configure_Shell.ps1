function Set-ShellRegs() {
    $Global:Ukeys = Get-ItemProperty 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders'
    $USK = @(
        [pscustomobject]@{PropName = 'Desktop' ; PropValue = '%USERPROFILE%\Desktop'; PropPath = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders' }
        [pscustomobject]@{PropName = 'Favorites' ; PropValue = '%USERPROFILE%\Favorites'; PropPath = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders' }
        [pscustomobject]@{PropName = 'My Music ' ; PropValue = '%USERPROFILE%\Music'; PropPath = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders' }
        [pscustomobject]@{PropName = 'My Pictures' ; PropValue = '%USERPROFILE%\Pictures'; PropPath = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders' }
        [pscustomobject]@{PropName = 'My Video' ; PropValue = '%USERPROFILE%\Videos'; PropPath = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders' }
        [pscustomobject]@{PropName = 'Personal' ; PropValue = '%USERPROFILE%\Documents'; PropPath = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders' }
        [pscustomobject]@{PropName = '{35286A68-3C57-41A1-BBB1-0EAE73D76C95}' ; PropValue = '%USERPROFILE%\Videos'; PropPath = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders' }
        [pscustomobject]@{PropName = '{0DDD015D-B06C-45D5-8C4C-F59713854639}' ; PropValue = '%USERPROFILE%\Pictures'; PropPath = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders' }
        [pscustomobject]@{PropName = '{F42EE2D3-909F-4907-8871-4C22FC0BF756}' ; PropValue = '%USERPROFILE%\Documents'; PropPath = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders' }
        [pscustomobject]@{PropName = '{A0C69A99-21C8-4671-8703-7934162FCF1D}' ; PropValue = '%USERPROFILE%\Music'; PropPath = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders' }
        [pscustomobject]@{PropName = '{1B3EA5DC-B587-4786-B4EF-BD1DC332AEAE}' ; PropValue = '%USERPROFILE%\AppData\Roaming\Microsoft\Windows\Libraries'; PropPath = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders' }
        [pscustomobject]@{PropName = 'Appdata' ; PropValue = '%USERPROFILE%\AppData\Roaming'; PropPath = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders' }
        [pscustomobject]@{PropName = 'My Music' ; PropValue = '%USERPROFILE%\Music'; PropPath = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders' }
        [pscustomobject]@{PropName = '{754AC886-DF64-4CBA-86B5-F7FBF4FBCEF5}' ; PropValue = '%USERPROFILE%\Desktop'; PropPath = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders' }       
    )
    
    Switch ($Global:Ukeys -like '*\\*') {
        $true { 
            foreach ($UK in $USK) {
                Set-ItemProperty -Path $UK.PropPath -Name $uk.PropName -Value $UK.PropValue -Force -ErrorAction SilentlyContinue 
            }
        }        
        $false { 
            Write-Host 'No action taken'
        }
    }
    
    $Global:SKey = Get-ItemProperty 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders'
    $SHK = @(
        [pscustomobject]@{PropName = 'Desktop' ; PropValue = "c:\Users\$env:USERNAME\Desktop"; PropPath = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders' }
        [pscustomobject]@{PropName = 'Favorites' ; PropValue = "c:\Users\$env:USERNAME\Favorites"; PropPath = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders' }
        [pscustomobject]@{PropName = 'My Music ' ; PropValue = "c:\Users\$env:USERNAME\Music"; PropPath = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders' }
        [pscustomobject]@{PropName = 'My Pictures' ; PropValue = "c:\Users\$env:USERNAME\Pictures"; PropPath = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders' }
        [pscustomobject]@{PropName = 'My Video' ; PropValue = "c:\Users\$env:USERNAME\Videos"; PropPath = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders' }
        [pscustomobject]@{PropName = 'Personal' ; PropValue = "c:\Users\$env:USERNAME\Documents"; PropPath = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders' }
        [pscustomobject]@{PropName = 'Appdata' ; PropValue = "c:\Users\$env:USERNAME\AppData\Roaming"; PropPath = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders' }
        [pscustomobject]@{PropName = 'My Music' ; PropValue = "c:\Users\$env:USERNAME\Music"; PropPath = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders' }
    )
    
    Switch ($global:SKey -like '*\\*') {
        $true { 
            foreach ($SK in $SHK) {
                Set-ItemProperty -Path $SK.PropPath -Name $SK.PropName -Value $SK.PropValue -Force -ErrorAction SilentlyContinue
            }
        }        
        $false { 
            Write-Host 'No action taken'
        }
    }
}    