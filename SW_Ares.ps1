$hostname = 'CIS2200388'
$source = 'F:\TempInstall\*'
$destination = '\\' + $hostname + '\c$\Tempinstall'

$Online = Test-Path -Path \\$hostname\C$

if ($Online)
    {
    if (Test-Path $destination) {Remove-Item -Path $destination -Force -Recurse}
    write-host 'Copying source'
    Copy-Item -Path $source -Destination $destination -Recurse -force
    write-host 'Source copied'
    }

if ($Online)
    {
    write-host 'Installing VCRedist'
    psexec64 -s \\$hostname c:\Tempinstall\vstor_redist.exe /passive /norestart
    write-host 'VCRedist installed'
    }
if ($Online)
    {
    write-host 'Installing Ares'
    #Invoke-Command -ComputerName $hostname -scriptblock { & 'psexec64 -s \\$hostname ' -something "/silent" }
    $path = $destination + '\ECARESLK004007002000'
    if (test-path $path)
        {psexec64 -s \\$hostname C:\TempInstall\ECARESLK004007002000\Script\RunSetup /silent}
        else
        {psexec64 -s \\$hostname C:\TempInstall\Script\RunSetup /silent}
    write-host 'Ares installed'
    $dateA = (get-itemproperty '\\CIS1900947\c$\Program Files (x86)\European Commission\AresLook4\AresLook4.dll.config').LastwriteTime
    $dateB = (get-itemproperty 'F:\TempInstall\ECARESLK004007002000\Script\Package\Files\Acceptance-testa.config').LastwriteTime
    if ($dateA -eq $dateB)
        {write-host 'Success'}
        else
        {write-host 'Fail'}
    }

$Online = $False

