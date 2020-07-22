#!/bin/bash

if [ $# != 4 ]
then
  echo "Usage: $0 <Enter Source HostName> <Enter Target hostname> <Source Token> <Target Token> "
  exit
fi

source_host=$1
target_host=$2
source_token=$3
target_token=$4
i=0
# setup Databricks Profile and change code later
echo  "machine  ${source_host}"  > ./netrc_source
echo  "login token "  >> ./netrc_source
echo  "password  ${source_token}"  >> ./netrc_source

echo  "machine  ${target_host}"  > ./netrc_target
echo  "login token "  >> ./netrc_target
echo  "password  ${target_token}"  >> ./netrc_target

cp netrc_source .netrc
###################### End profile setup #################

var_url="https://${source_host}/api/2.0/secrets/scopes/list"

ctr_scope=`curl  -n -X GET -H 'Content-Type: application/json'  $var_url | jq '.scopes | length'`
echo "No of Scopes  ${ctr_scope}"
while [ $i -lt $ctr_scope ]
do
   cp netrc_source .netrc
   var_url="https://${source_host}/api/2.0/secrets/scopes/list"
   echo "Ctr value ==> $i"
   var_sc=".scopes[$i]"
   echo $var_sc
   curl  -n -X GET -H 'Content-Type: application/json' ${var_url} | jq $var_sc  > ./script_Secret_scope${i}.json
   sed -i 's/name/scope/g' ./script_Secret_scope${i}.json
   sed -i '3 i   \"initial_manage_principal\":\"users\",' ./script_Secret_scope${i}.json

   cp netrc_target .netrc

   var_url="https://${target_host}/api/2.0/secrets/scopes/create"
   curl  -n -X POST -d @script_Secret_scope${i}.json $var_url
   i=`expr $i + 1`
done