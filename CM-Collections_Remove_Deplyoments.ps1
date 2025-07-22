clear
$CollectionName = "WKS GEN Top Collection | Model Office PCs"
$Applications = (Get-CMDeployment -CollectionName $CollectionName).SoftwareName

foreach ($Application in $Applications)
    {
    $Application
    Remove-CMDeployment -ApplicationName $Application -CollectionName $CollectionName -Force
    }

