#!/bin/sh

# version: 1.2
# author: weejar.zhang(anbob.com)
# purpose: kill tx blocker session last call et large than 60s on local instance
# call: in crontab each db instance host
# * * * * * sh /home/oracle/killtxblk.sh >> /home/oracle/log/killtxblk.log 2>&1

LOGFILE=/home/oracle/log/killtxblk.log

# set env
if [ -f ~/.profile ]
then
. ~/.profile
fi

if [ -f ~/.bash_profile ]
then
. ~/.bash_profile
fi

# Check user is oracle
USERID=`/usr/bin/id -u -nr`
if [ $? -ne 0 ]
then
        echo "ERROR: unable to determine uid" >> $LOGFILE
        exit 99
fi
if [ "${USERID}" != "oracle" ]
then
        echo "ERROR: This script must be run as oracle" >> $LOGFILE
        exit 98
fi

unset SQLPATH



echo " " >> $LOGFILE 2>&1
echo "START ----`date`" >> $LOGFILE 2>&1
echo "Detail log check $LOGFILE"
$ORACLE_HOME/bin/sqlplus /nolog <<EOF>>$LOGFILE
connect / as sysdba

set serveroutput on
set feedback off
set linesize 300

declare
blockcount number;
sqlreport varchar(3000);
sqloutput varchar(5000);
v_rec varchar(3000);
v_sql varchar(2000);

cursor blk_curs is select s.USERNAME BUSER,s.SID BSID,s.SERIAL# BSERIAL,s.STATUS BSTAT,s.program,s.LAST_CALL_ET BLAST  from dba_waiters w,v\$session s where w.lock_type='Transaction'  and W.HOLDING_SESSION=s.SID
 and s.username not in ('SYSTEM','DBSNMP','RMAN') 
 and s.last_call_et>=60;
begin
DBMS_OUTPUT.put_line('Checking for blocking sessions on this database');
DBMS_OUTPUT.put_line('-----------------------------------------------');
select count(*) into blockcount from  dba_blockers;
IF blockcount > 0 THEN
DBMS_OUTPUT.put_line('Found blocking sessions -> Fetching report for the same');
DBMS_OUTPUT.put_line('-------------------------------------------------------');
for v_rec in blk_curs LOOP
dbms_output.put_line('Blocker: ('||v_rec.BUSER ||' program'||v_rec.program||' ('||v_rec.BSID||','||v_rec.BSERIAL||') is Currently '||v_rec.BSTAT||' for last '||v_rec.BLAST||' Sec '||')');
end loop;
DBMS_OUTPUT.put_line('-');
DBMS_OUTPUT.put_line('-');
DBMS_OUTPUT.put_line('Further details on blocking sessions -> includes kill script of blocking session');
DBMS_OUTPUT.put_line('--------------------------------------------------------------------------------');
for v_rec in blk_curs LOOP
    BEGIN
v_sql:='alter system kill session '''
            || v_rec.BSID
            || ', '
            || v_rec.BSERIAL
            || '''immediate';
DBMS_OUTPUT.put_line(v_sql);	
-- execution kill
execute immediate v_sql;
	EXCEPTION
         WHEN OTHERS
         THEN
            DBMS_OUTPUT.PUT_LINE (SQLCODE);
    END;
end loop;
DBMS_OUTPUT.put_line('-');
DBMS_OUTPUT.put_line('-');
ELSE
DBMS_OUTPUT.put_line('-');
DBMS_OUTPUT.put_line('-');
DBMS_OUTPUT.put_line('Hurrey !!! No blocking sessions found');
DBMS_OUTPUT.put_line('-');
DBMS_OUTPUT.put_line('-');
END IF;

EXCEPTION
   WHEN OTHERS
   THEN
      DBMS_OUTPUT.PUT_LINE (SQLCODE);
	  
END;
/
EOF
echo "END ------`date`" >> $LOGFILE 2>&1


