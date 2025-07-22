clear
$folder = "\\consilium\dfs\Temporary9days\vdi\scripts\"
$AppNames = (Get-ChildItem -Path $folder -Filter *.control).BaseName

foreach ($AppName in $AppNames)
    {
    Write-Host "=========================="
    Write-Host "======= $AppName ======="
    Write-Host "=========================="
        
    # Variables 
    
    $date = Get-Date -Format "_yyyy-MM-dd_HH-mm-ss"
    $LogFile = "\\SERVERNAME\Maintenance\SignPowershell_"+$Appname+$date+".log"
    $log = $false
    $DestinationApp = "\\SERVERNAME\CM_Sources$\Applications\"
    $SourceApp = "\\consilium\dfs\Temporary9days\vdi\scripts\"

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

    ##########
    # Script #
    ##########
        
    $Source = $SourceApp + $AppName + ".ps1"
    $Destination = $DestinationApp + $AppName + "\Deploy-Application.ps1"
    $ControlFile = $SourceApp + $AppName + ".control"
    $Backup = "Deploy-Application_"+$date+".ps1"

    $Source
    $Destination   
    $ControlFile

    #if (-not(get-item $Destination)) {Copy-Item -Path $Source -Destination $Destination}
    Rename-Item -NewName $Backup -Path $Destination -Force
    Copy-Item -Path $Source -Destination $Destination
    if ($Destination) {Remove-Item -Path $Source -Force}
    if ($Destination) {Remove-Item -Path $ControlFile -Force}
    }

