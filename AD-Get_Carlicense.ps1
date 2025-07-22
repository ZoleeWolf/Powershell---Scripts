$carLicenseCount = (Get-ADObject -Filter {carLicense -like "*" } -SearchBase "DC=consilium,DC=eu,DC=int" -ResultSetSize $null).Count
Write-Host "The number of Active Directory assets with carLicense field is $carLicenseCount."

