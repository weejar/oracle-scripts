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
 