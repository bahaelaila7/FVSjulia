# main.jl — PROGRAM MAIN entry point
# Translated from: main.f (40 lines)
#
# Equivalent to Fortran PROGRAM MAIN:
#   1. Parse command line (--keywordfile=FILE etc.) via fvsSetCmdLine
#   2. Drive repeated FVS() calls until rtnCode ≠ 0
#   3. Exit with appropriate stop code

function main(argv::AbstractVector{<:AbstractString} = ARGS)
    _init_io_units!()

    # Build the command-line string that Fortran would have received
    # (empty string signals that we already set up the state externally)
    rtnCode = Ref(Int32(0))
    cmdline = isempty(argv) ? " " : join(argv, " ")
    lenCL   = Int32(length(cmdline))
    fvsSetCmdLine(cmdline, lenCL, rtnCode)
    if rtnCode[] != 0; @goto label_10; end

    # Main stand loop
    while true
        FVS(rtnCode)
        if rtnCode[] != 0; break; end
    end

    @label label_10
    i = Ref(Int32(0))
    fvsGetICCode(i)

    if i[] == 0; return 0; end

    stop_codes = (10, 20, 30, 40, 50)
    idx = Int(i[])
    if 1 <= idx <= length(stop_codes)
        return stop_codes[idx]
    end
    return 0
end
