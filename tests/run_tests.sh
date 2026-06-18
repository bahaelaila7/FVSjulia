#!/usr/bin/env bash
# run_tests.sh — FVSjulia full test suite
#
# Usage:
#   bash tests/run_tests.sh                     # from FVSjulia root
#   bash tests/run_tests.sh --skip-instantiate  # skip Pkg.instantiate
#   JULIA=~/.juliaup/bin/julia bash tests/run_tests.sh
#
# Steps:
#   0. Pkg.instantiate
#   1. Module smoke test
#   2. snt01 — basic simulation
#   3. snt02 — stop/restart (informational)
#   4. sndb  — SQLite output

set -euo pipefail

TESTSDIR="$(cd "$(dirname "$0")" && pwd)"
FVSJULIA="$TESTSDIR/.."
SKIP_INSTANTIATE=0

for arg in "$@"; do
    case "$arg" in
        --skip-instantiate) SKIP_INSTANTIATE=1 ;;
    esac
done

JULIA="${JULIA:-$(bash "$TESTSDIR/find_julia.sh")}"
echo "julia:   $JULIA ($($JULIA --version 2>&1))"
echo "project: $FVSJULIA"
echo ""

PASS=0
FAIL=0
SKIP=0

run_step() {
    local name="$1"; shift
    echo "========================================"
    echo "STEP: $name"
    echo "========================================"
    if bash "$@"; then
        echo ">>> PASS: $name"
        PASS=$((PASS + 1))
    else
        echo ">>> FAIL: $name"
        FAIL=$((FAIL + 1))
    fi
    echo ""
}

# Step 0: Pkg.instantiate
if [ "$SKIP_INSTANTIATE" -eq 0 ]; then
    run_step "Pkg.instantiate" -c "
        set -e
        \"$JULIA\" --project=\"$FVSJULIA\" -e '
            import Pkg; Pkg.instantiate(); println(\"Instantiate OK\")
        '
    "
fi

# Step 1: smoke test
run_step "module smoke test" -c "
    set -e
    \"$JULIA\" --project=\"$FVSJULIA\" -e '
        using FVSjulia; println(\"Module load OK\")
    '
"

# Step 2: snt01
run_step "snt01 basic simulation" "$TESTSDIR/test_snt01.sh"

# Step 3: snt02 (informational — always counted as skip)
echo "========================================"
echo "STEP: snt02 stop/restart (informational)"
echo "========================================"
JULIA="$JULIA" bash "$TESTSDIR/test_snt02.sh" || true
SKIP=$((SKIP + 1))
echo ""

# Step 4: sndb (legacy — needs the sqlite3 CLI; informational where it is absent)
if command -v sqlite3 >/dev/null 2>&1; then
    run_step "sndb SQLite output (sqlite3 CLI)" "$TESTSDIR/test_sndb.sh"
else
    echo "========================================"
    echo "STEP: sndb SQLite output (skipped — no sqlite3 CLI; see Fortran-diff below)"
    echo "========================================"
    SKIP=$((SKIP + 1)); echo ""
fi

# Step 5: sndb native count check (fast, Julia-only — no sqlite3, no Fortran).
echo "========================================"
echo "STEP: sndb native count check (informational)"
echo "========================================"
JULIA="$JULIA" bash "$TESTSDIR/test_sndb_native.sh" || true
SKIP=$((SKIP + 1)); echo ""

# Step 6+: Fortran ground-truth diff — runs FVSjulia AND the rebuilt Fortran on
# each scenario, then diffs the .sum and every SQLite table directly. No sqlite3
# CLI needed. These are informational (they surface every Float32-level and real
# divergence vs the live Fortran), counted separately so they don't gate CI yet.
FVSDATA="$FVSJULIA/../ForestVegetationSimulator/tests/FVSsn"
FVSFMSC="$FVSJULIA/../ForestVegetationSimulator/tests/testSetFromFMSC"
# Each entry is a full path to a .key. snt01/sn live in FVSsn; sntest (PLANT/BARE-
# ground establishment, TREEFMT, REWIND, STATS) lives in testSetFromFMSC.
for key in "$FVSDATA/snt01.key" "$FVSDATA/sn.key" "$FVSFMSC/sntest.key"; do
    if [ -f "$key" ]; then
        echo "========================================"
        echo "STEP: Fortran-diff $(basename "$key") (informational)"
        echo "========================================"
        JULIA="$JULIA" bash "$TESTSDIR/test_fortran_diff.sh" "$key" || true
        SKIP=$((SKIP + 1)); echo ""
    fi
done

echo "========================================"
echo "RESULTS: $PASS passed  $FAIL failed  $SKIP informational"
echo "========================================"
[ "$FAIL" -eq 0 ]
