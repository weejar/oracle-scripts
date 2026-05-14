--------------------------------------------
--
-- file: release_tbs.sql
-- author: weizhao.zhang(www.anbob.com)
-- date: 2016/07/07
-- purpose: remove tablespace and move object to another tablespace
-- version: v1.2
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

select owner,segment_name,segment_type from dba_segments where tablespace_name=upper('&&tbsname');
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
prompt OBJ in tbs but noseg  in '&&tbsname'

select 'alter index '||owner||'.'||index_name||' rebuild  tablespace &&tbsname_new;' from dba_indexes where tablespace_name=upper('&&tbsname') and SEGMENT_CREATED='NO';
select 'alter index '||index_owner||'.'||index_name||' rebuild partition '||partition_name||' tablespace &&tbsname_new;' from dba_ind_partitions where tablespace_name=upper('&&tbsname') and SEGMENT_CREATED='NO';
select 'alter index '||index_owner||'.'||index_name||' rebuild subpartition '||subpartition_name||' tablespace &&tbsname_new;' from dba_ind_subpartitions where tablespace_name=upper('&&tbsname') and SEGMENT_CREATED='NO';

select 'alter table '||owner||'.'||table_name||' move'||'tablespace &&tbsname_new;' from dba_tables where tablespace_name=upper('&&tbsname') and partitioned='NO' and SEGMENT_CREATED='NO';
select 'alter table '||table_owner||'.'||table_name||' move partition '||partition_name||' tablespace &&tbsname_new;' from dba_tab_partitions where tablespace_name=upper('&&tbsname') and subpartition_count=0 and SEGMENT_CREATED='NO';
select 'alter table '||table_owner||'.'||table_name||' move subpartition '||subpartition_name||' tablespace &&tbsname_new;' from dba_tab_subpartitions where tablespace_name=upper('&&tbsname') and SEGMENT_CREATED='NO';

prompt ***********
prompt Lob type OBJ  in '&&tbsname'
select 'alter table '||owner||'.'||table_name||' move lob('||COLUMN_NAME||') store as (tablespace &&tbsname_new);' from dba_lobs lob  where tablespace_name=upper('&&tbsname');
 select 'ALTER TABLE '||table_owner||'.'||table_name||' MOVE partition '||Partition_name||' lob('||column_name||')'||' STORE AS (TABLESPACE &&tbsname_new) ;' from dba_lob_partitions where TABLESPACE_NAME =upper('&&tbsname');

SELECT 'alter table ' || TABLE_OWNER || '.' || TABLE_NAME || ' move subpartition ' || SUBPARTITION_NAME || ' lob (' || COLUMN_NAME || ') store as SECUREFILE(tablespace &&tbsname_new ) ;' FROM DBA_LOB_SUBPARTITIONS  lobsubp where TABLESPACE_NAME =upper('&&tbsname');

prompt ***********
prompt To check default user using '&&tbsname'
select 'alter user '||username||' default tablespace users; ' from dba_users where default_tablespace=upper('&&tbsname');


prompt ***********
prompt TO purge deleted object in recyclebin
prompt
prompt  purge  tablespace &&tbsname ;

prompt ***********
prompt TO release dbfiles to OS
select file_name,bytes/1024/1024 mb from dba_data_files where tablespace_name=upper('&&tbsname');

