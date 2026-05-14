#!/bin/bash

# rman backup database 
# level: 0

# for linux
source /home/oracle/.bash_profile

# how to use
# need to confile RMAN backup retention, default 1 
# RMAN> configure retention policy to recovery window of 15 days;
# mkdir -p /backup/rmanbak/logs
# chown -R oracle:oinstall /backup
# sh rman_backup_lv0.sh 
# crontab 
# 0 0 * * * sh /backup/rmanbak/rman_backup_lv0.sh 

RMAN_LOG_FILE=/mesmdw_backup/rmanbak/logs/rman_database_backup.`date +%y%m%d%H%M`.out
RMAN_BACK_PATH=/mesmdw_backup/rmanbak
# -----------------------------------------------------------------
# Initialize the log file.
# -----------------------------------------------------------------

echo>> $RMAN_LOG_FILE
chmod 666 $RMAN_LOG_FILE

echo Script $0>> $RMAN_LOG_FILE
echo ==== started on `date` ====>> $RMAN_LOG_FILE
echo>> $RMAN_LOG_FILE

ORACLE_USER=oracle

RMAN=$ORACLE_HOME/bin/rman
BACKUP_TYPE="INCREMENTAL LEVEL 0"

# ---------------------------------------------------------------------------
# Print out the value of the variables set by this script.
# ---------------------------------------------------------------------------
echo>> $RMAN_LOG_FILE
echo "RMAN: $RMAN">> $RMAN_LOG_FILE
echo "ORACLE_SID: $ORACLE_SID">> $RMAN_LOG_FILE
echo "ORACLE_USER: $ORACLE_USER">> $RMAN_LOG_FILE
echo "ORACLE_HOME: $ORACLE_HOME">> $RMAN_LOG_FILE
echo "BACKUP_TYPE: $BACKUP_TYPE">> $RMAN_LOG_FILE
# ---------------------------------------------------------------------------

echo >> $RMAN_LOG_FILE

exec 1>> $RMAN_LOG_FILE 2>&1

$RMAN target / nocatalog  <<-EOF
RUN {
 ALLOCATE CHANNEL ch00 TYPE disk;
 ALLOCATE CHANNEL ch01 TYPE disk;
 BACKUP  AS COMPRESSED BACKUPSET $BACKUP_TYPE  
 SKIP INACCESSIBLE
 TAG hot_db_bk_level0
 FORMAT '$RMAN_BACK_PATH/%d_db_lv0_%T_%s_bak'
 DATABASE;

 RELEASE CHANNEL ch00;
 RELEASE CHANNEL ch01;

 ALLOCATE CHANNEL ch00 TYPE disk;
 ALLOCATE CHANNEL ch01 TYPE disk;

 BACKUP  AS COMPRESSED BACKUPSET
 SKIP INACCESSIBLE
 FORMAT '$RMAN_BACK_PATH/%d_arh_lv0_%T_%s_bak'
 ARCHIVELOG ALL DELETE INPUT;
 RELEASE CHANNEL ch00;
 RELEASE CHANNEL ch01;

 BACKUP 
 CURRENT CONTROLFILE
 FORMAT '$RMAN_BACK_PATH/%d_ctrl_%T_%s_bak';

 crosscheck backup;
 report obsolete;

 delete noprompt force obsolete;
 } 

EOF

echo "****ATTN: Database backup is finished.  The time is `date`.****" 
