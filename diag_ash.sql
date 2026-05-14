create table anbob.ash0829 tablespace users as select * from gv$active_session_history
where sample_time between to_date('2017-3-7 7:00','yyyy-mm-dd hh24:mi') and to_date('2017-3-7 8:17','yyyy-mm-dd hh24:mi');

select inst_id,min(sample_time),max(sample_time) from ash0829 group by inst_id;


-- ASH 每10分钟的TOP 10 EVENTS

select inst_id,min(SAMPLE_TIME),max(SAMPLE_TIME),count(*) from anbob.ash0829 group by inst_id;

break on etime skip 1
 select * from (
    select inst_id,etime,nvl(event,'on cpu') events, dbtime, round(threshold_in_ms,2), round(100*ratio_to_report(dbtime) OVER (partition by inst_id, etime ),2) pct,row_number() over(partition by inst_id,etime order by dbtime  desc) rn
 from (
select inst_id,substr(to_char(SAMPLE_TIME,'yyyymmdd hh24:mi'),1,13)||'0' etime,event,count(*) dbtime,avg(time_waited)/1000 threshold_in_ms
 from anbob.ash0829
 where SESSION_TYPE='FOREGROUND' -- and sample_time between to_date('2024-6-24 06:00','yyyy-mm-dd hh24:mi') and to_date('2024-6-24 07:00','yyyy-mm-dd hh24:mi')
 group by inst_id,substr(to_char(SAMPLE_TIME,'yyyymmdd hh24:mi'),1,13),event
)
) where rn<=5;  



break on etime skip 1
 select * from (
    select etime,nvl(event,'on cpu') events, dbtime, round(threshold_in_ms,2), round(100*ratio_to_report(dbtime) OVER (partition by etime ),2) pct,row_number() over(partition by etime order by dbtime  desc) rn
 from (
select substr(to_char(SAMPLE_TIME,'yyyymmdd hh24:mi'),1,13)||'0' etime,event,count(*) dbtime,avg(time_waited)/1000 threshold_in_ms
 from anbob.ash0829
 where inst_id=1
-- and  sample_time between to_date('2024-6-24 06:00','yyyy-mm-dd hh24:mi') and to_date('2024-6-24 09:00','yyyy-mm-dd hh24:mi')
 group by substr(to_char(SAMPLE_TIME,'yyyymmdd hh24:mi'),1,13),event
)
) where rn<=5;  



-- 并行会话
break on inst_id skip page on  etime skip 1
col etime for a20
col event for a25
COL PCT FOR 9999999
col cpus for a5
col load for a30
col db_time for a15
col in_parse for a10
col qc for a10
col sql_id for a22
col avg_waited for 999,990.90 head avg_ms
col sesid for a15
col bs for a10
col TOP_LEVEL_SQL_ID for a22
col SQL_ID for a18
col p1_p2 for a15

select to_char(SAMPLE_TIME,'yyyymmdd hh24:mi:ss') etime,event,p1||':'||p2 p1_p2,inst_id||':'||SESSION_ID||':'||SESSION_SERIAL# sesid,IS_SQLID_CURRENT,--SQL_OPCODE,
sql_id --,TOP_LEVEL_SQL_ID ,TOP_LEVEL_SQL_OPCODE  ,SQL_PLAN_HASH_VALUE,SQL_PLAN_LINE_ID,SQL_PLAN_OPERATION
,SQL_EXEC_ID,SQL_EXEC_START
--,PLSQL_ENTRY_OBJECT_ID,PLSQL_ENTRY_SUBPROGRAM_ID,PLSQL_OBJECT_ID
,QC_INSTANCE_ID||':'||QC_SESSION_ID||':'||QC_SESSION_SERIAL#  qc,SEQ# ,
SESSION_STATE,TIME_WAITED,BLOCKING_INST_ID||':'||BLOCKING_SESSION bs,CURRENT_OBJ# ,TOP_LEVEL_CALL_NAME
IN_PARSE,IN_SQL_EXECUTION,IN_PLSQL_EXECUTION --,IN_BIND,IN_CURSOR_CLOSE,MACHINE,PROGRAM
--,PGA_ALLOCATED,TEMP_SPACE_ALLOCATED
 from system.ASH_20240409 where  --session_id=2661 and SESSION_SERIAL#=175 
 QC_SESSION_ID=2661 and QC_SESSION_SERIAL#=175 
 order by 1
 



-- ASH 每1分钟的TOP 5 EVENTS

col pct for 999.00

 select * from (
    select etime,nvl(event,'on cpu') events, dbtime, round(threshold_in_ms,2), round(100*ratio_to_report(dbtime) OVER (partition by etime ),2) pct,row_number() over(partition by etime order by dbtime  desc) rn
 from (
select to_char(SAMPLE_TIME,'yyyymmdd hh24:mi')   etime,event,count(*) dbtime,avg(time_waited)/1000 threshold_in_ms
 from anbob.ash0829
 where inst_id=1
and  SESSION_TYPE='FOREGROUND' -- and sample_time between to_date('2024-6-24 06:00','yyyy-mm-dd hh24:mi') and to_date('2024-6-24 07:00','yyyy-mm-dd hh24:mi')
 group by to_char(SAMPLE_TIME,'yyyymmdd hh24:mi'),event
)
) where rn<=5;  



break on inst_id skip page on  etime skip 1
col events for a35
COL PCT FOR a20
col cpus for a5
col load for a30
col db_time for a15
col avg_waited for 999,990.90 head avg_ms
 select inst_id,etime,events,db_time,avg_waited,pct,aas,lpad('*',sum(aas) over(partition by inst_id,etime)/192,'*') load
 from (
        select inst_id,etime,nvl(event,'on cpu') events, lpad(dbtime,10,' ')||' s' db_time,round(dbtime/60) AAS, avg_waited,(select param.value from gv$parameter param where param.name like '%cpu_count%' and param.inst_id=v.inst_id ) cpus
		,lpad(round(100*ratio_to_report(dbtime) OVER (partition by etime ),2)||'%',15,' ') pct,row_number() over(partition by etime order by dbtime  desc) rn
     from (
    select  inst_id,to_char(SAMPLE_TIME,'yyyymmdd hh24:mi') etime,event,  count(*) dbtime, round(avg(time_waited)/1000,2) avg_waited 
     from anbob.ash0829 gash 
     where SESSION_TYPE='FOREGROUND'  and  inst_id=1
and  sample_time between to_date('20250829 10:01','yyyy-mm-dd hh24:mi') and to_date('20250829 10:18','yyyy-mm-dd hh24:mi')
     group by  inst_id,to_char(SAMPLE_TIME,'yyyymmdd hh24:mi'),event
    ) v
    ) where rn<=5
	order by 1,2,4 desc; 
	
	
	-- top  SQL ID
break on inst_id skip page on  etime skip 1
col events for a35
COL PCT FOR a20
col cpus for a5
col load for a30
col db_time for a15
col avg_waited for 999,990.90 head avg_ms
 select inst_id,etime,events, sql_id,db_time,avg_waited,pct,aas,lpad('*',sum(aas) over(partition by inst_id,etime)/192,'*') load
 from (
        select inst_id,etime,nvl(event,'on cpu') events, sql_id, lpad(dbtime,10,' ')||' s' db_time,round(dbtime/60) AAS, avg_waited,(select param.value from gv$parameter param where param.name like '%cpu_count%' and param.inst_id=v.inst_id ) cpus
		,lpad(round(100*ratio_to_report(dbtime) OVER (partition by etime ),2)||'%',15,' ') pct,row_number() over(partition by etime order by dbtime  desc) rn
     from (
    select  inst_id,to_char(SAMPLE_TIME,'yyyymmdd hh24:mi') etime,event, sql_id, count(*) dbtime, round(avg(time_waited)/1000,2) avg_waited 
     from anbob.ash0829 gash 
     where  SESSION_TYPE='FOREGROUND'  and 
	 inst_id=1
and  sample_time between to_date('20250829 10:06','yyyy-mm-dd hh24:mi') and to_date('20250829 10:18','yyyy-mm-dd hh24:mi')
     group by  inst_id,to_char(SAMPLE_TIME,'yyyymmdd hh24:mi'),event, sql_id
    ) v
    ) where rn<=3
	order by 1,2,5 desc; 
	
	--  top PROGRAM
 select inst_id,etime,  program,db_time,avg_waited,pct,aas,lpad('*',sum(aas) over(partition by inst_id,etime)/192,'*') load
 from (
        select inst_id,etime,  program, lpad(dbtime,10,' ')||' s' db_time,round(dbtime/60) AAS, avg_waited,(select param.value from gv$parameter param where param.name like '%cpu_count%' and param.inst_id=v.inst_id ) cpus
		,lpad(round(100*ratio_to_report(dbtime) OVER (partition by etime ),2)||'%',15,' ') pct,row_number() over(partition by etime order by dbtime  desc) rn
     from (
    select  inst_id,to_char(SAMPLE_TIME,'yyyymmdd hh24:mi') etime, program, count(*) dbtime, round(avg(time_waited)/1000,2) avg_waited 
     from anbob.ash0829 gash 
     where  SESSION_TYPE='FOREGROUND'  and 
	 inst_id=1
and  sample_time between to_date('20250829 10:06','yyyy-mm-dd hh24:mi') and to_date('20250829 10:18','yyyy-mm-dd hh24:mi')
     group by  inst_id,to_char(SAMPLE_TIME,'yyyymmdd hh24:mi'),  program
    ) v
    ) where rn<=3
	order by 1,2,4 desc; 
	
	
-- top program , sql id 
	
 select inst_id,etime,events, program,sql_id,db_time,avg_waited,pct,aas,lpad('*',sum(aas) over(partition by inst_id,etime)/192,'*') load
 from (
        select inst_id,etime,nvl(event,'on cpu') events, program,sql_id, lpad(dbtime,10,' ')||' s' db_time,round(dbtime/60) AAS, avg_waited,(select param.value from gv$parameter param where param.name like '%cpu_count%' and param.inst_id=v.inst_id ) cpus
		,lpad(round(100*ratio_to_report(dbtime) OVER (partition by etime ),2)||'%',15,' ') pct,row_number() over(partition by etime order by dbtime  desc) rn
     from (
    select  inst_id,to_char(SAMPLE_TIME,'yyyymmdd hh24:mi') etime,event, program,sql_id, count(*) dbtime, round(avg(time_waited)/1000,2) avg_waited 
     from anbob.ash0829 gash 
     where --SESSION_TYPE='FOREGROUND'  and 
	 inst_id=1
and  sample_time between to_date('20250829 10:06','yyyy-mm-dd hh24:mi') and to_date('20250829 10:18','yyyy-mm-dd hh24:mi') 
     group by  inst_id,to_char(SAMPLE_TIME,'yyyymmdd hh24:mi'),event, program,sql_id
    ) v
    ) where rn<=3
	order by 1,2,6 desc; 
	
 select inst_id,etime,events, program,sql_id,db_time,avg_waited,pct,aas,lpad('*',sum(aas) over(partition by inst_id,etime)/192,'*') load
 from (
        select inst_id,etime,nvl(event,'on cpu') events, program,sql_id, lpad(dbtime,10,' ')||' s' db_time,round(dbtime/60) AAS, avg_waited,(select param.value from gv$parameter param where param.name like '%cpu_count%' and param.inst_id=v.inst_id ) cpus
		,lpad(round(100*ratio_to_report(dbtime) OVER (partition by etime ),2)||'%',15,' ') pct,row_number() over(partition by etime order by dbtime  desc) rn
     from (
    select  inst_id,to_char(SAMPLE_TIME,'yyyymmdd hh24:mi') etime,event, program,sql_id, count(*) dbtime, round(avg(time_waited)/1000,2) avg_waited 
     from anbob.ash0829 gash 
     where --SESSION_TYPE='FOREGROUND'  and 
	 inst_id=1
and  sample_time between to_date('20250829 10:06','yyyy-mm-dd hh24:mi') and to_date('20250829 10:18','yyyy-mm-dd hh24:mi') 
     group by  inst_id,to_char(SAMPLE_TIME,'yyyymmdd hh24:mi'),event, program,sql_id
    ) v
    ) where rn<=3
	order by 1,2,6 desc; 
	

	
select inst_id, to_char(SAMPLE_TIME,'yyyymmdd hh24:mi') etime,user_id,program,sql_id,event,blocking_inst_id,blocking_session ,CURRENT_OBJ#,count(*)
from anbob.ash0829 gash 
     where --SESSION_TYPE='FOREGROUND'  and 
	 inst_id=1
and  sample_time between to_date('20250829 10:06','yyyy-mm-dd hh24:mi') and to_date('20250829 10:18','yyyy-mm-dd hh24:mi') 
and event like 'enq: TX - index contention' 
group by inst_id,user_id,program,sql_id,event,blocking_inst_id,blocking_session,to_char(SAMPLE_TIME,'yyyymmdd hh24:mi')  ,CURRENT_OBJ#
order by 1,2;
	
	
select inst_id,sample_id,to_char(SAMPLE_TIME,'yyyymmdd hh24:mi:ss') etime,session_id,machine,user_id,program,sql_id,event,p1,p2,p3,blocking_inst_id,blocking_session
from anbob.ash0829 gash 
     where --SESSION_TYPE='FOREGROUND'  and 
	 inst_id=1
and  sample_time between to_date('20250829 10:06','yyyy-mm-dd hh24:mi') and to_date('20250829 10:18','yyyy-mm-dd hh24:mi') 
and event like 'enq%' 
and sql_id='6nur82ms484b8'
and sample_id=140273716
order by 1,2;

select inst_id,sample_id,to_char(SAMPLE_TIME,'yyyymmdd hh24:mi:ss') etime,machine,user_id,program,sql_id,event,p1,p2,p3,blocking_inst_id,blocking_session 
,TIME_WAITED,SEQ#,SQL_EXEC_ID,SQL_EXEC_START,TOP_LEVEL_SQL_ID
from anbob.ash0829 gash 
     where --SESSION_TYPE='FOREGROUND'  and 
	 inst_id=1
and  sample_time between to_date('20250829 10:06','yyyy-mm-dd hh24:mi') and to_date('20250829 10:18','yyyy-mm-dd hh24:mi') 
and event like 'enq%' 
and sql_id='6nur82ms484b8'
--and sample_id=140273716
and session_id=1330
order by 1,2;
	