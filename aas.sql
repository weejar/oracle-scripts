select  hh24,round(aas/cpus,2) loads from (			   
  SELECT   to_char(sample_time,'hh24') hh24,  ROUND (COUNT (*) / ( (SYSDATE - (SYSDATE - 5 / 24 / 60)) * 86400), 1)   AAS
             FROM v$active_session_history a
           WHERE     session_type = 'FOREGROUND'
                 AND sample_time> sysdate-1
				 group by to_char(sample_time,'hh24')) v1,
				 (SELECT value cpus FROM V$PARAMETER WHERE NAME LIKE 'cpu_count') v2;