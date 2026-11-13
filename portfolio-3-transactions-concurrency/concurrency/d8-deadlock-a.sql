-- Demo 8, Window A: a deadlock.
-- Two librarians are re-shelving copies 2 and 4 in one transaction each,
-- but in the opposite order. A takes copy 2 then copy 4; B takes 4 then 2.
\set VERBOSITY verbose
\echo '[0s] A: move copy 2 (locks copy 2)'
BEGIN;
UPDATE book_copy SET shelf = 'R1' WHERE copy_id = 2;
\! sleep 2
\echo '[2s] A: move copy 4 (B holds copy 4, so A waits)'
\timing on
UPDATE book_copy SET shelf = 'R1' WHERE copy_id = 4;
\timing off
COMMIT;
