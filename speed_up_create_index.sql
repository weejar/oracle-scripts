alter session set workarea_size_policy=MANUAL;
alter session set db_file_multiblock_read_count=512;
alter session set events '10351 trace name context forever, level 128';
alter session set sort_area_size=734003200;
alter session set "_sort_multiblock_read_count"=128;
alter session enable parallel ddl;
alter session set db_file_multiblock_read_count=512;
alter session set db_file_multiblock_read_count=512;
alter session set "_sort_multiblock_read_count"=128;
alter session set "_sort_multiblock_read_count"=128;

TABLE_OWNER          TABLE_NAME                     INDEX_NAME                     POS# COLUMN_NAME            DSC
-------------------- ------------------------------ ------------------------------ ---- ------------------------------ ----
SPOTFIRE             TAB_MOD_LOTHISTORY_NEW         IDX_TAB_MOD_LOTHISTORY_NEW        1 TIMEKEY
                                                                                      2 OLDPROCESSOPERATIONNAME
                                                    TAB_MOD_LOTHISTORY_IX_ID          1 LOTNAME
                                                                                  2 OLDPROCESSOPERATIONNAME
-- 处理PK invalid 
									
drop index groulbo_xxxx;

create index SPOTFIRE.idx_TAB_MOD_LOTHISTORY_NEW on SPOTFIRE.TAB_MOD_LOTHISTORY_NEW(TIMEKEY,OLDPROCESSOPERATIONNAME) local unusable  ;

create  index SPOTFIRE.TAB_MOD_LOTHISTORY_NEW_pk on SPOTFIRE.TAB_MOD_LOTHISTORY_NEW(TIMEKEY,lotname) local unusable  ;

-- unique 
-- 分区有pk local index 必须包含分区键
alter table SPOTFIRE.TAB_MOD_LOTHISTORY_NEW add constraint TAB_MOD_LOTHISTORY_NEW_pk  primary key(TIMEKEY,lotname) using index SPOTFIRE.TAB_MOD_LOTHISTORY_NEW_pk;
  

CREATE INDEX INDEX_SPACE0_IX_LOCAL LOCAL  .........  UNUSABLE ;
 
CREATE INDEX INDEX_SPACE0_IX_LOCAL LOCAL  .........  UNUSABLE ;
ALTER INDEX INDEX_SPACE0_IX_LOCAL REBUILD PARTITION PARTITION INDEX_SPACE01;
ALTER INDEX INDEX_SPACE0_IX_LOCAL REBUILD PARTITION PARTITION INDEX_SPACE02;


create index tbcs.idx_subscr_subid_sn_reg on tbcs.subscriber(subsid,servnumber,region) online local parallel 8 invisible nologging;
ALTER SESSION SET OPTIMIZER_USE_INVISIBLE_INDEXES=TRUE;


SELECT    'alter index '
                 || index_owner
                 || '.'
                 || index_name
                 || ' rebuild partition  '
                 || partition_name
                 || '  online  parallel 8;'
                    sqls
            FROM dba_ind_partitions
           WHERE status NOT IN ('N/A', 'USABLE') order by 1;
		   
		   
		   
SELECT    'alter index '
                 || index_owner
                 || '.'
                 || index_name
                 || ' rebuild partition  '
                 || partition_name
                 || '   parallel 8;'
                    sqls
            FROM dba_ind_partitions
           WHERE status NOT IN ('N/A', 'USABLE') order by 1;	   
		   

DECLARE
     isClean BOOLEAN;
  BEGIN
       isClean := DBMS_REPAIR.ONLINE_INDEX_CLEAN(107059, DBMS_REPAIR.LOCK_WAIT);
  EXCEPTION
  WHEN OTHERS THEN
  RAISE;
  END;
  /
  
  
  
  
  