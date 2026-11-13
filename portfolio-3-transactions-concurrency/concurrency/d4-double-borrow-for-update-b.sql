-- Demo 4, Window B: B's check waits for A's lock, then sees the real status.
\! sleep 1
\echo '[1s] B (librarian 1): lock and check copy 5 (this waits for A)'
BEGIN;
\timing on
SELECT copy_id, status FROM book_copy WHERE copy_id = 5 FOR UPDATE;
\timing off
\echo 'B: the copy is already on loan, so B does not lend it and ends the transaction'
ROLLBACK;
\echo 'B: borrow_copy() gives the same result with a clear message'
SELECT borrow_copy(5, 4, 1);
