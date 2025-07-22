# Define the path to the new icon
$newIconPath = "\\SERVERNAME\CM_Sources$\Icons\HP_new.png"

# List of PackageIDs to update
$packageIDs = @("CEU001A8", "CEU00282", "CEU00280", "CEU00148", "CEU00147", "CEU001D6", "CEU001D2", "EUW00273", "CEU001D7", "EUW00274", "EUW00271", "EUW0027A", "CEU001D4", "EUW00272", "EUW00275", "CEU001B3", "CEU001D0", "CEU001FC", "EUW00270", "CEU0019B", "EUW002D4", "EUW002A0", "EUW00265", "EUW002D6", "CEU001A7", "EUW00269", "EUW00268", "EUW002D8", "EUW002DD", "EUW00308", "EUW002D5", "CEU001D3", "EUW00264", "EUW002D2", "CEU001D1", "EUW00267", "EUW002D3", "EUW00309", "CEU001B2", "EUW00266", "CEU001D5", "CEU00284") # Replace with your actual PackageIDs

# Loop through each PackageID and update the icon
foreach ($packageID in $packageIDs) {
    # Get the package
    $package = Get-CMPackage -Id $packageID

    if ($package) {
        # Update the icon
        Set-CMPackage -Id $packageID -IconLocation $newIconPath
        Write-Output "Updated icon for package: $packageID"
    } else {
        Write-Output "Package not found: $packageID"
    }
}

