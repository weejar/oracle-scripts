-- file: ase.sql
-- version: 2.1
-- author: weejar zhang(anbob.com)
-- Desc. To Display all sessions of ForeGround not "inactive"
-- Created: 2015/7/25
---if slow check execution plan access v$sql  should use index

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

SELECT /*+ */
    ses.username,
    ses.sid,
    CASE
            WHEN ses.state != 'WAITING' THEN 'On CPU / runqueue'
            ELSE event
        END
    AS event,
    ses.machine,
    regexp_substr(ses.module,'[^@]+') module,
    ses.status,
    ses.last_call_et --,   seq#  
   , ses.sql_id,
    wait_time
    || ':'
    || seconds_in_wait wai_secinwait,
    row_wait_obj#,
    substr(sql.sql_text,1,30) sqltext,
    final_blocking_instance
    || ':'
    || final_blocking_session bs,
    sql_child_number ch#,
    osuser,
    TO_CHAR(sql_exec_id,'xxxxxxxx') hex -- ,sstat.value cpu_value     --ltrim(p1raw,'0') p1raw 
    --taddr  
FROM
    v$session ses
    LEFT JOIN v$sql sql ON ses.sql_hash_value = sql.hash_value
                           AND ses.sql_child_number = sql.child_number 
WHERE
    ses.type = 'USER'
    AND   ses.status <> 'INACTIVE'  -- and sql.is_obsolete='N' --slower caused by full scan fixed table
    AND   ses.sid NOT IN (
        SELECT
            sys_context('userenv','sid')
        FROM
            dual
    )
ORDER BY
    last_call_et,
    seconds_in_wait;

SELECT
    SYSDATE current_time
FROM
    dual;