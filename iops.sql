-- file: iops.sql
-- author: weejar.zhang (www.anbob.com)
-- 

col "Time+Delta" for a20
col "Metric" for a80

 select to_char(min(begin_time),'hh24:mi:ss')||' /'||round(avg(intsize_csec/100),0)||'s' "Time+Delta",
       metric_name||' - '||metric_unit "Metric", 
       sum(value_inst1) inst1, sum(value_inst2) inst2
 from
  ( select begin_time,intsize_csec,metric_name,metric_unit,metric_id,group_id,
       case inst_id when 1 then round(value,1) end value_inst1,
       case inst_id when 2 then round(value,1) end value_inst2
  from gv$sysmetric
  where metric_name in ('I/O Megabytes per Second',
'I/O Requests per Second','Average Synchronous Single-Block Read Latency')
  )
 group by metric_id,group_id,metric_name,metric_unit
 order by metric_name;  
 
 
 
 
 select * from 
 (select to_char(begin_time,'hh24:mi:ss')||'-'||to_char(end_time,'hh24:mi:ss') "time",metric_name||' - '||metric_unit "metric",inst_id,round(value,1) value 
  from gv$sysmetric  where metric_name in ('I/O Megabytes per Second','I/O Requests per Second','Average Synchronous Single-Block Read Latency')
  or metric_name like '%Physical Reads%Per Sec%' or metric_name like '%Physical Writes%Per Sec%'
 ) 
  pivot
  (sum(value) for inst_id in (1 as "inst_1",2 as "inst_2",3 as "inst_3",4 as "inst_4",5 as "inst_5",6 as "inst_6",7 as "inst_7",8 as "inst_8"))
order by 1,2;
