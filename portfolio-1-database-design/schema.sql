-- Naalya Schools Library Management System
-- Portfolio 1: relational schema (PostgreSQL 16)

DROP TABLE IF EXISTS fine, hold, loan, book_copy, book_author, author, title, category, member, campus CASCADE;
DROP TYPE IF EXISTS member_type, copy_status, hold_status, fine_status CASCADE;

CREATE TYPE member_type AS ENUM ('student', 'staff', 'librarian');
CREATE TYPE copy_status AS ENUM ('available', 'on_loan', 'on_hold', 'damaged', 'lost');
CREATE TYPE hold_status AS ENUM ('waiting', 'ready', 'fulfilled', 'cancelled', 'expired');
CREATE TYPE fine_status AS ENUM ('unpaid', 'paid', 'waived');

-- A school can have several campuses; each campus runs its own library.
CREATE TABLE campus (
    campus_id   SERIAL PRIMARY KEY,
    name        VARCHAR(100) NOT NULL UNIQUE,
    city        VARCHAR(60)  NOT NULL
);

-- Anyone who can borrow (students, staff) or run the desk (librarians).
CREATE TABLE member (
    member_id   SERIAL PRIMARY KEY,
    campus_id   INT          NOT NULL REFERENCES campus(campus_id),
    full_name   VARCHAR(120) NOT NULL,
    email       VARCHAR(150) NOT NULL UNIQUE,
    type        member_type  NOT NULL,
    class_name  VARCHAR(30),                       -- only for students, e.g. 'S3'
    joined_on   DATE         NOT NULL DEFAULT CURRENT_DATE,
    CONSTRAINT chk_class_only_students
        CHECK (type = 'student' OR class_name IS NULL)
);

CREATE TABLE category (
    category_id SERIAL PRIMARY KEY,
    name        VARCHAR(60) NOT NULL UNIQUE
);

-- A title is the book as a work (one ISBN); copies are the physical books.
CREATE TABLE title (
    title_id       SERIAL PRIMARY KEY,
    isbn           VARCHAR(13)  UNIQUE,
    title          VARCHAR(200) NOT NULL,
    publisher      VARCHAR(120),
    published_year INT CHECK (published_year BETWEEN 1450 AND 2100),
    category_id    INT NOT NULL REFERENCES category(category_id) ON DELETE RESTRICT,
    CONSTRAINT chk_isbn_length CHECK (isbn IS NULL OR length(isbn) IN (10, 13))
);

CREATE TABLE author (
    author_id SERIAL PRIMARY KEY,
    full_name VARCHAR(120) NOT NULL
);

-- Many-to-many: a title can have several authors, an author several titles.
CREATE TABLE book_author (
    title_id  INT NOT NULL REFERENCES title(title_id)  ON DELETE CASCADE,
    author_id INT NOT NULL REFERENCES author(author_id) ON DELETE CASCADE,
    PRIMARY KEY (title_id, author_id)
);

CREATE TABLE book_copy (
    copy_id          SERIAL PRIMARY KEY,
    title_id         INT NOT NULL REFERENCES title(title_id)  ON DELETE RESTRICT,
    campus_id        INT NOT NULL REFERENCES campus(campus_id),
    accession_number VARCHAR(20) NOT NULL,
    shelf            VARCHAR(20),
    status           copy_status NOT NULL DEFAULT 'available',
    CONSTRAINT uq_accession_per_campus UNIQUE (campus_id, accession_number)
);

CREATE TABLE loan (
    loan_id     SERIAL PRIMARY KEY,
    copy_id     INT  NOT NULL REFERENCES book_copy(copy_id) ON DELETE RESTRICT,
    member_id   INT  NOT NULL REFERENCES member(member_id)  ON DELETE RESTRICT,
    lent_by     INT  NOT NULL REFERENCES member(member_id),
    lent_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    due_date    DATE NOT NULL,
    returned_at TIMESTAMPTZ,
    CONSTRAINT chk_due_after_lent   CHECK (due_date >= lent_at::date),
    CONSTRAINT chk_return_after_lent CHECK (returned_at IS NULL OR returned_at >= lent_at)
);

-- Business rule: a physical copy can only have ONE open loan at a time.
CREATE UNIQUE INDEX uq_one_open_loan_per_copy
    ON loan (copy_id) WHERE returned_at IS NULL;

-- A reservation for a title when no copy is free.
CREATE TABLE hold (
    hold_id      SERIAL PRIMARY KEY,
    title_id     INT NOT NULL REFERENCES title(title_id)   ON DELETE CASCADE,
    member_id    INT NOT NULL REFERENCES member(member_id) ON DELETE CASCADE,
    status       hold_status NOT NULL DEFAULT 'waiting',
    requested_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    expires_at   TIMESTAMPTZ
);

-- Business rule: a member can only have one live hold per title.
CREATE UNIQUE INDEX uq_one_live_hold
    ON hold (title_id, member_id) WHERE status IN ('waiting', 'ready');

-- A fine belongs to exactly one late or lost loan.
CREATE TABLE fine (
    fine_id   SERIAL PRIMARY KEY,
    loan_id   INT NOT NULL UNIQUE REFERENCES loan(loan_id) ON DELETE CASCADE,
    amount    NUMERIC(10,2) NOT NULL CHECK (amount > 0),
    reason    VARCHAR(20)   NOT NULL CHECK (reason IN ('overdue', 'lost', 'damaged')),
    status    fine_status   NOT NULL DEFAULT 'unpaid',
    issued_at TIMESTAMPTZ   NOT NULL DEFAULT now(),
    paid_at   TIMESTAMPTZ
);
