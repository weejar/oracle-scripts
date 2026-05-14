-- author: weejar (anbob.com)
-- purpose: report temp segment usage detail
-- version : 1.3
-- file: temp_rpt.sql

set markup html on spool on 
spool temp_report.html

select * from v$version;


SET ECHO        OFF
SET FEEDBACK    6
SET HEADING     ON
SET LINESIZE    300
SET PAGESIZE    50000
SET TERMOUT     ON
SET TIMING      OFF
SET TRIMOUT     ON
SET TRIMSPOOL   ON
SET VERIFY      OFF


CLEAR COLUMNS
CLEAR BREAKS
CLEAR COMPUTES

alter session set nls_date_format='yyyy-mm-dd hh24:mi:ss';
alter session set nls_timestamp_format='yyyy-mm-dd hh24:mi:ss';

select sysdate   from dual;


pro  list system  events 
oradebug setmypid
oradebug eventdump system;



COLUMN tablespace_name       FORMAT a20                 HEAD 'Tablespace Name'
COLUMN tablespace_status     FORMAT a9                  HEAD 'Status'
COLUMN tablespace_size       FORMAT 9,999,999,999,999   HEAD 'Size'
COLUMN used                  FORMAT 9,999,999,999,999   HEAD 'Used'
COLUMN used_pct              FORMAT 999                 HEAD 'Pct. Used'
COLUMN current_users         FORMAT 999,999             HEAD 'Current Users'

BREAK ON report

select h.tablespace_name,
       round(sum(h.bytes_free + h.bytes_used) / 1048576) megs_alloc,
       round(sum((h.bytes_free + h.bytes_used) - nvl(p.bytes_used, 0)) /
             1048576) megs_free,
       round(sum(nvl(p.bytes_used, 0)) / 1048576) megs_used,
       round((sum((h.bytes_free + h.bytes_used) - nvl(p.bytes_used, 0)) /
             sum(h.bytes_used + h.bytes_free)) * 100) Pct_Free,
       100 -
       round((sum((h.bytes_free + h.bytes_used) - nvl(p.bytes_used, 0)) /
             sum(h.bytes_used + h.bytes_free)) * 100) pct_used,
       round(sum(f.maxbytes) / 1048576) max
  from sys.v_$TEMP_SPACE_HEADER h,
       sys.v_$Temp_extent_pool  p,
       dba_temp_files           f
 where p.file_id(+) = h.file_id
   and p.tablespace_name(+) = h.tablespace_name
   and f.file_id = h.file_id
   and f.tablespace_name = h.tablespace_name
 group by h.tablespace_name
 ORDER BY 1
/

SELECT d.tablespace_name "Name", 
                TO_CHAR(NVL(a.bytes / 1024 / 1024, 0),'99,999,990.900') "Size (M)", 
                TO_CHAR(NVL(t.hwm, 0)/1024/1024,'99999999.999')  "HWM (M)",
                TO_CHAR(NVL(t.hwm / a.bytes * 100, 0), '990.00') "HWM % " ,
                TO_CHAR(NVL(t.bytes/1024/1024, 0),'99999999.999') "Using (M)", 
	        TO_CHAR(NVL(t.bytes / a.bytes * 100, 0), '990.00') "Using %" 
           FROM sys.dba_tablespaces d, 
                (select tablespace_name, sum(bytes) bytes from dba_temp_files group by tablespace_name) a,
                (select tablespace_name, sum(bytes_cached) hwm, sum(bytes_used) bytes from v$temp_extent_pool group by tablespace_name) t
          WHERE d.tablespace_name = a.tablespace_name(+) 
            AND d.tablespace_name = t.tablespace_name(+) 
            AND d.extent_management like 'LOCAL' 
            AND d.contents like 'TEMPORARY'
/


CLEAR COLUMNS
CLEAR BREAKS
CLEAR COMPUTES

COLUMN instance_name              FORMAT a8                 HEADING 'Instance'
COLUMN tablespace_name            FORMAT a15                HEADING 'Tablespace|Name'          JUST right
COLUMN temp_segment_name          FORMAT a8                 HEADING 'Segment|Name'             JUST right
COLUMN current_users              FORMAT 9,999              HEADING 'Current|Users'            JUST right
COLUMN total_temp_segment_size    FORMAT 999,999,999,999    HEADING 'Total Temp|Segment Size'  JUST right
COLUMN currently_used_bytes       FORMAT 999,999,999,999    HEADING 'Currently|Used Bytes'     JUST right
COLUMN pct_used                   FORMAT 999                HEADING 'Pct.|Used'                JUST right
COLUMN extent_hits                FORMAT 999,999,999,999    HEADING 'Extent|Hits'              JUST right
COLUMN max_size                   FORMAT 999,999,999,999    HEADING 'Max|Size'                 JUST right
COLUMN max_used_size              FORMAT 999,999,999,999    HEADING 'Max Used|Size'            JUST right
COLUMN max_sort_size              FORMAT 999,999,999,999    HEADING 'Max Sort|Size'            JUST right
COLUMN free_requests              FORMAT 999                HEADING 'Free|Requests'            JUST right


BREAK ON instance_name SKIP PAGE

SELECT
    i.instance_name               instance_name
  , t.tablespace_name             tablespace_name
  , 'SYS.'          || 
    t.segment_file  ||
    '.'             || 
    t.segment_block               temp_segment_name
  , t.current_users               current_users
  , (t.total_blocks*b.value)      total_temp_segment_size
  , (t.used_blocks*b.value)       currently_used_bytes
  , TRUNC(ROUND((t.used_blocks/t.total_blocks)*100))    pct_used
  , t.extent_hits                 extent_hits
  , (t.max_blocks*b.value)        max_size
  , (t.max_used_blocks*b.value)   max_used_size
  , (t.max_sort_blocks *b.value)  max_sort_size
  , t.free_requests               free_requests
FROM
    gv$instance                     i
  , gv$sort_segment                 t
  , (select value from v$parameter
     where name = 'db_block_size')  b
WHERE
    t.inst_id = i.inst_id
ORDER BY
    i.instance_name
  , t.tablespace_name;

CLEAR COLUMNS
CLEAR BREAKS
CLEAR COMPUTES

-- monitory temp REAL SQL  ID
SELECT  k.inst_id "INST_ID",
      ktssoses "SADDR",
      sid "SID",
      ktssosno "SERIAL#",
      username "USERNAME",
      osuser "OSUSER",
      ktssosqlid "SQL_ID",
      ktssotsn "TABLESPACE", decode(ktssocnt, 0, 'PERMANENT', 1, 'TEMPORARY') "CONTENTS", decode(ktssosegt, 1, 'SORT', 2, 'HASH', 3, 'DATA', 4, 'INDEX', 5, 'LOB_DATA', 6, 'LOB_INDEX' , 'UNDEFINED') "SEGTYPE", ktssofno "SEGFILE#", ktssobno "SEGBLK#", ktssoexts "EXTENTS", ktssoblks "BLOCKS", round(ktssoblks*p.value/1024/1024, 2) "SIZE_MB", ktssorfno "SEGRFNO#"
FROM x$ktsso k, v$session s, v$parameter p
WHERE ktssoses = s.saddr
    AND ktssosno = s.serial#
    AND p.name = 'db_block_size'order by sid;
	

COLUMN instance_name      FORMAT a8                 HEADING 'Instance'
COLUMN tablespace_name    FORMAT a10                HEADING 'Tablespace| Name'
COLUMN sid                FORMAT a10              HEADING 'SID'
COLUMN serial_id          FORMAT 99999999           HEADING 'Serial ID'
COLUMN session_status     FORMAT a9                 HEADING 'Status'
COLUMN oracle_username    FORMAT a18                HEADING 'Oracle User'
COLUMN os_username        FORMAT a10                HEADING 'O/S User'    trunc
COLUMN os_pid             FORMAT a8                 HEADING 'O/S PID'
COLUMN session_terminal   FORMAT a10                HEADING 'Terminal'         TRUNC
COLUMN session_machine    FORMAT a30                HEADING 'Machine'          TRUNC
COLUMN session_program    FORMAT a20                HEADING 'Session Program'  TRUNC
COLUMN contents           FORMAT a9                 HEADING 'Contents'
COLUMN extents            FORMAT 999,999,999        HEADING 'Extents'
COLUMN blocks             FORMAT 999,999,999        HEADING 'Blocks'
COLUMN size_mb            FORMAT 999,999,999        HEADING 'SIZE_MB'
COLUMN segtype            FORMAT a12                HEADING 'Segment Type'
COLUMN sql_id             FORMAT a30

BREAK ON instance_name SKIP PAGE

col sid for a12
SELECT
    i.instance_name       instance_name
  , t.tablespace          tablespace_name
  , s.sid||','||s.serial#      sid
  , s.status              session_status
  , s.username            oracle_username
  , s.machine			  session_machine
  , s.osuser              os_username
  , p.spid                os_pid
  , s.program             session_program
  , s.sql_id
  , t.contents            contents
  , t.segtype             segtype
  , (t.blocks * c.value)/1024/1024  SIZE_MB
FROM
    gv$instance     i
  , gv$session      s
  , gv$process      p
  , gv$sort_usage   t
  , (select value from v$parameter
     where name = 'db_block_size') c
WHERE
      s.inst_id = p.inst_id 
  AND p.inst_id = i.inst_id
  AND t.inst_id = i.inst_id
  AND s.inst_id = i.inst_id
  AND s.saddr = t.session_addr
  AND s.paddr = p.addr
ORDER BY
    i.instance_name
  , s.sid;



 select inst_id,tablespace,segtype,sum(blocks),count(*),sum(blocks)/count(*) from gv$tempseg_usage group by inst_id,tablespace,segtype;

select * from gv$temporary_lobs;


prom  history of temp

select inst_id  
,      session_id||','||session_serial#   sid
,      sql_exec_id  
,      sql_exec_start  
,      sql_id  
,      sql_plan_hash_value  
,      sql_plan_operation  
,      sql_plan_line_id  
,      min(sample_time)  
,      max(sample_time)  
,      max(temp_space_allocated)/power(1024,2) temp_mb  
from   gv$active_session_history --dba_hist_active_sess_history  
where  temp_space_allocated >  power(1024,2)*100
group by  
       inst_id  
,      session_id||','||session_serial# 
,      sql_exec_id  
,      sql_exec_start  
,      sql_id  
,      sql_plan_hash_value  
,      sql_plan_operation  
,      sql_plan_line_id  
order by max(sample_time) desc;  

select sql_id,sql_text from v$sqlarea where sql_id in(SELECT
    sql_id
FROM
    v$active_session_history --dba_hist_active_sess_history  
WHERE
    temp_space_allocated > 1024
GROUP BY
    sql_id
having MAX(temp_space_allocated) > power(1024,2)*500);

SELECT
    sql_id,
    plan_hash_value,
    operation,
    options,
    object_owner,
    object_name,
    object_alias,
    object_type,
    id,
    parent_id,
    depth,
    cost,
    cardinality,
    temp_space
FROM
    v$sql_plan
WHERE
     sql_id IN (
        SELECT
            sql_id
        FROM
            v$active_session_history --dba_hist_active_sess_history  
        WHERE
            temp_space_allocated > 1024
        GROUP BY
            sql_id
        HAVING
            MAX(temp_space_allocated) > power(1024,2) * 500
    );
	
spool off
set markup html off
prom  file name: temp_report.html

prom   please gather sql monitor report using  SQL:  select dbms_sqltune.report_sql_monitor(sql_id=>'your sql_id',report_level=>'ALL',type=>'text') from dual;