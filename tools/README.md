# FVSjulia deployment / fast-startup tools

The simulation itself runs in ~0.2s (faster than the Fortran binary). The only
cost is Julia's first-call JIT compilation (~12s cold). These tools eliminate it
by baking the compiled methods ahead of time. Two options:

| Artifact | Size | Cold run | Self-contained? | Build |
|----------|------|----------|-----------------|-------|
| **Package image** | **~77 MB** | ~1.0s | no — reuses installed Julia | `tools/build_pkgimage.sh` |
| **System image**  | ~256 MB | ~1.0s | mostly (still needs the `julia` binary) | `julia --project=tools tools/build_sysimage.jl` |
| (dev: no baking)  | ~16 MB | ~12s (first run) | — | `tools/dev_mode.sh` |

For reference, the Fortran `FVSsn` binary is ~10 MB. Julia can't match that without
its runtime (GC + dynamic dispatch); ~77 MB is the practical floor for *this*
codebase without a major rewrite (see the `--trim`/`juliac` discussion in memory).

## Which to use
- **Have Julia installed on the target?** → **package image** (smaller, 77 MB). It
  reuses the Julia base runtime that's already there instead of re-bundling it.
- **Want one file you can point `julia --sysimage` at?** → **system image** (256 MB).

Both give the same ~1s cold run. `tools/fvs.sh` auto-selects: it uses the system
image if present, else the package image. Force the package-image path with
`FVS_NO_SYSIMAGE=1`.

## Mode toggle (`precompile_workload` preference)
A `@compile_workload` is gated behind the `precompile_workload` preference
(`LocalPreferences.toml`):

- `tools/build_pkgimage.sh` → sets it **true** + precompiles (slow ~2-3 min once,
  then fast runs). Leaves it on.
- `tools/dev_mode.sh` → sets it **false** (fast ~10s precompile, slow first run) —
  use while editing source.
- `build_sysimage.jl` flips it on only for the build, then resets it, so building a
  sysimage doesn't change your current mode.

## Run

    tools/fvs.sh --keywordfile=/path/to/stand.key      # uses sysimage if built
    FVS_NO_SYSIMAGE=1 tools/fvs.sh --keywordfile=...    # force the package image

## Build knobs (system image)
- `FVS_CPU_TARGET=native` (default; smallest + exact FP, **this CPU class only**)
- `FVS_CPU_TARGET=generic` (portable x86-64, but ~1 ulp drift in board-foot volume)
- `FVS_CPU_TARGET="$(julia -e 'using PackageCompiler; print(PackageCompiler.default_app_cpu_target())')"`
  (portable + per-arch tuned, exact FP, but ~430 MB)
- `FVS_INCREMENTAL=1` (build on the full base image: ~3-5 min build, larger)

A non-incremental build recompiles base Julia from scratch (~15-20 min) so that
`filter_stdlibs` can strip the unused half of the base image.

## ⚠ If a build fails instantly with "PackageCompiler … not installed"
The Julia depot got wiped (e.g. /tmp cleared). Re-instantiate both envs:

    julia --project=tools -e 'import Pkg; Pkg.instantiate()'
    julia --project=.     -e 'import Pkg; Pkg.instantiate()'
