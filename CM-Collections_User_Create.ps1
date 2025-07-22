$LimitingCollections = "All Users"
$Groups = get-content 'C:\temp\groups.txt'
$Sched = New-CMSchedule -RecurInterval Hours -RecurCount 2

# Site configuration
$SiteCode = "CEU" # Site code 
$ProviderMachineName = "SERVERNAME" # SMS Provider machine name

# Customizations
$initParams = @{}
#$initParams.Add("Verbose", $true) # Uncomment this line to enable verbose logging
#$initParams.Add("ErrorAction", "Stop") # Uncomment this line to stop the script on any errors

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
Set-Location "$($SiteCode):\" @initParams

foreach ($Group in $Groups)
    {
    $Name = "USR CTL "+$Group
    if (Get-CMUserCollection -name $Name)
        {
        }
        Else
        {
        $Query = "select SMS_R_USER.ResourceID,SMS_R_USER.ResourceType,SMS_R_USER.Name,SMS_R_USER.UniqueUserName,SMS_R_USER.WindowsNTDomain from SMS_R_User where SMS_R_User.UserGroupName = '$($Group)%'"
        New-CMUserCollection -Name $Name -LimitingCollectionName $LimitingCollections -RefreshSchedule $Sched
        Sleep 1
        Add-CMUserCollectionQueryMembershipRule -CollectionName $Name -QueryExpression $Query -RuleName $Name
        }
    }

