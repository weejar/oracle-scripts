# author: weejar zhang(anbob.com)
# porpose: rman backup  scripts on WINDOWS

#callrman.bat

@echo off
rman target / nocatalog cmdfile='D:\RMAN_BACKUP\rman_backup.cmd' log=D:\RMAN_BACKUP\rman_backup_log.txt

#rman_backup.cmd
run
{
ALLOCATE CHANNEL c1 DEVICE TYPE disk;
ALLOCATE CHANNEL c2 DEVICE TYPE disk;
ALLOCATE CHANNEL c3 DEVICE TYPE disk;
ALLOCATE CHANNEL c4 DEVICE TYPE disk;
crosscheck archivelog all;
crosscheck backup;
BACKUP AS COMPRESSED BACKUPSET DATABASE FORMAT 'D:\RMAN_BACKUP\PROD_comp_%d_ lvl0_%U' TAG "dailyfull_db_lvl0_bkp" INCLUDE CURRENT CONTROLFILE;
sql 'ALTER SYSTEM ARCHIVE LOG CURRENT';
BACKUP AS COMPRESSED BACKUPSET ARCHIVELOG ALL FORMAT 'D:\RMAN_BACKUP\archive_%d_lvl0_%U';
DELETE NOPROMPT archivelog all completed before 'sysdate-7';
backup current controlfile format 'D:\RMAN_BACKUP\bkpcontrol_file.ctl_%d_%T_%s_bak'  ;
DELETE NOPROMPT OBSOLETE RECOVERY WINDOW OF 7 DAYS;

 
RELEASE CHANNEL c1;
RELEASE CHANNEL c2;
RELEASE CHANNEL c3;
RELEASE CHANNEL c4;
}


# create task  8:00 every day  until 2026/12/31
schtasks /create /tn rman_backup_db /tr D:\RMAN_BACKUP\callrman.bat /sc daily /st 08:00 /ed 2026/12/31

# run immeidate manaual
schtasks /run /tn rman_backup_db