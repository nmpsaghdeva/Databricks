#!/bin/sh/
########################################################################################################################################
# Purpose       : This script is used to take export of token generated in a workspace

# Input         : It takes name of the configured key vault. Configured key vault means, where secret scopes have been configured as 
#		  per requirement of this program
# Parameter     : Name of the key vault having all secrets
#		  Name of the storage account secret name. It has to be in the same key vault (parameter 1 )
#		  Temp Path to store temp files
########################################################################################################################################
record_ctr=0
vault_name=$1
storageaccount=$2
path=$3
DayOfWeek=$(date +%A)
if [ $# -ne 3 ]; then
        echo "Please provide valid <Key Vault Name > & <Path> "
        echo "Usage : <Key vault> and <path of temp folder> "
        exit 1
fi
cd $path
ctr=`az keyvault secret list --vault-name $vault_name | jq 'length'`
echo  "No of secrets $ctr "
if [ ${ctr} -eq 0  ]; then
        echo "No Secret found in the key vault => $vaula_name , Please check "
        exit -1
fi

i=0
j=0
FileName="token_details.csv"
storageaccountName=`echo $storageaccount | cut -d- -f2`
echo "host_name,token_id,creation_time,expiry_time,comment,created_by_id,created_by_username" > $path/${FileName}
while [ $i -lt $ctr ]
do
    var_sc=".[$i]|(.name)"
    secret_name=`az keyvault secret list --vault-name $vault_name  | jq  --raw-output $var_sc`
    var_sc=".[$i]|(.contentType)"
    string=`az keyvault secret list --vault-name $vault_name  | jq  --raw-output $var_sc`
    object_type=`echo $string | cut -d# -f1`
    host_name=`echo $string | cut -d# -f2`
    migration_yn=`echo $string | cut -d# -f4`
    target_host=`echo $string | cut -d# -f5`
    target_secret=`echo $string | cut -d# -f6`
    if [ $object_type = "secretscope" ] ; then
    echo "Processing ${secret_name}"
        if [ -z "${host_name}" ]  || [ -z "${storageaccount}" ] ; then
                echo "Unable to get details of Source Server "
        else
    	 full_secret_path=`az keyvault secret list --vault-name $vault_name | jq  --raw-output '.[]|(.id)'| grep $secret_name`
	 get_token=`az keyvault secret show --id $full_secret_path |  jq '.value' | sed s/\"//g`
       	 full_url="https://${host_name}"

	 token_info=`curl -X GET -H 'Content-Type: application/json' -H 'Authorization: Bearer '${get_token}  "${full_url}/api/2.0/token-management/tokens"`
	 token_ctr=`echo $token_info | jq '.token_infos | length'`
	 echo $token_info
  	 echo "total Token are : $token_ctr"	
	 j=0
       	 while [ $j -lt $token_ctr ]
       	 do   
		var_sc=".token_infos[$j].token_id"
		var_token=`echo $token_info | jq ${var_sc} | sed s/\"//g`
		var_sc=".token_infos[$j].creation_time"
		var=`echo $token_info | jq ${var_sc}| sed s/\"//g`
		var_creation_time=`echo $token_info | jq ${var_sc}| sed s/\"//g | cut -c-10`
		var_creation_date=`date -d @${var_creation_time}`
		var_sc=".token_infos[$j].expiry_time"
		var_expiry_time=`echo $token_info | jq ${var_sc}| sed s/\"//g | cut -c-10`
		var_expiry_date=`date -d @${var_expiry_time}`
		var_sc=".token_infos[$j].comment"
		var_comment=`echo $token_info | jq ${var_sc}| sed s/\"//g`
		var_sc=".token_infos[$j].created_by_id"
		var_created_by_id=`echo $token_info | jq ${var_sc}| sed s/\"//g`
		var_sc=".token_infos[$j].created_by_username"
		var_username=`echo $token_info | jq ${var_sc}| sed s/\"//g`
		echo "${host_name},${var_token},${var_creation_date},${var_expiry_date},${var_comment},${var_created_by_id},${var_username}" >> $path/${FileName}
		j=`expr $j + 1`
	 done
	fi
   var_sc=".[]|(.id)"
   full_secret_path=`az keyvault secret list --vault-name $vault_name  | jq  --raw-output $var_sc |grep $storageaccount`
   get_stg_token=`az keyvault secret show --id $full_secret_path |  jq '.value' | sed s/\"//g`
   fi
   i=`expr $i + 1`
done
   Container_exists=`az storage container exists --account-name $storageaccountName --account-key $get_stg_token --name backup-restapidata| jq '.exists'`
   echo "Container ==> $Container_exists"
   if [ $Container_exists = "false" ]; then
  	     echo "Creating Container ==> backup-restapidata"
       	     az storage container create --account-name $storageaccountName --account-key $get_stg_token --name backup-restapidata
  fi
  File_exists=`az storage blob exists --account-key $get_stg_token --account-name ${storageaccountName} --container-name backup-secretscope --name $FileName | jq '.exists'`
  echo "CSV File exists   >> $File_exists"
  if [ $File_exists = "true" ]; then
     echo "Deleting existing old file"
     az storage blob delete --account-key ${get_stg_token} --account-name ${storageaccountName} --container-name backup-restapidata --name /${FileName}
  fi
  az storage blob upload --account-key ${get_stg_token} --account-name ${storageaccountName} --container-name backup-retapidata --file ${path}/${FileName} --name /${FileName}
