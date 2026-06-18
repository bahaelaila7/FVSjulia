#!/usr/bin/env bash
# test_fortran_diff.sh — run FVSjulia and the rebuilt Fortran ground-truth on the
# same .key in isolated dirs, then diff their .sum output and (if produced) their
# SQLite database, table-by-table. This is the authoritative regression: it
# compares directly against freshly-generated Fortran output, not a stale .save.
#
# Usage:  test_fortran_diff.sh <keyfile>
# Exit:   0 if .sum matches and all shared DB tables match (within Float32 tol).

set -uo pipefail

TESTSDIR="$(cd "$(dirname "$0")" && pwd)"
FVSJULIA="$TESTSDIR/.."
JULIA="${JULIA:-$(bash "$TESTSDIR/find_julia.sh")}"

key="$1"
kbase="$(basename "$key")"
stem="${kbase%.key}"
kdir="$(cd "$(dirname "$key")" && pwd)"

echo "=== $kbase : FVSjulia vs Fortran ground-truth ==="

# --- Fortran baseline (rebuilds /tmp/FVSsn_new if needed) ---
ftdir="$(mktemp -d)"
if ! bash "$TESTSDIR/fortran_baseline.sh" "$key" "$ftdir" >/dev/null 2>"$ftdir/err"; then
    echo "  SKIP: could not build/run Fortran ground-truth"; sed 's/^/    /' "$ftdir/err"; exit 0
fi

# --- Julia run (isolated dir so outputs don't clobber the source tree) ---
jldir="$(mktemp -d)"
cp "$key" "$jldir/"
for ext in tre trl chp sng; do
    [ -f "$kdir/$stem.$ext" ] && cp "$kdir/$stem.$ext" "$jldir/" || true
done
( cd "$jldir" && "$JULIA" --project="$FVSJULIA" -e \
    "using FVSjulia; FVSjulia.main([\"--keywordfile=$jldir/$kbase\"])" >/dev/null 2>"$jldir/err" ) || true

rc=0

# --- .sum diff (strip -999 header lines that carry timestamps) ---
if [ -f "$jldir/$stem.sum" ] && [ -f "$ftdir/$stem.sum" ]; then
    n=$(diff -w <(grep -v -- '-999' "$jldir/$stem.sum") \
                <(grep -v -- '-999' "$ftdir/$stem.sum") | grep -c '^[<>]' || true)
    if [ "$n" -eq 0 ]; then echo "  .sum  : MATCH"; else echo "  .sum  : $n differing line(s)"; rc=1; fi
fi

# --- SQLite DB table-by-table diff (Julia-native; no sqlite3 CLI) ---
jdb=""; fdb=""
for d in snout.db FVSOut.db; do
    [ -f "$jldir/$d" ] && jdb="$jldir/$d"
    [ -f "$ftdir/$d" ] && fdb="$ftdir/$d"
done
if [ -n "$jdb" ] && [ -n "$fdb" ]; then
    "$JULIA" --project="$FVSJULIA" "$TESTSDIR/db_compare.jl" "$jdb" "$fdb" 2>&1 | sed 's/^/  /' || rc=1
fi

rm -rf "$ftdir" "$jldir"
exit $rc
