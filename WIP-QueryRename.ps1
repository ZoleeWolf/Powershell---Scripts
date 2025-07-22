Import-Module ConfigurationManager

# Set the site code and connect to the site
$SiteCode = "DB1"
Set-Location "$SiteCode`:"

# Load the input CSV
$inputFile = "D:\temp\input.txt"
$groupMappings = Import-Csv -Path $inputFile

# Function to simulate updates
function Test-Collections {
    param (
        [Parameter(Mandatory=$true)][string]$CollectionType
    )

    if ($CollectionType -eq "User") {
        $collections = Get-CMUserCollection
        $prefix = "USR CTL"
    } elseif ($CollectionType -eq "Device") {
        $collections = Get-CMDeviceCollection
        $prefix = "WKS CTL"
    } else {
        Write-Error "Invalid collection type"
        return
    }

    foreach ($collection in $collections) {
        $rules = Get-CMCollectionQueryMembershipRule -CollectionId $collection.CollectionID
        foreach ($rule in $rules) {
            foreach ($mapping in $groupMappings) {
                if ($rule.QueryExpression -like "*$($mapping.'Old AD Group')*") {
                    $newQuery = $rule.QueryExpression -replace [regex]::Escape($mapping.'Old AD Group'), $mapping.'New AD Group'

                    # Determine if names should be changed
                    $newRuleName = if ($rule.RuleName -like "*$($mapping.'Old AD Group')*") {
                        "$prefix $($mapping.'New AD Group')"
                    } else {
                        $rule.RuleName
                    }

                    $newCollectionName = if ($collection.Name -like "*$($mapping.'Old AD Group')*") {
                        "$prefix $($mapping.'New AD Group')"
                    } else {
                        $collection.Name
                    }

                    # Output
                    Write-Host "`nCollection:           `t$($collection.Name)"
                    Write-Host "New Collection Name:   `t$newCollectionName"
                    Write-Host "Original Rule Name:    `t$($rule.RuleName)"
                    Write-Host "New Rule Name:         `t$newRuleName"
                    Write-Host "Original Query:        `t$($rule.QueryExpression)"
                    Write-Host "New Query:             `t$newQuery"
                    Write-Host "------------------------------------------------------------"
                }
            }
        }
    }
}

# Run for both user and device collections
cls
Test-Collections -CollectionType "User"
Test-Collections -CollectionType "Device"






