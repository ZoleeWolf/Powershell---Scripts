$ApplicationName = 'OnsiteTests_ContextSystem'

$share = '\\SERVERNAME\U$'
$SiteCode = "CEU" # Site code
$ProviderMachineName = "SERVERNAME" # SMS Provider machine name

$log = $share + '\Retired\cleanup.txt'
$RSource = $share + '\Retired\APP_Source\'
$RExport = $share + '\Retired\APP_Export\'
$RADGroup = $share + '\Retired\APP_AD_Group\'

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
$RetiringApp = $false
$RetiringApp = Get-CMApplication -Name $ApplicationName
$PackageID = $RetiringApp.PackageID

write-host '============'
write-host '='$PackageID' ='
write-host '============'

if ($RetiringApp)
    {
    # Remove from DP
    Remove-CMContentDistribution -ApplicationName $ApplicationName -DistributionPointGroupName "DPs" -Force
    Start-Sleep 10

    # Export Application
    Export-CMApplication -Name $ApplicationName -Path "$RExport$ApplicationName.zip" -IgnoreRelated -OmitContent -Force
    write-host $PackageID ' - Exported'
    # Query Source from XML
    $xml = [xml]$RetiringApp.SDMPackageXML
    $Source = $xml.AppMgmtDigest.DeploymentType.Installer.Contents.Content.Location
    # Query Collections for Application to export connected AD Groups
    $Collection = $false
    $Collections = $false
    $Collections = (Get-CMApplicationDeployment -Name $ApplicationName).TargetCollectionID

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
            if ($ADgroup -like "*(CTL)*" -or $ADgroup -like "*(LIC)*")
                {
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

                 }
            else
            {
            write-host $ADgroup " - Not Controlled AD Group"
            }
            }
        # Remove Application Deployment
        Remove-CMApplicationDeployment -Name $ApplicationName -Force
        # Remove
        if ($Collection -like 'WKS CTL*')
            {
            Remove-CMCollection -Name $Collection -Confirm
            }
            else
            {
            write-host $Collection " - Not a Controlled collection please delete manually"

            }
        }

    # Set the current location to be D:\ to copy the sources.
    Set-Location -Path "D:\"
    # Test if source exists
    If (Test-Path -path $Source)
        {
        # Trim Pck\ from the end to copy all sources
        if ($Source -like "*Pck\") {$Source = $Source.replace("Pck\","")}
        # Move the source
        move-Item -Path $Source -Destination $RSource$ApplicationName -Force
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
      #Remove the Application
      Remove-CMApplication -Name $ApplicationName -Force
      write-host $PackageID ' - Application removed'
      Set-Location -Path "D:\"
      $cleanup = "Application;" + $PackageID + ";" + $ApplicationName + ";" + $Source
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


