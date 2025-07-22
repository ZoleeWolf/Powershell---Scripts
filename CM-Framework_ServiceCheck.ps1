$Servers = @('SERVERNAME', 'CS-P-CMDMP01.consilium.eu.int', 'CS-P-CMDMP02.consilium.eu.int')
$Services = @('CCMExec', 'WsusService', 'W3SVC', 'SMS_EXECUTIVE', 'SMS_SITE_COMPONENT_MANAGER')
$Drives = @('C', 'F', 'G', 'H')

while ($true) {
    $date = Get-Date -Format "yyyy-MM-dd hh:ss"
    Clear-Host
    Write-Host "=================================="
    Write-Host "======== $date ========"

    foreach ($Server in $Servers) {
        $ServiceStatus = (Invoke-Command -ComputerName $Server -ScriptBlock { Get-Service -Name winmgmt -ErrorAction SilentlyContinue }).Status
        if ($ServiceStatus -eq 'Running') {
            Write-Host "===================================================================="
            Write-Host "============== $Server - Online ==============" -ForegroundColor Green
            Write-Host "===================================================================="
        } else {
            Write-Host "===================================================================="
            Write-Host "============== $Server - Offline ==============" -ForegroundColor Red
            Write-Host "===================================================================="
        }

        foreach ($Service in $Services) {
            try {
                $ServiceStatus = (Invoke-Command -ComputerName $Server -ScriptBlock { Get-Service -Name $using:Service -ErrorAction SilentlyContinue }).Status
            } catch {
                $ServiceStatus = $null
            }

            if ($ServiceStatus -ne $null) {
                if ($ServiceStatus -eq 'Running') {
                    Write-Host "$Server $Service is $ServiceStatus" -ForegroundColor Green
                } else {
                    Write-Host "$Server $Service is $ServiceStatus" -ForegroundColor Red
                }
            }
        }
    }

    Write-Host "===================================================================="
    for ($a = 600; $a--) {
        Write-Host -NoNewLine "`rRefresh in $a seconds" -ForegroundColor Green
        Start-Sleep 1
    }
}

