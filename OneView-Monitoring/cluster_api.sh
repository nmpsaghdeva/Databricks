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

process_jobs() {
	tok=$2
	url=$1
	host=$5
	token_info=`curl -X GET -H 'Content-Type: application/json' -H 'Authorization: Bearer '${tok}  "${url}/api/2.0/jobs/list/"`
	token_ctr=`echo $token_info | jq '.jobs | length'`
	echo "Total Jobs are : $token_ctr"	
	j=0
       	while [ $j -lt $token_ctr ]
       	do   
		# Fetch Jobs details
		var_sc=".jobs[$j].job_id"
		var_job_id=`echo $token_info | jq ${var_sc} | sed s/\"//g`
		var_sc=".jobs[$j].settings.name"
		var_job_name=`echo $token_info | jq ${var_sc} | sed s/\"//g`
		var_sc=".jobs[$j].settings.new_cluster.spark_version"
		var_job_spk_ver=`echo $token_info | jq ${var_sc} | sed s/\"//g`
		var_sc=".jobs[$j].settings.new_cluster.node_type_id"
		var_job_node_type=`echo $token_info | jq ${var_sc} | sed s/\"//g`
		var_sc=".jobs[$j].settings.new_cluster.spark_env_vars.PYSPARK_PYTHON"
		var_spk_env_vars=`echo $token_info | jq ${var_sc} | sed s/\"//g`
		var_sc=".jobs[$j].settings.new_cluster.enable_elastic_disk"
		var_job_ela_disk=`echo $token_info | jq ${var_sc} | sed s/\"//g`
		var_sc=".jobs[$j].settings.new_cluster.azure_attributes.availability"
		var_job_availability=`echo $token_info | jq ${var_sc} | sed s/\"//g`
		var_sc=".jobs[$j].settings.new_cluster.num_workers"
		var_job_workers=`echo $token_info | jq ${var_sc} | sed s/\"//g`
		var_sc=".jobs[$j].settings.email_notifications"
		var_job_email=`echo $token_info | jq ${var_sc} | sed s/\"//g`
		var_sc=".jobs[$j].settings.timeout_seconds"
		var_job_timeout=`echo $token_info | jq ${var_sc} | sed s/\"//g`
		var_sc=".jobs[$j].settings.notebook_task.notebook_path"
		var_job_notebook_path=`echo $token_info | jq ${var_sc} | sed s/\"//g`
		var_sc=".jobs[$j].settings.max_concurrent_runs"
		var_job_con_run=`echo $token_info | jq ${var_sc} | sed s/\"//g`
		var_sc=".jobs[$j].created_time"
		var_job_start_timestamp=`echo $token_info | jq ${var_sc}| sed s/\"//g | cut -c-10`
		var_job_st_dt=`date -d @${var_job_start_timestamp} +"%d-%b-%y %H:%M:%S"`
		var_sc=".jobs[$j].creator_user_name"
		var_job_creator=`echo $token_info | jq ${var_sc} | sed s/\"//g`

		echo $host,$var_job_id,$var_job_name,$var_job_spk_ver,$var_job_node_type,$var_spk_env_vars,$var_job_ela_disk,$var_job_availability,$var_job_workers,$var_job_email,$var_job_timeout,$var_job_notebook_path,$var_job_con_run,$var_job_st_dt,$var_job_creator >> $3/$4

		echo 
		j=`expr $j + 1`
	done
}

process_instance_pool() {
	tok=$2
	url=$1
	host=$5
	token_info=`curl -X GET -H 'Content-Type: application/json' -H 'Authorization: Bearer '${tok}  "${url}/api/2.0/instance-pools/list/"`
	token_ctr=`echo $token_info | jq '.instance_pools | length'`
	echo "Total Instance Pool  are : $token_ctr"	
	j=0
       	while [ $j -lt $token_ctr ]
       	do   
		# Fetch Instance Pool details
		var_sc=".instance_pools[$j].instance_pool_name"
		var_pool_name=`echo $token_info | jq ${var_sc} | sed s/\"//g`
		var_sc=".instance_pools[$j].min_idle_instances"
		var_min_idel_ins=`echo $token_info | jq ${var_sc} | sed s/\"//g`
		var_sc=".instance_pools[$j].max_capacity"
		var_max_cap=`echo $token_info | jq ${var_sc} | sed s/\"//g`
		var_sc=".instance_pools[$j].node_type_id"
		var_node_type=`echo $token_info | jq ${var_sc} | sed s/\"//g`
		var_sc=".instance_pools[$j].idle_instance_autotermination_minutes"
		var_autoterminiation_min=`echo $token_info | jq ${var_sc} | sed s/\"//g`
		var_sc=".instance_pools[$j].enable_elastic_disk"
		var_ela_disk=`echo $token_info | jq ${var_sc} | sed s/\"//g`
		var_sc=".instance_pools[$j].instance_pool_id"
		var_ins_pool_id=`echo $token_info | jq ${var_sc} | sed s/\"//g`
		var_sc=".instance_pools[$j].state"
		var_state=`echo $token_info | jq ${var_sc} | sed s/\"//g`
		var_sc=".instance_pools[$j].stats.used_count"
		var_used_ctr=`echo $token_info | jq ${var_sc} | sed s/\"//g`
		var_sc=".instance_pools[$j].stats.idle_count"
		var_idel_ctr=`echo $token_info | jq ${var_sc} | sed s/\"//g`
		var_sc=".instance_pools[$j].stats.pending_used_count"
		var_pen_used_ctr=`echo $token_info | jq ${var_sc} | sed s/\"//g`
		var_sc=".instance_pools[$j].stats.pending_idle_count"
		var_pen_idel_ctr=`echo $token_info | jq ${var_sc} | sed s/\"//g`
		var_sc=".instance_pools[$j].status"
		var_status=`echo $token_info | jq ${var_sc} | sed s/\"//g`

		echo $host,$var_pool_name,$var_min_idel_ins,$var_max_cap,$var_node_type,$var_autoterminiation_min,$var_ela_disk,$var_ins_pool_id,$var_state,$var_used_ctr,$var_idel_ctr,$var_pen_used_ctr,$var_pen_idel_ctr,$var_status >> $3/$4

		echo 
		j=`expr $j + 1`
	done

}




i=0
j=0
FileName="clusters_drivers.csv"
storageaccountName=`echo $storageaccount | cut -d- -f2`
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
        if [ -z "${host_name}" ]  || [ -z "${storageaccount}" ] ; then
                echo "Unable to get details of Source Server "
        else
    	 full_secret_path=`az keyvault secret list --vault-name $vault_name | jq  --raw-output '.[]|(.id)'| grep $secret_name`
	 get_token=`az keyvault secret show --id $full_secret_path |  jq '.value' | sed s/\"//g`
       	 full_url="https://${host_name}"

	 token_info=`curl -X GET -H 'Content-Type: application/json' -H 'Authorization: Bearer '${get_token}  "${full_url}/api/2.0/clusters/list"`
	 token_ctr=`echo $token_info | jq '.clusters | length'`
  	 echo "Total Clusters are : $token_ctr"	
	 #process Workspace information	

	 FileName="instance_pool.csv"
	 process_instance_pool ${full_url} ${get_token} ${path} ${FileName} ${host_name}
	 FileName="jobs.csv"
	 process_jobs ${full_url} ${get_token} ${path} ${FileName} ${host_name}

	 # Procss Cluster information 
	 j=0
       	 while [ $j -lt $token_ctr ]
       	 do   
		# Fetch Cluster Driver details where applicable 
		var_sc=".clusters[$j].cluster_id"
		var_cluster_id=`echo $token_info | jq ${var_sc} | sed s/\"//g`
		var_sc=".clusters[$j].driver.node_id"
		var_driver_node_id=`echo $token_info | jq ${var_sc}| sed s/\"//g`
		if [ "$var_driver_node_id" != "null" ]; then 
			var_sc=".clusters[$j].driver.public_dns"
			var_driver_public_dns=`echo $token_info | jq ${var_sc}| sed s/\"//g`
			var_sc=".clusters[$j].driver.instance_id"
			var_driver_instance_id=`echo $token_info | jq ${var_sc}| sed s/\"//g`
			var_sc=".clusters[$j].driver.start_timestamp"
			var_driver_start_timestamp=`echo $token_info | jq ${var_sc}| sed s/\"//g | cut -c-10`
			var_driver_start_date=`date -d @${var_driver_start_timestamp} +"%d-%b-%y %H:%M:%S"`
			var_sc=".clusters[$j].driver.host_private_ip"
			var_driver_host_private_ip=`echo $token_info | jq ${var_sc}| sed s/\"//g`
			var_sc=".clusters[$j].driver.private_ip"
 			var_driver_private_ip=`echo $token_info | jq ${var_sc}| sed s/\"//g`
			FileName="clusters_drivers.csv"
			echo "${host_name},${var_cluster_id},${var_driver_public_dns},${var_driver_node_id},${var_driver_instance_id},${var_driver_start_date},${var_driver_host_private_ip},${var_driver_private_ip}" >> $path/${FileName}
		fi 

		var_sc=".clusters[$j].executors"
		var_executors=`echo $token_info | jq ${var_sc}| sed s/\"//g`
		if [ "$var_executors" != "null" ]; then 
			var_sc=".clusters[$j].executors|length"
			No_of_executors=`echo $token_info | jq ${var_sc}`
			echo "No of Eecutors are ==> $No_of_executors"	
	 		k=0
		       	while [ $k -lt $No_of_executors ]
		       	do  
				var_sc=".clusters[$j].executors[$k].public_dns"
				var_execu_pub_dns=`echo $token_info | jq ${var_sc}| sed s/\"//g`
				var_sc=".clusters[$j].executors[$k].node_id"
				var_execu_node_id=`echo $token_info | jq ${var_sc}| sed s/\"//g`
				var_sc=".clusters[$j].executors[$k].instance_id"
				var_execu_instance_id=`echo $token_info | jq ${var_sc}| sed s/\"//g`
				var_sc=".clusters[$j].executors[$k].start_timestamp"
				var_execu_start_timestamp=`echo $token_info | jq ${var_sc}| sed s/\"//g | cut -c -10`
				var_exec_st_dt=`date -d @${var_execu_start_timestamp} +"%d-%b-%y %H:%M:%S"`
				var_sc=".clusters[$j].executors[$k].host_private_ip"
				var_execu_host_private_ip=`echo $token_info | jq ${var_sc}| sed s/\"//g`
				var_sc=".clusters[$j].executors[$k].private_ip"
				var_execu_private_ip=`echo $token_info | jq ${var_sc}| sed s/\"//g`
			
				FileName="clusters_excutors.csv"
				echo "${host_name},${var_cluster_id},${var_execu_pub_dns},${var_execu_node_id},${var_execu_instance_id},${var_exec_st_dt},${var_execu_host_private_ip},${var_execu_private_ip}" >> $path/${FileName}
				k=`expr $k + 1`
				 
			done
		fi

		# Fetch Cluster Common details  
		FileName="clusters_master.csv"
		var_sc=".clusters[$j].spark_context_id"
		var_sc_id=`echo $token_info | jq ${var_sc} | sed s/\"//g`
		var_sc=".clusters[$j].cluster_name"
		var_clu_name=`echo $token_info | jq ${var_sc} | sed s/\"//g`
		var_sc=".clusters[$j].spark_version"
		var_sp_ver=`echo $token_info | jq ${var_sc} | sed s/\"//g`
		var_sc=".clusters[$j].node_type_id"
		var_node_type=`echo $token_info | jq ${var_sc} | sed s/\"//g`
		var_sc=".clusters[$j].driver_node_type_id"
		var_driver_node_type=`echo $token_info | jq ${var_sc} | sed s/\"//g`
		var_sc=".clusters[$j].autotermination_minutes"
		var_auto_termi_minu=`echo $token_info | jq ${var_sc} | sed s/\"//g`
		var_sc=".clusters[$j].enable_elastic_disk"
		var_elastick_disk=`echo $token_info | jq ${var_sc} | sed s/\"//g`
		var_sc=".clusters[$j].cluster_source"
		var_cluster_source=`echo $token_info | jq ${var_sc} | sed s/\"//g`
		var_sc=".clusters[$j].enable_local_disk_encryption"
		var_encry=`echo $token_info | jq ${var_sc} | sed s/\"//g`
		var_sc=".clusters[$j].state"
		var_state=`echo $token_info | jq ${var_sc} | sed s/\"//g`
		var_sc=".clusters[$j].start_time"
		var_start_time=`echo $token_info | jq ${var_sc} | sed s/\"//g | cut -c-10`
		var_start_dt=`date -d @${var_start_time} +"%d-%b-%y %H:%M:%S"`
		var_sc=".clusters[$j].autoscale.min_workers"
		var_min_workers=`echo $token_info | jq ${var_sc} | sed s/\"//g`
		var_sc=".clusters[$j].autoscale.max_workers"
		var_max_workers=`echo $token_info | jq ${var_sc} | sed s/\"//g`
		var_sc=".clusters[$j].cluster_memory_mb"
		var_memory=`echo $token_info | jq ${var_sc} | sed s/\"//g`
		var_sc=".clusters[$j].cluster_cores"
		var_cores=`echo $token_info | jq ${var_sc} | sed s/\"//g`
		var_sc=".clusters[$j].creator_user_name"
		var_cluster_creator=`echo $token_info | jq ${var_sc} | sed s/\"//g`
		var_sc=".clusters[$j].init_scripts_safe_mode"
		var_safe_mode=`echo $token_info | jq ${var_sc} | sed s/\"//g`
		
		echo "${host_name},${var_cluster_id},${var_sc_id},${var_clu_name},${var_sp_ver},${var_node_type},${var_driver_node_type},${var_auto_termi_minu},${var_elastick_disk},${var_cluster_source},${var_encry},${var_state},${var_start_dt},${var_min_workers},${var_max_workers},${var_memory},${var_cores},${var_cluster_creator},${var_safe_mode}" >> $path/${FileName}

		j=`expr $j + 1`
	 done
	fi
   var_sc=".[]|(.id)"
   full_secret_path=`az keyvault secret list --vault-name $vault_name  | jq  --raw-output $var_sc |grep $storageaccount`
   get_stg_token=`az keyvault secret show --id $full_secret_path |  jq '.value' | sed s/\"//g`
   fi
   i=`expr $i + 1`
done
#   Container_exists=`az storage container exists --account-name $storageaccountName --account-key $get_stg_token --name backup-restapidata| jq '.exists'`
#   echo "Container ==> $Container_exists"
#   if [ $Container_exists = "false" ]; then
#  	     echo "Creating Container ==> backup-restapidata"
#       	     az storage container create --account-name $storageaccountName --account-key $get_stg_token --name backup-restapidata
#  fi
#  File_exists=`az storage blob exists --account-key $get_stg_token --account-name ${storageaccountName} --container-name backup-secretscope --name $FileName | jq '.exists'`
#  echo "CSV File exists   >> $File_exists"
#  if [ $File_exists = "true" ]; then
#     echo "Deleting existing old file"
#     az storage blob delete --account-key ${get_stg_token} --account-name ${storageaccountName} --container-name backup-restapidata --name /${FileName}
#  fi
#  az storage blob upload --account-key ${get_stg_token} --account-name ${storageaccountName} --container-name backup-retapidata --file ${path}/${FileName} --name /${FileName}
