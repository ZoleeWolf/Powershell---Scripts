clear
$Data = Import-Csv 'D:\temp\models.txt'
$Sched = New-CMSchedule -DayOfWeek 0 -RecurCount 1 -Start "01/01/2024 12:00 PM"
$LimitingCollection = "All Systems"

foreach ($line in $data)
    {
    $Manufacturer =  $line.Manufacturer
    $Model = $line.Model
    $CollectionName = "WKS ADM Models | "+$Manufacturer+" - "+$Model
    if (Get-CMCollection -Name $CollectionName)
        {
        write-host $CollectionName - Already exists
        }
        else
        {
        $Query = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System inner join SMS_G_System_COMPUTER_SYSTEM on SMS_G_System_COMPUTER_SYSTEM.ResourceId = SMS_R_System.ResourceId where SMS_G_System_COMPUTER_SYSTEM.Model = """+$Model+""""
        New-CMDeviceCollection -Name $CollectionName -LimitingCollectionName $LimitingCollection -RefreshSchedule $Sched
        Sleep 1
        Add-CMDeviceCollectionQueryMembershipRule -CollectionName $CollectionName -QueryExpression $Query -RuleName $CollectionName
        }
    }

