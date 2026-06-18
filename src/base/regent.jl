# regent.jl — REGENT / REGCON: small-tree height and diameter growth + calibration
# Translated from: regent.f (588 lines)
#
# REGENT  — height/diameter increments for trees < 5 in DBH.
#           Called from CRATET (calibration, LESTB=false, LSTART=true) and
#           TREGRO (cycling, LESTB=false, LSTART=false).
#           Also called from CRATET with LESTB=true for newly established trees.
# REGCON  — ENTRY point: load model constants (called once from RCON).
#
# Small-tree height increment uses NC128 height coefficients (from HTCALC).
# Small-tree DBH is derived from height via the Wykoff or Curtis-Arney model.

# ---------------------------------------------------------------------------
# SAVE-semantics module-level arrays (DATA-initialized, may be updated by
# user keywords in future; currently hold defaults from DATA statements)
# ---------------------------------------------------------------------------
const _REGENT_HGADJ = fill(Float32(1.0), MAXSP)   # height growth adjustment factors
const _REGENT_DGMAX = fill(Float32(5.0),  MAXSP)   # max 10-yr DG by species
const _REGENT_XMIN  = fill(Float32(1.0),  MAXSP)   # lower DBH blend limit
const _REGENT_XMAX  = fill(Float32(3.0),  MAXSP)   # upper DBH blend limit
const _REGENT_REGYR = Float32(5.0)                  # nominal growth period (yr)

# DIAM — budwidth transition values (inches); DATA initialized in REGCON entry.
# These must match _HTDBH_SNDBAL in htdbh.jl (same physical constant).
const _REGENT_DIAM = Float32[
    0.1f0,0.3f0,0.2f0,0.5f0,0.5f0,0.5f0,0.5f0,0.5f0,0.5f0,0.5f0,
    0.5f0,0.4f0,0.5f0,0.5f0,0.2f0,0.2f0,0.1f0,0.2f0,0.2f0,0.2f0,
    0.2f0,0.2f0,0.3f0,0.1f0,0.1f0,0.2f0,0.3f0,0.3f0,0.1f0,0.2f0,
    0.1f0,0.2f0,0.1f0,0.2f0,0.2f0,0.2f0,0.2f0,0.1f0,0.2f0,0.2f0,
    0.1f0,0.3f0,0.4f0,0.2f0,0.2f0,0.2f0,0.2f0,0.2f0,0.2f0,0.2f0,
    0.2f0,0.2f0,0.2f0,0.2f0,0.2f0,0.2f0,0.2f0,0.2f0,0.1f0,0.1f0,
    0.2f0,0.1f0,0.2f0,0.2f0,0.1f0,0.1f0,0.2f0,0.1f0,0.2f0,0.2f0,
    0.2f0,0.1f0,0.1f0,0.2f0,0.2f0,0.1f0,0.1f0,0.2f0,0.2f0,0.1f0,
    0.1f0,0.1f0,0.1f0,0.1f0,0.1f0,0.1f0,0.1f0,0.3f0,0.2f0,0.2f0,
]

# ---------------------------------------------------------------------------
function REGENT(lestb::Bool, itrnin::Integer)
    debug = DBCHK(false, "REGENT", Int32(6), ICYC)
    if debug
        @printf(io_units[Int(JOSTND)], "ENTERING SUBROUTINE REGENT  CYCLE =%5d%10.3f\n", ICYC, FINT)
    end

    htgr = Float32(0)
    lskiph = false

    fnt = FINT
    if LSTART; fnt = Float32(IFINTH); end
    if lestb
        if FINT <= Float32(5.0)
            lskiph = true
        else
            fnt = fnt - Float32(5.0)
        end
    end

    # ---------------------------------------------------------------------------
    # Calibration section (only on first call, LSTART == true)
    # ---------------------------------------------------------------------------
    if LSTART
        @goto label_40
    end

    # ---------------------------------------------------------------------------
    # Growth prediction section
    # ---------------------------------------------------------------------------
    # Growth multipliers default to 1.0; MULTS only overrides species named by
    # keywords (it returns early without touching the array when none exist).
    # Must NOT be `undef` — uninitialized entries become garbage multipliers that
    # corrupt regen height growth (HTG→999) and make the run non-deterministic.
    xrhmlt = ones(Float32, MAXSP)
    xrdmlt = ones(Float32, MAXSP)
    MULTS(Int32(3), IY[ICYC], xrhmlt)
    MULTS(Int32(6), IY[ICYC], xrdmlt)

    if ITRN <= 0
        @goto label_91
    end

    scale  = fnt / _REGENT_REGYR
    scale2 = YR / fnt

    for ispc in Int32(1):Int32(MAXSP)
        i1 = ISCT[ispc, 1]
        if i1 == 0; continue; end
        i2 = ISCT[ispc, 2]

        xrdgro = xrdmlt[ispc]
        xrhgro = xrhmlt[ispc]
        con    = RHCON[ispc] * exp(HCOR[ispc])
        xmx    = _REGENT_XMAX[ispc]
        xmn    = _REGENT_XMIN[ispc]
        dgmx   = _REGENT_DGMAX[ispc] * scale

        for i3 in i1:i2
            i    = Int(IND1[i3])
            ipccf = Int(ITRE[i])
            d    = DBH[i]
            if d >= xmx; continue; end

            ddum = Float32(0)
            if MANAGD == 1; ddum = Float32(1); end

            if lestb
                if i < Int(itrnin); continue; end
                ddum = Float32(1)
                cr_val = Float32(0.89722) - Float32(0.0000461) * PCCF[ipccf]
                local ran_cr::Float32
                while true
                    ran_cr = BACHLO(Float32(0), Float32(1))
                    if ran_cr >= Float32(-1.0) && ran_cr <= Float32(1.0); break; end
                end
                cr_val = cr_val + Float32(0.07985) * ran_cr
                if cr_val > Float32(0.90); cr_val = Float32(0.90); end
                if cr_val < Float32(0.20); cr_val = Float32(0.20); end
                ICR[i] = Int32(floor(cr_val * Float32(100) + Float32(0.5)))
            end

            k = i; l = 0; h = HT[i]

            while true  # tripling inner loop (GO TO 2 backward jump)
                if lskiph
                    HTG[k] = Float32(0)
                    # jump to label 4 (skip height growth)
                else
                    # label 2: height growth
                    mode0   = Int32(0)
                    aget_r  = Ref(Float32(0))
                    h_r     = Ref(h)
                    htmax_r = Ref(Float32(0))
                    htg1_r  = Ref(Float32(0))
                    HTCALC(mode0, Int32(ispc), aget_r, h_r, htmax_r, htg1_r, JOSTND, debug)
                    htmax = htmax_r[]

                    if htmax - h <= Float32(1.0)
                        if debug
                            @printf(io_units[Int(JOSTND)], " HTI>=HTMAX , ABIRTH= %g\n", ABIRTH[i])
                        end
                        htgr = Float32(0.10)
                    else
                        mode9   = Int32(9)
                        htgr    = Float32(0)
                        htg1_r2 = Ref(htgr)
                        HTCALC(mode9, Int32(ispc), aget_r, h_r, htmax_r, htg1_r2, JOSTND, debug)
                        htgr    = htg1_r2[]
                        ptccf   = PCCF[ipccf]

                        if debug
                            @printf(io_units[Int(JOSTND)], "I,ISPC,PTCCF,HGADJ,FNT,ABIRTH= %d %d %g %g %g %g\n",
                                i, ispc, ptccf, _REGENT_HGADJ[ispc], fnt, ABIRTH[i])
                            @printf(io_units[Int(JOSTND)], "I,SCALE,SCALE2,HTGR,DBH,BA,IPCCF= %d %g %g %g %g %g %d\n",
                                i, scale, scale2, htgr, d, BA, ipccf)
                        end

                        htgr = htgr * con * scale * _REGENT_HGADJ[ispc] * xrhgro
                        if htgr < Float32(0.1); htgr = Float32(0.1); end
                    end

                    xwt = (d - xmn) / (xmx - xmn)
                    if d <= xmn || lestb; xwt = Float32(0); end

                    if debug
                        @printf(io_units[Int(JOSTND)], "IN REGENT 9982 FORMAT%10.4f  %10.4f  %10.4f  %7d%7d\n",
                            xwt, htgr, HTG[k], i, k)
                    end

                    htgr = htgr * (Float32(1) - xwt) + xwt * HTG[k]
                    if htgr < Float32(0.1); htgr = Float32(0.1); end

                    # random effect (± 10%)
                    ran_h = Float32(0)
                    if DGSD >= Float32(1.0)
                        while true
                            ran_h = BACHLO(Float32(0), Float32(1))
                            if ran_h >= Float32(-1.0) && ran_h <= Float32(1.0); break; end
                        end
                    end
                    htgr = htgr + ran_h * Float32(0.1) * htgr

                    HTG[k] = htgr
                    if HTG[k] < Float32(0.1); HTG[k] = Float32(0.1); end

                    if debug
                        @printf(io_units[Int(JOSTND)], "IN REGENT HTGR,HTG(K),I,K,LESTB= \n%10.4f  %10.4f  %10d%10d%10s\n",
                            htgr, HTG[k], i, k, string(lestb))
                    end

                    # size cap for height
                    if (h + HTG[k]) > SIZCAP[ispc, 4]
                        HTG[k] = SIZCAP[ispc, 4] - h
                        if HTG[k] < Float32(0.1); HTG[k] = Float32(0.1); end
                    end
                end  # end of LSKIPH else block (label 4 falls through here)

                # label 4: DBH assignment / increment for D < 3 in
                if d < Float32(3.0)
                    hk = h + HTG[k]
                    if hk <= Float32(4.5)
                        DG[k]  = Float32(0)
                        DBH[k] = d + Float32(0.001) * hk
                    else
                        # Wykoff H→D inverse
                        bx = HT2[ispc]
                        ax = if IABFLG[ispc] == 1
                            HT1[ispc]
                        else
                            AA[ispc]
                        end

                        dkk = (bx / (log(hk - Float32(4.5)) - ax)) - Float32(1)
                        dk  = if h <= Float32(4.5)
                            d
                        else
                            (bx / (log(h - Float32(4.5)) - ax)) - Float32(1)
                        end

                        if debug
                            @printf(io_units[Int(JOSTND)], "I,ISPC,DBH,H,HK,DK,DKK,DDUM=  %d %d %g %g %g %g %g %g\n",
                                i, ispc, DBH[k], h, hk, dk, dkk, ddum)
                        end

                        # Use inventory (Curtis-Arney) equations if Wykoff calibration is off
                        if !LHTDRG[ispc] || (LHTDRG[ispc] && IABFLG[ispc] == 1)
                            # HTDBH mode 1: H → D; pass H as Ref, get D back in Ref
                            hk_ref = Ref(hk)
                            HTDBH(IFOR, ispc, Float32(0), hk_ref, Int32(1))
                            dkk = hk_ref[]
                            if h <= Float32(4.5)
                                dk = d
                            else
                                h_ref2 = Ref(h)
                                HTDBH(IFOR, ispc, Float32(0), h_ref2, Int32(1))
                                dk = h_ref2[]
                            end
                            if debug
                                @printf(io_units[Int(JOSTND)], "INV EQN DUBBING IFOR,ISPC,H,HK,DK,DKK= %d %d %g %g %g %g\n",
                                    IFOR, ispc, h, hk, dk, dkk)
                                @printf(io_units[Int(JOSTND)], "ISPC,LHTDRG,IABFLG= %d %s %d\n",
                                    ispc, string(LHTDRG[ispc]), IABFLG[ispc])
                            end
                        end

                        if lestb
                            DBH[k] = dkk
                            if DBH[k] < _REGENT_DIAM[ispc] || hk < Float32(4.5)
                                DBH[k] = _REGENT_DIAM[ispc]
                            end
                            DBH[k] = DBH[k] + Float32(0.001) * hk
                            DG[k]  = DBH[k]
                        else
                            bark = BRATIO(ispc, d, h)
                            if debug
                                @printf(io_units[Int(JOSTND)], "BARK,XRDGRO= %g %g\n", bark, xrdgro)
                            end
                            if dk < Float32(0) || dkk < Float32(0)
                                DG[k]  = HTG[k] * Float32(0.2) * bark * xrdgro
                                dkk    = d + DG[k]
                            else
                                DG[k] = (dkk - dk) * bark * xrdgro
                            end
                            if debug
                                @printf(io_units[Int(JOSTND)], "K,DK,DKK,DG= %d %g %g %g\n", k, dk, dkk, DG[k])
                            end
                            if DG[k] < Float32(0); DG[k] = Float32(0.1); end
                            if DG[k] > dgmx; DG[k] = dgmx; end

                            # scale DG to FINT-yr estimate via DDS
                            dds  = DG[k] * (Float32(2) * bark * d + DG[k]) * scale2
                            DG[k] = sqrt((d * bark)^2 + dds) - bark * d
                        end

                        if (DBH[k] + DG[k]) < _REGENT_DIAM[ispc]
                            DG[k] = _REGENT_DIAM[ispc] - DBH[k]
                        end
                    end
                end

                # label 23: DGBND size-cap check
                dg_ref = Ref(DG[k])
                DGBND(ispc, DBH[k], dg_ref)
                DG[k] = dg_ref[]

                if debug
                    htnew = HT[i] + HTG[i]
                    @printf(io_units[Int(JOSTND)], "IN REGENT, I=%4d,  ISPC=%3d  CUR HT=%7.2f,  HT INC=%7.4f,  NEW HT=%7.2f,  CUR DBH=%10.5f,  DBH INC(I,K)=%7.4f%7.4f\n",
                        i, ispc, HT[i], HTG[i], htnew, DBH[i], DG[i], DG[k])
                end

                # label 22: tripling decision
                if lestb || !LTRIP || l >= 2; break; end
                l += 1
                k = ITRN + 2*i - 2 + l
            end  # end tripling while loop
        end  # end tree loop (DO 25)
    end  # end species loop (DO 30)

    @goto label_91

    # ---------------------------------------------------------------------------
    # Calibration section (label 40, entered when LSTART=true)
    # ---------------------------------------------------------------------------
    @label label_40

    cortem  = ones(Float32, MAXSP)
    numcal  = zeros(Int32,  MAXSP)
    for isp in 1:MAXSP
        HCOR[isp] = Float32(0)
    end

    if ITRN <= 0
        @goto label_91
    end

    scale3 = _REGENT_REGYR / FINTH

    for ispc in Int32(1):Int32(MAXSP)
        cornew = Float32(1.0)
        i1 = ISCT[ispc, 1]
        if i1 == 0 || !LHTCAL[ispc]; continue; end

        n   = 0
        snp = Float32(0); snx = Float32(0); sny = Float32(0)
        i2  = ISCT[ispc, 2]
        irefi = Int(IREF[ispc])

        for i3 in i1:i2
            i  = Int(IND1[i3])
            h  = HT[i]
            if IHTG < 2; h = h - HTG[i]; end
            if DBH[i] >= Float32(5.0) || h < Float32(0.01); continue; end
            ipccf = Int(ITRE[i])
            ptccf = PCCF[ipccf]

            if debug
                @printf(io_units[Int(JOSTND)], " IN REGENT 8900 H =%g\n", h)
            end

            mode0   = Int32(0)
            aget_r  = Ref(Float32(0))
            h_r     = Ref(h)
            htmax_r = Ref(Float32(0))
            htg1_r  = Ref(Float32(0))
            HTCALC(mode0, Int32(ispc), aget_r, h_r, htmax_r, htg1_r, JOSTND, debug)

            mode9   = Int32(9)
            htgr2   = Float32(0)
            htg1_r2 = Ref(htgr2)
            HTCALC(mode9, Int32(ispc), aget_r, h_r, htmax_r, htg1_r2, JOSTND, debug)
            htgr2 = htg1_r2[]

            if htgr2 < Float32(0.1); htgr2 = Float32(0.1); end

            edh = htgr2 * RHCON[ispc]
            if edh < Float32(0.1); edh = Float32(0.1); end

            p = PROB[i]
            if HTG[i] < Float32(0.001); continue; end

            term = HTG[i] * scale3
            snp  = snp + p
            snx  = snx + edh * p
            sny  = sny + term * p
            n   += 1

            if debug
                @printf(io_units[Int(JOSTND)], "NPLT=%-8s,  I=%5d,  ISPC=%3d,  H=%6.1f,  DBH=%5.1f,  ICR%5d,  PCT=%6.1f,  RELDEN=%6.1f\n            RHCON=%10.3f,  EDH=%10.3f, TERM=%10.3f HTGR= %10.3f SCALE3= %10.3f HGADJ(ISPC)= %10.3f\n ICR= %5d\n",
                    NPLT, i, ispc, h, DBH[i], ICR[i], PCT[i], RELDM1, RHCON[ispc], edh, term, htgr2, scale3, _REGENT_HGADJ[ispc], ICR[i])
            end
        end  # end tree calibration loop (DO 60)

        if debug
            @printf(io_units[Int(JOSTND)], "\nSUMS FOR SPECIES %2d:  SNP=%10.2f;  SNX=%10.2f;  SNY=%10.2f\n", ispc, snp, snx, sny)
        end

        if n >= NCALHT
            snx = snx / snp
            sny = sny / snp
            cornew = sny / snx
            if cornew <= Float32(0); cornew = Float32(1e-4); end
            HCOR[ispc] = log(cornew)

            if cornew < Float32(0.0821) || cornew > Float32(12.1825)
                ERRGRO(true, Int32(27))
                @printf(io_units[Int(JOSTND)], "                           SMALL TREE HTG: SPECIES = %2d (%3s) CALCULATED CALIBRATION VALUE = %8.2f\n",
                    ispc, NSP[ispc, 1][1:min(3,length(NSP[ispc,1]))], cornew)
                cornew = Float32(1.0)
                HCOR[ispc] = Float32(0)
            end
        end

        cortem[irefi] = cornew
        numcal[irefi] = Int32(n)
    end  # end species calibration loop (DO 100)

    # print calibration summary
    @printf(io_units[Int(JOSTND)], "\nNUMBER OF RECORDS AVAILABLE FOR SCALING\nTHE SMALL TREE HEIGHT INCREMENT MODEL\n")
    for idx in 1:NUMSP
        if (idx - 1) % 11 == 0; @printf(io_units[Int(JOSTND)], "%48s", ""); end
        @printf(io_units[Int(JOSTND)], "%4d  ", numcal[idx])
        if idx % 11 == 0 || idx == NUMSP; @printf(io_units[Int(JOSTND)], "\n"); end
    end

    @printf(io_units[Int(JOSTND)], "\nINITIAL SCALE FACTORS FOR THE SMALL TREE\nHEIGHT INCREMENT MODEL\n")
    for idx in 1:NUMSP
        if (idx - 1) % 11 == 0; @printf(io_units[Int(JOSTND)], "%48s", ""); end
        @printf(io_units[Int(JOSTND)], "%5.2f ", cortem[idx])
        if idx % 11 == 0 || idx == NUMSP; @printf(io_units[Int(JOSTND)], "\n"); end
    end

    DBSCALIB(Int32(2), cortem, numcal, cortem)

    if JOCALB > 0
        kout = 0
        for k in 1:MAXSP
            if cortem[k] != Float32(1.0) || numcal[k] >= NCALHT
                spec = NSP[MAXSP, 1][1:min(2, length(NSP[MAXSP, 1]))]
                ispec = MAXSP
                for kk in 1:MAXSP
                    if k != Int(IREF[kk]); continue; end
                    ispec = kk
                    spec  = NSP[kk, 1][1:min(2, length(NSP[kk, 1]))]
                    break
                end
                @printf(io_units[Int(JOCALB)], " CAL: SH %2d %2s %4d %6.3f\n", ispec, spec, numcal[k], cortem[k])
                kout += 1
            end
        end
        if kout == 0
            @printf(io_units[Int(JOCALB)], " NO SH VALUES COMPUTED\n")
        end
        @printf(io_units[Int(JOCALB)], " CALBSTAT END\n")
    end

    @label label_91
    if debug
        @printf(io_units[Int(JOSTND)], "LEAVING SUBROUTINE REGENT  CYCLE =%5d\n", ICYC)
    end
    return nothing
end

# ---------------------------------------------------------------------------
# REGCON — load small-tree height growth model constants (called from RCON).
# Sets RHCON from RCOR2 user-supplied values or defaults to 1.0.
# DIAM values are const above; RHCON is in coeffs.jl (COMMON /COEFFS/).
# ---------------------------------------------------------------------------
function REGCON()
    for ispc in 1:MAXSP
        RHCON[ispc] = Float32(1.0)
        if LRCOR2 && RCOR2[ispc] > Float32(0.0)
            RHCON[ispc] = RCOR2[ispc]
        end
    end
    return nothing
end
