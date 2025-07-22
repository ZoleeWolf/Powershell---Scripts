$date = Get-Date -Format "_yyyy-MM-dd_HH-mm-ss"
$LogFile = "\\SERVERNAME\Maintenance\AD_Lastlogon_180_"+$date+".txt"
$log = $false

function Write-Log
    {
    Param ([string]$LogString)
    $Stamp = (Get-Date).toString("yyyy/MM/dd HH:mm:ss")
    $LogMessage = "$LogString"
    Add-content $LogFile -value $LogMessage
    }

# Get all computer objects (excluding servers)
#$dcs = Get-ADComputer -Filter { OperatingSystem -NotLike '*Server*' -and carLicense -like '*'} -Properties OperatingSystem
$dcs = Get-ADComputer -Filter { OperatingSystem -NotLike '*Server*'} -Properties OperatingSystem

# Iterate through each computer
foreach ($dc in $dcs)
    {
    # Retrieve the last logon timestamp
    $lastLogonTimestamp = Get-ADComputer $dc.Name -Properties lastlogontimestamp |
                         Select-Object @{Name = "Name"; Expression = {$_.Name}},
                                       @{Name = "LastLogonTime"; Expression = {[DateTime]::FromFileTime($_.lastLogonTimestamp)}}

    # Check if the last logon time is older than 180 days
    if ($lastLogonTimestamp.LastLogonTime -lt (Get-Date).AddDays(-180))
        {
        $formattedDate = $lastLogonTimestamp.LastLogonTime.ToString("yyyy-MM-dd")
        $data = $lastLogonTimestamp.Name +','+ $formattedDate
        Write-Log $data
        }
    }

