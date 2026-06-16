# base/dense.jl — DENSE: compute stand density statistics
# Translated from: bin/FVSsn_buildDir/dense.f (306 lines)
#
# Calculates average height (AVH), crown competition factor (RELDEN),
# relative density by species (RELDSP), and maintains backdating support
# for calibration.  Calls CCFCAL, MBACAL, PCTILE, PTBAL.
#
# The Fortran "GO TO 6" inside the LREDO block is a backward jump that
# reruns the species loop without backdating.  Implemented here as an
# outer while-loop with a lredo flag.

function DENSE()
    debug = DBCHK("DENSE", Int32(5))

    lredo = false
    io    = get(io_units, Int(JOSTND), stdout)

    if ITRN <= Int32(0)
        # still need to zero out and continue to density calc below
        @goto label_after_backdate
    end

    # Load WK3 with current DBH
    for i in 1:Int(IREC1)
        WK3[i] = DBH[i]
    end

    if debug
        @printf(io, " IN DENSE;  IDG = %2d;  LBKDEN = %s\n", IDG, LBKDEN ? "T" : "F")
    end

    if !LBKDEN
        @goto label_after_backdate
    end

    # -----------------------------------------------------------------------
    # Backdate diameters: load dead-tree DBH into WK3
    # -----------------------------------------------------------------------
    lredo = true

    if IREC2 <= Int(MAXTRE)
        for i in Int(IREC2):Int(MAXTRE)
            WK3[i] = DBH[i]
            if IMC[i] == Int32(9)
                WK3[i] = Float32(0)
            end
        end
    end

    # Compute average basal-area growth ratio
    bagr = Float32(0); sn_cnt = Float32(0)
    for i in 1:Int(IREC1)
        g = DG[i]; d = DBH[i]
        if g < Float32(0); continue; end
        g_adj = if IDG == Int32(1)
            g
        else
            g / BRATIO(Int(ISP[i]), d, Float32(HT[i]))
        end
        if g_adj > d; continue; end
        bagr   += Float32(1) - (Float32(2)*d*g_adj - g_adj*g_adj) / (d*d)
        sn_cnt += Float32(1)
    end

    if sn_cnt <= Float32(0)
        @goto label_after_backdate
    end
    bagr /= sn_cnt

    # Backdate each active tree diameter into WK3
    for i in 1:Int(IREC1)
        is_i = Int(ISP[i]); g = DG[i]; d = DBH[i]
        g_adj = if IDG == Int32(1)
            g
        else
            g2 = g / BRATIO(is_i, d, Float32(HT[i]))
            g2 > d ? d : g2
        end
        r = Float32(1) - (Float32(2)*d*g_adj - g_adj*g_adj) / (d*d)
        if g_adj < Float32(0) || r <= Float32(0); r = bagr; end
        WK3[i] = sqrt(d*d*r)
        if debug
            @printf(io, " IN DENSE: I = %4d;  IS = %2d;  G = %6.2f;  R = %8.5f;  D = %6.2f;  WK3 = %6.2f\n",
                    i, is_i, g_adj, r, d, WK3[i])
        end
    end

    @label label_after_backdate

    # -----------------------------------------------------------------------
    # Outer loop: first pass (lredo=true for backdated) then second (lredo=false)
    # Locals declared here so they're visible after break
    # -----------------------------------------------------------------------
    tsumd2 = Float32(0); reldt = Float32(0); bat = Float32(0); sumdr0 = Float32(0)

    while true

        # Initialize density arrays (skip on second pass of backdating)
        if !(LBKDEN && !lredo)
            for ip in 1:Int(MAXPLT)
                BAAA[ip]  = Float32(0); PCCF[ip]  = Float32(0)
                PTPA[ip]  = Float32(0); PTPAA[ip] = Float32(0)
                PRDA[ip]  = Float32(0)
                for is in 1:Int(MAXSP)
                    OVER[is, ip] = Float32(0)
                end
            end
        end

        for is in 1:Int(MAXSP)
            RELDSP[is] = Float32(0)
        end

        tsumd2 = Float32(0)
        reldt  = Float32(0)
        global TPROB  = Float32(0)
        bat    = Float32(0)
        global BA     = Float32(0)
        sumdr0 = Float32(0)
        global DR016  = Float32(0)

        MBACAL()

        ccft_ref = Ref(Float32(0)); cw_ref = Ref(Float32(0))

        # -------------------------------------------------------------------
        # Species loop — accumulate CCF, BA, point density stats
        # -------------------------------------------------------------------
        for ispc in 1:Int(MAXSP)
            i2 = Int(ISCT[ispc, 2])
            if i2 <= 0; continue; end
            i1 = Int(ISCT[ispc, 1])

            for i3 in i1:i2
                i_t = Int(IND1[i3])
                p   = PROB[i_t]
                global TPROB += p

                d = (LBKDEN && lredo) ? WK3[i_t] : DBH[i_t]

                if d >= DBHSDI
                    sumdr0 += p * d^Float32(1.605)
                end

                dp       = d * p
                WK5[i_t] = d * dp          # D² * PROB
                tsumd2  += WK5[i_t]
                ip_t     = Int(ITRE[i_t])
                batree   = Float32(0.005454154) * WK5[i_t]
                bat     += batree

                CCFCAL(Int32(ispc), d, Float32(HT[i_t]), Int32(ICR[i_t]),
                       p, false, ccft_ref, cw_ref, Int32(1))
                ccft_v = ccft_ref[]

                if debug
                    @printf(io, " DENSE: CCFT PROB =%10.2f%10.2f\n", ccft_v, p)
                end

                RELDSP[ispc] += ccft_v

                if LBKDEN && !lredo
                    # Second-pass backdating: skip point density recompute
                    if debug
                        @printf(io, " IN DENSE: LBKDEN,LREDO,D,REGNBK = %s%s%15.7e%15.7e\n",
                                " T", " F", d, REGNBK)
                    end
                    continue
                end

                if debug
                    @printf(io, " IN DENSE: LBKDEN,LREDO,D,REGNBK = %s%s%15.7e%15.7e\n",
                            LBKDEN ? " T" : " F", lredo ? " T" : " F", d, REGNBK)
                end

                PCCF[ip_t] += ccft_v * Float32(PI) / GROSPC
                PTPA[ip_t] += p      * Float32(PI) / GROSPC

                if d < REGNBK; continue; end
                BAAA[ip_t]       += batree * Float32(PI) / GROSPC
                OVER[ispc, ip_t] += batree * Float32(PI) / GROSPC
                PTPAA[ip_t]      += p      * Float32(PI) / GROSPC
                if XMAXPT[ip_t] > Float32(0)
                    PRDA[ip_t] += (p * (d / Float32(10))^Float32(1.605) * Float32(PI) / GROSPC) / XMAXPT[ip_t]
                end
            end

            reldt += RELDSP[ispc]

            if debug
                @printf(io, " CCF FOR SPECIES%3d=%10.3f\n", ispc, RELDSP[ispc])
            end
        end   # species loop

        # -------------------------------------------------------------------
        # End of first (backdated) pass: save RELDM1/OLDBA, redo
        # -------------------------------------------------------------------
        if lredo
            lredo = false
            if Int(IREC2) <= Int(MAXTRE)
                for i in Int(IREC2):Int(MAXTRE)
                    WK3[i] = Float32(0.01)
                end
            end
            global RELDM1 = reldt
            global OLDBA  = bat
            PCTILE(Int(ITRN), IND, WK5, PCT)
            continue   # re-enter while loop for non-backdated pass
        end

        # -------------------------------------------------------------------
        # Non-backdated pass results (exits the while loop)
        # -------------------------------------------------------------------
        global RELDEN = reldt
        global RMSQD  = Float32(0)
        if ITRN > Int32(0) && TPROB > Float32(0)
            global RMSQD = sqrt(tsumd2 / TPROB)
            global DR016 = (sumdr0 / TPROB)^(Float32(1) / Float32(1.605))
        end
        global BA = bat

        if LBKDEN
            # Calibration: interpolate density estimates
            rat   = FINTH / FINT
            temp1 = (RELDEN - RELDM1) * rat + RELDM1
            temp2 = (BA     - OLDBA)  * rat + OLDBA
            global RELDEN = RELDM1
            global RELDM1 = temp1
            global BA     = OLDBA
            global OLDBA  = temp2
            if debug
                @printf(io, " IN DENSE:  BA = %8.2f, OLDBA = %8.2f, RELDEN = %8.2f, RELDM1 = %8.2f\n",
                        BA, OLDBA, RELDEN, RELDM1)
            end
        end

        if !LBKDEN
            PCTILE(Int(ITRN), IND, WK5, PCT)
            if LSTART
                global RELDM1 = RELDEN
            end
        end

        PTBAL()
        break   # exit while loop
    end   # while true

    # -----------------------------------------------------------------------
    # Top height: average HT of 40 largest-DBH trees/acre
    # -----------------------------------------------------------------------
    global AVH = Float32(0)
    if ITRN <= Int32(0)
        return nothing
    end

    ssumn = Float32(0)
    for i in 1:Int(ITRN)
        ii = Int(IND[i])
        p  = PROB[ii]
        if ssumn + p > Float32(40); p = Float32(40) - ssumn; end
        ssumn += p
        global AVH += HT[ii] * p
        if ssumn >= Float32(40); break; end
    end
    if ssumn > Float32(0)
        global AVH = AVH / ssumn
    end

    if debug
        @printf(io, " IN DENSE, GROSPC = %10.4f, TPROB = %10.4f, TSUMD2 = %10.2f, RELDEN = %10.4f, BA = %10.4f\n     RMSQD = %10.4f, AVH = %10.4f DR016= %10.4f\n",
                GROSPC, TPROB, tsumd2, RELDEN, BA, RMSQD, AVH, DR016)
    end

    return nothing
end
