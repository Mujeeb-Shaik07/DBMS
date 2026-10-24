DECLARE
    a INT;
    b INT;
    c INT;
BEGIN
    a := 0;
    b := 1;

    DBMS_OUTPUT.PUT_LINE(a);
    DBMS_OUTPUT.PUT_LINE(b);

    FOR i IN 1..8 LOOP
        c := a+b;
        DBMS_OUTPUT.PUT_LINE(c);
        a := b;
        b := c;
    END LOOP;
END;
/