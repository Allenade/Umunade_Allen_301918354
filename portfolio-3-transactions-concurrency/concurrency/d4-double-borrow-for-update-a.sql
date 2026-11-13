-- Demo 4, Window A: the same race, but each librarian locks the copy with
-- SELECT ... FOR UPDATE before deciding. This is what borrow_copy() does.
\echo '[0s] A (librarian 5): lock and check copy 5'
BEGIN;
SELECT copy_id, status FROM book_copy WHERE copy_id = 5 FOR UPDATE;
\! sleep 2
\echo '[2s] A: lend it to member 6'
INSERT INTO loan (copy_id, member_id, lent_by, due_date) VALUES (5, 6, 5, CURRENT_DATE + 14);
UPDATE book_copy SET status = 'on_loan' WHERE copy_id = 5;
\! sleep 1
\echo '[3s] A: COMMIT'
COMMIT;
