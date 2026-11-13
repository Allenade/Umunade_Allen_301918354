-- Run on the PRIMARY: switch from asynchronous to synchronous replication,
-- write once, then switch back.
-- Asynchronous (the default): COMMIT returns as soon as the primary has saved
-- the change. If the primary dies a moment later, the last few commits may not
-- have reached the replica.
-- Synchronous: COMMIT waits until the replica has also saved the change, so no
-- committed loan can be lost, but every write is a little slower and writes stop
-- if the replica is down.
\echo '=== Primary: asynchronous (default) ==='
SELECT application_name, sync_state FROM pg_stat_replication;

\echo '=== Primary: make replica1 a synchronous standby ==='
ALTER SYSTEM SET synchronous_standby_names = 'replica1';
SELECT pg_reload_conf();
SELECT pg_sleep(1);
SELECT application_name, sync_state FROM pg_stat_replication;

\echo '=== Primary: a write now waits for the replica before COMMIT returns ==='
\timing on
UPDATE book_copy SET shelf = 'S1' WHERE copy_id = 6;
\timing off

\echo '=== Primary: back to asynchronous ==='
ALTER SYSTEM RESET synchronous_standby_names;
SELECT pg_reload_conf();
SELECT pg_sleep(1);
SELECT application_name, sync_state FROM pg_stat_replication;
