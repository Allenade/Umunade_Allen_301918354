-- Small sample data set (made-up records) to prove the schema works.

INSERT INTO campus (name, city) VALUES
 ('Naalya Main Campus', 'Kampala'),
 ('Naalya Lugazi Campus', 'Lugazi');

INSERT INTO member (campus_id, full_name, email, type, class_name) VALUES
 (1, 'Grace Namuli',     'grace.namuli@example.com',   'librarian', NULL),
 (1, 'Brian Okello',     'brian.okello@example.com',   'student',   'S3'),
 (1, 'Aisha Nakato',     'aisha.nakato@example.com',   'student',   'S5'),
 (1, 'Peter Mugisha',    'peter.mugisha@example.com',  'staff',     NULL),
 (2, 'Joan Akello',      'joan.akello@example.com',    'librarian', NULL),
 (2, 'Daniel Ssempa',    'daniel.ssempa@example.com',  'student',   'S2');

INSERT INTO category (name) VALUES ('Science'), ('Mathematics'), ('Literature'), ('History');

INSERT INTO title (isbn, title, publisher, published_year, category_id) VALUES
 ('9780198529132', 'Biology for Secondary Schools', 'Oxford',    2016, 1),
 ('9780435966300', 'Things Fall Apart',             'Heinemann', 1958, 3),
 ('9781107613805', 'Core Mathematics',              'Cambridge', 2018, 2),
 ('9780521777339', 'A History of East Africa',      'Cambridge', 2001, 4);

INSERT INTO author (full_name) VALUES
 ('M. B. V. Roberts'), ('Chinua Achebe'), ('Hugh Neill'), ('Douglas Quadling'), ('Kenneth Ingham');

INSERT INTO book_author VALUES (1,1), (2,2), (3,3), (3,4), (4,5);

INSERT INTO book_copy (title_id, campus_id, accession_number, shelf, status) VALUES
 (1, 1, 'MC-0001', 'A1', 'on_loan'),
 (1, 1, 'MC-0002', 'A1', 'available'),
 (2, 1, 'MC-0003', 'C2', 'on_loan'),
 (3, 1, 'MC-0004', 'B1', 'available'),
 (4, 2, 'LG-0001', 'D1', 'available'),
 (2, 2, 'LG-0002', 'C1', 'available');

INSERT INTO loan (copy_id, member_id, lent_by, lent_at, due_date, returned_at) VALUES
 (1, 2, 1, now() - interval '20 days', (now() - interval '6 days')::date, NULL),  -- overdue
 (3, 3, 1, now() - interval '3 days',  (now() + interval '11 days')::date, NULL),
 (4, 4, 1, now() - interval '30 days', (now() - interval '16 days')::date, now() - interval '10 days');

INSERT INTO hold (title_id, member_id, status) VALUES (2, 6, 'waiting');

INSERT INTO fine (loan_id, amount, reason, status) VALUES (3, 3000.00, 'overdue', 'paid');
