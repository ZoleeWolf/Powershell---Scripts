clear
# Site configuration
$SiteCode = "CEU" # Site code 
$ProviderMachineName = "SERVERNAME" # SMS Provider machine name

# Customizations
$initParams = @{}
#$initParams.Add("Verbose", $true) # Uncomment this line to enable verbose logging
#$initParams.Add("ErrorAction", "Stop") # Uncomment this line to stop the script on any errors

# Do not change anything below this line

# Import the ConfigurationManager.psd1 module 
if((Get-Module ConfigurationManager) -eq $null) {
    Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1" @initParams 
}

# Connect to the site's drive if it is not already present
if((Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue) -eq $null) {
    New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $ProviderMachineName @initParams
}

# Set the current location to be the site code.
Set-Location "$($SiteCode):\" @initParams

$Applications = Get-CMApplication
foreach ($Application in $Applications)
    {
    $AppMgmt = ([xml]$Application.SDMPackageXML).AppMgmtDigest
    $AppName = $Application.LocalizedDisplayName
    foreach ($DeploymentType in $AppMgmt.DeploymentType)
        {
        Write-Host '=============================='
        $AppName
        $Source = $DeploymentType.Installer.Contents.Content.Location
        $Destination = '\\SERVERNAME\CM_Sources$\Applications\' + $AppName
        $CMSource = $Destination
        if ($Source -NotLike '\\SERVERNAME*')
            {
            Write-Host '=============================='
            $source
            Write-Host '=============================='
            sleep 5
            Set-Location "C:\"
            New-Item -ItemType Directory -Force -Path  $Destination -erroraction 'silentlycontinue'
            Copy-Item -Path $Source* -Container -Destination $Destination -Recurse -erroraction 'silentlycontinue'
            Set-Location "$($SiteCode):\" @initParams
            $DTName = ($Application | Get-CMDeploymentType).LocalizedDisplayName
            if ((Get-CMDeploymentType -ApplicationName $Appname -DeploymentTypeName $DTName).Technology -like 'MSI')
                {
                Set-CMMsiDeploymentType -ApplicationName $Appname -DeploymentTypeName $DTName -ContentLocation $CMSource
                }
                else
                {
                Set-CMScriptDeploymentType -ApplicationName $Appname -DeploymentTypeName $DTName -ContentLocation $CMSource
                }
            
            }
            else
            {write-host 'Source already good'}
        }
    }

