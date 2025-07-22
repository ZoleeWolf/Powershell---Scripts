$CollectionName = "USR CTL*"

# Site configuration
$SiteCode = "CEU" # Site code 
$ProviderMachineName = "SERVERNAME" # SMS Provider machine name

Set-Location "$($SiteCode):\"

$Collections = (Get-CMUserCollection -Name $CollectionName).CollectionID

# Weekly Sunday 12:00
#$RefreshSchedule = New-CMSchedule -DayOfWeek 0 -Start "01/01/2024 12:00 PM"
# By DAy
#$RefreshSchedule = New-CMSchedule -Start "01/01/2024 08:00 AM" -RecurInterval Days -RecurCount 1
# By hour
#$RefreshSchedule = New-CMSchedule -Start "01/01/2024 12:00 AM" -RecurInterval Hours -RecurCount 1
# By minute
$RefreshSchedule = New-CMSchedule -Start "01/01/2024 12:00 AM" -RecurInterval Minutes -RecurCount 30


foreach ($Collection in $Collections)
    {
    $Collection + ' - ' + (Get-CMUserCollection -Id $Collection).Name
    Set-CMCollection -CollectionId $Collection -RefreshSchedule $RefreshSchedule -RefreshType Periodic
    }

