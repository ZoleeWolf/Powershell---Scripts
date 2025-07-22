Import-Module ConfigurationManager

# Set the site code and connect to the site
$SiteCode = "DB1"  # Replace with your site code
Set-Location "$SiteCode`:"

# Load the input CSV
$inputFile = "D:\temp\input.txt"
$groupMappings = Import-Csv -Path $inputFile

# Function to update collections
function Update-Collections {
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
                    # Replace old group with new group
                    $newQuery = $rule.QueryExpression -replace [regex]::Escape($mapping.'Old AD Group'), $mapping.'New AD Group'
                    $newRuleName = "$prefix $($mapping.'New AD Group')"

                    # Remove old rule and add new one
                    Remove-CMCollectionQueryMembershipRule -CollectionId $collection.CollectionID -RuleName $rule.RuleName -Force
                    Add-CMCollectionQueryMembershipRule -CollectionId $collection.CollectionID -RuleName $newRuleName -QueryExpression $newQuery

                    # Rename the collection
                    $newCollectionName = "$prefix $($mapping.'New AD Group')"
                    Set-CMCollection -CollectionId $collection.CollectionID -Name $newCollectionName

                    Write-Host "Updated collection '$($collection.Name)' to '$newCollectionName'"
                }
            }
        }
    }
}

# Run for both user and device collections
Update-Collections -CollectionType "User"
Update-Collections -CollectionType "Device"






