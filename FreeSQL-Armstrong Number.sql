DECLARE
    n INT;
    t INT;
    r INT;
    s INT;
BEGIN
    n := 153;
    t := n;
    s := 0;

    WHILE t>0 LOOP
        r := MOD(t,10);
        s := s+r*r*r;
        t := TRUNC(t/10);
    END LOOP;

    IF s=n THEN
        DBMS_OUTPUT.PUT_LINE('Armstrong Number');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Not Armstrong Number');
    END IF;
END;
/