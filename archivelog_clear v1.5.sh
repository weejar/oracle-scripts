#!/bin/sh

# File: archivelog_clear.sh
# Purpose: monitor archive_dest usage. do remove archivelog automatic if usage more than 80% 
# Author: weejar(www.anbob.com)
# Version: 1.5

# usage: e.g NODE1  0,20,40 * * * * sh /home/oracle/sdbo/archivelog_clear.sh  >> /home/oracle/sdbo/archivelog_clear.log
# usage: e.g NODE2  10,30,50 * * * * sh /home/oracle/sdbo/archivelog_clear.sh  >> /home/oracle/sdbo/archivelog_clear.log

TMP_SQL_OUT_FILE=/tmp/_tmp_arch_path.ora
HOST_NAME=`hostname`

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
    echo " $ORACLE_SID is not available on $HOST_NAME !"    
    exit 96  
fi

#--execute SQL to get some diagnostic variables
unset SQLPATH ORACLE_PATH

# check archive log dest

$ORACLE_HOME/bin/sqlplus -S  "/ as sysdba" <<EOF > $TMP_SQL_OUT_FILE
archive log list
EOF

ARCH_STAT=`grep "Database log mode" $TMP_SQL_OUT_FILE|awk '{print $4}' `
if [ $? -ne 0 ]
then
    echo "check archivelog mode failed!"
    exit 95
fi
echo "Current archivelog mode: $ARCH_STAT"
if [ $ARCH_STAT != "Archive" ]
then
     echo "The database is not Archived log mode! exit."
	 exit 0
fi

ARCH_PATH=`grep "Archive destination" $TMP_SQL_OUT_FILE|awk '{print $3}' `

ARCH_PATH_MOUNT=$ARCH_PATH

ARCH_PATH_START=`echo $ARCH_PATH|cut -c 1`

ARCH_PATH_TYPE="UNKNOW"
if [[ "$ARCH_PATH_START" = '+' ]] ;then
   ARCH_PATH_TYPE="ASM"
fi

if [[ "$ARCH_PATH_START" = '/' ]] ;then
   ARCH_PATH_TYPE="NOASM"
# fix if ARCH_PATH endwith '/' df can not found  and more one level
   ARCH_PATH_MOUNT=`echo $ARCH_PATH|cut -d / -f 1,2`
fi


echo "archive destination : $ARCH_PATH"  
echo "archive destination type : $ARCH_PATH_TYPE"

# filesystem begin
if [ $ARCH_PATH_TYPE = "NOASM" ]
then
 echo "check filesystem"
 echo "*************************"

RMCMD="/usr/bin/rm "

ARCH_STYLE="${ARCH_PATH}/arch_*.arc"

PLATFORM=`/bin/uname`
echo "zzz ***"`date '+%a %b %e %T %Z %Y'` 

case $PLATFORM in
      Linux)
        FS_USAGE=`df|grep ${ARCH_PATH_MOUNT}|awk '{print $4}'|cut -d% -f1`
      ;;
      HP-UX|HI-UX)
        FS_USAGE=`bdf|grep ${ARCH_PATH_MOUNT}|awk '{print $4}'|cut -d% -f1`
      ;;
      AIX)
        FS_USAGE=`df|grep ${ARCH_PATH_MOUNT}|awk '{print $4}'|cut -d% -f1`
      ;;
	  SunOS)
        FS_USAGE=`df -h|grep "${ARCH_PATH_MOUNT} "|awk '{print $5}'|cut -d% -f1`
      ;;
    esac

cd ${ARCH_PATH} 
count=`ls -lrt $ARCH_STYLE|wc -l`
echo "Current archive location usage:"$FS_USAGE"%  number of archivelog files: "$count 

if [ $FS_USAGE -ge 80 ]
then 
   count=`ls -lrt $ARCH_STYLE|wc -l`
   echo "wc result:"$count
   if [ $count -ge 10 ]
   then
   count=`expr $count - 10`
   echo "head result:"$count
   delfile=`ls -lrt $ARCH_STYLE|head -$count|awk '{print $9}'`
#   ls -lrt $ARCH_STYLE|head -$count
   find $ARCH_STYLE |head -$count
   result=$?
   if [ "$result" -ne "0" ]
   then
      echo "Error retrieve information !"
      exit $result
   fi
   echo "del result:"$delfile
   echo  $RMCMD $delfile
   $RMCMD $delfile
   if [ $? -ne 0 ] 
   then
     echo "HAVE DELETE ARCHIVE LOG OF $HOST_NAME"
   fi

   fi
fi


# filesystem end
fi

# if asm begin
if [ $ARCH_PATH_TYPE = "ASM" ]
then
 echo "check asm"
 echo "*************************"
 
$ORACLE_HOME/bin/sqlplus -S  "/ as sysdba" <<EOF > $TMP_SQL_OUT_FILE
SET LINES 300
 select name,total_mb,free_mb,round((1-(free_mb/total_mb))*100) usage from v\$asm_diskgroup;
EOF

  DG_NAME=`echo $ARCH_PATH|cut -c2- |awk -F/ '{print $1}'`
if [ $? -ne 0 ]
then
    echo "get DG_NAME failed!"
    exit 94
fi
  
DG_USAGE=`grep  $DG_NAME  $TMP_SQL_OUT_FILE| awk '{print $4}'`
if [ $? -ne 0 ]
then
    echo "get DG_NAME usage failed!"
    exit 93
fi

echo "zzz ***"`date '+%a %b %e %T %Z %Y'` 
echo "Current archive location usage:"$DG_USAGE"% "
if [ $DG_USAGE -ge 80 ]
then 
echo "Note: Current DG USAGE: $DG_USAGE"
# delete archive log until 5hours 
$ORACLE_HOME/bin/rman  "target /" nocatalog  <<EOF
 DELETE force NOPROMPT ARCHIVELOG UNTIL TIME 'SYSDATE-5/24';
 CROSSCHECK ARCHIVELOG ALL;
 DELETE NOPROMPT EXPIRED ARCHIVELOG ALL;
EOF

fi


# if asm end
fi


