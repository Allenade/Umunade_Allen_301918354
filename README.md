# Naalya Schools Library Management System: Advanced Database Systems Portfolio

| | |
|---|---|
| **Student** | Umunade Allen |
| **Student ID** | 301918354 |
| **Course** | MIT 8103 Advanced Database Systems, Miva Open University |
| **Repository** | https://github.com/Allenade/Umunade_Allen_301918354 |

## Case study

Naalya Schools is a group of secondary schools in Uganda with more than one campus (for example
the Main campus and the Lugazi campus). Each campus runs its own library: books are catalogued,
physical copies are lent to students and staff, titles can be reserved, and late returns are
fined.

This portfolio designs and tests the database behind that library. The schema is a fresh,
simplified design based on the library module of the school's own system, and it is used with
the school's permission. No code was copied from the school's system, and **all records in this
repository are made-up sample data** (no real student information).

## Repository structure

| Folder | Part | What it shows |
|--------|------|---------------|
| [`portfolio-1-database-design`](portfolio-1-database-design) | 1. Database design | ER diagram, 10-table PostgreSQL schema normalised to BCNF, keys, CHECK and partial unique constraints, sample data and tests that break each rule |
| [`portfolio-2-query-optimisation`](portfolio-2-query-optimisation) | 2. Query optimisation | About 500,000 sample loans, five library queries measured with `EXPLAIN ANALYZE` before and after indexes, query rewrites, and the cost of indexes on writes |
| [`portfolio-3-transactions-concurrency`](portfolio-3-transactions-concurrency) | 3. Transactions and concurrency | COMMIT, ROLLBACK, savepoints, durability after a crash, isolation levels, two librarians lending the last copy, a lost update, and a deadlock |
| [`portfolio-4-nosql`](portfolio-4-nosql) | 4. NoSQL | The same library in MongoDB: document model, JSON Schema validation, CRUD, aggregation pipelines, indexes and a multi-document transaction, compared with SQL |
| [`portfolio-5-distributed-cloud`](portfolio-5-distributed-cloud) | 5. Distributed and cloud databases | A PostgreSQL primary and streaming replica, failover, sync vs async, loans partitioned by campus, sharding and CAP for a multi-campus school, and a managed cloud design |
| `docker-compose.yml` | | The PostgreSQL 16 container used by Parts 1 to 3 |

Each folder has its own `README.md` with the full explanation, the results and an
`evidence/` folder with the real output and screenshots.

## Prerequisites

- Docker (Docker Desktop or OrbStack) with Docker Compose
- `mongosh` (MongoDB Shell) for Part 4, or use the MongoDB Docker container in that folder
- No `psql` is needed on the laptop: every PostgreSQL command runs inside the container with
  `docker exec`

The main database container is `library_pg` (PostgreSQL 16, port 5433, user, password and
database all `library`).

## Quick start

Run everything from the repository root.

```bash
# start PostgreSQL 16 (used by Parts 1, 2 and 3)
docker compose up -d
```

**Part 1: design**

```bash
docker exec -i library_pg psql -U library -d library < portfolio-1-database-design/schema.sql
docker exec -i library_pg psql -U library -d library < portfolio-1-database-design/seed.sql
docker exec -i library_pg psql -U library -d library < portfolio-1-database-design/constraint-tests.sql
```

**Part 2: query optimisation** (starts from a fresh Part 1 database)

```bash
docker exec -i library_pg psql -U library -d library < portfolio-1-database-design/schema.sql
docker exec -i library_pg psql -U library -d library < portfolio-1-database-design/seed.sql
docker exec -i library_pg psql -U library -d library < portfolio-2-query-optimisation/bulk-data.sql
docker exec -i library_pg psql -U library -d library < portfolio-2-query-optimisation/queries-before.sql > before.txt
docker exec -i library_pg psql -U library -d library < portfolio-2-query-optimisation/indexes.sql
docker exec -i library_pg psql -U library -d library < portfolio-2-query-optimisation/queries-after.sql > after.txt
docker exec -i library_pg psql -U library -d library < portfolio-2-query-optimisation/rewrites.sql > rewrites.txt
```

See the Part 2 README for the write-cost test that runs before and after the indexes.

**Part 3: transactions and concurrency** (reloads the Part 1 data itself before each demo)

```bash
bash portfolio-3-transactions-concurrency/run-demos.sh
```

**Part 4: NoSQL** (with `mongod` running as a replica set, or with the Docker option in the Part 4 README)

```bash
bash portfolio-4-nosql/run-all.sh
```

**Part 5: distributed and cloud** (starts its own primary on port 5434 and replica on 5435)

```bash
bash portfolio-5-distributed-cloud/run-all.sh
docker compose -f portfolio-5-distributed-cloud/docker-compose.replication.yml down -v   # clean up afterwards
```

## What each part demonstrates

1. **Design:** a library schema in BCNF where the database itself enforces the business rules,
   for example one open loan per copy and one live reservation per member per title.
2. **Query optimisation:** how reading `EXPLAIN ANALYZE` plans leads to the right indexes and
   rewrites, and that indexes also slow down writes a little.
3. **Transactions and concurrency:** why borrowing a book must be one transaction, which problems
   each isolation level allows, and the safe pattern for lending (`SELECT ... FOR UPDATE` plus a
   unique index as a safety net).
4. **NoSQL:** when embedding or referencing fits the library data in MongoDB, and what is lost or
   gained compared with the relational design.
5. **Distributed and cloud:** how replication, failover, partitioning and sharding would let the
   database grow across campuses, the CAP trade-offs, and how to run it on a managed cloud
   service while protecting student data under Uganda's Data Protection and Privacy Act, 2019.
