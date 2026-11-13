-- Portfolio 2: the cost of indexes on writes.
-- Inserts 50,000 extra (returned) loans and times it, then rolls back so the
-- data is not changed (member 106 is one of the librarians). Run it once
-- before indexes.sql and once after, and
-- compare the INSERT times. The insert is run three times because the
-- first run is often slower while the data is read into memory.

\timing on
BEGIN;
INSERT INTO loan (copy_id, member_id, lent_by, lent_at, due_date, returned_at)
SELECT 7 + (g % 100000), 1 + (g % 45000), 106, now() - interval '200 days',
       (now() - interval '186 days')::date, now() - interval '190 days'
FROM generate_series(1, 50000) AS g;
ROLLBACK;

BEGIN;
INSERT INTO loan (copy_id, member_id, lent_by, lent_at, due_date, returned_at)
SELECT 7 + (g % 100000), 1 + (g % 45000), 106, now() - interval '200 days',
       (now() - interval '186 days')::date, now() - interval '190 days'
FROM generate_series(1, 50000) AS g;
ROLLBACK;

BEGIN;
INSERT INTO loan (copy_id, member_id, lent_by, lent_at, due_date, returned_at)
SELECT 7 + (g % 100000), 1 + (g % 45000), 106, now() - interval '200 days',
       (now() - interval '186 days')::date, now() - interval '190 days'
FROM generate_series(1, 50000) AS g;
ROLLBACK;

-- A rolled-back insert still leaves dead rows behind in the table and its
-- indexes. VACUUM cleans them up so the later timings are not affected.
\timing off
VACUUM ANALYZE loan;
