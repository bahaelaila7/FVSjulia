# sdichk.jl — SDICHK: check if initial stand SDI exceeds specified maximum
# Translated from: sdichk.f (106 lines)
# Called from SITSET in variants using SDI-based mortality.

function SDICHK()
    io = io_units[Int32(JOSTND)]
    debug = DBCHK(false, "SDICHK", Int32(6), ICYC)
    if debug
        @printf(io, " ENTERING SUBROUTINE SDICHK\n")
        @printf(io, "\nIN SDICHK 9010 ICYC,RMSQD= %5d     %6.2f\n", ICYC, RMSQD)
    end

    # Convert PMSDIL and PMSDIU from percent to proportion
    global PMSDIL = PMSDIL / Float32(100)
    global PMSDIU = PMSDIU / Float32(100)

    dq0 = RMSQD
    if LZEIDE; dq0 = DR016; end

    if dq0 < Float32(0.3)
        dq0 = Float32(0.3)
        if debug; @printf(io, " RESETTING DQ0= %g\n", dq0); end
    end
    if debug
        @printf(io, " DQ0,RMSQD,DR016= %g %g %g\n", dq0, RMSQD, DR016)
    end

    # SDIMAX carries weighted SDI maximum via SDICAL
    global SDIMAX = SDICAL(Int32(0))
    const_v = SDIMAX / Float32(0.02483133)
    tmd0 = const_v * (dq0^Float32(-1.605))
    if tmd0 > Float32(35000); tmd0 = Float32(35000); end

    upmax = PMSDIU + Float32(0.05)
    if upmax > Float32(1); upmax = Float32(1); end
    temd0  = LZEIDE ? DR016 : RMSQD
    temtpa = TPROB
    temmax = const_v * (temd0^Float32(-1.605))
    if temtpa <= upmax * temmax; return nothing; end

    tem  = const_v * Float32(0.02483133)
    tem  = upmax * tem
    if debug
        @printf(io, " IN SDICHK 9030%10.2f%10.2f%10.2f%10.2f\n",
            const_v, tem, temtpa, temd0)
    end

    const_v2 = exp(log(temtpa + Float32(1)) + Float32(1.605) * log(temd0)) / PMSDIU
    tem2 = const_v2 * Float32(0.02483133)
    for i in 1:Int(MAXSP)
        SDIDEF[i] = tem2
    end
    uplim = tmd0 * PMSDIU
    @printf(io, "\n%s\nFVS41    INITIAL STAND STOCKING OF %8.1f TREES/ACRE IS MORE THAN 5%% ABOVE THE UPPER LIMIT OF %8.1f TREES/ACRE.\nWARNING: UPPER LIMIT IS BASED ON A SDI MAXIMUM OF %10.1f AND AN UPPER BOUND OF %5.1f PERCENT OF MAXIMUM.\n         MAXIMUM SDI BEING RESET TO%10.1f FOR FURTHER PROCESSING.\n%s\n",
        repeat("***************", 2) * "\n",
        temtpa, uplim, SDIMAX, PMSDIU * Float32(100), tem2,
        repeat("***************", 2) * "\n")
    global LFIXSD = true
    ERRGRO(true, Int32(41))
    return nothing
end
