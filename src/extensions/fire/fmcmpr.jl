# fire/fmcmpr.f — Compress fire/snag model tree arrays after COMPRS
# Weighted-average of FMPROB, OLDHT, OLDCRL, OLDCRW[0:5], CROWNW[0:5], GROW_FM, FMICR
# Called from: COMPRS (base/comprs.jl)
# Note: Fortran source has a bug — inner loop accumulates FMICR(IREC1) instead of FMICR(IREC);
#       faithfully reproduced here.

function FMCMPR(nclas::Integer)
    debug = DBCHK("FMCMPR", 6, ICYC)
    if debug
        @printf(get(io_units, Int32(JOSTND), stdout),
            " ENTERING ROUTINE FMCMPR CYCLE = %2d LFMON=%s\n", ICYC, LFMON ? "T" : "F")
    end
    if !LFMON; return nothing; end

    local txp6 = zeros(Float32, 6)  # Fortran TXP6(0:5) → Julia [1..6]
    local txp7 = zeros(Float32, 6)

    local i1 = Int32(1)
    for icl in 1:Int(nclas)
        local i2 = Int(IND1[icl])
        local irec1 = Int(IND[i1])
        global IREC1 = Int32(irec1)

        if i1 == i2
            i1 = IND1[icl] + Int32(1)
            continue
        end

        local xp  = FMPROB[irec1]
        local txp = xp
        local k   = Int(i1) + 1

        local txp4 = OLDHT[irec1]  * xp
        local txp5 = OLDCRL[irec1] * xp
        for jj in 1:6
            txp6[jj] = OLDCRW[irec1, jj] * xp
            txp7[jj] = CROWNW[irec1, jj] * xp
        end
        local txp8 = Float32(GROW_FM[irec1]) * xp
        local txp9 = Float32(FMICR[irec1])   * xp

        for ii in k:i2
            local irec = Int(IND[ii])
            local xp2  = FMPROB[irec]
            txp  += xp2
            txp4 += OLDHT[irec]  * xp2
            txp5 += OLDCRL[irec] * xp2
            for jj in 1:6
                txp6[jj] += OLDCRW[irec, jj] * xp2
                txp7[jj] += CROWNW[irec, jj] * xp2
            end
            txp8 += Float32(GROW_FM[irec]) * xp2
            txp9 += Float32(FMICR[irec1])  * xp2   # Fortran bug: irec1 not irec
        end

        FMPROB[irec1] = txp
        if txp > 0.0f0
            OLDHT[irec1]  = txp4 / txp
            OLDCRL[irec1] = txp5 / txp
            for jj in 1:6
                OLDCRW[irec1, jj] = txp6[jj] / txp
                CROWNW[irec1, jj] = txp7[jj] / txp
            end
            GROW_FM[irec1]  = Int32(txp8 / txp)
            FMICR[irec1]    = Int32(txp9 / txp + 0.5f0)
        else
            OLDHT[irec1]  = 0.0f0
            OLDCRL[irec1] = 0.0f0
            for jj in 1:6
                OLDCRW[irec1, jj] = 0.0f0
                CROWNW[irec1, jj] = 0.0f0
            end
            GROW_FM[irec1]  = Int32(0)
            FMICR[irec1]    = Int32(0)
        end

        i1 = IND1[icl] + Int32(1)
    end
    return nothing
end
