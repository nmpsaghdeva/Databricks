#!/bin/bash

if [ $# != 1 ]
then
  echo "Usage: $0 Enter Name of the Application "
  exit
fi
echo "{"  > ./para.json
echo "\"displayName\": \"$1\"" >> ./para.json
echo "}\n" >> ./para.json
response=$(az account get-access-token --resource-type ms-graph)
token=$(echo $response | jq ".accessToken" -r)
curl -X POST -H "Authorization: Bearer $token" -d @para.json https://graph.microsoft.com/beta/applicationTemplates/9c9818d2-2900-49e8-8ba4-22688be7c675/instantiate  -H "Content-Type: application/json" |jq