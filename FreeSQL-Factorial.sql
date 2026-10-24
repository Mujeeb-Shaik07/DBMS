DECLARE
    n INT;
    f INT;
BEGIN
    n := 5;
    f := 1;

    FOR i IN 1..n LOOP
        f := f*i;
    END LOOP;

    DBMS_OUTPUT.PUT_LINE('Factorial = '||f);
END;