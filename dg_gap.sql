--
-- check dataguard gap of oracle database
-- author: zhangweizhao(anbob.com)

set lines 400 pages 1000
col name for a30
col status for a20
col value for a30
col client_pid for a15
col group# for a15
col time_computed for a40
col item for a40
col recovery_mode for a35
col type for a15
col units for a35
col error for a20

select name,database_role,force_logging,switchover_status from v$database;

select distinct DB_UNIQUE_NAME,PROTECTION_MODE,SYNCHRONIZATION_STATUS,SYNCHRONIZED from v$archive_dest_status; 

select scn_to_timestamp(current_scn)    from v$database;

select t.*,arched-applied gap,sysdate etime  from (select thread#,dest_id,max(sequence#) arched,
 max(decode(applied,'YES',sequence#,1)) applied, max(decode(DELETED,'YES',sequence#,1)) DELETED 
 from v$archived_log group by thread#,dest_id) t order by 2,1;

 
select t.*,arched-applied gap,sysdate etime  from (select dest_id, thread#,max(sequence#) arched, max(decode(applied,'YES',sequence#,1)) applied, max(decode(DELETED,'YES',sequence#,1)) DELETED from v$archived_log where resetlogs_change# in(select resetlogs_change# from v$database) 
and dest_id in(select  dest_id  from GV$ARCHIVE_DEST_STATUS where DESTINATION is not null and type='LOCAL'  )
-- and standby_dest='YES' # on primary 
group by thread#,dest_id ) t;	 


--check mrp rfs position on standby
prompt check managed_standby
select process,pid,status,client_process,client_pid,group#,thread#,sequence#,block#,delay_mins from v$managed_standby; 

--check trans  apply lag time on standby
prompt check dataguard_stats
select name,value,unit,time_computed from v$dataguard_stats; 

--check apply sppend on standby
prompt check recovery_progress
select to_char(start_time,'yyyymmdd hh24:mi') start_time,type,item,units,total, to_char(timestamp,'yyyymmdd hh24:mi') timestap from v$recovery_progress; 

-- check dest error on primary
col dest_name for a30
prompt check ARCHIVE_DEST_STATUS
select inst_id,dest_id,dest_name,status,type,recovery_mode,GAP_STATUS, error from GV$ARCHIVE_DEST_STATUS where DESTINATION is not null; 

-- on standby side
prompt archive gap
select * from v$archive_gap;


SELECT * FROM V$STANDBY_EVENT_HISTOGRAM WHERE UPPER(NAME)='APPLY LAG';


  
SELECT ARCH.THREAD# "Thread", ARCH.SEQUENCE# "Last in Sequence", APPL.SEQUENCE# "Last Applied Sequence", (ARCH.SEQUENCE# - APPL.SEQUENCE#) "Difference"
FROM
(SELECT THREAD# ,SEQUENCE# FROM V$ARCHIVED_LOG WHERE (THREAD#,FIRST_TIME ) IN (SELECT THREAD#,MAX(FIRST_TIME) FROM V$ARCHIVED_LOG GROUP BY THREAD#)) ARCH,
(SELECT THREAD# ,SEQUENCE# FROM V$LOG_HISTORY WHERE (THREAD#,FIRST_TIME ) IN (SELECT THREAD#,MAX(FIRST_TIME) FROM V$LOG_HISTORY GROUP BY THREAD#)) APPL
WHERE
ARCH.THREAD# = APPL.THREAD#
ORDER BY 1;
