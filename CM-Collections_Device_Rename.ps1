clear
$CollectionName = 'WKS CTL SEC-SMS-USU_OracleFormsLauncher-WS'
$Vendor = 'Oracle'

###################################################
$SiteCode = "CEU" # Site code
Set-Location "$($SiteCode):\"

$Collections = (Get-CMDeviceCollection -Name $CollectionName).CollectionID
foreach ($Collection in $Collections)
    {
    $Collection + ' - ' + (Get-CMDeviceCollection -Id $Collection).Name
    $ID = $Collection
    $Oldname = (Get-CMCollection -Id $ID -CollectionType Device).Name
    
    $OldQuery = (Get-CMCollectionQueryMembershipRule -CollectionId $ID).QueryExpression
    $Rulename =  (Get-CMCollectionQueryMembershipRule -CollectionId $ID).Rulename
    $NewCollectionName = "WKS CTL SEC-SMS-SW-"+$Vendor+"-"
    $NewName = $Oldname.replace('WKS CTL SEC-SMS-USU_',$NewCollectionName)
    
    # Define the distinguished name (DN) of the group you want to rename
    $oldGroupName = $Oldname.replace('WKS CTL ','')

    # Define the new name for the group
    $newGroupName = $Newname.replace('WKS CTL ','')
    
    $OldQuery = (Get-CMCollectionQueryMembershipRule -CollectionID $ID -RuleName $RuleName).QueryExpression
    $NewQuery = $OldQuery.replace(' like ',' = ').replace($oldGroupName,$newGroupName)

    write-host "================================================================================="
    $OldQuery
    write-host "================================================================================="
    $NewQuery
    write-host "================================================================================="

    $GroupName = $NewQuery.replace('select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System where SMS_R_System.SystemGroupName = "CONSILIUM\\','').replace('"','')
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
       
    Remove-CMDeviceCollectionQueryMembershipRule -CollectionId $ID -RuleName $RuleName -Force
    Add-CMDeviceCollectionQueryMembershipRule -CollectionId $ID -QueryExpression $NewQuery -RuleName $NewName
    if ((Get-CMDeviceCollection -Id $Collection).Name -ne $NewName)
        {
        Set-CMCollection -CollectionId $ID -NewName $NewName
        }
    }
Set-Location "C:\"

