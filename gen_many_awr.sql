-- instance awr
DECLARE
  l_dir              VARCHAR2(50) := 'DATAPUMP';  -- directory name, make sure it exists
  l_file             UTL_FILE.file_type;
  l_dbname        varchar2(200);
  l_awrfile_prefix varchar2(200);
BEGIN
   -- get dbname
   select name into l_dbname from v$database;
   
   -- awr file name prefix
   l_awrfile_prefix:='awrrpt_'||l_dbname|| '_';
   
   -- fetch generate  awr  report

for r in (SELECT dbid,INSTANCE_NUMBER,SNAP_ID,TO_CHAR(BEGIN_INTERVAL_TIME,'mm-dd_HH24:MI') tm  
FROM  dba_hist_snapshot WHERE TO_CHAR(BEGIN_INTERVAL_TIME,'HH24:MI') BETWEEN '08:30' AND '10:30' 
AND BEGIN_INTERVAL_TIME between sysdate-7 and sysdate   -- last 7 days
order by tm)
loop
    l_file := UTL_FILE.fopen(l_dir, l_awrfile_prefix||r.INSTANCE_NUMBER|| '_' || r.tm||'.html', 'w', 32767);
    FOR cur_rep IN (SELECT output
                    FROM   TABLE(DBMS_WORKLOAD_REPOSITORY.AWR_REPORT_HTML(r.dbid, r.INSTANCE_NUMBER, r.snap_id-1, r.snap_id)))
    LOOP
      UTL_FILE.put_line(l_file, cur_rep.output);
    END LOOP;
    UTL_FILE.fclose(l_file);
end loop;
END;
/


-- rac awr
DECLARE
  l_dir              VARCHAR2(50) := 'DUMP';
  l_file             UTL_FILE.file_type;
BEGIN
for r in (SELECT dbid,INSTANCE_NUMBER,SNAP_ID,TO_CHAR(BEGIN_INTERVAL_TIME,'mm-dd_HH24:MI') tm  
FROM  dba_hist_snapshot WHERE TO_CHAR(BEGIN_INTERVAL_TIME,'HH24:MI') BETWEEN '09:30' AND '10:30' 
AND TO_CHAR(BEGIN_INTERVAL_TIME,'MM-DD') IN ('02-01','02-09') order by tm)
loop
    l_file := UTL_FILE.fopen(l_dir, 'awrgrpt_tbcsa'|| '_' ||r.INSTANCE_NUMBER|| '_' || r.tm||'.htm', 'w', 32767);
    FOR cur_rep IN (SELECT output
                    FROM   TABLE(DBMS_WORKLOAD_REPOSITORY.AWR_GLOBAL_REPORT_HTML(r.dbid, null, r.snap_id-1, r.snap_id)))
    LOOP
      UTL_FILE.put_line(l_file, cur_rep.output);
    END LOOP;
    UTL_FILE.fclose(l_file);
end loop;
END;
/