-- Demo 7, Window A: the same two payments, written safely.
-- Instead of writing back a number worked out earlier, each cashier lets
-- the database do the sum: amount = amount - payment. The row lock makes
-- B wait for A and then subtract from the NEW amount.
\echo '[setup] A: make fine 1 unpaid with UGX 3,000 owing'
UPDATE fine SET status = 'unpaid', paid_at = NULL, amount = 3000 WHERE fine_id = 1;
\! sleep 1
\echo '[1s] A: take 1,000'
BEGIN;
UPDATE fine SET amount = amount - 1000 WHERE fine_id = 1 RETURNING fine_id, amount;
\! sleep 2
\echo '[3s] A: COMMIT'
COMMIT;
