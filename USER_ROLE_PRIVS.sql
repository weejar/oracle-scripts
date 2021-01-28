–- ################################################
–- # Creator: Oracle Corp.
–- # Created: 2005/01/01
–- #
–- ################################################
–- #
–- # Compatible: 8i 9i 10g 11g
–- #
–- ################################################
–- #
-- # Lists the privileges and roles, regardless of 
-- # how the roles/privileges were granted;
-- # either directly or indirectly.
–- #
–- ################################################

SET ECHO off
REM  Name :LIST_USER_ROLE_PRIVS.sql
REM  ------------------------------
REM  Should be run as SYS
REM  ------------------------------
prompt Creating the procedure LIST_USER_ROLE_PRIVS
CREATE OR REPLACE PROCEDURE LIST_USER_ROLE_PRIVS(UNAME VARCHAR2)
IS
U1 VARCHAR2(100):=UNAME;

CURSOR one IS SELECT u1.name USERNAME ,U2.NAME ROLENAME ,SUBSTR(SPM.NAME,1,27) PRIVILEGE
FROM SYS.SYSAUTH$ SA1, SYS.SYSAUTH$ SA2,SYS.USER$ U1, SYS.USER$ U2,SYS.SYSTEM_PRIVILEGE_MAP SPM
WHERE SA1.GRANTEE# = U1.USER#
AND SA1.PRIVILEGE# = U2.USER#
AND U2.USER# = SA2.GRANTEE# (+)
AND SA2.PRIVILEGE# = SPM.PRIVILEGE (+) AND
(U1.NAME IN
  (SELECT GRANTEE FROM DBA_ROLE_PRIVS connect by prior
	  granted_role=GRANTEE start with GRANTEE IN
          (SELECT NAME FROM USER$ WHERE user# in 
                  (select privilege# from sysauth$ t1, user$ t2
                   where t1.grantee#=t2.user# and t2.name=U1)
	  )
   UNION
   SELECT GRANTED_ROLE FROM DBA_ROLE_PRIVS connect by prior
	  granted_role=GRANTEE start with GRANTEE IN 
          (SELECT NAME FROM USER$ WHERE user# in 
                  (select privilege# from sysauth$ t1, user$ t2
	           where t1.grantee#=t2.user# and t2.name=U1)
	  )
   )
 OR U1.NAME=U1
 )
ORDER BY U2.USER#, U2.NAME ;

CURSOR two IS select u.name username,spm.name privilege
  from user$ u, sysauth$ s, system_privilege_map spm
  where u.user#=s.grantee# and s.privilege#=spm.privilege
  AND   U.NAME=U1
  ORDER BY 1,2;

BEGIN
 dbms_output.put_line(rpad('USERNAME',30,' ')||rPAD('ROLENAME',21,' ')||rPAD('PRIVILEGE',21,' '));
 DBMS_OUTPUT.PUT_LINE('----------------------------- -------------------- --------------------');
 for y in one loop	
   dbms_output.put_line(rPAD(y.USERNAME,30,' ')||rPAD(y.ROLENAME,21,' ')||rPAD(y.PRIVILEGE,21,' '));
 end loop;
 for x in two loop
   dbms_output.put_line(rPAD(x.username,51,' ')||rPAD(x.privilege,21,' '));
 end loop;

END;
/

set verify off


prompt Enter user to probe (uname)
set serveroutput on size 1000000
begin
 SYS.LIST_USER_ROLE_PRIVS('&UNAME');
end;
/

undef username
set verify on                 

drop PROCEDURE LIST_USER_ROLE_PRIVS;
-- end script LIST_USER_ROLE_PRIVS.sql
