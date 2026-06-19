# build_sysimage.jl — build a PackageCompiler system image for FVSjulia.
#
# Produces tools/FVSjuliaSysimage.so with FVSjulia (+ deps) and every hot method
# baked in, so a fresh process pays ~0 JIT cost (cold run ~1s incl. startup).
#
# How it works: the big simulation functions (INITRE/TREGRO/DGF/fire/econ/volume…)
# are NOT captured by PackageCompiler's trace-compile, so we flip FVSjulia's
# `precompile_workload` preference ON for the build. That makes FVSjulia's own
# precompilation run full simulations (PrecompileTools @compile_workload), baking
# the methods into its package cache, which create_sysimage then bundles. The
# preference is reset to false afterwards so normal dev precompile stays fast.
# (FVSjulia.__init__ restores pristine COMMON-block state on every load, so the
#  simulations run during the build don't leak into real runs.)
#
# Build:  julia --project=tools tools/build_sysimage.jl
# Use:    julia --sysimage=tools/FVSjuliaSysimage.so --project=. \
#               -e 'using FVSjulia; exit(FVSjulia.main(["--keywordfile=x.key"]))'

import TOML
using PackageCompiler

const FVSJL = normpath(joinpath(@__DIR__, ".."))
const OUTSO = get(ENV, "FVS_SYSIMAGE", joinpath(@__DIR__, "FVSjuliaSysimage.so"))
const EXECF = joinpath(@__DIR__, "precompile_exec.jl")
const PREFS = joinpath(FVSJL, "LocalPreferences.toml")

function _set_workload(val::Bool)
    d = isfile(PREFS) ? TOML.parsefile(PREFS) : Dict{String,Any}()
    get!(() -> Dict{String,Any}(), d, "FVSjulia")["precompile_workload"] = val
    open(PREFS, "w") do io; TOML.print(io, d); end
end

# Size knobs (env-overridable):
#   FVS_INCREMENTAL=1   build on the full base sysimage (bigger, faster build)
#   FVS_CPU_TARGET=…    "native" (default; smallest + exact FP, but the image only
#                       runs on this build machine's CPU class), "generic" (portable
#                       baseline x86-64; +~1 ulp in FP-heavy outputs), or a multi-
#                       target like PackageCompiler.default_app_cpu_target() (portable
#                       + per-arch tuned, but largest).
# Default = smallest image: non-incremental + filter unused stdlibs + native CPU
# target (single, machine-tuned — no clone_all multiversioning).
const INCREMENTAL = get(ENV, "FVS_INCREMENTAL", "0") == "1"
const CPUTARGET   = get(ENV, "FVS_CPU_TARGET", "native")

@info "Building FVSjulia system image" project=FVSJL output=OUTSO incremental=INCREMENTAL cpu_target=CPUTARGET
_set_workload(true)   # run the sim during FVSjulia precompilation → bake methods
try
    # No precompile_execution_file: the FVSjulia simulation methods come from its
    # workload-populated package image (bundled here), and that's the expensive
    # part. (An execution-file tracing pass under --compile=all SIGSEGVs on this
    # code and only adds Base/stdlib specializations, so it's not worth it.)
    create_sysimage(
        ["FVSjulia"];
        project        = FVSJL,
        sysimage_path  = OUTSO,
        incremental    = INCREMENTAL,
        filter_stdlibs = !INCREMENTAL,   # only valid (and only helps) for a fresh build
        cpu_target     = CPUTARGET,
    )
finally
    _set_workload(false)  # keep normal `using FVSjulia` precompile fast
end

# Strip debug sections (~40MB, verified harmless for the runtime image).
strip = Sys.which("strip")
if strip !== nothing
    try; run(`$strip --strip-debug $OUTSO`); catch; end
end

@info "System image built" path=OUTSO size_MB=round(filesize(OUTSO)/2^20, digits=1)
