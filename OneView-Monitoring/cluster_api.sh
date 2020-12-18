#!/bin/sh/
########################################################################################################################################
# Purpose       : This script is used to take export of token generated in a workspace

# Input         : It takes name of the configured key vault. Configured key vault means, where secret scopes have been configured as 
#		  per requirement of this program
# Parameter     : Name of the key vault having all secrets
#		  Temp Path to store temp files
#	          Batch Id 	
########################################################################################################################################
record_ctr=0
vault_name=$1
path=$2
batch_id=$3
DayOfWeek=$(date +%A)
if [ $# -ne 3 ]; then
        echo "Please provide valid <Key Vault Name > , <Path> & <Batch_id>"
        echo "Usage : <Key vault> <path of temp folder> <batch_id>"
        exit 1
fi
cd $path
ctr=`az keyvault secret list --vault-name $vault_name | jq 'length'`
echo  "No of secrets $ctr "
if [ ${ctr} -eq 0  ]; then
        echo "No Secret found in the key vault => $vaula_name , Please check "
        exit -1
fi

process_jobs() {
	tok=$2
	url=$1
	host=$5
	token_info=`curl -X GET -H 'Content-Type: application/json' -H 'Authorization: Bearer '${tok}  "${url}/api/2.0/jobs/list/"`
	token_ctr=`echo $token_info | jq '.jobs | length'`
	var_sc=".jobs"
	echo $token_info | jq ${var_sc}  > ${path}/temp.json
	sed '/"job_id"/i \    "Batch_id":"'${batch_id}'",\n    "host_name":"'${host}'",\n    "host_SName":"'${host_shortName}'",' temp.json > Jobs_${host}.json
	rec=`cat Jobs_${host}.json | wc -l`
	if [ $rec -lt 2 ]; then 
		echo "Deleting Empty Job File  <Jobs_${host}.json> " 
		rm Jobs_${host}.json
	fi 
}


process_secret_scopes () {
	tok=$2
	host_name=$1
	url="https://$1"
	host_shortName=$3
	CSVFileName='secret.csv'
	token_info=`curl -X GET -H 'Content-Type: application/json' -H 'Authorization: Bearer '${tok}  "${url}/api/2.0/secrets/scopes/list"`
	ctr_scope=`curl -X GET -H 'Content-Type: application/json' -H 'Authorization: Bearer '${tok}  "${url}/api/2.0/secrets/scopes/list" |jq '.scopes |length'`
       	var_sc=".scopes"
	echo $token_info | jq ${var_sc} > ./temp.json
	sed '/"name"/i \    "Batch_id":"'${batch_id}'",\n    "host_name":"'${host_name}'",\n    "host_SName":"'${host_shortName}'",' temp.json > ./secret_${host_shortName}.json
	rec=`cat ./secret_${host_shortName}.json | wc -l`
	if [ $rec -lt 2 ]; then 
		echo "Deleting Empty Secret  File  <secret_${host_shortName}.json> " 
		rm secret_${host_shortName}
	fi 	
}

process_instance_pool() {
	tok=$2
	url=$1
	host=$5
	token_info=`curl -X GET -H 'Content-Type: application/json' -H 'Authorization: Bearer '${tok}  "${url}/api/2.0/instance-pools/list/"`
	var_sc=".instance_pools"
	echo $token_info | jq ${var_sc} > ${path}/temp.json
	sed '/"instance_pool_name"/i \    "Batch_id":"'${batch_id}'",\n    "host_name":"'${host}'",\n    "host_SName":"'${host_shortName}'",' temp.json > instance_pool_${host}.json
	rec=`cat instance_pool_${host}.json | wc -l`
	if [ $rec -lt 2 ]; then 
		echo "Deleting Empty Instance Pool File  <instance_pool_${host}.json> " 
		rm instance_pool_${host}.json
	fi 
}



find_short_name() {

file=${path}/"ClusterMaster.csv"
label=$1
echo "Reading Master Data from ==> $file "
while IFS=, read -r shortname hostname Env
do
    if [ "${label}" = "${hostname}" ]; then
	host_shortName=$shortname
	return
    fi
    #Take action using input
done < $file
host_shortName="NotFound"
}



i=0
j=0
host_shortName="NotFound"
FileName="clusters_drivers.csv"
echo "host_name,cluster_id,driver_pubilc_dns,driver_node_id,driver_instance_id,driver_start_timestamp,driver_host_private_ip,driver_private_ip" > $path/${FileName}
FileName="clusters_master.csv"
echo "host_name,cluster_id,spark_context_id,cluster_name,spark_version,node_type_id,driver_node_type_id,autotermination_minutes,enable_elastic_disk,cluster_source" > $path/${FileName}

FileName="jobs.csv"
echo "Host_Name,job_id,Job_Name,spark_version,node_type_id,spark_env_vars,enable_elastic_disk,availability,num_workers,email_notifications,timeout_seconds,notebook_path,max_concurrent_runs,created_time,creator_user_name" > $path/${FileName}
FileName="instance_pool.csv"
echo "Host_name,instance_pool_name,min_idle_instances,max_capacity,node_type_id,idle_instance_autotermination_minutes,enable_elastic_disk,instance_pool_id,state,stats.used_count,stats.idle_count,stats.pending_used_count,stats.pending_idle_count,status" > $path/${FileName}
FileName="clusters_excutors.csv"
echo "host_name,cluster_id,public_dns,Node_id,isntance_id,start_date,host_private_ip,private_ip" > $path/${FileName}
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
        if [ -z "${host_name}" ]  ; then
                echo "Unable to get details of Source Server "
        else
    	 full_secret_path=`az keyvault secret list --vault-name $vault_name | jq  --raw-output '.[]|(.id)'| grep $secret_name`
	 get_token=`az keyvault secret show --id $full_secret_path |  jq '.value' | sed s/\"//g`
       	 full_url="https://${host_name}"

	 token_info=`curl -X GET -H 'Content-Type: application/json' -H 'Authorization: Bearer '${get_token}  "${full_url}/api/2.0/clusters/list"`
	 token_ctr=`echo $token_info | jq '.clusters | length'`
         find_short_name $host_name
	 var_sc=".clusters"
	 echo $token_info | jq ${var_sc}  > ${path}/temp.json
	 sed '/"cluster_id"/i \    "Batch_id":"'${batch_id}'",\n    "host_name":"'${host_name}'",\n    "host_SName":"'${host_shortName}'",'  temp.json > cluster_${host_name}.json
	rec=`cat cluster_${host_name}.json | wc -l`
	if [ $rec -lt 2 ]; then 
		echo "Deleting Empty Cluster File  <cluster_${host_name}.json> " 
		rm cluster_${host_name}.json
	fi 
	 echo "Total Clusters are : $token_ctr"	
	 #process Workspace information	

	 FileName="instance_pool.csv"
	 process_instance_pool ${full_url} ${get_token} ${path} ${FileName} ${host_name}
	 FileName="jobs.csv"
	 process_jobs ${full_url} ${get_token} ${path} ${FileName} ${host_name}

	 process_secret_scopes  ${host_name}  ${get_token} ${host_shortName}

	 # Procss Cluster information 
	 j=0
#       	 while [ $j -lt $token_ctr ]
#      	 do   
#	# Fetch Cluster Driver details where applicable 
#	var_sc=".clusters[$j].cluster_id"
#	var_cluster_id=`echo $token_info | jq ${var_sc} | sed s/\"//g`
#	var_sc=".clusters[$j].driver.node_id"
#	var_driver_node_id=`echo $token_info | jq ${var_sc}| sed s/\"//g`
#	if [ "$var_driver_node_id" != "null" ]; then 
#		var_sc=".clusters[$j].driver.public_dns"
#		var_driver_public_dns=`echo $token_info | jq ${var_sc}| sed s/\"//g`
#		var_sc=".clusters[$j].driver.instance_id"
#		var_driver_instance_id=`echo $token_info | jq ${var_sc}| sed s/\"//g`
#		var_sc=".clusters[$j].driver.start_timestamp"
#		var_driver_start_timestamp=`echo $token_info | jq ${var_sc}| sed s/\"//g | cut -c-10`
#		var_driver_start_date=`date -d @${var_driver_start_timestamp} +"%d-%b-%y %H:%M:%S"`
#		var_sc=".clusters[$j].driver.host_private_ip"
#		var_driver_host_private_ip=`echo $token_info | jq ${var_sc}| sed s/\"//g`
#		var_sc=".clusters[$j].driver.private_ip"
#			var_driver_private_ip=`echo $token_info | jq ${var_sc}| sed s/\"//g`
#		FileName="clusters_drivers.csv"
#		echo "${host_name},${var_cluster_id},${var_driver_public_dns},${var_driver_node_id},${var_driver_instance_id},${var_driver_start_date},${var_driver_host_private_ip},${var_driver_private_ip}" >> $path/${FileName}
#	fi 

#	var_sc=".clusters[$j].executors"
#	var_executors=`echo $token_info | jq ${var_sc}| sed s/\"//g`
#	if [ "$var_executors" != "null" ]; then 
#		var_sc=".clusters[$j].executors|length"
#		No_of_executors=`echo $token_info | jq ${var_sc}`
#		echo "No of Eecutors are ==> $No_of_executors"	
# 		k=0
#	       	while [ $k -lt $No_of_executors ]
#	       	do  
#			var_sc=".clusters[$j].executors[$k].public_dns"
#			var_execu_pub_dns=`echo $token_info | jq ${var_sc}| sed s/\"//g`
#			var_sc=".clusters[$j].executors[$k].node_id"
#			var_execu_node_id=`echo $token_info | jq ${var_sc}| sed s/\"//g`
#			var_sc=".clusters[$j].executors[$k].instance_id"
#			var_execu_instance_id=`echo $token_info | jq ${var_sc}| sed s/\"//g`
#			var_sc=".clusters[$j].executors[$k].start_timestamp"
#			var_execu_start_timestamp=`echo $token_info | jq ${var_sc}| sed s/\"//g | cut -c -10`
#			var_exec_st_dt=`date -d @${var_execu_start_timestamp} +"%d-%b-%y %H:%M:%S"`
#			var_sc=".clusters[$j].executors[$k].host_private_ip"
#			var_execu_host_private_ip=`echo $token_info | jq ${var_sc}| sed s/\"//g`
#			var_sc=".clusters[$j].executors[$k].private_ip"
#			var_execu_private_ip=`echo $token_info | jq ${var_sc}| sed s/\"//g`
#		
#			FileName="clusters_excutors.csv"
#			echo "${host_name},${var_cluster_id},${var_execu_pub_dns},${var_execu_node_id},${var_execu_instance_id},${var_exec_st_dt},${var_execu_host_private_ip},${var_execu_private_ip}" >> $path/${FileName}
#			k=`expr $k + 1`
#			 
#		done
#	fi
#	j=`expr $j + 1`
# done
	fi
   var_sc=".[]|(.id)"
   fi
   i=`expr $i + 1`
done