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
    $ContainerNodeId = (Get-WmiObject -ComputerName $SiteServer -Class SMS_ObjectContainerNode -Namespace root/SMS/site_$SiteCode -Filter "Name='$Container' and ObjectTypeName='SMS_Collection_Device'").ContainerNodeId
    $CollectionIds = (Get-WmiObject -ComputerName $SiteServer -Namespace root/SMS/site_$SiteCode -Query "SELECT fcm.* FROM SMS_FullCollectionMembership fcm, SMS_ObjectContainerItem oci WHERE oci.ContainerNodeID='$ContainerNodeId' AND fcm.Name='$ResourceName' AND fcm.CollectionID=oci.InstanceKey").CollectionId
    if ($CollectionIds -ne $null) {
        foreach ($CollectionId in $CollectionIds) {
            $ApplicationNames = (Get-WmiObject -ComputerName $SiteServer -Class SMS_ApplicationAssignment -Namespace root/SMS/site_$SiteCode -Filter "TargetCollectionID='$CollectionId' and OfferTypeID='0'").ApplicationName            
	        if ($ApplicationNames -ne $null) {
                foreach ($ApplicationName in $ApplicationNames) {
                    $Id = "{0:D2}" -f $Count
                    $AppId = "APPId$Id"
                    $TSEnv.Value($AppId) = $ApplicationName
                    $Count = $Count + 1
                    Write-Host $AppId $ApplicationName
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
