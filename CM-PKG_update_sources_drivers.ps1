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

$Package = Get-CMPackage -Fast -PackageType RegularPackage | Where-Object {$_.PackageID -Like 'CEU001FC'}
$Name = $Package.MIFName
$Manufacturer = $Package.Manufacturer
$ID = $Package.PackageID
Write-Host '=============================='
Write-Host $Package.Name - $Package.PackageID
Set-Location "CEU:\"
$Destination = '\\SERVERNAME\CM_OSD$\Packages\HP\Zbook Fury 16 G10 Mobile Workstation PC\Windows11-23H2-x64-3.00 A 1\StandardPkg'
$CMSource = '\\SERVERNAME\CM_OSD$\Packages\'+$Manufacturer+'\'+$Name+'\Windows11-23H2-x64-3.00 A 1\StandardPkg'
Set-Location "C:\"
# Create new folder
New-Item -ItemType Directory -Force -Path  $Destination -erroraction 'silentlycontinue'
# Copy source to new folder
Copy-Item -Path $Source* -Container -Destination $Destination -Recurse -erroraction 'silentlycontinue'
Set-Location "CEU:\"

Set-CMPackage -Id $ID -Path $CMSource
Write-Host $CMSource
Write-Host '=============================='

