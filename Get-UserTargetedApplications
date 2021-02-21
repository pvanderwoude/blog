[CmdletBinding()]

param (
 [string]$ResourceName,
 [string]$SiteCode='{YourSiteCode}',
 [string]$SiteServer='{YourSiteServer}',
 [string]$Container = "{YourApplicationCollectionContainer}"
 )

function Get-TargetedApplications {
    $Count = 1
    $TSEnv = New-Object -COMObject Microsoft.SMS.TSEnvironment
    $PrimaryUsers = (Get-WmiObject -ComputerName $SiteServer -Class SMS_UserMachineRelationship -Namespace root\SMS\Site_$SiteCode -Filter “ResourceName='$ResourceName' and IsActive='1' and Types='1'”).UniqueUserName.replace(“\”,”\\”)
    if ($PrimaryUsers -ne $null) {        
        foreach ($PrimaryUser in $PrimaryUsers){
            $ContainerNodeId = (Get-WmiObject -ComputerName $SiteServer -Class SMS_ObjectContainerNode -Namespace root/SMS/site_$SiteCode -Filter “Name='$Container' and ObjectTypeName='SMS_Collection_User'”).ContainerNodeId
            $InstanceKeys = (Get-WmiObject -ComputerName $SiteServer -Class SMS_ObjectContainerItem -Namespace root/SMS/site_$SiteCode -Filter “ContainerNodeID='$ContainerNodeId'”).InstanceKey  
            foreach ($InstanceKey in $InstanceKeys){
                $CollectionId = (Get-WmiObject -ComputerName $SiteServer -Class SMS_FullCollectionMembership -Namespace root/SMS/site_$SiteCode -Filter “CollectionID='$InstanceKey' and SMSID='$PrimaryUser'”).CollectionId
                if ($CollectionId -ne $null) {  
                    $ApplicationNames = (Get-WmiObject -ComputerName $SiteServer -Class SMS_ApplicationAssignment -Namespace root/SMS/site_$SiteCode -Filter “TargetCollectionID='$CollectionId' and OfferTypeID='0'”).ApplicationName
                    if ($ApplicationNames -ne $null) {
                        foreach ($ApplicationName in $ApplicationNames) {
                            $Id = “{0:D2}” -f $Count
                            $AppId = “APPId$Id”
                            $TSEnv.Value($AppId) = $ApplicationName.ApplicationName
                            Write-Host "$AppId $ApplicationName"
                            $Count = $Count + 1
                        }
                    }
                }
            }
        }
    }
    else {
        $TSEnv.Value("SkipApplications") = "True"
        Write-Host "Skip applications"
        break
    }
}

Get-TargetedApplications
