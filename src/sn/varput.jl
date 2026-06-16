# sn/varput.f — VARPUT/VARCHPUT: write variant-specific variables to parallel buffer
# Translated from: bin/FVSsn_buildDir/varput.f (78 lines)
#
# Part of the parallel-processing extension; writes KODIST and ISEFOR to WK3.
# IFWRIT/VARCHPUT stubs — parallel processing not yet implemented.

# IFWRIT is implemented in base/putgetsubs.jl

function VARPUT(wk3::Vector{Float32}, ipnt::Ref{Int32}, ilimit::Int32,
                reals::Vector{Float32}, logics::Vector{Bool}, ints::Vector{Int32})
    mxi    = Int32(2)
    ints_buf = Vector{Int32}([KODIST, ISEFOR])
    IFWRIT(wk3, ipnt, ilimit, ints_buf, mxi, Int32(2))
    return nothing
end

function VARCHPUT(cbuff::Vector{UInt8}, ipnt::Ref{Int32}, lncbuf::Int32)
    # Stub: no character data for sn variant
    return nothing
end
