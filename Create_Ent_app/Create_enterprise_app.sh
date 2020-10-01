#!/bin/bash

if [ $# != 3 ]
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

az login --service-principal --username 4ae3d5ed-bbd0-485d-956b-19c0378940a2 --password 0e9ca1ef-d135-4bd4-8968-f7c0af168a56 --tenant bc111fcd-1154-4322-b437-799c66a7677c
#az login --username $2 --password $3
response=$(az account get-access-token --resource-type ms-graph)
token=$(echo $response | jq ".accessToken" -r)
curl -X POST -H "Authorization: Bearer $token" -d @para.json https://graph.microsoft.com/beta/applicationTemplates/9c9818d2-2900-49e8-8ba4-22688be7c675/instantiate  -H "Content-Type: application/json" |jq
