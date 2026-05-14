-- file: session_rpt.sql
-- Purpose: To Collect all session information
-- Author:      weejar.zhang
-- Copyright:   (c) ANBOB - http://www.anbob.com.com - All rights reserved.
-- version 2.6


-- 2.6 spool name with date
-- 2.5 add version and process info
-- 2.4 add failed_over
-- 2.3 add group by server

col spoolname new_value spoolname

select 'session_rpt_'||to_char(sysdate,'yyyymmdd') spoolname from dual;

spool '&spoolname'

prom list of sessions
set lines 300 pages 1000
col current_time for a50
select 'anbob.com' author,to_char(sysdate,'yyyy-mm-dd hh24:mi:ss') current_time,instance_name,version,status,instance_role from v$instance
/


select * from v$resource_limit where RESOURCE_NAME in('processes','sessions');

col sid form 99999
col serial# form 99999
col spid form a6
col program heading 'program' for a25 trunc
col username form a20
col osuser form a10
col idle form a30 heading "Idle"
col terminal form a12
col logon_time form a18
col machine for a15 trunc
col rn for 9999
col service_name for a30
set lines 150 pages 1000

break  on report
compute sum of cnt on report

select inst_id,status,count(*) cnt from gv$session group by inst_id,status order by 1
/

select inst_id,username,status,count(*) cnt from gv$session group by inst_id,username,status order by 1,4 desc
/

select inst_id,username,machine,count(*) cnt from gv$session group by inst_id,username,machine order by 1,4,desc
/

select username,machine,failed_over,count(*) cnt from v$session where failed_over='YES' group by username,machine,failed_over order by 1,2
/

select inst_id,server,status,count(*) from gv$session   group by inst_id,server,status
/

select inst_id,service_name,count(*) cnt from gv$session group by  inst_id,service_name order by 1,2
/

select inst_id,pname,username,count(*) cnt from gv$process group by inst_id,pname,username
/

select machine,program,count(*) from v$session where type='USER' group by  machine,program order by 1,2
/

select machine,server,username, count(*) cnt
          from v$session 
         -- where program like 'oracle@qdyy%(TNS V1-V3)' 
         -- and machine in('qdyya1') 
          group by machine,server,username
/
ttitle -
   center  'displays the top 50 longest idle times'  skip 2

select  a.*
from (
  select sid,serial#,username,status, to_char(logon_time,'dd-mm-yy hh:mi:ss') logon_time
    , floor(last_call_et/3600)||' hours '
        || floor(mod(last_call_et,3600)/60)||' mins '
        || mod(mod(last_call_et,3600),60)||' secs' idle
    , machine ,row_number() over(order by last_call_et desc ) rn
  from v$session
  where type='USER' ) a
where rn<= 50
/

ttitle off

column event heading 'wait event' for a30 trunc

ttitle -
   center  'displays active session'  skip 2

select sid,serial#,username,event,program,MACHINE,sql_id,BLOCKING_SESSION from v$session where status='ACTIVE' and username is not null;

ttitle off

spool off

