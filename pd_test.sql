-- 遍历隐藏参数与fixed
-- 使用方法
--  1, spool 测试脚本到一个文件
--   如 spool p_test.sql
--  2, 把自己测试的脚本放到script.sql文件
--   如 explain plan for xxxx;
--  3, 把 p_test.sql的结果输出到 新的spool 中
--   如 spool res;
--     @p_test
set serveroutput on 

DECLARE
  l_unique_id              VARCHAR2(200);
  l_test_id                NUMBER := 0;
  l_test_id_rp_i           NUMBER := 0;
  l_spoolfile_name_p       VARCHAR2(100);
  l_spoolfile_name_vs      VARCHAR2(100); 
  l_spoolfile_name_rp_i_p  VARCHAR2(100);
  l_spoolfile_name_rp_i_vs VARCHAR2(100); 
  l_alter_session          VARCHAR2(4000);
  l_alter_session_bck      VARCHAR2(4000);
  l_skip_string_script     VARCHAR2(4000);
  l_skip_string_driver     VARCHAR2(4000);
  l_child_list             VARCHAR2(4000);
  PROCEDURE print (p_alter_session IN VARCHAR2)
  IS
  BEGIN
   l_test_id :=  l_test_id + 1;
   l_spoolfile_name_p := LPAD(l_test_id, 5, '0');
   dbms_output.put_line('PRO '||l_test_id||') "'||replace(p_alter_session,'ALTER SESSION SET',''));
   dbms_output.put_line(p_alter_session);
   dbms_output.put_line('@script');
  END;
begin
    FOR i IN (
         WITH cbo_param AS (
                SELECT /*+ materialize */ pname_qksceserow name
                  FROM x$qksceses
                 WHERE sid_qksceserow = SYS_CONTEXT('USERENV', 'SID')
                )
                SELECT x.indx+1 num,
                       x.ksppinm name,
                       x.ksppity type,
                       y.ksppstvl value,
                       y.ksppstdvl display_value,
                       y.ksppstdf isdefault,
                       x.ksppdesc description,
                       y.ksppstcmnt update_comment,
                       x.ksppihash hash
                  FROM x$ksppi x,
                       x$ksppcv y,
                       cbo_param
                 WHERE x.indx = y.indx
                   AND BITAND(x.ksppiflg, 268435456) = 0
                   AND TRANSLATE(x.ksppinm, '_', '#') NOT LIKE '##%'
                   AND x.ksppinm = cbo_param.name 
                   AND x.inst_id = USERENV('Instance')
                   AND DECODE(BITAND(x.ksppiflg/256, 1), 1, 'TRUE', 'FALSE') = 'TRUE'
                   AND x.ksppity IN (1, 2, 3)
				   --and lower(x.ksppinm) || ' ' || lower(x.ksppdesc) like lower('%parallel%')
                 ORDER BY x.ksppinm) 
LOOP
          IF SUBSTR(i.name , 1, 1) = CHR(95)  -- "_" 
		  THEN
            l_alter_session := 'ALTER SESSION SET "'||i.name ||'" = ';
          ELSE
            l_alter_session := 'ALTER SESSION SET '||i.name ||' = ';
          END IF;

          IF i.type = 1 THEN -- Boolean
            IF LOWER(i.value) = 'true' THEN
              l_alter_session := l_alter_session||' FALSE;';
            ELSIF LOWER(i.value) = 'false' THEN
              l_alter_session := l_alter_session||' TRUE;';
            ELSE
              dbms_output.put_line('--');
              dbms_output.put_line('-- skip test on '||i.name ||'. baseline value: '||i.value);
            END IF;
            print(l_alter_session);

          ELSIF i.type = 2 THEN -- String

            -- this is used as base ALTER SESSION for the LOV
            l_alter_session_bck := l_alter_session;

            FOR j IN (SELECT value_kspvld_values value
                        FROM x$kspvld_values
                       WHERE LOWER(name_kspvld_values) = i.name 

                         AND LOWER(value_kspvld_values) <> i.value
                       ORDER BY value_kspvld_values)
            LOOP
              l_alter_session := l_alter_session_bck||' '''||j.value||''';';
              print(l_alter_session);
            END LOOP;
		end if;			
end loop;

FOR i IN (SELECT * FROM v$session_fix_control WHERE session_id = SYS_CONTEXT('USERENV', 'SID') ORDER BY bugno) LOOP

          IF i.value = 0 THEN  --number
            l_alter_session := 'ALTER SESSION SET "_fix_control" = '''||i.bugno||':1'';';
          ELSIF i.value = 1 THEN
            l_alter_session := 'ALTER SESSION SET "_fix_control" = '''||i.bugno||':0'';';
          ELSE
            l_alter_session := 'ALTER SESSION SET "_fix_control" = '''||i.bugno||':0'';';
          END IF;
          print(l_alter_session);         
END LOOP;

end;
/