function Invoke-VarsAndLogging() {
    switch (Test-Path "$($env:USERPROFILE)\OD_LOG") {
        $true {
            Continue 
        }
        $false {
            $OutNull = mkdir "$($env:USERPROFILE)\OD_LOG" 
        }
    }
    
    $Global:logDir = "$($env:USERPROFILE)\OD_Log"
    
    # establish the path to the log file
    $global:LogFilePath = [System.IO.Path]::Combine($logDir, [string]::Format('OneDriveMigration_{0:yyyy-MM-dd_HH-mm-ss}.txt', [DateTime]::Now))
    #
    # Setup a database Connection:
    $connString = 'Data Source=FCBDD-SQL\UTILITIES; Initial Catalog=OneDriveConversion;Integrated Security=True;'
    $global:sqlConn = $null
    $global:sqlConn = [System.Data.SqlClient.SqlConnection]::new($connString)
    #
    try {
        $global:sqlConn.Open()
    }
    catch {
        # if we can't connect, we'll just move on without it
        $global:sqlConn = $null
    }
}

Invoke-VarsAndLogging

<#
################################################################################
#                                                                              #
# Log Migration Progress:                                                      #
#   If the database is available (sqlConn is not null), write there            #
#   If the database is unavailable, write to the file system                   #
#                                                                              #
################################################################################
#>
function Add-LoggingValue($messageToLog) {
    # if we can log to the database (the connection object is NOT null) let's do so
    if ($null -ne $global:sqlConn) {
        $cmdString = 'exec migration.pi_LogMessage @MigrationDate,  @MigrationUser,  @MigrationComputer, @LogMessage;'
        $sqlCmd = [System.Data.SqlClient.SqlCommand]::new($cmdString, $global:sqlConn)
        #
        $outnull = $sqlCmd.Parameters.AddWithValue('@MigrationDate', $global:datMigration)
        $outnull = $sqlCmd.Parameters.AddWithValue('@MigrationUser', $global:domainUser)
        $outnull = $sqlCmd.Parameters.AddWithValue('@MigrationComputer', $env:COMPUTERNAME)
        $outnull = $sqlCmd.Parameters.AddWithValue('@LogMessage', $messageToLog)
        #
        try {
            $outnull = $sqlCmd.ExecuteNonQuery()
        }
        catch {
            # In the event we aren't able to log this item, capture it in the local file instead
            [string]::Format('[Failed DB Write] ... {0:yyyy-MM-dd_HH-mm-ss} -> {1}', [DateTime]::Now, $messageToLog) | Out-File -FilePath $global:LogFilePath -Append
        }
    }
    else {
        # if we cannot log to the database, we'll write locally
        # format the message with a timestamp so we can see where stuff goes off the rails, how long steps take to execute, etc.
        [string]::Format('{0:yyyy-MM-dd_HH-mm-ss} -> {1}', [DateTime]::Now, $messageToLog) | Out-File -FilePath $global:LogFilePath -Append
    }
}

function Assert-OneDriveState {
    $retValue = $true; # unless told otherwise, you are GONNA execute this script!!
    #
    try {
        $Key_OneDriveSettings = 'HKCU:\SOFTWARE\Microsoft\OneDrive\Accounts\Business1'
        #
        # Does the path to the Settings key exist?
        if ( (Test-Path $Key_OneDriveSettings) -eq $true ) {
            $myValue = Get-ItemPropertyValue -Path $Key_OneDriveSettings -Name KfmFoldersProtectedNow
            #
            if ($myValue -eq 3584) {
                Add-LoggingValue -messageToLog 'This system is compliant'
                #
                $retValue = $false; # We do NOT need to go any further
            }
        }
    }
    catch {
        for ( $i = 0; $i -lt $Error.Count; $i++ ) {
            $err = $Error[$i]
            Add-LoggingValue -messageToLog $err.Exception
        }
    }
    #
    # Clear the error(s)
    $Error.Clear()
    #
    return $retValue
}

function Start-MigrationPrep() {
    #Add-LoggingValue -messageToLog "Sopping OneDrive"
    $Onedrv = Get-Process OneDrive -ea SilentlyContinue -ErrorVariable ODStop 
    switch ([bool]$Onedrv) {
        $true {
            $Onedrv | Stop-Process -Force
        }
    }
    
    $MobSync = Get-Process mobsync -ea SilentlyContinue -ErrorVariable MobStop 
    switch ([bool]$MobSync) {
        $true {
            $MobSync | Stop-Process -Force
        }
    }
}

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
        [pscustomobject]@{PropName = 'My Music' ; PropValue = "c:\Users\$env:USERNAME\Music"; PropPath = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders' }
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

function Reset-KFMuser() {
    $global:SilentBizConfig = Get-ItemPropertyValue -Path 'HKCU:\Software\Microsoft\OneDrive\' -Name 'SilentBusinessConfigCompleted' -ErrorAction SilentlyContinue -ErrorVariable SBCNull
    switch ($global:SilentBizConfig) {
        { $_ -gt 0 } {
            Set-ItemProperty -Path 'HKCU:\Software\Microsoft\OneDrive\' -Name 'SilentBusinessConfigCompleted' -Value 0 | Out-Null 
        }
        { $_ -eq 0 } {
            Continue 
        }
        { $SBCNull.Count -gt 0 } {
            New-ItemProperty -Path 'HKCU:\Software\Microsoft\OneDrive\' -Name 'SilentBusinessConfigCompleted' -PropertyType DWord -Value 0 -Force | Out-Null
        }
    }

    $global:KFMDoneValue = Get-ItemPropertyValue -Path 'HKCU:\Software\Microsoft\OneDrive\Accounts\Business1' -Name 'KfmIsDoneSilentOptIn'  -ErrorAction SilentlyContinue -ErrorVariable KFMDNull
    switch ($global:KFMDoneValue) {
        { $_ -gt 0 } {
            Remove-Item -Path 'HKCU:\Software\Microsoft\OneDrive\Accounts\Business1' -Recurse -Force -Confirm:$false | Out-Null
        }
        { $_ -eq 0 } {
            Continue 
        }
        { $KFMDNull.count -gt 0 } {
            Remove-Item -Path 'HKCU:\Software\Microsoft\OneDrive\Accounts\Business1' -Recurse -Force -Confirm:$false | Out-Null
        }
    }
}

function Get-RoboCopyConfiguration() {
    
    $csc = 'c:\Windows\csc\v2.0.6\namespace\'  
    $ShareX_FQDN = $env:HOMESHARE.Replace('\\', '')
    $ShareX_SMPL = $env:HOMESHARE.replace('.fcbmrdd.local', '').Replace('\\', '')
    $CSCRoot = [System.IO.Path]::Combine($csc, $ShareX_FQDN)

    if ((Test-Path $CSCRoot) -eq $false) {
        $CSCRoot = [System.IO.Path]::Combine($csc, $ShareX_SMPL)
    }

    $global:SwitchesCopyAll = '/COPY:DT /DCOPY:T /E /J /ETA /COMPRESS /r:0 /w:0 /MT:128 /XO /XF "~*"'
    $global:Robolog = "/LOG+:'$($global:logDir)\Robo.log'"
    
    if ((Test-Path "$($env:Onedrive)\Desktop") -eq $true) {
        $global:FinalDest = $env:Onedrive
    }
    else {
        $global:FinalDest = $env:USERPROFILE   
    }

    $global:SrcDestLap = New-Object -TypeName psobject -Property @{
        'Desktop'   = '"$($CSCRoot)\Desktop" "$($global:FinalDest)\Desktop"' 
        'Pictures'  = '"$($cscRoot)\My Documents\My Pictures" "$($global:FinalDest)\Documents\Pictures"'
        'Documents' = '"$($cscRoot)\My Documents" "$($global:FinalDest)\Documents"'
    }
    $global:SrcDestDesk = New-Object -TypeName psobject -Property @{
        'Desktop'   = '"H:\Desktop" "$($global:FinalDest)\Desktop"' 
        'Pictures'  = '"H:\My Documents\My Pictures" "$($global:FinalDest)\Documents\Pictures"'
        'Documents' = '"H:\My Documents" "$($global:FinalDest)\Documents"'
    }
}

function Copy-UsrData () {
    $Battery = gwmi win32_battery
    if ($Battery) {
        try {
            $outnull = Invoke-Expression "C:\Windows\System32\Robocopy.exe $($global:SrcDestLap.Desktop) $global:SwitchesCopyAll $global:Robolog"
            $outnull = Invoke-Expression "C:\Windows\System32\Robocopy.exe $($global:SrcDestLap.Pictures) $global:SwitchesCopyAll $global:Robolog"
            $outnull = Invoke-Expression "C:\Windows\System32\Robocopy.exe $($global:SrcDestLap.Documents) $global:SwitchesCopyAll $global:Robolog"
            $outnull = Invoke-Expression "C:\Windows\System32\Robocopy.exe $($global:SrcDestDesk.Desktop) $global:SwitchesCopyAll $global:Robolog"
            $outnull = Invoke-Expression "C:\Windows\System32\Robocopy.exe $($global:SrcDestDesk.Pictures) $global:SwitchesCopyAll $global:Robolog"
            $outnull = Invoke-Expression "C:\Windows\System32\Robocopy.exe $($global:SrcDestDesk.Documents) $global:SwitchesCopyAll $global:Robolog"
        }
        catch {
            continue
        }
    }
    else {
        try {
            $outnull = Invoke-Expression "C:\Windows\System32\Robocopy.exe $($global:SrcDestDesk.Desktop) $global:SwitchesCopyAll $global:Robolog"
            $outnull = Invoke-Expression "C:\Windows\System32\Robocopy.exe $($global:SrcDestDesk.Pictures) $global:SwitchesCopyAll $global:Robolog"
            $outnull = Invoke-Expression "C:\Windows\System32\Robocopy.exe $($global:SrcDestDesk.Documents) $global:SwitchesCopyAll $global:Robolog"
        }
        catch {
            continue
        }
    }
}

function Start-OneDrive () {
    $ExplorerProcs = Get-Process explorer
    foreach ($exp in $ExplorerProcs) {
        $exp | Stop-Process -Force | Out-Null
    }

    Start-Process 'C:\Program Files\Microsoft OneDrive\OneDrive.exe' -ArgumentList '/background' | Out-Null
} 

$global:sqlConn = $null
$global:datMigration = [datetime]::Now
$global:domainUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name; # "$($env:USERDOMAIN)\$($env:USERNAME)"

$NeedToContinue = Assert-OneDriveState

if ($NeedToContinue -eq $true) {

    Start-MigrationPrep
    
    Set-ShellRegs
    
    Reset-KFMuser

    Get-RoboCopyConfiguration

    Copy-UsrData

    Start-OneDrive

}

