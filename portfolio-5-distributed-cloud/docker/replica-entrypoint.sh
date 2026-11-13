#!/bin/sh
# Starts the replica. The first time (empty data folder) it copies the whole
# primary with pg_basebackup:
#   -R  writes standby.signal and primary_conninfo, so it starts as a read-only standby
#   -X stream  also streams the WAL written during the copy
#   -C -S replica1  creates a replication slot, so the primary keeps the WAL the replica still needs
#   -c fast  asks the primary for an immediate checkpoint, so the copy starts straight away
set -e
if [ ! -s "$PGDATA/PG_VERSION" ]; then
    echo "Waiting for the primary ..."
    until pg_isready -h pg_primary -p 5432 -U library; do sleep 1; done
    echo "Copying the primary with pg_basebackup ..."
    PGPASSWORD="$REPLICATION_PASSWORD" pg_basebackup -h pg_primary -p 5432 -U replicator \
        -D "$PGDATA" -R -X stream -C -S replica1 -c fast -P
    chmod 700 "$PGDATA"
fi
# cluster_name is used as the replica's name on the primary (application_name).
exec postgres -c cluster_name=replica1 -c hot_standby=on
