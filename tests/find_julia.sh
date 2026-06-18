#!/usr/bin/env bash
# find_julia.sh — locate julia binary and print its path
# Override by setting JULIA before sourcing, e.g.: JULIA=/custom/julia bash run_tests.sh

if [ -n "${JULIA:-}" ] && [ -x "$JULIA" ]; then
    echo "$JULIA"
    exit 0
fi

for candidate in \
    julia \
    "$HOME/.juliaup/bin/julia" \
    "/usr/local/bin/julia" \
    "/usr/bin/julia" \
    "/opt/julia/bin/julia"
do
    if command -v "$candidate" &>/dev/null 2>&1 || [ -x "$candidate" ]; then
        echo "$candidate"
        exit 0
    fi
done

echo "ERROR: julia not found — set JULIA=/path/to/julia before running tests" >&2
exit 1
