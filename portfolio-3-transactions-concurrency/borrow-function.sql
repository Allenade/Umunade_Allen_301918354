-- Portfolio 3: a "borrow a copy" function for the Naalya library.
-- It does the three steps of a loan in one go:
--   1. lock the copy row and check it is available
--   2. insert the loan
--   3. mark the copy as on_loan
-- A function always runs inside the caller's transaction, so if any step
-- fails, the whole thing is undone (nothing half-done is saved).

CREATE OR REPLACE FUNCTION borrow_copy(p_copy_id      INT,
                                       p_member_id    INT,
                                       p_librarian_id INT,
                                       p_days         INT DEFAULT 14)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE
    v_status  copy_status;
    v_loan_id INT;
BEGIN
    -- FOR UPDATE locks this copy, so a second librarian has to wait
    -- until this transaction finishes before they can check it.
    SELECT status INTO v_status
    FROM book_copy
    WHERE copy_id = p_copy_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'copy % does not exist', p_copy_id;
    END IF;

    IF v_status <> 'available' THEN
        RAISE EXCEPTION 'copy % is not available (status: %)', p_copy_id, v_status;
    END IF;

    INSERT INTO loan (copy_id, member_id, lent_by, due_date)
    VALUES (p_copy_id, p_member_id, p_librarian_id, CURRENT_DATE + p_days)
    RETURNING loan_id INTO v_loan_id;

    UPDATE book_copy SET status = 'on_loan' WHERE copy_id = p_copy_id;

    RETURN v_loan_id;
END;
$$;
