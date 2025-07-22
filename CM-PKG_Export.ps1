$Packages = (Get-CMPackage -Fast).PackageID

$share = '\\SERVERNAME\U$'
$SiteCode = "CEU" # Site code
$ProviderMachineName = "SERVERNAME" # SMS Provider machine name

$log = $share + '\Export\cleanup.txt'
$RSource = $share + '\Export\PKG_Source\'
$RExport = $share + '\Export\PKG_Export\'

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

foreach ($Package in $Packages)
    {
    Set-Location "$($SiteCode):\"
    write-host '============'
    write-host '='$Package' ='
    write-host '============'
    
    $Name = (Get-CMPackage -Fast -Id $Package).Name
    write-host $Package ' -'$Name
    write-host $Package ' - Exporting Task Sequence...'
    Export-CMPackage -FileName $RExport$Name.zip -Id $Package -Force -WithContent $false -WithDependence $false
    write-host $Package ' - Package Exported'

    # Query Package Source
    $Source = (Get-CMPackage -Fast -Id $Package).PkgSourcePath
    # Set the current location to be D:\ to copy the sources.
    Set-Location -Path "G:\"
    # Test if source exists
      if ($Source)
            {}
            else
            {$Source = "dummy"}
    If (Test-Path -path $Source)
        {
        # Move the source
        copy-Item -Path $Source -Destination $RSource$Name -Recurse
        write-host $PackageID ' - Source copied'
        }
        else
        {
        write-host $PackageID ' - Source does not exist'
        }

    }

