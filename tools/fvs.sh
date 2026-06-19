#!/usr/bin/env bash
# fvs.sh — run FVSjulia with whichever fast-start artifact is available.
#
#   tools/fvs.sh --keywordfile=path/to/stand.key
#
# Picks, in order:
#   1. the system image (tools/FVSjuliaSysimage.so) — self-contained, ~256MB
#   2. else the package image — needs build_pkgimage.sh first (~77MB, reuses the
#      installed Julia base). Set FVS_NO_SYSIMAGE=1 to force this path even when a
#      sysimage exists.
#   3. else a plain launch (works, but the first simulation JITs ~12s in dev mode)
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJ="$(cd "$HERE/.." && pwd)"
SYS="$HERE/FVSjuliaSysimage.so"
JULIA="${JULIA:-$(command -v julia)}"

if [ -f "$SYS" ] && [ "${FVS_NO_SYSIMAGE:-0}" != "1" ]; then
    exec "$JULIA" --sysimage="$SYS" --project="$PROJ" \
         -e 'using FVSjulia; exit(FVSjulia.main(ARGS))' -- "$@"
else
    exec "$JULIA" --project="$PROJ" \
         -e 'using FVSjulia; exit(FVSjulia.main(ARGS))' -- "$@"
fi
