clear
$Computers = get-content 'C:\temp\input.txt'

foreach ($Computer in $Computers)
    {
    Write-Host "=========================="
    Write-Host "======= $Computer ======="
    Write-Host "=========================="
        
    # Variables 
    
    $Source = "\\cs-p-sccas01\g$\W10software_repository\USU\PSADT-Winzip-v25\SupportFiles\Winzip.lnk"
    $Destination = "\\"+$Computer+"\c$\ProgramData\Microsoft\Windows\Start Menu\Programs"
    $AdminShare = "\\"+$Computer+"\c$"
    $date = Get-Date -Format "_yyyy-MM-dd_HH-mm-ss"
    $LogFile = "\\CS-P-SCPRW01.consilium.eu.int\ClientRepair\FixWinzip_"+$Computer+$date+".log"
    $fixable = $false
    $log = $false

    function Write-Log
        {
        Param ([string]$LogString)
        $Stamp = (Get-Date).toString("yyyy/MM/dd HH:mm:ss")
        $LogMessage = "$Stamp $LogString"
        Add-content $LogFile -value $LogMessage
        }

    # Check if PC is online

    $fixable = $false
    try {if (test-connection $Computer -Count 1 -erroraction 'silentlycontinue') {$fixable = $true} else {$fixable = $false}}
    catch{$fixable = $false}
    if ($fixable) {Write-Log "PC is Online"} else {Write-Host "PC is Offline"}

    # Check is $admin share is available

    if ($fixable)
        {
        try {if (Test-Path -Path $AdminShare -erroraction 'silentlycontinue') {$fixable = $true} else {$fixable = $false}}
        catch{$fixable = $false}
        Write-Log "=========================="
        if ($fixable) {Write-Log "Admin Share is Accessible"} else {Write-Log "Admin Share is not Accessible"}
        }

    # Check WinRM

    if ($fixable)
        {
        $EnableRemoting = Invoke-WmiMethod -ComputerName $Computer -Path win32_process -Name create -ArgumentList "powershell.exe -command Enable-PSRemoting -SkipNetworkProfileCheck -Force"
        try {if (Invoke-Command -Computer $Computer -ScriptBlock {ipconfig} -erroraction silentlycontinue) {$fixable = $true} else {$EnableRemoting}}
        catch{$fixable = $false}
        try {if (Invoke-Command -Computer $Computer -ScriptBlock {ipconfig} -erroraction silentlycontinue) {$fixable = $true} else {$fixable = $false}}
        catch{$fixable = $false}
        Write-Log "=========================="
        if ($fixable) {Write-Log "WinRM enabled"} else {Write-Log "WinRM cannot be enabled"}
        }
    
    # StartCleanup
    
    if($fixable)
        {
        Copy-Item -Path $Source -Destination $Destination -Force
        Write-Log "Shortcut copied"
        }
    }

