-- Run on the REPLICA straight after 03-write-on-primary.sql.
\echo '=== Replica: the new loan has arrived ==='
SELECT l.loan_id, l.copy_id, l.member_id, c.status AS copy_status
FROM loan l JOIN book_copy c ON c.copy_id = l.copy_id
WHERE l.copy_id = 2 AND l.returned_at IS NULL;

\echo '=== Replica: replication delay ==='
SELECT pg_last_wal_replay_lsn() AS replica_replayed_lsn,
       pg_last_xact_replay_timestamp() AS last_replayed_commit,
       clock_timestamp() - pg_last_xact_replay_timestamp() AS time_since_last_replayed_commit;
