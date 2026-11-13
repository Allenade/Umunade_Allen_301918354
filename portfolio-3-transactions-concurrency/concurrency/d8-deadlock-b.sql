-- Demo 8, Window B: the second librarian, in the opposite order.
\set VERBOSITY verbose
\! sleep 1
\echo '[1s] B: move copy 4 (locks copy 4)'
BEGIN;
UPDATE book_copy SET shelf = 'R2' WHERE copy_id = 4;
\! sleep 1.5
\echo '[2.5s] B: move copy 2 (A holds copy 2 and is waiting for B = deadlock)'
\timing on
UPDATE book_copy SET shelf = 'R2' WHERE copy_id = 2;
\timing off
COMMIT;
\! sleep 1
\echo 'Final shelves:'
SELECT copy_id, shelf FROM book_copy WHERE copy_id IN (2, 4) ORDER BY copy_id;
