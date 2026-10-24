DECLARE
    a INT;
    b INT;
    c INT;
BEGIN
    a := 10;
    b := 20;
    c := 15;

    IF a>b AND a>c THEN
        DBMS_OUTPUT.PUT_LINE(a);
    ELSIF b>c THEN
        DBMS_OUTPUT.PUT_LINE(b);
    ELSE
        DBMS_OUTPUT.PUT_LINE(c);
    END IF;
END;