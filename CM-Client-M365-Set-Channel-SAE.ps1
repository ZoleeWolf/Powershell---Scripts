clear
$Computers = Get-Content 'D:\temp\input.txt'
#$Channel = 'Monthly'
#$Channel = '2021'
$Channel = 'SAE'

$IgnoreGPO = 1

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

###################
# SCCM Connection #
###################

$SiteCode = "CEU" # Site code 
$ProviderMachineName = "SERVERNAME" # SMS Provider machine name
if((Get-Module ConfigurationManager) -eq $null) {Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1"}
if((Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue) -eq $null) {New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $ProviderMachineName}
# Set-Location "$($SiteCode):\"

##### 2021 #####
    
if ($Channel -like '2021')
    {
    Write-Host "Setting Channel: 2021"
    $UpdateBranch = "PerpetualVL2021"
    $CDNBaseUrl = "http://officecdn.microsoft.com/pr/5030841d-c919-4594-8d2d-84ae4f96e58e"
    $UpdateChannel = "http://officecdn.microsoft.com/pr/5030841d-c919-4594-8d2d-84ae4f96e58e"
    $UpdateChannelChanged = "true"
    }
    
##### SAE #####
    
if ($Channel -like 'SAE')
    {
    Write-Host "Setting Channel: SAE"
    $UpdateBranch = "Deferred"
    $CDNBaseUrl = "http://officecdn.microsoft.com/pr/7ffbc6bf-bc32-4f92-8982-f9dd17fd3114"
    $UpdateChannel = "http://officecdn.microsoft.com/pr/7ffbc6bf-bc32-4f92-8982-f9dd17fd3114"
    $UpdateChannelChanged = "true"
    }

foreach ($Computer in $Computers)
    {
    $lineLength = $Computer.Length + 12  # Adjust the padding as needed
    $line = "=" * $lineLength
    Write-Host $line
    Write-Host ("=" * 5 + " " + $Computer + " " + "=" * 5)
    Write-Host $line
    
    #####################
    # General Variables #
    #####################

    $SiteCode = "CEU"
    $ManagementPoint = "CS-P-CMDMP01.consilium.eu.int"
    
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
        $good = $true

        $IgnoreGPO_reg = $false
        $UpdateBranch_reg = $false
        $CDNBaseUrl_reg = $false
        $UpdateChannel_reg = $false
        $UpdateChannelChanged_reg = $false

        
        try {
            $IgnoreGPO_reg = (Invoke-Command -ComputerName $Computer -ScriptBlock {
                Get-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\cloud\office\16.0\Common\officeupdate' -Name IgnoreGPO -ErrorAction SilentlyContinue
            }).IgnoreGPO
        } catch {
            Write-Error "Failed to retrieve IgnoreGPO: $_"
        }

        try {
            $UpdateBranch_reg = (Invoke-Command -ComputerName $Computer -ScriptBlock {
                Get-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\office\16.0\Common\officeupdate' -Name UpdateBranch -ErrorAction SilentlyContinue
            }).UpdateBranch
        } catch {
            Write-Error "Failed to retrieve UpdateBranch: $_"
        }

        try {
            $CDNBaseUrl_reg = (Invoke-Command -ComputerName $Computer -ScriptBlock {
                Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\office\ClickToRun\Configuration' -Name CDNBaseUrl
            }).CDNBaseUrl
        } catch {
            Write-Error "Failed to retrieve CDNBaseUrl: $_"
        }

        try {
            $UpdateChannel_reg = (Invoke-Command -ComputerName $Computer -ScriptBlock {
                Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\office\ClickToRun\Configuration' -Name UpdateChannel
            }).UpdateChannel
        } catch {
            Write-Error "Failed to retrieve UpdateChannel: $_"
        }

        try {
            $UpdateChannelChanged_reg = (Invoke-Command -ComputerName $Computer -ScriptBlock {
                Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\office\ClickToRun\Configuration' -Name UpdateChannelChanged
            }).UpdateChannelChanged
        } catch {
            Write-Error "Failed to retrieve UpdateChannelChanged: $_"
        }

        if ($IgnoreGPO_reg -notlike $IgnoreGPO)
            {
            write-host "IgnoreGPO is True" -ForegroundColor Green
            }
            else
            {
            write-host "IgnoreGPO is False" -ForegroundColor Red
            }
        
        write-log $UpdateBranch_reg

        if ($UpdateBranch_reg -notlike $UpdateBranch)
            {
            write-host "UpdateBranch is $UpdateBranch_reg" -ForegroundColor Red
            
            Invoke-Command -ComputerName $Computer -ScriptBlock {
                param ($UpdateBranch)
    
                $keyPath = 'HKLM:\SOFTWARE\Policies\Microsoft\office\16.0\Common\officeupdate'
                $name = 'UpdateBranch'
    
                if (-not (Test-Path $keyPath)) {
                    New-Item -Path $keyPath -Force
                }
    
                Set-ItemProperty -Path $keyPath -Name $name -Value $UpdateBranch
            } -ArgumentList $UpdateBranch

            $good = $false
            }
            else
            {
            write-host "UpdateBranch is OK" -ForegroundColor Green
            }
        
        write-log $UpdateBranch_reg

        if ($CDNBaseUrl_reg -notlike $CDNBaseUrl)
            {
            write-host "CDNBaseUrl is $CDNBaseUrl_reg" -ForegroundColor Red
            Invoke-Command -Computer $Computer -ScriptBlock {Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\office\ClickToRun\Configuration' -Name CDNBaseUrl -Value $Using:CDNBaseUrl}
            $good = $false
            }
            else
            {
            write-host "CDNBaseUrl is OK" -ForegroundColor Green
            }
            
        write-log $CDNBaseUrl_reg 

        if ($UpdateChannel_reg -notlike $UpdateChannel)
            {
            write-host "UpdateChannel is $UpdateChannel_reg" -ForegroundColor Red
            Invoke-Command -Computer $Computer -ScriptBlock {Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\office\ClickToRun\Configuration' -Name UpdateChannel -Value $Using:UpdateChannel}
            $good = $false
            }
            else
            {
            write-host "UpdateChannel is OK" -ForegroundColor Green
            }
            
        write-log $UpdateChannel_reg

        if ($good -eq $false)
            {
            if ($UpdateChannelChanged_reg -notlike $UpdateChannelChanged)
                {
                write-host "UpdateChannelChanged is $UpdateChannelChanged_reg" -ForegroundColor Red
                Invoke-Command -Computer $Computer -ScriptBlock {Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\office\ClickToRun\Configuration' -Name UpdateChannelChanged -Value $Using:UpdateChannelChanged}
                $good = $false
                }
                else
                {
                write-host "UpdateChannelChanged is OK" -ForegroundColor Green
                }
            }
            
        write-log $UpdateChannelChanged_reg


        if ($good -eq $false)
            {
            write-host "-----------------"
            write-host "Triggering inventories"
            Invoke-Command -Computer $Computer -ScriptBlock {wuauclt.exe /ResetAuthorization /DetectNow} -errorAction silentlyContinue -WarningAction silentlyContinue | Out-Null
	        Invoke-Command -Computer $Computer -ScriptBlock {wuauclt /reportnow} -errorAction silentlyContinue -WarningAction silentlyContinue | Out-Null
            Invoke-Command -Computer $Computer -ScriptBlock {UsoClient StartScan} -errorAction silentlyContinue -WarningAction silentlyContinue | Out-Null
            Invoke-Command -Computer $Computer -ScriptBlock {([wmiclass]'ROOT\ccm:SMS_Client').TriggerSchedule('{00000000-0000-0000-0000-000000000021}')} -errorAction silentlyContinue -WarningAction silentlyContinue | Out-Null
	        Invoke-Command -Computer $Computer -ScriptBlock {([wmiclass]'ROOT\ccm:SMS_Client').TriggerSchedule('{00000000-0000-0000-0000-000000000108}')} -errorAction silentlyContinue -WarningAction silentlyContinue | Out-Null
	        Invoke-Command -Computer $Computer -ScriptBlock {([wmiclass]'ROOT\ccm:SMS_Client').TriggerSchedule('{00000000-0000-0000-0000-000000000024}')} -errorAction silentlyContinue -WarningAction silentlyContinue | Out-Null
	        Invoke-Command -Computer $Computer -ScriptBlock {([wmiclass]'ROOT\ccm:SMS_Client').TriggerSchedule('{00000000-0000-0000-0000-000000000023}')} -errorAction silentlyContinue -WarningAction silentlyContinue | Out-Null
	        Invoke-Command -Computer $Computer -ScriptBlock {(New-Object -ComObject Microsoft.CCM.UpdatesStore).RefreshServerComplianceState()} -errorAction silentlyContinue -WarningAction silentlyContinue | Out-Null
            Invoke-WmiMethod -ComputerName $Computer -Namespace root\CCM -Class SMS_Client -Name TriggerSchedule -ArgumentList '{00000000-0000-0000-0000-000000000001}' -ErrorAction silentlyContinue -WarningAction silentlyContinue | Out-Null
            }
        }
    }

