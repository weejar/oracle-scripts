CREATE OR REPLACE FUNCTION IS_NUMERIC(P_INPUT IN VARCHAR2) RETURN INTEGER IS
  RESULT INTEGER;
  NUM NUMBER ;
BEGIN
  NUM:=TO_NUMBER(P_INPUT);
  RETURN 1;
EXCEPTION WHEN OTHERS THEN
  RETURN 0;
END IS_NUMERIC;
/



create or replace function is_valid_number(p_v VARCHAR2) return number
is
v_char NUMBER;
begin
  v_char:=TO_NUMBER(p_v);
  return 1;
EXCEPTION
    WHEN OTHERS THEN
	return 0;
end;


DECLARE
  v_input VARCHAR2(10) := 'abc';
v_number NUMBER;
BEGIN
  BEGIN
    v_number := TO_NUMBER(v_input);
    DBMS_OUTPUT.PUT_LINE('Conversion successful. Number: ' || v_number);
  EXCEPTION
    WHEN INVALID_NUMBER THEN
      DBMS_OUTPUT.PUT_LINE('Error: Invalid number');
  END;
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;
/
