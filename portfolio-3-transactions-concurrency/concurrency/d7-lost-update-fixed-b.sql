-- Demo 7, Window B: the second cashier takes 500.
\! sleep 2
\echo '[2s] B: take 500 (waits for A)'
BEGIN;
\timing on
UPDATE fine SET amount = amount - 500 WHERE fine_id = 1 RETURNING fine_id, amount;
\timing off
COMMIT;
\echo 'B: final amount - 1500, both payments counted'
SELECT fine_id, amount FROM fine WHERE fine_id = 1;
