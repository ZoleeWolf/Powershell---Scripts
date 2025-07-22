# Define the SCCM site server and site code
$SiteServer = "SERVERNAME"
$SiteCode = "CEU"

# Import the SCCM module
Import-Module "$($Env:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1"

# Connect to the SCCM site
Set-Location "$($SiteCode):"

# Get the current date and the date three months ago
$CurrentDate = Get-Date
$ThreeMonthsAgo = $CurrentDate.AddMonths(-3)
$OneMonthAgo = $CurrentDate.AddMonths(-1)

# Get all Software Update Groups
$AllSUGs = Get-CMSoftwareUpdateGroup | Where-Object {$_.LocalizedDisplayName -ne "Browser Updates" -and $_.LocalizedDisplayName -notlike "*General"}

# Filter out SUGs older than three months
$RecentSUGs = $AllSUGs | Where-Object {
    $SUGDate = $_.LocalizedDisplayName -match "\d{4}-\d{2}"
    $SUGYear = [int]$Matches[0].Substring(0, 4)
    $SUGMonth = [int]$Matches[0].Substring(5, 2)
    $SUGDate = Get-Date -Year $SUGYear -Month $SUGMonth -Day 1
    $SUGDate -ge $ThreeMonthsAgo
}

# Filter out SUGs created in the current month
$CurrentMonthSUGs = $RecentSUGs | Where-Object {
    $SUGDate = $_.LocalizedDisplayName -match "\d{4}-\d{2}"
    $SUGYear = [int]$Matches[0].Substring(0, 4)
    $SUGMonth = [int]$Matches[0].Substring(5, 2)
    $SUGDate = Get-Date -Year $SUGYear -Month $SUGMonth -Day 1
    $SUGDate -ge $OneMonthAgo
}

# Group SUGs by their base name (excluding month and year)
$GroupedSUGs = $RecentSUGs | Group-Object { $_.LocalizedDisplayName -replace "\s\d{4}-\d{2}$", "" }

foreach ($SUG in $RecentSUGs) {
    # Get updates in the SUG
    $Updates = Get-CMSoftwareUpdate -UpdateGroupName $SUG.LocalizedDisplayName -Fast
    foreach ($Update in $Updates) {
        if ($Update.IsExpired) {
            # Remove expired updates from the SUG
            Remove-CMSoftwareUpdateFromGroup -SoftwareUpdateGroupName $SUG.LocalizedDisplayName -SoftwareUpdateId $Update.CI_ID -Force
            Write-Host "=============================="
            Write-Host "Removed expired update: $($Update.LocalizedDisplayName) from $($SUG.LocalizedDisplayName)"
        }
    }
}

foreach ($Group in $GroupedSUGs) {
    # Define the General SUG name
    $GeneralSUGName = "$($Group.Name) - General"

    # Check if the General SUG already exists
    $ExistingGeneralSUG = Get-CMSoftwareUpdateGroup -Name $GeneralSUGName -ErrorAction SilentlyContinue

    if (-not $ExistingGeneralSUG) {
        # Create a new General SUG for the merged updates
        $GeneralSUG = New-CMSoftwareUpdateGroup -Name $GeneralSUGName
    } else {
        Write-Host "=============================="
        Write-Host "Software Update Group '$GeneralSUGName' already exists. Adding updates to it."
        Write-Host "=============================="
        $GeneralSUG = $ExistingGeneralSUG
    }

    # Get updates in the current month SUGs
    $CurrentMonthUpdates = $CurrentMonthSUGs | ForEach-Object { Get-CMSoftwareUpdate -UpdateGroupName $_.LocalizedDisplayName -Fast }

    # Add updates from each SUG in the group to the General SUG if they are not in the current month SUGs
    foreach ($SUG in $Group.Group) {
        $Updates = Get-CMSoftwareUpdate -UpdateGroupName $SUG.LocalizedDisplayName -Fast
        foreach ($Update in $Updates) {
            if (-not ($CurrentMonthUpdates | Where-Object { $_.CI_ID -eq $Update.CI_ID })) {
                Add-CMSoftwareUpdateToGroup -SoftwareUpdateGroupName $GeneralSUGName -SoftwareUpdateId $Update.CI_ID
                Write-Host "Added the following Update: $($Update.LocalizedDisplayName)"
            }
        }
    }
}

# Remove SUGs older than three months
$OldSUGs = $AllSUGs | Where-Object {
    $SUGDate = $_.LocalizedDisplayName -match "\d{4}-\d{2}"
    $SUGYear = [int]$Matches[0].Substring(0, 4)
    $SUGMonth = [int]$Matches[0].Substring(5, 2)
    $SUGDate = Get-Date -Year $SUGYear -Month $SUGMonth -Day 1
    $SUGDate -lt $ThreeMonthsAgo
}
Write-Host "=============================="
foreach ($SUG in $OldSUGs) {
    Remove-CMSoftwareUpdateGroup -Name $SUG.LocalizedDisplayName -Force
    Write-Host "Removed old SUG: $($SUG.LocalizedDisplayName)"
}


