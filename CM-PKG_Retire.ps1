$PackageID2 = 'EUW002F3'

$share = '\\SERVERNAME\U$'
$SiteCode = "CEU" # Site code
$ProviderMachineName = "SERVERNAME" # SMS Provider machine name

$log = $share + '\Retired\cleanup.txt'
$RSource = $share + '\Retired\PKG_Source\'
$RExport = $share + '\Retired\PKG_Export\'
$RADGroup = $share + '\Retired\PKG_AD_Group\'

# Site configuration
$SiteCode = "CEU" # Site code 
$ProviderMachineName = "SERVERNAME" # SMS Provider machine name

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
Set-Location "$($SiteCode):\"

$PackageID = $false
$Removable = $false
$PackageID = $PackageID2

write-host '============'
write-host '='$PackageID' ='
write-host '============'

If (Get-CMPackage -Fast -Id $PackageID)
    {
    # Remove from DP
    Remove-CMContentDistribution -PackageId $PackageID -DistributionPointName DPs -Force
    Start-Sleep 10
    # Query Package Name
    $Name = (Get-CMPackage -Fast -Id $PackageID).Name
    # Query Package Source
    $Source = (Get-CMPackage -Fast -Id $PackageID).PkgSourcePath
    # Export Package
    Export-CMPackage -FileName "$RExport$Name.zip" -Id $PackageID -Force -WithContent $false -WithDependence $false
    write-host $PackageID ' - Package Exported'
    ############################## WIP ######################################
    # Query Collections for Application to export connected AD Groups
    $Collection = $false
    $Collections = $false
    $Collections = (Get-CMPackageDeployment -PackageId $PackageID).CollectionID
    
    Foreach ($Collection in $Collections)
        {
        # Check if the collection has query based rules
        $Queries = $false
        $Queries = Get-CMUserCollectionQueryMembershipRule -CollectionId $Collection
        foreach ($Query in $Queries)
            {
            # Harvest the AD Group from the queries
            $ADGroup = $false
            $ADGroup = ($Query.Substring($Query.IndexOf('\\')+2)).trim('"'," ")
            # Check if AD group exists in AD
            $ADexist = $null
            $ADexist = Get-ADGroup -LDAPFilter "(SAMAccountName=$ADgroup)"
            if ($ADexist -ne $null)
                {
                # Export AD Group's membership
                write-host $ADgroup " - Controlled AD Group"
                Get-ADGroupMember -Identity $ADgroup | Select-Object name,objectclass | Export-Csv "$RADGroup$ADgroup.csv"
                # Check if Export was a success
                if (test-path "$RADGroup$ADgroup.csv")
                    {
                    Write-host $ADgroup " - Exported to CSV"
                    Remove-ADGroup -Identity $ADgroup -Confirm
                    }
                    else
                    {
                    Write-host $ADgroup " - Export failed AD Group will not be deleted"
                    }
                }
                else
                {
                write-host $ADgroup " - Does not exist"
                }
            else
            {
            write-host $ADgroup " - Not Controlled AD Group"
            }
        }
        }
    #########################################################################
    # Set the current location to be D:\ to copy the sources.
    Set-Location -Path "C:\"
    # Test if source exists
      if ($Source)
            {}
            else
            {$Source = "dummy"}
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
      Remove-CMPackage -Id $PackageID -Force
      write-host $PackageID ' - Package removed'
      Set-Location -Path "C:\"
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

