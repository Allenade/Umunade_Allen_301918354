-- Portfolio 3, part A: transactions in one session.
-- Run after Part 1 schema.sql + seed.sql and borrow-function.sql.
--
-- Seed data used here (from Part 1):
--   copy 1 (Biology, Main Campus)   - already on loan to member 2
--   copy 2 (Biology, Main Campus)   - available
--   copy 3 (Things Fall Apart, Main) - already on loan to member 3
--   copy 4 (Core Mathematics, Main) - available
--   copy 6 (Things Fall Apart, Lugazi) - available
--   members: 1 and 5 are librarians, 2, 3 and 6 are students, 4 is staff

\echo ''
\echo '=============================================================='
\echo 'A1. COMMIT: member 4 borrows copy 2, step by step'
\echo '=============================================================='
BEGIN;
-- Step 1: lock the copy and check it is available.
SELECT copy_id, status FROM book_copy WHERE copy_id = 2 FOR UPDATE;
-- Step 2: record the loan.
INSERT INTO loan (copy_id, member_id, lent_by, due_date)
VALUES (2, 4, 1, CURRENT_DATE + 14)
RETURNING loan_id, copy_id, member_id, due_date;
-- Step 3: mark the copy as on loan.
UPDATE book_copy SET status = 'on_loan' WHERE copy_id = 2;
COMMIT;

\echo 'After COMMIT, both changes are saved together:'
SELECT c.copy_id, c.status, l.loan_id, l.member_id, l.returned_at
FROM book_copy c
JOIN loan l ON l.copy_id = c.copy_id AND l.returned_at IS NULL
WHERE c.copy_id = 2;

\echo ''
\echo '=============================================================='
\echo 'A2. ROLLBACK: member 6 tries to borrow copy 6 AND copy 1 together.'
\echo '    Copy 1 is already on loan, so the second insert breaks the'
\echo '    "one open loan per copy" rule from Part 1.'
\echo '=============================================================='
BEGIN;
INSERT INTO loan (copy_id, member_id, lent_by, due_date)
VALUES (6, 6, 5, CURRENT_DATE + 14)
RETURNING loan_id, copy_id;
UPDATE book_copy SET status = 'on_loan' WHERE copy_id = 6;
-- Inside the transaction copy 6 now looks borrowed:
SELECT copy_id, status FROM book_copy WHERE copy_id = 6;
-- This one fails:
INSERT INTO loan (copy_id, member_id, lent_by, due_date)
VALUES (1, 6, 5, CURRENT_DATE + 14);
-- After an error PostgreSQL refuses every other command until we end the transaction:
SELECT copy_id, status FROM book_copy WHERE copy_id = 6;
ROLLBACK;

\echo 'After ROLLBACK, nothing from A2 was saved (copy 6 is still available, member 6 has no loans):'
SELECT copy_id, status FROM book_copy WHERE copy_id = 6;
SELECT count(*) AS loans_for_member_6 FROM loan WHERE member_id = 6;

\echo ''
\echo '=============================================================='
\echo 'A3. The same rule through borrow_copy(): it checks first and'
\echo '    stops with a clear message, and the transaction is undone.'
\echo '=============================================================='
BEGIN;
SELECT borrow_copy(6, 6, 5) AS new_loan_id;
SELECT borrow_copy(1, 6, 5) AS new_loan_id;
ROLLBACK;
SELECT copy_id, status FROM book_copy WHERE copy_id = 6;

\echo ''
\echo '=============================================================='
\echo 'A4. SAVEPOINT: member 6 borrows copy 6, then tries copy 3'
\echo '    (already out). Only the failed part is undone, then copy 4'
\echo '    is borrowed instead and everything is committed.'
\echo '=============================================================='
BEGIN;
SELECT borrow_copy(6, 6, 5) AS first_loan_id;
SAVEPOINT second_book;
SELECT borrow_copy(3, 6, 5) AS second_loan_id;
ROLLBACK TO SAVEPOINT second_book;
SELECT borrow_copy(4, 6, 5) AS second_loan_id;
COMMIT;

\echo 'Member 6 now has copies 6 and 4, and copy 3 was not touched:'
SELECT l.loan_id, l.copy_id, c.status
FROM loan l JOIN book_copy c ON c.copy_id = l.copy_id
WHERE l.member_id = 6
ORDER BY l.loan_id;
SELECT copy_id, status FROM book_copy WHERE copy_id = 3;

\echo ''
\echo '=============================================================='
\echo 'A5. Consistency: the database refuses data that breaks its rules.'
\echo '=============================================================='
-- A due date before the day the book was lent (CHECK chk_due_after_lent):
INSERT INTO loan (copy_id, member_id, lent_by, due_date)
VALUES (5, 2, 1, CURRENT_DATE - 1);
-- A negative fine (CHECK on fine.amount):
UPDATE fine SET amount = -500 WHERE fine_id = 1;
-- A loan for a member who does not exist (foreign key):
INSERT INTO loan (copy_id, member_id, lent_by, due_date)
VALUES (5, 999, 1, CURRENT_DATE + 14);
\echo 'Copy 5 still has no loan and fine 1 still has its old amount:'
SELECT count(*) AS loans_for_copy_5 FROM loan WHERE copy_id = 5;
SELECT fine_id, amount FROM fine WHERE fine_id = 1;
