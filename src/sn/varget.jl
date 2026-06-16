# sn/varget.f — VARGET/VARCHGET: read variant-specific variables from parallel buffer
# Translated from: bin/FVSsn_buildDir/varget.f (80 lines)
#
# Part of the parallel-processing extension; reads KODIST and ISEFOR from WK3.
# IFREAD/VARCHGET stubs — parallel processing not yet implemented.

# IFREAD is implemented in base/putgetsubs.jl

function VARGET(wk3::Vector{Float32}, ipnt::Ref{Int32}, ilimit::Int32,
                reals::Vector{Float32}, logics::Vector{Bool}, ints::Vector{Int32})
    mxi    = Int32(2)
    ints_buf = zeros(Int32, mxi)
    IFREAD(wk3, ipnt, ilimit, ints_buf, mxi, Int32(2))
    global KODIST = ints_buf[1]
    global ISEFOR = ints_buf[2]
    return nothing
end

function VARCHGET(cbuff::Vector{UInt8}, ipnt::Ref{Int32}, lncbuf::Int32)
    # Stub: no character data for sn variant
    return nothing
end
