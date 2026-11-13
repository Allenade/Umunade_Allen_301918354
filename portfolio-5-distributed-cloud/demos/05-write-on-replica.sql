-- Run on the REPLICA: writes must be refused, because a standby is read-only.
\echo '=== Replica: try to lend copy 4 here ==='
INSERT INTO loan (copy_id, member_id, lent_by, due_date) VALUES (4, 6, 5, CURRENT_DATE + 14);
\echo '=== Replica: try to change a copy ==='
UPDATE book_copy SET shelf = 'Z9' WHERE copy_id = 4;
\echo '=== Replica: try to create a table ==='
CREATE TABLE test_table (id int);
\echo '=== Replica: reading still works ==='
SELECT copy_id, status, shelf FROM book_copy WHERE copy_id = 4;
