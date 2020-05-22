#!/bin/bash

if [ $# != 4 ]
then
  echo "Usage: $0 <Enter Name of the Application> <Application Admin Username> <Password> "
  exit
fi
rm -f ./para.json
echo "{"  > ./para.json
echo "\"displayName\": \"$1\"" >> ./para.json
echo "}\n" >> ./para.json
echo $2
echo $3

az login --service-principal --username $2 --password $3 --tenant $4
#az login --username $2 --password $3
response=$(az account get-access-token --resource-type ms-graph)
token=$(echo $response | jq ".accessToken" -r)
curl -X POST -H "Authorization: Bearer $token" -d @para.json https://graph.microsoft.com/beta/applicationTemplates/9c9818d2-2900-49e8-8ba4-22688be7c675/instantiate  -H "Content-Type: application/json" |jq
