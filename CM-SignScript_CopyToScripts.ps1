clear
$AppNames = @("Adobe_After_Effects","Adobe_Bridge","Adobe_Captivate","Adobe_Character_Animator","Adobe_Illustrator","Adobe_InCopy","Adobe_InDesign","Adobe_Media_Encoder","Adobe_Photoshop","Adobe_Premier_Pro")

foreach ($AppName in $AppNames)
    {
    Write-Host "=========================="
    Write-Host "======= $AppName ======="
    Write-Host "=========================="
        
    # Variables 
    
    $date = Get-Date -Format "_yyyy-MM-dd_HH-mm-ss"
    $LogFile = "\\SERVERNAME\Maintenance\SignPowershell_"+$Appname+$date+".log"
    $log = $false
    $SourceApp = "\\SERVERNAME\CM_Sources$\Applications\"
    $DestinationApp = "\\consilium\dfs\Temporary9days\vdi\scripts\"

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
        
    $Source = $SourceApp + $AppName + "\Deploy-Application.ps1"
    $Destination = $DestinationApp + $AppName + ".ps1"
    $ControlFile = $DestinationApp + $AppName + ".control"
        
    if (-not(get-item $Destination -ErrorAction SilentlyContinue)) {Copy-Item -Path $Source -Destination $Destination}
    if (-not(get-item $ControlFile -ErrorAction SilentlyContinue)) {New-Item -Path $ControlFile -ItemType File}

    }

