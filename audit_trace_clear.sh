#!/bin/sh

# File: audit_trace_clear.sh
# Purpose: To remove large than 30 days Oracle logon audit trace files in 'audit_file_dest'  
# Author: weejar(www.anbob.com)
# Version: 0.1

echo "The current working directory: $PWD"
echo "Shell: $0"

if [[ -f ~/.profile ]]
then
. ~/.profile
fi

if [[ -f ~/.bash_profile ]]
then
. ~/.bash_profile
fi

USERID=`/usr/bin/id -u -nr`
if [ $? -ne 0 ]
then
    echo "ERROR: unable to determine uid" 
    exit 99
fi

echo "current user: ${USERID}"

if [ "${USERID}" != "oracle" ]
then
   echo "ERROR: This script must be run as oracle"  
   exit 98
fi

if [ ! $ORACLE_SID ]
    then
           echo "Error: No ORACLE_SID set or provided as an argument"
           exit 97
else
   echo "current ORACLE_SID: ${ORACLE_SID}"
fi

STTIME=`date "+%Y-%m-%d %H:%M:%S"`
echo $STTIME

DB_STATE=`ps -ef | grep pmon_$ORACLE_SID | grep -v grep|wc -l`  

if [ 0 -eq $DB_STATE ]; then  
    echo " $ORACLE_SID is not available on `hostname` !"    
    exit 96  
fi

#--execute SQL to get some diagnostic variables
unset SQLPATH

AUDIT_DIR=`sqlplus -S '/ as sysdba' << EOF  
set pagesize 0 feedback off verify off heading off echo off  
SELECT value FROM  v\\$parameter WHERE  name = 'audit_file_dest';  
exit  
EOF`  

if [ ! $? -eq 0 ] 
then
   echo "Get AUDIT_DIR PATH failed!"
   exit -1
fi

echo "audit file dest path: $AUDIT_DIR"

if [ ! -d ${AUDIT_DIR} ]; then  
    echo "The audit directory was not found for ${ORACLE_SID}"  
    exit 95  
else
    cd $AUDIT_DIR
    if [ $? -eq 0 ] 
    then
       find . -mtime +30 -type f -name "*.aud" -print -exec rm {} \;
	else
	   echo "Switch in $AUDIT_DIR failed!"
	   exit 94
    fi
fi
echo `date "+%Y-%m-%d %H:%M:%S"` Complated!