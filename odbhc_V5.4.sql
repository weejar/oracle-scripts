prompt 
prompt +------------------------------------------------------------------------------+
prompt |                         ORACLE Database Health Check                         |
prompt |------------------------------------------------------------------------------+
prompt | Copyright (c) 2017-2022 Weejar Zhang (weejar@gmail.com). All rights reserved.|
prompt |Purpose:                                                                      |
prompt |Creating database health check report.                                        |
prompt |Usage:  sqlplus / as sysdba   SQL>@odbhc.sql                                  |                
prompt |Note:                                                                         |
prompt | This script must be run as a user with SYSDBA privileges.                     |
prompt | If there is a command "not found error", it can be safely ignored            |
prompt | The v$session.module is 'odbhc' , you can check Which SQL is runing now.	   |
prompt | This process can take several minutes to complete.please waiting ...          |
prompt +------------------------------------------------------------------------------+


whenever sqlerror exit sql.sqlcode;
declare
issysdba varchar2(10);
begin
select sys_context('userenv','ISDBA') into issysdba from dual;
if issysdba!='TRUE' then
 raise_application_error(-20100,'This script must be run as a user with SYSDBA privileges.');
end if;
end;
/
host echo Seting modeul...
BEGIN
  DBMS_APPLICATION_INFO.set_module(module_name => 'odbhc',
                                   action_name => 'DB health checking');
END;
/
clear buffer computes columns breaks

set termout       off
set echo          off
set feedback      off
set heading       off
set verify        off
set wrap          on
set trimspool     on
set serveroutput  on
set escape        on

whenever sqlerror continue;

set pagesize 50000
set linesize 175
set long     2000000000

clear buffer computes columns breaks

define reportHeader="<font size=+2 color=#d33><b>Oracle Database Health Check Report</b></font><hr>"
define reportfooter="<hr> <center>Copyright (c) 2017-2022 Weejar Zhang(weejar@gmail.com). All rights reserved. (<a target=""_blank"" href=""http://anbob.com"">www.anbob.com</a>)</center>"
define fileName=oracle_database_hc_report
define versionNumber=5.4

COLUMN tdate NEW_VALUE _date NOPRINT
SELECT TO_CHAR(SYSDATE,'MM/DD/YYYY') tdate FROM dual;

COLUMN time NEW_VALUE _time NOPRINT
SELECT TO_CHAR(SYSDATE,'HH24:MI:SS') time FROM dual;

COLUMN date_time NEW_VALUE _date_time NOPRINT
SELECT TO_CHAR(SYSDATE,'MM/DD/YYYY HH24:MI:SS') date_time FROM dual;

COLUMN date_time_timezone NEW_VALUE _date_time_timezone NOPRINT
SELECT TO_CHAR(systimestamp, 'Mon DD, YYYY (') || TRIM(TO_CHAR(systimestamp, 'Day')) || TO_CHAR(systimestamp, ') "at" HH:MI:SS AM') || TO_CHAR(systimestamp, ' "in Timezone" TZR') date_time_timezone
FROM dual;

COLUMN spool_time NEW_VALUE _spool_time NOPRINT
SELECT TO_CHAR(SYSDATE,'YYYYMMDD') spool_time FROM dual;

COLUMN dbname# NEW_VALUE _dbname NOPRINT
SELECT name dbname# FROM v$database;

COLUMN dbid NEW_VALUE _dbid NOPRINT
SELECT dbid dbid FROM v$database;

COLUMN platform_id NEW_VALUE _platform_id NOPRINT
SELECT platform_id platform_id FROM v$database;

COLUMN platform_name NEW_VALUE _platform_name NOPRINT
COLUMN database_role NEW_VALUE _db_role NOPRINT
column log_mode new_value _log_mode noprint
column force_logging new_value _force_logging noprint
column flashback_on new_value _flashback_on
SELECT platform_name platform_name,database_role,LOG_MODE,FORCE_LOGGING,FLASHBACK_ON  FROM v$database;

column headroom new_value _headroom noprint
select
   ((((
    ((to_number(to_char(sysdate,'YYYY'))-1988)*12*31*24*60*60) +
    ((to_number(to_char(sysdate,'MM'))-1)*31*24*60*60) +
    (((to_number(to_char(sysdate,'DD'))-1))*24*60*60) +
    (to_number(to_char(sysdate,'HH24'))*60*60) +
    (to_number(to_char(sysdate,'MI'))*60) +
    (to_number(to_char(sysdate,'SS')))
    ) * (16*1024)) - current_scn)
   / (16*1024*60*60*24)
   ) headroom
from v$database;


COLUMN global_name NEW_VALUE _global_name NOPRINT
SELECT global_name global_name FROM global_name;

COLUMN blocksize NEW_VALUE _blocksize NOPRINT
SELECT value blocksize FROM v$parameter WHERE name='db_block_size';

COLUMN startup_time NEW_VALUE _startup_time NOPRINT
SELECT TO_CHAR(startup_time, 'MM/DD/YYYY HH24:MI:SS') startup_time FROM v$instance;

COLUMN host_name NEW_VALUE _host_name NOPRINT
SELECT host_name host_name FROM v$instance;

COLUMN instance_name NEW_VALUE _instance_name NOPRINT
SELECT instance_name instance_name FROM v$instance;

COLUMN instance_number NEW_VALUE _instance_number NOPRINT
SELECT instance_number instance_number FROM v$instance;

COLUMN thread_number NEW_VALUE _thread_number NOPRINT
COLUMN db_version NEW_VALUE _version NOPRINT
SELECT thread# thread_number,version db_version FROM v$instance;

COLUMN cluster_database NEW_VALUE _cluster_database NOPRINT
SELECT value cluster_database FROM v$parameter WHERE name='cluster_database';

COLUMN cluster_database_instances NEW_VALUE _cluster_database_instances NOPRINT
SELECT value cluster_database_instances FROM v$parameter WHERE name='cluster_database_instances';

COLUMN PFILENAME NEW_VALUE _Pfile NOPRINT
select listagg(i.instance_name||': '||nvl2(name,'SPFILE','PFILE')||'<br />') within group(order by p.inst_id) PFILENAME from gv$parameter p, gv$instance i where p.name = 'spfile' and p.inst_id = i.instance_number;

COLUMN CDB NEW_VALUE _Multitenant NOPRINT
SELECT CDB FROM V$DATABASE;

COLUMN Storagetype NEW_VALUE _Storagetype NOPRINT
select listagg(storage||',')  Storagetype from (select case when type like '/dev%' then 'Raw Device' when type like  '+%' then 'ASM' else 'File System' end Storage  from (select  distinct substr(name,1,4)   Type from v$datafile ));


COLUMN reportRunUser NEW_VALUE _reportRunUser NOPRINT
SELECT user reportRunUser FROM dual;

COLUMN run_during_begin NEW_VALUE _run_during_begin NOPRINT
--SELECT round((sysdate-to_date('&_date_time','MM/DD/YYYY HH24:MI:SS'))*24*3600,2) report_during FROM dual;
select dbms_utility.get_time run_during_begin from dual;


DEF processor_model = 'Unknown';
COL processor_model NEW_V processor_model
HOS echo '' >  cpuinfo.sql
HOS cat /proc/cpuinfo | grep -i name | sort | uniq >> cpuinfo.sql
GET cpuinfo.sql
A ' processor_model FROM DUAL;
0 SELECT '
/
SELECT REPLACE(REPLACE(REPLACE(REPLACE('&&processor_model.', CHR(9)), CHR(10)), ':'), 'model name ') processor_model FROM DUAL;

-- +----------------------------------------------------------------------------+
-- |                   GATHER DATABASE REPORT INFORMATION                       |
-- +----------------------------------------------------------------------------+

set heading on

set markup html on spool on preformat off entmap on -
head ' -
  <title>Database Report</title> -
  <style type="text/css"> -
	body {font:bold 10pt Arial,Helvetica,Geneva,sans-serif; color:black;	background-color: #fff;} -
	a    {color: #c75f3e;font:9pt Arial,Helvetica,sans-serif; color:#663300; margin-top:0pt; margin-bottom:0pt; vertical-align:top;} -
	h2 {color:#336699;} -
    table {	border-collapse: collapse;	text-align: left;} -
	#mytable {width: 700px;	padding: 0;	margin: 0;} -
	.kmnotebox {width: 700px;background-color: papayawhip;border: 1px solid#c1a90d;} -
    caption {padding: 0 0 5px 0;width: 700px;font: italic 10px "Trebuchet MS", Verdana, Arial, Helvetica, sans-serif;text-align: right;} -
    th {font: bold 8pt Arial,Helvetica,Geneva,sans-serif;    color: White;    background: #0066CC;    padding-left: 4px;    padding-right: 4px;    padding-bottom: 2px;display: table-cell;    vertical-align: inherit;    font-weight: bold;    text-align: -internal-center;} -
    th.nobg {	border-top: 0;	border-left: 0;	border-right: 1px solid #C1DAD7;	background: none;} -
    td {border-right: 1px solid #C1DAD7;border-bottom: 1px solid #C1DAD7;padding: 6px 6px 6px 12px;color: #4f6b72;font-size: 11px; background: none;} -
    td.alt {background: #fff;color: #797268;font-size: 11px;} -
    th.spec {border-left: 1px solid #C1DAD7;border-top: 0;background: #fff url(images/bullet1.gif) no-repeat;font: bold "Trebuchet MS", Verdana, Arial, Helvetica, sans-serif;font-size: 10px;} -
    th.specalt {border-left: 1px solid #C1DAD7;	border-top: 0;background: #f5fafa url(images/bullet2.gif) no-repeat;font: bold 10px "Trebuchet MS", Verdana, Arial, Helvetica, sans-serif;	color: #797268;} -
	tr:nth-child(even) {background: #fff} -
	tr:nth-child(odd) {background: #FFFFCC} -
 </style>' -
table  'WIDTH="90%" BORDER="1"' 

spool &FileName._&_dbname._&_spool_time..html

set markup html on entmap off

prompt &reportHeader
prompt <a name="top"></a>
prompt <a name="report_header"></a>


-- +----------------------------------------------------------------------------+
-- |                            - REPORT HEADER -                               |
-- +----------------------------------------------------------------------------+

prompt <table id="mytable" cellspacing="0" summary="it's the report header profile"> -
<caption>report &_dbname </caption>-
<tr><th scope="col" >Report Name</th><td class="nobg"><tt>&FileName._&_dbname._&_spool_time..html</tt></td></tr> -
<tr><th scope="col" >ODBHC Version</th><td class="alt"><tt>&versionNumber</tt></td></tr> -
<tr><th scope="col" >Run Date / Time / Timezone</th><td class="nobg"><tt>&_date_time_timezone</tt></td></tr> -
<tr><th scope="col" >Host Name</th><td class="alt"><tt>&_host_name</tt></td></tr> -
<tr><th scope="col" >Processor</th><td class="nobg"><tt>&&processor_model</tt></td></tr> -
<tr><th scope="col" >Database Name</th><td class="alt"><tt>&_dbname</tt></td></tr> -
<tr><th scope="col" >Database Version</th><td class="nobg"><tt>&_version</tt></td></tr> -
<tr><th scope="col" >Database Role</th><td class="alt"><tt>&_db_role</tt></td></tr> -
<tr><th scope="col" >Database ID</th><td class="nobg"><tt>&_dbid</tt></td></tr> -
<tr><th scope="col" >Global Database Name</th><td class="alt"><tt>&_global_name</tt></td></tr> -
<tr><th scope="col" >Storage Type(File System/Raw Decice/ASM)</th><td class="nobg"><tt>&_Storagetype</tt></td></tr> -
<tr><th scope="col" >Multitenant</th><td class="alt"><tt>&_Multitenant</tt></td></tr> -
<tr><th scope="col" >SPFILE/PFILE</th><td class="nobg"><tt>&_Pfile</tt></td></tr> -
<tr><th scope="col" >Clustered Database?</th><td class="alt"><tt>&_cluster_database</tt></td></tr> -
<tr><th scope="col" >Clustered Database Instances</th><td class="nobg"><tt>&_cluster_database_instances</tt></td></tr> -
<tr><th scope="col" >LOG_MODE</th><td class="alt"><tt>&_log_mode</tt></td></tr> -
<tr><th scope="col" >Force Logging?</th><td class="nobg"><tt>&_force_logging</tt></td></tr> -
<tr><th scope="col" >FLASHBACK ON?</th><td class="alt"><tt>&_flashback_on</tt></td></tr> -
<tr><th scope="col" >Current Instance</th><td class="nobg"><tt>&_instance_name</tt></td></tr> -
<tr><th scope="col" >Instance Number</th><td class="alt"><tt>&_instance_number</tt></td></tr> -
<tr><th scope="col" >Thread Number</th><td class="nobg"><tt>&_thread_number</tt></td></tr> -
<tr><th scope="col" >Database Startup Time</th><td class="alt"><tt>&_startup_time</tt></td></tr> -
<tr><th scope="col" >Database Block Size</th><td class="nobg"><tt>&_blocksize</tt></td></tr> -
<tr><th scope="col" >SCN Headroom</th><td class="alt"><tt>&_headroom</tt></td></tr> -
<tr><th scope="col" >Report Run User</th><td class="nobg"><tt>&_reportRunUser</tt></td></tr> -
<tr><th scope="col" >Toltal during of the run(s)</th><td class="alt"><tt>_tmp_run_during</tt></td></tr> -
<tr><th scope="col" >Platform Name / ID</th><td class="nobg"><tt>&_platform_name / &_platform_id</tt></td></tr> -
</table>

prompt Tip:  -         
prompt* If SCN Headroom <60 means the SCN health is low,For further information review MOS document id 1393363.1

prompt <table width="90%" border="1"> -
 <tr><th colspan="4">Database and Instance Information</th></tr> -
<tr> -
<td nowrap align="center" width="25%"><a class="link" href="#report_header">Report Header</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#Instance">Instance</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#database">Database</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#OS">Host</a></td> -
</tr> -
<tr> -
<td nowrap align="center" width="25%"><a class="link" href="#start_hist">Instance Start Hist</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#pdb">Plaggable Database</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#Patches">Patches</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#Option">Option</a></td> -
</tr> -
<tr> -
<td nowrap align="center" width="25%"><a class="link" href="#feature_usage_statistics">Feature Usage Statistics</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#high_water_mark_statistics">High Water Mark Statistics</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#AAS">AAS</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#resource_limit">Resource Limit</a></td> -
</tr>  -
<tr> -
<td nowrap align="center" width="25%"><a class="link" href="#session">Session Overview</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#bgprocess">Background process</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#LMS_process">LMS process</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#connection">Connections TimeLine</a></td> -
</tr> -
<tr> -
<td nowrap align="center" width="25%"><a class="link" href="#DBParameter">Initialization Parameters</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#Controlfile">Control Files</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#Redo">Online Redo Logs</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#Archivelog">Archivelog</a></td> -
</tr> -
<tr><th colspan="4">Storage</th></tr> -
<tr> -
<td nowrap align="center" width="25%"><a class="link" href="#Tablespace">Tablespace</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#pdb_tablespace">PDB Tablespace</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#Temporary">Temporary</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#UNDO">UNDO</a></td> -
</tr> -
<tr> -
<td nowrap align="center" width="25%"><a class="link" href="#dbfile">Datafiles And Tempfiles</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#Fragmentation">Fragmentation</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#Recovery_file">Recovery Files</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#CORRUPTION">CORRUPTION</a></td> -
</tr> -
<tr> -
<td nowrap align="center" width="25%"><a class="link" href="#statistics_level">Statistics Level</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#parallel">Parallel</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#EVENT_ENABLED">EVENT_ENABLED</a></td> -
<td nowrap align="center" width="25%"></td> -
</tr> -
<tr><th colspan="4">ASM</th></tr> -
<tr> -
<td nowrap align="center" width="25%"><a class="link" href="#ASMDG">ASM DISKGROUP</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#ASMDISK">ASM DISK</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#ASMattr">ASM Attribute</a></td> -
<td nowrap align="center" width="25%"></td> -
</tr> -
<tr><th colspan="4">Scheduler / Jobs</th></tr> -
<tr> -
<td nowrap align="center" width="25%"><a class="link" href="#JOBS">JOBS</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#JOBS">Schedulers</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#TASK">AUTOTASK</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#task_hist">Auto TASK HISTORY</a></td> -
</tr> -
<tr><th colspan="4">User / Schemas</th></tr> -
<tr> -
<td nowrap align="center" width="25%"><a class="link" href="#users">users</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#user_profile">user_profile</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#lockdown">lockdown</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#schema">schema</a></td> -
</tr>  

prompt -
<tr><th colspan="4">Objects</th></tr> -
<tr> -
<td nowrap align="center" width="25%"><a class="link" href="#object_summary">Object Summary</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#dblink">Database Link</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#invalidobj">Invalid Objects</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#tab_diff_index">Table and INDEX diff Owner</a></td> -
</tr> -
<tr> -
<td nowrap align="center" width="25%"><a class="link" href="#empty_tab">STALE STATS Table 0 Rows</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#Largest_Object">Top 10 Segments (by size) in DB</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#largest_systbs">Top 10 Segments (by size) in SYSTEM/SYSAUX</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#obj_in_systbs">Object in SYSTEM/SYSAUX</a></td> -
</tr> -
<tr> -
<td nowrap align="center" width="25%"><a class="link" href="#nopartition">Large table Nopartition</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#toomany_partition">Toomany partition</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#toomany_index">Toomany_index</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#bitmap_index">Bitmap index</a></td> -
</tr> -
<tr> -
<td nowrap align="center" width="25%"><a class="link" href="#FK_without_index">FK without index</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#latest_mod">Object Modified in last 3 days</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#latest_mod_more10">Object Modified Percent more than 10%</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#top_10_segments_by_extents">Top 10 Segments (by number of extents)</a></td> -
</tr> -
<tr> -
<td nowrap align="center" width="25%"><a class="link" href="#dba_types">Types</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#dba_directories">Directories</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#dba_lob_segments">LOB Segments</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#obj_lvl">Index With High Blevel or Degree</a></td> -
</tr> -
<tr> -
<td nowrap align="center" width="25%"><a class="link" href="#objects_unable_to_extend">Objects Unable to Extend</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#objects_which_are_nearing_maxextents">Objects Which Are Nearing MAXEXTENTS</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#users_with_default_tablespace_defined_as_system">Users With Default Tablespace - (SYSTEM)</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#users_with_default_temporary_tablespace_as_system">Users With Default Temp Tablespace - (SYSTEM)</a></td> -
</tr>  


prompt -
<tr><th colspan="4">Backups / Flashback</th></tr> -
<tr> -
<td nowrap align="center" width="25%"><a class="link" href="#RMAN">RMAN Config</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#rmandetail">RMAN Detail</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#arcivelog_nodelete">Archiving No delete</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#archive_destinations">Archive Destinations</a></td> -
</tr> -
<tr> -
<td nowrap align="center" width="25%"><a class="link" href="#flash_recovery_area_parameters">Flash Recovery Area Parameters</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#flash_recovery_area_status">Flash Recovery Area Status</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#flashback_database_parameters">Flashback Database Parameters</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#recyclebin">Recycle Bin</a></td> -
</tr> -
<tr><th colspan="4">Automatic Workload Repository - (AWR)</th></tr> -
<tr> -
<td nowrap align="center" width="25%"><a class="link" href="#awr">AWR config</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#awrgap">AWR Snapshot Gap</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#awr_baselines">AWR Baselines</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#"></a></td> -
</tr>  -
<tr><th colspan="4">Memory</th></tr> -
<tr> -
<td nowrap align="center" width="25%"><a class="link" href="#Memory_summary">Memory_summary</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#ASMM">ASMM</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#SGA">SGA</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#PGA">PGA</a></td> -
</tr> - 
<tr> -
<td nowrap align="center" width="25%"><a class="link" href="#SHAREDPOOL">SHAREDPOOL</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#ROWCACHE">ROWCACHE</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#Librarycache">Librarycache</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#inmemory">Inmemory</a></td> -
</tr> -
<tr><th colspan="4">Transaction</th></tr> -
<tr> -
<td nowrap align="center" width="25%"><a class="link" href="#Roll_Transaction">Roll_Transaction</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#Active_Transaction">Active_Transaction</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#2pc_tx">2PC Dtrans</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#latch">Latch</a></td> -
</tr> -
<tr><th colspan="4">Multitenant</th></tr> -
<td nowrap align="center" width="25%"><a class="link" href="#pdb">Plaggable Database</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#Multitenant">Multitenant</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#resource_plan">resource_plan</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#Optimizer">Optimizer</a></td> -
</tr> -
<tr><th colspan="4">Security</th></tr> -
<tr> -
<td nowrap align="center" width="25%"><a class="link" href="#Bitcoin">Bitcoin</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#dba_role_user">Users With DBA Privileges</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#sys_trigger">LOGON Triggers</a></td> -
<td nowrap align="center" width="25%"><a class="link" href=""></a></td> -
</tr>- 
<tr> -
<td nowrap align="center" width="25%"><a class="link" href="#SCN">SCN </a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#SCN_self">SCN self Growth</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#scn_params">SCN parameters</a></td> -
<td nowrap align="center" width="25%"><a class="link" href=""></a></td> -
</tr>

prompt -
<tr><th colspan="4">RAC</th></tr> -
<tr> -
<td nowrap align="center" width="25%"><a class="link" href="#RAC">RAC</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#pub_Network">pub_Network</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#pri_Network">pri_Network</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#interconnect_traffic">Interconnect Traffic</a></td> -
</tr>- 
<tr> -
<td nowrap align="center" width="25%"><a class="link" href="#gc_lost">GC block lost</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#GES">GES</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#GCS">GCS</a></td> -
<td nowrap align="center" width="25%"><a class="link" href=""></a></td> -
</tr> -
<tr><th colspan="4">DataGuard</th></tr> -
<tr> -
<td nowrap align="center" width="25%"><a class="link" href="#dataguard">Dataguard Parameter </a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#dggap">Dataguard GAP</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#dgstat">Dataguard Stat</a></td> -
<td nowrap align="center" width="25%"><a class="link" href=""></a></td> -
</tr>-
<tr><th colspan="4">Performance</th></tr> -
<tr> -
<td nowrap align="center" width="25%"><a class="link" href="#Performance">Performance Summary</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#Event">Top Event</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#enq_3day">Last 3 days ENQ Event</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#wait_chains">Wait chains</a></td> -
</tr> -
<tr> -
<td nowrap align="center" width="25%"><a class="link" href="#top_sql">Top SQL Elapsed Time</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#nobind_sql">TOP No bind sql</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#high_version">TOP High version</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#full_scan">TOP Table Full scan SQL</a></td> -
</tr> -
<tr> -
<td nowrap align="center" width="25%"><a class="link" href="#dyn_sample">TOP dyn sample SQL</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#many_plan_sql">TOP many plan SQL</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#sql_statements_with_most_disk_reads">SQL Statements With Most Disk Reads</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#log_wait">Log wait</a></td> -
</tr> -
<tr> - 
<td nowrap align="center" width="25%"><a class="link" href="#sorts">Sorts</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#dba_outlines">Outlines</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#dba_sql_profiles">SQL Profile</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#dba_sql_profiles">SQL Patches</a></td> -
</tr> -
<tr> -
<td nowrap align="center" width="25%"><a class="link" href="#wait_class">Wait class</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#TIME_MODE_3"> Last 3 days Time mode </a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#tg_load_profile">Last 7 days Load Profile</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#iowait3">Last 3 days IO event</a></td> -
</tr>-
<tr><th colspan="4">Online Analytical Processing - (OLAP)</th></tr> -
<tr> -
<td nowrap align="center" width="25%"><a class="link" href="#dba_olap_materialized_views">Materialized Views</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#dba_olap_materialized_view_logs">Materialized View Logs</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#dba_olap_materialized_view_refresh_groups">Materialized View Refresh Groups</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#"></a></td> -
</tr>
prompt -
<tr><th colspan="4">Data Pump</th></tr> -
<tr> -
<td nowrap align="center" width="25%"><a class="link" href="#dba_directories">Directories</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#DBParameter_for_datapump">Parameter Affect Datapump</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#"></a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#"></a></td> -
</tr>-
<tr><th colspan="4">OS</th></tr> -
<tr> -
<td nowrap align="center" width="25%"><a class="link" href="#Incident">DB Incident</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#IO">IOSTAT</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#SAR">SAR</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#VMSTAT">VMSTAT</a></td> -
</tr> -
<tr> -
<td nowrap align="center" width="25%"><a class="link" href="#MEMINFO">Memory</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#CPUINFO">CPU</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#FS">FileSystem</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#HOSTS">Hosts File</a></td> -
</tr> -
<tr> -
<td nowrap align="center" width="25%"><a class="link" href="#ULIMIT">oracle ulimit</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#SYSCTL">Kernel setting</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#SWAP">SWAP</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="#CRONTAB">Crontab</a></td> -
</tr> -
<tr> -
<td nowrap align="center" width="25%"><a class="link" href="#NETSTAT">NETSTAT</a></td> -
<td nowrap align="center" width="25%"><a class="link" href="# ">   </a></td> -
<td nowrap align="center" width="25%"><a class="link" href="# "> </a></td> -
<td nowrap align="center" width="25%"><a class="link" href="# "> </a></td> -
</tr> -
</table>


host echo Check Instance info...
prompt <a name="Instance"></a>
prompt <font size="+2" face="Arial,Helvetica,Geneva,sans-serif" color="#336699"><b>Instance Overview</b></font>

Select (SELECT NAME FROM V$DATABASE) ||'_Oracle_Database_Health_Report: '||to_char(sysdate,'Mon dd yyyy hh24:mi:ss') "TIMESTAMP" from dual;
 
col "HOST_ADDRESS" FORMAT a15;
col RESETLOGS_TIME FORMAT a13;
col "DB RAC?" FORMAT A8;
col days format 9999;

select instance_name INSTANCE,HOST_NAME  "Host name", UTL_INADDR.GET_HOST_ADDRESS(host_name) "HOST_ADDRESS",
 LOGINS, archiver,to_char(STARTUP_TIME,'DD-MON-YYYY HH24:MI:SS') "DB_UP_TIME", RESETLOGS_TIME "RESET_TIME", FLOOR(sysdate-startup_time) days, 
 (select DECODE(vp1.value,'TRUE','Yes ('|| decode(vp1.value,'TRUE',' instances: '||vp2.value)||')','No')
 from v$instance,
 (select value from v$parameter 
  where name like 'cluster_database'
 ) vp1,
 (select value from v$parameter 
  where name like 'cluster_database_instances'
 ) vp2) "DB RAC?"
  from v$database,gv$instance;
 
select * from gv$instance order by inst_id;
 
prompt <a name="database"></a>
prompt <font size="+2" face="Arial,Helvetica,Geneva,sans-serif" color="#336699"><b>Database Overview</b></font>

host echo Check database info ...

clear columns breaks computes

select dbid,
       name,
       db_unique_name,
       created,
       log_mode,
       open_mode,
       protection_mode,
       database_role,
       force_logging,
       platform_name,
       flashback_on,
       cdb,
       dbtimezone
  from v$database;
  
host echo Check host info...
prompt
prompt <a name="OS"></a>
prompt <font size="+2" face="Arial,Helvetica,Geneva,sans-serif" color="#336699"><b>Host Overview</b></font>
COLUMN instance_name print
COLUMN instance_number print
COLUMN host_name   PRINT

column instance_name   format a15        heading 'Instance'
column host_name       format a25        heading 'Host Name'
column platform_name   format a35       
column cpus            format 9,999      heading 'CPUs'
column physical_memory format 999,990.99 heading 'Memory(GB)'

select i.instance_name  ,
       i.host_name  ,
       d.platform_name  ,
       o1.cpus,
       round(o2.physical_memory/1024/1024/1024,2) physical_memory
  from gv$instance i,
  (select platform_name from v$database) d,
  (select inst_id,value cpus from gv$osstat where osstat_id=0) o1,
  (select inst_id,value physical_memory from gv$osstat where osstat_id=1008) o2
 where i.inst_id = o1.inst_id and o1.inst_id = o2.inst_id
 order by 1;
 
SELECT 
NUM_CPU_SOCKETS,NUM_CPU_CORES,NUM_CPUS,LOAD,ROUND(PHYSICAL_MEMORY_BYTES/1024/1024/1024,2) "Memory(Gb)",
(1 - ROUND (busy_time / (busy_time + IDLE_TIME), 3)) * 100 "%idel",
       ROUND (USER_TIME / (busy_time + IDLE_TIME), 3) * 100 "%user",
       ROUND (SYS_TIME / (busy_time + IDLE_TIME), 3) * 100 "%sys",
       ROUND (IOWAIT_TIME / (busy_time + IDLE_TIME), 3) * 100 "%WIO"
  FROM (SELECT MAX (DECODE (stat_name, 'BUSY_TIME', VALUE, 0)) busy_time,
               MAX (DECODE (stat_name, 'IDLE_TIME', VALUE, 0)) IDLE_TIME,
               MAX (DECODE (stat_name, 'USER_TIME', VALUE, 0)) USER_TIME,
               MAX (DECODE (stat_name, 'SYS_TIME', VALUE, 0)) SYS_TIME,
               MAX (DECODE (stat_name, 'IOWAIT_TIME', VALUE, 0)) IOWAIT_TIME,
               MAX (DECODE (stat_name, 'NUM_CPUS', VALUE, 0)) NUM_CPUS,
			   MAX (DECODE (stat_name, 'NUM_CPU_SOCKETS', VALUE, 0)) NUM_CPU_SOCKETS,
			   MAX (DECODE (stat_name, 'NUM_CPU_CORES', VALUE, 0)) NUM_CPU_CORES,
               MAX (DECODE (stat_name, 'LOAD', VALUE, 0)) LOAD,
               MAX (DECODE (stat_name, 'PHYSICAL_MEMORY_BYTES', VALUE, 0)) PHYSICAL_MEMORY_BYTES
          FROM v$osstat
         WHERE osstat_id in (0,1,2,3,4,5,15,16,17,1008));

host echo Check Instance Startup History...
prompt <a name="start_hist"></a>
prompt <font size="+2" face="Arial,Helvetica,Geneva,sans-serif" color="#336699"><b>Instance Startup History Detail</b></font>
select INSTANCE_NUMBER,to_char(STARTUP_TIME,'yyyymmdd hh24:mi:ss') st,VERSION,DB_NAME,INSTANCE_NAME,HOST_NAME,PLATFORM_NAME,EDITION,DATABASE_ROLE from dba_hist_database_instance order by 1,2;


col name for a8
col open_time for a33
select con_id,name,dbid,open_mode,open_time,floor(sysdate-cast(open_time as date))||'Days '||floor(((sysdate-cast(open_time as date))-floor(sysdate-cast(open_time as date)))*24)||'hours '||round(((sysdate-cast(open_time as date)-floor(sysdate-cast(open_time as date) )*24)-floor((sysdate-cast(open_time as date)-floor(sysdate-cast(open_time as date))*24)))*60)||'minutes' "Database Uptime" from v$containers;


host echo Check Pluggable Database info...
prompt <a name="pdb"></a>
prompt  Pluggable Database 
col application_root heading "app_root"
col application_pdb  heading "app_pdb"
col application_seed heading "app_seed"
col proxy_pdb        heading "proxy_pdb"
col application_clone heading "app_clone"
select p1.con_id,
       p1.name,
       p1.open_mode,
       p1.restricted,
       p1.total_size,
       p1.block_size,
       p1.application_root ,
       p1.application_pdb ,
       p1.application_seed ,
       p1.proxy_pdb,
       p2.application_clone,
       p2.refresh_mode,
       p2.refresh_interval,
       local_undo,
       max_size
  from v$pdbs p1, cdb_pdbs p2
 where p1.con_id = p2.con_id;
 
prompt  Pluggable Database  Save States
 --DBA_PDB_SAVED_STATES
 select * from cdb_pdb_saved_states order by 1;  
 
prompt
host echo Check DB AAS info...
prompt <a name="AAS"></a>
prompt
prompt AAS of last 30days 

col "00-01_ " for 90.99
col "01-02_ " for 90.99
col "02-03_ " for 90.99
col "03-04_ " for 90.99
col "04-05_ " for 90.99
col "05-06_ " for 90.99
col "06-07_ " for 90.99
col "07-08_ " for 90.99
col "08-09_ " for 90.99
col "09-10_ " for 90.99
col "10-11_ " for 90.99
col "11-12_ " for 90.99
col "12-13_ " for 90.99
col "13-14_ " for 90.99
col "14-15_ " for 90.99
col "15-16_ " for 90.99
col "16-17_ " for 90.99
col "17-18_ " for 90.99
col "18-19_ " for 90.99
col "19-20_ " for 90.99
col "20-21_ " for 90.99
col "21-22_ " for 90.99
col "22-23_ " for 90.99
col "23-24_ " for 90.99
 
 
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
select instance_number,b_day,b_hour ,sum(sec)/sum(elapsed) aas
from 
(select sn.inst,stm.instance_number,(stme.value-stm.value)/1000000 sec,sn.b_day,sn.b_hour,sn.elapsed
FROM dba_hist_sys_time_model stm,dba_hist_sys_time_model stme,subq_snaps sn
      WHERE
      stm.dbid=sn.dbid
      and stm.instance_number=sn.inst 
	  and stm.snap_id=sn.b_snap
	  and stme.snap_id=sn.e_snap
	  and stm.stat_id=stme.stat_id
      and stme.dbid=sn.dbid
      and stme.instance_number=sn.inst
	  and stm.stat_name='DB time')
	  GROUP BY instance_number,b_day ,b_hour
	  )
SELECT instance_number,b_day,
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
ORDER BY instance_number,b_day;

prompt <a name="TIME_MODE_3"></a>
host echo Check Time Model Last 3 days...
prompt Time Model Last 3 days
WITH subq_snaps AS
(SELECT dbid                dbid
 ,      instance_number     inst
 ,      snap_id             e_snap
 ,      lag(snap_id) over (partition by instance_number, startup_time order by snap_id) b_snap
 ,      TO_CHAR(begin_interval_time,'D') b_day
 ,      TO_CHAR(begin_interval_time,'DD-MON-YYYY HH24:MI') b_time
 ,      TO_CHAR(end_interval_time,'HH24:MI')   e_time
 ,    ((extract(day    from (end_interval_time - begin_interval_time))*86400)
     + (extract(hour   from (end_interval_time - begin_interval_time))*3600)
     + (extract(minute from (end_interval_time - begin_interval_time))*60)
     + (extract(second from (end_interval_time - begin_interval_time)))) duration
 FROM   dba_hist_snapshot 
 where begin_interval_time>trunc(sysdate-3)
 )
SELECT ss.inst
--,      ss.b_snap
--,      ss.e_snap
,      ss.b_time
,      ss.e_time
,      TO_CHAR(ROUND(MAX(CASE WHEN bm.stat_name = 'DB time' THEN em.value - bm.value END)/1000000,2),'999999990.99')                                  db_time
,      TO_CHAR(ROUND(MAX(CASE WHEN bm.stat_name = 'DB time' THEN em.value - bm.value END)/(ss.duration*1000000),1),'999999990.99')        aas
,      (SELECT round(average,2)
        FROM   dba_hist_sysmetric_summary sm
        WHERE  sm.dbid            = ss.dbid
        AND    sm.snap_id         = ss.e_snap
        AND    sm.instance_number = ss.inst
        AND    sm.metric_name     = 'Average Synchronous Single-Block Read Latency'
        AND    sm.group_id        = 2)                                                                                                                   assbl
,      (SELECT round(average,2)
FROM   dba_hist_sysmetric_summary sm
WHERE  sm.dbid            = ss.dbid
AND    sm.snap_id         = ss.e_snap
AND    sm.instance_number = ss.inst
AND    sm.metric_name     = 'Host CPU Utilization (%)'
AND    sm.group_id        = 2)                                                                                                                   cpu_util
,      TO_CHAR(ROUND(MAX(CASE WHEN bm.stat_name = 'DB CPU' THEN em.value - bm.value END)/1000000,2),'999999990.99')                                      db_cpu
,      TO_CHAR(ROUND(MAX(CASE WHEN bm.stat_name = 'sql execute elapsed time' THEN em.value - bm.value END)/1000000,2),'999999990.99')                    sql_time
,      TO_CHAR(ROUND(MAX(CASE WHEN bm.stat_name = 'PL/SQL execution elapsed time' THEN em.value - bm.value END)/1000000,2),'999999990.99')               plsql_time
,      TO_CHAR(ROUND(MAX(CASE WHEN bm.stat_name = 'parse time elapsed' THEN em.value - bm.value END)/1000000,2),'999999990.00')                          parse_time
,      TO_CHAR(ROUND(MAX(CASE WHEN bm.stat_name = 'failed parse elapsed time' THEN em.value - bm.value END)/1000000,2),'999999990.99')                   failed_parse
,      TO_CHAR(ROUND(MAX(CASE WHEN bm.stat_name = 'hard parse (sharing criteria) elapsed time' THEN em.value - bm.value END)/1000000,2),'999999990.99')  hard_parse_sharing
,      TO_CHAR(ROUND(MAX(CASE WHEN bm.stat_name = 'RMAN cpu time (backup/restore)' THEN em.value - bm.value END)/1000000,2),'999999990.99')              rman_cpu
,      TO_CHAR(ROUND(MAX(CASE WHEN bm.stat_name = 'connection management call elapsed time' THEN em.value - bm.value END)/1000000,2),'999999990.99')     connection_mgmt
,      TO_CHAR(ROUND(MAX(CASE WHEN bm.stat_name = 'sequence load elapsed time' THEN em.value - bm.value END)/1000000,2),'999999990.99')                  sequence_load
--,      TO_CHAR(ROUND(100*MAX(CASE WHEN bm.stat_name = 'DB CPU' THEN em.value - bm.value END)
--           / NULLIF(MAX(CASE WHEN bm.stat_name = 'DB time' THEN em.value - bm.value END),0),2),'999999990.99')                                           db_cpu_perc
--,      TO_CHAR(ROUND(100*MAX(CASE WHEN bm.stat_name = 'sql execute elapsed time' THEN em.value - bm.value END)
--           / NULLIF(MAX(CASE WHEN bm.stat_name = 'DB time' THEN em.value - bm.value END),0),2),'999999990.99')                                           sql_time_perc
--,      TO_CHAR(ROUND(100*MAX(CASE WHEN bm.stat_name = 'PL/SQL execution elapsed time' THEN em.value - bm.value END)
--           / NULLIF(MAX(CASE WHEN bm.stat_name = 'DB time' THEN em.value - bm.value END),0),2),'999999990.99')                                           plsql_time_perc
--,      TO_CHAR(ROUND(100*MAX(CASE WHEN bm.stat_name = 'parse time elapsed' THEN em.value - bm.value END)
--           / NULLIF(MAX(CASE WHEN bm.stat_name = 'DB time' THEN em.value - bm.value END),0),2),'999999990.99')                                           parse_time_perc
--,      TO_CHAR(ROUND(100*MAX(CASE WHEN bm.stat_name = 'failed parse elapsed time' THEN em.value - bm.value END)
--           / NULLIF(MAX(CASE WHEN bm.stat_name = 'DB time' THEN em.value - bm.value END),0),2),'999999990.99')                                           failed_parse_perc
--,      TO_CHAR(ROUND(100*MAX(CASE WHEN bm.stat_name = 'hard parse (sharing criteria) elapsed time' THEN em.value - bm.value END)
--           / NULLIF(MAX(CASE WHEN bm.stat_name = 'DB time' THEN em.value - bm.value END),0),2),'999999990.99')                                           hard_parse_sharing_perc
--,      TO_CHAR(ROUND(100*MAX(CASE WHEN bm.stat_name = 'RMAN cpu time (backup/restore)' THEN em.value - bm.value END)
--           / NULLIF(MAX(CASE WHEN bm.stat_name = 'DB time' THEN em.value - bm.value END),0),2),'999999990.99')                                           rman_cpu_perc
FROM  subq_snaps              ss
,     dba_hist_sys_time_model em
,     dba_hist_sys_time_model bm
WHERE bm.dbid                   = ss.dbid
AND   bm.snap_id                = ss.b_snap
AND   bm.instance_number        = ss.inst
AND   em.dbid                   = ss.dbid
AND   em.snap_id                = ss.e_snap
AND   em.instance_number        = ss.inst
AND   bm.stat_id                = em.stat_id
GROUP BY
       ss.dbid
,      ss.inst
,      ss.b_day
,      ss.b_snap
,      ss.e_snap
,      ss.b_time
,      ss.e_time
,      ss.duration
--HAVING b_day NOT IN (6,7)
--AND    inst = 2
--AND b_snap = 18673
--AND    e_time = '17:00'
ORDER BY inst,b_time DESC;

host echo Check DB Patches...
prompt <a name="Patches"></a>
prompt
prompt <font size="+2" face="Arial,Helvetica,Geneva,sans-serif" color="#336699"><b>Patches Installed Overview</b></font>
col comments for a50
select * from registry$history order by 1;

host echo Check DB Tablespaces...
prompt <a name="Tablespace"></a>
prompt
prompt
prompt <font size="+2" face="Arial,Helvetica,Geneva,sans-serif" color="#336699"><b>Tablespace Overview</b></font>

col "Database Details" format a60;
SELECT
    1 sort1,' DBNAME:'||name ||chr(9)||'  DBID:'||dbid ||chr(9)|| '   Created:'||to_char(created, 'dd/mm/yyyy hh24:mi:ss') ||'  Open mode:'||open_mode||chr(10) "  Database Details"
FROM v$database
UNION
SELECT 2 sort1,'Datafiles: '||trim(TO_CHAR(COUNT(*),'9,990'))||chr(9)||'Datafile size(Gb): '||trim(TO_CHAR(SUM(bytes)/1073741824, '9,999,990'))
FROM v$datafile
UNION
SELECT 3 sort1,'Tempfiles: '||trim(TO_CHAR(COUNT(*),'9,990'))||chr(9)||'Tempfile size(Gb): '||trim(TO_CHAR(SUM(bytes)/1073741824, '9,999,990'))
FROM v$tempfile
UNION
SELECT 4 sort1,'Segment size (Gb): '||trim(TO_CHAR(SUM(bytes)/1073741824, '9,999,990'))
FROM dba_segments
UNION
SELECT 5 sort1,'Tables/Indexes: '|| trim(TO_CHAR(SUM(DECODE(type#, 2, 1, 0)), '999,990'))||'/'|| trim(TO_CHAR(SUM(DECODE(type#, 1, 1, 0)), '999,990'))
FROM sys.obj$ 
WHERE owner# <> 0 
UNION
SELECT 6 sort1,'Total DB Users: '||trim( TO_CHAR(COUNT(*), '9,990'))
FROM  sys.user$ WHERE 
type# = 1
UNION
SELECT 7 sort1,'Online Sessions of Cluster: '||trim( TO_CHAR(COUNT(*), '999,990'))
FROM  gv$session
WHERE type='USER'
UNION
SELECT 8 sort1,'Active Sessions of Cluster: '||trim( TO_CHAR(COUNT(*), '999,990'))
FROM  gv$session
WHERE type='USER' and status = 'ACTIVE'
UNION
SELECT 9 sort1,'Session highwater of Current Node: '|| trim(TO_CHAR(sessions_highwater, '999,990'))
FROM v$license;



 
col "Database Size" format a15;
col "Free space" format a15;
col megs_alloc format 999,999,990.99
col megs_used format 999,999,990.99

prompt Note: Database Size is All of files  these are dbfile,tempfile,redo log
select   round(sum(used.bytes) / 1024 / 1024/1024 ) || ' GB' "Database Size",
round(free.p / 1024 / 1024/1024) || ' GB' "Free space"
from (select bytes from v$datafile
union all select bytes from v$tempfile
union all select bytes from v$log) used,
(select sum(bytes) as p from dba_free_space) free
group by free.p;


SELECT   a.tablespace_name tablespace_name,
       ROUND(a.bytes_alloc / 1024 / 1024, 2) megs_alloc,
--       ROUND(NVL(b.bytes_free, 0) / 1024 / 1024, 2) megs_free,
       ROUND((a.bytes_alloc - NVL(b.bytes_free, 0)) / 1024 / 1024, 2) megs_used,
       ROUND((NVL(b.bytes_free, 0) / a.bytes_alloc) * 100,2) Pct_Free,
       (case when ROUND((NVL(b.bytes_free, 0) / a.bytes_alloc) * 100,2)<=0 
                                                then 'Immediate action required!'
             when ROUND((NVL(b.bytes_free, 0) / a.bytes_alloc) * 100,2)<5  
                                                then 'Critical (<5% free)'
             when ROUND((NVL(b.bytes_free, 0) / a.bytes_alloc) * 100,2)<15 
                                                then 'Warning (<15% free)'
             when ROUND((NVL(b.bytes_free, 0) / a.bytes_alloc) * 100,2)<25 
                                                then 'Warning (<25% free)'
             when ROUND((NVL(b.bytes_free, 0) / a.bytes_alloc) * 100,2)>60 
                                                then 'Waste of space? (>60% free)'
             else 'OK'
             end) msg
FROM  ( SELECT  f.tablespace_name,
               SUM(f.bytes) bytes_alloc,
               SUM(DECODE(f.autoextensible, 'YES',f.maxbytes,'NO', f.bytes)) maxbytes
        FROM DBA_DATA_FILES f
        GROUP BY tablespace_name) a,
      ( SELECT  f.tablespace_name,
               SUM(f.bytes)  bytes_free
        FROM DBA_FREE_SPACE f
        GROUP BY tablespace_name) b
WHERE a.tablespace_name = b.tablespace_name (+)
UNION
SELECT h.tablespace_name,
       ROUND(SUM(h.bytes_free + h.bytes_used) / 1048576, 2),
--       ROUND(SUM((h.bytes_free + h.bytes_used) - NVL(p.bytes_used, 0)) / 1048576, 2),
       ROUND(SUM(NVL(p.bytes_used, 0))/ 1048576, 2),
       ROUND((SUM((h.bytes_free + h.bytes_used) - NVL(p.bytes_used, 0)) / SUM(h.bytes_used + h.bytes_free)) * 100,2),
      (case when ROUND((SUM((h.bytes_free + h.bytes_used) - NVL(p.bytes_used, 0)) / SUM(h.bytes_used + h.bytes_free)) * 100,2)<=0 then 'Immediate action required!'
            when ROUND((SUM((h.bytes_free + h.bytes_used) - NVL(p.bytes_used, 0)) / SUM(h.bytes_used + h.bytes_free)) * 100,2)<5  then 'Critical (<5% free)'
            when ROUND((SUM((h.bytes_free + h.bytes_used) - NVL(p.bytes_used, 0)) / SUM(h.bytes_used + h.bytes_free)) * 100,2)<15 then 'Warning (<15% free)'
            when ROUND((SUM((h.bytes_free + h.bytes_used) - NVL(p.bytes_used, 0)) / SUM(h.bytes_used + h.bytes_free)) * 100,2)<25 then 'Warning (<25% free)'
            when ROUND((SUM((h.bytes_free + h.bytes_used) - NVL(p.bytes_used, 0)) / SUM(h.bytes_used + h.bytes_free)) * 100,2)>60 then 'Waste of space? (>60% free)'
            else 'OK'
            end) msg
FROM   sys.V_$TEMP_SPACE_HEADER h, sys.V_$TEMP_EXTENT_POOL p
WHERE  p.file_id(+) = h.file_id
AND    p.tablespace_name(+) = h.tablespace_name
GROUP BY h.tablespace_name
ORDER BY 1;


host echo Check DB Temporary tablespace... 
prompt <a name="Temporary"></a>
prompt
prompt Temporary tablespace information 

COLUMN tablespace_name       FORMAT a20                 HEAD 'Tablespace Name'
COLUMN tablespace_status     FORMAT a9                  HEAD 'Status'
COLUMN tablespace_size       FORMAT 9,999,999,999,999   HEAD 'Size'
COLUMN used                  FORMAT 9,999,999,999,999   HEAD 'Used'
COLUMN used_pct              FORMAT 999                 HEAD 'Pct. Used'
COLUMN current_users         FORMAT 999,999             HEAD 'Current Users'

BREAK ON report

select h.tablespace_name,
       round(sum(h.bytes_free + h.bytes_used) / 1048576) megs_alloc,
       round(sum((h.bytes_free + h.bytes_used) - nvl(p.bytes_used, 0)) /
             1048576) megs_free,
       round(sum(nvl(p.bytes_used, 0)) / 1048576) megs_used,
       round((sum((h.bytes_free + h.bytes_used) - nvl(p.bytes_used, 0)) /
             sum(h.bytes_used + h.bytes_free)) * 100) Pct_Free,
       100 -
       round((sum((h.bytes_free + h.bytes_used) - nvl(p.bytes_used, 0)) /
             sum(h.bytes_used + h.bytes_free)) * 100) pct_used,
       round(sum(f.maxbytes) / 1048576) max
  from sys.v_$TEMP_SPACE_HEADER h,
       sys.v_$Temp_extent_pool  p,
       dba_temp_files           f
 where p.file_id(+) = h.file_id
   and p.tablespace_name(+) = h.tablespace_name
   and f.file_id = h.file_id
   and f.tablespace_name = h.tablespace_name
 group by h.tablespace_name
 ORDER BY 1
/

column name                      format a15             heading 'Container'
column tablespace_name           format a20             heading 'Tablespace'
column contents                  format a9              heading 'Type'
column status                    format a9              heading 'Status'
column tablespace_size           format 999,999,990.99  heading 'Total Size(MB)'
column allocated_space           format 999,999,990.99  heading 'Allocated Size(MB)'
column free_space                format 999,999,990.99  heading 'Free Size(MB)'
column extent_management                                heading 'Extent|Management'
column segment_space_management  format a15             heading 'Segment Space|Management'

select c.con_id,
       c.name,
	   b.tablespace_name,
       b.contents,
       b.status,
--	   round(a.free_space/1024/1024,2)  free_space,
       round(a.tablespace_size/1024/1024,2) tablespace_size,
       round(a.allocated_space/1024/1024,2) allocated_space,
       round(a.free_space/1024/1024,2) free_space,
       b.extent_management,
       b.segment_space_management
  from cdb_temp_free_space a, cdb_tablespaces b, v$containers c
 where a.tablespace_name = b.tablespace_name
   and a.con_id = b.con_id
   and b.con_id = c.con_id
   and b.contents = 'TEMPORARY'
  order by 1;

COL temp_username FOR A20 HEAD USERNAME
COL temp_tablespace FOR A20 HEAD TABLESPACE

SELECT 
    u.inst_id
  , u.username   temp_username
  , s.sid
  , u.session_num serial#
  , u.sql_id
  , u.tablespace temp_tablespace
  , u.contents
  , u.segtype
  , ROUND( u.blocks * t.block_size / (1024*1024) ) MB
  , u.extents
  , u.blocks
FROM 
    gv$tempseg_usage u
  , gv$session s
  , dba_tablespaces t
WHERE
    u.session_addr = s.saddr
AND u.inst_id = s.inst_id
AND t.tablespace_name = u.tablespace
ORDER BY
    mb DESC
/


host echo Check DB UNDO tablespace... 
prompt <a name="UNDO"></a>
prompt
prompt UNDO tablespace information 

select t.tablespace_name, t.status tb, d.status df,
extent_management, allocation_type, segment_space_management, retention,
autoextensible, (maxbytes/1024/1024) mx
from dba_tablespaces t, dba_data_files d
where t.tablespace_name = d.tablespace_name
and retention like '%GUARANTEE'
/
 

select to_char(s.end_time,'yyyy-mm-dd hh24:mi:ss') end_time, s.inst_id, s.undotsn, t.name, sum(activeblks)
from gv$undostat s
join gv$tablespace t on t.ts# = s.undotsn
   and s.inst_id = t.inst_id
where s.end_time in ( select max(end_time) from gv$undostat group by inst_id)
group by to_char(s.end_time,'yyyy-mm-dd hh24:mi:ss'), s.inst_id, s.undotsn, t.name
order by 1,2
/

select to_char(s.end_time,'yyyy-mm-dd hh24:mi:ss') end_time, t.con_id, s.inst_id, s.undotsn, t.name, sum(activeblks)
from gv$undostat s
join gv$tablespace t on t.ts# = s.undotsn
   and s.inst_id = t.inst_id
   and s.con_id = t.con_id
--join gv$pdbs c on c.inst_id = t.inst_id
   --and c.con_id = t.con_id
where s.end_time = ( select max(end_time) from gv$undostat)
group by to_char(s.end_time,'yyyy-mm-dd hh24:mi:ss'), t.con_id, s.inst_id, s.undotsn, t.name
order by 1,2
/


col status format a20 head "Status"
col cnt format 999,999,999 head "How Many?"

select TABLESPACE_NAME,status, count(*) cnt
from dba_rollback_segs
group by TABLESPACE_NAME,status
/

select TABLESPACE_NAME,status,sum(bytes) from DBA_UNDO_EXTENTS group by TABLESPACE_NAME,status
/



host echo Check DB Fragmentation...
prompt <a name="Fragmentation"></a>
prompt FSFI - Free Space Fragmentation index 
select          tablespace_name
, file_id
,          sqrt(max(blocks)/sum(blocks)) *
          (100/sqrt(sqrt(count(blocks)))) fsfi
from          dba_free_space
group by     tablespace_name, file_id
order by     1,2;

 SELECT
 tablespace_name, 
 count(*) free_chunks,
 decode(round((max(bytes) / 1024000),2),
 null,0,
 round((max(bytes) / 1024000),2)) largest_chunk,
 nvl(round(sqrt(max(blocks)/sum(blocks))*(100/sqrt(sqrt(count(blocks)) )),2),0) fragmentation_index
 FROM
 sys.dba_free_space 
 group by 
 tablespace_name
 order by 2 desc, 1;
prompt Note:  FSFI is greater than 40% is OK, If FSFI is lower than 30% means it have high free space fragmentation index. 
prompt      A fragmented tablespace can lack the contiguous free space needed to allocate new extents. 



host echo Check DB Instance recover... 
prompt <a name="Roll_Transaction"></a>
prompt
prompt Rollback from fast_start_transactions
select to_char(systimestamp,'hh24:mi:ssxff') currtime
	, usn
	, slt
	, seq
	, state
	, pid
	, undoblocksdone
	, undoblockstotal
	, to_char( ( undoblocksdone / undoblockstotal ) * 100,'990.9')||'%' pctdone
from v$fast_start_transactions
/

host echo Check Active transactions... 
prompt <a name="Active_Transaction"></a>
prompt
prompt Active transactions 
col xid for a30  
select t.xidusn||'.'||t.xidslot||'.'||xidsqn XID ,s.sid,machine,s.sql_id,start_time, username, r.name,  
ubafil, ubablk, t.status, (used_ublk*p.value)/1024 blk, used_urec,decode(bitand(t.flag,power(2,7)),0, 'Normal','TX rolling') tx_state
 from v$transaction t, v$rollname r, v$session s, v$parameter p
 where xidusn=usn
 and s.saddr=t.ses_addr
 and p.name='db_block_size'
order by start_time desc; 

host echo Check Datafiles and Tempfiles info... 
prompt <a name="dbfile"></a>
prompt
prompt <font size="+1" face="Arial,Helvetica,Geneva,sans-serif" color="#336699"><b> Datafiles And Tempfiles</b></font>

COL tablespace_name FOR A30
COL current_size FOR A10
COL max_size FOR A10
select 
    tablespace_name,
    file_id,
    file_name ,    
    dbms_xplan.FORMAT_SIZE(bytes) current_size, 
	autoextensible autoext,
	decode(autoextensible, 'YES', dbms_xplan.FORMAT_SIZE(MAXBYTES), null)  max_size,STATUS
from
    (select tablespace_name, file_id, file_name, autoextensible, bytes, maxbytes,STATUS from dba_data_files  
     union all
     select tablespace_name, file_id, file_name, autoextensible, bytes, maxbytes,STATUS from dba_temp_files 
    )
order by
    tablespace_name,
    file_name
;

prompt  CDB Datafiles and Tempfiles
clear columns breaks computes

column container       format a15                 heading 'Contianer'
column tablespace_name format a15                 heading 'Tablespace'     print entmap
column file_name       format a50                 heading 'File_Name'      print entmap
column total_mb        format 999,999,990.00      heading 'Total_MB'       print entmap
column max_mb          format 999,999,990.00      heading 'Max_MB'         print entmap
column autoextensible  format a15                 heading 'Autoextensible' print entmap
column status          format a15                 heading 'Status'         print entmap

break on tablespace_name on report
compute count label 'Count:' of file_name on report
compute sum label 'Total:' of total_mb max_mb on report

select b.con_id,
       b.name container,
       a.tablespace_name,
       a.file_name,
       a.bytes / 1024 / 1024 total_mb,
       a.maxbytes / 1024 / 1024 max_mb,
       a.autoextensible,
       decode(a.online_status,'ONLINE',a.online_status,'SYSTEM',a.online_status,'<div align="left"><font color="red">' || a.online_status || '</font></div>') status
  from cdb_data_files a, v$containers b
 where a.con_id = b.con_id
union all
select b.con_id,
       b.name container,
       a.tablespace_name,
       a.file_name,
       a.bytes / 1024 / 1024 total_mb,
       a.maxbytes / 1024 / 1024 max_mb,
       a.autoextensible,
       decode(a.status,'ONLINE',a.status,'<div align="left"><font color="red">' || a.status || '</font></div>') status
  from cdb_temp_files a, v$containers b
  where a.con_id = b.con_id
order by 1,2,3;


host echo Check PDB tablespace info... 
prompt <a name="pdb_tablespace"></a>
prompt  PDB tablespace info
clear columns breaks computes

column con_id                   format 999
column container                format a10                 heading 'Container'
column tablespace_name          format a20                 heading 'Tablespace'
column type                     format a9                  heading 'Type'
column status                                              heading 'Status'
column bigfile                  format a7                  heading 'Bigfile'
column total_size               format 999,999,990.99      heading 'Total Size(MB)'
column free_size                format 999,999,990.99      heading 'Free Size(MB)'
column extensible_size          format 999,999,990.99      heading 'Extensible|Size(MB)'
-- column used_mb               format 999,999,990.00      heading 'Used Size(MB)'
column used                     format 990.99              heading 'Used %'
column e_used                   format 990.99              heading 'E_Used %'
column extent_management        format a10                 heading 'Extent|Management'
column segment_space_management format a13                 heading 'Segment Space|Management'
column compute                  format a7                  heading 'Compute'
break on report on con_id skip 1
compute count label 'Count:' of container                      on con_id, report 
compute sum   label 'Total:' of total_size free_size /* used_size */ on con_id,report
select a.con_id,
       c.name container,
       a.tablespace_name,
       a.type,
       space total_size,
	   nvl(free_space, 0) free_size,
    -- space - nvl(free_space, 0) used_mb,
       case
          when trunc ( (1 - nvl (free_space, 0) / space) * 100) >= 90
          then '<div align="right"><font color="red">' || to_char (round ( (1 - nvl (free_space, 0) / space) * 100, 2), '990.99') || '</font></div>'
          else '<div align="right">' || to_char (round ( (1 - nvl (free_space, 0) / space) * 100, 2), '990.99') || '</div>'
       end used,
	   a.bigfile,
       decode(a.status,'ONLINE',a.status,'<div align="left"><font color="red">' || a.status || '</font></div>') status,
       a.extent_management,
       a.segment_space_management,
	   extensible_mb extensible_size,
       case
          when trunc ( (1 - nvl (free_space + extensible_mb, 0) / space_e) * 100) >= 90
          then '<div align="right"><font color="red">' || to_char (round ( (1 - nvl (free_space+extensible_mb, 0) / space_e) * 100, 2), '990.99') || '</font></div>'
          else '<div align="right">' || to_char (round ( (1 - nvl (free_space+extensible_mb, 0) / space_e) * 100, 2), '990.99') || '</div>'
       end e_used
  from (select d.con_id,
               d.tablespace_name,
               t.contents type,
               t.status,
               t.bigfile,
               t.extent_management,
               t.segment_space_management,
               round(sum(d.bytes) / 1024 / 1024, 2) space,
               round(sum(to_number(decode(autoextensible, 'NO', to_char(d.bytes), 'YES', to_char(maxbytes)))) / 1024 / 1024, 2) space_e,
               round(sum(to_number(decode(autoextensible, 'YES', to_char(maxbytes - bytes), '0'))) / 1024 / 1024, 2) extensible_mb
          from cdb_data_files d, cdb_tablespaces t
         where d.tablespace_name = t.tablespace_name
		   and d.con_id = t.con_id
         group by d.con_id,
		          d.tablespace_name,
                  t.contents,
                  t.status,
                  t.bigfile,
                  t.extent_management,
                  t.segment_space_management) a,
       (select con_id, tablespace_name,
               round(sum(bytes) / 1024 / 1024, 2) free_space
          from cdb_free_space
         group by con_id, tablespace_name) b,
	   (select con_id, name from v$containers) c
 where a.tablespace_name = b.tablespace_name(+)
   and a.con_id = b.con_id
   and b.con_id = c.con_id
 order by con_id, used desc;
prompt <ul>-
<li><font size="2pt"><b>Free_Size not include extensible free space.</b></font></li>-
<li><font size="2pt"><b>"Used %" come from free_size/total_size,so this is the real usage percent of current physical space.</b></font></li>-
<li><font size="2pt"><b>"E_Used %" come from (free_size+extensible_size)/(total_size+extensible_size), so this is a theoretical value.</b></font></li>-
</ul>

host echo Check DB Corruption or Need of Recovery... 
prompt <a name="Recovery_file"></a>
prompt
prompt Monitor DB Corruption or Need of Recovery
SELECT r.FILE# AS df#, d.NAME AS df_name, t.NAME AS tbsp_name, '<font color="red">'||d.STATUS||'</font>',
    r.ERROR, r.CHANGE#, r.TIME FROM V$RECOVER_FILE r, V$DATAFILE d, V$TABLESPACE t
    WHERE t.TS# = d.TS# AND d.FILE# = r.FILE#;
prompt

prompt <a name="CORRUPTION"></a>
prompt DATABASE BLOCK CORRUPTION
select file#,block#,blocks,CORRUPTION_TYPE
from V$DATABASE_BLOCK_CORRUPTION;


host echo Check DB Controlfile... 
prompt <a name="Controlfile"></a>
prompt Controlfile Size
select name, block_size * file_size_blks / 1024 / 1024 SIZE_MB
  from v$controlfile;
prompt
prompt Controlfile record
select * from v$controlfile_record_section;

alter session set nls_date_format='yyyymmdd hh24:mi:ss';

host echo Check DB REDO and ARCHIVELOG... 
prompt <a name="Redo"></a>
prompt
prompt <font size="+2" face="Arial,Helvetica,Geneva,sans-serif" color="#336699"><b>Online Redo Overview</b></font>
col member  format A50 heading "Redolog Files";
col group# format 99;
col archived format a3;
col status format a10;
col first_time format a22;
select a.inst_id,a.group#,THREAD# ,SEQUENCE# , a.member,round(b.bytes/1024/1024) SIZE_MB, b.archived, b.status, b.first_time from gv$logfile a, gv$log b
where a.group# = b.group# and a.inst_id=b.inst_id order by 1, a.group#;


select 'Group# '||group#||': '||
       (case 
          when members<2 then '+ Redo log mirroring is recommended'
          else ' '||members||' members detected. - OK'
        end) recommended
from v$log
where members < 2;


select 
       (case
          when count(*)>3 then '+ '||count(*)||' times detected when log switches occured more than 1 log per 5 minutes.'||chr(10)||
                                               '+ You may consider to increase the redo log size.'
          else '+ Redo log size: OK'
        end) "Redolog Size Status"
from (
select trunc(FIRST_TIME,'HH') Week, count(*) arch_no, trunc(10*count(*)/60) archpermin
from v$log_history
group by trunc(FIRST_TIME,'HH')
having trunc(5*count(*)/60)>1
);

select (case  when sync_waits = 0 then '+ Waits for log file sync not detected: log_buffer is OK'
        else  '+ Waits for log file sync detected ('||sync_waits||' times): Consider to increase the log_buffer'
        end) "Log Buffer Status"
from ( select  decode(  sum(w.total_waits),  0, 0,
    nvl(100 * sum(l.total_waits) / sum(w.total_waits), 0)
  )  sync_waits
from  sys.v_$bgprocess  b,  sys.v_$session  s,  sys.v_$session_event  l,  sys.v_$session_event  w
where
  b.name like 'DBW_' and  s.paddr = b.paddr and
  l.sid = s.sid and  l.event = 'log file sync' and
  w.sid = s.sid and  w.event = 'db file parallel write'
);

col KSPPINM for a50
col KSPPSTVL for a50
col ksppdesc for a50
select  nam.ksppinm, val.KSPPSTVL, nam.ksppdesc   
 from    sys.x$ksppi nam,   
         sys.x$ksppsv val   
 where nam.indx = val.indx     
 AND   upper(nam.ksppinm) LIKE '%LOG_PARALLE%';   

select THREAD#, ROUND(log.BYTES/1024/1024) REDO_LOG_MB, round(sga.bytes/1024/1024) redo_buffer_mb,  os.value  "NCPUS" from v$log log,v$sgainfo sga ,v$osstat os  where log.status='CURRENT' and sga.name='Redo Buffers' and stat_name='NUM_CPUS';

prompt Tip:
prompt LOG_BUFFER depending on the SGA size and CPU count. If this is not explicitly set by the DBA then it use a default.
prompt the private redo strands in shared_pool.


prompt <a name="Archivelog"></a>
prompt
prompt <font size="+2" face="Arial,Helvetica,Geneva,sans-serif" color="#336699"><b>Archivelog Overview </b></font>
prompt 
prompt <a name="archive_destinations"></a>
select 'Database log mode' name,log_mode value from v$database
union all
select i.instance_name||'.'||p.name,p.value
  from gv$parameter p, gv$instance i
 where name like 'log_archive%' and name='archive_lag_target'
   and p.inst_id = i.instance_number
   and name not like 'log_archive_dest_state%'
   and value is not null
 order by 1;

host echo Check Archivelog switch... 
prompt <a name="logswitch"></a>
prompt Log File Switches
break on report on "Day"
compute sum label "Grand Total: " of "total" on report
alter session set nls_date_format='yyyy-mm-dd';
select thread#, trunc(first_time) as "date", to_char(first_time,'Dy') as "Day", count(1) as "total",
sum(decode(to_char(first_time,'HH24'),'00',1,0)) as "h00",
sum(decode(to_char(first_time,'HH24'),'01',1,0)) as "h01",
sum(decode(to_char(first_time,'HH24'),'02',1,0)) as "h02",
sum(decode(to_char(first_time,'HH24'),'03',1,0)) as "h03",
sum(decode(to_char(first_time,'HH24'),'04',1,0)) as "h04",
sum(decode(to_char(first_time,'HH24'),'05',1,0)) as "h05",
sum(decode(to_char(first_time,'HH24'),'06',1,0)) as "h06",
sum(decode(to_char(first_time,'HH24'),'07',1,0)) as "h07",
sum(decode(to_char(first_time,'HH24'),'08',1,0)) as "h08",
sum(decode(to_char(first_time,'HH24'),'09',1,0)) as "h09",
sum(decode(to_char(first_time,'HH24'),'10',1,0)) as "h10",
sum(decode(to_char(first_time,'HH24'),'11',1,0)) as "h11",
sum(decode(to_char(first_time,'HH24'),'12',1,0)) as "h12",
sum(decode(to_char(first_time,'HH24'),'13',1,0)) as "h13",
sum(decode(to_char(first_time,'HH24'),'14',1,0)) as "h14",
sum(decode(to_char(first_time,'HH24'),'15',1,0)) as "h15",
sum(decode(to_char(first_time,'HH24'),'16',1,0)) as "h16",
sum(decode(to_char(first_time,'HH24'),'17',1,0)) as "h17",
sum(decode(to_char(first_time,'HH24'),'18',1,0)) as "h18",
sum(decode(to_char(first_time,'HH24'),'19',1,0)) as "h19",
sum(decode(to_char(first_time,'HH24'),'20',1,0)) as "h20",
sum(decode(to_char(first_time,'HH24'),'21',1,0)) as "h21",
sum(decode(to_char(first_time,'HH24'),'22',1,0)) as "h22",
sum(decode(to_char(first_time,'HH24'),'23',1,0)) as "h23"
from
v$archived_log
where first_time > trunc(sysdate-10)
group by thread#, trunc(first_time), to_char(first_time, 'Dy') order by 2,1;


prompt Size of archivelog per day 
  select distinct
         to_char(trunc (first_time,'dd'),'yyyy/mm/dd') "Datetime",
         round (
            sum (blocks * block_size / 1024 / 1024)
               over (partition by trunc (first_time)),
            2)
            as "Archivelog(MB)/Day"
    from v$archived_log
   where dest_id = 1
     and sysdate - first_time <= 30
order by 1;
prompt Note: If it is a Multitenant environment, the archivelog size is the sum of all PDB.
prompt <a name="arcivelog_nodelete"></a>
prompt  NO deleted Archivelogs (v$archived_log.deleted='NO')
prompt
select dest.dest_name,dest.target,dest.status,dest.DESTINATION,log.* from 
(select min(FIRST_TIME),min(SEQUENCE#),max(NEXT_TIME),dest_id,thread#   from v$archived_log where  DELETED='NO' group by thread#,dest_id )log
,V$ARCHIVE_DEST dest where   log.dest_id=dest.dest_id;

host echo Check Flashback recover area... 
prompt <a name="flash_recovery_area_parameters"></a>
prompt <font size="+2" face="Arial,Helvetica,Geneva,sans-serif" color="#336699"><b>Flash Recovery Area Parameters</b></font>

prompt <b>db_recovery_file_dest_size is specified in bytes</b>
 
COLUMN instance_name_print   FORMAT a95    HEADING 'Instance Name'     ENTMAP off
COLUMN thread_number_print   FORMAT a95    HEADING 'Thread Number'     ENTMAP off
COLUMN name                  FORMAT a125   HEADING 'Name'              ENTMAP off
COLUMN value                               HEADING 'Value'             ENTMAP off

SELECT
    '<div align="center"><font color="#336699"><b>' || i.instance_name || '</b></font></div>'        instance_name_print
  , '<div align="center">'                          || i.thread#       || '</div>'                   thread_number_print
  , '<div nowrap>'                                  || p.name          || '</div>'                   name
  , (CASE p.name
         WHEN 'db_recovery_file_dest_size' THEN '<div nowrap align="right">' || TO_CHAR(p.value, '999,999,999,999,999') || '</div>'
     ELSE
         '<div nowrap align="right">' || NVL(p.value, '(null)') || '</div>'
     END)                                                                                            value
FROM
    gv$parameter p
  , gv$instance  i
WHERE
      p.inst_id = i.inst_id
  AND p.name IN ('db_recovery_file_dest_size', 'db_recovery_file_dest')
ORDER BY
    1
  , 3;
  
prompt <a name="flash_recovery_area_status"></a>
prompt <font size="+2" face="Arial,Helvetica,Geneva,sans-serif" color="#336699"><b>Flash Recovery Area Status</b></font>

prompt <b>Current location, disk quota, space in use, space reclaimable by deleting files, and number of files in the Flash Recovery Area</b>

CLEAR COLUMNS BREAKS COMPUTES

COLUMN name               FORMAT a75                  HEADING 'Name'               ENTMAP off
COLUMN space_limit        FORMAT 99,999,999,999,999   HEADING 'Space Limit'        ENTMAP off
COLUMN space_used         FORMAT 99,999,999,999,999   HEADING 'Space Used'         ENTMAP off
COLUMN space_used_pct     FORMAT 999.99               HEADING '% Used'             ENTMAP off
COLUMN space_reclaimable  FORMAT 99,999,999,999,999   HEADING 'Space Reclaimable'  ENTMAP off
COLUMN pct_reclaimable    FORMAT 999.99               HEADING '% Reclaimable'      ENTMAP off
COLUMN number_of_files    FORMAT 999,999              HEADING 'Number of Files'    ENTMAP off

SELECT
    '<div align="center"><font color="#336699"><b>' || name || '</b></font></div>'    name
  , space_limit                                                                       space_limit
  , space_used                                                                        space_used
  , ROUND((space_used / DECODE(space_limit, 0, 0.000001, space_limit))*100, 2)        space_used_pct
  , space_reclaimable                                                                 space_reclaimable
  , ROUND((space_reclaimable / DECODE(space_limit, 0, 0.000001, space_limit))*100, 2) pct_reclaimable
  , number_of_files                                                                   number_of_files
FROM
    v$recovery_file_dest
ORDER BY
    name;
	
host echo Check Flashback database... 
prompt <a name="flashback_database_parameters"></a>
prompt <font size="+2" face="Arial,Helvetica,Geneva,sans-serif" color="#336699"><b>Flashback Database Parameters</b></font>

prompt <b>db_flashback_retention_target is specified in minutes</b>
prompt <b>db_recovery_file_dest_size is specified in bytes</b>

CLEAR COLUMNS BREAKS COMPUTES

COLUMN instance_name_print   FORMAT a95    HEADING 'Instance Name'     ENTMAP off
COLUMN thread_number_print   FORMAT a95    HEADING 'Thread Number'     ENTMAP off
COLUMN name                  FORMAT a125   HEADING 'Name'              ENTMAP off
COLUMN value                               HEADING 'Value'             ENTMAP off

BREAK ON report ON instance_name_print ON thread_number_print

SELECT
    '<div align="center"><font color="#336699"><b>' || i.instance_name || '</b></font></div>'        instance_name_print
  , '<div align="center">'                          || i.thread#       || '</div>'                   thread_number_print
  , '<div nowrap>'                                  || p.name          || '</div>'                   name
  , (CASE p.name
         WHEN 'db_recovery_file_dest_size'    THEN '<div nowrap align="right">' || TO_CHAR(p.value, '999,999,999,999,999') || '</div>'
         WHEN 'db_flashback_retention_target' THEN '<div nowrap align="right">' || TO_CHAR(p.value, '999,999,999,999,999') || '</div>'
     ELSE
         '<div nowrap align="right">' || NVL(p.value, '(null)') || '</div>'
     END)                                                                                            value
FROM
    gv$parameter p
  , gv$instance  i
WHERE
      p.inst_id = i.inst_id
  AND p.name IN ('db_flashback_retention_target', 'db_recovery_file_dest_size', 'db_recovery_file_dest')
ORDER BY
    1
  , 3;

prompt <a name="flashback_database_status"></a>
prompt <font size="+2" face="Arial,Helvetica,Geneva,sans-serif" color="#336699"><b>Flashback Database Status</b></font>

CLEAR COLUMNS BREAKS COMPUTES

COLUMN dbid                                HEADING 'DB ID'              ENTMAP off
COLUMN name             FORMAT A75         HEADING 'DB Name'            ENTMAP off
COLUMN log_mode         FORMAT A75         HEADING 'Log Mode'           ENTMAP off
COLUMN flashback_on     FORMAT A75         HEADING 'Flashback DB On?'   ENTMAP off

SELECT
    '<div align="center"><font color="#336699"><b>' || dbid          || '</b></font></div>'  dbid
  , '<div align="center">'                          || name          || '</div>'             name
  , '<div align="center">'                          || log_mode      || '</div>'             log_mode
  , '<div align="center">'                          || flashback_on  || '</div>'             flashback_on
FROM v$database;

CLEAR COLUMNS BREAKS COMPUTES

COLUMN oldest_flashback_time    FORMAT a125               HEADING 'Oldest Flashback Time'     ENTMAP off
COLUMN oldest_flashback_scn                               HEADING 'Oldest Flashback SCN'      ENTMAP off
COLUMN retention_target         FORMAT 999,999            HEADING 'Retention Target (min)'    ENTMAP off
COLUMN retention_target_hours   FORMAT 999,999            HEADING 'Retention Target (hour)'   ENTMAP off
COLUMN flashback_size           FORMAT 9,999,999,999,999  HEADING 'Flashback Size'            ENTMAP off
COLUMN estimated_flashback_size FORMAT 9,999,999,999,999  HEADING 'Estimated Flashback Size'  ENTMAP off

SELECT
    '<div align="center"><font color="#336699"><b>' || TO_CHAR(oldest_flashback_time,'mm/dd/yyyy HH24:MI:SS') || '</b></font></div>'  oldest_flashback_time
  , oldest_flashback_scn             oldest_flashback_scn
  , retention_target                 retention_target
  , retention_target/60              retention_target_hours
  , flashback_size                   flashback_size
  , estimated_flashback_size         estimated_flashback_size
FROM
    v$flashback_database_log
ORDER BY
    1;
	
host echo Check DB Regisery and Option... 
prompt <a name="Option"></a>
prompt <font size="+2" face="Arial,Helvetica,Geneva,sans-serif" color="#336699"><b>Regisery and Option Overview</b></font>

select comp_id,comp_name,version,status,modified,schema,procedure from dba_registry order by 1;

column parameter format a75 heading 'Options'
column value     format a15 heading 'Value'

select * from v$option order by 1;

host echo Check DB Feature Usage... 
prompt <a name="feature_usage_statistics"></a>
prompt <font size="+2" face="Arial,Helvetica,Geneva,sans-serif" color="#336699"><b>Feature Usage Statistics</b></font>
select name feaname,FIRST_USAGE_DATE , LAST_USAGE_DATE,DESCRIPTION from DBA_FEATURE_USAGE_STATISTICS where LAST_USAGE_DATE is not null;

host echo Check DB High Water Mark... 
prompt <a name="high_water_mark_statistics"></a>
prompt <font size="+2" face="Arial,Helvetica,Geneva,sans-serif" color="#336699"><b>High Water Mark Statistics</b></font>
col HWMNAME for a40
select name hwmname,HIGHWATER , LAST_VALUE,DESCRIPTION from DBA_HIGH_WATER_MARK_STATISTICS ;


 
prompt <a name="Performance"></a>
prompt
prompt <font size="+2" face="Arial,Helvetica,Geneva,sans-serif" color="#336699"><b>Database Performance Profile</b></font>		 
host echo Check DB Response Time... 	
prompt LAST 1 minuts

prompt The time to respond
select inst_id,to_char(begin_time,'hh24:mi') btime, round( value * 10, 2) "Response Time (ms)"
     from gv$sysmetric
     where metric_name='SQL Service Response Time';
prompt
prompt Throughput
select a.inst_id,a.begin_time, a.end_time, round(((a.value + b.value)/131072),2) "GB per sec"
from gv$sysmetric a, gv$sysmetric b
where a.metric_name = 'Logical Reads Per Sec'
and b.metric_name = 'Physical Reads Direct Per Sec'
and a.begin_time = b.begin_time;
prompt
prompt LAST 1 hours
select * from gv$sysmetric_summary where metric_name like 'SQL Service Response%';
prompt
prompt LAST 1 minuts
select /*+ ORDERED USE_MERGE(m) */
        TO_CHAR (
            FROM_TZ (CAST (m.end_time AS TIMESTAMP),
                     TO_CHAR (SYSTIMESTAMP, 'tzr'))
               AT TIME ZONE SESSIONTIMEZONE,
            'YYYY-MM-DD HH24:MI:SS')
            snap_time, metric_name,round(value,2) metric_value ,metric_unit from 
  v$alert_types a, v$threshold_types t, v$sysmetric m
     WHERE     a.internal_metric_category = 'instance_throughput'
           AND a.reason_id = t.alert_reason_id
           AND t.metrics_id = m.metric_id
           AND m.GROUP_ID = 2
		   and value>0
           AND m.end_time <= SYSDATE
  ORDER BY m.end_time ASC,2;
prompt  Note:
prompt   in PDB above output is empty.
prompt   if user calls/(user commits+user rollbacks)<30 means commit too frequently
prompt   if logon per sec >20 means user logon(logon storm) too frequently
prompt   if hard parse per sec >100 means hard parse too frequently

host echo Check DB System-wide Wait... 	
prompt <a name="Event"></a>
prompt
prompt <font size="+2" face="Arial,Helvetica,Geneva,sans-serif" color="#336699"><b>System-wide Wait Analysis|for current wait events</b></font>	

column c1 heading 'Event|Name'             format a40
column c2 heading 'Total|Waits'            format 999,999,999,999,999
column c3 heading 'Seconds|Waiting'        format 999,999,999,999
column c4 heading 'Total|Timeouts'         format 999,999,999,999,999
column c5 heading 'Average|Wait|(in ms)' format 999,999,999,999.9
select
   event                         c1,
   total_waits                   c2,
   time_waited / 100             c3,
   total_timeouts                c4,
   average_wait    *10          c5
from
   sys.v_$system_event
where
   event not in (
    'dispatcher timer',
    'lock element cleanup',
    'Null event',
    'parallel query dequeue wait',
    'parallel query idle wait - Slaves',
    'pipe get',
    'PL/SQL lock timer',
    'pmon timer',
    'rdbms ipc message',
    'slave wait',
    'smon timer',
    'SQL*Net break/reset to client',
    'SQL*Net message from client',
    'SQL*Net message to client',
    'SQL*Net more data to client',
    'virtual circuit status',
    'WMON goes to sleep'
   )
AND
 event not like 'DFS%'
and
   event not like '%done%'
and
   event not like '%Idle%'
AND
 event not like 'KXFX%'
and time_waited>60
order by
    c3 desc,c2
;

prompt <a name="enq_3day"></a>
prompt
prompt <font size="+2" face="Arial,Helvetica,Geneva,sans-serif" color="#336699"><b>Last 3 days for ENQ events</b></font>	

select container,
             instance_number,
             end_interval_time,
             snap_id,
             event_name,
             round(wait_time / 1e3, 2) as wait_time,
             waits,
             round(wait_time / 1e3 / decode(waits, 0, null, waits), 2) avg_wait_time
        from (select c.name container,
                     e.instance_number,
                     s.end_interval_time,
                     e.snap_id,
                     e.event_name,
                     (e.time_waited_micro - lag(e.time_waited_micro)
                      over(partition by e.con_id,
                           s.instance_number,
                           s.startup_time,
                           e.event_name order by e.snap_id)) wait_time,
                     (e.total_waits - lag(e.total_waits)
                      over(partition by e.con_id,
                           s.instance_number,
                           s.startup_time,
                           e.event_name order by e.snap_id)) waits,
                     dense_rank() over(partition by e.con_id, s.startup_time, e.event_name order by e.snap_id) rank
                from cdb_hist_system_event e, cdb_hist_snapshot s, v$containers c
               where e.instance_number = s.instance_number
                 and e.snap_id = s.snap_id
                 and e.dbid = s.dbid
                 and e.con_id = c.con_id
                 and s.end_interval_time > sysdate - 7
                 and e.event_name LIKE 'enq%'
				 )
       where rank <> 1 and wait_time>600 and waits>60
       order by 1, 2, 4;
	   
host echo Check DB wait Chains... 	
prompt <a name="wait_chains"></a>
prompt <font size="+2" face="Arial,Helvetica,Geneva,sans-serif" color="#336699"><b>Current wait Chains</b></font>	

column w_proc format a50 tru
column instance format a20 tru
column inst format a28 tru
column wait_event format a50 tru
column p1 format a16 tru
column p2 format a16 tru
column p3 format a15 tru
column seconds format a50 tru
column sincelw format a50 tru
column blocker_proc format a50 tru
column waiters format a50 tru
column chain_signature format a100 wra
column blocker_chain format a100 wra
SELECT *
FROM (SELECT 'Current Process: '||osid W_PROC, 'SID '||i.instance_name INSTANCE,
'INST #: '||instance INST,'Blocking Process: '||decode(blocker_osid,null,'<none>',blocker_osid)||
' from Instance '||blocker_instance BLOCKER_PROC,'Number of waiters: '||num_waiters waiters,
'Wait Event: ' ||wait_event_text wait_event, 'P1: '||p1 p1, 'P2: '||p2 p2, 'P3: '||p3 p3,
'Seconds in Wait: '||in_wait_secs Seconds, 'Seconds Since Last Wait: '||time_since_last_wait_secs sincelw,
'Wait Chain: '||chain_id ||': '||chain_signature chain_signature,'Blocking Wait Chain: '||decode(blocker_chain_id,null,
'<none>',blocker_chain_id) blocker_chain
FROM v$wait_chains wc,
v$instance i
WHERE wc.instance = i.instance_number (+)
AND ( num_waiters > 0
OR ( blocker_osid IS NOT NULL
AND in_wait_secs > 10 ) )
ORDER BY chain_id,
num_waiters DESC)
WHERE ROWNUM < 101;

prompt <a name="latch"></a>
prompt Latch stat
column latch_name format a30 tru
select inst_id, name latch_name,
round((gets-misses)/decode(gets,0,1,gets),3) hit_ratio,
round(sleeps/decode(misses,0,1,misses),3) "SLEEPS/MISS"
from gv$latch
where round((gets-misses)/decode(gets,0,1,gets),3) < .99
and gets != 0
order by round((gets-misses)/decode(gets,0,1,gets),3);

-- No Wait Latches:
-- 
select inst_id, name latch_name,
round((immediate_gets/(immediate_gets+immediate_misses)), 3) hit_ratio,
round(sleeps/decode(immediate_misses,0,1,immediate_misses),3) "SLEEPS/MISS"
from gv$latch
where round((immediate_gets/(immediate_gets+immediate_misses)), 3) < .99
and immediate_gets + immediate_misses > 0
order by round((immediate_gets/(immediate_gets+immediate_misses)), 3);

host echo Check DB Parameters...
prompt <a name="DBParameter"></a>
prompt <font size="+2" face="Arial,Helvetica,Geneva,sans-serif" color="#336699"><b>Database Parameters Details</b></font>
column "database parameter" format a40;
column sid for a20
column "VALUE" format a40;

 
prompt instance parameter modified 
select inst_id,name,type ptype,DISPLAY_VALUE,DESCRIPTION  from  gV$SYSTEM_PARAMETER where ISDEFAULT='FALSE' order by 1,2;

prompt The parameters in memory and spfile difference Check
select * from (
select mem.inst_id, mem.name, mem.value, 'from mem' VALUE_FROM
  from (select inst_id, name, upper(display_value) value
          from gv$system_parameter2
         where isdefault = 'FALSE'
        minus
        select inst_id, name, upper(display_value) value
          from gv$spparameter
         where isspecified = 'TRUE') mem
union
select spf.inst_id, spf.name, spf.value, 'from spf'
  from (select inst_id, name, upper(display_value) value
          from gv$spparameter
         where isspecified = 'TRUE'
        minus
        select inst_id, name, upper(display_value) value
          from gv$system_parameter2
         where isdefault = 'FALSE') spf
		 )
where name not in('instance_number','thread','undo_tablespace','sessions')
order by 1, 2;	

prompt <a name="DBParameter_for_datapump"></a>
prompt Initialization Parameters That Affect Data Pump Performance
select inst_id,name,value,isdefault,DESCRIPTION from gv$system_parameter2 where name in('disk_asynch_io','db_block_checking','db_block_checksum','processes','sessions','parallel_max_servers','streams_pool_size','sga_target');

host echo Check DB Statistics Level...
prompt <a name="statistics_level"></a>
prompt <font size="+2" face="Arial,Helvetica,Geneva,sans-serif" color="#336699"><b>Statistics Level</b></font>
COLUMN instance_name_print     FORMAT a95    HEADING 'Instance Name'         ENTMAP off
COLUMN statistics_name         FORMAT a95    HEADING 'Statistics Name'       ENTMAP off
COLUMN session_status          FORMAT a95    HEADING 'Session Status'        ENTMAP off
COLUMN system_status           FORMAT a95    HEADING 'System Status'         ENTMAP off
COLUMN activation_level        FORMAT a95    HEADING 'Activation Level'      ENTMAP off
COLUMN statistics_view_name    FORMAT a95    HEADING 'Statistics View Name'  ENTMAP off
COLUMN session_settable        FORMAT a95    HEADING 'Session Settable?'     ENTMAP off
 
SELECT
    '<div align="center"><font color="#336699"><b>' || i.instance_name    || '</b></font></div>'               instance_name_print
  , '<div align="left" nowrap>'                     || s.statistics_name  || '</div>'                          statistics_name
  , DECODE(   s.session_status
            , 'ENABLED'
            , '<div align="center"><b><font color="darkgreen">' || s.session_status || '</font></b></div>'
            , '<div align="center"><b><font color="#990000">'   || s.session_status || '</font></b></div>')    session_status
  , DECODE(   s.system_status
            , 'ENABLED'
            , '<div align="center"><b><font color="darkgreen">' || s.system_status || '</font></b></div>'
            , '<div align="center"><b><font color="#990000">'   || s.system_status || '</font></b></div>')     system_status
  , (CASE s.activation_level
         WHEN 'TYPICAL' THEN '<div align="center"><b><font color="darkgreen">' || s.activation_level || '</font></b></div>'
         WHEN 'ALL'     THEN '<div align="center"><b><font color="darkblue">'  || s.activation_level || '</font></b></div>'
         WHEN 'BASIC'   THEN '<div align="center"><b><font color="#990000">'   || s.activation_level || '</font></b></div>'
     ELSE
         '<div align="center"><b><font color="#663300">'   || s.activation_level || '</font></b></div>'
     END)                                                      activation_level
  , s.statistics_view_name                                     statistics_view_name
  , '<div align="center">' || s.session_settable || '</div>'   session_settable
FROM
    gv$statistics_level s
  , gv$instance  i
WHERE
      s.inst_id = i.inst_id
ORDER BY
    i.instance_name
  , s.statistics_name;

host echo Check DB EVENT_ENABLED..
prompt <a name="EVENT_ENABLED"></a>
prompt Dump System level events enabled
oradebug setmypid
oradebug eventdump system
prompt
prompt NLS parameters
column "NLS_Parameter" format a40;
column "VALUE" format a40;
column "VALUE_FROM" format a40;
Select parameter "NLS_Parameter", value from nls_database_parameters;

host echo Check DB SGA and PGA..
prompt <font size="+2" face="Arial,Helvetica,Geneva,sans-serif" color="#336699"><b>Tunning Database SGA/PGA</b></font>
prompt <a name="Memory_summary"></a>
prompt
select comments,round(value/1024/1024/1024) size_gb from v$osstat where STAT_NAME like 'PHYSICAL%';
select name,value,isdefault,ismodified from v$parameter where name in('memory_target','memory_max_target','sga_max_size','sga_target','lock_sga','pre_page_sga') order by 1;

prompt <a name="ASMM"></a>
prompt
prompt <font size="+2" face="Arial,Helvetica,Geneva,sans-serif" color="#336699"><b>Memory Manage ASMM OPS</b></font>
prompt 
col  component for a30
 select 
   component, 
   oper_type, 
   oper_mode, 
   initial_size/1024/1024 "Initial", 
   TARGET_SIZE/1024/1024  "Target", 
   FINAL_SIZE/1024/1024   "Final", 
   status ,START_TIME,end_TIME
from 
   v$sga_resize_ops;
prompt <a name="SGA"></a>
prompt
prompt <font size="+1" face="Arial,Helvetica,Geneva,sans-serif" color="#336699"><b>SGA Info</b></font>

clear columns breaks computes

break on report on instance_name

column instance_name format a13         heading 'Instance'
column name          format a50         heading 'Pool Name'
column bytes         format 999,990.99  heading 'Size_MB'
column resizeable    format a10         heading 'Resizeable'

  select instance_name,
         name,
         round (bytes / 1024 / 1024, 2) bytes,
         resizeable
    from gv$sgainfo s, gv$instance i
   where s.inst_id = i.inst_id
order by 1, 3 desc;

prompt <font size="+2" face="Arial,Helvetica,Geneva,sans-serif" color="#336699"><b>SGA Stat</b></font>
prompt 
column "SGA Pool"format a33;
col "M_bytes" format 999,999,999.99;

select pool "SGA Pool", m_bytes from ( select  pool, to_char( trunc(sum(bytes)/1024/1024,2), '9,999,999.99' ) as M_bytes
    from v$sgastat
    where pool is not null   group  by pool
    union
    select name as pool, to_char( trunc(bytes/1024/1024,3), '9,999,999.99' ) as M_bytes
    from v$sgastat
    where pool is null  order     by 2 desc
    ) UNION ALL
    select    'TOTAL' as pool, to_char( trunc(sum(bytes)/1024/1024,3), '9,999,999.99' ) from v$sgastat;

col used_mb for 999,999,999.00
col free_mb for 999,999,999.00
Select round(tot.bytes  /1024/1024 ,2)  sga_total, round(used.bytes /1024/1024 ,2)  used_mb, round(free.bytes /1024/1024 ,2)  free_mb
from (select sum(bytes) bytes  from v$sgastat where  name != 'free memory') used,    
(select sum(bytes) bytes from  v$sgastat  where  name = 'free memory') free, 
(select sum(bytes) bytes from v$sgastat) tot;

select pool,  round(sgasize/1024/1024,2) "SGA_TARGET",  
round(bytes/1024/1024,2) FREE_MB, 
round(bytes/sgasize*100, 2) "%FREE"
from  (select sum(bytes) sgasize from sys.v_$sgastat) s, sys.v_$sgastat f
where  f.name = 'free memory';

prompt <a name="SHAREDPOOL"></a>
prompt Allocate large than 1GB memarea name of shared pool 
SELECT name, to_char( trunc(bytes/1024/1024,3), '9,999,999.99' ) as M_bytes 
FROM v$sgastat WHERE pool = 'shared pool' 
AND (bytes > 999999 OR name = 'free memory') and bytes>1*power(1024,3) 
 ORDER BY bytes DESC;

prompt <a name="ROWCACHE"></a>
prompt Rowcache
col "Data Dict. Gets" heading Data_Dict.|Gets format 999,999,999,999,999,990;
col "Data Dict. Cache Misses" heading Dict._Cache|Misses;
col "Data Dict Cache Hit Ratio" heading Dict._Cache|Hit_Ratio;
col "% Missed" heading Missed|%;
SELECT SUM(gets)   "Data Dict. Gets", SUM(getmisses)  "Data Dict. Cache Misses"
  , TRUNC((1-(sum(getmisses)/SUM(gets)))*100, 2) "Data Dict Cache Hit Ratio"
  , TRUNC(SUM(getmisses)*100/SUM(gets), 2)  "% Missed"
FROM  v$rowcache;

prompt
Prompt* The Dict. Cache Hit% shuold be > 90% and misses% should be < 15%. If not consider increase SHARED_POOL_SIZE.

prompt
prompt x$kghlu
col kghluidx head SUB|POOL
col kghludur head SSUB|POOL
col kghlufsh head FLUSHED|CHUNKS
col kghluops head "LRU LIST|OPERATIONS"
col kghlurcr head RECURRENT|CHUNKS
col kghlutrn head TRANSIENT|CHUNKS
col kghlunfu head "FREE UNPIN|UNSUCCESS"
col kghlunfs head "LAST FRUNP|UNSUCC SIZE"
col kghlurcn head RESERVED|SCANS
col kghlurmi head RESERVED|MISSES
col kghlurmz head "RESERVED|MISS SIZE"
col kghlurmx head "RESERVED|MISS MAX SZ"


select
    to_char(sysdate, 'YYYY-MM-DD HH24:MI:SS') current_time
  , kghluidx
  , kghludur
  , kghlufsh
  , kghluops
  , kghlurcr
  , kghlutrn
  , kghlunfu
  , kghlunfs
  , kghlurcn
  , kghlurmi
  , kghlurmz
  , kghlurmx
--  , kghlumxa
--  , kghlumes
--  , kghlumer
from
    x$kghlu
order by
    kghluidx
  , kghludur
/

prompt <a name="Librarycache"></a>
prompt Librarycache


col "Namespace" heading name|space;
col "Hit Ratio" heading Hit|Ratio;
col "Pin Hit Ratio" heading Pin_Hit|Ratio;
col "Invalidations" heading invali|dations;

SELECT  namespace  "Namespace",gets, TRUNC(gethitratio*100) "Hit Ratio", pins,
TRUNC(pinhitratio*100) "Pin Hit Ratio", reloads "Reloads", invalidations  "Invalidations"
FROM  v$librarycache
order by 2;

prompt 
prompt <ul>-
<li><font size="2pt"><b>SGETHITRATIO and PINHITRATIO should be more than 90%.</b></font></li>-
<li><font size="2pt"><b>More of Invalid object in namespace will cause more reloads.</b></font></li>-
</ul>

col "Cache Misses" heading Cache|Misses;
col "Library Cache Hit Ratio" heading Lib._Cache|Hit_Ratio;
col "% Missed" heading Missed|%;
SELECT SUM(pins)     "Executions", SUM(reloads)  "Cache Misses"
  , TRUNC((1-(SUM(reloads)/SUM(pins)))*100, 2) "Library Cache Hit Ratio"
  , ROUND(SUM(reloads)*100/SUM(pins))       "% Missed"        
FROM  v$librarycache;
prompt
prompt <ul>-
<li><font size="2pt"><b>The Lib. Cache Hit% shuold be > 90% and misses% should be < 1%. If not consider increase SHARED_POOL_SIZE.</b></font></li>-
</ul>


DECLARE
      libcac number(10,2);
      rowcac number(10,2);
      bufcac number(10,2);
      redlog number(10,2);
      redoent number;
      redowaittime number;
BEGIN
select value into redlog from v$sysstat where name = 'redo log space requests';
select value into redoent from v$sysstat where name = 'redo entries';
select value into redowaittime from v$sysstat where name = 'redo log space wait time';
select 100*(sum(pins)-sum(reloads))/sum(pins) into libcac from v$librarycache;
select 100*(sum(gets)-sum(getmisses))/sum(gets) into rowcac from v$rowcache;
select 100*(cur.value + con.value - phys.value)/(cur.value + con.value) into bufcac
from v$sysstat cur,v$sysstat con,v$sysstat phys,v$statname ncu,v$statname nco,v$statname nph
where cur.statistic# = ncu.statistic#
        and ncu.name = 'db block gets'
        and con.statistic# = nco.statistic#
        and nco.name = 'consistent gets'
        and phys.statistic# = nph.statistic#
        and nph.name = 'physical reads';
dbms_output.put_line('<div class="kmnotebox">');
if
 libcac < 90  then dbms_output.put_line('*** HINT: Library Cache too low! Increase the Shared Pool Size.');
END IF;
if
 rowcac < 85  then dbms_output.put_line('*** HINT: Row Cache too low! Increase the Shared Pool Size.');
END IF;
if
 bufcac < 90  then dbms_output.put_line('*** HINT: Buffer Cache too low! Increase the DB Block Buffer value.');
END IF;
if
 redlog > 1000000 then dbms_output.put_line('*** HINT: Log Buffer value is rather low!');
END IF;
END;
/


prompt Recommendations:
prompt <ul>-
<li><font size="2pt"><b>SQL Cache Hit rate ratio should be above 90%, if not then increase the Shared Pool Size.</b></font></li>-
<li><font size="2pt"><b>Dict Cache Hit rate ratio should be above 85%, if not then increase the Shared Pool Size.</b></font></li>-
<li><font size="2pt"><b>Buffer Cache Hit rate ratio should be above 90%, if not then increase the DB Block Buffer value.</b></font></li>-
<li><font size="2pt"><b>Redo Log space requests should be less than 0.5% of redo entries, if not then increase log buffer.</b></font></li>-
<li><font size="2pt"><b>Redo Log space wait time should be near to 0.</b></font></li>-
</ul>


exec dbms_output.put_line('</div>');

col free_space format 999,999,999,999 head "Reserved|Free Space"
col max_free_size format 999,999,999,999 head "Reserved|Max"
col avg_free_size format 999,999,999,999 head "Reserved|Avg"
col used_space format 999,999,999,999 head "Reserved|Used"
col requests format 999,999,999,999 head "Total|Requests"
col request_misses format 999,999,999,999 head "Reserved|Area|Misses"
col last_miss_size format 999,999,999,999 head "Size of|Last Miss" 
col request_failures format 9,999,999,999 head "Shared|Pool|Miss"
col last_failure_size format 999,999,999,999 head "Failed|Size"

select request_failures,request_misses,
case 
when request_misses=0 then 'too big'
when request_misses>request_failures and request_misses<100  then 'small'
when request_misses>=100 and request_failures>100 then 'too small'
end "reserved pool state",
 last_failure_size, free_space, max_free_size, avg_free_size,used_space, requests, last_miss_size
from v$shared_pool_reserved
/

prompt <a name="PGA"></a>
prompt PGA Overview

column instance_name heading 'Instance'
column name          heading 'Name'
column pgastat_value     for 999,999,999,999,999    heading 'Value'
column unit		     heading 'Unit'

  select i.instance_name,
         p.name pgastat_name,
         p.value pgastat_value,
         p.unit
    from gv$pgastat p, gv$instance i
   where p.inst_id = i.inst_id
order by 1, 3 desc,4;

clear columns breaks computes

host echo Check DB Resource Limit..
prompt <a name="resource_limit"></a>
prompt <font size="+2" face="Arial,Helvetica,Geneva,sans-serif" color="#336699"><b>Resource Limit</b></font>
select * from gv$resource_limit;	


host echo Check DB Session / Processes...
prompt <a name="session"></a>
prompt
prompt <font size="+2" face="Arial,Helvetica,Geneva,sans-serif" color="#336699"><b>Session Overview</b></font>

compute sum label 'Total:' of sessions on report
  select inst_id,type,status,count(*) sessions
    from gv$session
group by inst_id,type,status
order by inst_id;

col Username for a30
select inst_id,
 nvl( username, 'background') "Username",
 program "Program",
 server "Server",
 count(*) "Sessions"
from
 sys.gv_$session
where
 type='USER'
 and program not like '%QMN%'
 and program not like '%CJQ%'
group by inst_id,username, program, server
order by count(*) desc
/


select con_id,inst_id,
 nvl( username, 'background') "Username",
 program "Program",
 server "Server",
 count(*) "Sessions"
from
 sys.gv_$session
where
 type='USER'
 and program not like '%QMN%'
 and program not like '%CJQ%'
group by con_id,inst_id,username, program, server
order by count(*) desc
/

prompt <a name="bgprocess"></a>
prompt <font size="+2" face="Arial,Helvetica,Geneva,sans-serif" color="#336699"><b>Background Processes</b></font>
select bg.inst_id,p.pid,p.spid,bg.name,bg.DESCRIPTION,bg.error from gv$bgprocess bg ,gv$process p where bg.inst_id=p.inst_id and  bg.paddr=p.addr;

prompt <a name="LMS_process"></a>
select inst_id,num,name,value,DESCRIPTION from gv$parameter where name in('gcs_server_processes');



host echo Check DB Connections TimeLine...
prompt <a name="connection"></a>
prompt 
prompt <font size="+2" face="Arial,Helvetica,Geneva,sans-serif" color="#336699"><b>Connections TimeLine</b></font>
col begin_interval_time for a40
col end_interval_time for a40
SELECT sn.instance_number,to_char(sn.begin_interval_time,'yyyymmdd hh24:mi:ss') begin_interval_time,
                to_char(sn.end_interval_time,'yyyymmdd hh24:mi:ss') end_interval_time,
                ss.stat_name stat_name,
                ss.VALUE e_value,
                LAG (ss.VALUE, 1)
                   OVER (PARTITION BY ss.instance_number,stat_name ORDER BY  ss.snap_id)
                   b_value ,
				 to_char((ss.VALUE-LAG (ss.VALUE, 1)
                   OVER (PARTITION BY ss.instance_number,stat_name ORDER BY  ss.snap_id))/LAG (ss.VALUE, 1)
                   OVER (PARTITION BY ss.instance_number,stat_name ORDER BY  ss.snap_id)*100,'990.99') diff
               -- ,sn.snap_id
           FROM dba_hist_sysstat ss, dba_hist_snapshot sn
          WHERE     TRUNC (sn.begin_interval_time) >TRUNC (SYSDATE)-7 --need modify
                AND ss.snap_id = sn.snap_id
                AND ss.dbid = sn.dbid
                AND ss.instance_number = sn.instance_number
                AND ss.dbid = (SELECT dbid FROM v$database)
                AND ss.stat_name IN ('logons current')
				order by 1,2;
				
				
prompt <a name="tg_load_profile"></a>
prompt <font size="+1" face="Arial,Helvetica,Geneva,sans-serif" color="#336699"><b>Last 7 days Load Profile overview</b></font>

host echo Check last 7 days load profile ...

clear columns breaks computes

break on instance_number skip 1

col instance_number heading "Inst"
 
select
       instance_number,
       end_interval_time,
       snap_id,
       sum(decode(stat_name, 'db block changes', value, 0)) as "db block changes",
       sum(decode(stat_name, 'execute count', value, 0)) as "execute count",
       sum(decode(stat_name, 'logons cumulative', value, 0)) as "logons cumulative",
       sum(decode(stat_name, 'parse count (total)', value, 0)) as "parse count (total)",
       sum(decode(stat_name, 'parse count (hard)', value, 0)) as "parse count (hard)",
       sum(decode(stat_name, 'parse time elapsed', value, 0)) as "parse time elapsed",
       sum(decode(stat_name, 'physical reads', value, 0)) as "physical reads",
       sum(decode(stat_name, 'physical writes', value, 0)) as "physical writes",
       sum(decode(stat_name, 'redo size', value, 0)) as "redo size",
       sum(decode(stat_name, 'session logical reads', value, 0)) as "session logical reads",
       sum(decode(stat_name, 'user calls', value, 0)) as "user calls",
       sum(decode(stat_name, 'user commits', value, 0)) as "user commits",
       sum(decode(stat_name, 'user rollbacks', value, 0)) as "user rollbacks",
       sum(decode(stat_name, 'workarea executions - optimal', value, 0)) as "SQL workarea"
  from (select 
               e.instance_number,
               s.end_interval_time,
               e.snap_id,
               e.stat_name,
               e.value - lag(e.value) over(partition by  e.instance_number, s.startup_time, e.stat_name order by e.snap_id) value,
               dense_rank() over(partition by   s.startup_time, e.stat_name order by e.snap_id) rank
          from DBA_hist_sysstat e, DBA_hist_snapshot s 
         where e.instance_number = s.instance_number
           and e.dbid = s.dbid
           and s.end_interval_time > sysdate - 7
           and e.snap_id = s.snap_id
           and e.stat_name in
               ('db block changes',
                'execute count',
                'logons cumulative',
                'parse count (total)',
                'parse count (hard)',
                'parse time elapsed',
                'physical reads',
                'physical writes',
                'redo size',
                'session logical reads',
                'user calls',
                'user commits',
                'user rollbacks',
                'workarea executions - optimal'))
 where rank <> 1
 group by  instance_number, end_interval_time, snap_id
 order by  instance_number, snap_id;


select container,
       instance_number,
       end_interval_time,
       snap_id,
       sum(decode(stat_name, 'db block changes', value, 0)) as "db block changes",
       sum(decode(stat_name, 'execute count', value, 0)) as "execute count",
       sum(decode(stat_name, 'logons cumulative', value, 0)) as "logons cumulative",
       sum(decode(stat_name, 'parse count (total)', value, 0)) as "parse count (total)",
       sum(decode(stat_name, 'parse count (hard)', value, 0)) as "parse count (hard)",
       sum(decode(stat_name, 'parse time elapsed', value, 0)) as "parse time elapsed",
       sum(decode(stat_name, 'physical reads', value, 0)) as "physical reads",
       sum(decode(stat_name, 'physical writes', value, 0)) as "physical writes",
       sum(decode(stat_name, 'redo size', value, 0)) as "redo size",
       sum(decode(stat_name, 'session logical reads', value, 0)) as "session logical reads",
       sum(decode(stat_name, 'user calls', value, 0)) as "user calls",
       sum(decode(stat_name, 'user commits', value, 0)) as "user commits",
       sum(decode(stat_name, 'user rollbacks', value, 0)) as "user rollbacks",
       sum(decode(stat_name, 'workarea executions - optimal', value, 0)) as "SQL workarea"
  from (select c.name container,
               e.instance_number,
               s.end_interval_time,
               e.snap_id,
               e.stat_name,
               e.value - lag(e.value) over(partition by e.con_id, e.instance_number, s.startup_time, e.stat_name order by e.snap_id) value,
               dense_rank() over(partition by e.con_id, s.startup_time, e.stat_name order by e.snap_id) rank
          from cdb_hist_sysstat e, cdb_hist_snapshot s, v$containers c
         where e.instance_number = s.instance_number
           and e.dbid = s.dbid
           and e.con_id = c.con_id
           and s.end_interval_time > sysdate - 7
           and e.snap_id = s.snap_id
           and e.stat_name in
               ('db block changes',
                'execute count',
                'logons cumulative',
                'parse count (total)',
                'parse count (hard)',
                'parse time elapsed',
                'physical reads',
                'physical writes',
                'redo size',
                'session logical reads',
                'user calls',
                'user commits',
                'user rollbacks',
                'workarea executions - optimal'))
 where rank <> 1
 group by container, instance_number, end_interval_time, snap_id
 order by container, instance_number, snap_id;


host echo Check DB Parallel...
prompt <a name="parallel"></a>
prompt <font size="+2" face="Arial,Helvetica,Geneva,sans-serif" color="#336699"><b>Parallel Report</b></font>
column "VALUE" format a40;
select name,value,isdefault,ismodified from v$parameter where name like '%parallel%';
select name, value sys_value from v$sysstat where lower(name) like lower('%parallel%');

select  statistic, value "PARALLEL_ST_VALUE"  from  v$px_process_sysstat where  statistic like 'Servers%';
       
prompt <div>-
<font size="2pt"><b>If you see a "Servers highwater" value significantly greater than cpu_count, -
Oracle may be issuing too many parallel query slaves.You should reduce  the parallel_max_servers parameter value. -
</b></font>-
</div>
prompt
prompt
prompt Tables or Indexes Object-level parallelism
SELECT OWNER, TABLE_NAME "OBJECT", DEGREE
  FROM DBA_TABLES
 WHERE trim(DEGREE)  not in('1','0','DEFAULT')
UNION
SELECT OWNER, INDEX_NAME "OBJECT", DEGREE
  FROM DBA_INDEXES
 WHERE trim(DEGREE)  not in('1','0','DEFAULT')
 /

host echo Check DB object...
prompt <a name="object_summary"></a>
prompt <font size="+2" face="Arial,Helvetica,Geneva,sans-serif" color="#336699"><b>Database Object Information</b></font>

WITH o
     AS (  SELECT owner,
                  COUNT (1) TOTAL,
                  SUM (
                     DECODE (object_type,
                             'TABLE', 1,
                             'TABLE PARTITION', 1,
                             'TABLE SUBPARTITION', 1,
                             0))
                     tables,
                  SUM (DECODE (object_type,  'JOB', 1,  'SCHEDULE', 1,  0))
                     JOBS,
                  SUM (DECODE (object_type, 'PROCEDURE', 1, 0)) PROC,
				  SUM (DECODE (object_type, 'FUNCTION', 1, 0)) FUNS,
                  SUM (DECODE (object_type, 'DATABASE LINK', 1, 0)) links,
                  SUM (DECODE (object_type, 'VIEW', 1, 0)) VIEWS,
                  SUM (DECODE (object_type, 'MATERIALIZED VIEW', 1, 0)) MVIEWS,
                  SUM (DECODE (object_type, 'SYNONYM', 1, 0)) SYN,
				  SUM (DECODE (object_type, 'TRIGGER', 1, 0)) trg,
				  SUM (DECODE (object_type, 'SEQUENCE', 1, 0)) SEQ,
                  SUM (
                     DECODE (object_type,  'LOB', 1,  'LOB PARTITION', 1,  0))
                     lobs
					,SUM(decode(status,'INVALID',1,0)) invalid
             FROM dba_objects where owner not in('SYS','XDB','SYSTEM','WMSYS','ORDSYS','MDSYS','LBACSYS','OJVMSYS','ORDDATA','AUDSYS','CTXSYS','DVSYS','OLAPSYS','DBSNMP','ORACLE_OCM','OUTLN','DBSFWUSER','REMOTE_SCHEDULER_AGENT','APPQOSSYS','DVF','GSMADMIN_INTERNAL','ORDPLUGINS')
         GROUP BY owner)
  SELECT o.*,
         U.ACCOUNT_STATUS,
         U.CREATED         
    FROM o JOIN dba_users u ON o.owner = U.USERNAME
ORDER BY account_status, owner;


select owner,object_type,count(*) from dba_objects where owner  NOT IN(select schema_name from v$sysaux_occupants) and owner not in('SYS','XDB','SYSTEM','WMSYS','ORDSYS','MDSYS','LBACSYS','OJVMSYS','ORDDATA','AUDSYS','CTXSYS','DVSYS','OLAPSYS','DBSNMP','ORACLE_OCM','OUTLN','DBSFWUSER','REMOTE_SCHEDULER_AGENT','APPQOSSYS','DVF','GSMADMIN_INTERNAL','ORDPLUGINS') group by owner,object_type order by 1;



prompt <a name="dblink"></a>
prompt Database links

col dblinks_owner head OWNER for a20
col dblinks_db_link head DB_LINK for a40
col dblinks_username head USERNAME for a20
col dblinks_host head HOST for a40

select 
	owner dblinks_owner,
	db_link dblinks_db_link,
	username dblinks_username,
	host dblinks_host,
	created
from
	dba_db_links;
	
prompt <a name="invalidobj"></a>
prompt Invalid Objects
prompt
select owner,object_type,count(*) from dba_objects where status != 'VALID' group by owner,object_type
union all
select owner,INDEX_TYPE, count(*) from dba_indexes where status not in ('VALID', 'N/A') group by owner,INDEX_TYPE 
union all
select null,null,0 from dual order by 1;

prompt <font size="+1" face="Arial,Helvetica,Geneva,sans-serif" color="#336699"><b>Unusable Indexes</b></font>

clear columns breaks computes

col container  for a15 heading 'Container'
col owner      for a15 heading 'Owner'
col index_name for a15 heading "Index Name"
col index_type for a15 heading "Index Type"
col table_name for a15 heading "Table Name"
col status     for a15 heading "Status"

select i.owner,
       i.index_name,
       i.index_type,
       i.table_name,
       i.status
  from dba_indexes i
 where status = 'UNUSABLE';

select c.con_id,
       c.name container,
       i.owner,
       i.index_name,
       i.index_type,
       i.table_name,
       i.status
  from cdb_indexes i, v$containers c
 where status = 'UNUSABLE'
   and i.con_id = c.con_id;
   
prompt <a name="obj_lvl"></a>
prompt <font size="+1" face="Arial,Helvetica,Geneva,sans-serif" color="#336699"><b>Index With High Blevel or Degree</b></font>

host echo Check indexes with blevel more than 4 or degree more then 1 ...

select c.name container,i.owner index_owner,i.index_name,i.index_type,i.table_owner,i.table_name,i.uniqueness,i.compression,i.blevel,i.degree
from cdb_indexes i, v$containers c
where i.con_id = c.con_id
and (blevel > 3 or degree not in ('0','1','DEFAULT'))
order by 1,2,3;

prompt <a name="tab_diff_index"></a>
col table_owner for a30
prompt Tables and Indexes owner are different
prompt
select table_owner, table_name, owner as "index_owner", index_name
  from dba_indexes
 where table_owner <> owner
 union all
 select null,null,null,'0' from dual order by 1;
 
prompt <a name="empty_tab"></a>
 prompt
 prompt Empty Tables Statistics but stale
 select owner,table_name,PARTITION_NAME,SUBPARTITION_NAME,BLOCKS,NUM_ROWS,STALE_STATS,LAST_ANALYZED from dba_tab_statistics 
where NUM_ROWS=0 and owner NOT IN(select schema_name from v$sysaux_occupants) and LAST_ANALYZED>sysdate-1/24 and STALE_STATS='YES';

prompt <a name="recyclebin"></a>
prompt recyclebin Usage
prompt
select OWNER,TYPE,count(*) from dba_recyclebin group by owner,type order by 3;
select pdb_name,OWNER,TYPE,count(*) from cdb_recyclebin bin,dba_pdbs pdb where bin.con_id=pdb.con_id group by pdb_name, owner,type order by 4;

prompt <a name="schema"></a>
prompt Schema Usage
prompt
select  /*+rule*/  obj.owner "USERNAME",  obj_cnt "Objects", decode(seg_size, NULL, 0, seg_size) "Size_MB"
from (select owner, count(*) obj_cnt from dba_objects group by owner) obj,
(select owner, ceil(sum(bytes)/1024/1024) seg_size
from dba_segments group by owner) seg
where obj.owner  = seg.owner(+)
order by 3 desc,2 desc, 1;

 
select owner,segment_type,count(*) seg_count, ceil(sum(bytes)/1024/1024) "Size_MB"
from dba_segments 
where owner NOT IN(select schema_name from v$sysaux_occupants)
 group by owner,segment_type 
 order by 1,2;
 
prompt <a name="Largest_Object"></a>
prompt
prompt List of Largest Object in Database:
prompt 
col SEGMENT_NAME format a30;
col SEGMENT_TYPE format a10;
col BYTES format a15;
col TABLESPACE_NAME FORMAT A25;
SELECT * FROM (select owner,SEGMENT_NAME, SEGMENT_TYPE TYPE, sum(BYTES)/1024/1024 SIZE_MB 
from dba_segments group by owner,segment_name,SEGMENT_TYPE order by SIZE_MB desc ) WHERE ROWNUM <= 10;


prompt <a name="nopartition"></a>
prompt
prompt Large table(large than 20GB) is not partitioned:
select owner,segment_name,round(sum(bytes)/1024/1024/1024) size_GB
from dba_segments where segment_type='TABLE' group by owner,segment_name
having sum(bytes)/1024/1024/1024>20 order by 1,3 DESC;

prompt <a name="toomany_partition"></a>
prompt
prompt Too Many partitions of table (large than 500)
select table_owner,table_name,sum(SUBPARTITION_COUNT) subpartition_cnt ,count(*) partition_cnt 
from dba_tab_partitions group by table_owner,table_name having count(*)>500 or sum(SUBPARTITION_COUNT)>500;

prompt <a name="obj_in_systbs"></a>
prompt
prompt List of  Object of non-sys schema in System Sysaux TABLESPACE:
select OWNER,tablespace_name,COUNT(*) from dba_segments where tablespace_name in('SYSTEM','SYSAUX') AND OWNER NOT IN(select schema_name from v$sysaux_occupants) GROUP BY OWNER,tablespace_name order by 1;

prompt <a name="largest_systbs"></a>
prompt 
prompt List of TOP 10 largest objects in SYSTEM AND SYSAUX TABLESPACE:
select * from (
select tablespace_name,topseg_seg_owner,topseg_segment_name,segment_type,mb,partitions, row_number() over(partition by tablespace_name order by mb desc) rn from (
select 
                tablespace_name, 
                owner topseg_seg_owner, 
                segment_name topseg_segment_name, 
                --partition_name, 
                segment_type, 
                round(SUM(bytes/1048576)) MB, 
    case when count(*) >= 1 then count(*) else null end partitions 
        from dba_segments 
        where upper(tablespace_name) in ('SYSTEM','SYSAUX')  -- tablespace name   
  group by 
                tablespace_name, 
                owner, 
                segment_name, 
                segment_type ))
     where rn<=10;

prompt <a name="toomany_index"></a>
prompt
prompt List Too many indexes of  table:
select table_owner, table_name, count(*)
  from dba_indexes
 where table_owner NOT IN ('SYS',
                           'SYSTEM',
                           'SYSMAN',
                           'SYSMAN_MDS',
                           'SYSMAN_RO',
                           'DBSNMP',
                           'WMSYS','WDSYS','XDB',
                           'OUTLN')
 group by table_owner, table_name
having count(*) > 20;

prompt <a name="bitmap_index"></a>
prompt 
prompt BitMap indexes in DB
select owner, index_name from dba_indexes where index_type = 'BITMAP';

prompt <a name="FK_without_index"></a>
prompt  
prompt FK constraints without index on child table
select 
 acc.OWNER "Owner",
 acc.CONSTRAINT_NAME "Constraint",
 acc.table_name "Table",
 acc.COLUMN_NAME "Column",
 acc.POSITION "Position"
from
 dba_cons_columns acc, dba_constraints ac
where
 ac.CONSTRAINT_NAME = acc.CONSTRAINT_NAME and ac.CONSTRAINT_TYPE = 'R'
 and acc.OWNER not in ( 'ANONYMOUS', 'AURORA$', 'AURORA', 'CTXSYS', 'DBSNMP', 'DIP', 'DMSYS', 'DVF', 'DVSYS', 'EXFSYS', 'HR', 'LBACSYS', 'MDDATA', 'MDSYS', 'MGMT_VIEW', 'ODM', 'ODM_MTR', 'OE', 'OLAPSYS', 'ORACLE_OCM', 'ORAWSM', 'ORDPLUGINS', 'ORDSYS', 'OSE', 'OUTLN', 'PERFSTAT', 'PM', 'QS', 'QS_ADM', 'QS_CB', 'QS_CBADM', 'QS_CS', 'QS_ES', 'QS_OS', 'QS_WS', 'REPADMIN', 'SCOTT', 'SH', 'SI_INFORMTN_SCHEMA', 'SYS', 'SYSMAN', 'SYSTEM', 'TRACESVR', 'TSMSYS', 'WKPROXY', 'WKSYS', 'WK_TEST', 'WKUSER', 'WMSYS', 'XDB','APEX_030200','GSMADMIN_INTERNAL','ORDDATA' )
 and acc.OWNER = ac.OWNER
 and not exists ( select 'TRUE' from dba_ind_columns b
                  where b.TABLE_OWNER = acc.OWNER
                  and b.TABLE_NAME = acc.TABLE_NAME
                  and b.COLUMN_NAME = acc.COLUMN_NAME
                  and b.COLUMN_POSITION = acc.POSITION)
 order by acc.OWNER, acc.CONSTRAINT_NAME, acc.COLUMN_NAME, acc.POSITION
;

prompt <a name="latest_mod"></a>
prompt
prompt Object Modified in last 3 days:
set line 200;
col owner format a15;
col object_name format a30;
col object_type format a15;
col last_modified format a20;
col created format a20;
col status format a10;
select owner, object_name, object_type, to_char(max(LAST_DDL_TIME),'MM/DD/YYYY HH24:MI:SS') last_modified,
    to_char(max(CREATED),'MM/DD/YYYY HH24:MI:SS') created 
from  dba_objects
where (SYSDATE - LAST_DDL_TIME) < 3  and OWNER NOT IN(select schema_name from v$sysaux_occupants)
group by owner, object_name, object_type
order by last_modified DESC;

prompt <a name="latest_mod_more10"></a>
prompt
prompt Top 20 Object Modified Percent more than 10%:
SELECT dt.owner, dt.table_name "Table Change > 10%",
       ROUND ( sum(DELETES + UPDATES + INSERTS) / sum(num_rows) * 100) PERCENTAGE
FROM   dba_tables dt, all_tab_modifications atm
WHERE  dt.owner = atm.table_owner
       AND dt.table_name = atm.table_name
       AND num_rows > 0
	   and owner NOT IN(select schema_name from v$sysaux_occupants)
       AND ROUND ( (DELETES + UPDATES + INSERTS) / num_rows * 100) >= 10
	  and rownum<=20
	 group by  dt.owner,dt.table_name
ORDER BY 3 desc;

prompt
SELECT owner "Object Created in this Week: ",count(1) total from DBA_objects
where owner NOT IN(select schema_name from v$sysaux_occupants) AND created >= sysdate -7
group by owner;



prompt <a name="top_10_segments_by_extents"></a>
prompt <font size="+2" face="Arial,Helvetica,Geneva,sans-serif" color="#336699"><b>Top 10 Segments (by number of extents)</b></font>

CLEAR COLUMNS BREAKS COMPUTES

COLUMN owner                                               HEADING 'Owner'            ENTMAP off
COLUMN segment_name                                        HEADING 'Segment Name'     ENTMAP off
COLUMN partition_name                                      HEADING 'Partition Name'   ENTMAP off
COLUMN segment_type                                        HEADING 'Segment Type'     ENTMAP off
COLUMN tablespace_name                                     HEADING 'Tablespace Name'  ENTMAP off
COLUMN extents             FORMAT 999,999,999,999,999,999  HEADING 'Extents'          ENTMAP off
COLUMN bytes               FORMAT 999,999,999,999,999,999  HEADING 'Size (in bytes)'  ENTMAP off

BREAK ON report
COMPUTE sum LABEL '<font color="#990000"><b>Total: </b></font>' OF extents bytes ON report

SELECT
    a.owner
  , a.segment_name
  , a.partition_name
  , a.segment_type
  , a.tablespace_name
  , a.extents
  , a.bytes
FROM
    (select
         b.owner
       , b.segment_name
       , b.partition_name
       , b.segment_type
       , b.tablespace_name
       , b.bytes
       , b.extents
     from
         dba_segments b
     order by
         b.extents desc
    ) a
WHERE
    rownum <= 10;
	
prompt <a name="objects_unable_to_extend"></a>
prompt <font size="+2" face="Arial,Helvetica,Geneva,sans-serif" color="#336699"><b>Objects Unable to Extend</b></font> 

prompt <b>Segments that cannot extend because of MAXEXTENTS or not enough space</b>

CLEAR COLUMNS BREAKS COMPUTES

COLUMN owner             FORMAT a75                  HEADING 'Owner'            ENTMAP off
COLUMN tablespace_name                               HEADING 'Tablespace Name'  ENTMAP off
COLUMN segment_name                                  HEADING 'Segment Name'     ENTMAP off
COLUMN segment_type                                  HEADING 'Segment Type'     ENTMAP off
COLUMN next_extent       FORMAT 999,999,999,999,999  HEADING 'Next Extent'      ENTMAP off
COLUMN max               FORMAT 999,999,999,999,999  HEADING 'Max. Piece Size'  ENTMAP off
COLUMN sum               FORMAT 999,999,999,999,999  HEADING 'Sum of Bytes'     ENTMAP off
COLUMN extents           FORMAT 999,999,999,999,999  HEADING 'Num. of Extents'  ENTMAP off
COLUMN max_extents       FORMAT 999,999,999,999,999  HEADING 'Max Extents'      ENTMAP off

BREAK ON report ON owner

SELECT
    '<div nowrap align="left"><font color="#336699"><b>' || ds.owner || '</b></font></div>'    owner
  , ds.tablespace_name    tablespace_name
  , ds.segment_name       segment_name
  , ds.segment_type       segment_type
  , ds.next_extent        next_extent
  , NVL(dfs.max, 0)       max
  , NVL(dfs.sum, 0)       sum
  , ds.extents            extents
  , ds.max_extents        max_extents
FROM 
    dba_segments ds
  , (select
         max(bytes) max
       , sum(bytes) sum
       , tablespace_name
     from
         dba_free_space 
     group by
         tablespace_name
    ) dfs
WHERE
      (ds.next_extent > nvl(dfs.max, 0)
       OR
       ds.extents >= ds.max_extents)
  AND ds.tablespace_name = dfs.tablespace_name (+)
  AND ds.owner NOT IN ('SYS','SYSTEM')
ORDER BY
    ds.owner
  , ds.tablespace_name
  , ds.segment_name;
 
 
-- +----------------------------------------------------------------------------+
-- |               - OBJECTS WHICH ARE NEARING MAXEXTENTS -                     |
-- +----------------------------------------------------------------------------+
host echo Check Objects Which Are Nearing MAXEXTENTS...
prompt <a name="objects_which_are_nearing_maxextents"></a>
prompt <font size="+2" face="Arial,Helvetica,Geneva,sans-serif" color="#336699"><b>Objects Which Are Nearing MAXEXTENTS</b></font> 

prompt <b>Segments where number of EXTENTS is less than 1/2 of MAXEXTENTS</b>

CLEAR COLUMNS BREAKS COMPUTES

COLUMN owner             FORMAT a75                   HEADING 'Owner'             ENTMAP off
COLUMN tablespace_name   FORMAT a30                   HEADING 'Tablespace name'   ENTMAP off
COLUMN segment_name      FORMAT a30                   HEADING 'Segment Name'      ENTMAP off
COLUMN segment_type      FORMAT a20                   HEADING 'Segment Type'      ENTMAP off
COLUMN bytes             FORMAT 999,999,999,999,999   HEADING 'Size (in bytes)'   ENTMAP off
COLUMN next_extent       FORMAT 999,999,999,999,999   HEADING 'Next Extent Size'  ENTMAP off
COLUMN pct_increase                                   HEADING '% Increase'        ENTMAP off
COLUMN extents           FORMAT 999,999,999,999,999   HEADING 'Num. of Extents'   ENTMAP off
COLUMN max_extents       FORMAT 999,999,999,999,999   HEADING 'Max Extents'       ENTMAP off
COLUMN pct_util          FORMAT a35                   HEADING '% Utilized'        ENTMAP off

SELECT
    owner
  , tablespace_name
  , segment_name
  , segment_type
  , bytes
  , next_extent
  , pct_increase
  , extents
  , max_extents
  , '<div align="right">' || ROUND((extents/max_extents)*100, 2) || '%</div>'   pct_util
FROM
    dba_segments
WHERE
      extents > max_extents/2
  AND max_extents != 0
ORDER BY
    (extents/max_extents) DESC;

host echo Check Directory ...
prompt <a name="dba_directories"></a>
prompt <font size="+2" face="Arial,Helvetica,Geneva,sans-serif" color="#336699"><b>Directories</b></font> 

CLEAR COLUMNS BREAKS COMPUTES

COLUMN owner             FORMAT a75  HEADING 'Owner'             ENTMAP off
COLUMN directory_name    FORMAT a75  HEADING 'Directory Name'    ENTMAP off
COLUMN directory_path                HEADING 'Directory Path'    ENTMAP off

BREAK ON report ON owner

SELECT
   *
FROM
    dba_directories
ORDER BY
    owner
  , directory_name;
  
prompt <a name="dba_types"></a>
prompt <font size="+2" face="Arial,Helvetica,Geneva,sans-serif" color="#336699"><b>Types</b></font> 
prompt <b>Excluding all internal system schemas (i.e. CTXSYS, MDSYS, SYS, SYSTEM)</b>

CLEAR COLUMNS BREAKS COMPUTES

COLUMN owner              FORMAT a75        HEADING 'Owner'              ENTMAP off
COLUMN type_name          FORMAT a75        HEADING 'Type Name'          ENTMAP off
COLUMN typecode           FORMAT a75        HEADING 'Type Code'          ENTMAP off
COLUMN attributes         FORMAT a75        HEADING 'Num. Attributes'    ENTMAP off
COLUMN methods            FORMAT a75        HEADING 'Num. Methods'       ENTMAP off
COLUMN predefined         FORMAT a75        HEADING 'Predefined?'        ENTMAP off
COLUMN incomplete         FORMAT a75        HEADING 'Incomplete?'        ENTMAP off
COLUMN final              FORMAT a75        HEADING 'Final?'             ENTMAP off
COLUMN instantiable       FORMAT a75        HEADING 'Instantiable?'      ENTMAP off
COLUMN supertype_owner    FORMAT a75        HEADING 'Super Owner'        ENTMAP off
COLUMN supertype_name     FORMAT a75        HEADING 'Super Name'         ENTMAP off
COLUMN local_attributes   FORMAT a75        HEADING 'Local Attributes'   ENTMAP off
COLUMN local_methods      FORMAT a75        HEADING 'Local Methods'      ENTMAP off

BREAK ON report ON owner

SELECT
    '<div nowrap align="left"><font color="#336699"><b>' || t.owner || '</b></font></div>'    owner
  , '<div nowrap>'                || t.type_name                                          || '</div>'   type_name
  , '<div nowrap>'                || t.typecode                                           || '</div>'   typecode
  , '<div nowrap align="right">'  || TO_CHAR(t.attributes, '999,999')                     || '</div>'   attributes
  , '<div nowrap align="right">'  || TO_CHAR(t.methods, '999,999')                        || '</div>'   methods
  , '<div nowrap align="center">' || t.predefined                                         || '</div>'   predefined
  , '<div nowrap align="center">' || t.incomplete                                         || '</div>'   incomplete
  , '<div nowrap align="center">' || t.final                                              || '</div>'   final
  , '<div nowrap align="center">' || t.instantiable                                       || '</div>'   instantiable
  , '<div nowrap align="left">'   || NVL(t.supertype_owner, '')                       || '</div>'   supertype_owner
  , '<div nowrap align="left">'   || NVL(t.supertype_name, '')                        || '</div>'   supertype_name
  , '<div nowrap align="right">'  || NVL(TO_CHAR(t.local_attributes, '999,999'), '')  || '</div>'   local_attributes
  , '<div nowrap align="right">'  || NVL(TO_CHAR(t.local_methods, '999,999'), '')     || '</div>'   local_methods
FROM
    dba_types  t
WHERE
    t.owner NOT IN (    'CTXSYS'
                      , 'DBSNMP'
                      , 'DMSYS'
                      , 'EXFSYS'
                      , 'IX'
                      , 'LBACSYS'
                      , 'MDSYS'
                      , 'OLAPSYS'
                      , 'ORDSYS'
                      , 'OUTLN'
                      , 'SYS'
                      , 'SYSMAN'
                      , 'SYSTEM'
                      , 'WKSYS'
                      , 'WMSYS'
                      , 'XDB'
                      , 'DVSYS'
					  , 'GSMADMIN_INTERNAL')
ORDER BY
    t.owner
  , t.type_name;
  
host echo Check LOB Segments ...
prompt <a name="dba_lob_segments"></a>
prompt <font size="+2" face="Arial,Helvetica,Geneva,sans-serif" color="#336699"><b>LOB Segments</b></font> 
prompt <b>Excluding all internal system schemas (i.e. CTXSYS, MDSYS, SYS, SYSTEM)</b>

CLEAR COLUMNS BREAKS COMPUTES

COLUMN owner              FORMAT a85        HEADING 'Owner'              ENTMAP off
COLUMN table_name         FORMAT a75        HEADING 'Table Name'         ENTMAP off
COLUMN column_name        FORMAT a75        HEADING 'Column Name'        ENTMAP off
COLUMN segment_name       FORMAT a125       HEADING 'LOB Segment Name'   ENTMAP off
COLUMN tablespace_name    FORMAT a75        HEADING 'Tablespace Name'    ENTMAP off
COLUMN lob_segment_bytes  FORMAT a75        HEADING 'Segment Size'       ENTMAP off
COLUMN index_name         FORMAT a125       HEADING 'LOB Index Name'     ENTMAP off
COLUMN in_row             FORMAT a75        HEADING 'In Row?'            ENTMAP off

BREAK ON report ON owner ON table_name

SELECT
    '<div nowrap align="left"><font color="#336699"><b>' || l.owner || '</b></font></div>'    owner
  , '<div nowrap>' || l.table_name        || '</div>'       table_name
  , '<div nowrap>' || l.column_name       || '</div>'       column_name
  , '<div nowrap>' || l.segment_name      || '</div>'       segment_name
  , '<div nowrap>' || s.tablespace_name   || '</div>'       tablespace_name
  , '<div nowrap align="right">' || TO_CHAR(s.bytes, '999,999,999,999,999') || '</div>'  lob_segment_bytes
  , '<div nowrap>' || l.index_name        || '</div>'       index_name
  , DECODE(   l.in_row
            , 'YES'
            , '<div align="center"><font color="darkgreen"><b>' || l.in_row || '</b></font></div>'
            , 'NO'
            , '<div align="center"><font color="#990000"><b>'   || l.in_row || '</b></font></div>'
            , '<div align="center"><font color="#663300"><b>'   || l.in_row || '</b></font></div>')   in_row
FROM
    dba_lobs     l
  , dba_segments s
WHERE
      l.owner = s.owner
  AND l.segment_name = s.segment_name
  AND l.owner NOT IN (    'CTXSYS'
                        , 'DBSNMP'
                        , 'DMSYS'
                        , 'EXFSYS'
                        , 'IX'
                        , 'LBACSYS'
                        , 'MDSYS'
                        , 'OLAPSYS'
                        , 'ORDSYS'
                        , 'OUTLN'
                        , 'SYS'
                        , 'SYSMAN'
                        , 'SYSTEM'
                        , 'WKSYS'
                        , 'WMSYS'
                        , 'XDB'
						, 'AUDSYS')
ORDER BY
    l.owner
  , l.table_name
  , l.column_name;
 
 
host echo Check materialized view ...
prompt <a name="dba_olap_materialized_views"></a>
prompt <font size="+2" face="Arial,Helvetica,Geneva,sans-serif" color="#336699"><b>Materialized Views</b></font> 

CLEAR COLUMNS BREAKS COMPUTES



COLUMN owner                FORMAT a75     HEADING 'Owner'               ENTMAP off
COLUMN mview_name           FORMAT a75     HEADING 'MView|Name'          ENTMAP off
COLUMN master_link          FORMAT a75     HEADING 'Master|Link'         ENTMAP off
COLUMN updatable            FORMAT a75     HEADING 'Updatable?'          ENTMAP off
COLUMN update_log           FORMAT a75     HEADING 'Update|Log'          ENTMAP off
COLUMN rewrite_enabled      FORMAT a75     HEADING 'Rewrite|Enabled?'    ENTMAP off
COLUMN refresh_mode         FORMAT a75     HEADING 'Refresh|Mode'        ENTMAP off
COLUMN refresh_method       FORMAT a75     HEADING 'Refresh|Method'      ENTMAP off
COLUMN build_mode           FORMAT a75     HEADING 'Build|Mode'          ENTMAP off
COLUMN fast_refreshable     FORMAT a75     HEADING 'Fast|Refreshable'    ENTMAP off
COLUMN last_refresh_type    FORMAT a75     HEADING 'Last Refresh|Type'   ENTMAP off
COLUMN last_refresh_date    FORMAT a75     HEADING 'Last Refresh|Date'   ENTMAP off
COLUMN staleness            FORMAT a75     HEADING 'Staleness'           ENTMAP off
COLUMN compile_state        FORMAT a75     HEADING 'Compile State'       ENTMAP off

BREAK ON owner

SELECT
    '<div align="left"><font color="#336699"><b>' || m.owner || '</b></font></div>'                    owner
  , m.mview_name                                                                                       mview_name
  , m.master_link                                                                                      master_link
  , '<div align="center">' || NVL(m.updatable,'<br>')        || '</div>'                               updatable
  , update_log                                                                                         update_log
  , '<div align="center">' || NVL(m.rewrite_enabled,'<br>')  || '</div>'                               rewrite_enabled
  , m.refresh_mode                                                                                     refresh_mode
  , m.refresh_method                                                                                   refresh_method
  , m.build_mode                                                                                       build_mode
  , m.fast_refreshable                                                                                 fast_refreshable
  , m.last_refresh_type                                                                                last_refresh_type
  , '<div nowrap align="right">' || TO_CHAR(m.last_refresh_date, 'mm/dd/yyyy HH24:MI:SS') || '</div>'  last_refresh_date
  , m.staleness                                                                                        staleness
  , DECODE(   m.compile_state
            , 'VALID'
            , '<div align="center"><font color="darkgreen"><b>' || m.compile_state || '</b></font></div>'
            , '<div align="center"><font color="#990000"><b>'   || m.compile_state || '</b></font></div>' ) compile_state
FROM
  dba_mviews     m 
ORDER BY
    owner
  , mview_name
/

prompt CDB Mviews

clear columns breaks computes
select c.con_id,
       c.name container,
       m.owner,
       m.name,
       m.mview_site,
       m.can_use_log,
       m.updatable,
       m.refresh_method,
       m.version
  from cdb_registered_mviews m, cdb_users u, v$containers c
 where m.owner = u.username
   and m.con_id = u.con_id
   and u.con_id = c.con_id
   and u.oracle_maintained = 'N'
 order by 1, 3, 4;
-- +----------------------------------------------------------------------------+
-- |                        - MATERIALIZED VIEW LOGS -                          |
-- +----------------------------------------------------------------------------+

prompt <a name="dba_olap_materialized_view_logs"></a>
prompt <font size="+2" face="Arial,Helvetica,Geneva,sans-serif" color="#336699"><b>Materialized View Logs</b></font> 

CLEAR COLUMNS BREAKS COMPUTES

COLUMN log_owner            FORMAT a75     HEADING 'Log Owner'            ENTMAP off
COLUMN log_table            FORMAT a75     HEADING 'Log Table'            ENTMAP off
COLUMN master               FORMAT a75     HEADING 'Master'               ENTMAP off
COLUMN log_trigger          FORMAT a75     HEADING 'Log Trigger'          ENTMAP off
COLUMN rowids               FORMAT a75     HEADING 'Rowids?'              ENTMAP off
COLUMN primary_key          FORMAT a75     HEADING 'Primary Key?'         ENTMAP off
COLUMN object_id            FORMAT a75     HEADING 'Object ID?'           ENTMAP off
COLUMN filter_columns       FORMAT a75     HEADING 'Filter Columns?'      ENTMAP off
COLUMN sequence             FORMAT a75     HEADING 'Sequence?'            ENTMAP off
COLUMN include_new_values   FORMAT a75     HEADING 'Include New Values?'  ENTMAP off

BREAK ON log_owner

SELECT
    '<div align="left"><font color="#336699"><b>' || ml.log_owner || '</b></font></div>'       log_owner
  , ml.log_table                                                              log_table
  , ml.master                                                                 master
  , ml.log_trigger                                                            log_trigger
  , '<div align="center">' || NVL(ml.rowids,'<br>')              || '</div>'  rowids
  , '<div align="center">' || NVL(ml.primary_key,'<br>')         || '</div>'  primary_key
  , '<div align="center">' || NVL(ml.object_id,'<br>')           || '</div>'  object_id
  , '<div align="center">' || NVL(ml.filter_columns,'<br>')      || '</div>'  filter_columns
  , '<div align="center">' || NVL(ml.sequence,'<br>')            || '</div>'  sequence
  , '<div align="center">' || NVL(ml.include_new_values,'<br>')  || '</div>'  include_new_values
FROM
    dba_mview_logs  ml
ORDER BY
    ml.log_owner
  , ml.master;

prompt <a name="dba_olap_materialized_view_refresh_groups"></a>
prompt <font size="+2" face="Arial,Helvetica,Geneva,sans-serif" color="#336699"><b>Materialized View Refresh Groups</b></font> 

CLEAR COLUMNS BREAKS COMPUTES

COLUMN owner         FORMAT a75   HEADING 'Owner'        ENTMAP off
COLUMN name          FORMAT a75   HEADING 'Name'         ENTMAP off
COLUMN broken        FORMAT a75   HEADING 'Broken?'      ENTMAP off
COLUMN next_date     FORMAT a75   HEADING 'Next Date'    ENTMAP off
COLUMN interval      FORMAT a75   HEADING 'Interval'     ENTMAP off

BREAK ON report ON owner

SELECT
    '<div nowrap align="left"><font color="#336699"><b>' || rowner   || '</b></font></div>'  owner
  , '<div align="left">'                                 || rname    || '</div>'             name
  , '<div align="center">'                               || broken   || '</div>'             broken
  , '<div nowrap align="right">'                         || NVL(TO_CHAR(next_date, 'mm/dd/yyyy HH24:MI:SS'), '<br>') || '</div>'   next_date
  , '<div nowrap align="right">'                         || interval || '</div>'             interval
FROM
    dba_refresh 
ORDER BY
    rowner
  , rname
/

 
host echo Check DB Users / Schemas...
prompt <a name="users"></a>

prompt <font size="2pt"><b>User Information</b></font>

prompt <font size="+2" face="Arial,Helvetica,Geneva,sans-serif" color="#336699"><b>Database Users Activities</b></font>
col pdb_name for a15
col username format a20;
col profile format a10;
col default_ts# format a18;
col temp_ts# format a10;
col created format a12;
Select username, account_status , TO_CHAR(created, 'yyyy-mm-dd') created, profile, 
default_tablespace default_ts#, temporary_tablespace temp_ts#, TO_CHAR(EXPIRY_DATE, 'yyyy-mm-dd') EXPIRY_DATE, TO_CHAR(LOCK_DATE, 'yyyy-mm-dd') LOCK_DATE from dba_users
order by created,1;


clear columns breaks computes

column container                   format a12  heading 'Container'
column username                    format a30  heading 'Username'
column account_status              format a16  heading 'Account|Status'
column default_tablespace          format a18  heading 'Default|Tablespace'
column temporary_tablespace        format a15  heading 'Temporary|Tablespace'
column local_temp_tablespace       format a15  heading 'Local Temp|Tablespace'
column profile                     format a20  heading 'Profile'
column initial_rsrc_consumer_group format a20  heading 'Initial Rsrc|Consumer Group'
column password_versions           format a10  heading 'Password|Versions'
column created                     format a19  heading 'Created'
column expiry_date                 format a19  heading 'Expire Date'
column lock_date                   format a19  heading 'Lock Date'
column oracle_maintained           format a10  heading 'ORACLE|Maintained'
 
select c.con_id,
       c.name container,
       u.username,
       u.account_status,
       u.default_tablespace,
       u.temporary_tablespace,
       u.local_temp_tablespace,
       u.profile,
       u.initial_rsrc_consumer_group,
       u.password_versions,
       u.created,
       u.lock_date,
       u.expiry_date,
	   u.oracle_maintained
  from cdb_users u, v$containers c
 where u.con_id = c.con_id
 order by 1, 4 desc;
 
prompt <a name="users_with_default_tablespace_defined_as_system"></a>
prompt <font size="+2" face="Arial,Helvetica,Geneva,sans-serif" color="#336699"><b>Users With Default Tablespace - (SYSTEM)</b></font>

CLEAR COLUMNS BREAKS COMPUTES

COLUMN username                 FORMAT a75    HEADING 'Username'                ENTMAP off
COLUMN default_tablespace       FORMAT a125   HEADING 'Default Tablespace'      ENTMAP off
COLUMN temporary_tablespace     FORMAT a125   HEADING 'Temporary Tablespace'    ENTMAP off
COLUMN created                  FORMAT a75    HEADING 'Created'                 ENTMAP off
COLUMN account_status           FORMAT a75    HEADING 'Account Status'          ENTMAP off

SELECT
    '<font color="#336699"><b>' || username             || '</font></b>'                  username
  , '<div align="left">'        || default_tablespace   || '</div>'                       default_tablespace
  , '<div align="left">'        || temporary_tablespace || '</div>'                       temporary_tablespace
  , '<div align="right">'       || TO_CHAR(created, 'mm/dd/yyyy HH24:MI:SS') || '</div>'  created
  , DECODE(   account_status
            , 'OPEN'
            , '<div align="center"><b><font color="darkgreen">' || account_status || '</font></b></div>'
            , '<div align="center"><b><font color="#663300">'   || account_status || '</font></b></div>') account_status
FROM
    dba_users
WHERE
    default_tablespace = 'SYSTEM'
ORDER BY
    username;

host echo Check DB Temporary TBS...
prompt <a name="users_with_default_temporary_tablespace_as_system"></a>
prompt <font size="+2" face="Arial,Helvetica,Geneva,sans-serif" color="#336699"><b>Users With Default Temporary Tablespace - (SYSTEM)</b></font>

CLEAR COLUMNS BREAKS COMPUTES

COLUMN username                 FORMAT a75    HEADING 'Username'                ENTMAP off
COLUMN default_tablespace       FORMAT a125   HEADING 'Default Tablespace'      ENTMAP off
COLUMN temporary_tablespace     FORMAT a125   HEADING 'Temporary Tablespace'    ENTMAP off
COLUMN created                  FORMAT a75    HEADING 'Created'                 ENTMAP off
COLUMN account_status           FORMAT a75    HEADING 'Account Status'          ENTMAP off

SELECT
    '<font color="#336699"><b>'  || username             || '</font></b>'                  username
  , '<div align="center">'       || default_tablespace   || '</div>'                       default_tablespace
  , '<div align="center">'       || temporary_tablespace || '</div>'                       temporary_tablespace
  , '<div align="right">'        || TO_CHAR(created, 'mm/dd/yyyy HH24:MI:SS') || '</div>'  created
  , DECODE(   account_status
            , 'OPEN'
            , '<div align="center"><b><font color="darkgreen">' || account_status || '</font></b></div>'
            , '<div align="center"><b><font color="#663300">'   || account_status || '</font></b></div>') account_status
FROM
    dba_users
WHERE
    temporary_tablespace = 'SYSTEM'
ORDER BY
    username;
	
prompt <a name="user_profile"></a>
prompt
prompt <font size="+2" face="Arial,Helvetica,Geneva,sans-serif" color="#336699"><b>Database Profiles</b></font>
select  * from dba_profiles;

column container     format a12 heading 'Container'
column profile       format a20 heading 'Profile'
column resource_name format a50 heading 'Resource Name'
column resource_type format a30 heading 'Resource Type'
column limit         format a30 heading 'Limit'
 
select c.con_id,
       c.name container,
       p.profile,
       p.resource_name,
       p.resource_type,
       p.limit
  from cdb_profiles p, v$containers c
 where p.con_id = c.con_id
 order by 1,3;
 

prompt <a name="2pc_tx"></a>
prompt
prompt <font size="+2" face="Arial,Helvetica,Geneva,sans-serif" color="#336699"><b>Two phase commit pending Transactions</b></font>

select 
 LOCAL_TRAN_ID "Local Tran ID",
 GLOBAL_TRAN_ID "Global Tran ID",
 STATE "State",
 MIXED "Mixed",
 ADVICE "Advice",
 TRAN_COMMENT "Comment",
 FAIL_TIME "Fail Time",
 FORCE_TIME "Force Time",
 RETRY_TIME "Retry Time",
 OS_USER "OS User",
 OS_TERMINAL "OS Terminal",
 HOST "Host",
 DB_USER "DB User",
 COMMIT# "Commit#"
from
 dba_2pc_pending order by LOCAL_TRAN_ID, GLOBAL_TRAN_ID
/

host echo Check DB JOBS/ SCHEDULE...
prompt <a name="JOBS"></a>
prompt
prompt <font size="+2" face="Arial,Helvetica,Geneva,sans-serif" color="#336699"><b>Database Jobs of Failed</b></font>
select 
  schema_user,
    what,
    TO_CHAR(last_date,'yyyy-mm-dd hh24:mi:ss') last_date,
    TO_CHAR(next_date,'yyyy-mm-dd hh24:mi:ss') next_date,
    trunc(total_time) run_secs,
    interval,
    broken||'' broken,
    failures,
    NULL issys
FROM
    dba_jobs where Broken='Y' OR FAILURES>1
UNION ALL
SELECT
    owner,
    program_name
    || job_action,
    TO_CHAR(last_start_date,'yyyy-mm-dd hh24:mi:ss') last_date,
    TO_CHAR(next_run_date,'yyyy-mm-dd hh24:mi:ss') next_date,
    trunc(EXTRACT(SECOND FROM last_run_duration) ) run_secs,
     nvl(repeat_interval,schedule_name),
    state, 
    failure_count,
    system
FROM
    dba_scheduler_jobs  where enabled='TRUE' and failure_count>0
    order by last_date,1;

prompt <font size="+1" face="Arial,Helvetica,Geneva,sans-serif" color="#336699"><b>CDB Jobs</b></font>

host echo Check jobs info ...

clear columns breaks computes

column job        format 999999  heading 'Job ID'
column log_user   format a30     heading 'Log User'
column what       format a150    heading 'What'
column next_date  format a19     heading 'Next Date'
column interval   format a10     heading 'Interval'
column last_date  format a19     heading 'Last Date'
column failures   format 999999  heading 'Failures'
column broken     format a6      heading 'Broken'

select c.con_id,
       c.name container,
       j.job,
       j.log_user,
       j.what,
       j.next_date,
       j.interval,
       j.last_date,
       j.failures,
       j.broken
  from cdb_jobs j, v$containers c
 where j.con_id = c.con_id
 order by job;
prompt <font size="+1" face="Arial,Helvetica,Geneva,sans-serif" color="#336699"><b>CDB SCHEDULE</b></font>
 column owner           format a30 heading 'Owner'
column job_name        format a30 heading 'Job Name'
column schedule_name   format a30 heading 'Schedule Name'
column start_date      format a50 heading 'Start Date'
column repeat_interval format a70 heading 'Repeat Interval'
column enabled         format a15 heading 'Enable'
column state           format a15 heading 'State'
 

select c.con_id,
       c.name container,
       j.owner,
       j.job_name,
       j.schedule_name,
       j.start_date,
       j.end_date,
       j.repeat_interval,
       j.enabled,
       j.state,
       j.stop_on_window_close
  from cdb_scheduler_jobs j, v$containers c
 where j.con_id = c.con_id
 order by 1, 3;


prompt <a name="TASK"></a>
prompt
prompt <font size="+2" face="Arial,Helvetica,Geneva,sans-serif" color="#336699"><b>Database 11g+ Auto Task</b></font>
--select client_name,status from dba_autotask_client;
SELECT C.CNAME_KETCL,
DECODE(dbms_auto_task.get_client_status_override(CR.CLIENT_ID),
1, 'DISABLED',
decode(CR.STATUS, 2, 'ENABLED',  1, 'DISABLED', 'INVALID'))
AS STATUS  FROM X$KETCL C, KET$_CLIENT_CONFIG CR
WHERE C.CID_KETCL = CR.CLIENT_ID
AND CR.OPERATION_ID = 0
AND C.CID_KETCL > 0
AND (BITAND(C.ATTR_KETCL,2048) = 0
OR 999999 < (SELECT TO_NUMBER(VALUE)
FROM V$SYSTEM_PARAMETER
WHERE NAME = '_automatic_maintenance_test'));

prompt <font size="+1" face="Arial,Helvetica,Geneva,sans-serif" color="#336699"><b>Schedules Window Interval</b></font>
select window_name,autotask_status from DBA_AUTOTASK_WINDOW_CLIENTS;

select c.con_id,
       c.name container,
       b.window_group_name,
       a.window_name,
       a.repeat_interval,
       a.next_start_date,
       a.duration
  from cdb_scheduler_windows          a,
       cdb_scheduler_wingroup_members b,
       v$containers                   c
 where a.window_name = b.window_name
   and a.con_id = b.con_id
   and b.con_id = c.con_id
 order by 1;
 
prompt <a name="task_hist"></a>
prompt <font size="+1" face="Arial,Helvetica,Geneva,sans-serif" color="#336699"><b>Autotask Job History (3Days)</b></font>

host echo Check autotask job history ...

clear columns breaks computes

select j.client_name,
       j.window_name,
       j.window_start_time,
       j.window_duration,
       j.job_name,
       j.job_status,
       j.job_start_time,
       j.job_duration,
       j.job_error,
       j.job_info
  from dba_autotask_job_history j 
 where window_start_time>sysdate-3
 order by 1,2,job_start_time;
 
select c.name container,
       j.client_name,
       j.window_name,
       j.window_start_time,
       j.window_duration,
       j.job_name,
       j.job_status,
       j.job_start_time,
       j.job_duration,
       j.job_error,
       j.job_info
  from cdb_autotask_job_history j, v$containers c
 where j.con_id = c.con_id
 and window_start_time>sysdate-3
 order by 1,2,job_start_time;
 
host echo Check ASM...
prompt <a name="ASMDG"></a>
prompt
prompt <font size="+2" face="Arial,Helvetica,Geneva,sans-serif" color="#336699"><b>ASM GROUP Overview</b></font>
prompt 
  

COLUMN group_name             FORMAT a20           HEAD 'Disk Group|Name'
COLUMN sector_size            FORMAT 99,999        HEAD 'Sector|Size'
COLUMN block_size             FORMAT 99,999        HEAD 'Block|Size'
COLUMN allocation_unit_size   FORMAT 999,999,999   HEAD 'Allocation|Unit Size'
COLUMN state                  FORMAT a11           HEAD 'State'
COLUMN type                   FORMAT a6            HEAD 'Type'
COLUMN total_mb               FORMAT 999,999,999   HEAD 'Total Size (MB)'
COLUMN used_mb                FORMAT 999,999,999   HEAD 'Used Size (MB)'
COLUMN pct_used               FORMAT 999.99        HEAD 'Pct. Used'

break on report on disk_group_name skip 1

compute sum label "Grand Total: " of total_mb used_mb on report

select name diskgroup,
       decode(state,'DISMOUNTED','<div align="left"><font color="red">'||state||'</font></div>',state) state,
       type,
       sector_size,
       block_size,
       allocation_unit_size au_size,
       total_mb,
       free_mb,
       required_mirror_free_mb,
       decode(substr(usable_file_mb,1,1),'-','<div align="left"><font color="red">'||to_char(usable_file_mb)||'</font></div>',to_char(usable_file_mb)) usable_file_mb,
       decode(offline_disks,0,offline_disks,'<div align="left"><font color="red">'||offline_disks||'</font></div>') offline_disks
      ,voting_files
  from v$asm_diskgroup_stat
order by 1;

prompt <a name="ASMDISK"></a>
prompt
prompt <font size="+2" face="Arial,Helvetica,Geneva,sans-serif" color="#336699"><b>ASM DISK Overview</b></font>
prompt ASM Disk Status
select a.name          diskgroup,
       b.name          disk_name,
       b.disk_number,
       b.path,
       b.header_status,
       decode(b.mode_status,'ONLINE',b.mode_status,'<div align="left"><font color="red">'||b.mode_status||'</font></div>') mode_status,
       b.total_mb,
       b.free_mb,
       b.failgroup
      ,b.voting_file
  from v$asm_diskgroup_stat a, v$asm_disk_stat b
 where a.group_number = b.group_number
order by 1;

prompt <a name="ASMattr"></a>
prompt
prompt <font size="+2" face="Arial,Helvetica,Geneva,sans-serif" color="#336699"><b>ASM Attribute</b></font>
prompt  ASM diskgroup attributes information
SELECT b.name diskgroup, a.name_kfenv attribute, a.value_kfenv value
  FROM x$kfenv a, v$asm_diskgroup b
 WHERE     a.group_kfenv = b.group_number
       AND a.name_kfenv IN ('au_size',
                            'sector_size',
                            'compaTle.asm',
                            'compaTle.rdbms',
                            'disk_repair_time',
                            '_rebalance_compact');

prompt ASM Imbalance information 
clear columns breaks computes

column "Diskgroup" format A30
column "Diskgroup"             heading "Diskgroup"
column "Imbalance" format 99.9 heading "Imbalance(%)"
column "Varience"  format 99.9 heading "Varience"
column "MinFree"   format 99.9 heading "Free(%)"
column "DiskCnt"   format 9999 heading "Disk Count"
column "Type"      format A10  heading "Redundancy"

select g.name "Diskgroup",
       100*(max((d.total_mb-d.free_mb + (128*g.allocation_unit_size/1048576))/(d.total_mb + (128*g.allocation_unit_size/1048576)))-min((d.total_mb-d.free_mb + (128*g.allocation_unit_size/1048576))/(d.total_mb + (128*g.allocation_unit_size/1048576))))/max((d.total_mb-d.free_mb + (128*g.allocation_unit_size/1048576))/(d.total_mb + (128*g.allocation_unit_size/1048576))) "Imbalance",
       100*(max(d.total_mb)-min(d.total_mb))/max(d.total_mb) "Varience",
       100*(min(d.free_mb/d.total_mb)) "MinFree",
       count(*) "DiskCnt",
       g.type "Type"
  from v$asm_disk d ,
       v$asm_diskgroup_stat g
 where d.group_number = g.group_number and
       d.group_number <> 0 and
       d.state = 'NORMAL' and
       d.mount_status = 'CACHED'
 group by g.name , g.type;

-- for non external diskgroup,external diskgroup will return null
column "PImbalance" format 99   heading "Partner|Count|Imbalance"
column "SImbalance" format 99.9 heading "Partner|Space %|Imbalance"
column "FailGrpCnt" format 9999 heading "Failgroup|Count"
column "Inactive"   format 9999 heading "Inactive|Partnership|Count"

select g.name "Diskgroup",
       max(p.cnt)-min(p.cnt) "PImbalance",
       100*(max(p.pspace)-min(p.pspace))/max(p.pspace) "SImbalance",
       count(distinct p.fgrp) "FailGrpCnt",
       sum(p.inactive)/2 "Inactive"
  from v$asm_diskgroup_stat g ,
       (select x.grp grp,x.disk disk,sum(x.active) cnt,greatest(sum(x.total_mb/d.total_mb),0.0001) pspace,d.failgroup fgrp,count(*)-sum(x.active) inactive
          from v$asm_disk d ,
              (select y.grp grp,y.disk disk,z.total_mb*y.active_kfdpartner total_mb,y.active_kfdpartner active
                 from x$kfdpartner y,v$asm_disk z
                where y.number_kfdpartner = z.disk_number and y.grp = z.group_number) x
         where d.group_number = x.grp and d.disk_number = x.disk and d.group_number <> 0 and d.state = 'NORMAL' and d.mount_status = 'CACHED'
         group by x.grp, x.disk, d.failgroup) p
 where g.group_number = p.grp
 group by g.name;


host echo Check DB Performance...
prompt
prompt <font size="+2" face="Arial,Helvetica,Geneva,sans-serif" color="#336699"><b> Oracle performance </b></font> 

prompt <a name="top_sql"></a>

prompt Top  20 elapsed time SQL from cache
col ELAPSED_TIME for 9999999999999999
col et_per_exec for 99999999999999
col sql_text for a100
SELECT sql_id,child_number,sql_text, elapsed_time, EXECUTIONS,et_per_exec
  FROM (SELECT sql_id, child_number, sql_text, elapsed_time, cpu_time,EXECUTIONS,elapsed_time/decode(EXECUTIONS,0,-1,EXECUTIONS) et_per_exec,
               disk_reads,
               RANK () OVER (ORDER BY elapsed_time DESC) AS elapsed_rank
          FROM v$sql)
 WHERE elapsed_rank <= 20;
 
prompt Top  20 buffer gets SQL from cache
SELECT * FROM
(SELECT sql_id,substr(sql_text,1,999) sql,
        buffer_gets, executions, round(buffer_gets/executions,2) "Gets/Exec",
        hash_value,address
   FROM V$SQLAREA
  WHERE buffer_gets > 10000
 ORDER BY buffer_gets DESC)
WHERE rownum <= 20
/

COL pct FOR A10 JUST RIGHT
COL cpu_pct FOR 999.9
COL io_pct FOR 999.9
COL topsql_proce_name FOR A30

BREAK ON day SKIP 1

DEF days=7

PROMPT Displaying daily top SQL for last &days days...

WITH ash AS (
    SELECT 
        day
      , owner
      , object_name
      , procedure_name
      , sql_id
      , sql_plan_hash_value
      , total_seconds
      , io_seconds
      , cpu_seconds
      , LPAD(TRIM(TO_CHAR(RATIO_TO_REPORT(total_seconds) OVER (PARTITION BY day) * 100, '999.9'))||'%', 10) pct
      , RATIO_TO_REPORT(total_seconds) OVER (PARTITION BY day) * 100 pct_num
    FROM (
        SELECT
            TO_CHAR(sample_time, 'YYYY-MM-DD') day
          , sql_id
          , sql_plan_hash_value 
          , p.owner
          , p.object_name
          , p.procedure_name
          , SUM(10) total_seconds
          , SUM(CASE WHEN wait_class = 'User I/O' THEN 10 ELSE 0 END) io_seconds
          , SUM(CASE WHEN wait_class IS NULL THEN 10 ELSE 0 END) cpu_seconds
        FROM
            dba_hist_active_sess_history a
          , dba_procedures p
        WHERE
            a.plsql_entry_object_id = p.object_id (+)
        AND a.plsql_entry_subprogram_id = p.subprogram_id (+)
        AND sample_time > SYSDATE - &days
        AND session_type != 'BACKGROUND' -- ignore for now
        GROUP BY
            sql_id
          , sql_plan_hash_value 
          , p.owner
          , p.object_name
          , p.procedure_name
          , TO_CHAR(sample_time, 'YYYY-MM-DD')
    )
)
, sqlstat AS (
    SELECT /*+ MATERIALIZE */ 
        TO_CHAR(begin_interval_time, 'YYYY-MM-DD') day
      , sql_id
      , plan_hash_value
      , SUM(executions_delta) executions
      , SUM(rows_processed_delta) rows_processed
      , SUM(disk_reads_delta) blocks_read
      , SUM(disk_reads_delta)*8/1024 mb_read
      , SUM(buffer_gets_delta) buffer_gets
      , SUM(iowait_delta)/1000000 awr_iowait_seconds
      , SUM(cpu_time_delta)/1000000 awr_cpu_seconds 
      , SUM(elapsed_time_delta)/1000000 awr_elapsed_seconds
    FROM
        dba_hist_snapshot
      NATURAL JOIN
        dba_hist_sqlstat
    WHERE
        begin_interval_time > SYSDATE - &days
    GROUP BY
        TO_CHAR(begin_interval_time, 'YYYY-MM-DD') 
      , sql_id
      , plan_hash_value
)
SELECT 
        day
      , pct
      , owner      
      , object_name||procedure_name    topsql_proc_name
      , sql_id
      , sql_plan_hash_value plan_hash
      , ROUND(total_seconds / 3600,1) total_hours
      , total_seconds
      , executions
      , ROUND(total_seconds / NULLIF(executions,0),2) sec_per_exec
      , io_pct
      , cpu_pct
      , mb_read
      , ROUND(mb_read / NULLIF(executions,0),2) mb_per_exec
      , buffer_gets
      , ROUND(buffer_gets / NULLIF(executions,0),2) gets_per_exec
FROM (
    SELECT
        day
      , pct
      , owner
      , object_name
      , procedure_name
      , sql_id
      , sql_plan_hash_value
      , total_seconds
      , io_seconds/total_seconds*100 io_pct
      , cpu_seconds/total_seconds*100 cpu_pct
      , (SELECT executions FROM sqlstat s  WHERE ash.sql_id = s.sql_id AND ash.sql_plan_hash_value = s.plan_hash_value AND ash.day = s.day) executions
      , (SELECT mb_read FROM sqlstat s     WHERE ash.sql_id = s.sql_id AND ash.sql_plan_hash_value = s.plan_hash_value AND ash.day = s.day) mb_read
      , (SELECT buffer_gets FROM sqlstat s WHERE ash.sql_id = s.sql_id AND ash.sql_plan_hash_value = s.plan_hash_value AND ash.day = s.day) buffer_gets
    FROM 
        ash
    WHERE 
        ash.pct_num >= 1
)
ORDER BY
    day DESC
  , total_seconds DESC
/

prompt <a name="nobind_sql"></a>
prompt
prompt Top 50 Literal SQL text:
col force_matching_signature for 9999999999999999999999
col cnt for 999999999
col rn for 99999
select * from (
select PARSING_SCHEMA_NAME,force_matching_signature, count(*) over(partition by force_matching_signature) cnt, sql_text, 
row_number() over(partition by force_matching_signature order by rownum) rn
  from v$sql
  where force_matching_signature > 0
  and PARSING_SCHEMA_NAME<>'SYS'
) where cnt>1000 and rn<=3
order by cnt desc ;

prompt <a name="high_version"></a>
prompt
prompt Top 50 High version count :
select * from (
select PARSING_SCHEMA_NAME,sql_id, sql_text, version_count,EXECUTIONS
  from v$sqlarea 
 where version_count > 200
 order by version_count desc)
 where rownum<=50;
 
 prompt <a name="full_scan"></a>
prompt
prompt Top 50 Full table scan caused by implicit conversion:
select * from 
(
select PARSING_SCHEMA_NAME,s.sql_id, s.sql_text, s.elapsed_time,s.EXECUTIONS
  from v$sqlarea s
 where s.sql_id in
       (select p.sql_id
          from v$sql_plan p
         where p.OPERATION = 'TABLE ACCESS'
           and p.OPTIONS = 'FULL'
           and p.FILTER_PREDICATES like '%INTERNAL_FUNCTION%')
		   and PARSING_SCHEMA_NAME not in('SYS')
		   order by elapsed_time desc)
		   where rownum<=50;
		   
COLUMN large_table_scans   FORMAT 999,999,999,999,999  HEADING 'Large Table Scans'   ENTMAP off
COLUMN small_table_scans   FORMAT 999,999,999,999,999  HEADING 'Small Table Scans'   ENTMAP off
COLUMN pct_large_scans                                 HEADING 'Pct. Large Scans'    ENTMAP off

SELECT
    a.value large_table_scans
  , b.value small_table_scans
  , '<div align="right">' || ROUND(100*a.value/DECODE((a.value+b.value),0,1,(a.value+b.value)),2) || '%</div>' pct_large_scans
FROM
    v$sysstat  a
  , v$sysstat  b
WHERE
      a.name = 'table scans (long tables)'
  AND b.name = 'table scans (short tables)';
  
prompt
prompt <a name="dyn_sample"></a>  
prompt Top 50 SQL with dynamic sampling
select PARSING_SCHEMA_NAME, s.sql_id,s.EXECUTIONS,s.sql_text
  from v$sqlarea s
 where s.sql_id in
       (select p.sql_id
          from v$sql_plan p
         where p.id = 1
           and p.other_xml like '%dynamic_sampling%') 
		 and PARSING_SCHEMA_NAME not in('SYS')
		 and rownum<=50 ;
prompt <a name="many_plan_sql"></a>
prompt Top 50 SQL with more than 3 execute plan
select sql_id,PARSING_SCHEMA_NAME, count(distinct plan_hash_value)
  from v$sql
 group by sql_id,PARSING_SCHEMA_NAME
having count(distinct plan_hash_value) > 3
/

host echo Check DB Security...
prompt
prompt <font size="+2" face="Arial,Helvetica,Geneva,sans-serif" color="#336699"><b> Security</b></font>
prompt <a name="Bitcoin"></a>
prompt Bitcoin ransomware object check
select decode(count(*),0,' Not found!','Warning! Discover suspicious objects') result
  from dba_objects
 where owner = 'SYS'
   and object_type in ('TRIGGER', 'PROCEDURE')
   AND object_name like 'DBMS_%_INTERNAL% ';
   
prompt <a name="dba_role_user"></a>
prompt
prompt  Database ROLES of  DBA 
select * from dba_role_privs start with granted_role='DBA' connect by prior grantee=granted_role;
prompt 
prompt <a name="sys_trigger"></a>
prompt Logon or Logoff Triggers	 
select OWNER,TRIGGER_NAME,TRIGGER_TYPE,TRIGGERING_EVENT,STATUS,TRIGGER_BODY from dba_triggers where TRIGGERING_EVENT like 'LOG%' and trigger_name<>'GSMLOGOFF';

host echo Check DB SCN...
prompt
prompt <a name="SCN"></a>
prompt <font size="+2" face="Arial,Helvetica,Geneva,sans-serif" color="#336699"><b> SCN Growth for last 24hour </b></font>
prompt   
SET NUMWIDTH 17
ALTER SESSION SET NLS_DATE_FORMAT='yyyy-mm-dd HH24:MI:SS';
SELECT TIM, GSCN,
 ROUND(RATE) rate_per_sec,
 ROUND((CHK16KSCN - GSCN)/24/3600/16/1024,1) "HEADROOM_DAY"
FROM
(
SELECT TIM, GSCN, RATE,
 ((
 ((TO_NUMBER(TO_CHAR(TIM,'YYYY'))-1988)*12*31*24*60*60) +
 ((TO_NUMBER(TO_CHAR(TIM,'MM'))-1)*31*24*60*60) +
 (((TO_NUMBER(TO_CHAR(TIM,'DD'))-1))*24*60*60) +
 (TO_NUMBER(TO_CHAR(TIM,'HH24'))*60*60) +
 (TO_NUMBER(TO_CHAR(TIM,'MI'))*60) +
 (TO_NUMBER(TO_CHAR(TIM,'SS')))
 ) * (16*1024)) CHK16KSCN
 FROM
 (
 SELECT FIRST_TIME TIM , FIRST_CHANGE# GSCN,
 ((NEXT_CHANGE#-FIRST_CHANGE#)/
 ((NEXT_TIME-FIRST_TIME)*24*60*60)) RATE
 FROM V$ARCHIVED_LOG
 WHERE dest_id=1 and (NEXT_TIME > FIRST_TIME) and FIRST_TIME>sysdate-1
)
)
ORDER BY 1,2;

prompt <p style="background: lightgoldenrodyellow;">

DECLARE
    rsl                NUMBER;
    headroom_in_scn    NUMBER;
    headroom_in_sec    NUMBER;
    cur_scn_compat     NUMBER;
    max_scn_compat     NUMBER;
    auto_rollover_ts   DATE;
    target_compat      NUMBER;
    is_enabled         BOOLEAN;
    version            VARCHAR2(100);
    is_hava_scn        BINARY_INTEGER;
    is_rolloverd       BOOLEAN;
    db_name            VARCHAR2(100);
    db_role            VARCHAR2(100);
    started_ts         DATE;
BEGIN
    SELECT
        banner
    INTO
        version
    FROM
        v$version
    WHERE
        ROWNUM = 1;

    SELECT
        database_role,
        name
    INTO
        db_role,db_name
    FROM
        v$database;

    SELECT
        startup_time
    INTO
        started_ts
    FROM
        v$instance;

    SELECT
        COUNT(*)
    INTO
        is_hava_scn
    FROM
        dba_objects
    WHERE
        owner = 'SYS'
        AND   object_name = 'DBMS_SCN'
        AND   object_type = 'PACKAGE BODY';

    dbms_output.put_line('Current datatime:'
    || TO_CHAR(SYSDATE,'RRRRmmdd hh24:mi:ss') );
    dbms_output.put_line('Oracle DBNAME:'
    || db_name);
    dbms_output.put_line('Oracle Version:'
    || version);
    dbms_output.put_line('Database role:'
    || db_role);
    dbms_output.put_line('Instance starttime: '
    || TO_CHAR(started_ts,'RRRRmmdd hh24:mi:ss') );
    IF
        is_hava_scn > 0
    THEN
        dbms_scn.getcurrentscnparams(rsl,headroom_in_scn,headroom_in_sec,cur_scn_compat,max_scn_compat);
        dbms_output.put_line('RSL='
        || rsl);
        dbms_output.put_line('headroom_in_scn='
        || headroom_in_scn);
        dbms_output.put_line('headroom_in_sec='
        || headroom_in_sec);
        dbms_output.put_line('CUR_SCN_COMPAT='
        || cur_scn_compat);
        dbms_output.put_line('MAX_SCN_COMPAT='
        || max_scn_compat);
        dbms_scn.getscnautorolloverparams(auto_rollover_ts,target_compat,is_enabled);
        dbms_output.put_line('auto_rollover_ts='
        || TO_CHAR(auto_rollover_ts,'YYYY-MM-DD') );
        dbms_output.put_line('target_compat='
        || target_compat);
        IF
            ( is_enabled )
        THEN
            dbms_output.put_line(' Auto_rollover is enabled!');
            IF
                cur_scn_compat = target_compat
            THEN
                dbms_output.put_line('SCN compat had Auto rollover !');
            END IF;
            IF
                cur_scn_compat < target_compat AND SYSDATE > auto_rollover_ts
            THEN
                dbms_output.put_line('SCN compat No Auto_rollover !');
	-- standby or read-only database 
                IF
                    started_ts < auto_rollover_ts AND db_role = 'PHYSICAL STANDBY'
                THEN
                    dbms_output.put_line('Tip: Restart Instance SCN compat will rollover automatic.');
                END IF;

            END IF;

        ELSE
            dbms_output.put_line(' Auto_rollover is disabled!');
        END IF;

    ELSE
        dbms_output.put_line('Error: the DBMS_SCN package not found!');
        dbms_output.put_line('CUR_SCN_COMPAT is default 1.');
    END IF;

END;
/

prompt </p>

prompt <a name="SCN_self"></a>
prompt
prompt Call to kcmgas
select dbid,instance_number,end_interval_time,
       snap_id,
       elapsed , 
	   stat_name,stat_value ,
	   trunc(stat_value/decode(elapsed,0,1,elapsed)) avg_scn_by_self_per_sec
	   from (
select to_char (dbid) dbid,
       instance_number,
       snap_id,
       elapsed,
       to_char (end_interval_time, 'YYYY-MM-DD HH24:MI') end_interval_time,
       stat_name,
       (case when stat_value > 0 then stat_value else 0 end) stat_value
  from (  select x.snap_id,
                 x.dbid,
                 x.instance_number,
                 trunc (sn.end_interval_time, 'MI') end_interval_time,
                 x.stat_name,
                 trunc ((cast (sn.end_interval_time as date) - cast (sn.begin_interval_time as date)) * 86400) as elapsed,
                 (x.value - lag ( x.value, 1, x.value) over (partition by x.dbid, x.instance_number order by x.snap_id)) as stat_value
            from dba_hist_sysstat x, dba_hist_snapshot sn
           where     x.snap_id = sn.snap_id
                 and x.dbid = sn.dbid
                 and x.instance_number = sn.instance_number
                 and x.stat_name = 'calls to kcmgas'
                 and cast (sn.begin_interval_time as date) > sysdate - 7
        order by instance_number, snap_id)
		);

prompt <font size="2pt">-
The V$SYSSTAT statistic "calls to kcmgas" gives a good indication of the intrinsic SCN growth rate of the local instance.<br/> -
Ideally we want the rate of change of this statistic per second so we can see if it seems high ( increasing at > 15k/sec ).<br/> -
The statistic is instance specific and so for RAC instances one should consider "high" as the worst case scenario of "(15k/sec) / number_of_active_instances" <br/> -
<br/>-
If "calls to kcmgas" growth smooth and have a high value each time,that means it is a inter-db consumption.<br/><br/>-
If "calls to kcmgas" growth smooth and have a low value each time,but the headroom steadily decreases over time,<br/>-
then it is likely due to frequent communication with some other database.<br/><br/> -
From v$archived_log analysis,if the rate growth smooth in most cases,but there is an obvious single large SCN jump,<br/>-
then it is likely due to frequent communication with some other database.-
</font>
 
prompt <a name="scn_params"></a>
prompt <font size="2pt"><b>SCN relation parameters</b></font>

host echo Check SCN related hidden parameter ...

select ksppinm name, ksppstvl value, ksppdesc description
  from x$ksppi x, x$ksppcv y
 where x.indx = y.indx
   and translate(ksppinm, '_', '#') like '#external_scn%';

host echo Check DB RMAN BACKUP...
prompt <a name="RMAN"></a>  
prompt <font size="+2" face="Arial,Helvetica,Geneva,sans-serif" color="#336699"><b>Rman Backup CHECK</b></font>

select * from v$rman_configuration;

prompt  check rman backup for the last 8 days
select  sid, row_type, operation, status, to_char(start_time,'dd-mm-yyyyhh24:mi:ss') start_time, to_char(end_time,'dd-mm-yyyy hh24:mi:ss') end_time ,OUTPUT_DEVICE_TYPE
from  v$rman_status where start_time>sysdate-8 order by start_time;

prompt <a name="rmandetail"></a>
prompt  check rman backup detail for the last 7 days
set lines 220
set pages 1000
col cf for 9,999
col df for 9,999
col elapsed_seconds heading "ELAPSED|SECONDS"
col i0 for 9,999
col i1 for 9,999
col l for 9,999
col output_mbytes for 9,999,999 heading "OUTPUT|MBYTES"
col session_recid for 999999 heading "SESSION|RECID"
col session_stamp for 99999999999 heading "SESSION|STAMP"
col status for a10 trunc
col time_taken_display for a10 heading "TIME|TAKEN"
col output_instance for 9999 heading "OUT|INST"
select
  j.session_recid, j.session_stamp,
  to_char(j.start_time, 'yyyy-mm-dd hh24:mi:ss') start_time,
  to_char(j.end_time, 'yyyy-mm-dd hh24:mi:ss') end_time,
  (j.output_bytes/1024/1024) output_mbytes, j.status, j.input_type,
  decode(to_char(j.start_time, 'd'), 1, 'Sunday', 2, 'Monday',
                                     3, 'Tuesday', 4, 'Wednesday',
                                     5, 'Thursday', 6, 'Friday',
                                     7, 'Saturday') dow,
  j.elapsed_seconds, j.time_taken_display,
  x.cf, x.df, x.i0, x.i1, x.l,
  ro.inst_id output_instance
from V$RMAN_BACKUP_JOB_DETAILS j
  left outer join (select
                     d.session_recid, d.session_stamp,
                     sum(case when d.controlfile_included = 'YES' then d.pieces else 0 end) CF,
                     sum(case when d.controlfile_included = 'NO'
                               and d.backup_type||d.incremental_level = 'D' then d.pieces else 0 end) DF,
                     sum(case when d.backup_type||d.incremental_level = 'D0' then d.pieces else 0 end) I0,
                     sum(case when d.backup_type||d.incremental_level = 'I1' then d.pieces else 0 end) I1,
                     sum(case when d.backup_type = 'L' then d.pieces else 0 end) L
                   from
                     V$BACKUP_SET_DETAILS d
                     join V$BACKUP_SET s on s.set_stamp = d.set_stamp and s.set_count = d.set_count
                   where s.input_file_scan_only = 'NO'
                   group by d.session_recid, d.session_stamp) x
    on x.session_recid = j.session_recid and x.session_stamp = j.session_stamp
  left outer join (select o.session_recid, o.session_stamp, min(inst_id) inst_id
                   from GV$RMAN_OUTPUT o
                   group by o.session_recid, o.session_stamp)
    ro on ro.session_recid = j.session_recid and ro.session_stamp = j.session_stamp
where j.start_time > trunc(sysdate)-7
order by j.start_time;


host echo Check DB AWR...
prompt <a name="awr"></a>
prompt
prompt <font size="+2" face="Arial,Helvetica,Geneva,sans-serif" color="#336699"><b>AWR Overview</b></font>
col container        for a15 heading 'Container'
col dbid                     heading 'DBID'
col snap_interval    for a25 heading 'Interval'
col retention        for a25  heading 'Retention'
col topnsql                  heading 'TopN SQL'

select c.name container,a.dbid,a.snap_interval,a.retention,a.topnsql
from cdb_hist_wr_control a, v$containers c
where a.dbid = c.dbid;

prompt <a name="awrgap"></a>
prompt AWR SNAPSHOT GAP
with t as (
select (select count(*) from dba_hist_snapshot a,dba_hist_wr_control b where instance_number=userenv('INSTANCE')
   and a.dbid=b.dbid and a.begin_interval_time>sysdate-b.snap_interval*24) as cnt1,
   (select count(*) from dba_hist_snapshot where instance_number=userenv('INSTANCE') and flush_elapsed> interval '5' MINUTE 
 and begin_interval_time>sysdate-1) as cnt2,
 (select count(*) from dba_hist_snapshot a,dba_hist_wr_control b where instance_number=userenv('INSTANCE')
   and a.dbid=b.dbid and a.begin_interval_time<sysdate-b.retention-1) cnt3 from dual)
select (select 'DB NAME: '||b.name ||CHR(10)||
'SNAP_INTERVAL: '||SNAP_INTERVAL||CHR(10)||
'RETENTION: '||RETENTION||CHR(10)||'----check-----'||chr(10) from dba_hist_wr_control a,v$database b where a.dbid=b.dbid)||
(case when cnt1<23 then 'last day not snap:'||chr(10) else '' end
||case when cnt2>0 then 'awr takes more than 5 minutes:'||cnt2||chr(10) else '' end
||case when cnt3>0 then 'awr snap over keep retention:'||cnt3||chr(10) else '' end) as checkret
 from t;
 
 prompt <a name="awr_baselines"></a>
prompt <font size="+2" face="Arial,Helvetica,Geneva,sans-serif" color="#336699"><b>AWR Baselines</b></font>

prompt Use the <b>DBMS_WORKLOAD_REPOSITORY.CREATE_BASELINE</b> procedure to create a named baseline.
prompt A baseline (also known as a preserved snapshot set) is a pair of AWR snapshots that represents a
prompt specific period of database usage. The Oracle database server will exempt the AWR snapshots 
prompt assigned to a specific baseline from the automated purge routine. The main purpose of a baseline
prompt is to preserve typical run-time statistics in the AWR repository which can then be compared to 
prompt current performance or similar periods in the past.

CLEAR COLUMNS BREAKS COMPUTES

COLUMN dbbid            FORMAT a75    HEAD 'Database ID'              ENTMAP off
COLUMN dbb_name         FORMAT a75    HEAD 'Database Name'            ENTMAP off
COLUMN baseline_id                    HEAD 'Baseline ID'              ENTMAP off
COLUMN baseline_name    FORMAT a75    HEAD 'Baseline Name'            ENTMAP off
COLUMN start_snap_id                  HEAD 'Beginning Snapshot ID'    ENTMAP off
COLUMN start_snap_time  FORMAT a75    HEAD 'Beginning Snapshot Time'  ENTMAP off
COLUMN end_snap_id                    HEAD 'Ending Snapshot ID'       ENTMAP off
COLUMN end_snap_time    FORMAT a75    HEAD 'Ending Snapshot Time'     ENTMAP off

SELECT
    '<div align="left"><font color="#336699"><b>' || b.dbid || '</b></font></div>'  dbbid
  , d.name                                                                          dbb_name
  , b.baseline_id                                                                   baseline_id
  , baseline_name                                                                   baseline_name
  , b.start_snap_id                                                                 start_snap_id
  , '<div nowrap align="right">' || TO_CHAR(b.start_snap_time, 'mm/dd/yyyy HH24:MI:SS')  || '</div>'  start_snap_time
  , b.end_snap_id                                                                   end_snap_id
  , '<div nowrap align="right">' || TO_CHAR(b.end_snap_time, 'mm/dd/yyyy HH24:MI:SS')  || '</div>'    end_snap_time
FROM
    dba_hist_baseline   b
  , v$database          d
WHERE
    b.dbid = d.dbid
ORDER BY
    dbbid
  , b.baseline_id;
  

 SELECT * FROM
(
SELECT
A.INSTANCE_NUMBER,
LAG(A.SNAP_ID) OVER (ORDER BY A.SNAP_ID) BEGIN_SNAP_ID,
A.SNAP_ID END_SNAP_ID,
TO_CHAR(B.BEGIN_INTERVAL_TIME,'DD-MON-YY HH24:MI') SNAP_BEGIN_TIME,
TO_CHAR(B.END_INTERVAL_TIME ,'DD-MON-YY HH24:MI') SNAP_END_TIME,
extract( day from((END_INTERVAL_TIME-BEGIN_INTERVAL_TIME))*24*60)  elapsed_time_min,
ROUND((A.VALUE-LAG(A.VALUE) OVER (ORDER BY A.SNAP_ID ))/1000000/60,2) DB_TIME_MIN
FROM
   DBA_HIST_SYS_TIME_MODEL A,
   DBA_HIST_SNAPSHOT       B
WHERE
A.SNAP_ID = B.SNAP_ID AND
A.INSTANCE_NUMBER = B.INSTANCE_NUMBER AND
A.STAT_NAME = 'DB time' 
and  B.END_INTERVAL_TIME >= SYSDATE-3
)
WHERE DB_TIME_MIN IS NOT NULL AND DB_TIME_MIN > 0
ORDER BY 1,2 DESC;


 COLUMN wait_class        FORMAT a20              HEADING 'WAIT_CLASS'
 COLUMN inst_id           FORMAT 99               HEADING 'INST_ID'          JUSTIFY right
 COLUMN BEGIN_TIME        FORMAT 9999999          HEADING 'BEGIN_TIME'         JUSTIFY left
 COLUMN end_time          FORMAT 9999999          HEADING 'END_TIME'             JUSTIFY left
 COLUMN dbtime_in_wait    FORMAT 9999.99          HEADING 'DBTIME_IN_WAIT'     JUSTIFY right
 COLUMN time_waited       FORMAT 9999999.99          HEADING 'TIME_WAITED'        JUSTIFY right

prompt <a name="wait_class"></a>
 select a.inst_id,b.wait_class ,a.inst_id ,a.begin_time ,
 a.end_time , a.dbtime_in_wait , a.time_waited from GV$WAITCLASSMETRIC a , gV$SYSTEM_WAIT_CLASS b where
 a.wait_class_id = b.wait_class_id
 and a.inst_id = b.inst_id
 --- and b.wait_class='Commit'
 order by 5 desc ;
 
 
prompt <a name="iowait3"></a>
prompt 
prompt Redo log file IO waits  for AWR last 3 days

prompt <a name="log_wait"></a>
col  total_waits for 999,999,999,000
SELECT
     CAST(begin_interval_time AS DATE) begin_time
	,instance_number
  , event_name
  , time_waited_micro
  , total_waits
  , total_timeouts
  , round(time_waited_micro/nullif(total_waits,0)*0.001,2) avg_wait_ms
FROM
    dba_hist_snapshot
NATURAL JOIN
    dba_hist_system_event
WHERE
    event_name IN ('log file sync', 'log file parallel write', 'ksfd: async disk IO') 
AND begin_interval_time > SYSDATE - 3
ORDER BY
instance_number
   , event_name
  , begin_time;


host echo Check DB DataGuard...
prompt <a name="dataguard"></a>
prompt   
prompt <font size="+2" face="Arial,Helvetica,Geneva,sans-serif" color="#336699"><b>DATAGUARD Params CHECK</b></font>

select database_name,database_role,force_logging from v$database;

show parameter standby
prompt <a name="dggap"></a>
prompt <font size="+2" face="Arial,Helvetica,Geneva,sans-serif" color="#336699"><b>DATAGUARD Gap</b></font>
select t.*,arched-applied gap,sysdate etime  from (select thread#,max(sequence#) arched, max(decode(applied,'YES',sequence#,1)) applied, max(decode(DELETED,'YES',sequence#,1)) DELETED from v$archived_log group by thread#) t;		 

prompt <a name="dgstat"></a>
prompt <font size="+2" face="Arial,Helvetica,Geneva,sans-serif" color="#336699"><b>DATAGUARD STAT</b></font>
select name,value,unit,time_computed from v$dataguard_stats; 

select process,pid,status,thread#,sequence#,delay_mins from v$managed_standby; 

select to_char(start_time,'yyyymmdd hh24:mi') start_time,type,item,units,total, to_char(timestamp,'yyyymmdd hh24:mi') timestap from v$recovery_progress; 

col dest_name for a30
select inst_id,dest_id,dest_name,status,type,recovery_mode, error from GV$ARCHIVE_DEST_STATUS where DESTINATION is not null; 


host echo Check DB RAC...
prompt <a name="RAC"></a>
prompt   
prompt   
prompt <font size="+2" face="Arial,Helvetica,Geneva,sans-serif" color="#336699"><b>Oracle RAC CHECK</b></font>



prompt  Check whether CPUs is the same between nodes
select INST_ID,COMMENTS,value from gv$osstat where osstat_id=0;
prompt <a name="pub_Network"></a>
prompt  Public Network traffic last 24 Hours
select INSTANCE_NUMBER,to_char(BEGIN_TIME,'yyyymmdd hh24:mi:ss') btime,METRIC_NAME, MAXVAL , AVERAGE, METRIC_UNIT from dba_hist_sysmetric_summary where metric_id=2058 and BEGIN_TIME> sysdate-1 order by 1;

prompt <a name="pri_Network"></a>
prompt  Interconect Network
SELECT * FROM gv$cluster_interconnects ORDER BY inst_id,name;

prompt <a name="interconnect_traffic"></a>
prompt Estd Interconnect traffic for RAC system last 48 Hours  ...

clear columns breaks computes
break on instance_number skip 1
col instance_number                       heading "Inst"

prompt <div style="overflow-x: auto; overflow-y: auto; min-height: 100px; max-height: 300px; width:%100px;">

col traffic heading "Estd Interconnect traffic (KB)"

select v1.instance_number, v1.snap_id,to_char(sn.begin_interval_time,'yyyymmdd hh24:mi:ss') btime,traffic from (
select instance_number, snap_id, round(sum(value) / 1024 / elapsed,2) traffic
  from (select instance_number,
               snap_id,
               elapsed,
               stat_name,
               case
                 when stat_name in ('gc cr blocks received',
                                    'gc cr blocks served',
                                    'gc current blocks received',
                                    'gc current blocks served') then
                  value * (select value from v$parameter where name = 'db_block_size')
                 else
                  value * 200
               end value
          from (select a.instance_number,
                       a.snap_id,
                       a.stat_name,
                       (cast(b.end_interval_time as date) -
                       cast(b.begin_interval_time as date)) * 24 * 60 * 60 elapsed,
                       value - lag(value) over(partition by a.instance_number, b.startup_time, a.stat_name order by a.snap_id) value
                  from dba_hist_sysstat a, dba_hist_snapshot b
                 where a.instance_number = b.instance_number
                   and a.snap_id = b.snap_id
                   and a.dbid = b.dbid
                   and b.begin_interval_time > sysdate - 2
                   and a.stat_name in ('gc cr blocks received',
                                       'gc cr blocks served',
                                       'gc current blocks received',
                                       'gc current blocks served',
                                       'gcs messages sent',
                                       'ges messages sent')
                union all
                select a.instance_number,
                       a.snap_id,
                       a.name,
                       (cast(b.end_interval_time as date) -
                       cast(b.begin_interval_time as date)) * 24 * 60 * 60 elapsed,
                       value - lag(value) over(partition by a.instance_number, b.startup_time, a.name order by a.snap_id) value
                  from dba_hist_dlm_misc a, dba_hist_snapshot b
                 where a.instance_number = b.instance_number
                   and a.snap_id = b.snap_id
                   and a.dbid = b.dbid
                   and b.begin_interval_time > sysdate - 2
                   and a.name in ('gcs msgs received', 'ges msgs received')))
 group by instance_number, snap_id, elapsed
 ) v1,dba_hist_snapshot sn where v1.instance_number=sn.instance_number and v1.snap_id=sn.snap_id
 order by 1, 2;
 
prompt </div>



clear columns breaks computes

break on instance_number skip 1

col instance_number                       heading "Inst"
 
col traffic heading "Estd Interconnect traffic (KB)"

select instance_number, snap_id, round(sum(value) / 1024 / elapsed,2) traffic
  from (select instance_number,
               snap_id,
               elapsed,
               stat_name,
               case
                 when stat_name in ('gc cr blocks received',
                                    'gc cr blocks served',
                                    'gc current blocks received',
                                    'gc current blocks served') then
                  value * (select value from v$parameter where name = 'db_block_size')
                 else
                  value * 200
               end value
          from (select a.instance_number,
                       a.snap_id,
                       a.stat_name,
                       (cast(b.end_interval_time as date) -
                       cast(b.begin_interval_time as date)) * 24 * 60 * 60 elapsed,
                       value - lag(value) over(partition by a.instance_number, b.startup_time, a.stat_name order by a.snap_id) value
                  from cdb_hist_sysstat a, cdb_hist_snapshot b
                 where a.instance_number = b.instance_number
                   and a.snap_id = b.snap_id
                   and a.dbid = b.dbid
                   and b.begin_interval_time > sysdate - 2
                   and a.stat_name in ('gc cr blocks received',
                                       'gc cr blocks served',
                                       'gc current blocks received',
                                       'gc current blocks served',
                                       'gcs messages sent',
                                       'ges messages sent')
                union all
                select a.instance_number,
                       a.snap_id,
                       a.name,
                       (cast(b.end_interval_time as date) -
                       cast(b.begin_interval_time as date)) * 24 * 60 * 60 elapsed,
                       value - lag(value) over(partition by a.instance_number, b.startup_time, a.name order by a.snap_id) value
                  from cdb_hist_dlm_misc a, cdb_hist_snapshot b
                 where a.instance_number = b.instance_number
                   and a.snap_id = b.snap_id
                   and a.dbid = b.dbid
                   and b.begin_interval_time > sysdate - 2
                   and a.name in ('gcs msgs received', 'ges msgs received')))
 group by instance_number, snap_id, elapsed
 order by 1, 2;

prompt <a name="gc_lost"></a>
prompt  GC blocks lost last 7 days
col begin_interval_time for a40
col end_interval_time for a40
select * from (
SELECT sn.instance_number,to_char(sn.begin_interval_time,'yyyymmdd hh24:mi:ss') begin_interval_time,
                to_char(sn.end_interval_time,'yyyymmdd hh24:mi:ss') end_interval_time,
                ss.stat_name stat_name,
                ss.VALUE e_value,
                LAG (ss.VALUE, 1)
                   OVER (PARTITION BY ss.instance_number,stat_name ORDER BY  ss.snap_id)
                   b_value ,
				 (ss.VALUE-LAG (ss.VALUE, 1)
                   OVER (PARTITION BY ss.instance_number,stat_name ORDER BY  ss.snap_id)) diff
               -- ,sn.snap_id
           FROM dba_hist_sysstat ss, dba_hist_snapshot sn
          WHERE     TRUNC (sn.begin_interval_time) = TRUNC (SYSDATE-7) --need modify
                AND ss.snap_id = sn.snap_id
                AND ss.dbid = sn.dbid
                AND ss.instance_number = sn.instance_number
                AND ss.dbid = (SELECT dbid FROM v$database)
                AND ss.stat_name IN ('gc blocks lost')
				) where diff>=1
				order by 1,2;

prompt <a name="GES"></a>
prompt 
prompt  GES info (GES_TRAFFIC_CONTROLLER) note tickets avalible
select * from GV$GES_TRAFFIC_CONTROLLER;
prompt  GES info (ges_statistics)
select * from v$ges_statistics where value>0;

prompt <a name="GCS"></a>
prompt GCS info (instance_cache_transfer)
SELECT instance ||'->' || inst_id transfer,
class,
cr_block cr_blk,
TRUNC(cr_block_time /decode(cr_block,0,-1,cr_block)/1000,2) avg_Cr,
current_block cur_blk,
TRUNC(current_block_time/current_block/1000,2) avg_cur_time
FROM gv$instance_cache_transfer
WHERE cr_block >0 AND current_block>0
ORDER BY instance, inst_id, class
/

prompt GCS requests info (cr_block_server)
SELECT inst_id,CR_REQUESTS cr, CURRENT_REQUESTS cur,DATA_REQUESTS data, UNDO_REQUESTS undo,TX_REQUESTS tx
FROM gv$cr_block_server;
prompt GCS info (current_block_server)
select * from  gv$current_block_server;

select /*+no_merge(v)*/ inst_id,cr_time,cr_block, round(cr_time / decode(cr_block,0,-1,cr_block),2)  "AVG CR BLOCK RECEIVE TIME(ms)"
from
(
select b1.inst_id, b2.value cr_time,b1.value cr_block
from gv$sysstat b1, gv$sysstat b2
where (b1.name = 'global cache cr block receive time' and
b2.name = 'global cache cr blocks received' and b1.inst_id = b2.inst_id)
or ( b1.name = 'gc cr block receive time' and b2.name = 'gc cr blocks received' and b1.inst_id = b2.inst_id )
) v;



select /*+no_merge(v)*/ inst_id,cur_time,cur_block, round(cur_time / decode(cur_block,0,-1,cur_block),2)  "AVG CUR BLOCK RECEIVE TIME(ms)"
from
(
select b1.inst_id, b2.value cur_time,b1.value cur_block
from gv$sysstat b1, gv$sysstat b2
where (b1.name = 'global cache current block receive time' and
b2.name = 'global cache current blocks received' and b1.inst_id = b2.inst_id)
or ( b1.name = 'gc current block receive time' and b2.name = 'gc current blocks received' and b1.inst_id = b2.inst_id )
) v;


 SELECT
DECODE(name,'gc cr blocks received','global cache blocks received','gc cr blocks served','global cache blocks served','gc current blocks received','global cache blocks received','gc current blocks served','global cache blocks served',name) AS name,
  SUM(VALUE) AS VALUE,
  TO_CHAR(SYSDATE,'yyyy-mm-dd hh24:mi:ss') AS date_taken
  FROM gv$sysstat
  WHERE inst_id=(select instance_number from v$instance)
  AND name IN ('gc cr blocks received','gc cr blocks served','gc current blocks received','gc current blocks served','gcs messages sent','ges messages sent')
  GROUP BY DECODE(name,'gc cr blocks received','global cache blocks received','gc cr blocks served','global cache blocks served','gc current blocks received','global cache blocks received','gc current blocks served','global cache blocks served',name)
  UNION
  SELECT name,VALUE,TO_CHAR(SYSDATE,'yyyy-mm-dd hh24:mi:ss') AS date_taken
  FROM gv$dlm_misc
  WHERE name IN ('gcs msgs received','ges msgs received')
  AND inst_id=(select instance_number from v$instance);

prompt Wait 10 Seconds for check Interconnect Traffic
exec dbms_lock.sleep(10);

 SELECT
DECODE(name,'gc cr blocks received','global cache blocks received','gc cr blocks served','global cache blocks served','gc current blocks received','global cache blocks received','gc current blocks served','global cache blocks served',name) AS name,
  SUM(VALUE) AS VALUE,
  TO_CHAR(SYSDATE,'yyyy-mm-dd hh24:mi:ss') AS date_taken
  FROM gv$sysstat
  WHERE inst_id=(select instance_number from v$instance)
  AND name IN ('gc cr blocks received','gc cr blocks served','gc current blocks received','gc current blocks served','gcs messages sent','ges messages sent')
  GROUP BY DECODE(name,'gc cr blocks received','global cache blocks received','gc cr blocks served','global cache blocks served','gc current blocks received','global cache blocks received','gc current blocks served','global cache blocks served',name)
  UNION
  SELECT name,VALUE,TO_CHAR(SYSDATE,'yyyy-mm-dd hh24:mi:ss') AS date_taken
  FROM gv$dlm_misc
  WHERE name IN ('gcs msgs received','ges msgs received')
  AND inst_id=(select instance_number from v$instance);
  
prompt Estd Interconnect traffic = ((Global Cache blocks received + Global Cache blocks served)*db_block_size +(GCS/GES messages received + GCS/GES messages sent)*200)/elapsed time
 
 
host echo Check DB Multitenant...
prompt <a name="Multitenant"></a>
prompt      
prompt <font size="+2" face="Arial,Helvetica,Geneva,sans-serif" color="#336699"><b>For Oracle 12c+  Multitenant</b></font>


 

prompt <a name="pdb_tablespace"></a> 
COL con_name        FORM A15 HEAD "Container|Name"
COL files           FORM 999,999 HEAD "Num Files"
COL tablespace_name FORM A30
COL fsm             FORM 999,999,999,999 HEAD "Free|Space Meg."
COL apm             FORM 999,999,999,999 HEAD "Alloc|Space Meg."

COMPUTE SUM OF fsm apm files ON con_id REPORT
BREAK ON REPORT ON con_id ON con_name ON tablespace_name
prompt tablespace information 
WITH x AS (SELECT c1.con_id, cf1.tablespace_name, SUM(cf1.bytes)/1024/1024 fsm
           FROM cdb_free_space cf1
               ,v$containers c1
           WHERE cf1.con_id = c1.con_id
           GROUP BY c1.con_id, cf1.tablespace_name),
     y AS (SELECT c2.con_id, cd.tablespace_name, count(*) files,SUM(cd.bytes)/1024/1024 apm
           FROM cdb_data_files cd
               ,v$containers c2
           WHERE cd.con_id = c2.con_id
           GROUP BY c2.con_id
                   ,cd.tablespace_name)
SELECT x.con_id, v.name  con_name, x.tablespace_name,files, x.fsm, y.apm, round(1-fsm/apm,2) pct
FROM x, y, v$containers v
WHERE x.con_id          = y.con_id
AND   x.tablespace_name = y.tablespace_name
AND   v.con_id          = y.con_id
UNION
SELECT vc2.con_id, vc2.name , tf.tablespace_name,count(*) files, null, SUM(tf.bytes)/1024/1024, null
FROM v$containers vc2, cdb_temp_files tf
WHERE vc2.con_id = tf.con_id
GROUP BY vc2.con_id, vc2.name , tf.tablespace_name
ORDER BY 1, 2; 

PROMPT Print the details of the Users Tablespace Quotas
SELECT   con_id,tablespace_name ta, username , bytes / 1024/1024  size_mb,
         max_bytes / 1024/1024 max_bytes
    FROM cdb_ts_quotas
   WHERE MAX_BYTES!=-1
ORDER BY tablespace_name, username;


prompt <a name="inmemory"></a>
prompt  In-memory segments ...
select c.name container, s.*
  from v$im_segments s, v$containers c, cdb_users u
 where s.con_id = c.con_id
   and c.con_id = u.con_id
   and s.con_id = u.con_id
   and u.oracle_maintained = 'N'
 order by 1,s.owner;
 
prompt <a name="lockdown"></a>
prompt Query PDB Lockdown Profiles ...

clear columns breaks computes

select c.name contianer, p.*
  from cdb_lockdown_profiles p, v$containers c
 where p.con_id = c.con_id;
 
 
host echo Check DB Resource Plan...
prompt <a name="resource_plan"></a>
prompt Query CDB Resource Plan ...

clear columns breaks computes

col container                  for a20 heading 'Container'
col plan                       for a25 heading 'Plan'
col num_plan_directives                heading 'Num Plan|Direvtives'
col cpu_method                 for a20 heading 'CPU Method'
col mgmt_method                for a20 heading 'MGMT Method'
col active_sess_pool_mth       for a20 heading 'Active Session|Pool Method'
col parallel_degree_limit_mth  for a20 heading 'Parallel Degree|Limit Method'
col queueing_mth               for a20 heading 'Queueing|Method'
col sub_plan                   for a20 heading 'Sub Plan'
col comments                   for a20 heading 'Comments'
col status                     for a10 heading 'Status'
col mandatory                  for a20 heading 'Mandatory'

select c.name container,
       r.plan,
       r.num_plan_directives,
       r.cpu_method,
       r.mgmt_method,
       r.active_sess_pool_mth,
       r.parallel_degree_limit_mth,
       r.queueing_mth,
       r.sub_plan,
       r.comments,
       r.status,
       r.mandatory
  from cdb_rsrc_plans r, v$containers c
 where r.con_id = c.con_id
 order by 1,2;
 
prompt Query CDB Resource Plan Directives ...

clear columns breaks computes

col container              for a20 heading 'Container'
col plan                   for a30 heading 'Plan'
col pluggable_database     for a25 heading 'Pluggable|Database'
col profile                for a15 heading 'Profile'
col directive_type         for a15 heading 'Directive|Type'
col shares                         heading 'Shares'
col utilization_limit              heading 'Utilization|Limit'
col parallel_server_limit          heading 'Parallel Server|Limit'
col memory_min                     heading 'Memory Min'
col memory_limit                   heading 'Memory|Limit'
col comments               for a30 heading 'Comments'
col Status                 for a10 heading 'Status'
col mandatory              for a15 heading 'Mandatory'

select c.name container,
       p.plan,
       p.pluggable_database,
       p.profile,
       p.directive_type,
       p.shares,
       p.utilization_limit,
       p.parallel_server_limit,
       p.memory_min,
       p.memory_limit,
       p.comments,
       p.status,
       p.mandatory
  from cdb_cdb_rsrc_plan_directives p, v$containers c
 where p.con_id = c.con_id
 order by 1,2;
prompt Query Resource Capability ...

clear columns breaks computes

col container              for a20 heading 'Container'
col cpu_capable                    heading 'CPU Capable'
col io_capable             for a20 heading 'IO Capable'
col Status                 for a10 heading 'Status'

select c.name container, cpu_capable, io_capable, status
  from cdb_rsrc_capability r, v$containers c
 where r.con_id = c.con_id
 order by 1;

prompt Query Resource Categories ...

clear columns breaks computes

col container   for a20 heading 'Container'
col category    for a30 heading 'Category'
col comments    for a30 heading 'Comments'
col Status      for a10 heading 'Status'
col mandatory              for a15 heading 'Mandatory'

select c.name container, r.name category, r.comments, r.status, r.mandatory
  from cdb_rsrc_categories r, v$containers c
 where r.con_id = c.con_id
 order by 1,2;

prompt Query Resource Consumer Group ...

clear columns breaks computes

col container       for a20 heading 'Container'
col consumer_group  for a20 heading 'Consumer Group'
col cpu_method      for a20 heading 'CPU Method'
col mgmt_method     for a20 heading 'MGMT Method'
col internal_use    for a20 heading 'Internal Use'
col comments        for a30 heading 'Comments'
col category        for a30 heading 'Category'
col Status          for a10 heading 'Status'
col mandatory       for a15 heading 'Mandatory'

select c.name container,
       r.consumer_group,
       r.cpu_method,
       r.mgmt_method,
       r.internal_use,
       r.comments,
       r.category,
       r.status,
       r.mandatory
  from cdb_rsrc_consumer_groups r, v$containers c
 where r.con_id = c.con_id
 order by 1,2;

prompt Query Resource Consumer Group Privs ...

clear columns breaks computes

col container       for a20 heading 'Container'
col grantee         for a20 heading 'Grantee'
col granted_group   for a20 heading 'Granted Group'
col grant_option    for a20 heading 'Grant Option'
col internal_group  for a20 heading 'Internal Group'

select c.name container,
       r.grantee,
       r.granted_group,
       r.grant_option,
       r.initial_group
  from cdb_rsrc_consumer_group_privs r, v$containers c
 where r.con_id = c.con_id
 order by 1;
 
prompt Query Resource IO Capability ...

clear columns breaks computes

col container       for a20 heading 'Container'
col start_time      for a25 heading 'Start Time'

select c.name container,
       r.start_time,
       r.end_time,
       r.max_iops,
       r.max_mbps,
       r.max_pmbps,
       r.latency,
       r.num_physical_disks
  from cdb_rsrc_io_calibrate r, v$containers c
 where r.con_id = c.con_id
 order by 1;
 
 prompt  Query Resource Manager System Privs ...

clear columns breaks computes

col container    for a20 heading 'Container'
col grantee      for a25 heading 'Grantee'
col privilege    for a20 heading 'Privilege'
col admin_option for a20 heading 'Admin Option'

select c.name container, r.grantee, r.privilege, r.admin_option
  from cdb_rsrc_manager_system_privs r, v$containers c
 where r.con_id = c.con_id
 order by 1;
 
prompt
prompt <a name="Optimizer"></a>   
prompt   
prompt <font size="+2" face="Arial,Helvetica,Geneva,sans-serif" color="#336699"><b>Optimizer</b></font>
col compatible for a50
col optimizer_features_enable for a50
select * from (
select i.instance_name,i.VERSION,p.name pname ,p.value pvalue
  from gv$parameter p, gv$instance i
 where name in('compatible','optimizer_features_enable')
   and p.inst_id = i.instance_number
   )
pivot (max(pvalue) for pname in('compatible' as compatible,'optimizer_features_enable' as optimizer_features_enable ));

host echo Check HOST /OS STATS...
prompt <a name="OS_stat"></a>  
prompt   
prompt <font size="+2" face="Arial,Helvetica,Geneva,sans-serif" color="#336699"><b>OS stats </b></font> 
 
SPOOL OFF
ho echo "<pre>" >> &FileName._&_dbname._&_spool_time..html
-- show adrci
ho echo  '<a name="Incident"></a> ' >> &FileName._&_dbname._&_spool_time..html
ho echo '<font size="+2" face="Arial,Helvetica,Geneva,sans-serif" color="#336699"><b>DB Incident</b></font>'  >> &FileName._&_dbname._&_spool_time..html
ho echo '<p style="background: lightgoldenrodyellow;">'>> &FileName._&_dbname._&_spool_time..html
host adrci exec="show incident -all" >> &FileName._&_dbname._&_spool_time..html
ho echo '</p>'>> &FileName._&_dbname._&_spool_time..html
ho echo  '<a name="IO"></a> ' >> &FileName._&_dbname._&_spool_time..html
ho echo '<font size="+2" face="Arial,Helvetica,Geneva,sans-serif" color="#336699"><b>IOSTAT</b></font>'  >> &FileName._&_dbname._&_spool_time..html
ho echo '<p style="background: lightgoldenrodyellow;">'>> &FileName._&_dbname._&_spool_time..html
host iostat -d  3 3 >> &FileName._&_dbname._&_spool_time..html
ho echo '</p>'>> &FileName._&_dbname._&_spool_time..html
ho echo  '<a name="SAR"></a> ' >> &FileName._&_dbname._&_spool_time..html
ho echo '<font size="+2" face="Arial,Helvetica,Geneva,sans-serif" color="#336699"><b>SAR</b></font>'  >> &FileName._&_dbname._&_spool_time..html
ho echo '<p style="background: lightgoldenrodyellow;">'>> &FileName._&_dbname._&_spool_time..html
host sar -d 3 3 >> &FileName._&_dbname._&_spool_time..html
ho echo '</p>'>> &FileName._&_dbname._&_spool_time..html
ho echo  '<a name="VMSTAT"></a> ' >> &FileName._&_dbname._&_spool_time..html
ho echo 
ho echo '<font size="+2" face="Arial,Helvetica,Geneva,sans-serif" color="#336699"><b>VMSTAT</b></font>'  >> &FileName._&_dbname._&_spool_time..html
ho echo '<p style="background: lightgoldenrodyellow;">'>> &FileName._&_dbname._&_spool_time..html
host vmstat 3 3 >> &FileName._&_dbname._&_spool_time..html
ho echo '</p>'>> &FileName._&_dbname._&_spool_time..html
ho echo 
ho echo  '<a name="MEMINFO"></a> ' >> &FileName._&_dbname._&_spool_time..html
ho echo '<font size="+2" face="Arial,Helvetica,Geneva,sans-serif" color="#336699"><b>Memory info</b></font>'  >> &FileName._&_dbname._&_spool_time..html
ho echo '<p style="background: lightgoldenrodyellow;">'>> &FileName._&_dbname._&_spool_time..html
host cat /proc/meminfo >> &FileName._&_dbname._&_spool_time..html
host svmon -G  2>&1 >> &FileName._&_dbname._&_spool_time..html
ho echo '</p>'>> &FileName._&_dbname._&_spool_time..html
ho echo 
ho echo  '<a name="CPUINFO"></a> ' >> &FileName._&_dbname._&_spool_time..html
ho echo '<font size="+2" face="Arial,Helvetica,Geneva,sans-serif" color="#336699"><b>CPU info</b></font>'  >> &FileName._&_dbname._&_spool_time..html
ho echo '<p style="background: lightgoldenrodyellow;">'>> &FileName._&_dbname._&_spool_time..html
host cat /proc/cpuinfo|grep "model name"|sort|uniq -c >> &FileName._&_dbname._&_spool_time..html
host lscpu|grep -v Flags >> &FileName._&_dbname._&_spool_time..html
ho echo '</p>'>> &FileName._&_dbname._&_spool_time..html
ho echo 
ho echo  '<a name="FS"></a> ' >> &FileName._&_dbname._&_spool_time..html
ho echo '<font size="+2" face="Arial,Helvetica,Geneva,sans-serif" color="#336699"><b>File System</b></font>'  >> &FileName._&_dbname._&_spool_time..html
ho echo '<p style="background: lightgoldenrodyellow;">'>> &FileName._&_dbname._&_spool_time..html
host df -h >> &FileName._&_dbname._&_spool_time..html
host bdf  2>&1 >> &FileName._&_dbname._&_spool_time..html
ho echo '</p>'>> &FileName._&_dbname._&_spool_time..html
ho echo 
ho echo  '<a name="HOSTS"></a> ' >> &FileName._&_dbname._&_spool_time..html
ho echo '<font size="+2" face="Arial,Helvetica,Geneva,sans-serif" color="#336699"><b>Hosts file</b></font>'  >> &FileName._&_dbname._&_spool_time..html
ho echo '<p style="background: lightgoldenrodyellow;">'>> &FileName._&_dbname._&_spool_time..html
host cat /etc/hosts >> &FileName._&_dbname._&_spool_time..html
ho echo '</p>'>> &FileName._&_dbname._&_spool_time..html
ho echo 
ho echo  '<a name="ULIMIT"></a> ' >> &FileName._&_dbname._&_spool_time..html
ho echo '<font size="+2" face="Arial,Helvetica,Geneva,sans-serif" color="#336699"><b>User limits</b></font>'  >> &FileName._&_dbname._&_spool_time..html
ho echo '<p style="background: lightgoldenrodyellow;">'>> &FileName._&_dbname._&_spool_time..html
host ulimit -a >> &FileName._&_dbname._&_spool_time..html
ho echo '</p>'>> &FileName._&_dbname._&_spool_time..html
ho echo '<font size="+2" face="Arial,Helvetica,Geneva,sans-serif" color="#336699"><b>Limitd config</b></font>'  >> &FileName._&_dbname._&_spool_time..html
ho echo '<p style="background: lightgoldenrodyellow;">'>> &FileName._&_dbname._&_spool_time..html
host cat /etc/security/limits.d/*.conf|egrep -v '^(#|$)' >> &FileName._&_dbname._&_spool_time..html
ho echo '</p>'>> &FileName._&_dbname._&_spool_time..html
ho echo 
ho echo  '<a name="SYSCTL"></a> ' >> &FileName._&_dbname._&_spool_time..html
ho echo '<font size="+2" face="Arial,Helvetica,Geneva,sans-serif" color="#336699"><b>Kernel parameter</b></font>'  >> &FileName._&_dbname._&_spool_time..html
ho echo '<p style="background: lightgoldenrodyellow;">'>> &FileName._&_dbname._&_spool_time..html
host sysctl -a 2>&1 |egrep -i 'ipfrag|netdev|min_free|direty|swappiness|aio|sem|shm|oops|huge|hang|pid_max'|grep -v netdev_rss_key  >> &FileName._&_dbname._&_spool_time..html
ho echo '</p>'>> &FileName._&_dbname._&_spool_time..html
ho echo  '<a name="SWAP"></a> ' >> &FileName._&_dbname._&_spool_time..html

ho echo '<font size="+2" face="Arial,Helvetica,Geneva,sans-serif" color="#336699"><b>Swap</b></font>'  >> &FileName._&_dbname._&_spool_time..html
ho echo '<p style="background: lightgoldenrodyellow;">'>> &FileName._&_dbname._&_spool_time..html
host free >> &FileName._&_dbname._&_spool_time..html
ho echo '</p>'>> &FileName._&_dbname._&_spool_time..html
ho echo 
ho echo  '<a name="CRONTAB"></a> ' >> &FileName._&_dbname._&_spool_time..html
ho echo '<font size="+2" face="Arial,Helvetica,Geneva,sans-serif" color="#336699"><b>Crontab</b></font>'  >> &FileName._&_dbname._&_spool_time..html
ho echo '<p style="background: lightgoldenrodyellow;">'>> &FileName._&_dbname._&_spool_time..html
host crontab -l >> &FileName._&_dbname._&_spool_time..html
ho echo '</p>'>> &FileName._&_dbname._&_spool_time..html
ho echo 
ho echo  '<a name="NETSTAT"></a> ' >> &FileName._&_dbname._&_spool_time..html
ho echo '<font size="+2" face="Arial,Helvetica,Geneva,sans-serif" color="#336699"><b>Netstat</b></font>'  >> &FileName._&_dbname._&_spool_time..html
ho echo '<p style="background: lightgoldenrodyellow;">'>> &FileName._&_dbname._&_spool_time..html
host netstat -s|egrep 'err|drop|reassem|over|fail|bad' >> &FileName._&_dbname._&_spool_time..html
ho echo '</p>'>> &FileName._&_dbname._&_spool_time..html
ho echo 
ho echo "</pre>" >> &FileName._&_dbname._&_spool_time..html

ho echo '<a href="#top">Back to Top</a>' >> &FileName._&_dbname._&_spool_time..html
 
spool &FileName._&_dbname._&_spool_time..html append
 
prompt &reportfooter
spool off

COLUMN run_during_end NEW_VALUE _run_during_end NOPRINT

select dbms_utility.get_time run_during_end from dual;

COLUMN report_during NEW_VALUE _report_during NOPRINT
select (&_run_during_end - &_run_during_begin)/100  report_during from dual;

-- replace durint time
ho  sed -i 's/_tmp_run_during/&_report_during/' &FileName._&_dbname._&_spool_time..html

SET MARKUP HTML OFF
SET TERMOUT ON
prompt End of health check report ...
prompt elapsed  &_report_during seconds
prompt ==========================================================
prompt Output written to: &FileName._&_dbname._&_spool_time..html
prompt ==========================================================

EXIT;