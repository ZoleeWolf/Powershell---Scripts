clear
$collectionName = "WKS GEN Top Collection | Model Office PCs"

$Applications = (Get-CMApplication -fast | Where-Object {$_.LocalizedDescription -like 'Created by Patch My PC*' -and $_.NumberOfDeployments -like '0'}).LocalizedDisplayName
#$Applications = get-content 'C:\temp\input.txt'

foreach ($ApplicationName in $Applications)
    {
    $Application = Get-CMApplication -Name $ApplicationName
    $Collection = Get-CMDeviceCollection -Name $CollectionName
    New-CMApplicationDeployment -CollectionName $collectionName -Name $ApplicationName -DeployAction Install -DeployPurpose Available -UserNotification DisplaySoftwareCenterOnly -AvailableDateTime '01/01/2024 00:00:00' -AllowRepairApp $True
    }

