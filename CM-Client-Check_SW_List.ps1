clear
$SWNames = ("Google Chrome", "Microsoft Edge")
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

    $LogName = "Check_SW_List"    

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
        
        $InstalledSoftware = Get-WmiObject -Class Win32_Product -ComputerName $Computer
        foreach ($SWName in $SWNames)
            {
            $SWVersion = ($InstalledSoftware | Where-Object { $_.Name -like $SWName }).Version
            if ($SWVersion)
                {
                if ($SWName -like "Google Chrome" -or $SWName -like "Microsoft Edge")
                    {
                    if ([version]$SWVersion -lt [version]"134.0")
                        {
                        Write-Host "$SWName version $SWVersion is installed on $Computer." -ForegroundColor Yellow
                        }
                        else
                        {
                        Write-Host "$SWName version $SWVersion is installed on $Computer." -ForegroundColor Green
                        }
                    Write-Log "$SWName version $SWVersion is installed on $Computer."
                    }
                    else
                    {
                    Write-Host "$SWName version $SWVersion is installed on $Computer."
                    }
                }
            else
                {
                Write-Host "$SWName is not installed on $Computer."
                Write-Log "$SWName is not installed on $Computer."
                }
            }
        Write-Log "Finished"
	    }
    }

