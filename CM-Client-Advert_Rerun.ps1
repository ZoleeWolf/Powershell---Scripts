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

    $LogName = "Advert_Rerun"
    $advertisementId = 'CEU20140'
    $advertisementIdVTC = 'CEU2014F'
    $packageId = 'CEU00144'  

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
        {
        $Empty = $False
        $CountWMI = (Get-WmiObject -ComputerName $Computer -query "SELECT * FROM CacheInfoEx" -namespace "ROOT\ccm\SoftMgmtAgent").Count
        $CountCache = (Get-ChildItem -Path \\$Computer\admin$\ccmcache).Count
        if($CountWMI -ne 0 -and $CountCache -ne 0)
            {$Empty = $True}
                
        if($Empty)
            {
            Write-Log "=========================="
            Write-Log "Cleaning starting"
            Write-Log "=========================="
            $log = 'Items in WMI: '+$CountWMI
            Write-Log $log
            $log = 'Items in Cache: '+$CountCache
            Write-Log $log
            Write-Log "=========================="

            #################
            # Cleanup Cache #
            #################

            Write-Log "Cleaning all cache items from WMI"
            Invoke-Command -ComputerName $Computer -ScriptBlock {
                [__comobject]$CCMComObject = New-Object -ComObject 'UIResource.UIResourceMgr'
                $CacheInfo = $CCMComObject.GetCacheInfo().GetCacheElements()
                ForEach ($CacheItem in $CacheInfo)
                    {
                    $null = $CCMComObject.GetCacheInfo().DeleteCacheElement([string]$($CacheItem.CacheElementID))
                    }
                }

            Invoke-Command -ComputerName $Computer -ScriptBlock {
                
                }

            ###################
            # Cleanup Orphans #
            ###################

            Write-Log "Cleaning orphaned folders"
            
            Invoke-Command -ComputerName $Computer -ScriptBlock {
                $CacheElements = get-wmiobject -query "SELECT * FROM CacheInfoEx" -namespace "ROOT\ccm\SoftMgmtAgent"
                $UsedFolders = $CacheElements | % { Select-Object -inputobject $_.Location }
                $ccmcache = 'C:\windows\ccmcache'
                Get-ChildItem($ccmcache) |  ?{ $_.PSIsContainer } | WHERE { $UsedFolders -notcontains $_.FullName } | % { Remove-Item $_.FullName -recurse ;}
                }
            ###################
            # Cleanup Folders #
            ###################

            Write-Log "Cleaning all folders"

            $CountWMI = (Get-WmiObject -ComputerName $Computer -query "SELECT * FROM CacheInfoEx" -namespace "ROOT\ccm\SoftMgmtAgent").Count
            $CountCache = (Get-ChildItem -Path \\$Computer\admin$\ccmcache).Count

            if ($CountWMI -ne 0)
                {
                $Directories = (Get-WmiObject -ComputerName $Computer -query "SELECT * FROM CacheInfoEx" -namespace "ROOT\ccm\SoftMgmtAgent").Location
                ForEach ($LocalDir in $Directories)
                    {
                    $NetworkDir = ($LocalDir).Replace("C:\","\\$Computer\c$\")
                    Remove-Item -Path $NetworkDir -Recurse -Force
                    }
                }

            ###############
            # Cleanup WMI #
            ###############
            Write-Log "Cleaning orphaned WMI entries"

            Invoke-Command -ComputerName $Computer -ScriptBlock {
                $CacheElements =  get-wmiobject -query "SELECT * FROM CacheInfoEx" -namespace "ROOT\ccm\SoftMgmtAgent"
                $ElementGroup = $CacheElements | Group-Object ContentID

                #Cleanup CacheItems where ContentFolder does not exist
                $CacheElements | where {!(Test-Path $_.Location)} | % { $_.Delete()}
                $CacheElements = get-wmiobject -query "SELECT * FROM CacheInfoEx" -namespace "ROOT\ccm\SoftMgmtAgent"

                foreach ($ElementID in $ElementGroup) 
                    {
                    if ($ElementID.Count -gt 1) 
                        {
                        $max = ($ElementID.Group.ContentVer| Measure-Object -Maximum).Maximum

                        $ElementsToRemove = $CacheElements | where {$_.contentid -eq $ElementID.Name -and $_.ContentVer-ne $Max}
                        foreach ($Element in $ElementsToRemove) 
                            {
                            Write-Log “Deleting”$Element.ContentID”with version”$Element.ContentVersion

                            Remove-Item $Element.Location -recurse
                            $Element.Delete()
                            }
                        } 
                    }
                }
            
            $CountWMI = (Get-WmiObject -ComputerName $Computer -query "SELECT * FROM CacheInfoEx" -namespace "ROOT\ccm\SoftMgmtAgent").Count
            $CountCache = (Get-ChildItem -Path \\$Computer\admin$\ccmcache).Count
            Write-Log "=========================="
            Write-Log "Cleanup Result:"
            $log = 'Items in WMI: '+$CountWMI
            Write-Log $log
            $log = 'Items in Cache: '+$CountCache
            Write-Log $log
            }
            else
            {
            Write-Log "=========================="
            Write-Log "CCMCache is empty"
            }
        
        ####################
        # Fix Stucked BITS #
        ####################
               
        Invoke-Command -ComputerName $Computer -ScriptBlock {Get-BitsTransfer -AllUsers | Where-Object { $_.JobState -like "TransientError" } | Remove-BitsTransfer}
        Invoke-Command -ComputerName $Computer -ScriptBlock {Get-BitsTransfer -AllUsers | Where-Object { $_.JobState -like "SUSPENDED" } | Resume-BitsTransfer}
        
        ################
        # Restart SCCM #
        ################

        Write-Log "=========================="
        Write-Log "Restarting CCMExec"
        Write-Log "=========================="
        Invoke-Command -ComputerName $Computer -ScriptBlock {Restart-Service -InputObject ccmexec -Force}
        Write-Log "Sleeping for 5 seconds"
        Start-Sleep -Seconds 5
        Write-Log "Requesting new Machine policy"
        Invoke-Command -ComputerName $Computer -ScriptBlock {([wmiclass]'ROOT\ccm:SMS_Client').ResetPolicy(1)}
        Invoke-Command -ComputerName $Computer -ScriptBlock {([wmiclass]'ROOT\ccm:SMS_Client').TriggerSchedule('{00000000-0000-0000-0000-000000000040}')}
        Invoke-Command -ComputerName $Computer -ScriptBlock {([wmiclass]'ROOT\ccm:SMS_Client').TriggerSchedule('{00000000-0000-0000-0000-000000000021}')}
        Write-Log "Sleeping for 10 seconds"
        Start-Sleep -Seconds 10

        
        $searchString = "$advertisementId-$packageId-*" 
        Write-Log "Triggering Advert"
        Write-Log "=========================="
        Write-Log "Getting ID of ScheduleMessage on $Computer"
        $schMsgs = Get-WmiObject -ComputerName $Computer -Namespace "root\ccm\policy\machine\actualconfig" -Class CCM_Scheduler_ScheduledMessage
        $thisMsg = $schMsgs | ? { $_.ScheduledMessageID -like $searchString } | Sort ActiveTime -Descending | select -First $maxRun
        if(!$thisMsg)
            {
            Write-Log "Cannot Find Advertisement/Package on Target Computer"
            }
            else
            {
            $thisMsg | % {

                [xml]$activeMessage = $_.activeMessage

                $amProgramId = $activeMessage.SoftwareDeploymentMessage.ProgramID
                $amAdvId = $activeMessage.SoftwareDeploymentMessage.AdvertisementID
                $amPkgId = $activeMessage.SoftwareDeploymentMessage.PackageID
                $ScheduledMessageId = $_.ScheduledMessageId

                Write-Log  "Restarting $amArogramId (ADV=$amAdvId) (PKG=$amPkgId) for Schedule Message $ScheduledMessageId"
                $softwareDist = Get-WmiObject -ComputerName $Computer -Namespace "root\ccm\policy\machine\actualconfig" -Class CCM_SoftwareDistribution -Filter "ADV_AdvertisementID = '$amAdvId' and PKG_PackageID = '$amPkgId'"
                $original_Rerun = $softwareDist.ADV_RepeatRunBehavior
            
                if($original_Rerun -ne "RerunAlways")
                    {
                    Write-Log "Changing Rerun Status from $original_Rerun to RerunAlways"
                    $softwareDist.ADV_RepeatRunBehavior = "RerunAlways"
                    $softwareDist.put() | Out-Null
                    }

                Write-Log "Triggering Schedule on $Computer"
                Invoke-WmiMethod -ComputerName $Computer -Namespace "root\ccm" -Class "SMS_CLIENT" -Name TriggerSchedule $ScheduledMessageId | Out-Null
        
                Write-Log "Sleeping for 2 seconds"
                Start-Sleep -Seconds 2

                if($original_Rerun -ne "RerunAlways") {
                    Write-Log "Changing Rerun Status back to $original_Rerun"
                    $softwareDist.ADV_RepeatRunBehavior = "$original_Rerun"
                    $softwareDist.put() | Out-Null
                }
                Write-Log "=========================="
                Write-Log "Reran Advertisement"
                }
            }
        Write-Log "Finished"
	    }
    }

