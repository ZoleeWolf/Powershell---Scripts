Get-CMPackage -Name "Adobe Uninstaller" -PackageType RegularPackage

# Define the package ID
$packageID = "CEU0026E"

# Define the programs
$programs = @(
    "AdobeUninstaller.exe --products=AME#22.0",
    "AdobeUninstaller.exe --products=AME#23.0",
    "AdobeUninstaller.exe --products=IDSN#18.0",
    "AdobeUninstaller.exe --products=ILST#27.0",
    "AdobeUninstaller.exe --products=PHSP#24.0",
    "AdobeUninstaller.exe --products=PPRO#23.0",
    "AdobeUninstaller.exe --products=PPRO#24.0"
)

# Loop through each program and create it in SCCM
foreach ($program in $programs) {
    $programName = ($program.Split("=")[1]).Split("#")[0] + "_" + $program.Split("#")[1]
    $Programname
    New-CMProgram -CommandLine $program -PackageId $packageID -StandardProgramName $programName -Duration 15 -ProgramRunType WhetherOrNotUserIsLoggedOn
}

Write-Output "Programs created successfully for package ID $packageID."

