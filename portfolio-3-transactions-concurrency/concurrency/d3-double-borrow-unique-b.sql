-- Demo 3, Window B: the second librarian, a moment later.
\! sleep 1
\echo '[1s] B (librarian 1): check copy 5'
BEGIN;
SELECT copy_id, status FROM book_copy WHERE copy_id = 5;
\! sleep 2
\echo '[3s] B: it looked available, so lend it to member 4 (this has to wait for A)'
\timing on
INSERT INTO loan (copy_id, member_id, lent_by, due_date) VALUES (5, 4, 1, CURRENT_DATE + 14);
\timing off
UPDATE book_copy SET status = 'on_loan' WHERE copy_id = 5;
ROLLBACK;
\! sleep 1
\echo 'B: final state - copy 5 has exactly one open loan'
SELECT loan_id, copy_id, member_id, lent_by FROM loan WHERE copy_id = 5 AND returned_at IS NULL;
