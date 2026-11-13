#!/bin/bash
# Portfolio 5: starts the primary + replica in Docker, runs every demo and
# saves the output in evidence/.
# Usage (from the repository root):
#   bash portfolio-5-distributed-cloud/run-all.sh
# It removes and recreates the two replication containers and their data
# first. The root library_pg container is not touched.

HERE="$(cd "$(dirname "$0")" && pwd)"
OUT="$HERE/evidence"
COMPOSE="docker compose -f $HERE/docker-compose.replication.yml"
PRIMARY=${PRIMARY:-"docker exec -i naalya_pg_primary psql -U library -d library"}
REPLICA=${REPLICA:-"docker exec -i naalya_pg_replica psql -U library -d library"}
START=${START:-"$COMPOSE down -v && $COMPOSE up -d"}
STOP_PRIMARY=${STOP_PRIMARY:-"docker stop naalya_pg_primary"}
mkdir -p "$OUT"

echo "Starting primary and replica ..."
eval "$START" > "$OUT/00-start.txt" 2>&1
until $REPLICA -c "SELECT 1" > /dev/null 2>&1; do sleep 1; done
sleep 2

run() {   # run <server> <file> <output name>
    echo "Running $2 ..."
    $1 -e < "$HERE/$2" > "$OUT/$3.txt" 2>&1
}

run "$PRIMARY" demos/01-primary-status.sql   01-primary-status
run "$REPLICA" demos/02-replica-status.sql   02-replica-status
run "$PRIMARY" demos/03-write-on-primary.sql 03-write-on-primary
run "$REPLICA" demos/04-read-on-replica.sql  04-read-on-replica
run "$REPLICA" demos/05-write-on-replica.sql 05-write-on-replica
run "$PRIMARY" demos/06-sync-replication.sql 06-sync-replication
run "$PRIMARY" partitioning.sql               08-partitioning
echo "Checking the partitioned table also reached the replica ..."
sleep 1
$REPLICA -e -c "SELECT tableoid::regclass AS partition, count(*) FROM loan_by_campus GROUP BY 1 ORDER BY 1;" \
    > "$OUT/08-partitioning-on-replica.txt" 2>&1

echo "Stopping the primary (failover test) ..."
eval "$STOP_PRIMARY" > "$OUT/07-stop-primary.txt" 2>&1
$PRIMARY -c "SELECT 1" >> "$OUT/07-stop-primary.txt" 2>&1
run "$REPLICA" demos/07-promote-replica.sql  07-promote-replica

echo "Done. Output is in $OUT"
echo "To remove the test containers: $COMPOSE down -v"
