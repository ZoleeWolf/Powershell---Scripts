$ApplicationName = "Premiere Rush"
$ContentLocation = "\\SERVERNAME\CM_Sources$\Applications\Adobe_Premiere_Rush"
$Description = ""
$Publisher = "Adobe"
$Version = "1.0"
$InstallationBehaviorType = "InstallForSystem"
$LogonRequirementType = "WhetherOrNotUserLoggedOn"
$UserInteractionMode = "Hidden"
$RebootBehavior = "NoAction"
$Comment = ""

# Site configuration
$SiteCode = "CEU" # Site code 
$ProviderMachineName = "SERVERNAME" # SMS Provider machine name

Set-Location "C:\"

$msiFilePath = $ContentLocation+"\Files"
$msiFile = Get-ChildItem -Path $msiFilePath -Filter *.msi
function Get-MSIProductCode {
    param (
        [parameter(Mandatory=$true)]
        [string]$MSIPath
    )

    $WindowsInstaller = New-Object -ComObject WindowsInstaller.Installer
    $MSIDatabase = $WindowsInstaller.GetType().InvokeMember("OpenDatabase", "InvokeMethod", $null, $WindowsInstaller, @($MSIPath, 0))
    $Query = "SELECT Value FROM Property WHERE Property = 'ProductCode'"
    $View = $MSIDatabase.GetType().InvokeMember("OpenView", "InvokeMethod", $null, $MSIDatabase, ($Query))
    $View.GetType().InvokeMember("Execute", "InvokeMethod", $null, $View, $null)
    $Record = $View.GetType().InvokeMember("Fetch", "InvokeMethod", $null, $View, $null)
    $ProductCode = $Record.GetType().InvokeMember("StringData", "GetProperty", $null, $Record, 1)

    # Clean up
    $View.GetType().InvokeMember("Close", "InvokeMethod", $null, $View, $null)
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($WindowsInstaller) | Out-Null
    [System.GC]::Collect()

    return $ProductCode
}
$productCode = Get-MSIProductCode -MSIPath $msiFile.FullName
$guidProductCode = [Guid]::Parse($productCode)
$detectionClause = New-CMDetectionClauseWindowsInstaller -Existence -ProductCode $guidProductCode

Set-Location "$($SiteCode):\"

New-CMApplication -Name $ApplicationName -Description $Description -Publisher $Publisher -SoftwareVersion $Version -IconLocationFile "$ContentLocation\Icon.png"
$installScript = "$ContentLocation\Deploy-Application.ps1"
Add-CMScriptDeploymentType -ApplicationName $ApplicationName -DeploymentTypeName $ApplicationName -InstallCommand "Deploy-Application.exe -DeploymentType 'Install' -DeployMode 'Silent'" -UnInstallCommand "Deploy-Application.exe -DeploymentType 'Uninstall' -DeployMode 'Silent'" -RepairCommand "Deploy-Application.exe -DeploymentType 'Repair'" -ContentLocation $ContentLocation -AddDetectionClause $detectionClause -InstallationBehaviorType $InstallationBehaviorType -LogonRequirementType $LogonRequirementType -UserInteractionMode $UserInteractionMode -RebootBehavior $RebootBehavior -Comment $Comment -EnableContentLocationFallback

