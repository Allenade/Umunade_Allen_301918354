-- Demo 3, Window A: two librarians lend the LAST copy of a title at the same time.
-- Copy 5 is the only copy of "A History of East Africa".
-- Both librarians check the copy first (plain SELECT, no lock), see it is
-- available, and go ahead. Only the partial unique index from Part 1
-- (uq_one_open_loan_per_copy) stops a double loan.
\echo '[0s] A (librarian 5): check copy 5'
BEGIN;
SELECT copy_id, status FROM book_copy WHERE copy_id = 5;
\! sleep 2
\echo '[2s] A: it is available, so lend it to member 6'
INSERT INTO loan (copy_id, member_id, lent_by, due_date) VALUES (5, 6, 5, CURRENT_DATE + 14);
UPDATE book_copy SET status = 'on_loan' WHERE copy_id = 5;
\! sleep 2
\echo '[4s] A: COMMIT'
COMMIT;
