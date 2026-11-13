-- Demo 6, Window A: a lost update.
-- Fine 1 is UGX 3,000. Two cashiers take part payments at the same time:
-- A takes 1,000 and B takes 500, so 1,500 should be left.
-- Each cashier reads the amount, works out the new amount, and writes it back.
\echo '[setup] A: make fine 1 unpaid with UGX 3,000 owing'
UPDATE fine SET status = 'unpaid', paid_at = NULL, amount = 3000 WHERE fine_id = 1;
\! sleep 1
\echo '[1s] A: read the fine'
BEGIN;
SELECT fine_id, amount FROM fine WHERE fine_id = 1;
\! sleep 2
\echo '[3s] A: 3000 - 1000 = 2000, write 2000'
UPDATE fine SET amount = 2000 WHERE fine_id = 1;
\! sleep 2
\echo '[5s] A: COMMIT'
COMMIT;
