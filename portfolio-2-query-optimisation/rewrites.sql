-- Portfolio 2: query rewriting (run AFTER indexes.sql).
-- Indexes are not the whole story. The way a query is written decides
-- whether PostgreSQL can use an index at all.

-- R1. Loans made last month.
-- Version A wraps the column in a function. The index on lent_at stores raw
-- lent_at values, not date_trunc(lent_at), so it cannot be used.
\echo '=== R1a: last month loans, function on the column ==='
EXPLAIN (ANALYZE, BUFFERS)
SELECT count(*)
FROM loan
WHERE date_trunc('month', lent_at) = date_trunc('month', now()) - interval '1 month';

-- Version B asks the same question as a plain range on the column itself,
-- so the index on lent_at can be used.
\echo '=== R1b: last month loans, plain range ==='
EXPLAIN (ANALYZE, BUFFERS)
SELECT count(*)
FROM loan
WHERE lent_at >= date_trunc('month', now()) - interval '1 month'
  AND lent_at <  date_trunc('month', now());

-- R2. New members (joined in the last 7 days, campus 3) who have never borrowed.
-- Version A uses NOT IN. Because NOT IN has to handle NULLs in a special way,
-- PostgreSQL cannot turn it into an anti join; with 500,000 loans the list is
-- too big to hash in memory, so it re-reads the list for every member.
\echo '=== R2a: never borrowed, NOT IN ==='
EXPLAIN (ANALYZE, BUFFERS)
SELECT m.member_id, m.full_name
FROM member m
WHERE m.campus_id = 3
  AND m.joined_on >= CURRENT_DATE - 7
  AND m.member_id NOT IN (SELECT l.member_id FROM loan l);

-- Version B uses NOT EXISTS, which PostgreSQL runs as an anti join and can
-- check each member with one quick look-up in idx_loan_member_lent.
\echo '=== R2b: never borrowed, NOT EXISTS ==='
EXPLAIN (ANALYZE, BUFFERS)
SELECT m.member_id, m.full_name
FROM member m
WHERE m.campus_id = 3
  AND m.joined_on >= CURRENT_DATE - 7
  AND NOT EXISTS (SELECT 1 FROM loan l WHERE l.member_id = m.member_id);
