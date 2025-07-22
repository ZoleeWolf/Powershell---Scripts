$PackageID2 = 'EUW001DD'

$share = '\\SERVERNAME\U$'
$SiteCode = "CEU" # Site code
$ProviderMachineName = "SERVERNAME" # SMS Provider machine name

$log = $share + '\Retired\cleanup.txt'
$RSource = $share + '\Retired\DRV_Source\'
$RExport = $share + '\Retired\DRV_Export\'


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

$PackageID = $false
$Removable = $false
$PackageID = $PackageID2

write-host '============'
write-host '='$PackageID' ='
write-host '============'

If (Get-CMDriverPackage -Fast -Id $PackageID)
    {
    # Query Package Name
    $Name = (Get-CMDriverPackage -Fast -Id $PackageID).Name
    # Query Package Source
    $Source =(Get-CMDriverPackage -Fast -Id $PackageID).PkgSourcePath
    # Export Package
    Export-CMDriverPackage -ExportFilePath "$RExport$Name.zip" -Id $PackageID -Force -WithContent $false -WithDependence $false
    write-host $PackageID ' - Package Exported'
    #########################################################################
    # Set the current location to be D:\ to copy the sources.
    Set-Location -Path "D:\"
    # Test if source exists
    If (Test-Path -path $Source)
        {
        # Trim Pck\ from the end to copy all sources
        if ($Source -like "*Pck\") {$Source = $Source.replace("Pck\","")}
        # Move the source
        move-Item -Path $Source -Destination $RSource$Name
        write-host $PackageID ' - Source copied'
        # Check if the source is moved
        If (Test-Path -path $Source)
            {
            Write-host $PackageID ' - Source is NOT removed ' $Source
            $Removable = $false
            }
            else
            {
            write-host $PackageID ' - Source removed'
            $Removable = $true
            }
        }
        else
        {
        write-host $PackageID ' - Source does not exist'
        $Removable = $true
        }
    if ($Removable)
      {
      # Set the current location to be the site code.
      Set-Location "$($SiteCode):\"
      #Remove the Package
      Remove-CMDriverPackage -Id $PackageID -Confirm
      write-host $PackageID ' - Package removed'
      Set-Location -Path "F:\"
      $cleanup = "Package;" + $PackageID + ";" + $Name + ";" + $Source
      Add-Content -Path $log $cleanup
      }
      else
      {
      write-host $PackageID ' - Package is not removable'
      }
      
    }
    else
    {
    write-host $PackageID ' - Does not exist'
    }

