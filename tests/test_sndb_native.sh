#!/usr/bin/env bash
# test_sndb_native.sh — fast Julia-native regression for the sn.key DB output.
# Runs FVSjulia on sn.key (subprocess) to produce snout.db, then asserts the
# expected table presence + row counts via check_sndb_counts.jl. No sqlite3 CLI,
# no Fortran rebuild — runs anywhere the package loads.

set -uo pipefail
TESTSDIR="$(cd "$(dirname "$0")" && pwd)"
FVSJULIA="$TESTSDIR/.."
FVSDATA="$FVSJULIA/../ForestVegetationSimulator/tests/FVSsn"
JULIA="${JULIA:-$(bash "$TESTSDIR/find_julia.sh")}"

echo "=== sndb native count check (sn.key) ==="
rundir="$(mktemp -d)"
( cd "$rundir" && "$JULIA" --project="$FVSJULIA" -e \
    "using FVSjulia; FVSjulia.main([\"--keywordfile=$FVSDATA/sn.key\"])" >/dev/null 2>"$rundir/err" ) || true

if [ ! -f "$rundir/snout.db" ]; then
    echo "  FAIL: snout.db not produced"; sed 's/^/    /' "$rundir/err" | tail -5; rm -rf "$rundir"; exit 1
fi

"$JULIA" --project="$FVSJULIA" "$TESTSDIR/check_sndb_counts.jl" "$rundir/snout.db"
rc=$?
rm -rf "$rundir"
exit $rc
