select * from table(dbms_stats.diff_table_stats_in_history(
                         ownname => '&schemaname',
                         tabname => upper('&tabname'),
                         time1 => systimestamp,
                         time2 => '&time2'),
                         pctthreshold => 0));