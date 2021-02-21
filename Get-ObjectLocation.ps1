$SiteCode = "{YourSiteCode}"
$SiteServer = "{YourSiteCode}"

function Get-ObjectLocation {
    param (
    [string]$InstanceKey
    )
    
    #oci.ObjectTypeName='SMS_Collection_Device' AND
    $ContainerNode = Get-WmiObject -Namespace root/SMS/site_$($SiteCode) -ComputerName $SiteServer -Query "SELECT ocn.* FROM SMS_ObjectContainerNode AS ocn JOIN SMS_ObjectContainerItem AS oci ON ocn.ContainerNodeID=oci.ContainerNodeID WHERE oci.InstanceKey='$InstanceKey'"
    if ($ContainerNode -ne $null) {
        $ObjectFolder = $ContainerNode.Name
        if ($ContainerNode.ParentContainerNodeID -eq 0) {
            $ParentFolder = $false
        }
        else {
            $ParentFolder = $true
            $ParentContainerNodeID = $ContainerNode.ParentContainerNodeID
        }
        while ($ParentFolder -eq $true) {
            $ParentContainerNode = Get-WmiObject -Namespace root/SMS/site_$($SiteCode) -ComputerName $SiteServer -Query "SELECT * FROM SMS_ObjectContainerNode WHERE ContainerNodeID = '$ParentContainerNodeID'"
            $ObjectFolder =  $ParentContainerNode.Name + "\" + $ObjectFolder
            if ($ParentContainerNode.ParentContainerNodeID -eq 0) {
                $ParentFolder = $false
            }
            else {
                $ParentContainerNodeID = $ParentContainerNode.ParentContainerNodeID
            }
        }
        $ObjectFolder = "Root\" + $ObjectFolder
        Write-Output $ObjectFolder
    }
    else {
        $ObjectFolder = "Root"
        Write-Output $ObjectFolder
    }
}

Get-ObjectLocation {YourInstanceKey}
