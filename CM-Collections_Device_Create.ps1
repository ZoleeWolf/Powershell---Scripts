clear
$Groups = Get-Content 'D:\temp\input.txt'
#$Group = "SEC-SMS-AutoCAD-2025-US"

foreach ($Group in $Groups)
    {
    Set-Location "$($SiteCode):\"
    $wql = 'select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System      LEFT JOIN SMS_UserMachineRelationship ON SMS_UserMachineRelationship.ResourceID = SMS_R_System.ResourceId      LEFT JOIN SMS_R_User ON SMS_UserMachineRelationship.UniqueUserName = SMS_R_User.UniqueUserName  WHERE      SMS_R_User.UserGroupName = "CONSILIUM\\'+$Group+'"'
    $name = "WKS CTL "+$Group
    $Schedule = New-CMSchedule -Start "01/01/2013 7:00" -RecurInterval Days -RecurCount 1

    # Site configuration
    $SiteCode = "CEU" # Site code 
    $ProviderMachineName = "SERVERNAME" # SMS Provider machine name

    # Do not change anything below this line

    # Import the ConfigurationManager.psd1 module 
    if((Get-Module ConfigurationManager) -eq $null) {
        Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1" @initParams 
    }

    # Connect to the site's drive if it is not already present
    if((Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue) -eq $null) {
        New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $ProviderMachineName @initParams
    }

    # Set the current location to be the site code.
    
    New-CMDeviceCollection -Name $name -LimitingCollectionName "WKS GEN Top Collection" -RefreshSchedule $schedule -RefreshType 2
    Add-CMDeviceCollectionQueryMembershipRule -CollectionName $name -QueryExpression $wql -RuleName $name
    }

