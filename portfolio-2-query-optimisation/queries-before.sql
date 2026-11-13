-- Portfolio 2: the five test queries BEFORE adding any new indexes.
-- Only the indexes from Part 1 exist at this point (primary keys, unique
-- keys and the two partial unique indexes).
-- Run after bulk-data.sql.

-- Q1. A member's borrowing history, newest first (the desk looks this up
--     when a student comes to the counter).
\echo '=== Q1: loan history for member 57 (latest 20) ==='
EXPLAIN (ANALYZE, BUFFERS)
SELECT l.loan_id, t.title, c.accession_number, l.lent_at::date AS lent_on,
       l.due_date, l.returned_at::date AS returned_on
FROM loan l
JOIN book_copy c ON c.copy_id  = l.copy_id
JOIN title     t ON t.title_id = c.title_id
WHERE l.member_id = 57
ORDER BY l.lent_at DESC
LIMIT 20;

-- Q2. Overdue report: books still out past their due date, per campus,
--     with the fine owed so far (UGX 500 per late day).
\echo '=== Q2: overdue loans per campus with fine owed ==='
EXPLAIN (ANALYZE, BUFFERS)
SELECT ca.name AS campus,
       count(*) AS overdue_loans,
       sum(500 * (CURRENT_DATE - l.due_date)) AS fine_owed_ugx
FROM loan l
JOIN book_copy c ON c.copy_id   = l.copy_id
JOIN campus   ca ON ca.campus_id = c.campus_id
WHERE l.returned_at IS NULL
  AND l.due_date < CURRENT_DATE
GROUP BY ca.name
ORDER BY overdue_loans DESC;

-- Q3. Catalogue search: all titles by an author whose name contains 'achebe'.
\echo '=== Q3: catalogue search by author name ==='
EXPLAIN (ANALYZE, BUFFERS)
SELECT t.title_id, t.title, a.full_name AS author, cat.name AS category
FROM author a
JOIN book_author ba ON ba.author_id  = a.author_id
JOIN title t        ON t.title_id    = ba.title_id
JOIN category cat   ON cat.category_id = t.category_id
WHERE a.full_name ILIKE '%achebe%'
ORDER BY t.title;

-- Q4. Most borrowed titles in the last 90 days (top 10).
\echo '=== Q4: top 10 most borrowed titles, last 90 days ==='
EXPLAIN (ANALYZE, BUFFERS)
SELECT t.title_id, t.title, count(*) AS times_borrowed
FROM loan l
JOIN book_copy c ON c.copy_id  = l.copy_id
JOIN title     t ON t.title_id = c.title_id
WHERE l.lent_at >= now() - interval '90 days'
GROUP BY t.title_id, t.title
ORDER BY times_borrowed DESC
LIMIT 10;

-- Q5. Is there a free copy of title 1736 at campus 2 right now?
\echo '=== Q5: available copies of title 1736 at campus 2 ==='
EXPLAIN (ANALYZE, BUFFERS)
SELECT c.copy_id, c.accession_number, c.shelf
FROM book_copy c
WHERE c.title_id  = 1736
  AND c.campus_id = 2
  AND c.status    = 'available';
