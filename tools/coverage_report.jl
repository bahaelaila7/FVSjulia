# coverage_report.jl — measure what fraction of the FVSjulia source the precompile
# workload actually exercises (i.e. what the system image bakes by RUNNING code).
#
#   julia --project=. tools/coverage_report.jl
#
# Runs all workload scenarios under --code-coverage in a subprocess, then reports
# overall line coverage + the least-covered files. Run this after adding code to
# see whether new paths are exercised by the workload; uncovered functions still
# work but JIT on first use (unless they're caught by _precompile_all!'s signature
# substitution — this report only reflects RUN coverage, the lower bound).
#
# Optional: pass a percentage threshold to fail (exit 1) if overall coverage drops
# below it, e.g. for CI:  julia --project=. tools/coverage_report.jl 50

const FVSJL = normpath(joinpath(@__DIR__, ".."))
const SRC   = joinpath(FVSJL, "src")
const REPO  = normpath(joinpath(FVSJL, ".."))
const JULIA = Base.julia_cmd()[1]
const THRESH = length(ARGS) >= 1 ? parse(Float64, ARGS[1]) : nothing

# scenarios (absolute key paths)
keys = filter(isfile, [
    joinpath(REPO, "ForestVegetationSimulator", "tests", "FVSsn", "sn.key"),
    joinpath(REPO, "ForestVegetationSimulator", "tests", "FVSsn", "snt01.key"),
    joinpath(REPO, "ForestVegetationSimulator", "tests", "testSetFromFMSC", "sntest.key"),
    joinpath(FVSJL, "tests", "data", "sn_fiavbc.key"),
])

# clean stale coverage
for (root,_,fs) in walkdir(SRC), f in fs
    endswith(f, ".cov") && rm(joinpath(root, f); force=true)
end

runner = """
using FVSjulia
home = pwd()
R(a) = (d=mktempdir(); cd(d); try; redirect_stdout(devnull) do; redirect_stderr(devnull) do; FVSjulia.main(a); end; end; catch; end; cd(home); rm(d;recursive=true,force=true))
$(join(["R([\"--keywordfile=$k\"])" for k in keys], "\n"))
let d=mktempdir(); cd(d); try; redirect_stdout(devnull) do; redirect_stderr(devnull) do; sf=joinpath(d,"s.stop"); FVSjulia.main(["--keywordfile=$(keys[2])","--stoppoint=2,2020,\$sf"]); FVSjulia.main(["--restart=\$sf"]); end; end; catch; end; cd(home); rm(d;recursive=true,force=true); end
"""
@info "Running workload scenarios under coverage ($(length(keys)) keys + stop/restart)…"
run(`$JULIA --code-coverage=user --project=$FVSJL -e $runner`)

# aggregate
tot_ex=0; tot_hit=0; perfile = Tuple{String,Int,Int}[]
for (root,_,fs) in walkdir(SRC), f in fs
    endswith(f, ".cov") || continue
    p = joinpath(root, f); ex=0; hit=0
    for ln in eachline(p)
        length(ln) < 9 && continue
        c = strip(ln[1:9]); c == "-" && continue
        n = tryparse(Int, c); n === nothing && continue
        ex += 1; n > 0 && (hit += 1)
    end
    ex > 0 && push!(perfile, (relpath(replace(p, ".cov"=>""), SRC), ex, hit))
    global tot_ex += ex; global tot_hit += hit
    rm(p; force=true)
end
pct = round(100*tot_hit/max(tot_ex,1), digits=1)
println("\nWORKLOAD LINE COVERAGE: $tot_hit/$tot_ex = $pct%")
sort!(perfile, by = t -> t[3]/t[2])
println("\n20 least-covered files (>=40 exec lines):")
shown = 0
for (p,ex,hit) in perfile
    ex >= 40 || continue
    println("  ", lpad(round(Int,100hit/ex),3), "%  ", lpad(hit,4), "/", rpad(ex,5), "  ", p)
    (shown += 1) >= 20 && break
end
if THRESH !== nothing && pct < THRESH
    println("\nFAIL: coverage $pct% < threshold $THRESH%"); exit(1)
end
