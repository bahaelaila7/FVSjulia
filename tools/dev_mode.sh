#!/usr/bin/env bash
# dev_mode.sh — switch FVSjulia to development mode.
# Sets precompile_workload=false so `using FVSjulia` precompiles fast (~10s) for
# quick edit/test iteration. The trade-off: the FIRST simulation in a fresh
# process JITs (~12s). For fast runs again, use tools/build_pkgimage.sh (77MB) or
# build a sysimage (tools/build_sysimage.jl, ~256MB).
set -euo pipefail
PROJ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
printf '[FVSjulia]\nprecompile_workload = false\n' > "$PROJ/LocalPreferences.toml"
echo "dev mode: precompile_workload=false (fast precompile, slow first run)"
