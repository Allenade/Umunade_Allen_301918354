-- Demo 9, Window B: B uses the same order, so it simply waits for A.
\! sleep 1
\echo '[1s] B: lock copies 2 and 4 in copy_id order (waits for A)'
BEGIN;
\timing on
SELECT copy_id FROM book_copy WHERE copy_id IN (2, 4) ORDER BY copy_id FOR UPDATE;
\timing off
UPDATE book_copy SET shelf = 'R2' WHERE copy_id = 4;
UPDATE book_copy SET shelf = 'R2' WHERE copy_id = 2;
COMMIT;
\echo 'B: no deadlock, both transactions finished. Final shelves:'
SELECT copy_id, shelf FROM book_copy WHERE copy_id IN (2, 4) ORDER BY copy_id;
