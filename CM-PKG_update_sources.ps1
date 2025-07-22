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

$Packages = Get-CMPackage -Fast -PackageType RegularPackage | Where-Object {$_.PackageID -Like 'CEU*' -and $_.PkgSourcePath -notlike "" -and $_.PkgSourcePath -notlike "\\SERVERNAME*"}
#$Packages = Get-CMPackage -Fast -Name BIOS* -PackageType RegularPackage

foreach ($Package in $Packages)
    {
    $Name = $Package.Name
    $Version = $Package.Version
    $ID = $Package.PackageID
    Write-Host '=============================='
    Write-Host $Package.Name - $Package.PackageID
    if ((Get-CMPackage -Fast -Name $Name).PkgSourcePath)
        {
        Set-Location "CEU:\"
        $Source = (Get-CMPackage -Fast -ID $ID).PkgSourcePath + '\'
        $Destination = '\\SERVERNAME\CM_Sources$\Packages\' + $Name + '_' + $Version
        $CMSource = '\\SERVERNAME\CM_Sources$\Packages\' + $Name + '_' + $Version
        if ($Source -NotLike '\\SERVERNAME*')
            {
            Set-Location "C:\"
            New-Item -ItemType Directory -Force -Path  $Destination -erroraction 'silentlycontinue'
            Copy-Item -Path $Source* -Container -Destination $Destination -Recurse -erroraction 'silentlycontinue'
    
            Set-Location "CEU:\"
            Set-CMPackage -Id $ID -Path $CMSource
            }
            else
            {write-host 'Source already moved'}
        }
    Write-Host $CMSource
    Write-Host '=============================='
    }

