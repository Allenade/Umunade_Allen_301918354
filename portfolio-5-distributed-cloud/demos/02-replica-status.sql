-- Run on the REPLICA (port 5435).
\echo '=== Replica: is this server in recovery (read-only standby)? ==='
SELECT pg_is_in_recovery() AS in_recovery, current_setting('cluster_name') AS server,
       current_setting('transaction_read_only') AS read_only;

\echo '=== Replica: WAL receiver (pg_stat_wal_receiver) ==='
SELECT status, sender_host, sender_port, slot_name, written_lsn, flushed_lsn
FROM pg_stat_wal_receiver;

\echo '=== Replica: the Part 1 data was copied from the primary ==='
SELECT (SELECT count(*) FROM campus) AS campuses, (SELECT count(*) FROM member) AS members,
       (SELECT count(*) FROM book_copy) AS copies, (SELECT count(*) FROM loan) AS loans;
