# create table and sequence
 
 CREATE TABLE "DBMT"."JOB_LOGS"
   (    "ID" NUMBER(*,0),
        "JOBNAME" VARCHAR2(100),
        "RUNTIME" DATE,
        "ERRCODE" NUMBER,
        "INFO" VARCHAR2(200)
   ) tablespace users;
   
create sequence dbmt.seq_job;

# privs

grant select on dba_indexes to dbmt;
grant select on dba_ind_partitions to dbmt;
grant select on dba_ind_subpartitions to dbmt;


# create procedure 
   
CREATE OR REPLACE PROCEDURE dbmt.P_index_rebuild
AUTHID CURRENT_USER 
IS
-- author: weejar(anbob.com)
-- date: 2017-4-21
-- puporse: rebuild indexes including partitioned
-- option: online 
   err_num NUMBER;
   err_msg VARCHAR2(100);
BEGIN
-- index nopart
   FOR i
      IN (SELECT    'alter index '
                 || owner
                 || '.'
                 || index_name
                 || ' rebuild online nologging'
                    sqls
            FROM dba_indexes
           WHERE status NOT IN ('VALID', 'N/A'))
   LOOP
      BEGIN
         DBMS_OUTPUT.put_line (i.sqls);


         EXECUTE IMMEDIATE i.sqls;
      EXCEPTION
         WHEN OTHERS
         THEN
            DBMS_OUTPUT.put_line (SQLERRM);
			err_num := SQLCODE;
            err_msg := SUBSTR(SQLERRM, 1, 100);
            insert into dbmt.job_logs(id,jobname,runtime,errcode,info) values(dbmt.seq_job.nextval,'P_INDEX_REBUILD',sysdate,err_num,err_msg);
		    commit;
      END;
   END LOOP;
-- partition
   FOR i
      IN (SELECT    'alter index '
                 || index_owner
                 || '.'
                 || index_name
                 || ' rebuild partition  '
                 || partition_name
                 || '  online nologging parallel 8'
                    sqls
            FROM dba_ind_partitions
           WHERE status NOT IN ('N/A', 'USABLE'))
   LOOP
      BEGIN
         DBMS_OUTPUT.put_line (i.sqls);

         EXECUTE IMMEDIATE i.sqls;
      EXCEPTION
         WHEN OTHERS
         THEN
		 -- write log
            DBMS_OUTPUT.put_line (SQLERRM);
			err_num := SQLCODE;
            err_msg := SUBSTR(SQLERRM, 1, 100);
            insert into dbmt.job_logs(id,jobname,runtime,errcode,info) values(dbmt.seq_job.nextval,'P_INDEX_REBUILD',sysdate,err_num,err_msg);
		    commit;
      END;
   END LOOP;

-- subpartition
   FOR i
      IN (SELECT    'alter index '
                 || index_owner
                 || '.'
                 || index_name
                 || ' rebuild subpartition '
                 || subpartition_name
                 || '  online'
                    sqls
            FROM dba_ind_subpartitions
           WHERE status NOT IN ('USABLE'))
   LOOP
      BEGIN
         DBMS_OUTPUT.put_line (i.sqls);

         EXECUTE IMMEDIATE i.sqls;
      EXCEPTION
         WHEN OTHERS
         THEN
		 -- write log 
            DBMS_OUTPUT.put_line (SQLERRM);
			err_num := SQLCODE;
            err_msg := SUBSTR(SQLERRM, 1, 100);
            insert into dbmt.job_logs(id,jobname,runtime,errcode,info) values(dbmt.seq_job.nextval,'P_INDEX_REBUILD',sysdate,err_num,err_msg);
		    commit;
      END;
   END LOOP;
END;
/  


-- create job  , run every 30 minutes
var jobno number;
BEGIN
DBMS_JOB.SUBMIT(:jobno,'dbmt.P_INDEX_REBUILD;',  
SYSDATE, 'SYSDATE +30/24/60');  
commit; 
END;
/