
purpose: move empty table partitions to another tablespace
version: 0.1
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
   tablespace_name      varchar2(50),
   last_analyze_time    DATE DEFAULT SYSDATE,
   flag                 NUMBER (1) default 1 not null ,   
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
   v_commit number:=0;
   CURSOR cur1
   IS
      SELECT owner,
             segment_name,
             partition_name,
			 tablespace_name,
             bytes
        FROM dba_segments
       WHERE     blocks<=1024 -- bytes < 5 * 1024 * 1024
             AND segment_type = 'TABLE PARTITION'
			 and segment_name not like 'BIN%'
			 and tablespace_name in(select distinct tablespace_name from dba_data_files where online_status='OFFLINE');
BEGIN
   FOR it IN cur1
   LOOP
   
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
            'insert into dbmt.empty_tab_partition(owner,table_name,partition_name,tablespace_name,bytes) values(:1,:2,:3,:4,:5)'
            USING it.owner,
                  it.segment_name,
                  it.partition_name,
				  it.tablespace_name,
                  it.bytes;
		 v_commit:=v_commit+1;
		 
		 if v_commit>=100 then
		    commit;
			v_commit:=0;
		end if ;
      END IF;
	  
   END LOOP;
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
         || ' move  partition '
         || it.partition_name
		 ||' tablespace '
		 || it.tablespace_name||'_new'
		 ||' segment creation deferred');


      EXECUTE IMMEDIATE
	   'alter table '
         || it.owner
         || '.'
         || it.table_name
         || ' move  partition '
         || it.partition_name
		 ||' tablespace '
		 || it.tablespace_name||'_new'
		 ||' segment creation deferred';

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

select 'alter index '||index_owner ||'.'||index_name||' rebuild partition '||partition_name||' ;' from dba_ind_partitions where status not in ('N/A', 'USABLE')  
 union all 
 select 'alter index '||owner||'.'||index_name||' rebuild;' from dba_indexes where  status not in ('VALID', 'N/A')  
 union all 
 select 'alter index '||index_owner ||'.'||index_name||' rebuild subpartition '||subpartition_name||' ;' from   dba_ind_subpartitions where status not in ('USABLE') ;