cls

#########################################

# Site configuration
$SiteCode = "CEU"
$ProviderMachineName = "SERVERNAME"

Set-Location "$($SiteCode):\"

#########################################

Write-Host "=========================="
Write-Host "== Disabling SW Updates =="
Write-Host "=========================="

# Get all Software Update Deployments
$deployments = Get-CMSoftwareUpdateDeployment

# Initialize counters
$enabledCount = 0
$disabledCount = 0

# Count enabled and disabled deployments
foreach ($deployment in $deployments)
    {
    if ($deployment.Enabled)
        {
        $enabledCount++
        }
        else
        {
        $disabledCount++
        }
    }

# Output the counts
Write-Host "======== Before =========="
Write-Host "=========================="
Write-Output "Enabled Deployments: $enabledCount"
Write-Output "Disabled Deployments: $disabledCount"
Write-Host "=========================="

# Disable each deployment
$deployments = $deployments | Where-Object { $_.Enabled -eq $True }
$deployments | select AssignmentName,Enabled | sort Enabled,AssignmentName
$deployments | Set-CMSoftwareUpdateDeployment -Enable $false

# Initialize counters
$enabledCount = 0
$disabledCount = 0

$deployments = Get-CMSoftwareUpdateDeployment

# Count enabled and disabled deployments
foreach ($deployment in $deployments)
    {
    if ($deployment.Enabled)
        {
        $enabledCount++
        }
        else
        {
        $disabledCount++
        }
    }

# Output the counts
Write-Host "========= After =========="
Write-Host "=========================="
Write-Output "Enabled Deployments: $enabledCount"
Write-Output "Disabled Deployments: $disabledCount"
Write-Host "=========================="

Write-Output "All Software Update Deployments have been disabled."

