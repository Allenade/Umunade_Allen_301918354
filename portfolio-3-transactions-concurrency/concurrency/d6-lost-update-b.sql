-- Demo 6, Window B: the second cashier.
\! sleep 2
\echo '[2s] B: read the fine'
BEGIN;
SELECT fine_id, amount FROM fine WHERE fine_id = 1;
\! sleep 2
\echo '[4s] B: 3000 - 500 = 2500, write 2500 (waits for A, then overwrites A)'
\timing on
UPDATE fine SET amount = 2500 WHERE fine_id = 1;
\timing off
COMMIT;
\echo 'B: final amount - should be 1500, but A''s payment of 1000 has been lost'
SELECT fine_id, amount FROM fine WHERE fine_id = 1;
