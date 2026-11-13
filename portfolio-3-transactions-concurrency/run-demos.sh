#!/bin/bash
# Portfolio 3: runs every demo and saves the output in evidence/.
# Each two-window demo starts both sessions at the same time in the
# background; the "\! sleep" lines in the .sql files keep the steps in order.
#
# Usage (from the repository root, with the library_pg container running):
#   bash portfolio-3-transactions-concurrency/run-demos.sh

PSQL=${PSQL:-"docker exec -i library_pg psql -U library -d library"}
# How to "crash" the database server for the durability test.
RESTART=${RESTART:-"docker kill library_pg && docker start library_pg"}
# How to read the server log after the restart (shows the crash recovery).
SERVERLOG=${SERVERLOG:-"docker logs --tail 12 library_pg"}

HERE="$(cd "$(dirname "$0")" && pwd)"
P1="$HERE/../portfolio-1-database-design"
OUT="$HERE/evidence"
mkdir -p "$OUT"

reset_db() {
    $PSQL -q < "$P1/schema.sql"    > /dev/null 2>&1
    $PSQL -q < "$P1/seed.sql"      > /dev/null 2>&1
    $PSQL -q < "$HERE/borrow-function.sql" > /dev/null 2>&1
}

run_pair() {
    name=$1
    echo "Running $name ..."
    reset_db
    $PSQL -e < "$HERE/concurrency/$name-a.sql" > "$OUT/$name-a.txt" 2>&1 &
    $PSQL -e < "$HERE/concurrency/$name-b.sql" > "$OUT/$name-b.txt" 2>&1 &
    wait
}

# Part A: transactions in one session, then the durability test.
echo "Running transactions.sql ..."
reset_db
$PSQL -e < "$HERE/transactions.sql" > "$OUT/transactions.txt" 2>&1

echo "Killing and restarting the database server ..."
eval "$RESTART" > /dev/null 2>&1
until $PSQL -c "SELECT 1" > /dev/null 2>&1; do sleep 1; done
$PSQL -e < "$HERE/durability-check.sql" > "$OUT/durability.txt" 2>&1
eval "$SERVERLOG" 2>&1 | grep -E "interrupted|not properly shut down|redo starts|redo done|ready to accept" > "$OUT/durability-server-log.txt"

# Part B: two sessions at a time.
for demo in d1-read-committed d2-repeatable-read d3-double-borrow-unique \
            d4-double-borrow-for-update d5-double-borrow-serializable \
            d6-lost-update d7-lost-update-fixed d8-deadlock d9-no-deadlock; do
    run_pair "$demo"
done

echo "Done. Output is in $OUT"
