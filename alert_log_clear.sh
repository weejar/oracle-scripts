#!/bin/sh
# File: alert_log_clear.sh
# Author: weejar(www.anbob.com)
# Version: 0.2
# 0.2 2016/1/12  weejar 

echo "The current working directory: $PWD"
echo "Shell: $0"

# set file size limit
FILESIZELIMIT=300
# set oracle env

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


#--code
start=`date "+%Y-%m-%d %H:%M:%S"`

DB_STATE=`ps -ef | grep pmon_$ORACLE_SID | grep -v grep|wc -l`  

if [ 0 -eq $DB_STATE ]; then  
    echo " $ORACLE_SID is not available on `hostname` !"    
    exit 96  
fi


#--execute SQL to get some diagnostic variables
unset SQLPATH

DUMP_PATH=`sqlplus -S '/ as sysdba' << EOF  
set pagesize 0 feedback off verify off heading off echo off  
SELECT value FROM  v\\$parameter WHERE  name = 'background_dump_dest';  
exit  
EOF`  

echo "The background_dump_dest value: ${DUMP_PATH}"

if [ ! -d ${DUMP_PATH} ]; then  
    echo "The bdump directory was not found for ${ORACLE_SID}"  
    exit 95  
fi 

# alert trace file name
ALERT_FNAME=alert_${ORACLE_SID}.log

# alert trace file full name
ALERT_CUR="${DUMP_PATH}/${ALERT_FNAME}"

if [ ! -f ${ALERT_CUR} ]; then  
    echo "The alert log  was not found for ${ORACLE_SID}"  
    exit 94  
else  
    echo "The alert log filename : ${ALERT_FNAME}"
fi


ALERT_BAK="${ALERT_CUR}_last"
 
# alert trace file size 
FILESIZE=`ls -l ${ALERT_CUR}|awk '{ printf "%.0f", $5/1024/1024 }'`
echo "The alert log current filesize(MB):${FILESIZE}"
if [ ${FILESIZE} -gt ${FILESIZELIMIT} ]
then
 echo "The alert log is bigger than ${FILESIZELIMIT} MB"
 echo "The alert log will be backup to ${ALERT_BAK}"
 # cut alert log file
 echo "mv -f ${ALERT_CUR} ${ALERT_BAK}"
mv -f ${ALERT_CUR} ${ALERT_BAK}
# to generate a new alert
$ORACLE_HOME/bin/sqlplus -S  "/ as sysdba" <<EOF
set pagesize 0 feedback off verify off heading off echo off
exec dbms_system.ksdwrt(2, to_char(sysdate,'yyyy-mm-dd hh24:mi:ss'));
exec dbms_system.ksdwrt(2, 'the alert had archived by alert log clear shell!');
exec dbms_system.ksdfls;
exit  
EOF

 # to compress alchived alert log file
 echo "gzip -f ${ALERT_BAK}"
 gzip -f ${ALERT_BAK}
else
 echo "The alert log is litter than ${FILESIZELIMIT} MB"
fi


# remove alert trace file  longer than 30 days 

echo "To remove alert trace file(trc trm)  longer than 30 days"
cd ${DUMP_PATH}
find . -ctime +30 -type f \( -name "*.trm" -o -name "*.trc" \)  -exec rm -f {} \;

if [ $? -ne 0 ]
  then
  echo "ERROR: unable to rm alert trace file " 
fi


echo  `date "+%Y-%m-%d %H:%M:%S"`
echo "To clear alert log file complated!"  
echo  ""
echo  ""