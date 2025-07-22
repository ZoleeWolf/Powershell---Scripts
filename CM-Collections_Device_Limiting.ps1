$CollectionName = "WKS GEN Software*"
$LimitingCollection = "WKS GEN Top Collection"

$Collections = (Get-CMDeviceCollection -Name $CollectionName).CollectionID
$LimitingCollectionID = (Get-CMDeviceCollection -Name $LimitingCollection).CollectionID

foreach ($Collection in $Collections)
    {
    $Collection + ' - ' + (Get-CMDeviceCollection -Id $Collection).Name
    Set-CMCollection -CollectionID $collection -LimitingCollectionID $limitingCollectionID
    }

