-- Demo 5, Window A: the same race with no locks, but both transactions
-- run at SERIALIZABLE level.
\set VERBOSITY verbose
\echo '[0s] A (librarian 5): SERIALIZABLE, check copy 5'
BEGIN ISOLATION LEVEL SERIALIZABLE;
SELECT copy_id, status FROM book_copy WHERE copy_id = 5;
\! sleep 2
\echo '[2s] A: lend it to member 6'
UPDATE book_copy SET status = 'on_loan' WHERE copy_id = 5;
INSERT INTO loan (copy_id, member_id, lent_by, due_date) VALUES (5, 6, 5, CURRENT_DATE + 14);
\! sleep 1
\echo '[3s] A: COMMIT'
COMMIT;
