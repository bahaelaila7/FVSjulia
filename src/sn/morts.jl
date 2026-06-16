# morts.jl — SN mortality model (MORTS + MORCON entry)
# Translated from: sn/morts.f (1069 lines)
#
# MORTS(): SDI-based + background periodic mortality → WK2[i] (trees/acre dying)
#   Activity codes: 94 = MORTMULT, 97 = FIXMORT
# MORCON(): ENTRY — initialize CEPMRT, SLPMRT, TPAMRT

# ---------------------------------------------------------------------------
# Background mortality constants (DATA arrays)
# ---------------------------------------------------------------------------
const MORTS_PMSC = Float32[
  5.1676998, 9.6942997, 5.1676998, 5.5876999, 5.5876999,
  5.5876999, 5.1676998, 5.5876999, 5.5876999, 5.5876999,
  5.5876999, 5.5876999, 5.5876999, 5.5876999, 5.5876999,
  5.5876999, 5.1676998, 5.1676998, 5.1676998, 5.1676998,
  5.1676998, 5.1676998, 5.1676998, 5.9617000, 5.1676998,
  5.1676998, 5.9617000, 5.9617000, 5.9617000, 5.1676998,
  5.1676998, 5.1676998, 5.1676998, 5.1676998, 5.9617000,
  5.9617000, 5.1676998, 5.9617000, 5.1676998, 5.1676998,
  5.1676998, 5.9617000, 5.9617000, 5.9617000, 5.9617000,
  5.1676998, 5.9617000, 5.1676998, 5.9617000, 5.1676998,
  5.9617000, 5.1676998, 5.9617000, 5.1676998, 5.9617000,
  5.1676998, 5.1676998, 5.1676998, 5.9617000, 5.9617000,
  5.9617000, 5.9617000, 5.9617000, 5.9617000, 5.9617000,
  5.9617000, 5.9617000, 5.1676998, 5.9617000, 5.9617000,
  5.9617000, 5.9617000, 5.9617000, 5.9617000, 5.9617000,
  5.9617000, 5.9617000, 5.9617000, 5.9617000, 5.1676998,
  5.1676998, 5.1676998, 5.1676998, 5.1676998, 5.1676998,
  5.1676998, 5.1676998, 5.5876999, 5.9617000, 5.9617000]

const MORTS_PMD = Float32[
 -0.0077681, -0.0127328, -0.0077681, -0.0053480, -0.0053480,
 -0.0053480, -0.0077681, -0.0053480, -0.0053480, -0.0053480,
 -0.0053480, -0.0053480, -0.0053480, -0.0053480, -0.0053480,
 -0.0053480, -0.0077681, -0.0077681, -0.0077681, -0.0077681,
 -0.0077681, -0.0077681, -0.0077681, -0.0340128, -0.0077681,
 -0.0077681, -0.0340128, -0.0340128, -0.0340128, -0.0077681,
 -0.0077681, -0.0077681, -0.0077681, -0.0077681, -0.0340128,
 -0.0340128, -0.0077681, -0.0340128, -0.0077681, -0.0077681,
 -0.0077681, -0.0340128, -0.0340128, -0.0340128, -0.0340128,
 -0.0077681, -0.0340128, -0.0077681, -0.0340128, -0.0077681,
 -0.0340128, -0.0077681, -0.0340128, -0.0077681, -0.0340128,
 -0.0077681, -0.0077681, -0.0077681, -0.0340128, -0.0340128,
 -0.0340128, -0.0340128, -0.0340128, -0.0340128, -0.0340128,
 -0.0340128, -0.0340128, -0.0077681, -0.0340128, -0.0340128,
 -0.0340128, -0.0340128, -0.0340128, -0.0340128, -0.0340128,
 -0.0340128, -0.0340128, -0.0340128, -0.0340128, -0.0077681,
 -0.0077681, -0.0077681, -0.0077681, -0.0077681, -0.0077681,
 -0.0077681, -0.0077681, -0.0053480, -0.0340128, -0.0340128]

# ---------------------------------------------------------------------------
# helper: test if species `isp` belongs to group `igrp` from ISPGRP
# ---------------------------------------------------------------------------
function _morts_in_grp(isp::Int32, ispcc::Int32)::Bool
    if ispcc == Int32(0); return true; end
    if ispcc == isp;      return true; end
    if ispcc < Int32(0)
        igrp = -ispcc
        iulim = ISPGRP[igrp, 1] + Int32(1)
        for ig in Int32(2):iulim
            if isp == ISPGRP[igrp, ig]; return true; end
        end
    end
    return false
end

# ---------------------------------------------------------------------------
# MORTS — compute periodic mortality for all trees
# ---------------------------------------------------------------------------
function MORTS()
    myacts = Int32[94, 97]
    debug  = DBCHK("MORTS", Int32(5))
    if debug
        @printf(io_units[JOSTND], "ENTERING SUBROUTINE MORTS  CYCLE =%4d\n", ICYC)
    end

    treeit = Float32(0.0)
    knt    = Int32(0)

    # ---------------------------------------------------------------------------
    # Process MORTMULT keyword (activity 94)
    # ---------------------------------------------------------------------------
    ntodo = OPFIND(Int32(1), Int32[myacts[1]])
    if ntodo > Int32(0)
        prm = zeros(Float32, 6)
        for i in Int32(1):ntodo
            idate_r = Ref(Int32(0)); iactk_r = Ref(Int32(0)); np_r = Ref(Int32(0))
            OPGET(i, Int32(4), idate_r, iactk_r, np_r, prm)
            OPDONE(i, IY[ICYC])
            ispcc = Int32(trunc(prm[1]))
            if ispcc != Int32(0)
                XMMULT[ispcc] = prm[2]
                XMDIA1[ispcc] = prm[3]
                XMDIA2[ispcc] = prm[4]
            else
                for j in Int32(1):MAXSP
                    XMMULT[j] = prm[2]
                    XMDIA1[j] = prm[3]
                    XMDIA2[j] = prm[4]
                end
            end
        end
    end

    if debug
        @printf(io_units[JOSTND], "IN MORTS 9010 ICYC,RMSQD= %5d%10.2f\n", ICYC, RMSQD)
    end

    if RMSQD == Float32(0.0)
        global CEPMRT = Float32(0.0)
        global SLPMRT = Float32(0.0)
    end

    if PMSDIL > Float32(1.0); global PMSDIL = PMSDIL / Float32(100.0); end
    if PMSDIU > Float32(1.0); global PMSDIU = PMSDIU / Float32(100.0); end

    ipass  = Int32(0)
    sumkil = Float32(0.0)

    # ---------------------------------------------------------------------------
    # Compute quadratic mean diameter at start (DQ0) and end (DQ10) of cycle
    # ---------------------------------------------------------------------------
    t        = Float32(0.0)
    dq0      = Float32(0.0)
    sdq0     = Float32(0.0)
    sd2sq    = Float32(0.0)
    sumdr0   = Float32(0.0)
    sumdr10  = Float32(0.0)
    dr0      = Float32(0.0)
    dr10     = Float32(0.0)

    for ispc in Int32(1):MAXSP
        i1 = ISCT[ispc, 1]
        if i1 <= Int32(0); continue; end
        i2 = ISCT[ispc, 2]
        for i3 in i1:i2
            i = IND1[i3]
            p = PROB[i]; is = ISP[i]; d = DBH[i]
            WK2[i] = Float32(0.0)
            if LZEIDE && d < DBHZEIDE; continue; end
            if !LZEIDE && d < DBHSTAGE; continue; end
            bark = BRATIO(is, d, HT[i])
            g    = (DG[i] / bark) * (FINT / Float32(5.0))
            ciobds = Float32(2.0) * d * g + g * g
            sd2sq  = sd2sq  + p * (d * d + ciobds)
            sdq0   = sdq0   + p * d^2
            if LZEIDE
                sumdr10 = sumdr10 + p * (d + g)^Float32(1.605)
                sumdr0  = sumdr0  + p * d^Float32(1.605)
            end
            t = t + p
        end
    end

    if debug
        @printf(io_units[JOSTND], "SDQ0,SD2SQ,SUMDR0,SUMDR10,T= %f %f %f %f %f\n",
                sdq0, sd2sq, sumdr0, sumdr10, t)
    end

    if ICYC > Int32(1) && abs(t - TPAMRT) > Float32(1.0)
        global CEPMRT = Float32(0.0)
        global SLPMRT = Float32(0.0)
        if debug
            @printf(io_units[JOSTND], "RESETTING SLOPE,INTERCEPT T,TPAMRT= %f %f\n", t, TPAMRT)
        end
    end

    if t < Float32(1.0); @goto label_45; end

    dq0  = sqrt(sdq0  / t)
    dq10 = sqrt(sd2sq / t)
    if LZEIDE
        dr0  = (sumdr0  / t)^(Float32(1.0) / Float32(1.605))
        dr10 = (sumdr10 / t)^(Float32(1.0) / Float32(1.605))
    end
    if debug
        @printf(io_units[JOSTND], "IN MORTS, T,ISISP,LZEIDE= %f %d %s\n", t, ISISP, string(LZEIDE))
    end

    dia0 = LZEIDE ? dr0  : dq0
    d10  = LZEIDE ? dr10 : dq10
    tn10 = Float32(0.0)

    @label label_10

    deltba = Float32(0.005454154) * d10 * d10 * t - BA

    if debug
        @printf(io_units[JOSTND], "IN MORTS  DQ0 = %8.2f DQ10 = %10.2f T = %8.2f SD2SQ = %10.2f DR0= %10.2f DR10= %10.2f\n",
                dq0, dq10, t, sd2sq, dr0, dr10)
    end

    if dia0 < Float32(0.3)
        d10  = Float32(0.3) + d10 - dia0
        dia0 = Float32(0.3)
        if debug
            @printf(io_units[JOSTND], "RESETTING DIA0,D10= %f %f\n", dia0, d10)
        end
    end

    # ---------------------------------------------------------------------------
    # Call SDICAL to get SDIMAX, then compute CONST = SDIMAX/0.02483133
    # ---------------------------------------------------------------------------
    SDICAL(Int32(0), SDIMAX)
    const_v = SDIMAX / Float32(0.02483133)

    if debug
        @printf(io_units[JOSTND], "SDIMAX,CONST,BAMAX= %f %f %f\n", SDIMAX, const_v, BAMAX)
    end

    if SDIMAX < Float32(5.0)
        tn10 = Float32(0.0)
        @goto label_271
    end

    ipath = Int32(0)
    if t > Float32(35000.0); t = Float32(35000.0); end

    tmd0  = const_v * dia0^Float32(-1.605)
    if tmd0 > Float32(35000.0); tmd0 = Float32(35000.0); end
    t85d0 = tmd0 * PMSDIU
    t55d0 = PMSDIL * tmd0

    if debug
        @printf(io_units[JOSTND], "TMD0,PMSDIU,PMSDIL,T85D0,T55D0= %f %f %f %f %f\n",
                tmd0, PMSDIU, PMSDIL, t85d0, t55d0)
    end

    tmd10  = const_v * d10^Float32(-1.605)
    if tmd10 > Float32(35000.0); tmd10 = Float32(35000.0); end
    t85d10 = tmd10 * PMSDIU
    t55d10 = PMSDIL * tmd10

    if debug
        @printf(io_units[JOSTND], "TMD10,PMSDIU,PMSDIL,T85D10,T55D10= %f %f %f %f %f\n",
                tmd10, PMSDIU, PMSDIL, t85d10, t55d10)
        @printf(io_units[JOSTND], "IN MORTS ICYC,MAX SDI =%5d%10.1f\n", ICYC, SDIMAX)
    end

    if SLPMSB != Float32(0.0)
        global CEPMSB = log(const_v * QMDMSB^Float32(-1.605)) - SLPMSB * log(QMDMSB)
    end

    if debug
        @printf(io_units[JOSTND], "MATURE STAND BOUNDARY SETTINGS, QMDMSB,CEPMSB,SLPMSB,D10= %f %f %f %f\n",
                QMDMSB, CEPMSB, SLPMSB, d10)
    end

    if t > t85d0
        tn10 = t85d10
        @goto label_270
    end

    @label label_210

    if t > t55d0
        # Between 55% and 85% — linear function (iterative or direct)
        if abs(t85d0 - t) <= Float32(5.0)
            tn10 = t85d10
            @goto label_270
        end

        knt   = Int32(1)
        treeit = t + Float32(0.1) * t
        ipath  = Int32(1)
        d55m   = Float32(0.0); t55m = Float32(0.0); d85m = Float32(0.0)
        slp    = Float32(0.0); cept = Float32(0.0)

        @label label_220

        tem_v = (ipath == Int32(2)) ? t : treeit
        if debug
            @printf(io_units[JOSTND], "MORTS 220,TEM,CONST %f %f\n", tem_v, const_v)
        end
        d55m = (log(tem_v) - log(PMSDIL * const_v)) / Float32(-1.605)
        t55m = log(tem_v)
        d85m = d55m * Float32(1.25)
        if debug
            @printf(io_units[JOSTND], "D55M,T55M,D85M= %f %f %f\n", d55m, t55m, d85m)
        end

        @label label_221
        if d85m > Float32(5.0);   d85m = Float32(5.0);   end
        if d85m < Float32(0.125); d85m = Float32(0.125); end
        t85m = log(const_v * exp(d85m)^Float32(-1.605) * PMSDIU)
        slp  = (t85m - t55m) / (d85m - d55m)
        if debug
            @printf(io_units[JOSTND], "D55M,D85M,T55M,T85M,SLP= %f %f %f %f %f\n",
                    d55m, d85m, t55m, t85m, slp)
        end
        if slp > Float32(-0.5) && d85m < Float32(5.0)
            d85m += Float32(0.1)
            @goto label_221
        end

        cept = t55m - slp * d55m

        if t > t55d0
            if debug
                @printf(io_units[JOSTND], "MORTS,359,DIA0 %f\n", dia0)
            end
            tprime = cept + slp * log(dia0)
            diff   = t - exp(tprime)
            if debug
                @printf(io_units[JOSTND],
                    "MORTS 9050%9.3f%9.3f%9.3f%9.3f%9.3f%9.3f%9.3f%9.3f%9.3f%9.3f%9.3f%9.3f%9.3f%4d\n",
                    dia0, d10, t, treeit, tem_v, d55m, t55m, d85m, t85m, slp, cept, tprime, diff, knt)
            end
            if !(diff <= Float32(5.0) && diff >= Float32(-5.0))
                treeit = treeit + Float32(0.5) * diff
                knt += Int32(1)
                if knt <= Int32(100); @goto label_220; end
            end
        end

        @label label_230
        if SLPMRT == Float32(0.0); global SLPMRT = slp; end
        if CEPMRT == Float32(0.0); global CEPMRT = cept; end
        if debug
            @printf(io_units[JOSTND], "D10,CEPMRT,SLPMRT= %f %f %f\n", d10, CEPMRT, SLPMRT)
        end
        tn10 = exp(CEPMRT + SLPMRT * log(d10))
        if tn10 >= t85d10; tn10 = t85d10; end
        @goto label_270
    end

    @label label_240
    if t <= t55d10
        tn10 = t
    else
        ipath = Int32(2)
        @goto label_220
    end

    @label label_270
    if debug
        @printf(io_units[JOSTND], "MORTS 9060%10.3f   %10.3f   %10.3f   %10.3f   %10.3f   %10.3f   %4d\n",
                dia0, d10, t, tn10, treeit, const_v, knt)
    end

    @label label_271
    if tn10 > t; tn10 = t; end
    if tn10 < Float32(0.1); tn10 = Float32(0.0); end

    rn_v = t > Float32(0.0) ?
        Float32(1.0) - (Float32(1.0) - ((t - tn10) / t))^(Float32(1.0) / FINT) :
        Float32(0.0)

    if debug
        @printf(io_units[JOSTND], "TESTMORTS, RN=%f T=%f TN10=%f\n", rn_v, t, tn10)
    end

    # ---------------------------------------------------------------------------
    # Per-tree mortality rate loop
    # ---------------------------------------------------------------------------
    for ispc in Int32(1):MAXSP
        i1 = ISCT[ispc, 1]
        if i1 <= Int32(0); continue; end
        i2 = ISCT[ispc, 2]
        xmort = XMMULT[ispc]
        d1    = XMDIA1[ispc]
        d2    = XMDIA2[ispc]
        b0    = MORTS_PMSC[ispc]
        b1    = MORTS_PMD[ispc]

        for i3 in i1:i2
            i = IND1[i3]
            p = PROB[i]
            WK2[i]  = Float32(0.0)
            wki     = Float32(0.0)
            if p <= Float32(0.0); continue; end
            d = DBH[i]

            # Background mortality (Hamilton logistic)
            ri = Float32(1.0) / (Float32(1.0) + exp(b0 + b1 * d))

            # SDI mortality rate check
            tem_v2 = const_v * d10^Float32(-1.605)
            if tem_v2 > Float32(35000.0); tem_v2 = Float32(35000.0); end
            tem_v2 *= PMSDIL

            rip = (t <= tem_v2 || rn_v <= Float32(0.0)) ? ri : rn_v
            if rip > Float32(1.0); rip = Float32(1.0); end

            x = Float32(1.0)
            if d >= d1 && d < d2; x = xmort; end
            if rip == rn_v; x = Float32(1.0); end

            wki = p * (Float32(1.0) - (Float32(1.0) - rip)^FINT) * x
            if wki > p; wki = p; end

            if debug
                @printf(io_units[JOSTND],
                    "MORTALITY RATE ESTIMATES FOR TREE %4d, DBH = %6.2f\n RI = %7.5f RN = %7.5f RIP = %7.5f\n",
                    i, d, ri, rn_v, rip)
            end
            WK2[i] = wki

            if debug
                pres_v = p - wki
                vlos_v = wki * CFV[i] / FINT
                @printf(io_units[JOSTND],
                    "IN MORTS, I=%4d,  ISPC=%3d,  DBH=%7.2f,  INIT PROB=%9.3f,  TREES DYING=%9.3f  RES PROB=%9.3f,  VOL LOST=%9.3f\n",
                    i, ispc, d, p, wki, pres_v, vlos_v)
            end
        end

        if debug
            @printf(io_units[JOSTND], "IN MORTS,  ISPC=%3d           B0=%8.6f,  B1=%8.6f\n",
                    ispc, b0, b1)
        end
    end

    # ---------------------------------------------------------------------------
    # Distribute mortality (VARMRT) if not killing all trees
    # ---------------------------------------------------------------------------
    sumtre = Float32(0.0)
    rip_last = (t > Float32(0.0) && tn10 > Float32(0.0)) ? rn_v : Float32(0.0)
    if rip_last == rn_v; sumtre = t - tn10; end
    if sumtre < Float32(0.0); sumtre = Float32(0.0); end
    if tn10 >= Float32(0.1)
        VARMRT(sumtre, debug, sumkil)
    end

    # ---------------------------------------------------------------------------
    # Verify QMD estimate; iterate if needed
    # ---------------------------------------------------------------------------
    tn       = Float32(0.0)
    sd2sqn   = Float32(0.0)
    sumdr10n = Float32(0.0)
    dr10n    = Float32(0.0)
    ipass += Int32(1)

    for i in Int32(1):ITRN
        p  = PROB[i] - WK2[i]
        is = ISP[i]; d = DBH[i]
        if LZEIDE  && d < DBHZEIDE;  continue; end
        if !LZEIDE && d < DBHSTAGE; continue; end
        bark = BRATIO(is, d, HT[i])
        g    = (DG[i] / bark) * (FINT / Float32(5.0))
        ciobds = Float32(2.0) * d * g + g * g
        sd2sqn += p * (d * d + ciobds)
        if LZEIDE; sumdr10n += p * (d + g)^Float32(1.605); end
        tn += p
    end

    if tn == Float32(0.0); @goto label_35; end

    dq10n = sqrt(sd2sqn / tn)
    if LZEIDE; dr10n = (sumdr10n / tn)^(Float32(1.0) / Float32(1.605)); end

    if debug
        @printf(io_units[JOSTND], "MORTS CHECK DIA. IPASS,DQ10,DR10 DQ10N,DR10N= %d %f %f %f %f\n",
                ipass, dq10, dr10, dq10n, dr10n)
    end

    d10n = LZEIDE ? dr10n : dq10n

    if ipass < Int32(10)
        diff2 = abs(d10 - d10n)
        if diff2 > Float32(0.1)
            if d10n <= dia0
                ipath = Int32(0)
                @goto label_35
            end
            d10 = d10n
            @goto label_10
        end
    end

    @label label_35

    # ---------------------------------------------------------------------------
    # Alternate (mature stand boundary) mortality
    # ---------------------------------------------------------------------------
    tmmsb  = Float32(0.0)
    t85msb = Float32(0.0)
    if d10 > QMDMSB && tn > Float32(0.0)
        tmmsb  = exp(CEPMSB + SLPMSB * log(d10))
        t85msb = tmmsb * PMSDIU
        tmore  = tn - t85msb
        if tmore < Float32(0.0); tmore = Float32(0.0); end

        if debug
            @printf(io_units[JOSTND],
                "ALTERNATE MORTALITY LOGIC, D10,TN,QMDMSB,CEPMSB,SLPMSB,TMMSB,T85MSB,PMSDIU,TMORE= \n%f %f %f %f %f %f %f %f %f\n",
                d10, tn, QMDMSB, CEPMSB, SLPMSB, tmmsb, t85msb, PMSDIU, tmore)
        end

        # Compute TPA in MSB DBH class
        tpacls = Float32(0.0)
        for i in Int32(1):ITRN
            bark   = BRATIO(ISP[i], DBH[i], HT[i])
            dbhend = DBH[i] + (DG[i] / bark) * (FINT / Float32(5.0))
            if dbhend >= DLOMSB && dbhend < DHIMSB
                tpacls += PROB[i] - WK2[i]
            end
        end
        if debug
            @printf(io_units[JOSTND], "ALT MORT LOGIC DLOMSB,DHIMSB,TPACLS = %f %f %f\n",
                    DLOMSB, DHIMSB, tpacls)
        end

        if tmore > tpacls
            @printf(io_units[JOSTND],
                "\n%s\nWARNING: FOR ALTERNATE MORTALITY, TPA IN DBH CLASS OF %8.1f TREES/ACRE IS LESS THAN THE ADDITIONAL MORTALITY TPA\n%9s OF %8.1f TREES/ACRE.  ALTERNATE MORTALITY CANCELLED.\n%s\n",
                repeat("***************", 2), tpacls, " ", tmore, repeat("***************", 2))
            @goto label_353
        end

        temeff = EFFMSB
        if MFLMSB == Int32(3)
            temeff = tmore / tpacls
        else
            if tpacls * temeff < tmore
                temeff = tmore / tpacls
                @printf(io_units[JOSTND],
                    "\n%s\nWARNING: FOR ALTERNATE MORTALITY, MORTALITY EFFICIENCY OF %8.4f IS TOO LOW TO REACH THE ADDITIONAL MORTALITY LEVEL. \n%9s MORTALITY EFFICIENCY RESET TO %8.4f FOR FURTHER PROCESSING.\n%s\n",
                    repeat("***************", 2), EFFMSB, " ", temeff, repeat("***************", 2))
            end
        end
        MSBMRT(temeff, tmore, DLOMSB, DHIMSB, MFLMSB, debug)
        ipath = Int32(0)
    end

    @label label_353

    # ---------------------------------------------------------------------------
    # Size cap mortality
    # ---------------------------------------------------------------------------
    for i in Int32(1):ITRN
        is    = ISP[i]; d = DBH[i]; p = PROB[i]
        bark  = BRATIO(is, d, HT[i])
        g     = (DG[i] / bark) * (FINT / Float32(5.0))
        idmflg = Int32(trunc(SIZCAP[is, 3]))
        if (d + g) >= SIZCAP[is, 1] && idmflg != Int32(1)
            WK2[i] = max(WK2[i], p * SIZCAP[is, 2] * FINT / Float32(5.0))
            if WK2[i] > p; WK2[i] = p; end
            if debug
                @printf(io_units[JOSTND],
                    "SIZE CAP RESTRICTION IMPOSED, I,IS,D,P,SIZCAP 1-3,WK2 = %d %d %f %f %f %f %f %f\n",
                    i, is, d, p, SIZCAP[is,1], SIZCAP[is,2], SIZCAP[is,3], WK2[i])
            end
        end
    end

    # ---------------------------------------------------------------------------
    # BAMAX enforcement: adjust WK2 until residual BA ≤ BAMAX
    # ---------------------------------------------------------------------------
    knt2 = Int32(0)

    @label label_9001
    tnew   = Float32(0.0)
    banew  = Float32(0.0)
    qmdnew = Float32(0.0)
    badead = Float32(0.0)

    for i in Int32(1):ITRN
        p  = PROB[i] - WK2[i]; d = DBH[i]
        bark = BRATIO(ISP[i], d, HT[i])
        g    = (DG[i] / bark) * (FINT / Float32(5.0))
        if debug
            @printf(io_units[JOSTND], "I,DG,BARK,FINT,G= %d %f %f %f %f\n",
                    i, DG[i], bark, FINT, g)
        end
        tnew   += p
        banew  += Float32(0.0054542) * (d + g)^2 * p
        badead += Float32(0.0054542) * (d + g)^2 * WK2[i]
        qmdnew += (d + g)^2 * p
        if debug
            @printf(io_units[JOSTND], "I,P,D,G,TNEW,BANEW,QMDNEW,BADEAD= %d %f %f %f %f %f %f %f\n",
                    i, p, d, g, tnew, banew, qmdnew, badead)
        end
    end
    qmdnew = tnew > Float32(0.0) ? sqrt(qmdnew / tnew) : Float32(0.0)

    if debug
        @printf(io_units[JOSTND], "ICYC,BANEW,BAMAX,TNEW,QMDNEW,KNT2= %d %f %f %f %f %d\n",
                ICYC, banew, BAMAX, tnew, qmdnew, knt2)
    end

    if (banew - BAMAX) > Float32(1.0)
        adjfac = (banew - BAMAX) / badead
        if debug
            @printf(io_units[JOSTND], "BANEW,BAMAX,ADJFAC= %f %f %f\n", banew, BAMAX, adjfac)
        end
        tnew = Float32(0.0)
        for i in Int32(1):ITRN
            p   = PROB[i]
            wki = WK2[i] * (Float32(1.0) + adjfac)
            if wki > p; wki = p; end
            WK2[i] = wki
            if debug
                @printf(io_units[JOSTND], "ADJUSTING FOR BAMAX I,P,WKI= %d %f %f\n", i, p, wki)
                pres_v = p - wki; vlos_v = wki * CFV[i] / FINT
                @printf(io_units[JOSTND],
                    "IN MORTS, I=%4d,  ISPC=%3d,  DBH=%7.2f,  INIT PROB=%9.3f,  TREES DYING=%9.3f  RES PROB=%9.3f,  VOL LOST=%9.3f\n",
                    i, Int32(0), d10, p, wki, pres_v, vlos_v)
            end
            tnew += p - wki
        end
        knt2 += Int32(1)
        if knt2 < Int32(100); @goto label_9001; end
        ipath = Int32(0)
        if debug
            @printf(io_units[JOSTND], "AFTER BA ADJUSTMENT RESIDUAL TPA = %f\n", tnew)
        end
    end
    global TPAMRT = tnew

    @label label_45

    # ---------------------------------------------------------------------------
    # FIXMORT keyword processing (activity 97)
    # ---------------------------------------------------------------------------
    ntodo2 = OPFIND(Int32(1), Int32[myacts[2]])
    if ntodo2 > Int32(0)
        prm2 = zeros(Float32, 6)
        for itodo in Int32(1):ntodo2
            idate_r = Ref(Int32(0)); iactk_r = Ref(Int32(0)); np_r = Ref(Int32(0))
            OPGET(itodo, Int32(6), idate_r, iactk_r, np_r, prm2)
            if iactk_r[] < Int32(0); continue; end
            OPDONE(itodo, IY[ICYC])
            ispcc = Int32(trunc(prm2[1]))
            if np_r[] <= Int32(4)
                if prm2[2] > Float32(1.0); prm2[2] = Float32(1.0); end
            end
            if prm2[3] < Float32(0.0); prm2[3] = Float32(0.0); end
            if prm2[4] <= Float32(0.0); prm2[4] = Float32(999.0); end

            ip = Int32(1)
            if np_r[] > Int32(4)
                if prm2[5] < Float32(3.0)
                    if prm2[2] > Float32(1.0); prm2[2] = Float32(1.0); end
                    if prm2[2] < Float32(0.0); prm2[2] = Float32(0.0); end
                end
                if     prm2[5] == Float32(1.0); ip = Int32(2)
                elseif prm2[5] == Float32(2.0); ip = Int32(3)
                elseif prm2[5] == Float32(3.0); ip = Int32(4)
                end
            end

            kpoint = Int32(0); kbig = Int32(0)
            if prm2[6] > Float32(0.0)
                p6 = Int32(trunc(prm2[6]))
                if     p6 == Int32(1);  kpoint = Int32(1)
                elseif p6 == Int32(10); kbig   = Int32(1)
                elseif p6 == Int32(11); kpoint = Int32(1); kbig = Int32(1)
                elseif p6 == Int32(20); kbig   = Int32(2)
                elseif p6 == Int32(21); kpoint = Int32(1); kbig = Int32(2)
                end
            end

            if ITRN <= Int32(0); continue; end

            if kbig >= Int32(1) || (kpoint == Int32(1) && IPTINV > Int32(1))
                # Pre-pass: gather xmore (total additional kill budget) and zero WK2 for replace/mult
                xmore  = Float32(0.0)
                credit = Float32(0.0)
                for i in Int32(1):ITRN
                    if !(_morts_in_grp(ISP[i], ispcc) && prm2[3] <= DBH[i] && DBH[i] < prm2[4])
                        continue
                    end
                    if     ip == Int32(1); xmore += PROB[i] * prm2[2]; WK2[i] = Float32(0.0)
                    elseif ip == Int32(2); xmore += max(Float32(0.0), PROB[i] - WK2[i]) * prm2[2]
                    elseif ip == Int32(3)
                        tmp = max(WK2[i], PROB[i] * prm2[2])
                        if tmp > WK2[i]; xmore += tmp - WK2[i]; end
                    elseif ip == Int32(4); xmore += WK2[i] * prm2[2]; WK2[i] = Float32(0.0)
                    end
                end

                if debug
                    @printf(io_units[JOSTND], "KPOINT,KBIG,ITRN,XMORE= %d %d %d %f\n",
                            kpoint, kbig, ITRN, xmore)
                end

                # Sort scratch by DBH±G for size concentration
                for i in Int32(1):ITRN
                    IWORK1[i] = IND1[i]
                    bark_i = BRATIO(ISP[i], DBH[i], HT[i])
                    enddbh = DBH[i] + DG[i] / bark_i
                    WORK3[i] = (kbig == Int32(1)) ? -enddbh : enddbh
                end
                RDPSRT(ITRN, WORK3, IWORK1, false)

                if kbig >= Int32(1) && kpoint == Int32(0)
                    # Size-only concentration
                    for i in Int32(1):ITRN
                        ix = IWORK1[i]
                        if !(_morts_in_grp(ISP[ix], ispcc) && prm2[3] <= DBH[ix] && DBH[ix] < prm2[4])
                            continue
                        end
                        tmp = credit + PROB[ix] - WK2[ix]
                        if tmp <= xmore || abs(tmp - xmore) < Float32(1e-4)
                            credit += PROB[ix] - WK2[ix]; WK2[ix] = PROB[ix]
                        else
                            WK2[ix] += xmore - credit; credit = xmore; break
                        end
                    end

                elseif kpoint == Int32(1) && kbig == Int32(0)
                    # Point-only concentration
                    for j in Int32(1):IPTINV
                        for i in Int32(1):ITRN
                            if ITRE[i] != j; continue; end
                            if !(_morts_in_grp(ISP[i], ispcc) && prm2[3] <= DBH[i] && DBH[i] < prm2[4])
                                continue
                            end
                            tmp = credit + PROB[i] - WK2[i]
                            if tmp <= xmore || abs(tmp - xmore) < Float32(1e-4)
                                credit += PROB[i] - WK2[i]; WK2[i] = PROB[i]
                            else
                                WK2[i] += xmore - credit; credit = xmore; @goto label_295
                            end
                        end
                    end

                else
                    # Size on points (point has priority)
                    for j in Int32(1):IPTINV
                        for i in Int32(1):ITRN
                            ix = IWORK1[i]
                            if ITRE[ix] != j; continue; end
                            if !(_morts_in_grp(ISP[ix], ispcc) && prm2[3] <= DBH[ix] && DBH[ix] < prm2[4])
                                continue
                            end
                            tmp = credit + PROB[ix] - WK2[ix]
                            if tmp <= xmore || abs(tmp - xmore) < Float32(1e-4)
                                credit += PROB[ix] - WK2[ix]; WK2[ix] = PROB[ix]
                            else
                                WK2[ix] += xmore - credit; credit = xmore; @goto label_295
                            end
                        end
                    end
                end
            else
                # Normal FIXMORT (no point/size concentration)
                for i in Int32(1):ITRN
                    if !(_morts_in_grp(ISP[i], ispcc) && prm2[3] <= DBH[i] && DBH[i] < prm2[4])
                        continue
                    end
                    if     ip == Int32(1)
                        WK2[i] = PROB[i] * prm2[2]
                    elseif ip == Int32(2)
                        WK2[i] = WK2[i] + max(Float32(0.0), PROB[i] - WK2[i]) * prm2[2]
                    elseif ip == Int32(3)
                        WK2[i] = max(WK2[i], PROB[i] * prm2[2])
                    elseif ip == Int32(4)
                        WK2[i] = min(PROB[i], WK2[i] * prm2[2])
                    end
                end
            end

            @label label_295
            if debug
                wk2str = join([@sprintf("%f", WK2[ig]) for ig in 1:ITRN], ",")
                @printf(io_units[JOSTND], "ITODO,WK2= %d  %s\n", itodo, wk2str)
            end
        end
    end
    return nothing
end

# ---------------------------------------------------------------------------
# MORCON — ENTRY: initialize mortality model constants (called from RCON)
# ---------------------------------------------------------------------------
function MORCON()
    global CEPMRT = Float32(0.0)
    global SLPMRT = Float32(0.0)
    global TPAMRT = Float32(0.0)
    return nothing
end

# ---------------------------------------------------------------------------
# Stubs for subroutines called by MORTS
# ---------------------------------------------------------------------------
VARMRT(sumtre, debug, sumkil) = nothing
MSBMRT(temeff, tmore, dlo, dhi, mfl, debug) = nothing
SDICAL(mode, sdimax_ref)      = nothing
