function Start-VarsAndLogging() {
    
    switch (Test-Path 'C:\ODMIG\LOG') {
        $true {
            Continue 
        }
        $false {
            $OutNull = mkdir 'C:\ODMIG\LOG' 
        }
    }
    # establish the logging directory
    $global:logDir = 'C:\ODMIG\LOG'
    # establish the path to the log file
    $global:LogFilePath = [System.IO.Path]::Combine($logDir, [string]::Format('OneDriveMigration_{0:yyyy-MM-dd_HH-mm-ss}.log', [DateTime]::Now))
}

Start-VarsAndLogging

function logProgress($messageToLog) {

    # format the message with a timestamp so we can see where stuff goes off the rails, how long steps take to execute, etc.
    [string]::Format('{0:yyyy-MM-dd_HH-mm-ss} -> {1}', [DateTime]::Now, $messageToLog) | Out-File -FilePath $global:LogFilePath -Append
}

function Start-ODMigration() {
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

Start-ODMigration

function Enable-ODExe () {
    $ODNoSync = Get-Item 'HKLM:\Software\Policies\Microsoft\Windows\OneDrive' -ErrorAction SilentlyContinue -ErrorVariable NoSyncNull
    switch ([bool]$ODNoSync) {
        { $NoSyncNull.count -gt 1 } {
            Continue
        }
        $true {
            $OutNull = Remove-ItemProperty -Path 'HKLM:\Software\Policies\Microsoft\Windows\OneDrive' -Name 'DisableFileSyncNGSC' -Force -Confirm:$false -ErrorAction SilentlyContinue 
        }
    }
}

Enable-ODExe

function Set-AdminRegValues () {
    $pols = @(
        [pscustomobject]@{PropName = 'KFMSilentOptInDesktop' ; PropValue = 1; PropPath = 'HKLM:\SOFTWARE\Policies\Microsoft\OneDrive'; PropType = 'dword' }
        [pscustomobject]@{PropName = 'KFMSilentOptInDocuments' ; PropValue = 1; PropPath = 'HKLM:\SOFTWARE\Policies\Microsoft\OneDrive'; PropType = 'dword' }
        [pscustomobject]@{PropName = 'KFMSilentOptInPictures' ; PropValue = 1; PropPath = 'HKLM:\SOFTWARE\Policies\Microsoft\OneDrive'; PropType = 'dword' }
        [pscustomobject]@{PropName = 'SilentAccountConfig' ; PropValue = 1; PropPath = 'HKLM:\SOFTWARE\Policies\Microsoft\OneDrive'; PropType = 'dword' }
        [pscustomobject]@{PropName = 'EnableSyncAdminReports' ; PropValue = 1; PropPath = 'HKLM:\SOFTWARE\Policies\Microsoft\OneDrive'; PropType = 'dword' }
        [pscustomobject]@{PropName = 'DisableFirstDeleteDialog' ; PropValue = 1; PropPath = 'HKLM:\SOFTWARE\Policies\Microsoft\OneDrive'; PropType = 'dword' }
        [pscustomobject]@{PropName = 'EnableSendFeedback' ; PropValue = 0; PropPath = 'HKLM:\SOFTWARE\Policies\Microsoft\OneDrive'; PropType = 'dword' }
        [pscustomobject]@{PropName = 'EnableSurveyCampaigns' ; PropValue = 0; PropPath = 'HKLM:\SOFTWARE\Policies\Microsoft\OneDrive'; PropType = 'dword' }
        [pscustomobject]@{PropName = 'EnableContactSupport' ; PropValue = 0; PropPath = 'HKLM:\SOFTWARE\Policies\Microsoft\OneDrive'; PropType = 'dword' }
        [pscustomobject]@{PropName = 'GPOSetUpdateRing' ; PropValue = 5; PropPath = 'HKLM:\SOFTWARE\Policies\Microsoft\OneDrive'; PropType = 'dword' }
        [pscustomobject]@{PropName = 'KFMOptInWithWizard' ; PropValue = '33e24bf3-773d-4355-b24e-94065359d9e5'; PropPath = 'HKLM:\SOFTWARE\Policies\Microsoft\OneDrive'; PropType = 'ExpandString' }
        [pscustomobject]@{PropName = 'KFMSilentOptIn' ; PropValue = '33e24bf3-773d-4355-b24e-94065359d9e5'; PropPath = 'HKLM:\SOFTWARE\Policies\Microsoft\OneDrive'; PropType = 'ExpandString' }
    )

    $ODPols = Get-Item 'HKLM:\SOFTWARE\Policies\Microsoft\OneDrive' -ErrorAction SilentlyContinue -ErrorVariable ODPolsNul
    Switch ([bool]$ODPols) {
        { $ODPolsNul.count -gt 0 } {
            $OutNull = New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\' -Name 'OneDrive' -ItemType 'Key'
            foreach ($pol in $pols) {
                $OutNull = New-ItemProperty -Path $pol.proppath -Name $pol.PropName -Value $pol.Propvalue -PropertyType $pol.PropType -Force -ea SilentlyContinue
            }
        }
        default {
            foreach ($pol in $pols) {
                $OutNull = New-ItemProperty -Path $pol.proppath -Name $pol.PropName -Value $pol.Propvalue -PropertyType $pol.PropType -Force -ea SilentlyContinue
            }
        }
    }
}

Set-AdminRegValues

function Clear-FRandOFS() {

    $Redirection = Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\' -Recurse | Select-Object -ExpandProperty Name | Where-Object { $_ -like '*fdeploy' } 
    $OfflineFiles = Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\' -Recurse | Select-Object -ExpandProperty Name | Where-Object { $_ -like '*SyncItemLog' } 
    
    try {
        foreach ($FKey in $redirection) {
            Remove-Item -LiteralPath ($FKey).Replace('HKEY_LOCAL_MACHINE', 'HKLM:') -Recurse -Force -Confirm:$false -ea Stop
        }
    
        foreach ($SKey in $OfflineFiles) {
            Remove-Item -LiteralPath ($SKey).Replace('HKEY_LOCAL_MACHINE', 'HKLM:') -Recurse -Force -Confirm:$false -ea Stop
        }
    }
    catch {
        continue
    }    
}


function Revoke-CSC () {
    # VARs-N-Such
    $OwnProc = 'C:\Windows\System32\takeown.exe'
    $OwnArgs = '/R /A /D Y /F C:\windows\csc\v2.0.6\namespace\'
    $global:OwnDir = 'C:\windows\csc\v2.0.6\namespace\'
    $global:NewCSCDir = 'C:\FCBDD-CSC\'
    $global:cscSrcDest = '"$($global:OwnDir)" "$($global:NewCSCDir)"' 
    $global:SwitchesCopyAll = '/COPY:DT /DCOPY:T /E /J /ETA /COMPRESS /r:0 /w:0 /MT:128 /XO /XF "~*"'
    $nulOutput = [reflection.assembly]::loadwithpartialname('System.Windows.Forms') 
    $nulOutput = [reflection.assembly]::loadwithpartialname('System.Drawing')
    $notify = New-Object system.windows.forms.notifyicon
    $notify.icon = [System.Drawing.SystemIcons]::Information
    $notify.visible = $true

    # Begin modifications
    # Validate/create destination directory.
    if ((Test-Path $NewCSCDir) -eq $false) {
        $nulOutput = mkdir $NewCSCDir
    }
        
    #Take Ownership of CSC
    Try {
        # setup Notification bubble

        $OwnProc = 'C:\Windows\System32\takeown.exe'
        $OwnArgs = '/R /A /D Y /F C:\windows\csc\v2.0.6\namespace\'
        $global:OwnDir = 'C:\windows\csc\v2.0.6\namespace\'
        $CSCOwnStart = $notify.showballoontip(10, 'Beginning CSC Ownership Update', 'Changing ownership...', [system.windows.forms.tooltipicon]::Info)
        $CSCOwnStart 

        $nulOutput = Start-Process $OwnProc -ArgumentList $OwnArgs -WindowStyle Hidden -Wait -ErrorAction Stop
    }
    catch {
        Continue
    }
    
    # Backup CSC dir before database format.
    try {
        $JobSrc = Invoke-Expression "C:\Windows\System32\Robocopy.exe $global:cscSrcDest $global:SwitchesCopyAll"
        $J1 = Start-Job -ScriptBlock { $JobSrc }
        while ($J1.State -ne 'Completed') {
            Start-Sleep -Seconds 1 
        }
    }
    catch {
        Continue
    }
       
    # Set registry to format CSC Cache.
    try {
        if ((Get-ChildItem $NewCSCDir).Length -gt 0) {
            $nulOutput = New-Item -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\csc\Parameters' -Name 'FormatDatabase' -Value 1 -ItemType DWord -ea Stop
        }
    }
    catch {
        Continue

    }
}

Revoke-CSC