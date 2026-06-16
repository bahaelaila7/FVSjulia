# base/opcset.jl — OPCSET: set up per-cycle activity sort array
# Translated from: bin/FVSsn_buildDir/opcset.f (43 lines)
#
# Called at the start of each cycle from GRINCR.
# Copies this cycle's portion of the all-cycle sort array (IOPSRT) into
# the within-cycle sort array (IOPCYC) and sorts by activity number.

function OPCSET(icyc::Integer)
    global IMG1 = IMGPTS[Int(icyc), 1]
    if IMG1 == Int32(0); return nothing; end
    global IMG2 = IMGPTS[Int(icyc), 2]

    # Copy this cycle's activities from IOPSRT → IOPCYC
    for i in Int(IMG1):Int(IMG2)
        IOPCYC[i] = IOPSRT[i]
    end

    # Sort IOPCYC on ascending activity numbers
    n   = Int(IMG2) - Int(IMG1) + 1
    seg = view(IOPCYC, Int(IMG1):Int(IMG2))
    IAPSRT(n, IACT[:, 1], seg, false)

    return nothing
end
