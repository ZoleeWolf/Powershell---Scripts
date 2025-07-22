clear
#$Collections = Get-CMCollection | Where-Object { $_.LimitToCollectionID -eq "SMS00001" }
$Collections = Get-CMCollection | Where-Object { $_.Name -like "WKS ADM Models | *" }
foreach ($Collection in $Collections)
    {
    Write-Host "==================="
    $Collection.Name
    $Collection.LimittOCollectionName
    Set-CMCollection -CollectionID $Collection.CollectionID -LimitToCollectionID "SMS00001"
    $Collection.LimittOCollectionName
    }

