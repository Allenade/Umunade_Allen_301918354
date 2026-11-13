-- Demo 5, Window B: B read the copy before A committed, so B's update is refused
-- with a serialization failure (SQLSTATE 40001). The fix is to retry.
\set VERBOSITY verbose
\! sleep 1
\echo '[1s] B (librarian 1): SERIALIZABLE, check copy 5'
BEGIN ISOLATION LEVEL SERIALIZABLE;
SELECT copy_id, status FROM book_copy WHERE copy_id = 5;
\! sleep 3
\echo '[4s] B: it looked available, so try to lend it to member 4'
UPDATE book_copy SET status = 'on_loan' WHERE copy_id = 5;
ROLLBACK;
\echo 'B: retry the whole transaction from the start'
BEGIN ISOLATION LEVEL SERIALIZABLE;
SELECT copy_id, status FROM book_copy WHERE copy_id = 5;
\echo 'B: now it shows on_loan, so B does not lend it'
ROLLBACK;
