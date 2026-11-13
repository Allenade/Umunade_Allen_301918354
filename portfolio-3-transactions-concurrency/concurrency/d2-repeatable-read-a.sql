-- Demo 2, Window A: REPEATABLE READ prevents the non-repeatable read.
-- Same steps as Demo 1, only the isolation level is different.
\echo '[0s] A: start a REPEATABLE READ transaction and read copy 5'
BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT copy_id, status FROM book_copy WHERE copy_id = 5;
\! sleep 2
\echo '[2s] A: read copy 5 again in the same transaction'
SELECT copy_id, status FROM book_copy WHERE copy_id = 5;
COMMIT;
\echo 'A: after COMMIT, a new transaction sees the change made by B'
SELECT copy_id, status FROM book_copy WHERE copy_id = 5;
