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

    $LogName = "Repair_Updates"
    
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
        try {if ((Invoke-Command -Computer $Computer -ScriptBlock {Get-CimInstance -Class Win32_OperatingSystem}).ProductType -like '1') {$fixable = $true} else {$fixable = $false}}
        catch {$fixable = $true}
        if ($fixable) {Write-Log "Computer is Workstation"} else {Write-Log "Computer is NOT a Workstation"; Write-Host "Computer is NOT a Workstation" -ForegroundColor Red}
        }

    ###################
    # Starting Script #
    ###################

    if ($fixable)
        {
        Write-Log "=========================="
	    Write-Log "Repairing starting"
	    Write-Log "=========================="
	    
        Write-Log "Stopping CCMEXEC..."
        # Stop CCMEXEC and dependent services
        Get-Service -Name ccmexec -ComputerName $Computer -DependentServices | Stop-Service -Force -Verbose

        # Check if CCMCache is empty
        $Empty = $False
        $CountWMI = (Get-WmiObject -ComputerName $Computer -Query "SELECT * FROM CacheInfoEx" -Namespace "ROOT\ccm\SoftMgmtAgent").Count
        $CountCache = (Get-ChildItem -Path \\$Computer\admin$\ccmcache).Count
        if ($CountWMI -ne 0 -and $CountCache -ne 0) {
            $Empty = $True
        }

        if ($Empty) {
            Write-Log "Cleaning starting"
            Write-Log "=========================="
            Write-Log "Items in WMI: $CountWMI"
            Write-Log "Items in Cache: $CountCache"
            Write-Log "=========================="

            Write-Log "Cleaning all cache items from WMI"
            Invoke-Command -ComputerName $Computer -ScriptBlock {
                $CCMComObject = New-Object -ComObject 'UIResource.UIResourceMgr'
                $CacheInfo = $CCMComObject.GetCacheInfo().GetCacheElements()
                foreach ($CacheItem in $CacheInfo) {
                    $null = $CCMComObject.GetCacheInfo().DeleteCacheElement([string]$($CacheItem.CacheElementID))
                }
            }

            Write-Log "Cleaning orphaned folders"
            Invoke-Command -ComputerName $Computer -ScriptBlock {
                $CacheElements = Get-WmiObject -Query "SELECT * FROM CacheInfoEx" -Namespace "ROOT\ccm\SoftMgmtAgent"
                $UsedFolders = $CacheElements | Select-Object -ExpandProperty Location
                $ccmcache = 'C:\windows\ccmcache'
                Get-ChildItem -Path $ccmcache | Where-Object { $_.PSIsContainer } | Where-Object { $UsedFolders -notcontains $_.FullName } | Remove-Item -Recurse -Force
            }

            Write-Log "Cleaning all folders"
            $Directories = (Get-WmiObject -ComputerName $Computer -Query "SELECT * FROM CacheInfoEx" -Namespace "ROOT\ccm\SoftMgmtAgent").Location
            foreach ($LocalDir in $Directories) {
                $NetworkDir = $LocalDir.Replace("C:\", "\\$Computer\c$\")
                Remove-Item -Path $NetworkDir -Recurse -Force
            }

            Write-Log "Cleaning orphaned WMI entries"
            Invoke-Command -ComputerName $Computer -ScriptBlock {
                $CacheElements = Get-WmiObject -Query "SELECT * FROM CacheInfoEx" -Namespace "ROOT\ccm\SoftMgmtAgent"
                $ElementGroup = $CacheElements | Group-Object ContentID

                $CacheElements | Where-Object { !(Test-Path $_.Location) } | ForEach-Object { $_.Delete() }
                $CacheElements = Get-WmiObject -Query "SELECT * FROM CacheInfoEx" -Namespace "ROOT\ccm\SoftMgmtAgent"

                foreach ($ElementID in $ElementGroup) {
                    if ($ElementID.Count -gt 1) {aio 
                        $Max = ($ElementID.Group.ContentVer | Measure-Object -Maximum).Maximum
                        $ElementsToRemove = $CacheElements | Where-Object { $_.ContentID -eq $ElementID.Name -and $_.ContentVer -ne $Max }
                        foreach ($Element in $ElementsToRemove) {
                            Write-Log "Deleting $($Element.ContentID) with version $($Element.ContentVersion)"
                            Remove-Item -Path $Element.Location -Recurse -Force
                            $Element.Delete()
                        }
                    }
                }
            }

            $CountWMI = (Get-WmiObject -ComputerName $Computer -Query "SELECT * FROM CacheInfoEx" -Namespace "ROOT\ccm\SoftMgmtAgent").Count
            $CountCache = (Get-ChildItem -Path \\$Computer\admin$\ccmcache).Count
            Write-Log "=========================="
            Write-Log "Cleanup Result:"
            Write-Log "Items in WMI: $CountWMI"
            Write-Log "Items in Cache: $CountCache"
            Write-Log "=========================="

            Write-Log "Restarting CCMExec"
            Invoke-Command -ComputerName $Computer -ScriptBlock { Restart-Service -Name ccmexec -Force }
            Write-Log "Sleeping for 5 seconds"
            Start-Sleep -Seconds 5
        } else {
            Write-Log "Cache is empty"
        }

        # reset windows update

        Write-Log "Stopping Windows Update Services..."

        # List of services to stop
        $services = @("BITS", "wuauserv", "appidsvc", "cryptsvc", "DoSvc")

        # Stop each service and its dependent services
        foreach ($service in $services) {
            Get-Service -Name $service -ComputerName $Computer -DependentServices | Stop-Service -Force -Verbose
        }

	    Write-Log "Removing the Software Distribution and CatRoot Folder..."
        Invoke-Command -ComputerName $Computer -ScriptBlock {
            $paths = @(
                "C:\ProgramData\Application Data\Microsoft\Network\Downloader",
                "C:\Windows\SoftwareDistribution",
                "C:\Windows\System32\Catroot2"
            )

            foreach ($path in $paths) {
                try {
                    Remove-Item -Path $path -Recurse -Force -ErrorAction Stop
                    Write-Output "Deleted: $path"
                } catch {
                    Write-Output "Failed to delete: $path - $_"
                }
            }
        }
          
        Write-Log "Checking status of Windows Update related services..."

        $services = @("BITS", "wuauserv", "appidsvc", "cryptsvc", "DoSvc")

        foreach ($service in $services) {
            try {
                $svc = Get-Service -Name $service -ComputerName $Computer -ErrorAction Stop
                Write-Log "$($svc.DisplayName) ($service) is currently: $($svc.Status)"
            } catch {
                Write-Log "Failed to retrieve status for service: $service - $_"
            }
        }

        Write-Log "Removing old Windows Update log..." 
	    Remove-Item -Path $WUL -Force -Recurse -erroraction silentlycontinue
		 
	    Write-Log "Resetting the Windows Update Services to default settings..."
        # Set security descriptors for BITS and Windows Update services
        $services = @(
            @{Name = "bits"; SD = "D:(A;;CCLCSWRPWPDTLOCRRC;;;SY)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)(A;;CCLCSWLOCRRC;;;AU)(A;;CCLCSWRPWPDTLOCRRC;;;PU)"},
            @{Name = "wuauserv"; SD = "D:(A;;CCLCSWRPWPDTLOCRRC;;;SY)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)(A;;CCLCSWLOCRRC;;;AU)(A;;CCLCSWRPWPDTLOCRRC;;;PU)"}
        )

        foreach ($service in $services) {
            Invoke-Command -ComputerName $Computer -ScriptBlock {
                param ($serviceName, $securityDescriptor)
                sc.exe sdset $serviceName $securityDescriptor
            } -ArgumentList $service.Name, $service.SD -ErrorAction SilentlyContinue
        }

		 
	    Write-Log "Registering some DLLs..."
        # List of DLLs to register
        $dlls = @(
            "atl.dll", "urlmon.dll", "mshtml.dll", "shdocvw.dll", "browseui.dll", "jscript.dll",
            "vbscript.dll", "scrrun.dll", "msxml.dll", "msxml3.dll", "msxml6.dll", "actxprxy.dll",
            "softpub.dll", "wintrust.dll", "dssenh.dll", "rsaenh.dll", "gpkcsp.dll", "sccbase.dll",
            "slbcsp.dll", "cryptdlg.dll", "oleaut32.dll", "ole32.dll", "shell32.dll", "initpki.dll",
            "wuapi.dll", "wuaueng.dll", "wuaueng1.dll", "wucltui.dll", "wups.dll", "wups2.dll",
            "wuweb.dll", "qmgr.dll", "qmgrprxy.dll", "wucltux.dll", "muweb.dll", "wuwebv.dll"
        )

        # Register each DLL
        foreach ($dll in $dlls) {
            Invoke-Command -ComputerName $Computer -ScriptBlock {regsvr32.exe /s $using:dll} -ErrorAction SilentlyContinue
        }

		Write-Log "Resetting the WinSock..."
        Invoke-Command -ComputerName $Computer -ScriptBlock { netsh winsock reset }
        Invoke-Command -ComputerName $Computer -ScriptBlock { netsh winhttp reset proxy }

        Write-Log "Delete all BITS jobs..."
        Import-Module BitsTransfer
        Invoke-Command -ComputerName $Computer -ScriptBlock {
            Get-BitsTransfer -AllUsers | Where-Object { $_.JobState -like 'TransientError' } | Remove-BitsTransfer
            Set-Item -Path WSMan:\localhost\Client\TrustedHosts -Value '*' -Force
            Get-BitsTransfer -AllUsers | Where-Object { $_.JobState -like 'SUSPENDED' } | Resume-BitsTransfer
        }

        Write-Log "Remove old GPO..."
        Invoke-Command -ComputerName $Computer -ScriptBlock {
            Remove-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Recurse
        }
        $RegistryPolPath = "\\$Computer\C$\Windows\System32\GroupPolicy\Machine\Registry.pol"
        if (Test-Path $RegistryPolPath) {
            Remove-Item $RegistryPolPath -Force
        }
        Invoke-Command -ComputerName $Computer -ScriptBlock { gpupdate.exe /Force }

        Write-Log "Starting Windows Update Services..."
        $services = @("BITS", "wuauserv", "appidsvc", "cryptsvc")
        foreach ($service in $services) {
            Set-Service -Name $service -ComputerName $Computer -Status Running -Verbose -ErrorAction SilentlyContinue
        }

        Write-Log "Forcing discovery..."
        Invoke-Command -ComputerName $Computer -ScriptBlock {
        Start-Process -FilePath "usoclient.exe" -ArgumentList "StartScan" -NoNewWindow
        Start-Sleep -Seconds 5
        Start-Process -FilePath "usoclient.exe" -ArgumentList "StartDownload" -NoNewWindow
        Start-Sleep -Seconds 5
        Start-Process -FilePath "usoclient.exe" -ArgumentList "StartInstall" -NoNewWindow
        }

        
        Write-Log "Requesting new Machine policy..."
        
        # Define the list of WMI methods to trigger
        $triggerGuids = @(
            '{00000000-0000-0000-0000-000000000040}', # Machine Policy Retrieval & Evaluation Cycle
            '{00000000-0000-0000-0000-000000000108}', # Application Deployment Evaluation Cycle
            '{00000000-0000-0000-0000-000000000024}', # Software Update Deployment Evaluation Cycle
            '{00000000-0000-0000-0000-000000000113}'  # Office 365 Client Update Cycle
        )

        # Reset policy
        Invoke-Command -ComputerName $Computer -ScriptBlock {
            ([wmiclass]'ROOT\ccm:SMS_Client').ResetPolicy(1)
        } -ErrorAction SilentlyContinue

        # Trigger each schedule
        foreach ($guid in $triggerGuids) {
            Invoke-Command -ComputerName $Computer -ScriptBlock {
                param($ScheduleId)
                ([wmiclass]'ROOT\ccm:SMS_Client').TriggerSchedule($ScheduleId)
            } -ArgumentList $guid -ErrorAction SilentlyContinue
        }

        # Refresh Office update compliance state
        Invoke-Command -ComputerName $Computer -ScriptBlock {
            try {
                $updatesStore = New-Object -ComObject Microsoft.CCM.UpdatesStore
                $updatesStore.RefreshServerComplianceState()
            } catch {
                Write-Log "Failed to refresh Office compliance state: $_"
            }
        } -ErrorAction SilentlyContinue

        }
        Write-Log "Finished"
    }

