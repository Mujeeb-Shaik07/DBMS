DECLARE
    n INT;
    t INT;
    r INT;
    rev INT;
BEGIN
    n := 121;
    t := n;
    rev := 0;

    WHILE t>0 LOOP
        r := MOD(t,10);
        rev := rev*10+r;
        t := TRUNC(t/10);
    END LOOP;

    IF rev=n THEN
        DBMS_OUTPUT.PUT_LINE('Palindrome');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Not Palindrome');
    END IF;
END;
/