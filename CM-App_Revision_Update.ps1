cls
$AppNames = @("Bridge","After Effects","Captivate","Character Animator","Illustrator","InCopy","InDesign","Media Encoder","Photoshop","Premiere Pro","Premiere Rush","XD","Lightroom")
foreach ($AppName in $AppNames)
    {
    Write-Host "=========================="
    Write-Host "======= $AppName ======="
    Write-Host "=========================="

    if ((Get-CMApplication -Name $AppName).CIVersion -lt 16)
        {
        do {
            Update-CMDistributionPoint -ApplicationName $AppName -DeploymentTypeName $AppName
            $AppVersion = (Get-CMApplication -Name $AppName).CIVersion
            write-host "Revision - "$AppVersion
            } while ($AppVersion -lt 20)
        }
        else
        {
        Write-Host OK
        }

    }

