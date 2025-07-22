# Source file location
$source = 'https://download.jetbrains.com/python/pycharm-professional-2024.2.1.exe'
$filename = $source.Substring($source.LastIndexOf("/") + 1)

#$filename = 'ricghtclick.msi'
#Destination to save the file
#$destination = '\\SERVERNAME\PMP_Local\' + $filename
#$destination = '\\CS-P-WSAS01\G$\Patch_My_Pc_Temp\' + $filename
$destination = 'C:\temp\' + $filename
#Download the file
Invoke-WebRequest -Uri $source -OutFile $destination

