DECLARE
    n INT;
    c INT;
BEGIN
    n := &n;
    c := 0;

    FOR i IN 1..n LOOP
        IF MOD(n,i)=0 THEN
            c := c+1;
        END IF;
    END LOOP;

    IF c=2 THEN
        DBMS_OUTPUT.PUT_LINE('Prime Number');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Not Prime Number');
    END IF;
END;
/