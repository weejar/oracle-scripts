-- file: ase_cdb.sql
-- version: 1.2
-- author: weejar zhang(anbob.com)
-- Desc. To Display all sessions of ForeGround not "inactive" for Multitenant
-- Created: 2019/7/25

SET LINES 400 PAGES 1000
COL username FOR a10
COL machine FOR a10
COL osuser FOR a10 TRUNC
COL module FOR a20 TRUNC
COL event FOR a20 TRUNC
COL sqltext FOR a30
COL sql_id FOR a15
COL wai_secinwait FOR a10
COL bs FOR a10
COL ch# FOR 999
COL cpu_value FOR 999,999,999 HEADING 'CPU'
col pdb   for a10 
 select /*+ordered rule*/  pdb.name pdb, ses.username,   ses.sid,   
 CASE WHEN ses.state != 'WAITING' THEN 'On CPU / runqueue'  ELSE event end as event,   
 ses.machine,  regexp_substr(ses.module,'[^@]+') module,   
 ses.status,   ses.last_call_et --,   seq#   
   ,ses.sql_id,wait_time||':'||SECONDS_IN_WAIT wai_secinwait ,  ROW_WAIT_OBJ# ,
   substr(sql.sql_text,1,30) sqltext,FINAL_BLOCKING_instance||':'||FINAL_BLOCKING_SESSION  bs,sql_child_number ch# ,osuser  
   ,to_char(sql_exec_id,'xxxxxxxx') hex -- ,sstat.value cpu_value     --ltrim(p1raw,'0') p1raw 
   from    v$session ses    
   left join  v$sql sql on    ses.sql_hash_value = sql.hash_value and  sql.child_number=ses.sql_child_number  and sql.is_obsolete='N'
     left join v$pdbs pdb on ses.con_id=pdb.con_id 
   where  ses.type = 'USER' and ses.status<>'INACTIVE'   and ses.sid not in(select sys_context('userenv','sid') from dual)   order by  last_call_et,SECONDS_IN_WAIT; 
 select  sysdate current_time from dual; 
 
