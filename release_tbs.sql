--------------------------------------------
--
-- file: release_tbs.sql
-- author: weejar
-- Create date: 2016/07/07
-- purpose: remove tablespace and move object to another tablespace
-- version: v1.3
---------------------------------------------

undefine tbsname
col file_name for a70
col segment_name for a30
col segment_type for a40
col owner for a20
col scripts for a200
prompt
column uservar new_value tbsname_new noprint
select 'USERS' uservar from dual;
accept tbsname prompt 'Please enter Name of Tablespace: '
accept tbsname_new prompt 'Please enter Name of Tablespace will move to: '

prompt List segments in current tablespace :
select owner,segment_name,segment_type from dba_segments where tablespace_name=upper('&&tbsname');


select 
COUNT(*) TOTAL,
sum(case when bytes/1024/1024 between 0 and 5 then 1 end) "0-5M",
sum(case when bytes/1024/1024 between 5 and 10 then 1 end) "5-10M",
sum(case when bytes/1024/1024 between 10 and 50 then 1 end) "10-50M",
sum(case when bytes/1024/1024 between 50 and 100 then 1 end) "50-100M",
sum(case when bytes/1024/1024 between 100 and 1024 then 1 end) "100-1024M",
sum(case when bytes/1024/1024 between 1024 and 10240 then 1 end) "1-10G",
sum(case when bytes/1024/1024 between 10240 and 50240 then 1 end) "10-50G",
sum(case when bytes/1024/1024 between 50240 and 102400 then 1 end) "50-100G",
sum(case when bytes/1024/1024 between 102400 and 204800 then 1 ELSE 0 end) "100-200G",
sum(case when bytes/1024/1024 >204800 then 1 ELSE 0 end) "200G+" from dba_segments 
where tablespace_name=upper('&&tbsname');
--where tablespace_name in(select distinct tablespace_name from dba_data_files where online_status='OFFLINE') ;


prompt 'MOVE to another tablespace scripts:'
select decode(segment_type,'INDEX','alter index ','TABLE','alter table ','TABLE PARTITION','alter table ','TABLE SUBPARTITION','alter table ','INDEX PARTITION','alter index ')||owner||'.'||segment_name
       ||  decode(segment_type,'INDEX',' rebuild ',
	   'TABLE',' move ',
	   'TABLE PARTITION',' move partition '||partition_name,
	   'TABLE SUBPARTITION',' move subpartition '||partition_name,
	   'INDEX SUBPARTITION',' rebuild subpartition '||partition_name,
	   'INDEX PARTITION',' rebuild partition '||partition_name)|| ' tablespace &&tbsname_new;' scripts
	   from dba_segments where tablespace_name=upper('&&tbsname') and (segment_type like 'INDEX%' OR segment_type like 'TABLE%');
  
prompt ***********
prompt IOT in tbs but noseg  in '&&tbsname'

with idxsegs as (
	select i.owner, i.index_name, t.table_name
	from dba_indexes i
	join dba_tables t on t.table_name = i.table_name
		and t.owner = i.table_owner
	where iot_type = 'IOT'
)
select  'alter table '||s.owner||'.'||xs.table_name|| 
decode(segment_type,'INDEX',' move ',
           'INDEX SUBPARTITION',' move subpartition '||partition_name,
           'INDEX PARTITION',' move partition '||partition_name)|| ' tablespace &&tbsname_new;' scripts
from dba_segments s
join idxsegs xs on xs.owner = s.owner
	and xs.index_name = s.segment_name
 where s.tablespace_name=upper('&&tbsname');

prompt ***********
prompt OBJ in tbs but noseg  in '&&tbsname'

select 'alter index '||owner||'.'||index_name||' rebuild  tablespace &&tbsname_new;' from dba_indexes where tablespace_name=upper('&&tbsname') and SEGMENT_CREATED='NO';
select 'alter index '||index_owner||'.'||index_name||' rebuild partition '||partition_name||' tablespace &&tbsname_new;' from dba_ind_partitions where tablespace_name=upper('&&tbsname') and SEGMENT_CREATED='NO';
select 'alter index '||index_owner||'.'||index_name||' rebuild subpartition '||subpartition_name||' tablespace &&tbsname_new;' from dba_ind_subpartitions where tablespace_name=upper('&&tbsname') and SEGMENT_CREATED='NO';

select 'alter table '||owner||'.'||table_name||' move  tablespace &&tbsname_new;' from dba_tables where tablespace_name=upper('&&tbsname') and partitioned='NO' and SEGMENT_CREATED='NO';
select 'alter table '||table_owner||'.'||table_name||' move partition '||partition_name||' tablespace &&tbsname_new;' from dba_tab_partitions where tablespace_name=upper('&&tbsname') and subpartition_count=0 and SEGMENT_CREATED='NO';
select 'alter table '||table_owner||'.'||table_name||' move subpartition '||subpartition_name||' tablespace &&tbsname_new;' from dba_tab_subpartitions where tablespace_name=upper('&&tbsname') and SEGMENT_CREATED='NO';

prompt ***********
prompt  OBJ  Default Attributes  in '&&tbsname'

SELECT 'ALTER INDEX '||OWNER||'.'||INDEX_NAME||' MODIFY DEFAULT ATTRIBUTES TABLESPACE &&tbsname_new;' FROM DBA_PART_INDEXES WHERE DEF_TABLESPACE_NAME=upper('&&tbsname');
SELECT 'ALTER TABLE '||OWNER||'.'||TABLE_NAME||'  MODIFY DEFAULT ATTRIBUTES TABLESPACE &&tbsname_new;' FROM DBA_PART_TABLES WHERE DEF_TABLESPACE_NAME=upper('&&tbsname');

SELECT 'ALTER TABLE '||table_OWNER||'.'||TABLE_NAME||'  MODIFY DEFAULT ATTRIBUTES for partition '|| partition_name||' TABLESPACE &&tbsname_new;'       
 FROM dba_tab_partitions tp where tp.tablespace_name=upper('&&tbsname');

SELECT 'ALTER index '||index_OWNER||'.'||INDEX_NAME||'  MODIFY DEFAULT ATTRIBUTES for partition '|| partition_name||' TABLESPACE &&tbsname_new;'       
 FROM dba_ind_partitions tp
where tp.tablespace_name where tp.tablespace_name=upper('&&tbsname');

prompt ***********
prompt Lob type OBJ  in '&&tbsname'
select 'alter table '||owner||'.'||table_name||' move lob('||COLUMN_NAME||') store as (tablespace &&tbsname_new);' from dba_lobs lob  where tablespace_name=upper('&&tbsname');
select 'ALTER TABLE '||table_owner||'.'||table_name||' MOVE partition '||Partition_name||' lob('||column_name||')'||' STORE AS (TABLESPACE &&tbsname_new) ;' from dba_lob_partitions where TABLESPACE_NAME =upper('&&tbsname');

SELECT 'alter table ' || TABLE_OWNER || '.' || TABLE_NAME || ' move subpartition ' || SUBPARTITION_NAME || ' lob (' || COLUMN_NAME || ') store as SECUREFILE(tablespace &&tbsname_new ) ;' FROM DBA_LOB_SUBPARTITIONS  lobsubp where TABLESPACE_NAME =upper('&&tbsname');

prompt ***********
prompt To check default user using '&&tbsname'
select 'alter user '||username||' default tablespace &&tbsname_new; ' from dba_users where default_tablespace=upper('&&tbsname');


prompt ***********
prompt TO purge deleted object in recyclebin, to  run the following command manually:
prompt
prompt  purge  tablespace &&tbsname ;

prompt ***********
prompt TO release dbfiles to OS
select file_name,bytes/1024/1024 mb from dba_data_files where tablespace_name=upper('&&tbsname');



 
 
