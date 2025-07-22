clear
$ports = (135,445,2701,2702,3389,5985,65000)
$Computer = "CIS2206710"

Write-Host "=========================="
Write-Host "======= $Computer ======="
Write-Host "=========================="
foreach ($port in $ports)
    {
    $result = Test-NetConnection -ComputerName $Computer -Port $port -InformationLevel Quiet
    if ($result)
        {
        write-host $port - $result -ForegroundColor Green
        }
        else
        {
        write-host $port - $result -ForegroundColor Red
        }
    }

Invoke-Command -ComputerName CIS2206710 -ScriptBlock {Get-UICulture}

