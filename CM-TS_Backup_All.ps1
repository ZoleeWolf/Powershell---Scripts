# Set the path where you want to save the exported task sequences
#$ExportPath = "\\SERVERNAME\U$\Backups\TS"
$ExportPath = "T:\Backups\TS\$(Get-Date -Format 'yyyy-MM-dd')"
New-Item -Path $ExportPath -ItemType "directory"

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

# Get all task sequences
$TaskSequences = Get-CMTaskSequence -fast

# Export each task sequence
foreach ($TS in $TaskSequences) {
    $ExportFileName = "$ExportPath\$($TS.Name)_$(Get-Date -Format 'yyyy-MM-dd').zip"
    Export-CMTaskSequence -TaskSequencePackageID $TS.PackageID -ExportFilePath $ExportFileName
    Write-Host "Exported $($TS.Name) to $ExportFileName"
}

Write-Host "Task sequences exported successfully!"

