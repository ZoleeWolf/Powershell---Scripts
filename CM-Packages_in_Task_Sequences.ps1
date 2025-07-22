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

(Get-CMPackage -PackageType TaskSequence).name

# Get all Regular Packages that are not predefined packages and package name not 'Configuration Manager Client Piloting Package'
    $RegularPackage = Get-CMPackage -Fast -PackageType RegularPackage | Where-Object {($_.IsPredefinedPackage -eq $false) -and ($_.Name -ne 'Configuration Manager Client Piloting Package')}
 
    # Get all Driver Packages
    $DriverPackage = Get-CMPackage -Fast -PackageType Driver
 
    # Get all Operating System Image packages
    $ImageDeploymentPackage = Get-CMPackage -Fast -PackageType ImageDeployment
 
    # Get all Operating System Upgrade packages
    $OSInstallPackagePackage = Get-CMPackage -Fast -PackageType OSInstallPackage
 
    # Get all Boot Image packages, DefaultImage=False
    $BootImagePackage = Get-CMPackage -Fast -PackageType BootImage | Where-Object {$_.DefaultImage -eq $false}
 
    # Combine all packages lists together
    $AllPackages = ($RegularPackage + $DriverPackage + $ImageDeploymentPackage + $OSInstallPackagePackage + $BootImagePackage)
 


$TaskSequences = Get-CMTaskSequence | Where-Object { $_.References -ne $null }
foreach ($TaskSequence in $TaskSequences)
    {
    foreach ($Package in $Allpackages)
        {
        if ($TaskSequence.References.Package -eq $package.PackageID)
            {Write-Host $package.PackageID -- $TaskSequence.Name}
        }
    }

