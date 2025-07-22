$servers = ('\\SERVERNAME\SMS_CEU\inboxes')
while ($true) {
    $date = Get-Date -Format "yyyy-MM-dd hh:ss"
    Clear-Host
    Write-Host "======================"
    Write-Host "==" $date "=="
    
    foreach ($server in $servers) {
        $backlog = $false
        Write-Host "====================================================================================================="
        Write-Host "==========================" $server "=========================="
        Write-Host "====================================================================================================="
        
        $folders = Get-ChildItem -Directory -Path $server -Recurse | Sort-Object -Property FullName
        foreach ($folder in $folders) {
            $fileCount = (Get-ChildItem -File -Path $folder.FullName).Count
            if ($fileCount -gt 5) {
                $backlog = $true
                if ($fileCount -gt 100) {
                    Write-Host "$($folder.FullName) - $fileCount" -ForegroundColor Red
                } else {
                    Write-Host "$($folder.FullName) - $fileCount" -ForegroundColor Yellow
                }
            }
        }
        
        if (-not $backlog) {
            Write-Host "No backlog detected in the inboxes" -ForegroundColor Green
        }
    }
    
    Write-Host '====================='
    for ($a = 60; $a -gt 0; $a--) {
        Write-Host -NoNewLine "`rRefresh in $a seconds" -ForegroundColor Green
        Start-Sleep 1
    }
}

