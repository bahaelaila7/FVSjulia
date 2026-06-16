# tregro.jl — Per-cycle tree growth driver
# Translated from: base/tregro.f (61 lines)
#
# TREGRO orchestrates one simulation cycle:
#   GRINCR: compute increments + harvest
#   GRADD:  apply growth, update tree records, establishment

"""
    TREGRO()

Main per-cycle growth driver. Called from FVS! once per simulation cycle.
Dispatches to GRINCR (pre-growth) and GRADD (post-growth update).
"""
function TREGRO()
    ltmgo  = false
    lmpbgo = false
    ldfbgo = false
    lbwego = false
    lcvatv = false

    debug = DBCHK("TREGRO", Int32(6))

    istopres = fvsGetRestartCode()
    if debug
        @printf(io_units[JOSTND], " IN TREGRO, ICYC=%3d ISTOPRES=%3d\n", ICYC, istopres)
    end
    if !(istopres >= Int32(5) && istopres != Int32(7))
        GRINCR(debug, Int32(1), ltmgo, lmpbgo, ldfbgo, lbwego, lcvatv)
        istopdone = getAmStopping()
        if istopdone != Int32(0); return nothing; end
        irtncd = fvsGetRtnCode()
        if irtncd != Int32(0); return nothing; end
    end

    GRADD(debug, Int32(1), ltmgo, lmpbgo, ldfbgo, lbwego, lcvatv)
    irtncd = fvsGetRtnCode()
    if irtncd != Int32(0); return nothing; end

    if debug
        @printf(io_units[JOSTND], " END OF TREGRO, CYCLE=%2d\n", ICYC)
    end
    return nothing
end
