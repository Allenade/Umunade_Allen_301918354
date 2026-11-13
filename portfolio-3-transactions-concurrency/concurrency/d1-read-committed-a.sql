-- Demo 1, Window A: READ COMMITTED allows a non-repeatable read.
-- Window A reads copy 5 twice inside ONE transaction. In between,
-- Window B marks the copy as damaged and commits.
\echo '[0s] A: start a READ COMMITTED transaction and read copy 5'
BEGIN ISOLATION LEVEL READ COMMITTED;
SELECT copy_id, status FROM book_copy WHERE copy_id = 5;
\! sleep 2
\echo '[2s] A: read copy 5 again in the same transaction'
SELECT copy_id, status FROM book_copy WHERE copy_id = 5;
COMMIT;
\echo 'A: the same SELECT gave two different answers (non-repeatable read)'
