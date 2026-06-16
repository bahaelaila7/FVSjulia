# base/cwidth.jl — CWIDTH: compute crown width for each tree record
# Translated from: bin/FVSsn_buildDir/cwidth.f (188 lines)
#
# For each tree: uses user-defined equations (CWDCOM) if available,
# otherwise calls CWCALC (default species-specific models).
# Also processes FIXCW keyword (activity 90) crown-width multipliers.

function CWIDTH()
    debug = DBCHK("CWIDTH", Int32(6))
    io    = get(io_units, Int(JOSTND), stdout)

    if debug
        @printf(io, " ENTERING CWIDTH ICYC,ITRN= %d %d\n", ICYC, ITRN)
    end

    myacts = Int32[90]   # activity 90 = FIXCW

    # -----------------------------------------------------------------------
    # Compute crown width for live trees (1..ITRN)
    # -----------------------------------------------------------------------
    if ITRN > Int32(0)
        cw_ref = Ref(Float32(0))
        for i in 1:Int(ITRN)
            ispc = Int(ISP[i])
            p    = PROB[i]; d = DBH[i]; h = HT[i]
            cr   = Float32(ICR[i]); iicr = Int(ICR[i])
            CRWDTH[i] = Float32(0)

            if LSPCWE[ispc]
                cw_val = if d < CWTDBH[ispc]
                    CWDS0[ispc] + CWDS1[ispc]*d + CWDS2[ispc]*(d^CWDS3[ispc])
                else
                    CWDL0[ispc] + CWDL1[ispc]*d + CWDL2[ispc]*(d^CWDL3[ispc])
                end
                CRWDTH[i] = cw_val
            else
                CWCALC(ispc, p, d, h, cr, iicr, cw_ref, Int32(0), Int32(JOSTND))
                CRWDTH[i] = cw_ref[]
            end

            if debug
                @printf(io, " LIVE: I,ISPC,D,CR,CW= %d %d %f %f %f\n",
                        i, ispc, d, cr, CRWDTH[i])
            end
        end
    end

    # -----------------------------------------------------------------------
    # Compute crown width for cycle-0 dead trees (IREC2..MAXTRE)
    # -----------------------------------------------------------------------
    if IREC2 <= Int32(MAXTRE)
        cw_ref = Ref(Float32(0))
        for i in Int(IREC2):Int(MAXTRE)
            ispc = Int(ISP[i])
            p    = PROB[i]; d = DBH[i]; h = HT[i]
            cr   = Float32(ICR[i]); iicr = Int(ICR[i])
            CRWDTH[i] = Float32(0)

            if LSPCWE[ispc]
                cw_val = if d < CWTDBH[ispc]
                    CWDS0[ispc] + CWDS1[ispc]*d + CWDS2[ispc]*(d^CWDS3[ispc])
                else
                    CWDL0[ispc] + CWDL1[ispc]*d + CWDL2[ispc]*(d^CWDL3[ispc])
                end
                CRWDTH[i] = cw_val
            else
                CWCALC(ispc, p, d, h, cr, iicr, cw_ref, Int32(0), Int32(JOSTND))
                CRWDTH[i] = cw_ref[]
            end

            if debug
                @printf(io, " DEAD: I,ISPC,D,H,CW= %d %d %f %f %f\n",
                        i, ispc, d, h, CRWDTH[i])
            end
        end
    end

    # -----------------------------------------------------------------------
    # Process FIXCW keyword (activity 90) — crown width multipliers
    # -----------------------------------------------------------------------
    ntodo = OPFIND(Int32(1), myacts)

    if debug
        @printf(io, " PROCESSING FIXCW, NTODO= %d\n", ntodo)
    end

    if ntodo > Int32(0)
        prm = zeros(Float32, 5)
        for itodo in 1:Int(ntodo)
            iactk, idate, np = OPGET(itodo, Int32(4), prm)

            if debug
                @printf(io, " ITODO,IDATE,IACTK,NP,PRM= %d %d %d %d %f %f %f %f %f\n",
                        itodo, idate, iactk, np, prm[1], prm[2], prm[3], prm[4], prm[5])
            end

            if iactk < Int32(0); continue; end
            if ICYC > Int32(0); OPDONE(itodo, IY[Int(ICYC)]); end

            ispcc = Int(floor(prm[1]))
            if prm[2] < Float32(0); prm[2] = Float32(0); end
            if prm[3] < Float32(0); prm[3] = Float32(0); end
            if prm[4] <= Float32(0); prm[4] = Float32(999); end

            if debug
                @printf(io, " FIXCW: ISPCC,MULT,DBHLO,DBHHI= %d %f %f %f\n",
                        ispcc, prm[2], prm[3], prm[4])
            end

            # Apply multiplier to live trees
            if ITRN > Int32(0)
                for i in 1:Int(ITRN)
                    lincl = if ispcc == 0 || ispcc == Int(ISP[i])
                        true
                    elseif ispcc < 0
                        igrp  = -ispcc
                        iulim = Int(ISPGRP[igrp, 1]) + 1
                        found = false
                        for ig in 2:iulim
                            if Int(ISP[i]) == Int(ISPGRP[igrp, ig])
                                found = true; break
                            end
                        end
                        found
                    else
                        false
                    end

                    if lincl && prm[3] <= DBH[i] && DBH[i] < prm[4]
                        CRWDTH[i] *= prm[2]
                        if CRWDTH[i] > Float32(99.9); CRWDTH[i] = Float32(99.9); end
                        if debug
                            @printf(io, " LIVE: I,ISPCC,ISP,DBH,CRWDTH= %d %d %d %f %f\n",
                                    i, ispcc, ISP[i], DBH[i], CRWDTH[i])
                        end
                    end
                end
            end

            # Apply multiplier to dead trees
            if IREC2 > Int32(MAXTRE); continue; end
            for i in Int(IREC2):Int(MAXTRE)
                lincl = if ispcc == 0 || ispcc == Int(ISP[i])
                    true
                elseif ispcc < 0
                    igrp  = -ispcc
                    iulim = Int(ISPGRP[igrp, 1]) + 1
                    found = false
                    for ig in 2:iulim
                        if Int(ISP[i]) == Int(ISPGRP[igrp, ig])
                            found = true; break
                        end
                    end
                    found
                else
                    false
                end

                if lincl && prm[3] <= DBH[i] && DBH[i] < prm[4]
                    CRWDTH[i] *= prm[2]
                    if CRWDTH[i] > Float32(99.9); CRWDTH[i] = Float32(99.9); end
                    if debug
                        @printf(io, " DEAD: I,ISPCC,ISP,DBH,CRWDTH= %d %d %d %f %f\n",
                                i, ispcc, ISP[i], DBH[i], CRWDTH[i])
                    end
                end
            end
        end
    end

    if debug
        @printf(io, " LEAVING CWIDTH ICYC= %d\n", ICYC)
    end

    return nothing
end
