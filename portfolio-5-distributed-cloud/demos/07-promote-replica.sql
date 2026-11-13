-- Run on the REPLICA after the primary has been STOPPED (failover).
\echo '=== Replica: still a read-only standby? ==='
SELECT pg_is_in_recovery() AS in_recovery;

\echo '=== Replica: promote it to be the new primary ==='
SELECT pg_promote(wait => true);

\echo '=== New primary: no longer in recovery ==='
SELECT pg_is_in_recovery() AS in_recovery, current_setting('transaction_read_only') AS read_only;

\echo '=== New primary: lending works again (the write that failed in 05 now succeeds) ==='
INSERT INTO loan (copy_id, member_id, lent_by, due_date)
VALUES (4, 6, 5, CURRENT_DATE + 14)
RETURNING loan_id, copy_id, member_id;
UPDATE book_copy SET status = 'on_loan' WHERE copy_id = 4;

\echo '=== New primary: nothing committed on the old primary was lost ==='
SELECT loan_id, copy_id, member_id FROM loan WHERE returned_at IS NULL ORDER BY loan_id;
