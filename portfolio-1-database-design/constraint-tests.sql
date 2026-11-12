-- Each statement below SHOULD FAIL. They prove the constraints protect the data.

-- 1. Same copy lent twice while still out (unique partial index)
INSERT INTO loan (copy_id, member_id, lent_by, due_date) VALUES (1, 3, 1, CURRENT_DATE + 14);

-- 2. Duplicate ISBN (unique key)
INSERT INTO title (isbn, title, category_id) VALUES ('9780435966300', 'Duplicate', 3);

-- 3. Class name on a staff member (check constraint)
INSERT INTO member (campus_id, full_name, email, type, class_name)
VALUES (1, 'Wrong Row', 'wrong@example.com', 'staff', 'S1');

-- 4. Copy pointing to a title that does not exist (foreign key)
INSERT INTO book_copy (title_id, campus_id, accession_number) VALUES (999, 1, 'MC-9999');

-- 5. Deleting a title that still has copies (ON DELETE RESTRICT)
DELETE FROM title WHERE title_id = 1;
