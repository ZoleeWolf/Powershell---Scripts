$TaskSequences = (Get-CMTaskSequence -Fast).PackageID

$share = '\\SERVERNAME\U$'
$SiteCode = "EUC" # Site code
$ProviderMachineName = "CS-P-SCCAS01" # SMS Provider machine name

$log = $share + '\Export\cleanup.txt'
$RExport = $share + '\Export\TS_Export\'

$TaskSequenceID = $false
$Removable = $false
$TaskSequenceID = $TaskSequenceID2

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

foreach ($TaskSequence in $TaskSequences)
    {
    write-host '============'
    write-host '='$TaskSequence' ='
    write-host '============'
    
    $Name = (Get-CMTaskSequence -Fast -Id $TaskSequence).Name
    write-host $TaskSequence ' -'$Name
    write-host $TaskSequence ' - Exporting Task Sequence...'
    Export-CMTaskSequence -ExportFilePath $RExport$Name.zip -TaskSequencePackageId $TaskSequence -Force -WithContent $false -WithDependence $false
    write-host $TaskSequence ' - Task Sequence Exported'

    }

