# Replace with your Workspace ID
$CustomerId = "814005ae-064e-4efd-a44a-5e2db1f7a45e"  

# Replace with your Primary Key
$SharedKey = "gvYyoTS3oagcfgG6Nz8phGvrULf8rQhHBHrixxbjH2Om6TTmBmmrfNYmgOLxX+67NlisIzVwPSRW4VjhLuuhzQ=="

# Specify the name of the record type that you'll be creating
$LogType = "Token_data_CL"

# You can use an optional field to specify the timestamp from the data. If the time field is not specified, Azure Monitor assumes the time is the message ingestion time
$TimeStampField = ""


# Create two records with the same set of properties to create
#$json = @"
#[{  "host_name": "adb-2229882759465707.7.azuredatabricks.net",
#    "token_id": "57ce8c83da30fbff0dc023441e6cec9efb0146a262bfb9e185dc9f1a3b25ec40",
#    "creation_time": 1601008582522,
#    "expiry_time": 1608784582522,
#    "comment": "dbfs",
#    "created_by_username": "manoj.muppidi@kroger.com"
#},
#{   "host_name": "adb-1515192762105108.8.azuredatabricks.net",
#    "token_id": "3908973d17f5acd332562bbc9a05b9838ddad7b0b4066a6e8076a1c09465721e",
#    "creation_time": 1601578471617,
#    "expiry_time": -1,
#    "comment": "devops",
#    "created_by_username": "manoj.muppidi@kroger.com"
#}]
#"@
$path =  "./"
$json = (Get-Content $path"try.json" -Raw)

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
Post-LogAnalyticsData -customerId $customerId -sharedKey $sharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($json)) -logType $logType
