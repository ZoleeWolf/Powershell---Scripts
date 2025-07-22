$Ring0 =   $True
$Ring1 =   $True
$Ring2 =   $True
$VTCTest = $True
$VTC =     $True

$Change =  $False

##################################################################################

$StartTime_Ring0 = (Get-Date "2024-02-01T06:00:00")
$EnforcementDeadline_Ring0 = (Get-Date "2024-02-07T12:00:00")

$StartTime_Ring1 = (Get-Date "2024-02-01T06:00:00")
$EnforcementDeadline_Ring1 = (Get-Date "2024-02-07T12:00:00")

$StartTime_Ring2 = (Get-Date "2024-02-01T06:00:00")
$EnforcementDeadline_Ring2 = (Get-Date "2024-02-07T12:00:00")

##################################################################################

$StartTime_VTCTest = (Get-Date "2024-02-01T06:00:00")
$EnforcementDeadline_VTCTest = (Get-Date "2024-02-07T12:00:00")

$StartTime_VTC = (Get-Date "2024-02-01T06:00:00")
$EnforcementDeadline_VTC = (Get-Date "2024-02-07T12:00:00")

##################################################################################

# Site configuration
$SiteCode = "CEU"
$ProviderMachineName = "SERVERNAME"

Set-Location "$($SiteCode):\"

##################################################################################

cls
Write-Host "==========================="
Write-Host "== Reschedule SW Updates =="


if ($Ring0)
    {
    Write-Host "=========================="
    Write-Host "======== Ring 0 =========="
    Write-Host "=========================="

    $deployments = Get-CMSoftwareUpdateDeployment | where {$_.TargetCollectionID -eq "CEU003F7"}
    if ($Change)
        {
        $deployments | Set-CMSoftwareUpdateDeployment -AvailableDateTime $StartTime_Ring0 SoftDeadlineEnabled $EnforcementDeadline_Ring0
        }
    Get-CMSoftwareUpdateDeployment | where {$_.TargetCollectionID -eq "CEU003F7"} | select AssignmentName,TargetCollectionID,StartTime,EnforcementDeadline | sort AssignmentName
    }

if ($Ring1)
    {
    Write-Host "=========================="
    Write-Host "======== Ring 1 =========="
    Write-Host "=========================="

    $deployments = Get-CMSoftwareUpdateDeployment | where {$_.TargetCollectionID -eq "CEU003F8"}
    if ($Change)
        {
        $deployments | Set-CMSoftwareUpdateDeployment -AvailableDateTime $StartTime_Ring1 SoftDeadlineEnabled $EnforcementDeadline_Ring0
        }
    
    Get-CMSoftwareUpdateDeployment | where {$_.TargetCollectionID -eq "CEU003F8"} | select AssignmentName,TargetCollectionID,StartTime,EnforcementDeadline | sort AssignmentName
    }

if ($Ring2)
    {
    Write-Host "=========================="
    Write-Host "======== Ring 2 =========="
    Write-Host "=========================="

    $deployments = Get-CMSoftwareUpdateDeployment | where {$_.TargetCollectionID -eq "CEU003F9"}
    if ($Change)
        {
        $deployments | Set-CMSoftwareUpdateDeployment -AvailableDateTime $StartTime_Ring2 SoftDeadlineEnabled $EnforcementDeadline_Ring0
        }
    
    Get-CMSoftwareUpdateDeployment | where {$_.TargetCollectionID -eq "CEU003F9"} | select AssignmentName,TargetCollectionID,StartTime,EnforcementDeadline | sort AssignmentName
    }

if ($VTCTest)
    {
    Write-Host "=========================="
    Write-Host "======= VTC Test ========="
    Write-Host "=========================="

    $deployments = Get-CMSoftwareUpdateDeployment | where {$_.TargetCollectionID -eq "CEU0044E"}
    if ($Change)
        {
        $deployments | Set-CMSoftwareUpdateDeployment -AvailableDateTime $StartTime_VTCTest SoftDeadlineEnabled $EnforcementDeadline_Ring0
        }
    
    Get-CMSoftwareUpdateDeployment | where {$_.TargetCollectionID -eq "CEU0044E"} | select AssignmentName,TargetCollectionID,StartTime,EnforcementDeadline | sort AssignmentName
    }

if ($VTC)
    {
    Write-Host "=========================="
    Write-Host "========= VTC  ==========="
    Write-Host "=========================="

    $deployments = Get-CMSoftwareUpdateDeployment | where {$_.TargetCollectionID -eq "CEU003FF"}
    if ($Change)
        {
        $deployments | Set-CMSoftwareUpdateDeployment -AvailableDateTime $StartTime_VTC SoftDeadlineEnabled $EnforcementDeadline_Ring0
        }
    
    Get-CMSoftwareUpdateDeployment | where {$_.TargetCollectionID -eq "CEU003FF"} | select AssignmentName,TargetCollectionID,StartTime,EnforcementDeadline | sort AssignmentName
    }

