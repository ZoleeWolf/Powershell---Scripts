$Applications = (Get-CMApplication).LocalizedDisplayName

$share = '\\SERVERNAME\U$'
$SiteCode = "CEU" # Site code
$ProviderMachineName = "SERVERNAME" # SMS Provider machine name

$log = $share + '\Export\cleanup.txt'
$RSource = $share + '\Export\APP_Source\'
$RExport = $share + '\Export\APP_Export\'

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

foreach ($ApplicationName in $Applications)
    {
    Set-Location "$($SiteCode):\"

    write-host '============'
    write-host '='$PackageID' ='
    write-host '============'

    $PackageID = $false
    $Removable = $false
    $RetiringApp = $false
    $RetiringApp = Get-CMApplication -Name $ApplicationName
    $PackageID = $RetiringApp.PackageID

    if ($RetiringApp)
        {
        # Export Application
        Export-CMApplication -Name $ApplicationName -Path "$RExport$ApplicationName.zip" -IgnoreRelated -OmitContent -Force
        write-host $PackageID ' - Exported'
        # Query Source from XML
        $xml = [xml]$RetiringApp.SDMPackageXML
        $Source = $xml.AppMgmtDigest.DeploymentType.Installer.Contents.Content.Location
        # Query Collections for Application to export connected AD Groups
    
        # Set the current location to be D:\ to copy the sources.
        Set-Location -Path "G:\"
        # Test if source exists
        If (Test-Path -path $Source)
            {
            # Trim Pck\ from the end to copy all sources
            if ($Source -like "*Pck\") {$Source = $Source.replace("Pck\","")}
            # Copy the source
            Copy-Item -Path $Source -Destination $RSource$ApplicationName -Recurse
            write-host $PackageID ' - Source copied'
            }
            else
            {
            write-host $PackageID ' - Source does not exist'
            $Removable = $true
            }
        }
        else
        {
        write-host $PackageID ' - Does not exist'
        }
    }

