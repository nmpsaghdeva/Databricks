#########################################################################################
# Purpose :  This script is used to send data to log analytics workspace                #
#											#
# parrameters : 1. Log analytics workspace Id 					 	#	
#		2. Workspace key Id							#	 
#		3. Table Name 								#
#		4. Source File  Name 							#
#########################################################################################

# Replace with your Workspace ID
#$CustomerId = "814005ae-064e-4efd-a44a-5e2db1f7a45e"  
$CustomerId = $args[0]

# Replace with your Primary Key
#$SharedKey = "gvYyoTS3oagcfgG6Nz8phGvrULf8rQhHBHrixxbjH2Om6TTmBmmrfNYmgOLxX+67NlisIzVwPSRW4VjhLuuhzQ=="
$SharedKey = $args[1]

# Specify the name of the record type that you'll be creating
$LogType = "Token_data_CL"
#$LogType = $args[2]

# You can use an optional field to specify the timestamp from the data. If the time field is not specified, Azure Monitor assumes the time is the message ingestion time
$TimeStampField = ""


$path =  "./"

# Create the function to create the authorization signature
Function Build-Signature ($customerId, $sharedKey, $date, $contentLength, $method, $contentType, $resource)
{
    $xHeaders = "x-ms-date:" + $date
    $stringToHash = $method + "`n" + $contentLength + "`n" + $contentType + "`n" + $xHeaders + "`n" + $resource

    $bytesToHash = [Text.Encoding]::UTF8.GetBytes($stringToHash)
    $keyBytes = [Convert]::FromBase64String($sharedKey)

    $sha256 = New-Object System.Security.Cryptography.HMACSHA256
    $sha256.Key = $keyBytes
    $calculatedHash = $sha256.ComputeHash($bytesToHash)
    $encodedHash = [Convert]::ToBase64String($calculatedHash)
    $authorization = 'SharedKey {0}:{1}' -f $customerId,$encodedHash
    return $authorization
}


# Create the function to create and post the request
Function Post-LogAnalyticsData($customerId, $sharedKey, $body, $logType)
{
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

# Submit the data to the API endpoint
$LogType =  "Token_data_CL"
Get-childitem -Path $Path -Filter token_a*.json | % {
     $file = $_.FullName
     Write-Host $file
     $json = (Get-Content $file -Raw)
     Post-LogAnalyticsData -customerId $customerId -sharedKey $sharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($json)) -logType $logType
}

$LogType =  "Cluster_data_CL"
Get-childitem -Path $Path -Filter cluster*.json | % {
     $file = $_.FullName
     Write-Host $file
     $json = (Get-Content $file -Raw)
     Post-LogAnalyticsData -customerId $customerId -sharedKey $sharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($json)) -logType $logType
}

$LogType =  "Instance_pool_CL"
Get-childitem -Path $Path -Filter instance_pool*.json | % {
     $file = $_.FullName
     Write-Host $file
     $json = (Get-Content $file -Raw)
     Post-LogAnalyticsData -customerId $customerId -sharedKey $sharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($json)) -logType $logType
}


$LogType =  "Jobs_data_CL"
Get-childitem -Path $Path -Filter Jobs_*.json | % {
     $file = $_.FullName
     Write-Host $file
     $json = (Get-Content $file -Raw)
     Post-LogAnalyticsData -customerId $customerId -sharedKey $sharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($json)) -logType $logType
}


$LogType =  "Secret_scope_CL"
Get-childitem -Path $Path -Filter secret*.json | % {
     $file = $_.FullName
     Write-Host $file
     $json = (Get-Content $file -Raw)
     Post-LogAnalyticsData -customerId $customerId -sharedKey $sharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($json)) -logType $logType
}