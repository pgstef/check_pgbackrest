DROP TABLE IF EXISTS wal_gen;

CREATE TABLE wal_gen (
    id integer NOT NULL GENERATED always AS IDENTITY,
    lsn pg_lsn
);

CREATE OR REPLACE FUNCTION wal_gen_function (my_loop_nb NUMERIC)
    RETURNS void
    AS $$
BEGIN
    FOR i IN 1..my_loop_nb LOOP
        INSERT INTO wal_gen (lsn)
        SELECT
            pg_switch_wal ();
    END LOOP;
END;
$$
LANGUAGE plpgsql;

SELECT
    wal_gen_function (:my_loop_nb);

SELECT
    count(*)
FROM
    wal_gen;

DROP FUNCTION wal_gen_function;

DROP TABLE wal_gen;