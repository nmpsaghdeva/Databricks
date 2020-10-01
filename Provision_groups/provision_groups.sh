#!/bin/bash

if [ $# != 3 ]
then
  echo "Usage: $0 <Service Principal Id> <Databricks URL> <Token> <Access token>"
  exit
fi
rm -f ./para.json
echo "{"  > ./para.json
echo "\"displayName\": \"$1\"" >> ./para.json
echo "}\n" >> ./para.json
echo $2
echo $3

echo
#spid="e08ee5fb-89a8-4fe3-9a64-e898cc2288f3"
#BaseAddress="https://adb-3689169406628329.9.azuredatabricks.net"
#secretToken="dapi1995068484ada9c8998e97fee0d80571"

# Parameters
spid=$1
BaseAddress=$2
secretToken=$3
#app_id=$4
#pwd=$5
#tenant_id=$6

tenant_id=`az account show | jq '.tenantId' | sed s'/\"//g'`
app_id=`az ad sp show --id ${spid} | jq '.appId' | sed s'/\"//g'`
echo "Application Id ==>" $app_id

#az login --username $user --password $pwd
#az login --service-principal --username APP_ID --password PASSWORD --tenant TENANT_ID
#az login --service-principal --username ${app_id} --password ${pwd} --tenant ${tenant_id}
response=$(az account get-access-token --resource-type ms-graph)
token=$(echo $response | jq ".accessToken" -r)


baseUrl=\""${BaseAddress}/api/2.0/preview/scim\""
echo "Base URL :" ${baseUrl}

# Create Job: Provisioning task with name aws created under service pricnical
graphurl="https://graph.microsoft.com/beta/servicePrincipals/${spid}/synchronization/jobs"
rm -f ./para.json
echo "{"  > ./para.json
echo "\"templateId\": \"dataBricks\"" >> ./para.json
echo "}\n" >> ./para.json
echo $graphurl
curl -X POST -H "Authorization: Bearer $token" -d @para.json $graphurl  -H "Content-Type: application/json" |jq

#Get Job ID
graphurl="https://graph.microsoft.com/beta/servicePrincipals/${spid}/synchronization/jobs/"
JobId=`curl -X GET -H "Authorization: Bearer $token" -d @para.json $graphurl  -H "Content-Type: application/json" | jq  '.value[0].id' | sed 's/\"//g'`

echo  "Test Connection  "
# Validate  Credentials
graphurl="https://graph.microsoft.com/beta/servicePrincipals/${spid}/synchronization/jobs/${JobId}/validateCredentials"
rm -f ./para.json
echo "{"  > ./para.json
echo "\t\"credentials\": [" >> ./para.json
echo "\t\t{ \"key\": \"BaseAddress\", \"value\" : $baseUrl  }," >> ./para.json
echo "\t\t{ \"key\": \"SecretToken\", \"value\" : \"$secretToken\"  }" >> ./para.json
echo "\t]" >> ./para.json
echo "}\n" >> ./para.json
echo $graphurl
curl -X POST -H "Authorization: Bearer $token" -d @para.json $graphurl  -H "Content-Type: application/json" |jq


echo  "Provisioning Job created"
# Save Credentials
graphurl="https://graph.microsoft.com/beta/servicePrincipals/${spid}/synchronization/secrets"
rm -f ./para.json
echo "{"  > ./para.json
echo "\t\"value\": [" >> ./para.json
echo "\t\t{ \"key\": \"BaseAddress\", \"value\" : $baseUrl  }," >> ./para.json
echo "\t\t{ \"key\": \"SecretToken\", \"value\" : \"$secretToken\"  }" >> ./para.json
echo "\t]" >> ./para.json
echo "}\n" >> ./para.json
echo $graphurl
curl -X PUT -H "Authorization: Bearer $token" -d @para.json $graphurl  -H "Content-Type: application/json" |jq

echo  "Saved Credentials....  "
#Get Job Id


echo  "Getting Job Details.....  "
#Start Job
Jobidnew=`echo ${JobId}| sed 's/\"//g'`
echo $Jobidnew

echo  "Starting  Job Details.....  "
graphurl="https://graph.microsoft.com/beta/servicePrincipals/${spid}/synchronization/jobs/${Jobidnew}/start"
curl -X POST -H "Authorization: Bearer $token" -d @para.json $graphurl  -H "Content-Type: application/json" | jq

