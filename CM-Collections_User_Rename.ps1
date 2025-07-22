clear
$CollectionName = "USR CTL SEC-SMS-Java-Runtime-US"
$Vendor = "Oracle"

###################################################
$SiteCode = "CEU" # Site code
Set-Location "$($SiteCode):\"

$Collections = (Get-CMUserCollection -Name $CollectionName).CollectionID
foreach ($Collection in $Collections)
    {
    $Collection + ' - ' + (Get-CMUserCollection -Id $Collection).Name
    $ID = $Collection
    $Oldname = (Get-CMCollection -Id $ID -CollectionType User).Name
    
    $OldQuery = (Get-CMCollectionQueryMembershipRule -CollectionId $ID).QueryExpression
    $Rulename =  (Get-CMCollectionQueryMembershipRule -CollectionId $ID).Rulename
    $NewCollectionName = "USR CTL SEC-SMS-SW-"+$Vendor+"-"
    $NewName = $Oldname.replace('USR CTL SEC-SMS-USU_',$NewCollectionName)
       
    # Define the distinguished name (DN) of the group you want to rename
    $oldGroupName = $Oldname.replace('USR CTL ','')

    # Define the new name for the group
    $newGroupName = $Newname.replace('USR CTL ','')
    
    $OldQuery = (Get-CMCollectionQueryMembershipRule -CollectionID $ID -RuleName $RuleName).QueryExpression
    $NewQuery = $OldQuery.replace(' like ',' = ').replace($oldGroupName,$newGroupName)
    
    write-host "================================================================================="
    $OldQuery
    write-host "================================================================================="
    $NewQuery
    write-host "================================================================================="

    $GroupName = $NewQuery.replace('select SMS_R_USER.ResourceID,SMS_R_USER.ResourceType,SMS_R_USER.Name,SMS_R_USER.UniqueUserName,SMS_R_USER.WindowsNTDomain from SMS_R_User where SMS_R_User.UserGroupName = "CONSILIUM\\','').replace('"','')
    Write-Host "New Collection name:"
    Write-Host $NewName -ForegroundColor Green

    Start-Sleep 5
        
    # Get the group object
    $filter = "name -like '"+$oldGroupName+"'"
    $group = Get-ADGroup -Filter $Filter
        
    # Change SAMAccountName
    Set-ADgroup -Identity $group -SamAccountName $newGroupName    

    # Rename the group
    Rename-ADObject -Identity $group -NewName $newGroupName

    Write-Host "Renamed AD Group: "$newGroupName

    Remove-CMUserCollectionQueryMembershipRule -CollectionId $ID -RuleName $RuleName -Force
    Add-CMUserCollectionQueryMembershipRule -CollectionId $ID -QueryExpression $NewQuery -RuleName $NewName
    if ((Get-CMDeviceCollection -Id $Collection).Name -ne $NewName)
        {
        Set-CMCollection -CollectionId $ID -NewName $NewName
        }
    }
Set-Location "C:\"

