#!/usr/bin/env bash
# test_sndb.sh — FVSjulia SQLite database output test
# Mirrors the Fortran makefile "sndb" target.
# Runs FVSjulia on sn.key, queries snout.db, diffs against snout.txt.save.
#
# sn.key writes "snout.db" relative to the julia CWD — we cd to /tmp first.

set -euo pipefail

TESTSDIR="$(cd "$(dirname "$0")" && pwd)"
FVSJULIA="$TESTSDIR/.."
FVSDATA="$TESTSDIR/../../ForestVegetationSimulator/tests/FVSsn"
DBFILE=/tmp/snout.db

JULIA="${JULIA:-$(bash "$TESTSDIR/find_julia.sh")}"
echo "julia:   $JULIA ($($JULIA --version 2>&1))"
echo ""
echo "=== test_sndb: SQLite database output ==="

rm -f "$DBFILE"

# cd to /tmp inside Julia so snout.db lands there, not in the source tree
"$JULIA" --project="$FVSJULIA" -e "
    cd(\"/tmp\")
    using FVSjulia
    FVSjulia.main([\"--keywordfile=$FVSDATA/sn.key\"])
"

if [ ! -f "$DBFILE" ]; then
    echo "FAIL: $DBFILE was not created"
    exit 1
fi

sqlite3 "$DBFILE" < "$FVSDATA/snTablesTest.sql" > /tmp/fvs_snout.txt
echo "sqlite3 exit code: $?"

if diff -w /tmp/fvs_snout.txt "$FVSDATA/snout.txt.save"; then
    echo ""
    echo "PASS: SQLite output matches baseline"
else
    echo ""
    echo "FAIL: SQLite output differs from snout.txt.save (diff above)"
    rm -f /tmp/fvs_snout.txt "$DBFILE"
    exit 1
fi

rm -f /tmp/fvs_snout.txt "$DBFILE"
