#!/bin/bash
# +---------------------------------------------------------------+
# |--Name         : RMAN delete archivelog file                   |
# |--Execute Time : 0                                             |
# |--Author       : weejar                                        |
# |--Memo         : 0-Sun 1-Mon 2-Tue 3-Wed 4-Thu 5-Fri 6-Sat     |
# +---------------------------------------------------------------+
# 
# note: we can use  Force to delete archivelog when 'RMAN-08137: WARNING: archived log not deleted as it is still needed'
. ~/.bash_profile

BackupDate=`date +%Y%m%d%H%M%S`
LogDir=/home/oracle/arch/

# Check user is oracle
USERID=`/usr/bin/id -u -nr`
if [ $? -ne 0 ]
then
        echo "ERROR: unable to determine uid" >> $LOGFILE
        exit 99
fi
if [ "${USERID}" != "oracle" ]
then
        echo "ERROR: This script must be run as oracle" >> $LOGFILE
        exit 98
fi

#--+------------------------------------
#--|--delete logfile before 20 days
#--+------------------------------------
rm -rf ${LogDir}delete_archivelog_`date -d "-7 days" +%Y%m%d`*.log

rman target / nocatalog msglog=${LogDir}delete_archivelog_${BackupDate}.log <<-EOF
 DELETE NOPROMPT ARCHIVELOG UNTIL TIME 'SYSDATE-20';
 CROSSCHECK ARCHIVELOG ALL;
 DELETE NOPROMPT EXPIRED ARCHIVELOG ALL;
EOF

