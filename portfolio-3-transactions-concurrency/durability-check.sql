-- Portfolio 3: durability check.
-- Run this after transactions.sql AND after the database server has been
-- killed and started again. The loans committed in A1 and A4 must still be there.

\echo 'Open loans after the server restart:'
SELECT l.loan_id, l.copy_id, l.member_id, c.status
FROM loan l JOIN book_copy c ON c.copy_id = l.copy_id
WHERE l.returned_at IS NULL
ORDER BY l.loan_id;
