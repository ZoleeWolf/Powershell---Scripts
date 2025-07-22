clear

###################
# Query Hostnames #
###################

$Computers = Get-Content 'D:\temp\input.txt'

###################
# SCCM Connection #
###################

$SiteCode = "CEU"
$ProviderMachineName = "SERVERNAME"
if((Get-Module ConfigurationManager) -eq $null) {Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1"}
if((Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue) -eq $null) {New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $ProviderMachineName}
#Set-Location "$($SiteCode):\"

#####################
# Initialize script #
#####################

foreach ($Computer in $Computers)
    {
    $lineLength = $Computer.Length + 12
    $line = "=" * $lineLength
    Write-Host $line
    Write-Host ("=" * 5 + " " + $Computer + " " + "=" * 5)
    Write-Host $line

    ####################
    # Custom Variables #
    ####################

    $LogName = "Repair_CCM"
    
    #####################
    # General Variables #
    #####################

    $maxRun = 1
    $Today = Get-Date
    $date = Get-Date -Format "_yyyy-MM-dd_HH-mm-ss"
    $fixable = $false
    $log = $false

    $LogFile = "\\SERVERNAME\maintenance\"+$LogName+"_"+$Computer+$date+".log"

    $SiteCode = "CEU"
    $ManagementPoint = "CS-P-CMDMP01.consilium.eu.int"

    $ClientSource = "\\SERVERNAME\Client\*.*"
    $ClientInstall = "CCMSetup.exe /mp:$ManagementPoint /forceinstall SMSSITECODE=$SiteCode"
    
    $ccm = "\\"+$Computer+"\c$\windows\ccm"
    $ccmexe = "\\"+$Computer+"\c$\windows\ccm\ccmexec.exe"
    $ccmsetup = "\\"+$Computer+"\c$\windows\ccmsetup"
    $ccmsetupexe = "\\"+$Computer+"\c$\windows\ccmsetup\ccmsetup.exe"
    $ccmcache = "\\"+$Computer+"\c$\windows\ccmcache"
    $SMScfg = "\\"+$Computer+"\c$\Windows\smscfg.ini"
    $Windows = "\\"+$Computer+"\c$\Windows\"
    $AdminShare = "\\"+$Computer+"\c$"

    $Downloader = "\\"+$Computer+"\c$\ProgramData\application data\Microsoft\Network\Downloader"
    $SWD = "\\"+$Computer+"\c$\Windows\SoftwareDistribution"
    $Catroot = "\\"+$Computer+"\c$\Windows\System32\Catroot2"
    $WUL =  "\\"+$Computer+"\c$\Windows\WindowsUpdate.log"

    $HardwareInventoryID = '{00000000-0000-0000-0000-000000000001}'
    $SoftwareInventoryID = '{00000000-0000-0000-0000-000000000002}'
    
    ###############
    # Script body #
    ###############

    ###########
    # Logging #
    ###########

    function Write-Log
        {
        Param ([string]$LogString)
        $Stamp = (Get-Date).toString("yyyy/MM/dd HH:mm:ss")
        $LogMessage = "$Stamp $LogString"
        Add-content $LogFile -value $LogMessage
        }

    #########################
    # Check if PC is online #
    #########################

    try {if (test-connection $Computer -Count 1 -erroraction 'silentlycontinue') {$fixable = $true} else {$fixable = $false}}
    catch{$fixable = $false}
    if ($fixable) {Write-Log "PC is Online"} else {Write-Host 'PC is Offline'}

    ######################
    # Check $admin share #
    ######################

    if ($fixable)
        {
        try {if (Test-Path -Path $AdminShare -erroraction 'silentlycontinue') {$fixable = $true} else {$fixable = $false}}
        catch{$fixable = $false}
        if ($fixable) {Write-Log "Admin Share is Accessible"} else {Write-Log "Admin Share is not Accessible" ; Write-Host 'Admin Share is not Accessible' -ForegroundColor Red ; Set-Location "$($SiteCode):\" ; Add-CMDeviceCollectionDirectMembershipRule -CollectionID 'CEU0029C' -ResourceID (Get-CMDevice -Name $Computer).ResourceID ; Set-Location "C:\"}
        }

    ###############
    # Check WinRM #
    ###############

    if ($fixable)
        {
        try {if (Invoke-Command -Computer $Computer -ScriptBlock {ipconfig} -erroraction silentlycontinue) {$fixable = $true} else {Invoke-WmiMethod -ComputerName $Computer -Path win32_process -Name create -ArgumentList "powershell.exe -command Enable-PSRemoting -SkipNetworkProfileCheck -Force"}}
        catch {$fixable = $false}
        try {if (Invoke-Command -Computer $Computer -ScriptBlock {ipconfig} -erroraction silentlycontinue) {$fixable = $true} else {$fixable = $false}}
        catch {$fixable = $false}
        if ($fixable) {Write-Log "WinRM enabled"} else {Write-Log "WinRM cannot be enabled"}
        $fixable = $true
        }
    
    ############
    # Check OS #
    ############

    if ($fixable)
        {
        try {if ((Invoke-Command -Computer $Computer -ScriptBlock {Get-CimInstance -Class Win32_OperatingSystem}).ProductType -like '1') {$fixable = $true} else {$fixable = $false}}
        catch {$fixable = $true}
        if ($fixable) {Write-Log "Computer is Workstation"} else {Write-Log "Computer is NOT a Workstation"; Write-Host "Computer is NOT a Workstation" -ForegroundColor Red}
        $fixable = $true
        }

    ###################
    # Starting Script #
    ###################

    if ($fixable)
        {
        Write-Host 'Starting Repair'
        Write-Log "Checking Metered connection"
        $profiles = Invoke-Command -ComputerName $Computer -ScriptBlock { (Get-ChildItem -Path "Registry::HKEY_LOCAL_MACHINE\Software\Microsoft\Dusmsvc\Profiles").Name }
        if ($profiles -eq $null) {
            Write-Log "No LAN profiles"
        } else {
            foreach ($profile in $profiles) {
                $Name = "Registry::" + $profile + "\*"
                $key = $Name.Replace('Registry::HKEY_LOCAL_MACHINE\', '')
                $valuename = 'UserCost'
                $reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $Computer)
                $regkey = $reg.OpenSubKey($key)
                $usercost = $regkey.GetValue($valuename)
                Start-Sleep -Seconds 2
                if ($usercost -eq 0) {
                    Write-Log "LAN connection is not Metered"
                } else {
                    $Cost = $Name.Replace('Registry::HKEY_LOCAL_MACHINE\', 'HKLM:\')
                    Invoke-Command -ComputerName $Computer -ScriptBlock { Set-ItemProperty -Path $using:Cost -Name $using:valuename -Value 0 }
                    Get-Service -Name "dusmsvc" -ComputerName $Computer | Stop-Service -Force -Verbose
                    Get-Service -Name "dusmsvc" -ComputerName $Computer | Start-Service -Verbose
                    Write-Log "LAN Connection was metered"
                }
            }
        }
        $FileExistsCcm = Test-Path $ccmexe
        Write-Log "Stopping CM services"
        $services = @("ccmexec", "cmrcservice", "msmtsmgr")
        foreach ($service in $services) {
            try {
                if ((Get-Service -ComputerName $Computer -Name $service -ErrorAction SilentlyContinue).Status -eq 'Running') {
                    Invoke-Command -ComputerName $Computer -ScriptBlock { net stop $using:service }
                }
            } catch {
                Get-Process -ComputerName $Computer -Name $service | Stop-Process -Force
            }
        }
        Write-Log "CM Services Stopped"
        Start-Sleep -Seconds 20
        $FileExistsCcmSetup = Test-Path $ccmsetupexe
        if (-not $FileExistsCcmSetup) {
            New-Item -Path "\\$Computer\C$\windows\ccmsetup" -ItemType Directory -Force
            Copy-Item -Path $ClientSource -Destination "\\$Computer\C$\windows\ccmsetup"
            Write-Log "CCMSetup created and copied"
        }
        Write-Log "Uninstalling CCM Client"
        Invoke-Command -ComputerName $Computer -ScriptBlock { c:\windows\ccmsetup\CCMSetup.exe /uninstall }
        $uninstall = $false
        $i = 0
        do {
            $i += 10
            Start-Sleep -Seconds 10
            try {
                if (Get-Service -ComputerName $Computer -Name ccmsetup -ErrorAction SilentlyContinue) {
                    $uninstall = $false
                    Write-Log 'CCMSetup is still running'
                } else {
                    $uninstall = $true
                }
            } catch {
                $uninstall = $true
            }
        } until ($uninstall -or $i -ge 300)
        if (-not $uninstall) {
            Write-Log 'CCMSetup service is still running'
            Get-Process -ComputerName $Computer -Name ccmsetup | Stop-Process -Force
            Write-Log 'CCMSetup service killed'
        }
        Write-Log "Uninstalled CCM Client"
        if ($FileExistsCcm = $true)
            {
            $t = 30
            do
                {
                $Log = "Sleeping for " + $t + " seconds"
                Write-log $Log
                Start-Sleep 10
                $t = $t - 10
                }
            until ($t -le 0)
            }
        Invoke-Command -ComputerName $Computer -ScriptBlock {RUNDLL32.EXE SETUPAPI.DLL,InstallHinfSection DefaultInstall 128 C:\WINDOWS\CCM\prepdrv.inf}
        Write-Log "Repairing WMI"
	    $services = (Get-Service -Name "winmgmt" -ComputerName $Computer -DependentServices | Where-Object {$_.Status -eq "Running"}).Name
	    Get-Service -Name WinMgmt -ComputerName $Computer -DependentServices | stop-service -force -Verbose
        Invoke-Command -ComputerName $Computer -ScriptBlock {net stop winmgmt /y}
        Set-Service -Name WinMgmt -ComputerName $Computer -Status stopped -StartupType disabled
	    Write-Log "Stopped the Windows Management Instrumentation Service"
        Sleep -Seconds 10
        Write-Log "Cleaning up residual files"
        $folders = @{
            "CCM" = $ccm
            "CCMSetup" = $ccmsetup
            "CCMCache" = $ccmcache
            "SMSCFG" = $SMScfg
        }
        foreach ($folder in $folders.Keys) {
            $path = $folders[$folder]
            if (Test-Path $path) {
                Write-Log "Cleaning $folder folder"
                Remove-Item -Path $path -Force -Recurse -ErrorAction SilentlyContinue
                Write-Log "$folder folder removed"
            }
        }
        $newName = "CCM_backup"
        if (Test-Path -Path $ccm) {Rename-Item -Path $ccm -NewName $newName}
        Write-Log "Residual files deleted"
        Write-Log "Cleaning up services"
        $services = @("ccmexec", "ccmsetup", "cmrcservice", "smstsmgr")
        foreach ($service in $services) {
            if (Get-Service -ComputerName $Computer -Name $service -ErrorAction SilentlyContinue) {
                Invoke-Command -ComputerName $Computer -ScriptBlock { sc delete $using:service }
            }
        }
        Write-Log "Cleaned up Services"
        Write-Log "Cleaning up MIF files"
        $Mifs = (Get-ChildItem -path $Windows -File -Filter *.mif).Name
        foreach ($Mif in $Mifs)
            {
            $MifFile = $Windows + $Mif
            Remove-Item -Path $MifFile -Force
            }
 	    Write-Log "MIF files deleted"
        $registryPaths = @(
            "HKLM:SOFTWARE\Microsoft\SMS\",
            "HKLM:\SOFTWARE\Wow6432Node\Microsoft\SMS",
            "HKLM:SOFTWARE\Microsoft\CCM\",
            "HKLM:\SOFTWARE\Wow6432Node\Microsoft\CCM",
            "HKLM:\Software\Microsoft\CCMSetup",
            "HKLM:\Software\Wow6432Node\Microsoft\CCMSetup",
            "HKLM:\Software\Microsoft\SystemCertificates\SMS\Certificates\*",
            "HKLM:\SYSTEM\CurrentControlSet\Services\CcmExec",
            "HKLM:\SYSTEM\CurrentControlSet\Services\ccmsetup"
        )
        foreach ($path in $registryPaths) {
            if (Invoke-Command -ComputerName $Computer -ScriptBlock {Get-Item -Path $using:path -ErrorAction SilentlyContinue}) {
                Write-Log "Cleaning up registry at $path"
                Invoke-Command -ComputerName $Computer -ScriptBlock {Remove-Item -Path $using:path -Recurse -Force -ErrorAction SilentlyContinue -Verbose}
                Write-Log "Registry at $path removed"
            }
        }
	    Invoke-Command -ComputerName $Computer -ScriptBlock {Winmgmt /resetrepository}
        Write-Log "Reset the Windows Management Instrumentation"
        Set-Service -Name WinMgmt -ComputerName $Computer -Status Running -StartupType Automatic -Verbose -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 10
        Write-Log "Started the Windows Management Instrumentation Service"

        foreach ($service in $services) {
            Get-Service -Name $service -ComputerName $Computer | Start-Service -Verbose -ErrorAction SilentlyContinue
        }
        Write-Log "Started the WMI Depending Services"

        Invoke-Command -ComputerName $computer -ScriptBlock {
            $directories = @(
                "$env:windir\System32\wbem",
                "$env:windir\System32\wbem\AutoRecover"
            )

            foreach ($dir in $directories) {
                Write-Host "Processing directory: $dir"
                Get-ChildItem -Path $dir -Filter *.mof -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
                    Write-Host "Compiling: $($_.FullName)"
                    mofcomp $_.FullName
                }
                Get-ChildItem -Path $dir -Filter *.mfl -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
                    Write-Host "Compiling: $($_.FullName)"
                    mofcomp $_.FullName
                }
            }
        }
        Write-Log "Recompiled MOF files"

        New-Item -Path "\\$Computer\C$\windows\ccmsetup" -ItemType Directory -Force
        Copy-Item -Path $ClientSource -Destination "\\$Computer\C$\windows\ccmsetup" -Recurse -Force
        Write-Log "CCMSetup created and copied"

        New-Item -Path "\\$Computer\C$\temp" -ItemType Directory -Force
        Copy-Item -Path "\\CS-P-CMRDS01\Client" -Destination "\\$Computer\C$\temp" -Recurse -Force

        $RegistryPolPath = "\\$Computer\C$\Windows\System32\GroupPolicy\Machine\Registry.pol"
        if (Test-Path $RegistryPolPath) {
            Remove-Item $RegistryPolPath -Force
        }

        Invoke-Command -ComputerName $Computer -ScriptBlock { gpupdate /force }
        Start-Sleep -Seconds 2

        Invoke-Command -ComputerName $Computer -ScriptBlock {
            C:\windows\ccmsetup\ccmsetup.exe CCMHTTPPORT="80" /AllowMetered /mp:CS-P-CMDMP01.consilium.eu.int SMSSLP="CS-P-CMDMP01.consilium.eu.int" SMSSITECODE=CEU RESETKEYINFORMATION="TRUE" /forceinstall
        }
        Write-Log "CM Client installation started"
        Write-Log "Finished"
    }
}

