#!/usr/bin/env bash
# fortran_baseline.sh — produce Fortran ground-truth output for a .key file.
#
# Ensures the rebuilt FVSsn ground-truth binary exists (the shipped one fails on
# this box's GLIBC), then runs it on a keyword file in an isolated directory so
# its .sum / snout.db can be diffed against the Julia port.
#
# Usage:  fortran_baseline.sh <keyfile> <outdir>
#   Runs the Fortran binary with cwd=<outdir> so relative outputs (snout.db) land
#   there; copies the keyfile + its companion .tre in first. Prints the run dir.
#
# The binary + glibc shim live in /tmp (cleared between sessions) and are rebuilt
# from the resolved object files in bin/FVSsn_buildDir when missing.

set -euo pipefail

BUILDDIR="${FVS_BUILDDIR:-/workspace/ForestVegetationSimulator/bin/FVSsn_buildDir}"
BIN="${FVS_FORTRAN_BIN:-/tmp/FVSsn_new}"
SHIM=/tmp/glibc_shim.o

_ensure_binary() {
    if [ -x "$BIN" ]; then return 0; fi
    echo "  [fortran_baseline] rebuilding $BIN from $BUILDDIR ..." >&2
    if [ ! -f "$SHIM" ]; then
        cat > /tmp/glibc_shim.c <<'EOF'
#define _GNU_SOURCE
#include <stdio.h>
#include <stdarg.h>
/* Provide the glibc-2.38 __isoc23_* symbols the prebuilt C objects reference. */
int __isoc23_sscanf(const char *s, const char *f, ...){va_list a;va_start(a,f);int r=vsscanf(s,f,a);va_end(a);return r;}
int __isoc99_sscanf(const char *s, const char *f, ...){va_list a;va_start(a,f);int r=vsscanf(s,f,a);va_end(a);return r;}
EOF
        gcc -c -O2 /tmp/glibc_shim.c -o "$SHIM"
    fi
    local n
    n=$(ls "$BUILDDIR"/*.o 2>/dev/null | wc -l)
    if [ "$n" -lt 100 ]; then
        echo "  [fortran_baseline] ERROR: $BUILDDIR has only $n .o files (need the resolved build)." >&2
        return 1
    fi
    ( cd "$BUILDDIR" && gfortran -o "$BIN" *.o "$SHIM" -lpthread -ldl )
}

main() {
    local key="$1" out="$2"
    _ensure_binary
    mkdir -p "$out"
    # Bring the keyfile and any companion tree file into the run dir.
    local kbase kdir
    kbase=$(basename "$key")
    kdir=$(cd "$(dirname "$key")" && pwd)
    cp "$key" "$out/$kbase"
    # Copy companion files referenced by name (.tre, .trl, etc.) if present.
    for ext in tre trl chp sng; do
        [ -f "$kdir/${kbase%.key}.$ext" ] && cp "$kdir/${kbase%.key}.$ext" "$out/" || true
    done
    rm -f "$out/snout.db" "$out/FVSOut.db"
    ( cd "$out" && "$BIN" --keywordfile="$out/$kbase" >/dev/null 2>&1 ) || true
    echo "$out"
}

main "$@"
