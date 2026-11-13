-- Portfolio 2: new indexes for the five test queries.
-- Part 1 already gave us the primary keys, the unique keys and two partial
-- unique indexes (one open loan per copy, one live hold per member per title),
-- so none of those are repeated here.

\timing on

-- Q1: a member's loan history, newest first.
-- loan.member_id is a foreign key, but PostgreSQL does not index foreign keys
-- on its own. Putting lent_at second (DESC) means the rows come out of the
-- index already in the right order, so there is no sort and LIMIT 20 can stop early.
CREATE INDEX idx_loan_member_lent
    ON loan (member_id, lent_at DESC);

-- Q2: overdue report.
-- Partial index: only open loans (returned_at IS NULL) go in, which is about
-- 2% of the loan table, so the index is tiny. INCLUDE (copy_id) stores the
-- copy id in the index too, so the query can read it without visiting the table.
CREATE INDEX idx_loan_open_due
    ON loan (due_date) INCLUDE (copy_id)
    WHERE returned_at IS NULL;

-- Q3: catalogue search with ILIKE '%achebe%'.
-- A normal B-tree cannot help when the pattern starts with %, but a trigram
-- (GIN) index can. pg_trgm ships with PostgreSQL.
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE INDEX idx_author_name_trgm
    ON author USING gin (full_name gin_trgm_ops);

-- Q3 also joins book_author by author_id. The primary key is
-- (title_id, author_id), which only helps when searching by title first.
CREATE INDEX idx_book_author_author
    ON book_author (author_id);

-- Q4: loans in the last 90 days.
-- Range search on lent_at; INCLUDE (copy_id) lets PostgreSQL answer from the
-- index alone (index-only scan).
CREATE INDEX idx_loan_lent_at
    ON loan (lent_at) INCLUDE (copy_id);

-- Q5: free copies of one title at one campus.
-- Also covers the title_id foreign key, which had no index.
CREATE INDEX idx_copy_title_campus
    ON book_copy (title_id, campus_id);

-- Update statistics so the planner knows about the new indexes.
ANALYZE;

-- Size of each new index (the storage cost).
SELECT indexrelname AS index_name,
       relname      AS table_name,
       pg_size_pretty(pg_relation_size(indexrelid)) AS index_size
FROM pg_stat_user_indexes
WHERE indexrelname IN ('idx_loan_member_lent', 'idx_loan_open_due', 'idx_author_name_trgm',
                       'idx_book_author_author', 'idx_loan_lent_at', 'idx_copy_title_campus')
ORDER BY pg_relation_size(indexrelid) DESC;

-- The loan table compared with all of its indexes together.
SELECT pg_size_pretty(pg_relation_size('loan')) AS loan_table_size,
       pg_size_pretty(pg_indexes_size('loan'))  AS loan_all_indexes_size;
