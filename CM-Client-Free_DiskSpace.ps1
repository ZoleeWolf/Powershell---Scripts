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

    $LogName = "Free_DiskSpace"    

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
        try {if ((Invoke-Command -Computer $Computer -ScriptBlock {Get-CimInstance -Class Win32_OperatingSystem}).ProductType -like '1') {$fixable = $true} else {$fixable = $false}}
        catch {$fixable = $true}
        if ($fixable) {Write-Log "Computer is Workstation"} else {Write-Log "Computer is NOT a Workstation"; Write-Host "Computer is NOT a Workstation" -ForegroundColor Red}
        }

    ###################
    # Starting Script #
    ###################

    if ($fixable)
        {
        $freeSpace = Invoke-Command -ComputerName $Computer -ScriptBlock {([wmi]"root\cimv2:Win32_logicalDisk.DeviceID='C:'").FreeSpace / 1GB
        }
        Invoke-Command -ComputerName $Computer -ScriptBlock {(([wmi]"root\cimv2:Win32_logicalDisk.DeviceID='C:'").FreeSpace/1GB).ToString("N2")+"GB"}
        if ($freeSpace -lt 20)
            {
        Write-Host "Deleting Cache - Folders"
        Invoke-Command -ComputerName $Computer -ScriptBlock {
                $CCMComObject = New-Object -ComObject 'UIResource.UIResourceMgr'
                $CacheInfo = $CCMComObject.GetCacheInfo().GetCacheElements()
                foreach ($CacheItem in $CacheInfo) {
                    $null = $CCMComObject.GetCacheInfo().DeleteCacheElement([string]$($CacheItem.CacheElementID))
                }
            }
        Invoke-Command -ComputerName $Computer -ScriptBlock {
                $CacheElements = Get-WmiObject -Query "SELECT * FROM CacheInfoEx" -Namespace "ROOT\ccm\SoftMgmtAgent"
                $UsedFolders = $CacheElements | Select-Object -ExpandProperty Location
                $ccmcache = 'C:\windows\ccmcache'
                Get-ChildItem -Path $ccmcache | Where-Object { $_.PSIsContainer } | Where-Object { $UsedFolders -notcontains $_.FullName } | Remove-Item -Recurse -Force
            }
        Write-Host "Deleting Cache - WMI"
        Invoke-Command -ComputerName $Computer -ScriptBlock {
                $CacheElements = Get-WmiObject -Query "SELECT * FROM CacheInfoEx" -Namespace "ROOT\ccm\SoftMgmtAgent"
                $ElementGroup = $CacheElements | Group-Object ContentID

                $CacheElements | Where-Object { !(Test-Path $_.Location) } | ForEach-Object { $_.Delete() }
                $CacheElements = Get-WmiObject -Query "SELECT * FROM CacheInfoEx" -Namespace "ROOT\ccm\SoftMgmtAgent"

                foreach ($ElementID in $ElementGroup) {
                    if ($ElementID.Count -gt 1) {
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
        # Get all user profiles on the remote machine
        $userProfiles = Get-WmiObject -ComputerName $Computer -Class Win32_UserProfile | Where-Object { $_.Special -eq $false -and $_.LocalPath -notlike '*ciscoacvpnuser*' }

        foreach ($profile in $userProfiles) {
            $username = $profile.LocalPath.Split('\')[-1]
    
            # Check if the user exists in Active Directory
            $userExists = Get-ADUser -Filter { SamAccountName -eq $username } -ErrorAction SilentlyContinue
    
            if (-not $userExists) {
                # If the user does not exist in Active Directory, remove the profile
                Write-Host "Removing profile for user: $username on $Computer"
                $profile.Delete()
            }
        }
        Write-Host "Emptying recycle bins"
        Invoke-Command -ComputerName $Computer -ScriptBlock {
            $shell = New-Object -ComObject Shell.Application
            $recycleBin = $shell.Namespace(0xA)  # 0xA is the Recycle Bin

            # Loop through and delete all items
            $recycleBin.Items() | ForEach-Object { $_.InvokeVerb("delete") }
        }

        Invoke-Command -ComputerName $Computer -ScriptBlock {(([wmi]"root\cimv2:Win32_logicalDisk.DeviceID='C:'").FreeSpace/1GB).ToString("N2")+"GB"}
        Write-Host "Send new HW Inventory"
        Invoke-Command -ComputerName $Computer -ScriptBlock {([wmiclass]'ROOT\ccm:SMS_Client').TriggerSchedule('{00000000-0000-0000-0000-000000000001}')} | Out-Null
        Write-Host "Starting DISM as a job"
        Invoke-Command -ComputerName $Computer -ScriptBlock {
            Dism.exe /online /Cleanup-Image /StartComponentCleanup /ResetBase
            } -AsJob | Out-Null
            }
         Write-Log "Removing Inventories from cache"
        try {
            Get-WmiObject -ComputerName $Computer -Namespace 'Root\CCM\INVAGT' -Class 'InventoryActionStatus' -Filter "InventoryActionID='$HardwareInventoryID'" -ErrorAction Stop | Remove-WmiObject
            Write-Log "Successfully removed Hardware Inventory from cache"
            }
        catch {Write-Log "Failed to remove Hardware Inventory from cache"}
        try {
            Get-WmiObject -ComputerName $Computer -Namespace 'Root\CCM\INVAGT' -Class 'InventoryActionStatus' -Filter "InventoryActionID='$SoftwareInventoryID'" -ErrorAction Stop | Remove-WmiObject
            Write-Log "Successfully removed Software Inventory from cache"
            }
        catch {Write-Log "Failed to remove Software Inventory from cache"}
        Start-Sleep -s 5
        Write-Log "=========================="
        Write-Log "Triggering new Inventories"
        try {
            Invoke-WmiMethod -ComputerName $Computer -Namespace root\CCM -Class SMS_Client -Name TriggerSchedule -ArgumentList $HardwareInventoryID -ErrorAction Stop
            Write-Log "Successfully triggered new Hardware Inventory"
            }
        catch{Write-Log "Failed to trigger new Hardware Inventory"}
        try {
            Invoke-WmiMethod -ComputerName $Computer -Namespace root\CCM -Class SMS_Client -Name TriggerSchedule -ArgumentList $SoftwareInventoryID -ErrorAction Stop
            Write-Log "Successfully triggered new Software Inventory"
            }
        catch{Write-Log "Failed to trigger new Software Inventory"}
        Write-Log "=========================="
        Write-Log "Finished"
        }
    }


