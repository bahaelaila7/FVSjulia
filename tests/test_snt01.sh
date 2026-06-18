#!/usr/bin/env bash
# test_snt01.sh — FVSjulia basic simulation test
# Mirrors the Fortran makefile "snt01" target.
# Runs FVSjulia on snt01.key, diffs snt01.sum against snt01.sum.save.

set -euo pipefail

TESTSDIR="$(cd "$(dirname "$0")" && pwd)"
FVSJULIA="$TESTSDIR/.."
FVSDATA="$TESTSDIR/../../ForestVegetationSimulator/tests/FVSsn"

JULIA="${JULIA:-$(bash "$TESTSDIR/find_julia.sh")}"
echo "julia:   $JULIA ($($JULIA --version 2>&1))"
echo "project: $FVSJULIA"
echo "data:    $FVSDATA"
echo ""
echo "=== test_snt01: basic simulation ==="

# Run — outputs snt01.{out,sum,...} next to the key file
"$JULIA" --project="$FVSJULIA" -e "
    using FVSjulia
    FVSjulia.main([\"--keywordfile=$FVSDATA/snt01.key\"])
"

# Strip -999 lines (contain variant/date/version stamps that vary between runs)
grep -v -- '-999' "$FVSDATA/snt01.sum"      > /tmp/fvs_snt01.tmp
grep -v -- '-999' "$FVSDATA/snt01.sum.save" > /tmp/fvs_snt01.save

if diff -w /tmp/fvs_snt01.tmp /tmp/fvs_snt01.save; then
    echo ""
    echo "PASS: snt01.sum matches baseline"
else
    echo ""
    echo "FAIL: snt01.sum differs from snt01.sum.save (diff above)"
    rm -f /tmp/fvs_snt01.tmp /tmp/fvs_snt01.save
    exit 1
fi

rm -f /tmp/fvs_snt01.tmp /tmp/fvs_snt01.save
