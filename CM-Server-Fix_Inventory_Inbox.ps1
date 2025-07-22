clear

###################
# Query Hostnames #
###################

$directoryPaths = @(
    "\\SERVERNAME\SMS_CEU\inboxes\auth\dataldr.box\ToProcessMIFS\DeltaMismatch",
    "\\SERVERNAME\SMS_CEU\inboxes\auth\dataldr.box\BADMIFS\NonExistentRow",
    "\\SERVERNAME\SMS_CEU\inboxes\auth\dataldr.box\BADMIFS\MajorMismatch")

$files = @()

foreach ($directoryPath in $directoryPaths) {
    # Get all files in the directory and add them to the $files variable
    $files += Get-ChildItem -Path $directoryPath
}

# Initialize an array to store hostnames
$hostnames = @()

# Loop through each file
foreach ($file in $files) {
    # Read the content of the file
    $content = Get-Content -Path $file.FullName | Select-Object -First 20
    
    # Define the regex pattern to match hostnames
    $pattern = "NetBIOS Name\s*([\w\d]+)"
    
    # Find all matches in the content
    $matches = [regex]::Matches($content, $pattern)

    # Add each matched hostname to the array
    foreach ($match in $matches) {
        $hostnames += $match.Groups[1].Value
    }
}

# Remove duplicate hostnames
$Computers = $hostnames | Sort-Object -Unique
Write-Host "There are"($Computers).Count"computers with issues"

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
    $LogName = "Inbox_Inventory"
    

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
        Write-Log "=========================="
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

