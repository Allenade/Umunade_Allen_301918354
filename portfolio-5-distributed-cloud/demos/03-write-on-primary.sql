-- Run on the PRIMARY: a librarian lends a book (normal write).
\echo '=== Primary: member 4 borrows copy 2 ==='
BEGIN;
INSERT INTO loan (copy_id, member_id, lent_by, due_date)
VALUES (2, 4, 1, CURRENT_DATE + 14)
RETURNING loan_id, copy_id, member_id, lent_at;
UPDATE book_copy SET status = 'on_loan' WHERE copy_id = 2;
COMMIT;
SELECT pg_current_wal_lsn() AS primary_lsn_after_commit, clock_timestamp() AS committed_at;

\echo '=== Primary: half a second later, how far behind is the replica? ==='
SELECT pg_sleep(0.5);
SELECT application_name, replay_lsn,
       pg_wal_lsn_diff(pg_current_wal_lsn(), replay_lsn) AS bytes_behind,
       replay_lag
FROM pg_stat_replication;
