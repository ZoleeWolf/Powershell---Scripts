$Path = 'D:\Powershell'
$Filter = '*.ps1'
$Files = (Get-ChildItem -File $Path -Filter $Fileter).name
foreach ($File in $Files)
    {
    
    ((Get-Content -path $File -Raw) -replace 'CM_CEU','CM_DB1') | Set-Content -Path $File
    Write-host $File
    Start-Sleep -Seconds 1
    }

