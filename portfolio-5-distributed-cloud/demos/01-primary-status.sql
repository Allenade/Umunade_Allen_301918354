-- Run on the PRIMARY (port 5434).
-- Shows the replica connected to this primary and how far behind it is.
\echo '=== Primary: is this server in recovery (read-only standby)? ==='
SELECT pg_is_in_recovery() AS in_recovery, current_setting('cluster_name') AS server;

\echo '=== Primary: connected replicas (pg_stat_replication) ==='
SELECT application_name, client_addr, state, sync_state,
       sent_lsn, write_lsn, flush_lsn, replay_lsn,
       pg_wal_lsn_diff(sent_lsn, replay_lsn) AS bytes_behind,
       write_lag, flush_lag, replay_lag
FROM pg_stat_replication;

\echo '=== Primary: replication slot ==='
SELECT slot_name, slot_type, active, restart_lsn FROM pg_replication_slots;
