Get-CMApplication | ForEach-Object {
    $appName = $_.LocalizedDisplayName
    $deploymentTypes = Get-CMDeploymentType -ApplicationName $appName
    foreach ($depType in $deploymentTypes) {
        $depTypeName = $depType.LocalizedDisplayName
        $depType.LocalizedDisplayName
        Update-CMDistributionPoint -ApplicationName $appName -DeploymentTypeName $depTypeName
    }
}

