-- Portfolio 2: bulk test data for the Naalya library database.
-- Run this AFTER Part 1 schema.sql and seed.sql.
-- Everything here is made-up data built with generate_series().
-- Rough size: 5 campuses, 50,000 members, 20,000 titles, 100,000 copies,
-- about 500,000 loans, 40,000 holds and the fines that go with late loans.

\timing on

-- Same random numbers every time, so results can be repeated.
SELECT setseed(0.42);

BEGIN;

-- 1. Three more campuses (the seed already has 2).
INSERT INTO campus (name, city) VALUES
 ('Naalya Bweyogerere Campus', 'Wakiso'),
 ('Naalya Kira Campus',        'Kira'),
 ('Naalya Mukono Campus',      'Mukono');

-- 2. More categories (the seed has 4).
INSERT INTO category (name) VALUES
 ('Physics'), ('Chemistry'), ('Geography'), ('Economics'), ('Religious Education'),
 ('Computer Studies'), ('English Language'), ('Kiswahili'), ('French'), ('Agriculture'),
 ('Fine Art'), ('Music'), ('Entrepreneurship'), ('Fiction'), ('Biography'), ('Reference');

-- 3. 50,000 members: about 1% librarians, 10% staff, the rest students in S1-S6.
--    The last 5,000 members are new this term (joined in the last 60 days)
--    and have not borrowed anything yet.
INSERT INTO member (campus_id, full_name, email, type, class_name, joined_on)
SELECT 1 + (g % 5),
       (ARRAY['Grace','Brian','Aisha','Peter','Joan','Daniel','Ruth','Isaac','Mary','Samuel',
              'Esther','Moses','Sarah','Joseph','Agnes','David','Faith','Ivan','Doreen','Henry'])[1 + floor(random()*20)::int]
       || ' ' ||
       (ARRAY['Namuli','Okello','Nakato','Mugisha','Akello','Ssempa','Nansubuga','Kato','Achieng','Wasswa',
              'Babirye','Opio','Atim','Lubega','Nabirye','Ouma','Kyomuhendo','Tumusiime','Auma','Kizza'])[1 + floor(random()*20)::int],
       'member' || g || '@example.com',
       t.mtype,
       CASE WHEN t.mtype = 'student' THEN 'S' || (1 + floor(random()*6)::int) END,
       CASE WHEN g > 45000 THEN CURRENT_DATE - floor(random()*60)::int
            ELSE CURRENT_DATE - 60 - floor(random()*2000)::int END
FROM generate_series(1, 50000) AS g
CROSS JOIN LATERAL (
    SELECT CASE WHEN g % 100 = 0 THEN 'librarian'::member_type
                WHEN g % 10  = 0 THEN 'staff'::member_type
                ELSE 'student'::member_type END AS mtype
) AS t;

-- 4. 8,000 authors.
INSERT INTO author (full_name)
SELECT (ARRAY['A.','B.','C.','D.','E.','F.','G.','H.','J.','K.','L.','M.','N.','P.','R.','S.','T.','W.'])[1 + floor(random()*18)::int]
       || ' ' ||
       (ARRAY['Achebe','Ngugi','Okot','Soyinka','Adichie','Mazrui','Roberts','Neill','Quadling','Ingham',
              'Kiwanuka','Mwangi','Byaruhanga','Smith','Brown','Taylor','Wilson','Clarke','Mensah','Banda',
              'Otieno','Kamau','Musoke','Johnson','Walker','Hughes','Evans','Owusu','Phiri','Ndlovu'])[1 + floor(random()*30)::int]
       || '-' || g
FROM generate_series(1, 8000) AS g;

-- 5. 20,000 titles spread over the 20 categories.
INSERT INTO title (isbn, title, publisher, published_year, category_id)
SELECT '978' || lpad(g::text, 10, '0'),
       (ARRAY['Introduction to','Foundations of','Essential','Revision Guide for','Advanced','A Short History of',
              'Practical','Understanding','Exploring','New Certificate'])[1 + floor(random()*10)::int]
       || ' ' ||
       (ARRAY['Biology','Chemistry','Physics','Mathematics','Geography','History','Economics','Literature',
              'Agriculture','Computer Studies','Fine Art','Music','Kiswahili','French','English'])[1 + floor(random()*15)::int]
       || ' Book ' || g,
       (ARRAY['Oxford','Cambridge','Longman','Heinemann','Fountain','Macmillan','Pearson','MK Publishers'])[1 + floor(random()*8)::int],
       1960 + floor(random()*66)::int,
       1 + floor(random()*20)::int
FROM generate_series(1, 20000) AS g;

-- 6. Every new title gets one author; about one in five gets a second author.
INSERT INTO book_author (title_id, author_id)
SELECT t.title_id, 1 + floor(random()*8000)::int + 5
FROM title t WHERE t.title_id > 4;

INSERT INTO book_author (title_id, author_id)
SELECT t.title_id, 1 + floor(random()*8000)::int + 5
FROM title t WHERE t.title_id > 4 AND random() < 0.2
ON CONFLICT DO NOTHING;

-- 7. 100,000 physical copies. Status is fixed further down, after the loans exist.
INSERT INTO book_copy (title_id, campus_id, accession_number, shelf, status)
SELECT 1 + floor(random()*20004)::int,
       1 + floor(random()*5)::int,
       'BK-' || lpad(g::text, 7, '0'),
       chr(65 + floor(random()*8)::int) || (1 + floor(random()*20)::int),
       'available'
FROM generate_series(1, 100000) AS g;

-- Helper list of librarian ids, used for the "lent_by" column.
CREATE TEMP TABLE librarians AS
SELECT row_number() OVER (ORDER BY member_id) AS rn, member_id
FROM member WHERE type = 'librarian';

-- 8a. 490,000 returned (closed) loans over the last 3 years, by members
--     1 to 45,006 (the older members).
--     About 15% came back late. Returned loans never clash with the
--     "one open loan per copy" rule because returned_at is set.
INSERT INTO loan (copy_id, member_id, lent_by, lent_at, due_date, returned_at)
SELECT x.copy_id, x.member_id, l.member_id, x.lent_at,
       (x.lent_at + interval '14 days')::date,
       x.lent_at + CASE WHEN x.late THEN interval '15 days' + random() * interval '30 days'
                        ELSE random() * interval '13 days' END
FROM (
    SELECT 1 + floor(random()*100006)::int        AS copy_id,
           1 + floor(random()*45006)::int         AS member_id,
           now() - interval '30 days' - random() * interval '1065 days' AS lent_at,
           random() < 0.15                        AS late,
           1 + floor(random()*(SELECT count(*) FROM librarians))::int AS lib_rn
    FROM generate_series(1, 490000)
) AS x
JOIN librarians l ON l.rn = x.lib_rn;

-- 8b. About 10,000 open loans (books still out), each on a different copy.
--     Roughly one copy in ten is out right now.
--     Lent in the last 25 days with a 14 day due date, so some are overdue.
INSERT INTO loan (copy_id, member_id, lent_by, lent_at, due_date, returned_at)
SELECT c.copy_id,
       1 + floor(random()*45006)::int,
       (SELECT member_id FROM librarians ORDER BY rn LIMIT 1 OFFSET (c.copy_id % 500)),
       c.lent_at,
       (c.lent_at + interval '14 days')::date,
       NULL
FROM (
    SELECT copy_id, now() - random() * interval '25 days' AS lent_at
    FROM book_copy
    WHERE copy_id > 6 AND random() < 0.10
) AS c;

-- 9. Copy status must match the loans: copies with an open loan are on_loan,
--    and a few others are damaged or lost.
UPDATE book_copy c SET status = 'on_loan'
WHERE EXISTS (SELECT 1 FROM loan l WHERE l.copy_id = c.copy_id AND l.returned_at IS NULL);

UPDATE book_copy SET status = CASE WHEN copy_id % 2 = 0 THEN 'damaged'::copy_status ELSE 'lost'::copy_status END
WHERE status = 'available' AND copy_id > 6 AND copy_id % 97 = 0;

-- 10. Fines for every late return (UGX 500 per late day, capped at 20,000).
--     Older fines are mostly paid; the last 90 days are mostly unpaid.
INSERT INTO fine (loan_id, amount, reason, status, issued_at, paid_at)
SELECT f.loan_id, f.amount, 'overdue', f.st, f.returned_at,
       CASE WHEN f.st = 'paid' THEN f.returned_at + interval '7 days' END
FROM (
    SELECT l.loan_id, l.returned_at,
           LEAST(500 * (l.returned_at::date - l.due_date), 20000)::numeric(10,2) AS amount,
           CASE WHEN l.returned_at > now() - interval '90 days' AND random() < 0.7 THEN 'unpaid'::fine_status
                WHEN random() < 0.05 THEN 'waived'::fine_status
                ELSE 'paid'::fine_status END AS st
    FROM loan l
    WHERE l.returned_at IS NOT NULL
      AND l.returned_at::date > l.due_date
      AND l.loan_id > 3
) AS f;

-- 11. Holds. Old holds that are finished (fulfilled, cancelled, expired) ...
INSERT INTO hold (title_id, member_id, status, requested_at, expires_at)
SELECT 1 + floor(random()*20004)::int,
       1 + floor(random()*50006)::int,
       (ARRAY['fulfilled','cancelled','expired']::hold_status[])[1 + floor(random()*3)::int],
       x.req, x.req + interval '7 days'
FROM (SELECT now() - interval '10 days' - random() * interval '1000 days' AS req
      FROM generate_series(1, 36000)) AS x;

-- ... and about 4,000 live holds (waiting or ready). ON CONFLICT skips any
-- random pair that would break the "one live hold per member per title" rule.
INSERT INTO hold (title_id, member_id, status, requested_at, expires_at)
SELECT 1 + floor(random()*20004)::int,
       1 + floor(random()*50006)::int,
       CASE WHEN random() < 0.8 THEN 'waiting'::hold_status ELSE 'ready'::hold_status END,
       x.req, x.req + interval '7 days'
FROM (SELECT now() - random() * interval '10 days' AS req
      FROM generate_series(1, 4000)) AS x
ON CONFLICT DO NOTHING;

COMMIT;

-- Refresh the planner's statistics so EXPLAIN uses the real row counts.
VACUUM ANALYZE;

-- Quick check of the row counts.
SELECT * FROM (VALUES
  ('campus',      (SELECT count(*) FROM campus)),
  ('member',      (SELECT count(*) FROM member)),
  ('category',    (SELECT count(*) FROM category)),
  ('title',       (SELECT count(*) FROM title)),
  ('author',      (SELECT count(*) FROM author)),
  ('book_author', (SELECT count(*) FROM book_author)),
  ('book_copy',   (SELECT count(*) FROM book_copy)),
  ('loan',        (SELECT count(*) FROM loan)),
  ('open loans',  (SELECT count(*) FROM loan WHERE returned_at IS NULL)),
  ('overdue',     (SELECT count(*) FROM loan WHERE returned_at IS NULL AND due_date < CURRENT_DATE)),
  ('hold',        (SELECT count(*) FROM hold)),
  ('fine',        (SELECT count(*) FROM fine))
) AS t(table_name, row_count);
