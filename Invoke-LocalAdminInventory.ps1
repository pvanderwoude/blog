# Replace with your Workspace ID
$CustomerId = ""  

# Replace with your Primary Key
$SharedKey = ""

# Specify the name of the record type that you'll be creating
$LogType = "AdminInventory"

# You can use an optional field to specify the timestamp from the data. If the time field is not specified, Azure Monitor assumes the time is the message ingestion time
$TimeStampField = ""

# Create the function to create the authorization signature
Function Build-Signature ($customerId, $sharedKey, $date, $contentLength, $method, $contentType, $resource) {
    $xHeaders = "x-ms-date:" + $date
    $stringToHash = $method + "`n" + $contentLength + "`n" + $contentType + "`n" + $xHeaders + "`n" + $resource

    $bytesToHash = [Text.Encoding]::UTF8.GetBytes($stringToHash)
    $keyBytes = [Convert]::FromBase64String($sharedKey)

    $sha256 = New-Object System.Security.Cryptography.HMACSHA256
    $sha256.Key = $keyBytes
    $calculatedHash = $sha256.ComputeHash($bytesToHash)
    $encodedHash = [Convert]::ToBase64String($calculatedHash)
    $authorization = 'SharedKey {0}:{1}' -f $customerId, $encodedHash
    return $authorization
}

# Create the function to create and post the request
Function Post-LogAnalyticsData($customerId, $sharedKey, $body, $logType) {
    $method = "POST"
    $contentType = "application/json"
    $resource = "/api/logs"
    $rfc1123date = [DateTime]::UtcNow.ToString("r")
    $contentLength = $body.Length
    $signature = Build-Signature `
        -customerId $customerId `
        -sharedKey $sharedKey `
        -date $rfc1123date `
        -contentLength $contentLength `
        -method $method `
        -contentType $contentType `
        -resource $resource
    $uri = "https://" + $customerId + ".ods.opinsights.azure.com" + $resource + "?api-version=2016-04-01"

    $headers = @{
        "Authorization" = $signature;
        "Log-Type" = $logType;
        "x-ms-date" = $rfc1123date;
        "time-generated-field" = $TimeStampField;
    }

    $response = Invoke-WebRequest -Uri $uri -Method $method -ContentType $contentType -Headers $headers -Body $body -UseBasicParsing
    return $response.StatusCode

}

#Get the computername
$ComputerName = (Get-ComputerInfo).CsName

#Get the local administrator information
$localAdministrators = @()
$administratorsGroup = ([ADSI]"WinNT://$env:COMPUTERNAME").psbase.children.find("Administrators")
$administratorsGroupMembers= $administratorsGroup.psbase.invoke("Members")
foreach ($administrator in $administratorsGroupMembers) { 
    $localAdministrators += $administrator.GetType().InvokeMember('Name','GetProperty',$null,$administrator,$null) 
}

#Add the local administrator information and device information to a new array
$adminArray = @()
foreach ($localAdministrator in $localAdministrators) {
    $tempAdminArray = New-Object System.Object  
    $tempAdminArray | Add-Member -MemberType NoteProperty -Name "ComputerName" -Value "$ComputerName" -Force 
    $tempAdminArray | Add-Member -MemberType NoteProperty -Name "LocalAdministrator" -Value "$localAdministrator" -Force
    $adminArray += $tempAdminArray
}  

#Convert the array to json
$adminjson = $adminArray | ConvertTo-Json

#Submit the data to the API endpoint
$responseAdminInventory = Post-LogAnalyticsData -customerId $customerId -sharedKey $sharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($adminjson)) -logType $LogType 

#Report back status
$date = Get-Date -Format "dd-MM HH:mm"
$outputMessage = "InventoryDate:$date "

if ($responseAdminInventory -match "200") {
    $outputMessage = $outputMessage + " LocalAdminInventory: OK "
}
else {
    $outputMessage = $outputMessage + " LocalAdminInventory:Fail "
}

Write-Output $outputMessage
Exit 0
