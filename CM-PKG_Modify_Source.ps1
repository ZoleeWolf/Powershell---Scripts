$PackageID = 'EUC0004D'

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

write-host '============'
write-host '='$PackageID' ='
write-host '============'

If (Get-CMPackage -Fast -Id $PackageID)
    {
    # Query Package Name
    $Name = (Get-CMPackage -Fast -Id $PackageID).Name.Replace(" ","_")
    $Version = (Get-CMPackage -Fast -Id $PackageID).Version
    $Destination = "\\SERVERNAME\CM_OSD$\Packages\"+$Name+"-"+$Version
    # Query Package Source
    $Source = (Get-CMPackage -Fast -Id $PackageID).PkgSourcePath
    
    $Source
    $Destination
    # Set the current location to be D:\ to copy the sources.
    Set-Location -Path "C:\"
    If (Test-Path -path $Source)
        {
        # Move the source
        Move-Item -Path $Source -Destination $Destination
        Write-Host $PackageID ' - Source copied'
        # Check if the source is moved
        If (Test-Path -path $Source)
            {
            Write-host $PackageID ' - Source is NOT removed ' $Source
            }
            else
            {
            write-host $PackageID ' - Source moved'
            }
        }

    Set-Location "$($SiteCode):\" @initParams
    Set-CMPackage -Id $PackageID -Path $Destination
              
    }
    else
    {
    write-host $PackageID ' - Does not exist'
    }

