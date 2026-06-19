#!/usr/bin/env bash
# build_pkgimage.sh — build the fast FVSjulia *package image* (no separate sysimage).
#
# This is the SMALL deployment option (~77MB of FVSjulia compiled code in the Julia
# depot, vs the ~256MB self-contained sysimage). It reuses the installed Julia base
# runtime, so it only makes sense when Julia is present on the target (always true
# to run Julia anyway). Cold run ~1s, same as the sysimage.
#
# It flips the `precompile_workload` preference ON and precompiles, baking all hot
# methods (incl. _precompile_all!'s signature coverage) into FVSjulia's pkgimage.
# Leaves the preference ON so subsequent runs stay fast; switch back to dev mode
# (fast ~10s precompile, slow first run) with:  tools/dev_mode.sh
#
# After this, run with:  tools/fvs.sh --keywordfile=...   (auto-uses the pkgimage
# when no sysimage is present, or force it with FVS_NO_SYSIMAGE=1)
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJ="$(cd "$HERE/.." && pwd)"
JULIA="${JULIA:-$(command -v julia)}"

printf '[FVSjulia]\nprecompile_workload = true\n' > "$PROJ/LocalPreferences.toml"
echo "build_pkgimage: precompile_workload=true; precompiling (one-time, ~2-3 min)…"
"$JULIA" --project="$PROJ" -e 'using FVSjulia; println("pkgimage built (workload baked)")'

sz=$(find "$HOME/.julia/compiled" -type f -name '*.so' 2>/dev/null | grep -i fvsjulia \
     | xargs -r ls -la | sort -k5 -n | tail -1 | awk '{printf "%.0f MB", $5/1024/1024}')
echo "FVSjulia pkgimage: ${sz:-unknown}.  Run via: $HERE/fvs.sh --keywordfile=..."
