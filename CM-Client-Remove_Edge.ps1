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
# Set-Location "$($SiteCode):\"

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

    $LogName = "Remove_Edge"
    
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
        }
    
    ############
    # Check OS #
    ############

    if ($fixable)
        {
        $OSName = 'NULL'
        try {if ((Invoke-Command -Computer $Computer -ScriptBlock {Get-ComputerInfo -Property OSName}).OSName -like 'Microsoft Windows 1*') {$fixable = $true} else {$fixable = $false}}
        catch {$fixable = $true}
        if ($fixable) {Write-Log "Computer is Workstation"} else {Write-Log "Computer is NOT a Workstation"; Write-Host "Computer is NOT a Workstation" -ForegroundColor Red}
        }

    ###################
    # Starting Script #
    ###################

    if ($fixable)
        {
        if(Get-Process -ComputerName $Computer -Name MSEdge -erroraction silentlycontinue) 
            {
            Write-Log "Edge is running"
            Write-Host "Edge is running"
            }
            else
            {
            $AppInfo = Get-WmiObject -ComputerName $Computer Win32_Product -Filter "Name like 'Microsoft Edge'"
            $EdgeVer = $AppInfo.Version
            $GUID = $false
            $GUID = $AppInfo.IdentifyingNumber
            Write-Log 'Edge is on version: '
            Write-Log  $EdgeVer

            if ($EdgeVer -lt '139.*')
                {
                # Script to grant full access to the registry key and its subkeys
                $scriptBlock = {
                    $acl = Get-Acl -Path "HKLM:\Software\Microsoft\Edge"
                    $rule = New-Object System.Security.AccessControl.RegistryAccessRule ("Everyone", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
                    $acl.SetAccessRule($rule)
                    Set-Acl -Path "HKLM:\Software\Google\Chrome" -AclObject $acl
                    }
                # Invoke the script block on the remote computer
                Invoke-Command -ComputerName $Computer -ScriptBlock $scriptBlock

                if ($GUID) {Write-Log 'Removing Edge with MSI'; Invoke-Command -ComputerName $Computer -ScriptBlock {Invoke-Expression "msiexec.exe /q /x '$using:GUID}'"}}
      
                $EdgePath32 = '\\'+$Computer+'\C$\Program Files (x86)\Microsoft\Edge\Application\'+$EdgeVer+'\Installer\'
                $EdgePath64 = '\\'+$Computer+'\C$\Program Files\Microsoft\Edge\Application\'+$EdgeVer+'\Installer\'
                $EdgePath32Setup = '\\'+$Computer+'\C$\Program Files (x86)\Microsoft\Edge\Application\'+$EdgeVer+'\Installer\setup.exe --uninstall --multi-install --Edge --system-level --force-uninstall'
                $EdgePath64Setup = '\\'+$Computer+'\C$\Program Files\Microsoft\Edge\Application\'+$EdgeVer+'\Installer\setup.exe --uninstall --multi-install --Edge --system-level --force-uninstall'

                if(Test-Path -Path $EdgePath32){Write-Log 'Removing Edge with EXE';Invoke-Command -ComputerName $Computer -ScriptBlock {Invoke-Expression $EdgePath32Setup}}
                if(Test-Path -Path $EdgePath64){Write-Log 'Removing Edge with EXE';Invoke-Command -ComputerName $Computer -ScriptBlock {Invoke-Expression $EdgePath64Setup}}

                Start-Sleep 10

                Write-Log 'Removing Edge with WMI'
                Invoke-Command -ComputerName $Computer -ScriptBlock {wmic product where "name like 'Microsoft Edge'" call uninstall /nointeractive}

                Start-Sleep 10
                                
                $EdgeRegKey = Invoke-Command -ComputerName $Computer -ScriptBlock {Get-ChildItem -Path 'HKLM:\Software\Classes\Installer\Products\' | Get-ItemProperty | Where-Object {$_.ProductName -match "Microsoft Edge"}}
                    
                if($EdgeRegKey.PSChildName)
                    {
                    Write-Log 'Removing Registry Keys'
                    $EdgeDirToDelete = "HKLM:\Software\Classes\Installer\Products\" + $EdgeRegKey.PSChildName
                    Invoke-Command -ComputerName $Computer -ScriptBlock {Remove-Item -Path $using:EdgeDirToDelete -Force -Recurse}
                    }
                Write-Log 'Cleaning up residual folders'
                $Edge32Path = '\\'+$Computer+'\C$\Program Files (x86)\Microsoft\Edge\'
                $Edge64Path = '\\'+$Computer+'\C$\Program Files\Microsoft\Edge\'

                if(Test-Path -Path $Edge32Path){Remove-Item -Path $Edge32Path -Force -Recurse;Write-Log '32 bit Edge folder remove'}
                if(Test-Path -Path $Edge64Path){Remove-Item -Path $Edge64Path -Force -Recurse;Write-Log '64 bit Edge folder remove'}
                Write-Log 'Cleanup finished'
                }
                else
                {
                Write-Log 'Edge is already updates to version:'$EdgeVer
                }
            }
        Write-Log "Finished"	    
        }
    }

