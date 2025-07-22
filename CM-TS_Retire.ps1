$TaskSequenceID2 = 'CEU001A0'

$share = '\\SERVERNAME\U$'
$SiteCode = "CEU" # Site code
$ProviderMachineName = "SERVERNAME" # SMS Provider machine name

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

$log = $share + '\Retired\cleanup.txt'
$RExport = $share + '\Retired\TS_Export\'

$TaskSequenceID = $false
$Removable = $false
$TaskSequenceID = $TaskSequenceID2

write-host '============'
write-host '='$TaskSequenceID' ='
write-host '============'

If (Get-CMTaskSequence -TaskSequencePackageId $TaskSequenceID -Fast)
    {
    Set-Location "$($SiteCode):\"
    # Query Task Sequence Name
    $Name = (Get-CMTaskSequence -Fast -Id $TaskSequenceID).Name
    write-host $TaskSequenceID ' -'$Name
    # Export Task Sequence
    write-host $TaskSequenceID ' - Exporting Task Sequence...'
    Export-CMTaskSequence -ExportFilePath $RExport$Name.zip -TaskSequencePackageId $TaskSequenceID -Force -WithContent $false -WithDependence $false
    write-host $TaskSequenceID ' - Task Sequence Exported'
    #Remove the Task Sequence
    Remove-CMTaskSequence -TaskSequencePackageId $TaskSequenceID
    write-host $TaskSequenceID ' - Task Sequence Removed'
    Set-Location -Path "C:\"
    $cleanup = "TaskSequence;" + $TaskSequenceID + ";" + $Name + ";" + $Source
    Add-Content -Path $log $cleanup
    Set-Location "$($SiteCode):\"
    }
    else
    {
    write-host $TaskSequenceID ' - Does not exist'
    }

