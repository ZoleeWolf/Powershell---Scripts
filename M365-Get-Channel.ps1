clear
$Computers = Get-Content 'D:\temp\input.txt'

foreach ($Computer in $Computers)
    {
    $lineLength = $Computer.Length + 12  # Adjust the padding as needed
    $line = "=" * $lineLength
    Write-Host $line
    Write-Host ("=" * 5 + " " + $Computer + " " + "=" * 5)
    Write-Host $line
    
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

    #####################
    # General Variables #
    #####################

    $SiteCode = "CEU"
    $ManagementPoint = "CS-P-CMDMP01.consilium.eu.int"

    $ClientSource = "\\SERVERNAME\Client\ccmsetup.exe"
    $ClientInstall = "CCMSetup.exe /mp:$ManagementPoint /forceinstall SMSSITECODE=$SiteCode"

    $ccm = "\\"+$Computer+"\c$\windows\ccm"
    $ccmexe = "\\"+$Computer+"\c$\windows\ccm\ccmexec.exe"
    $ccmsetup = "\\"+$Computer+"\c$\windows\ccmsetup"
    $ccmsetupexe = "\\"+$Computer+"\c$\windows\ccmsetup\ccmsetup.exe"
    $ccmcache = "\\"+$Computer+"\c$\windows\ccmcache"
    $SMScfg = "\\"+$Computer+"\c$\Windows\smscfg.ini"
    $Windows = "\\"+$Computer+"\c$\Windows\"
    $AdminShare = "\\"+$Computer+"\c$"

    $maxRun = 1
    $Today = Get-Date
    $date = Get-Date -Format "_yyyy-MM-dd_HH-mm-ss"
    $fixable = $false
    $log = $false

    ####################
    # Custom Variables #
    ####################
        
    $LogFile = "\\SERVERNAME\maintenance\M365_"+$Computer+$date+".log"

    #########################
    # Check if PC is online #
    #########################

    try {if (test-connection $Computer -Count 1 -erroraction 'silentlycontinue') {$fixable = $true} else {$fixable = $false}}
    catch{$fixable = $false}
    if ($fixable) {Write-Log "PC is Online"} else {Write-Host 'PC is Offline'}

    # Check is $admin share is available

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

    if ($fixable)
        {
        $IgnoreGPO_reg = $false
        $UpdateBranch_reg = $false
        $CDNBaseUrl_reg = $false
        $UpdateChannel_reg = $false
        $UpdateChannelChanged_reg = $false

        $IgnoreGPO_reg = (Invoke-Command -ComputerName $Computer -ScriptBlock {Get-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\cloud\office\16.0\Common\officeupdate' -Name IgnoreGPO -ErrorAction SilentlyContinue}).IgnoreGPO
        $UpdateBranch_reg = (Invoke-Command -Computer $Computer -ScriptBlock {Get-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\office\16.0\Common\officeupdate' -Name UpdateBranch}).UpdateBranch
        $CDNBaseUrl_reg = (Invoke-Command -Computer $Computer -ScriptBlock {Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\office\ClickToRun\Configuration' -Name CDNBaseUrl}).CDNBaseUrl
        $UpdateChannel_reg = (Invoke-Command -Computer $Computer -ScriptBlock {Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\office\ClickToRun\Configuration' -Name UpdateChannel}).UpdateChannel
        $UpdateChannelChanged_reg = (Invoke-Command -Computer $Computer -ScriptBlock {Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\office\ClickToRun\Configuration' -Name UpdateChannelChanged}).UpdateChannelChanged

        $IgnoreGPO_reg
        $UpdateBranch_reg
        $CDNBaseUrl_reg
        $UpdateChannel_reg
        $UpdateChannelChanged_reg
        }
    }

