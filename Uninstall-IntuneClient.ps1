function Get-ServiceId {
    #Set the registry path containing the service ID
    $RegistryPath = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\OnlineManagement"
    try {
        #Get all the names of the items in the registry location
        $RegistryItems = (Get-ChildItem -Path Registry::$RegistryPath -ErrorAction Stop).Name
        #Loop through all the results
        foreach ($RegistryItem in $RegistryItems) {
            #Find the result that starts with the registry location followed by the first sign of a GUID
            if ($RegistryItem.StartsWith("$RegistryPath\{")) {
                #Replace the registry location with nothing to get the GUID
                $ServiceId = $RegistryItem.Replace("$RegistryPath\","")
                break
            }
        }
        return $ServiceId
    }
    catch {
        Write-Output "The Microsoft Intune client is not installed"
    }
}

function Start-Uninstall {
    param (
    [parameter(Mandatory=$true)]$ServiceId
    )
    try {
        #Set the ProvisioningUtil location and parameters
        $ProvisioningUtilPath = "C:\Program Files\Microsoft\OnlineManagement\Common"
        $ProvisioningUtilExecutable = "ProvisioningUtil.exe"
        $ProvisioningUtilArguments = "/UninstallClient /ServiceId $ServiceId /TaskName 'tempTask' /SubEventId 16"
        #Trigger the uninstall of the Microsoft Intune client
        Start-Process -FilePath "$($ProvisioningUtilPath)\$($ProvisioningUtilExecutable)" -ArgumentList $ProvisioningUtilArguments -Wait -PassThru
    }
    catch {
        Write-Output "Failed to trigger the uninstall of the Microsoft Intune client"
    }
}

Start-Uninstall (Get-ServiceId)
