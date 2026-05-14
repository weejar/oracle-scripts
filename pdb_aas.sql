with subq_snaps AS
(SELECT dbid                dbid
 ,      instance_number     inst
 ,      snap_id             e_snap
 ,      lag(snap_id) over (partition by instance_number, startup_time order by snap_id) b_snap
 ,      TO_CHAR(begin_interval_time,'yyyymmdd') b_day
 ,      TO_CHAR(begin_interval_time,'HH24')   b_hour
 ,    (cast(END_INTERVAL_TIME as date) - cast(BEGIN_INTERVAL_TIME as date))
    *86400 as elapsed 
 FROM   dba_hist_snapshot 
 where begin_interval_time>trunc(sysdate-30) 	and  dbid in (select dbid from v$database)
 ), t as (
select instance_number,con_id,b_day,b_hour ,sum(sec)/sum(elapsed) aas
from 
(select stm.con_id,sn.inst,stm.instance_number,(stme.value-stm.value)/1000000 sec,sn.b_day,sn.b_hour,sn.elapsed
FROM DBA_HIST_CON_SYS_TIME_MODEL stm,DBA_HIST_CON_SYS_TIME_MODEL stme,subq_snaps sn
      WHERE
      stm.dbid=sn.dbid
      and stm.instance_number=sn.inst 
	  and stm.con_id=stme.con_id
	  and stm.snap_id=sn.b_snap
	  and stme.snap_id=sn.e_snap
	  and stm.stat_id=stme.stat_id
      and stme.dbid=sn.dbid
      and stme.instance_number=sn.inst
	  and stm.stat_name='DB time')
	  GROUP BY instance_number,con_id,b_day ,b_hour
	  )
SELECT instance_number,con_id,b_day,
  NVL("00-01_ ",0) "00-01_ ",
  NVL("01-02_ ",0) "01-02_ ",
  NVL("02-03_ ",0) "02-03_ ",
  NVL("03-04_ ",0) "03-04_ ",
  NVL("04-05_ ",0) "04-05_ ",
  NVL("05-06_ ",0) "05-06_ ",
  NVL("06-07_ ",0) "06-07_ ",
  NVL("07-08_ ",0) "07-08_ ",
  NVL("08-09_ ",0) "08-09_ ",
  NVL("09-10_ ",0) "09-10_ ",
  NVL("10-11_ ",0) "10-11_ ",
  NVL("11-12_ ",0) "11-12_ ",
  NVL("12-13_ ",0) "12-13_ ",
  NVL("13-14_ ",0) "13-14_ ",
  NVL("14-15_ ",0) "14-15_ ",
  NVL("15-16_ ",0) "15-16_ ",
  NVL("16-17_ ",0) "16-17_ ",
  NVL("17-18_ ",0) "17-18_ ",
  NVL("18-19_ ",0) "18-19_ ",
  NVL("19-20_ ",0) "19-20_ ",
  NVL("20-21_ ",0) "20-21_ ",
  NVL("21-22_ ",0) "21-22_ ",
  NVL("22-23_ ",0) "22-23_ ",
  NVL("23-24_ ",0) "23-24_ "
FROM t pivot( SUM(aas) AS " " FOR b_hour IN ('00' AS "00-01",'01' AS "01-02",'02' AS "02-03",'03' AS "03-04",'04' AS "04-05",'05' AS "05-06",'06' AS "06-07",'07' AS "07-08",
                                          '08' AS "08-09",'09' AS "09-10",'10' AS "10-11", '11' AS "11-12",'12' AS "12-13",'13' AS "13-14",'14' AS "14-15",'15' AS "15-16",
                                          '16' AS "16-17",'17' AS "17-18",'18' AS "18-19",'19' AS "19-20",'20' AS "20-21",'21' AS "21-22", '22' AS "22-23",'23' AS "23-24") 
            )
ORDER BY instance_number,con_id,b_day;




