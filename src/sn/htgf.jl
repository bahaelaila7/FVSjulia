# htgf.jl — SN height growth function (HTGF + HTCONS entry)
# Translated from: sn/htgf.f (337 lines)
#
# HTGF():  compute predicted periodic height increment → HTG[i]
#          Called from TREGRO each cycle.
# HTCONS(): ENTRY point called from RCON to initialize HTCON[] from HCOR2.

# ---------------------------------------------------------------------------
# Species-level relative-height modifier coefficients (DATA arrays in htgf.f)
# ---------------------------------------------------------------------------
const HTGF_RHYXS = Float32[
  0.20,0.05,0.15,0.05,0.05,0.05,0.20,0.05,0.05,0.05,
  0.05,0.10,0.05,0.05,0.10,0.10,0.20,0.15,0.15,0.15,
  0.15,0.20,0.15,0.05,0.05,0.20,0.10,0.05,0.10,0.15,
  0.20,0.20,0.20,0.15,0.05,0.05,0.15,0.05,0.15,0.15,
  0.20,0.05,0.05,0.05,0.05,0.15,0.10,0.15,0.10,0.15,
  0.05,0.15,0.05,0.15,0.05,0.15,0.15,0.15,0.10,0.01,
  0.01,0.05,0.10,0.01,0.10,0.05,0.05,0.15,0.10,0.05,
  0.05,0.05,0.05,0.10,0.10,0.05,0.05,0.10,0.10,0.01,
  0.01,0.05,0.15,0.10,0.15,0.10,0.15,0.10,0.10,0.10]

const HTGF_RHR = Float32[
  20.0,13.0,16.0,13.0,13.0,13.0,20.0,13.0,13.0,
  13.0,13.0,15.0,13.0,13.0,15.0,15.0,20.0,16.0,
  16.0,16.0,16.0,20.0,16.0,13.0,13.0,20.0,15.0,
  13.0,15.0,16.0,20.0,20.0,20.0,16.0,13.0,13.0,
  16.0,13.0,16.0,16.0,20.0,13.0,13.0,13.0,13.0,
  16.0,15.0,16.0,15.0,16.0,13.0,16.0,13.0,16.0,
  13.0,16.0,16.0,16.0,15.0,12.0,12.0,13.0,15.0,
  12.0,15.0,13.0,13.0,16.0,15.0,13.0,13.0,13.0,
  13.0,15.0,15.0,13.0,13.0,15.0,15.0,12.0,12.0,
  13.0,16.0,15.0,16.0,15.0,16.0,15.0,15.0,15.0]

const HTGF_RHB = Float32[
  -1.10,-1.60,-1.20,-1.60,-1.60,-1.60,-1.10,-1.60,-1.60,
  -1.60,-1.60,-1.45,-1.60,-1.60,-1.45,-1.45,-1.10,-1.20,
  -1.20,-1.20,-1.20,-1.10,-1.20,-1.60,-1.60,-1.10,-1.45,
  -1.60,-1.45,-1.20,-1.10,-1.10,-1.10,-1.20,-1.60,-1.60,
  -1.20,-1.60,-1.20,-1.20,-1.10,-1.60,-1.60,-1.60,-1.60,
  -1.20,-1.45,-1.20,-1.45,-1.20,-1.60,-1.20,-1.60,-1.20,
  -1.60,-1.20,-1.20,-1.20,-1.45,-1.60,-1.60,-1.60,-1.45,
  -1.60,-1.45,-1.60,-1.60,-1.20,-1.45,-1.60,-1.60,-1.60,
  -1.60,-1.45,-1.45,-1.60,-1.60,-1.45,-1.45,-1.60,-1.60,
  -1.60,-1.20,-1.45,-1.20,-1.45,-1.20,-1.45,-1.45,-1.45]

# RHM, RHXS, RHK are uniform across all species
const HTGF_RHM  = Float32(1.10)
const HTGF_RHXS = Float32(0.0)
const HTGF_RHK  = Float32(1.0)

# Crown ratio modifier Hoerl constants
const HTGF_CRA = Float32(100.0)
const HTGF_CRB = Float32(3.0)
const HTGF_CRC = Float32(-5.0)

# Reference cycle length (years) used to build regression
const HTGF_REGYR = Float32(5.0)

# ---------------------------------------------------------------------------
# HTGF — compute height increment for each tree this cycle
# ---------------------------------------------------------------------------
function HTGF()
    debug = DBCHK("HTGF", Int32(4))
    if debug
        @printf(io_units[JOSTND], " ENTERING HTGF, CYCLE= %d  BA= %f\n", ICYC, BA)
    end

    scale  = FINT / YR
    scale2 = FINT / HTGF_REGYR

    # Apply user-supplied HT growth multipliers
    MULTS(Int32(2), IY[ICYC], XHMULT)

    for ispc in Int32(1):MAXSP
        i1 = ISCT[ispc, 1]
        if i1 == Int32(0); continue; end
        i2 = ISCT[ispc, 2]
        xht = XHMULT[ispc]
        si  = SITEAR[ispc]

        rhyxs_sp = HTGF_RHYXS[ispc]
        rhr_sp   = HTGF_RHR[ispc]
        rhb_sp   = HTGF_RHB[ispc]

        for i3 in i1:i2
            i = IND1[i3]
            HTG[i] = Float32(0.0)
            if PROB[i] <= Float32(0.0); @goto label_4; end

            hti = HT[i]

            # Mode 0: compute HTMAX AND AGET (tree age from current height HTI).
            # AGET is RETURNED here and must be preserved for the mode-9 call below,
            # which computes the 5-yr increment starting from that age.
            aget  = Ref(Float32(0.0))
            htmax = Ref(Float32(0.0))
            htg1  = Ref(Float32(0.0))
            href  = Ref(hti)
            HTCALC(Int32(0), ispc, aget, href, htmax, htg1, JOSTND, debug)

            if htmax[] - hti <= Float32(1.0)
                if debug
                    @printf(io_units[JOSTND],
                        " HTI>=HTMAX , ABIRTH= %f  XHT=%f  HTCON=%f\n",
                        ABIRTH[i], xht, HTCON[ispc])
                end
                HTG[i] = Float32(0.10)
                HTG[i] = HTG[i] * xht * scale * exp(HTCON[ispc])
                @goto label_4
            end

            # Mode 9: compute 5-year HTG1 starting from AGET (set by the mode-0 call).
            # Do NOT reset aget here — Fortran preserves it (htgf.f: no AGET reset
            # between the mode-0 and mode-9 HTCALC calls).
            htg1[] = Float32(0.0)
            href[]  = hti
            HTCALC(Int32(9), ispc, aget, href, htmax, htg1, JOSTND, debug)

            if debug
                @printf(io_units[JOSTND],
                    " HTGF,MAIN HT CALC, AGET,HTMAX,HTG1= %f %f %f\n",
                    aget[], htmax[], htg1[])
            end

            # Relative height modifier
            relht = Float32(0.0)
            if AVH > Float32(0.0)
                relht = hti / AVH
                if relht > Float32(1.5); relht = Float32(1.5); end
            end

            # Crown ratio modifier (Hoerl's special function)
            hgmdcr = HTGF_CRA * (Float32(ICR[i]) / Float32(100.0))^HTGF_CRB *
                     exp(HTGF_CRC * (Float32(ICR[i]) / Float32(100.0)))
            if hgmdcr > Float32(1.0); hgmdcr = Float32(1.0); end

            # Relative height modifier (generalized Chapman-Richards)
            rhx    = relht
            fctrkx = (HTGF_RHK / rhyxs_sp)^(HTGF_RHM - Float32(1.0)) - Float32(1.0)
            fctrrb = Float32(-1.0) * (rhr_sp / (Float32(1.0) - rhb_sp))
            fctrxb = rhx^(Float32(1.0) - rhb_sp) - HTGF_RHXS^(Float32(1.0) - rhb_sp)
            fctrm  = Float32(-1.0) / (HTGF_RHM - Float32(1.0))

            if debug
                @printf(io_units[JOSTND],
                    " HTGF-HGMDRH FACTORS = %d %f %f %f %f %f\n",
                    ispc, rhx, fctrkx, fctrrb, fctrxb, fctrm)
            end
            hgmdrh = HTGF_RHK * (Float32(1.0) + fctrkx * exp(fctrrb * fctrxb))^fctrm

            # Weighted combined modifier
            wtcr   = Float32(0.25)
            wtrh   = Float32(1.0) - wtcr
            htgmod = wtcr * hgmdcr + wtrh * hgmdrh

            if debug
                @printf(io_units[JOSTND],
                    " IN HTGF, HTGMOD= %f ICR=%d  ABIRTH= %f\n",
                    htgmod, ICR[i], ABIRTH[i])
            end

            if htgmod >= Float32(2.0); htgmod = Float32(2.0); end
            if htgmod <= Float32(0.1); htgmod = Float32(0.1); end

            HTG[i] = htg1[] * htgmod
            if HTG[i] < Float32(0.1); HTG[i] = Float32(0.1); end
            HTG[i] = HTG[i] * xht * scale * exp(HTCON[ispc])

            if debug
                htnew = hti + HTG[i]
                @printf(io_units[JOSTND],
                    " I,ISPC,XHT,HTCON,SCALE,HTG= %d %d %f %f %f %f\n",
                    i, ispc, xht, HTCON[ispc], scale, HTG[i])
                @printf(io_units[JOSTND],
                    " ISPC5= %d  I5= %d  ICYC= %d  FINT= %f\n",
                    ispc, i, ICYC, FINT)
                @printf(io_units[JOSTND],
                    " 9000HTGF,HTG=%8.4f D=%8.4f XHT=%8.4f AGET=%8.4f\n SI =%8.4f HT(I)= %8.4f WK1= %8.4f HTNEW= %8.4f HTGMOD= %8.4f\n RELHT= %8.4f AVH= %8.4f\n HTMAX= %10.3f SCALE= %5.1f SCALE2= %5.1f HGMDCR=%9.3f HGMDRH=%9.3f RHB(ISPC)=%6.2f\n",
                    HTG[i], DBH[i], xht, aget[], si, hti, WK1[i],
                    htnew, htgmod, relht, AVH, htmax[], scale, scale2,
                    hgmdcr, hgmdrh, rhb_sp)
            end

            @label label_4
            temhtg = HTG[i]

            # Size cap
            if HT[i] + HTG[i] > SIZCAP[ispc, 4]
                HTG[i] = SIZCAP[ispc, 4] - HT[i]
                if HTG[i] < Float32(0.1); HTG[i] = Float32(0.1); end
            end

            if !LTRIP; continue; end

            # Fill tripled-record entries
            itfn = ITRN + 2 * i - 1
            HTG[itfn] = temhtg
            if HT[itfn] + HTG[itfn] > SIZCAP[ispc, 4]
                HTG[itfn] = SIZCAP[ispc, 4] - HT[itfn]
                if HTG[itfn] < Float32(0.1); HTG[itfn] = Float32(0.1); end
            end

            HTG[itfn+1] = temhtg
            if HT[itfn+1] + HTG[itfn+1] > SIZCAP[ispc, 4]
                HTG[itfn+1] = SIZCAP[ispc, 4] - HT[itfn+1]
                if HTG[itfn+1] < Float32(0.1); HTG[itfn+1] = Float32(0.1); end
            end

            if debug
                @printf(io_units[JOSTND], " UPPER HTG =%8.4f LOWER HTG =%8.4f\n",
                        HTG[itfn], HTG[itfn+1])
            end
        end
    end
    return nothing
end

# ---------------------------------------------------------------------------
# HTCONS — ENTRY point: initialize HTCON[] from HCOR2 calibration values
# Called from RCON once per stand (after calibration data are known).
# ---------------------------------------------------------------------------
function HTCONS()
    for ispc in Int32(1):MAXSP
        HTCON[ispc] = Float32(0.0)
        if LHCOR2 && HCOR2[ispc] > Float32(0.0)
            HTCON[ispc] = log(HCOR2[ispc])
        end
    end
    return nothing
end
