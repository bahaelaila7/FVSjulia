# precompile_exec.jl — PackageCompiler "precompile execution file".
# Run by create_sysimage to capture every hot method into the system image. It
# drives the full set of scenarios so ALL major code paths get compiled:
#   sn.key         growth, thinning (THINDBH/THINBTA/THINPRSC), fire & fuels (FFE),
#                  carbon/snags/down-wood, econ, establishment (stump sprouting),
#                  every DBS output table, event monitor (IF/THEN)
#   snt01.key      TREEFMT + external .tre reading, unthinned/shelterwood blocks
#   sntest.key     PLANT establishment into a BARE-ground stand, REWIND, STATS
#   sn_fiavbc.key  FIAVBC FIA-NVB volume/biomass path
#   stop/restart   PUTSTD/GETSTD COMMON-block serialization
#
# NOTE: each run mutates FVSjulia's COMMON-block globals; that's fine here because
# the package's __init__ restores pristine state every time the image is loaded
# (see _snapshot_state!/_restore_state! in FVSjulia.jl).

using FVSjulia

const _FVSJL  = normpath(joinpath(@__DIR__, ".."))
const _REPO   = normpath(joinpath(_FVSJL, ".."))
const _FVSSN  = joinpath(_REPO, "ForestVegetationSimulator", "tests", "FVSsn")
const _FMSC   = joinpath(_REPO, "ForestVegetationSimulator", "tests", "testSetFromFMSC")
const _DATA   = joinpath(_FVSJL, "tests", "data")

# Run a list of CLI argv vectors, each in its own temp dir, output suppressed.
function _exercise(argvs)
    for argv in argvs
        d = mktempdir()
        try
            cd(d) do
                redirect_stdout(devnull) do
                    redirect_stderr(devnull) do
                        try
                            FVSjulia.main(argv)
                        catch
                        end
                    end
                end
            end
        finally
            rm(d; recursive=true, force=true)
        end
    end
end

let
    runs = Vector{Vector{String}}()
    isfile(joinpath(_FVSSN, "sn.key"))   && push!(runs, ["--keywordfile=$(joinpath(_FVSSN, "sn.key"))"])
    isfile(joinpath(_FVSSN, "snt01.key"))&& push!(runs, ["--keywordfile=$(joinpath(_FVSSN, "snt01.key"))"])
    isfile(joinpath(_FMSC, "sntest.key"))&& push!(runs, ["--keywordfile=$(joinpath(_FMSC, "sntest.key"))"])
    isfile(joinpath(_DATA, "sn_fiavbc.key")) && push!(runs, ["--keywordfile=$(joinpath(_DATA, "sn_fiavbc.key"))"])
    _exercise(runs)

    # stop/restart cycle (serialization paths) — both runs share one temp dir
    if isfile(joinpath(_FVSSN, "snt01.key"))
        d = mktempdir()
        try
            cd(d) do
                stopf = joinpath(d, "fvs.stop")
                redirect_stdout(devnull) do
                    redirect_stderr(devnull) do
                        try
                            FVSjulia.main(["--keywordfile=$(joinpath(_FVSSN, "snt01.key"))",
                                           "--stoppoint=2,2020,$stopf"])
                            FVSjulia.main(["--restart=$stopf"])
                        catch
                        end
                    end
                end
            end
        finally
            rm(d; recursive=true, force=true)
        end
    end
end
