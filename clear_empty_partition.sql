purpose: drop empty table partitions until time(xxxxxxxx)
version: 0.5
author:  anbob.com

1, To create a temporary table for empty table partition
 
DROP TABLE dbmt.empty_tab_partition;

CREATE TABLE dbmt.empty_tab_partition
(
   owner                VARCHAR2 (20),
   table_name           VARCHAR2 (30),
   partition_name       VARCHAR2 (30),
   bytes                NUMBER,
   partition_position   NUMBER,
   last_analyze_time    DATE DEFAULT SYSDATE,
   flag                 NUMBER (1) not null default 1,   
   deleted              number(1)   --1 deleted  0 not
);

--truncate table dbmt.empty_tab_partition;


2, To find empty table partitions into a temporary table

DECLARE
   -- purpose: drop empty table partitions
   -- authore: zhangweizhao
   -- date:  2016-7-5
   -- note:  partition name end with yyyymm format and later than 2015-1-1
   -- hist : 2018-2-5  exclude recyclebin segment
   v_cnt   NUMBER;

   CURSOR cur1
   IS
      SELECT owner,
             segment_name,
             partition_name,
             bytes
        FROM dba_segments
       WHERE    blocks<=1024 -- bytes < 5 * 1024 * 1024
             AND REGEXP_LIKE (partition_name, '20[0-4]{2}[0-9]{2,4}$')
             AND segment_type = 'TABLE PARTITION'
			 and segment_name not like 'BIN%'
			 and owner in('ACCOUNT','TBCS');    ---- list drop schema, need modify
BEGIN
   FOR it IN cur1
   LOOP
   
--     dbms_output.put_line('select count(*) into v_cnt from '
--            || it.owner
--            || '.'
--            || it.segment_name
--            || ' partition( '
--            || it.partition_name
--            || ') where rownum<2');


      EXECUTE IMMEDIATE
            'select count(*)  from '
         || it.owner
         || '.'
         || it.segment_name
         || ' partition( '
         || it.partition_name
         || ') where rownum<2' into v_cnt;

      IF v_cnt < 1
      THEN
         EXECUTE IMMEDIATE
            'insert into dbmt.empty_tab_partition(owner,table_name,partition_name,bytes) values(:1,:2,:3,:4)'
            USING it.owner,
                  it.segment_name,
                  it.partition_name,
                  it.bytes;
      END IF;
   END LOOP;
   commit;
   
   -- do not drop partitions of last 6 months
   update dbmt.empty_tab_partition set flag=-1
    where to_date(REGEXP_substr(partition_name, '20[0-4]{2}[0-9]{2}$'),'yyyymm')  >add_months(sysdate,-6);
    
   commit;
   
END;


3, verify

select count(*), sum(decode(flag,-1,1,0)) from dbmt.empty_tab_partition;

select owner,count(*)  from dbmt.empty_tab_partition group by owner;


!!!!!!!!!!!!!!!!!! 生成临时表数据后，确认后，删除操作不要间隔太久避免删除前有数据写入，  操作需谨慎  !!!!!!!!!!
4, drop empty table partition  and update flag

DECLARE 
   CURSOR curt
   IS
        SELECT *
          FROM dbmt.empty_tab_partition
         WHERE flag=1 and (deleted is null or deleted<>1)    ORDER BY 1, 2, 3;
	v_msg      VARCHAR2 (2000) := '';	 

BEGIN
   --  note implicit commit after DDL
   FOR it IN curt
   LOOP
      BEGIN
      DBMS_OUTPUT.put_line (
            'alter table '
         || it.owner
         || '.'
         || it.table_name
         || ' drop partition '
         || it.partition_name);


      EXECUTE IMMEDIATE
           'alter table '
        || it.OWNER
        || '.'
        || it.table_name
        || ' drop partition '
        || it.partition_name;

      EXECUTE IMMEDIATE
         'update dbmt.empty_tab_partition set deleted=1 where owner=:1 and table_name=:2 and partition_name=:3'
         USING it.owner, it.table_name, it.partition_name;
	  EXCEPTION
	     WHEN OTHERS
         THEN
		     v_msg:='drop partition Fail,Err:'||SQLCODE;
			 DBMS_OUTPUT.put_line(v_msg);
			 EXECUTE IMMEDIATE 'update dbmt.empty_tab_partition set deleted=0 where owner=:1 and table_name=:2 and partition_name=:3'
					USING it.owner, it.table_name, it.partition_name;
		 
	  END;
   END LOOP;

   COMMIT;
END;


5, verify

-- 检查删除进度
select deleted,round(ratio_to_report(count(*)) over(),4)*100,count(*) from dbmt.empty_tab_partition where last_analyze_time>sysdate-10 group by deleted;

-- 删除明细
SELECT *
  FROM dbmt.empty_tab_partition
 WHERE deleted = 1

6, check index invalid

select 'alter index '||index_owner ||'.'||index_name||' rebuild partition '||partition_name||';' from dba_ind_partitions where status not in ('N/A', 'USABLE');

7, 检查没有删掉的表
SELECT table_owner,table_name,partition_name,last_analyzed
  FROM dba_tab_partitions b
 WHERE EXISTS
          (SELECT 1
             FROM dbmt.empty_tab_partition c
            WHERE     b.table_owner = c.owner
                  AND b.table_name = c.table_name
                  AND b.partition_name = c.partition_name);


8, 根据表空间监控， 估算清理空间
  SELECT DISTINCT TO_CHAR (exectime, 'yyyy-mm-dd hh24'), db_name
    FROM DB_FREESPACE
   WHERE db_name LIKE 'account%' AND exectime > SYSDATE - 1
ORDER BY 1;

WITH c
     AS (  SELECT
                 exectime, db_name, SUM (used_space) used_mb
             FROM DB_FREESPACE
            WHERE     db_name LIKE 'account%'
                  AND exectime BETWEEN TO_DATE ('2016-07-20 10:00',
                                                'yyyy-mm-dd hh24:mi')
                                   AND TO_DATE ('2016-07-21 10:01',
                                                'yyyy-mm-dd hh24:mi')
         GROUP BY exectime, db_name),
     d
     AS (  SELECT db_name, MIN (used_mb) minused, MAX (used_mb) maxused
             FROM c
         GROUP BY db_name)
SELECT db_name,
       minused,
       maxused,
       maxused - minused diff
  FROM d;

DBNAME		MIN			MAX			DIFF
--------	--------	--------	------
accountb	12064.22	12375.81	311.59
accountc	11181.82	11615.72	433.9
accountd	12455.87	12850.34	394.47
accounta	5541.1	     6763.47	122.37