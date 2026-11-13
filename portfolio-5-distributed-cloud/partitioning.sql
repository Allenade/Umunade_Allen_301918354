-- Portfolio 5: LIST partitioning of loans by campus.
-- This is the single-server version of "sharding by campus": one logical table,
-- split into one physical table (partition) per campus.
-- It uses its own table (loan_by_campus) with made-up rows, so it does not
-- change the Part 1 tables. Run it on the primary (port 5434) or on library_pg (5433).

DROP TABLE IF EXISTS loan_by_campus CASCADE;

-- The partition key (campus_id) must be part of the primary key.
CREATE TABLE loan_by_campus (
    loan_id     BIGINT GENERATED ALWAYS AS IDENTITY,
    campus_id   INT         NOT NULL,
    copy_id     INT         NOT NULL,
    member_id   INT         NOT NULL,
    lent_at     TIMESTAMPTZ NOT NULL,
    due_date    DATE        NOT NULL,
    returned_at TIMESTAMPTZ,
    PRIMARY KEY (loan_id, campus_id),
    CHECK (due_date >= lent_at::date)
) PARTITION BY LIST (campus_id);

CREATE TABLE loan_campus_1 PARTITION OF loan_by_campus FOR VALUES IN (1);  -- Main
CREATE TABLE loan_campus_2 PARTITION OF loan_by_campus FOR VALUES IN (2);  -- Lugazi
CREATE TABLE loan_campus_3 PARTITION OF loan_by_campus FOR VALUES IN (3);  -- Bweyogerere
CREATE TABLE loan_campus_4 PARTITION OF loan_by_campus FOR VALUES IN (4);  -- Kira
CREATE TABLE loan_campus_5 PARTITION OF loan_by_campus FOR VALUES IN (5);  -- Mukono
-- Any campus without its own partition (for example a new campus) goes here.
CREATE TABLE loan_campus_other PARTITION OF loan_by_campus DEFAULT;

-- An index created on the parent is created on every partition.
CREATE INDEX ON loan_by_campus (member_id);

-- 250,000 made-up loans over 3 years: about 1% belong to a new campus 6.
\timing on
INSERT INTO loan_by_campus (campus_id, copy_id, member_id, lent_at, due_date, returned_at)
SELECT CASE WHEN g % 100 = 0 THEN 6 ELSE 1 + (g % 5) END,
       1 + (g % 20000),
       1 + (g % 50000),
       now() - (g % 1095) * interval '1 day',
       (now() - (g % 1095) * interval '1 day' + interval '14 days')::date,
       CASE WHEN g % 1095 < 20 AND g % 3 = 0 THEN NULL
            ELSE now() - (g % 1095) * interval '1 day' + interval '7 days' END
FROM generate_series(1, 250000) AS g;
\timing off
ANALYZE loan_by_campus;

\echo '=== Each row was routed to its campus partition automatically ==='
SELECT tableoid::regclass AS partition, count(*) AS loans
FROM loan_by_campus
GROUP BY 1 ORDER BY 1;

\echo '=== P1. Open loans at campus 2: only loan_campus_2 is scanned (partition pruning) ==='
EXPLAIN (ANALYZE, COSTS OFF)
SELECT count(*) FROM loan_by_campus WHERE campus_id = 2 AND returned_at IS NULL;

\echo '=== P2. The same question with no campus filter: every partition is scanned ==='
EXPLAIN (ANALYZE, COSTS OFF)
SELECT count(*) FROM loan_by_campus WHERE returned_at IS NULL;

\echo '=== P3. Two campuses: only those two partitions are scanned ==='
EXPLAIN (ANALYZE, COSTS OFF)
SELECT campus_id, count(*) FROM loan_by_campus WHERE campus_id IN (1, 3) GROUP BY campus_id;

\echo '=== P4. P1 again with pruning switched off, for comparison ==='
SET enable_partition_pruning = off;
EXPLAIN (ANALYZE, COSTS OFF)
SELECT count(*) FROM loan_by_campus WHERE campus_id = 2 AND returned_at IS NULL;
RESET enable_partition_pruning;

\echo '=== P5. A campus can be detached as a separate table (e.g. to move it to its own server) ==='
ALTER TABLE loan_by_campus DETACH PARTITION loan_campus_5;
SELECT count(*) AS rows_left_in_loan_by_campus FROM loan_by_campus;
SELECT count(*) AS rows_in_detached_loan_campus_5 FROM loan_campus_5;
ALTER TABLE loan_by_campus ATTACH PARTITION loan_campus_5 FOR VALUES IN (5);
SELECT count(*) AS rows_after_attaching_again FROM loan_by_campus;
