#!/bin/bash
# Portfolio 4: runs every step and saves the output in evidence/.
# Usage (from the repository root, with mongod running):
#   bash portfolio-4-nosql/run-all.sh
# To use another server, set MONGO_URI, for example the Docker one:
#   MONGO_URI="mongodb://localhost:27018/naalya_library?directConnection=true" bash portfolio-4-nosql/run-all.sh

MONGO_URI=${MONGO_URI:-"mongodb://localhost:27017/naalya_library"}
MONGOSH=${MONGOSH:-mongosh}
HERE="$(cd "$(dirname "$0")" && pwd)"
OUT="$HERE/evidence"
mkdir -p "$OUT"

for step in 01-schema 02-load 03-crud 04-aggregations 05-indexes 06-transaction; do
    echo "Running $step.js ..."
    $MONGOSH --quiet "$MONGO_URI" "$HERE/$step.js" > "$OUT/$step.txt" 2>&1
done
echo "Done. Output is in $OUT"
