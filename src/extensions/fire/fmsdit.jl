# SUBROUTINE FMSDIT — fire stand data initialization, called from GRINCR each cycle
# Translated from: fmsdit.f (139 lines)
#
# Resets SCCF and FIRKIL, copies PROB/ICR to fire model arrays, computes crown-lifting
# fractions from old/new crown geometry, calls FMCROW to refresh crown weights.

function FMSDIT()
    local debug::Bool = false
    DBCHK(Ref(debug), "FMSDIT", Int32(6), ICYC)
    if debug
        @printf(io_units[Int32(JOSTND)], " ENTERING ROUTINE FMSDIT CYCLE = %2d LFMON=%s\n",
                ICYC, LFMON)
    end

    if !LFMON; return; end

    global IFMYR1 = Int32(-1)

    EVUST4(Int32(22))   # CROWNIDX
    EVUST4(Int32(26))   # CRBASEHT
    EVUST4(Int32(27))   # TORCHIDX
    EVUST4(Int32(28))   # CRBULKDN

    if ICYC == 1
        EVSET4(Int32(21), Float32(-1.0))
        EVSET4(Int32(23), Float32(BURNYR))
        EVSET4(Int32(20), Float32(0.0))
    end

    global FMKOD  = KODTYP
    global FMSLOP = SLOPE
    global SCCF   = Float32(0.0)

    local cyclen::Float32 = Float32(IY[ICYC+1] - IY[ICYC])

    for i in 1:ITRN
        FMPROB[i] = PROB[i]
        FMICR[i]  = ICR[i]
    end
    for i in 1:MAXTRE
        FIRKIL[i] = Float32(0.0)
    end

    global TONRMS = Float32(0.0)
    global TONRMH = Float32(0.0)
    global TONRMC = Float32(0.0)

    if ICYC > 1
        for i in 1:ITRN
            local oldbot::Float32 = OLDHT[i] - OLDCRL[i]
            local newbot::Float32 = HT[i] - (HT[i] * Float32(ICR[i]) / 100.0f0)

            if (OLDCRL[i] > 0.001f0) && (newbot - oldbot > 0.0f0)
                local x::Float32 = ((newbot - oldbot) / OLDCRL[i]) / cyclen
                for j in 0:5
                    if OLDCRW[i, j+1] < 0.0000625f0
                        OLDCRW[i, j+1] = Float32(0.0)
                    else
                        OLDCRW[i, j+1] = x * OLDCRW[i, j+1]
                    end
                end
            else
                for j in 0:5
                    OLDCRW[i, j+1] = Float32(0.0)
                end
            end
        end
    end

    # Calculate crown component weights for this cycle (needs HT and DBH)
    FMCROW()

    # On first call, add inventory snags; IY[1]-FINTM gives year of last
    # mortality measurement period start
    if LFMON2
        FMSADD(IY[1] - Int32(FINTM), Int32(3))
    end

    return nothing
end
