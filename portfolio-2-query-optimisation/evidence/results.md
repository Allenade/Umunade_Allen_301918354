# Part 2 results: execution time before and after

Times are the "Execution Time" reported by `EXPLAIN (ANALYZE, BUFFERS)`, in milliseconds.
Each query was run once to warm up, then 5 more times; the table shows the median
of the 5 runs. All raw times are in `timing-runs-before.txt` and `timing-runs-after.txt`.
The full plans in `before.txt` and `after.txt` come from one separate run, so their
times are close to, but not exactly, the medians below.

Test machine: PostgreSQL 16.16, default settings (shared_buffers 128 MB, work_mem 4 MB).

## Indexes (queries-before.sql vs queries-after.sql)

| Query | What it does | Before (ms) | After (ms) | Change | Main plan change |
|-------|--------------|------------:|-----------:|-------:|------------------|
| Q1 | A member's loan history (latest 20) | 9.87 | 0.20 | about 51x faster | Parallel Seq Scan on loan -> Bitmap Index Scan on idx_loan_member_lent |
| Q2 | Overdue loans per campus with fine owed | 13.34 | 12.82 | about 4% faster | Bitmap scan on uq_one_open_loan_per_copy -> Index Only Scan on idx_loan_open_due (book_copy is still read in full) |
| Q3 | Catalogue search by author name (ILIKE) | 6.77 | 4.07 | about 1.7x faster | Seq Scan on author -> Bitmap Index Scan on idx_author_name_trgm |
| Q4 | Top 10 titles borrowed in the last 90 days | 56.80 | 44.72 | about 1.3x faster | Parallel Seq Scan on loan -> Index Only Scan on idx_loan_lent_at |
| Q5 | Free copies of one title at one campus | 2.06 | 0.021 | about 98x faster | Bitmap scan of a whole campus (20,105 rows) -> Bitmap Index Scan on idx_copy_title_campus (6 rows) |

Every query returned the same rows before and after (Q1 9, Q2 5, Q3 774, Q4 10, Q5 6).

## Rewrites (rewrites.sql, run with the new indexes in place, one run each)

| Query | Version | Time (ms) | Plan |
|-------|---------|----------:|------|
| R1 loans last month | A: `date_trunc('month', lent_at) = ...` | 43.43 | Parallel Seq Scan on loan (the index cannot be used) |
| R1 loans last month | B: `lent_at >= ... AND lent_at < ...` | 1.30 | Index Only Scan on idx_loan_lent_at |
| R2 new members who never borrowed | A: `NOT IN (SELECT ...)` | 5340.51 | Seq Scan + SubPlan that re-reads all 499,984 loans for each of 116 members |
| R2 new members who never borrowed | B: `NOT EXISTS (...)` | 2.69 | Nested Loop Anti Join + Index Only Scan on idx_loan_member_lent |

Both versions of R2 return the same 116 members.

## Write cost (write-cost.sql: insert 50,000 loans, then roll back)

| Run | Before new indexes (ms) | After new indexes (ms) |
|-----|------------------------:|-----------------------:|
| 1 | 581.30 | 677.10 |
| 2 | 573.59 | 734.01 |
| 3 | 587.16 | 676.04 |

Inserting into loan got about 16% slower (median 581.30 -> 677.10 ms), because three of
the new indexes are on the loan table and each one has to be updated on every insert.

## Storage cost (from indexes-output.txt)

| Index | Table | Size |
|-------|-------|-----:|
| idx_loan_member_lent | loan | 15 MB |
| idx_loan_lent_at | loan | 15 MB |
| idx_copy_title_campus | book_copy | 1936 kB |
| idx_book_author_author | book_author | 360 kB |
| idx_author_name_trgm | author | 344 kB |
| idx_loan_open_due | loan | 240 kB |

The loan table itself is 32 MB; all of its indexes together (old and new) come to 45 MB.
