clear
$Computers = get-content 'D:\temp\input.txt'

$Today = Get-Date
$date = Get-Date -Format "_yyyy-MM-dd_HH-mm-ss"
$LogFile = "\\SERVERNAME\maintenance\WinZip_LicenseFix"+$date+".log"

    function Write-Log
        {
        Param ([string]$LogString)
        $Stamp = (Get-Date).toString("yyyy/MM/dd HH:mm:ss")
        $LogMessage = "$Stamp $LogString"
        Add-Content -Path $LogFile -Value $LogMessage
        }


foreach ($Computer in $Computers)
    {
    #Write-Host "=========================="
    #Write-Host "======= $Computer ======="
    #Write-Host "=========================="
        
    
    #####################
    # General Variables #
    #####################

    $SiteCode = "CEU"
    $ManagementPoint = "CS-P-CMDMP01.consilium.eu.int"
    
    $Windows = "\\"+$Computer+"\c$\Windows\"
    $AdminShare = "\\"+$Computer+"\c$"

    $maxRun = 1
    $fixable = $false
    $log = $false

    ####################
    # Custom Variables #
    ####################
    
    

    # Check if PC is online

    $fixable = $false
    try {if (test-connection $Computer -Count 1 -erroraction 'silentlycontinue') {$fixable = $true} else {$fixable = $false}}
    catch{$fixable = $false}
    if ($fixable) {} else {Write-Log "$Computer - PC is Offline";Write-Host $Computer" - Offline" -ForegroundColor Yellow}

    # StartCleanup
    
    if($fixable)
        {
        $Destination = "\\"+$Computer+"\C$\ProgramData\Winzip\Winzip.wzmul"
        $targetDate = Get-Date "2024-10-24 11:20:02.7213932"
        if ((Get-Item -Path $Destination).LastWriteTime -ne $targetDate)
            {
            Write-Host $Computer" - License is not correct" -ForegroundColor Red
            Write-Log "$Computer - Copied License File"
            Copy-Item -Path "\\SERVERNAME\CM_Sources$\PmPM_other\Winzip.wzmul" -Destination $Destination -Force
            }
            else
            {
            Write-Host $Computer" - OK" -ForegroundColor Green
            Write-Log "$Computer - License OK"
            }
        

        $Destination = "\\"+$Computer+"\C$\ProgramData\Microsoft\Windows\Start Menu\Programs\Winzip\Winzip.lnk"
        $targetDate = Get-Date "2024-10-24 11:20:02.6901388"

        $folderPath = "\\$Computer\C$\ProgramData\Microsoft\Windows\Start Menu\Programs\Winzip"

        if (-Not (Test-Path -Path $folderPath))
            {
            New-Item -ItemType Directory -Path $folderPath
            Write-Log "$Computer - Folder created at $folderPath"
            Copy-Item -Path "\\SERVERNAME\CM_Sources$\PmPM_other\Winzip.lnk" -Destination $Destination -Force
            Write-Log "$Computer - Copied Shortcut File"
            }

        if ((Get-Item -Path $Destination).LastWriteTime -ne $targetDate)
            {
            Write-Log "$Computer - Copied Shortcut File"
            Copy-Item -Path "\\SERVERNAME\CM_Sources$\PmPM_other\Winzip.lnk" -Destination $Destination -Force
            }
            else
            {
            Write-Log "$Computer - Shortcut OK"
            }
        }
    }

