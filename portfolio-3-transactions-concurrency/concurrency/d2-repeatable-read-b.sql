-- Demo 2, Window B (same as Demo 1): change copy 5 while Window A's transaction is open.
\! sleep 1
\echo '[1s] B: mark copy 5 as damaged (auto-commit)'
UPDATE book_copy SET status = 'damaged' WHERE copy_id = 5;
