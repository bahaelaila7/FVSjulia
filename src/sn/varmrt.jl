# sn/varmrt.f — VARMRT: distribute density-related mortality by shade tolerance
# Translated from: bin/FVSsn_buildDir/varmrt.f (229 lines)
#
# Distributes TOKILL TPA across ITRN tree records using a geometric-progression
# algorithm. NPASS is adjusted iteratively until the summed mortality ≈ TOKILL.
# Result: WK2[i] = TPA killed for tree i; SUMKIL = total killed.

function VARMRT(tokill::Ref{Float32}, debug::Bool, sumkil::Ref{Float32})
    # shade tolerance scalars for sn 90 species (VARADJ, index 1..90)
    varadj = Float32[
        0.1f0, 0.7f0, 0.3f0, 0.7f0, 0.7f0, 0.7f0, 0.1f0, 0.7f0, 0.7f0, 0.7f0,
        0.7f0, 0.5f0, 0.7f0, 0.7f0, 0.5f0, 0.5f0, 0.1f0, 0.3f0, 0.3f0, 0.3f0,
        0.3f0, 0.1f0, 0.3f0, 0.7f0, 0.7f0, 0.1f0, 0.5f0, 0.7f0, 0.5f0, 0.3f0,
        0.1f0, 0.1f0, 0.1f0, 0.3f0, 0.7f0, 0.7f0, 0.3f0, 0.7f0, 0.3f0, 0.3f0,
        0.1f0, 0.7f0, 0.7f0, 0.7f0, 0.7f0, 0.3f0, 0.5f0, 0.3f0, 0.5f0, 0.3f0,
        0.7f0, 0.3f0, 0.7f0, 0.3f0, 0.7f0, 0.3f0, 0.3f0, 0.3f0, 0.5f0, 0.9f0,
        0.9f0, 0.7f0, 0.5f0, 0.9f0, 0.5f0, 0.7f0, 0.7f0, 0.3f0, 0.5f0, 0.7f0,
        0.7f0, 0.7f0, 0.7f0, 0.5f0, 0.5f0, 0.7f0, 0.7f0, 0.5f0, 0.5f0, 0.9f0,
        0.9f0, 0.7f0, 0.3f0, 0.5f0, 0.3f0, 0.5f0, 0.3f0, 0.5f0, 0.5f0, 0.5f0]

    io = io_units[JOSTND]

    if debug
        @printf(io, "0ENTERING VARMRT CYCLE =%3d DENSITY RELATED TOKILL = %6.1f\n", ICYC, tokill[])
    end

    # if TOKILL==0, sum background mortality already in WK2
    if tokill[] == Float32(0.0)
        t = Float32(0.0)
        for i in 1:ITRN; t += WK2[i]; end
        tokill[] = t
        if debug; @printf(io, " BACKGROUND TOKILL = %g\n", tokill[]); end
    end

    temkil  = tokill[]
    jpass   = 0
    pass1   = Float32(0.0)
    sumkil[] = Float32(0.0)

    temwk2 = zeros(Float32, ITRN)
    efftr  = zeros(Float32, ITRN)
    for i in 1:ITRN
        WK2[i] = Float32(0.0)
    end

    # compute per-tree mortality efficiency values
    for i in 1:ITRN
        jspc = ISP[i]
        peff = 0.84525f0 - 0.01074f0 * PCT[i] + 0.0000002f0 * PCT[i]^3.0f0
        peff = clamp(peff, 0.01f0, 1.0f0)
        efftr[i] = peff * varadj[jspc] * 0.1f0
        pass1   += PROB[i] * efftr[i]
    end

    if debug
        @printf(io, " MORTALITY EFFICIENCY VALUES, ITRN = %7d\n", ITRN)
        for ig in 1:ITRN; @printf(io, "%10.5f", efftr[ig]); end
        @printf(io, "\n TREES KILLED IN ONE PASS = %g\n", pass1)
    end

    npass    = Int(floor(tokill[] / pass1)) + 1
    short_v  = Float32(0.0)   # running shortfall from previous outer pass

    if debug
        @printf(io, " APPROXIMATE NUMBER OF PASSES NEEDED = %d\n", npass)
    end

    # outer loop: outer pass (Fortran label 100)
    while true
        jpass += 1
        if jpass > 1
            temkil = short_v
        end
        iswtch = 0

        # inner loop: adjust NPASS until ADJUST is in [0.8, 1.2] (Fortran label 105)
        while true
            temsum = Float32(0.0)
            for i in 1:ITRN
                tpalft = PROB[i] - WK2[i]
                if tpalft > Float32(0.0)
                    otem2 = temwk2[i]
                    temwk2[i] = -tpalft * ((1.0f0 - efftr[i])^npass - 1.0f0)
                    if debug
                        @printf(io, " I,PROB,WK2,TPALFT,EFFTR,TEMWK2,OTEM2= %d %g %g %g %g %g %g\n",
                                i, PROB[i], WK2[i], tpalft, efftr[i], temwk2[i], otem2)
                    end
                    temsum += temwk2[i]
                end
            end
            if debug
                @printf(io, " AFTER GUESS %d TEMSUM= %g  TOKILL= %g\n", jpass, temsum, tokill[])
            end

            minstp = npass > 50 ? 5 : (npass > 20 ? 2 : 1)
            adjust = temkil / temsum

            if adjust < Float32(0.8) && iswtch != 2
                if debug
                    @printf(io, " TEMKIL,TEMSUM,PASS1,NPASS= %g %g %g %d\n", temkil, temsum, pass1, npass)
                end
                npass  = npass - max(minstp, Int(floor((temsum - temkil) / pass1)))
                if debug
                    @printf(io, " ADJUST= %g  IS TO SMALL, MIN STEP= %d NEW NPASS= %d\n", adjust, minstp, npass)
                end
                iswtch = 1
                npass > 0 && continue   # @goto 105
            elseif adjust > Float32(1.2) && iswtch != 1
                npass  = npass + max(minstp, Int(floor((temkil - temsum) / pass1)))
                if debug
                    @printf(io, " ADJUST= %g  IS TO BIG, MIN STEP= %d NEW NPASS= %d\n", adjust, minstp, npass)
                end
                iswtch = 2
                continue   # @goto 105
            end
            break   # ADJUST in [0.8,1.2] or oscillating → fall to label 110
        end  # inner while (label 105)

        # label 110: apply adjusted mortality values
        short_v = Float32(0.0)
        if debug
            @printf(io, " TEMKIL= %g  TEMSUM= %g  ADJUSTMENT= %g\n", temkil, temsum, temkil / (temsum == 0 ? 1 : temsum))
        end
        adjust = temkil / (temsum == Float32(0.0) ? Float32(1.0) : temsum)

        for i in 1:ITRN
            tpalft = PROB[i] - WK2[i]
            tpalft < Float32(0.00001) && continue
            xkill = temwk2[i] * adjust
            if (PROB[i] - WK2[i] - xkill) <= Float32(0.00001)
                temwk2[i] = PROB[i] - WK2[i]
                if debug
                    @printf(io, " SHORT,I,XKILL,PROB,WK2= %g %d %g %g %g\n",
                            short_v, i, xkill, PROB[i], WK2[i])
                end
                short_v += xkill - PROB[i] + WK2[i]
                if debug; @printf(io, " SHORT= %g\n", short_v); end
                pass1 -= efftr[i]
            else
                temwk2[i] = xkill
            end
            WK2[i]   += temwk2[i]
            sumkil[] += temwk2[i]
        end

        if debug
            @printf(io, " ADJUSTED MORTALITY VALUES, ITRN = %7d\n", ITRN)
            for ig in 1:ITRN; @printf(io, "%10.5f", WK2[ig]); end
            @printf(io, "\n SHORT = %g\n", short_v)
        end

        short_v <= Float32(0.0) && break   # done; exit outer loop

        npass = Int(floor(short_v / pass1)) + 1
        if debug
            @printf(io, " SHORT,PASS1, ADJUSTED PASSES NEEDED= %g %g %d\n", short_v, pass1, npass)
        end
    end  # outer while (label 100)

    return nothing
end
