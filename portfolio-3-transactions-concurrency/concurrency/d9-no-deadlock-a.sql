-- Demo 9, Window A: the deadlock fix. Both librarians lock the copies they
-- need at the start, always in the same order (ORDER BY copy_id).
\echo '[0s] A: lock copies 2 and 4 in copy_id order'
BEGIN;
SELECT copy_id FROM book_copy WHERE copy_id IN (2, 4) ORDER BY copy_id FOR UPDATE;
UPDATE book_copy SET shelf = 'R1' WHERE copy_id = 2;
\! sleep 2
\echo '[2s] A: move copy 4 and COMMIT'
UPDATE book_copy SET shelf = 'R1' WHERE copy_id = 4;
COMMIT;
