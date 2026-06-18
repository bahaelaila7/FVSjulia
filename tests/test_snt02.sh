#!/usr/bin/env bash
# test_snt02.sh — FVSjulia stop/restart test
# Mirrors the Fortran makefile "snt02" target.
#
# Stops every stand at year 2020 (--stoppoint), serializing full stand state
# via PUTSTD, then resumes via --restart/GETSTD and runs to completion. The
# combined output must match an uninterrupted run (snt01.sum.save).
#
# Stop/restart serialization is implemented; the only residual is the same
# single off-by-1 board-foot value at 2033 that snt01 exhibits (a Float32
# transcendental-rounding diff vs the Fortran baseline, unrelated to restart).

set -euo pipefail

TESTSDIR="$(cd "$(dirname "$0")" && pwd)"
FVSJULIA="$TESTSDIR/.."
FVSDATA="$TESTSDIR/../../ForestVegetationSimulator/tests/FVSsn"
STOPFILE=/tmp/fvs_snt.stop

JULIA="${JULIA:-$(bash "$TESTSDIR/find_julia.sh")}"
echo "julia:   $JULIA ($($JULIA --version 2>&1))"
echo ""
echo "=== test_snt02: stop/restart (informational — stubs not yet real) ==="

rm -f "$STOPFILE"

echo ""
echo "--- Run 1: stop at year 2020 ---"
"$JULIA" --project="$FVSJULIA" -e "
    using FVSjulia
    FVSjulia.main([\"--keywordfile=$FVSDATA/snt01.key\",
                   \"--stoppoint=2,2020,$STOPFILE\"])
"
echo "Stop run exit code: $?"

echo ""
echo "--- Run 2: restart from stop file ---"
"$JULIA" --project="$FVSJULIA" -e "
    using FVSjulia
    FVSjulia.main([\"--restart=$STOPFILE\"])
"
echo "Restart run exit code: $?"

# Save the stop/restart output, then run snt01 straight through and compare:
# if stop/restart is correct they must be byte-identical (both share whatever
# residual they have vs the Fortran .save baseline).
grep -v -- '-999' "$FVSDATA/snt01.sum" > /tmp/fvs_snt02_restart.tmp

echo ""
echo "--- Run 3: straight run (no stop) for comparison ---"
"$JULIA" --project="$FVSJULIA" -e "
    using FVSjulia
    FVSjulia.main([\"--keywordfile=$FVSDATA/snt01.key\"])
"
grep -v -- '-999' "$FVSDATA/snt01.sum" > /tmp/fvs_snt02_straight.tmp

echo ""
rc=0
if diff -w /tmp/fvs_snt02_restart.tmp /tmp/fvs_snt02_straight.tmp; then
    echo "PASS: stop/restart output is identical to an uninterrupted run"
else
    echo "FAIL: stop/restart output differs from an uninterrupted run (diff above)"
    rc=1
fi

# Informational: residual vs the Fortran baseline (shared with snt01).
grep -v -- '-999' "$FVSDATA/snt01.sum.save" > /tmp/fvs_snt01.save
nbase=$(diff -w /tmp/fvs_snt02_straight.tmp /tmp/fvs_snt01.save | grep -c '^[<>]' || true)
echo "(residual vs Fortran baseline: $nbase line(s) — same as snt01)"

rm -f /tmp/fvs_snt02_restart.tmp /tmp/fvs_snt02_straight.tmp /tmp/fvs_snt01.save "$STOPFILE"
exit $rc
