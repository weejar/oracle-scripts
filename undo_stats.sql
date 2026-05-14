spool Undo_Diag.out  

ttitle off
set pages 999
set lines 150
set verify off 

set termout off
set trimout on
set trimspool on

REM   
REM ------------------------------------------------------------------------  
  
REM   
REM  -----------------------------------------------------------------  
REM  
  
set space 2  

REM  REPORTING TABLESPACE INFORMATION: 
REM   
REM  This looks at Tablespace Sizing - Total bytes and free bytes  
REM   
 
column tablespace_name  format a30            heading 'TS Name'  
column sbytes           format 9,999,999,999  heading 'Total MBytes'  
column fbytes           format 9,999,999,999  heading 'Free MBytes'  
column file_name        format a30            heading 'File Name'
column kount            format 999            heading 'Ext'  
 
compute sum of fbytes on tablespace_name  
compute sum of sbytes on tablespace_name  
compute sum of sbytes on report  
compute sum of fbytes on report  
 
break on tablespace_name skip 2  
 
select a.tablespace_name,  a.file_name,  round(a.bytes/1024/1024,0) sbytes,  
       round(sum(b.bytes/1024/1024),0) fbytes,  count(*) kount, autoextensible  
from   dba_data_files a,  dba_free_space b  
where  a.file_id  =  b.file_id  
and a.tablespace_name in (select z.tablespace_name from dba_tablespaces z where retention like '%GUARANTEE')
group  by a.tablespace_name, a.file_name, a.bytes, autoextensible
order  by a.tablespace_name  
/  
 
set linesize 160  
 
 
REM   
REM  If you can significantly reduce physical reads by adding incremental  
REM  data buffers...do it.  To determine whether adding data buffers will  
REM  help, set db_block_lru_statistics = TRUE and  
REM  db_block_lru_extended_statistics = TRUE in the init.ora parameters.  
REM  You can determine how many extra hits you would get from memory as  
REM  opposed to physical I/O from disk.  **NOTE:  Turning these on will  
REM  impact performance.  One shift of statistics gathering should be enough  
REM  to get the required information.  
REM   
  

REM   
REM  -----------------------------------------------------------------  
REM

set lines 160

col tablespace_name format a30 heading "Tablespace"
col tb format a15 heading "TB Status"
col df format a10 heading "DF Status"
col extent_management format a15 heading "Extent|Management"
col allocation_type format a8 heading "Type"
col segment_space_management format a7 heading "Auto|Segment"
col retention format a11 heading "Retention|Level"
col autoextensible format a5 heading "Auto?"
col mx format 999,999,999 heading "Max Allowed"

select t.tablespace_name, t.status tb, d.status df,
extent_management, allocation_type, segment_space_management, retention,
autoextensible, (maxbytes/1024/1024) mx
from dba_tablespaces t, dba_data_files d
where t.tablespace_name = d.tablespace_name
and retention like '%GUARANTEE'
/


col status format a20 head "Status"
col cnt format 999,999,999 head "How Many?"

select status, count(*) cnt
from dba_rollback_segs
group by status
/


  

set termout on
set trimout off
set trimspool off
set lines 120
set pages 999

set termout off
set trimout on
set trimspool on

alter session set nls_date_format='dd-Mon-yyyy hh24:mi';


prompt
prompt  ############## RUNTIME ############## 
prompt

col rdate head "Run Time"

select sysdate rdate from dual;

prompt 
prompt  ############## DATAFILES ############## 
prompt 

col retention head "Retention"
col tablespace_name format a30 head "TBSP Name"
col file_id format 999 head "File #"
col a format 999,999,999,999,999 head "Bytes Alloc (MB)"
col b format 999,999,999,999,999 head "Max Bytes Used (MB)"
col autoextensible head "Auto|Ext"
col extent_management head "Ext Mngmnt"
col allocation_type head "Type"
col segment_space_management head "SSM"

select tablespace_name, file_id, sum(bytes)/1024/1024 a, 
       sum(maxbytes)/1024/1024 b, 
       autoextensible
from dba_data_files
where tablespace_name in (select tablespace_name from dba_tablespaces
   where retention like '%GUARANTEE' )
group by file_id, tablespace_name, autoextensible
order by tablespace_name
/

set termout on
set trimout off
set trimspool off

ttitle off
set pages 999
set lines 150
set verify off 

set termout off
set trimout on
set trimspool on

REM   
REM ------------------------------------------------------------------------  
  
REM   
REM  -----------------------------------------------------------------  
REM  
  
REM
REM  REPORTING UNDO EXTENTS INFORMATION:  
REM   
REM  -----------------------------------------------------------------  
REM 
REM  Undo Extents breakdown information
REM

ttitle center "Rollback Segments Breakdown" skip 2

col status format a20
col cnt format 999,999,999 head "How Many?"

select tablespace_name,status, count(*) cnt from dba_rollback_segs
group by tablespace_name,status
/

ttitle center "Undo Extents" skip 2


ttitle center "Undo Extents Statistics" skip 2

col size format 999,999,999,999 heading "Size"
col "HOW MANY" format 999,999,999 heading "How Many?"
col st heading a12 heading "Status"

select TABLESPACE_NAME,SEGMENT_NAME,status,count(*) "HOW MANY", sum(bytes) "SIZE" from dba_undo_extents 
group by  TABLESPACE_NAME ,status,segment_name order by 2,3;


col segment_name format a30 heading "Name"
col TABLESPACE_NAME for a20
col BYTES for 999,999,999,999
col BLOCKS for 999,999,999
col status for a15 heading "Status"
col segment_name heading "Segment"
col extent_id heading "ID"


select SEGMENT_NAME, TABLESPACE_NAME, EXTENT_ID, 
      FILE_ID, BLOCK_ID, BYTES, BLOCKS, STATUS
from dba_undo_extents
order by 1,3,4,5
/


REM
REM  -----------------------------------------------------------------  
REM 
REM  Undo Extents Contention breakdown
REM  Take out column TUNED_UNDORETENTION if customer 
REM   prior to 10.2.x
REM
REM   The time frame can be adjusted with this query
REM   By default using around 4 hour window of time
REM
REM   Ex.
REM   Using sysdate-.04 looking at the last hour
REM   Using sysdate-.16 looking at the last 4 hours
REM   Using sysdate-.32 looking at the last 8 hours
REM   Using sysdate-1 looking at the last 24 hours
REM

set linesize 140

ttitle center "Undo Extents Error Conditions (Default - Last 4 Hours)" skip 2


col UNXPSTEALCNT format 999,999,999  heading "# Unexpired|Stolen"
col EXPSTEALCNT format 999,999,999   heading "# Expired|Reused"
col SSOLDERRCNT format 999,999,999   heading "ORA-1555|Error"
col NOSPACEERRCNT format 999,999,999 heading "Out-Of-space|Error"
col MAXQUERYLEN format 999,999,999   heading "Max Query|Length"
col TUNED_UNDORETENTION format 999,999,999  heading "Auto-Ajusted|Undo Retention"
col hours format 999,999 heading "Tuned|(HRs)"

select inst_id, to_char(begin_time,'MM/DD/YYYY HH24:MI') begin_time, 
     UNXPSTEALCNT, EXPSTEALCNT , SSOLDERRCNT, NOSPACEERRCNT, MAXQUERYLEN,
     TUNED_UNDORETENTION, TUNED_UNDORETENTION/60/60 hours
from gv$undostat
where begin_time between (sysdate-.16) 
                     and sysdate
order by inst_id, begin_time
/

  
set termout on
set trimout off
set trimspool off


ttitle off
set pages 999
set lines 150
set verify off 
set termout off
set trimout on
set trimspool on

REM   
REM ------------------------------------------------------------------------  
  
col name format a30  
col gets format 9,999,999  
col waits format 9,999,999  
 
PROMPT  ROLLBACK HIT STATISTICS:  
REM   
  
REM  GETS - # of gets on the rollback segment header 
REM  WAITS - # of waits for the rollback segment header  
  
set head on;  
 
select name, waits, gets  
from   v$rollstat, v$rollname  
where  v$rollstat.usn = v$rollname.usn  
/  
 
col pct head "< 2% ideal"
 
select 'The average of waits/gets is '||  
   round((sum(waits) / sum(gets)) * 100,2)||'%' PCT 
From    v$rollstat  
/  
  

  
PROMPT  REDO CONTENTION STATISTICS:

REM   
REM  If the ratio of waits to gets is more than 1% or 2%, consider  
REM  creating more rollback segments  
REM   
REM  Another way to gauge rollback contention is:  
REM   
  
column xn1 format 9999999  
column xv1 new_value xxv1 noprint  
 

 
select class, count  
from   v$waitstat  
where  class in ('system undo header', 'system undo block', 
                 'undo header',        'undo block'          )  
/  

set head off

select 'Total requests = '||sum(count) xn1, sum(count) xv1  
from    v$waitstat  
/  
 
select 'Contention for system undo header = '||  
       (round(count/(&xxv1+0.00000000001),4)) * 100||'%'  
from  v$waitstat  
where   class = 'system undo header'  
/  
 
select 'Contention for system undo block = '||  
       (round(count/(&xxv1+0.00000000001),4)) * 100||'%'  
from    v$waitstat  
where   class = 'system undo block'  
/  
 
select 'Contention for undo header = '||  
       (round(count/(&xxv1+0.00000000001),4)) * 100||'%'  
from    v$waitstat  
where   class = 'undo header'  
/  
 
select 'Contention for undo block = '||  
       (round(count/(&xxv1+0.00000000001),4)) * 100||'%'  
from    v$waitstat  
where   class = 'undo block'  
/  

REM   
REM  NOTE: Not as useful with AUM configured 
REM 
REM  If the percentage for an area is more than 1% or 2%, consider  
REM  creating more rollback segments.  Note:  This value is usually very  
REM  small 
REM  and has been rounded to 4 places.  
REM   
REM ------------------------------------------------------------------------  
  
REM   
REM  The following shows how often user processes had to wait for space in  
REM  the redo log buffer:  
  
select name||' = '||value  
from   v$sysstat  
where  name = 'redo log space requests'  
/  
 
REM   
REM  This value should be near 0.  If this value increments consistently,  
REM  processes have had to wait for space in the redo buffer.  If this  
REM  condition exists over time, increase the size of LOG_BUFFER in the  
REM  init.ora file in increments of 5% until the value nears 0.  
REM  ** NOTE: increasing the LOG_BUFFER value will increase total SGA size.  
REM   
REM  -----------------------------------------------------------------------  
  
  
col name format a15  
col gets format 9999999  
col misses format 9999999  
col immediate_gets heading 'IMMED GETS' format 9999999  
col immediate_misses heading 'IMMED MISS' format 9999999  
col sleeps format 999999  
 
PROMPT  LATCH CONTENTION:  
REM   
REM  GETS - # of successful willing-to-wait requests for a latch  
REM  MISSES - # of times an initial willing-to-wait request was unsuccessful  
REM  IMMEDIATE_GETS - # of successful immediate requests for each latch  
REM  IMMEDIATE_MISSES = # of unsuccessful immediate requests for each latch  
REM  SLEEPS - # of times a process waited and requests a latch after an  
REM           initial willing-to-wait request  
REM   
REM  If the latch requested with a willing-to-wait request is not  
REM  available, the requesting process waits a short time and requests  
REM  again.  
REM  If the latch requested with an immediate request is not available,  
REM  the requesting process does not wait, but continues processing  
REM   

set head on  
select name,          gets,              misses,  
       immediate_gets,  immediate_misses,  sleeps  
from   v$latch  
where  name in ('redo allocation',  'redo copy')  
/  

set head off 

select 'Ratio of MISSES to GETS: '||  
        round((sum(misses)/(sum(gets)+0.00000000001) * 100),2)||'%'  
from    v$latch  
where   name in ('redo allocation',  'redo copy')  
/  
 

select 'Ratio of IMMEDIATE_MISSES to IMMEDIATE_GETS: '||  
        round((sum(immediate_misses)/  
       (sum(immediate_misses+immediate_gets)+0.00000000001) * 100),2)||'%' 
from    v$latch  
where   name in ('redo allocation',  'redo copy')  
/  
 
set head on
REM   
REM  If either ratio exceeds 1%, performance will be affected.  
REM   
REM  Decreasing the size of LOG_SMALL_ENTRY_MAX_SIZE reduces the number of  
REM  processes copying information on the redo allocation latch.  
REM   
REM  Increasing the size of LOG_SIMULTANEOUS_COPIES will reduce contention  
REM  for redo copy latches.  
  
REM   
REM  -----------------------------------------------------------------  
REM  This looks at overall i/o activity against individual  
REM  files within a tablespace  
REM   
REM  Look for a mismatch across disk drives in terms of I/O  
REM   
REM  Also, examine the Blocks per Read Ratio for heavily accessed  
REM  TSs - if this value is significantly above 1 then you may have  
REM  full tablescans occurring (with multi-block I/O)  
REM   
REM  If activity on the files is unbalanced, move files around to balance  
REM  the load.  Should see an approximately even set of numbers across files  
REM   
  
set space 1  

PROMPT  REPORTING I/O STATISTICS:
 
column pbr       format 99999999  heading 'Physical|Blk Read'  
column pbw       format 999999    heading 'Physical|Blks Wrtn'  
column pyr       format 999999    heading 'Physical|Reads'  
column readtim   format 99999999  heading 'Read|Time'  
column name      format a55       heading 'DataFile Name'  
column writetim  format 99999999  heading 'Write|Time'  
 
compute sum of f.phyblkrd, f.phyblkwrt on report  
 
select fs.name name,  f.phyblkrd pbr,  f.phyblkwrt pbw, 
       f.readtim,     f.writetim  
from   v$filestat f, v$datafile fs  
where  f.file#  =  fs.file#  
order  by fs.name  
/  
 
REM   
REM  -----------------------------------------------------------------  
  
PROMPT  GENERATING WAIT STATISTICS:  
REM   
REM  This will show wait stats for certain kernel instances.  This  
REM  may show the need for additional rbs, wait lists, db_buffers  
REM   
 
column class  heading 'Class Type'  
column count  heading 'Times Waited'  format 99,999,999 
column time   heading 'Total Times'   format 99,999,999  
 
select class,  count,  time  
from   v$waitstat  
where  count > 0  
order  by class  
/  
 
REM   
REM  Look at the wait statistics generated above (if any). They will  
REM  tell you where there is contention in the system.  There will  
REM  usually be some contention in any system - but if the ratio of  
REM  waits for a particular operation starts to rise, you may need to  
REM  add additional resource, such as more database buffers, log buffers,  
REM  or rollback segments  
REM   
REM  -----------------------------------------------------------------  
  
PROMPT  ROLLBACK EXTENT STATISTICS:  
REM   


 
column usn        format 999          heading 'Undo #'
column extents    format 999          heading 'Extents'  
column rssize     format 999,999,999  heading 'Size in|Bytes'  
column optsize    format 999,999,999  heading 'Optimal|Size'  
column hwmsize    format 99,999,999   heading 'High Water|Mark'  
column shrinks    format 9,999        heading 'Num of|Shrinks'  
column wraps      format 9,999        heading 'Num of|Wraps'  
column extends    format 999,999      heading 'Num of|Extends'  
column aveactive  format 999,999,999  heading 'Average size|Active Extents'  
column rownum noprint  
 
select usn, extents, rssize,    optsize,  hwmsize,  
       shrinks,   wraps,    extends,  aveactive  
from   v$rollstat  
order  by rownum  
/  



set termout on
set trimout off
set trimspool off

set lines 120
set pages 999

set termout off
set trimout on
set trimspool on



prompt
prompt  ############## RUNTIME ############## 
prompt

col rdate head "Run Time"

select sysdate rdate from dual;

prompt 
prompt  ############## HISTORICAL DATA ############## 
prompt 

col x format 999,999 head "Max Concurrent|Last 7 Days"
col y format 999,999 head "Max Concurrent|Since Startup"

select max(maxconcurrency) x from v$undostat
/
select max(maxconcurrency) y from sys.wrh$_undostat
/

col i format 999,999 head "1555 Errors"
col j format 999,999 head "Undo Space Errors"

select sum(ssolderrcnt) i from v$undostat
where end_time > sysdate-2
/

select sum(nospaceerrcnt) j from v$undostat
where end_time > sysdate-2
/

prompt 
prompt  ############## CURRENT STATUS OF SEGMENTS  ############## 
prompt  ##############   SNAPSHOT IN TIME INFO     ##############
prompt  ##############(SHOWS CURRENT UNDO ACTIVITY)##############
prompt 

col segment_name format a30 head "Segment Name"
col "ACT BYTES" format 999,999,999,999 head "Active Bytes"
col "UNEXP BYTES" format 999,999,999,999 head "Unexpired Bytes"
col "EXP BYTES" format 999,999,999,999 head "Expired Bytes"

select segment_name, nvl(sum(act),0) "ACT BYTES", 
  nvl(sum(unexp),0) "UNEXP BYTES",
  nvl(sum(exp),0) "EXP BYTES"
from (select segment_name, nvl(sum(bytes),0) act,00 unexp, 00 exp
   from dba_undo_extents where status='ACTIVE' group by segment_name
union 
select segment_name, 00 act, nvl(sum(bytes),0) unexp, 00 exp
from dba_undo_extents where status='UNEXPIRED' group by segment_name
union
select segment_name, 00 act, 00 unexp, nvl(sum(bytes),0) exp
from dba_undo_extents where status='EXPIRED' group by segment_name)
group by segment_name
order by 1
/


select segment_name, 00 act, count(*) exts,nvl(sum(bytes),0) unexp, 00 exp
from dba_undo_extents where status='UNEXPIRED' group by segment_name

prompt 
prompt  ############## UNDO SPACE USAGE ############## 
prompt 

col usn format 999,999 head "Segment#"
col shrinks format 999,999,999 head "Shrinks"
col aveshrink format 999,999,999 head "Avg Shrink Size"

select usn, shrinks, aveshrink from v$rollstat
/
set termout on
set trimout off
set trimspool off
set pages 999

set termout off
set trimout on
set trimspool on


prompt
prompt  ############## RUNTIME ############## 
prompt

col rdate head "Run Time"

select sysdate rdate from dual;

col inst_id format 999 head "Instance #"
col Parameter format a35 wrap
col "Session Value" format a25 wrapped
col "Instance Value" format a25 wrapped

prompt
prompt  ############## PARAMETERS ############## 
prompt

select  a.inst_id, a.ksppinm  "Parameter",
             b.ksppstvl "Session Value",
             c.ksppstvl "Instance Value"
      from x$ksppi a, x$ksppcv b, x$ksppsv c
     where a.indx = b.indx and a.indx = c.indx
       and a.inst_id=b.inst_id and b.inst_id=c.inst_id
       and a.ksppinm in ('_undo_autotune', '_smu_debug_mode',
                         '_highthreshold_undoretention',
                'undo_tablespace','undo_retention','undo_management')
order by 2;

set termout on
set trimout off
set trimspool off
set pages 999

set termout off
set trimout on
set trimspool on

prompt
prompt  ############## RUNTIME ############## 
prompt

col rdate head "Run Time"

select sysdate rdate from dual;

prompt 
prompt  ############## WAITS FOR UNDO (Since Startup) ############## 
prompt 

col inst_id head "Instance#"
col eq_type format a3 head "Enq"
col total_req# format 999,999,999,999,999,999 head "Total Requests"
col total_wait# format 999,999 head "Total Waits"
col succ_req# format 999,999,999,999,999,999 head "Successes"
col failed_req# format 999,999,999999 head "Failures"
col cum_wait_time format 999,999,999 head "Cummalitve|Time"

select * from v$enqueue_stat where eq_type='US'
union
select * from v$enqueue_stat where eq_type='HW'
/

prompt 
prompt  ############## LOCKS FOR UNDO ############## 
prompt 

col addr head "ADDR"
col KADDR head "KADDR"
col sid head "Session"
col osuser format a10 head "OS User"
col machine format a15 head "Machine"
col program format a17 head "Program"
col process format a7 head "Process"
col lmode head "Lmode"
col request head "Request"
col ctime format 9,999 head "Time|(Mins)"
col block head "Blocking?"

select /*+ RULE */  a.SID, b.process,
b.OSUSER,  b.MACHINE,  b.PROGRAM, 
addr, kaddr, lmode, request, round(ctime/60/60,0) ctime, block 
from 
v$lock a, 
v$session b 
where 
a.sid=b.sid
and a.type='US'
/

prompt 
prompt  ############## TUNED RETENTION HISTORY (Last 2 Days) ############## 
prompt  ##############        LOWEST AND HIGHEST DATA        ############## 
prompt 

col low format 999,999,999,999 head "Undo Retention|Lowest Tuned Value"
col high format 999,999,999,999 head "Undo Retention|Highest Tuned Value"

select end_time, tuned_undoretention from v$undostat where tuned_undoretention = (
select min(tuned_undoretention) low
from v$undostat
where end_time > sysdate-2)
/

select end_time, tuned_undoretention from v$undostat where tuned_undoretention = (
select max(tuned_undoretention) high
from v$undostat
where end_time > sysdate-2)
/

prompt 
prompt  ############## CURRENT TRANSACTIONS ############## 
prompt 

col sql_text format a40 word_wrapped head "SQL Code"

select a.start_date, a.start_scn, a.status, c.sql_text
from v$transaction a, v$session b, v$sqlarea c
where b.saddr=a.ses_addr and c.address=b.sql_address
and b.sql_hash_value=c.hash_value
/

select current_scn from v$database
/

col a format 999,999 head "UnexStolen"
col b format 999,999 head "ExStolen"
col c format 999,999 head "UnexReuse"
col d format 999,999 head "ExReuse"

prompt 
prompt  ############## WHO'S STEALING WHAT? (Last 2 Days) ############## 
prompt 

select unxpstealcnt a, expstealcnt b,
  unxpblkreucnt c, expblkreucnt d
from v$undostat
where (unxpstealcnt > 0 or expstealcnt > 0)
and end_time > sysdate-2
/

set termout on
set trimout off
set trimspool off
set pages 999

set termout off
set trimout on
set trimspool on

prompt
prompt  ############## RUNTIME ############## 
prompt

col rdate head "Run Time"

select sysdate rdate from dual;

col current_scn head "SCN Now"
col start_date head "Trans Started"
col start_scn head "SCN for Trans"
col ses_addr head "ADDR"

prompt 
prompt  ############## Historical V$UNDOSTAT (Last 2 Days) ############## 
prompt 


col end_time format a18 Head "Date/Time"
col maxq format 999,999 head "Query|Maximum|Minutes"
col maxquerysqlid head "SqlID"
col undotsn format 999,999 head "TBS"
col undoblks format 999,999,999 head "Undo|Blocks"
col txncount format 999,999,999 head "# of|Trans"
col unexpiredblks format 999,999,999 head "# of Unexpired"
col expiredblks format 999,999,999 head "# of Expired"
col tuned format 999,999 head "Tuned Retention|(Minutes)"

select end_time, round(maxquerylen/60,0) maxq, maxquerysqlid,
undotsn, undoblks, txncount, unexpiredblks, expiredblks, 
round(tuned_undoretention/60,0) Tuned
from dba_hist_undostat
where end_time > sysdate-2
order by 1
/

prompt 
prompt  ############## RECENT MISSES FOR UNDO (Last 2 Days) ############## 
prompt 

set lines 500
select * from v$undostat where maxquerylen > tuned_undoretention
and end_time > sysdate-2
order by 2
/

select * from sys.wrh$_undostat where maxquerylen > tuned_undoretention
and end_time > sysdate-2
order by 2
/

prompt 
prompt  ############## AUTO-TUNING TUNE-DOWN DATA    ############## 
prompt  ############## ROLLBACK DATA (Since Startup) ############## 
prompt 

col name format a60 head "Name"
col value format 999,999,999 head "Counters"

select name, value from v$sysstat
where name like '%down retention%' or name like 'une down%'
or name like '%undo segment%' or name like '%rollback%'
or name like '%undo record%'
/

prompt 
prompt  ############## Long Running Query History ############## 
prompt 

col end_time head "Date"
col maxquerysqlid head "SQL ID"
col runawayquerysqlid format a15 head "Runaway SQL ID"
col results format a35 word_wrapped head "Space Issues"
col status head "Status"
col newret head "Tuned Down|Retention"

select end_time, maxquerysqlid, runawayquerysqlid, status,
        decode(status,1,'Slot Active',4,'Reached Best Retention',5,'Reached Best Retention',
                    8, 'Runaway Query',9,'Runaway Query-Active',10,'Space Pressure',
                   11,'Space Pressure Currently',
                   16, 'Tuned Down (to undo_retention) due to Space Pressure', 
                   17,'Tuned Down (to undo_retention) due to Space Pressure-Active',
                   18, 'Tuning Down due to Runaway', 19, 'Tuning Down due to Runaway-Active',
                   28, 'Runaway tuned down to last tune down value',
                   29, 'Runaway tuned down to last tune down value',
                   32, 'Max Tuned Down - Not Auto-Tuning',
                   33, 'Max Tuned Down - Not Auto-Tuning (Active)',
                   37, 'Max Tuned Down - Not Auto-Tuning (Active)', 
                   38, 'Max Tuned Down - Not Auto-Tuning', 
                   39, 'Max Tuned Down - Not Auto-Tuning (Active)', 
                   40, 'Max Tuned Down - Not Auto-Tuning', 
                   41, 'Max Tuned Down - Not Auto-Tuning (Active)', 
                   42, 'Max Tuned Down - Not Auto-Tuning', 
                   44, 'Max Tuned Down - Not Auto-Tuning', 
                   45, 'Max Tuned Down - Not Auto-Tuning (Active)', 
                   'Other ('||status||')') Results, spcprs_retention NewRet
from sys.wrh$_undostat
where status > 1
/



prompt 
prompt  ############## Details on Long Run Queries ############## 
prompt 

col sql_fulltext head "SQL Text"
Col sql_id heading "SQL ID"

select sql_id, sql_fulltext, last_load_time "Last Load", 
round(elapsed_time/60/60/24,0) "Elapsed Days" 
from v$sql where sql_id in 
(select maxquerysqlid from sys.wrh$_undostat 
where status > 1)
/

set termout on
set trimout off
set trimspool off
set pages 999

set termout off
set trimout on
set trimspool on

prompt
prompt  ############## RUNTIME ############## 
prompt

col rdate head "Run Time"

select sysdate rdate from dual;

prompt 
prompt  ############## IN USE Undo Data ############## 
prompt 

select 
((select (nvl(sum(bytes),0)) 
from dba_undo_extents 
where tablespace_name in (select tablespace_name from dba_tablespaces
   where retention like '%GUARANTEE' )
and status in ('ACTIVE','UNEXPIRED')) *100) / 
(select sum(bytes) 
from dba_data_files 
where tablespace_name in (select tablespace_name from dba_tablespaces
   where retention like '%GUARANTEE' )) "PCT_INUSE" 
from dual; 


select tablespace_name, extent_management, allocation_type,
segment_space_management, retention
from dba_tablespaces where retention like '%GUARANTEE'
/

col c format 999,999,999,999 head "Sum of Free"

select (nvl(sum(bytes),0)) c from dba_free_space
where tablespace_name in
(select tablespace_name from dba_tablespaces where retention like '%GUARANTEE')
/

col d format 999,999,999,999 head "Total Bytes"

select sum(bytes) d from dba_data_files
where tablespace_name in
(select tablespace_name from dba_tablespaces where retention like '%GUARANTEE')
/


PROMPT
PROMPT  ############## UNDO SEGMENTS ############## 
PROMPT

col status head "Status"
col z format 999,999 head "Total Extents"
break on report
compute sum on report of z

select status, count(*) z from dba_undo_extents
group by status
/

col z format 999,999 head "Undo Segments"

select status, count(*) z from dba_rollback_segs
group by status
/


prompt 
prompt  ############## CURRENT STATUS OF SEGMENTS  ############## 
prompt  ##############   SNAPSHOT IN TIME INFO     ##############
prompt  ##############(SHOWS CURRENT UNDO ACTIVITY)##############
prompt 


col segment_name format a30 head "Segment Name"
col "ACT BYTES" format 999,999,999,999 head "Active Bytes"
col "UNEXP BYTES" format 999,999,999,999 head "Unexpired Bytes"
col "EXP BYTES" format 999,999,999,999 head "Expired Bytes"

select segment_name, nvl(sum(act),0) "ACT BYTES", 
  nvl(sum(unexp),0) "UNEXP BYTES",
  nvl(sum(exp),0) "EXP BYTES"
from (select segment_name, nvl(sum(bytes),0) act,00 unexp, 00 exp
   from dba_undo_extents where status='ACTIVE' group by segment_name
union 
select segment_name, 00 act, nvl(sum(bytes),0) unexp, 00 exp
from dba_undo_extents where status='UNEXPIRED' group by segment_name
union
select segment_name, 00 act, 00 unexp, nvl(sum(bytes),0) exp
from dba_undo_extents where status='EXPIRED' group by segment_name)
group by segment_name
order by 1
/

prompt 
prompt  ############## UNDO SPACE USAGE ############## 
prompt 

col usn format 999,999 head "Segment#"
col shrinks format 999,999,999 head "Shrinks"
col aveshrink format 999,999,999 head "Avg Shrink Size"

select usn, shrinks, aveshrink from v$rollstat
/



select maxqueryid||' '||to_char(end_time,'hh24:mi')||' '||
rtrim(lower(''
--||decode(MAXCONCURRENCY,0,'','MAXCONCURRENCY='||MAXCONCURRENCY||' ')
||decode(UNDOBLKS,0,'','UNDOBLKS='||UNDOBLKS||' ')
||decode(ACTIVEBLKS,0,'','ACTIVEBLKS='||ACTIVEBLKS||' ')
||decode(UNEXPIREDBLKS,0,'','UNEXPIREDBLKS='||UNEXPIREDBLKS||' ')
||decode(EXPIREDBLKS,0,'','EXPIREDBLKS='||EXPIREDBLKS||' ')
||decode(TUNED_UNDORETENTION,0,'','TUNED_UNDORETENTION(hour)='||to_char(TUNED_UNDORETENTION/60/60,'FM999.9')||' ')
||decode(UNXPSTEALCNT,0,'','UNXPSTEALCNT='||UNXPSTEALCNT||' ')
||decode(UNXPBLKRELCNT,0,'','UNXPBLKRELCNT='||UNXPBLKRELCNT||' ')
||decode(UNXPBLKREUCNT,0,'','UNXPBLKREUCNT='||UNXPBLKREUCNT||' ')
||decode(EXPSTEALCNT,0,'','EXPSTEALCNT='||EXPSTEALCNT||' ')
||decode(EXPBLKRELCNT,0,'','EXPBLKRELCNT='||EXPBLKRELCNT||' ')
||decode(EXPBLKREUCNT,0,'','EXPBLKREUCNT='||EXPBLKREUCNT||' ')
||decode(SSOLDERRCNT,0,'','SSOLDERRCNT='||SSOLDERRCNT||' ')
||decode(NOSPACEERRCNT,0,'','NOSPACEERRCNT='||NOSPACEERRCNT||' ')
)) "undostats covering ORA-1555"
 from (
select BEGIN_TIME-MAXQUERYLEN/24/60/60 SSOLD_BEGIN_TIME,END_TIME SSOLD_END_TIME from V$UNDOSTAT where SSOLDERRCNT>0
) , lateral(select * from v$undostat
 where end_time>=ssold_begin_time and begin_time<=ssold_end_time)
order by end_time;
/

prompt When the columns UNXPSTEALCNT through EXPBLKREUCNT hold non-zero values, it is an indication of space pressure.
prompt If the column SSOLDERRCNT is non-zero, then UNDO_RETENTION is not properly set.
prompt If the column NOSPACEERRCNT is non-zero, then there is a serious space problem.

set termout on
set trimout off
set trimspool off
spool off
