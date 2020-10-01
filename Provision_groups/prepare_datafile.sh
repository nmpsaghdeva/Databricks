#!/bin/bash
#########################################################################################################################
# Purpose : Script to take groups and users as a string and split it to process for adding it to Enterprise application #
# i                                                                                                                     #
# Parrameters: It takes 3 parameters                                                                                    #
#               1. Path where csv files will be saved                                                                   #
#               2. Groups to be added as a string separated by comma                                                    #
#               3. Comma separated users list                                                                           #
##########################################################################################################################

var_grps=$2
var_users=$3
path=$1

if [ $# -lt 2 ]
then
    echo "Please provide all mandatory parrameters "
    echo "Usage : <path of temp folder> <Groups> <users> "
    echo "User parrameter is optional "
    return
fi

if [ -z "${var_grps}" ]
then
        echo "Please add groups to be synced with enterprise application"
        exit 1
fi
var_array=`echo $var_grps | tr "," "\n"`
echo "ObjectName, ObjectType" > $path/data.csv
#Print the split string
for i in $var_array
do
    echo "$i,Group" >> $path/data.csv
done

if [ -n "${var_users}" ]
then
        arr_users=`echo $var_users | tr "," "\n"`
        for i in $arr_users
        do
            echo "$i,User" >> $path/data.csv
        done
fi
