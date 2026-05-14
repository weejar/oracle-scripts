
CREATE TABLE dbmt.job_logs
(
   etype         VARCHAR2 (30),                                 -- info, error
   etime         DATE DEFAULT SYSDATE,
   esrc          VARCHAR2 (50),
   errcode       VARCHAR (30),
   owner         VARCHAR2 (30),
   msg           VARCHAR2 (300),
   instance_id   NUMBER (1)
);

COMMENT ON TABLE dbmt.job_logs IS 'jobs run log created by DBA';

/* Formatted on 2016-3-3 11:21:35 (QP5 v5.256.13226.35510) */
 CREATE OR REPLACE PROCEDURE "DBMT"."P_CLEAR_DISTRIBUTED_TX"
IS
   -- Clear Distributed Transactions
   -- date: 2016-3-3

   v_txid    VARCHAR (50);
   v_emeg    VARCHAR2 (200);
   v_ecode   VARCHAR2 (200);

   CURSOR c
   IS
      SELECT local_tran_id, HOST, fail_time,state
        FROM dba_2pc_pending t
       WHERE (SYSDATE - FAIL_TIME) * 24 * 60 > 10;
BEGIN
   FOR i IN c
   LOOP
   
     if i.state<>'forced rollback' then
      DBMS_TRANSACTION.rollback_force (i.local_tran_id);
      COMMIT;
	 end if;
	 
      DBMS_TRANSACTION.purge_lost_db_entry (i.local_tran_id);
      COMMIT;

      INSERT INTO dbmt.job_logs (etype,
                                 esrc,
                                 owner,
                                 msg,
                                 instance_id)
           VALUES ('info',
                   'p_clear_Distributed_tx',
                   'dbmt',
                   i.HOST || ' ' || i.fail_time || ' dtx cleared!',
                   SYS_CONTEXT ('USERENV', 'INSTANCE'));

      COMMIT;
   END LOOP;
EXCEPTION
   WHEN OTHERS
   THEN
      v_emeg := SUBSTR (SQLERRM, 1, 100);
      v_ecode := SQLCODE;

      INSERT INTO dbmt.job_logs (etype,
                                 esrc,
                                                                 owner,
                                 errcode,
                                 msg,
                                 instance_id)
           VALUES ('error',
                   'p_clear_Distributed_tx',
                   'dbmt',
                   v_ecode,
                   v_emeg,
                   SYS_CONTEXT ('USERENV', 'INSTANCE'));

      COMMIT;
END;
/

-- create job, run every 30 minutes, Note: login as dbmt user
VARIABLE jobno NUMBER;

BEGIN
   DBMS_JOB.SUBMIT ( :jobno,
                    'p_clear_Distributed_tx();',
                    SYSDATE,
                    'SYSDATE + (30/24/60)');
   COMMIT;
END;
/


# privs req
grant select on dba_2pc_pending to dbmt;
grant execute on sys.dbms_transaction to dbmt;
grant delete  on SYS.PENDING_TRANS$ to dbmt;
grant delete on SYS.PENDING_SESSIONS$ to dbmt;
grant delete on  SYS.PENDING_SUB_SESSIONS$ to dbmt;
grant FORCE ANY TRANSACTION to dbmt;


for i in(

SELECT KTUXEUSN,KTUXESLT,KTUXESQN,
KTUXESTA Status,KTUXECFL Flags
FROM x$ktuxe
WHERE ktuxesta!='INACTIVE';
)

ROLLBACK FORCE '73.11.124822'

if ORA-02058 then (

SELECT local_tran_id, global_tran_fmt, global_oracle_id,
   global_foreign_id, state, status, heuristic_dflt,
          session_vector, reco_vector,
        global_commit#
        FROM PENDING_TRANS$;
 )
 
UPDATE pending_trans$SET STATE='prepared',
STATUS='p'
WHERE local_tran_id='73.11.124822';
COMMIT;

ROLLBACK FORCE '73.11.124822';

if  ORA-01591 THEN

UPDATE pending_trans$ SET STATE='prepared',
STATUS='P'
where local_tran_id='73.11.124822';
commit；
commit force '73.11.124822';

将这个事务清理掉:
SQL>exec dbms_transaction.purge_lost_db_entry('108.28.46269')
然后手工插入相关记录:
SQL>alter system disable distributed recovery;
SQL> insert into pending_trans$ (
        LOCAL_TRAN_ID,
        GLOBAL_TRAN_FMT,
        GLOBAL_ORACLE_ID,
        STATE,
        STATUS,
        SESSION_VECTOR,
        RECO_VECTOR,
        TYPE#,
        FAIL_TIME,
        RECO_TIME)
    values('108.28.46269',
        306206,     
        'XXXXXXX.12345.1.2.3',
        'prepared','P',         
        hextoraw( '00000001' ),
        hextoraw( '00000000' ),
        0, sysdate, sysdate );

SQL>insert into pending_sessions$
    values( '108.28.46269',
        1, hextoraw('05004F003A1500000104'),
        'C', 0, 30258592, '',
        146
      );

SQL>Commit；

然后再次强制提交：
SQL>commit force '108.28.46249';
commit compelte.

