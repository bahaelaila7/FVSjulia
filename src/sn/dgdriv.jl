# dgdriv.jl — SN diameter growth driver
# Translated from: sn/dgdriv.f (749 lines)
#
# Two modes:
#   LSTART=false: compute cycle DG for all trees from DGF + serial correlation
#   LSTART=true:  calibration pass — compute COR, SIGMA, OLDRN from measured DG

# Prior variance for empirical Bayes correction (from DATA PSIGSQ)
const PSIGSQ_DGDRIV = Float32(0.089827273)   # one value; array entries are all equal

"""
    DGDRIV()

Compute per-tree diameter growth (stored in `DG[1:ITRN]`).
If `LSTART`, run calibration first; otherwise compute increments from `DGF` output.
"""
function DGDRIV()
    debug = DBCHK("DGDRIV", Int32(6))

    if LSTART; @goto label_100; end

    # -------------------------------------------------------------------------
    # Normal growth mode
    # -------------------------------------------------------------------------
    WORK2[1] = Float32(MANAGD)
    MULTS(Int32(7), IY[ICYC], WORK2)
    global MANAGD = Int32(round(WORK2[1]))

    pvmlt = VMLT
    covmlt_r = Ref(COVMLT); vmlt_r = Ref(VMLT)
    AUTCOR(covmlt_r, vmlt_r)
    global COVMLT = covmlt_r[]; global VMLT = vmlt_r[]
    corr = COVMLT / sqrt(VMLT * pvmlt)

    # WK1 ← last cycle DG (for MORTS)
    WK1[1:ITRN] .= DG[1:ITRN]

    DGF(DBH)

    MULTS(Int32(1), IY[ICYC], XDMULT)

    if debug
        @printf(io_units[JOSTND], "\n")
        for v in (SIGMA, XDMULT, BKRAT, COR)
            for val in view(v, 1:min(length(v), MAXSP))
                @printf(io_units[JOSTND], "%11.5f", val)
            end
        end
        @printf(io_units[JOSTND], "\n")
    end

    sfint = Float32(IY[ICYC+1] - IY[1])

    for ispc in Int32(1):MAXSP
        varyp1 = VARDG[ispc] * pvmlt
        evarp1  = (sqrt(Float32(1.0) + Float32(4.0) * varyp1) + Float32(1.0)) / Float32(2.0)
        sig1    = sqrt(log(max(evarp1, Float32(1.0) + eps(Float32))))
        varyp2  = VARDG[ispc] * VMLT
        evarp2  = (sqrt(Float32(1.0) + Float32(4.0) * varyp2) + Float32(1.0)) / Float32(2.0)
        ssigma  = sqrt(log(max(evarp2, Float32(1.0) + eps(Float32))))
        rho     = (sig1 > 0f0 && ssigma > 0f0) ?
                  log(Float32(1.0) + corr * sqrt((evarp1 - Float32(1.0)) * (evarp2 - Float32(1.0)))) /
                  (sig1 * ssigma) : Float32(0.0)
        rhocp   = sqrt(max(Float32(1.0) - rho * rho, Float32(0.0)))
        xdgrow  = log(max(XDMULT[ispc], eps(Float32)))

        if ICYC == Int32(1)
            WCI[ispc]  = Float32(0.5) * COR[ispc]
            DIFH[ispc] = HCOR[ispc] - WCI[ispc]
        end

        i1 = ISCT[ispc, 1]
        if i1 == Int32(0); continue; end
        i2 = ISCT[ispc, 2]

        if LDGCAL[ispc]
            cormlt    = exp(Float32(-0.02773) * sfint)
            COR[ispc] = WCI[ispc] + cormlt * WCI[ispc]
            HCOR[ispc]= WCI[ispc] + cormlt * DIFH[ispc]
            if debug
                @printf(io_units[JOSTND],
                    "FOR SPECIES %2d NEW DGCOR = %7.4f NEW HTCOR = %7.4f ATTENUATION GOAL = %7.4f\n",
                    ispc, COR[ispc], HCOR[ispc], WCI[ispc])
            end
        end

        frl = Float32(0.0); frm = Float32(0.0); fru = Float32(0.0)
        if LTRIP
            frl = FL[ispc] * ssigma * rhocp
            frm = FM[ispc] * ssigma * rhocp
            fru = FU[ispc] * ssigma * rhocp
        end

        for i3 in i1:i2
            i      = IND1[i3]
            d      = DBH[i] * BRATIO(ispc, DBH[i], HT[i])
            dds    = exp(WK2[i] + xdgrow)
            dsq    = d * d
            wki    = sqrt(dsq + dds) - d

            if !LTRIP
                frm_r = Ref(frm)
                DGSCOR(ssigma, frm_r, rho, rhocp, i)
                frm = frm_r[]
                DG[i] = sqrt(dsq + dds * frm) - d
                DG[i] *= MISDGF(i, ispc)
                DG[i] = DGBND(ispc, DBH[i], DG[i])
                if debug
                    @printf(io_units[JOSTND],
                        "IN DGDRIV, I=%4d, ISPC=%3d, DBH=%7.2f, HT=%7.2f, EXP.GR.=%7.4f, PRED.GR.=%7.4f, FRM=%7.4f MISDGF= %7.4f\n",
                        i, ispc, d, HT[i], wki, DG[i], frm, MISDGF(i, ispc))
                end
            else
                itripu = ITRN + Int32(2) * i - Int32(1)
                itripl = itripu + Int32(1)
                rnpar  = OLDRN[i]
                frmt   = frm + corr * OLDRN[i]
                DG[i]  = sqrt(dsq + dds * exp(frmt)) - d
                DG[i]  *= MISDGF(i, ispc)
                OLDRN[i] = frmt
                frmt       = fru + corr * rnpar
                DG[itripu] = sqrt(dsq + dds * exp(frmt)) - d
                DG[itripu] *= MISDGF(i, ispc)
                DBH[itripu]  = DBH[i]
                OLDRN[itripu]= frmt
                frmt       = frl + corr * rnpar
                DG[itripl] = sqrt(dsq + dds * exp(frmt)) - d
                DG[itripl] *= MISDGF(i, ispc)
                DBH[itripl]  = DBH[i]
                OLDRN[itripl]= frmt
                DG[i]      = DGBND(ispc, DBH[i], DG[i])
                DG[itripu] = DGBND(ispc, DBH[i], DG[itripu])
                DG[itripl] = DGBND(ispc, DBH[i], DG[itripl])
                if debug
                    @printf(io_units[JOSTND],
                        "IN DGDRIV, ISPC=%3d, DBH=%7.2f, HT=%7.2f, EXP.GR.=%7.4f, DG(%4d)=%7.4f, FRM=%7.4f\n             DG(%4d)U=%7.4f, FRU=%7.4f, DG(%4d)L=%7.4f, FRL=%7.4f\n",
                        ispc, d, HT[i], wki,
                        i, DG[i], frm,
                        itripu, DG[itripu], fru,
                        itripl, DG[itripl], frl)
                end
            end
        end
    end
    return nothing

    # -------------------------------------------------------------------------
    # Calibration mode (LSTART=true)
    # -------------------------------------------------------------------------
    @label label_100

    if JOCALB > Int32(0)
        rev = "          "
        REVISE(VARACD, rev)
        dat_s = "          "; tim_s = "        "
        GRDTIM(dat_s, tim_s)
        isi = Int32(round(SITEAR[ISISP]))
        @printf(io_units[JOCALB],
            " CALBSTAT %2s      %10s %8s %26s %4s %3d %2d %3d %3d %s\n",
            VARACD, dat_s, tim_s, NPLT, MGMID, KODTYP, ISISP, isi, IAGE, rev)
    end

    covyr_r = Ref(COVYR); vmltyr_r = Ref(VMLTYR)
    AUTCOR(covyr_r, vmltyr_r)
    global COVYR = covyr_r[]; global VMLTYR = vmltyr_r[]
    global VMLT = VMLTYR
    sfint = Float32(0.0)

    if ITRN <= Int32(0); @goto label_115; end

    scale = YR / FINT

    # Convert input DG to inside-bark if IDG=1 or 3
    if IDG != Int32(0) && IDG != Int32(2)
        for i in Int32(1):ITRN
            ispc = ISP[i]
            DG[i] *= BRATIO(ispc, DBH[i], HT[i])
        end
    end

    DGF(WK3)   # WK3 = old DBH; loads WK2 with predicted ln(DDS)

    @label label_115

    stdrat = ones(Float32, MAXSP)
    cortem = ones(Float32, MAXSP)
    wci_v  = zeros(Float32, MAXSP)
    numcal = zeros(Int32, MAXSP)

    for i in Int32(1):MAXSP
        WCI[i] = Float32(0.0)
    end

    for ispc in Int32(1):MAXSP
        cornew = Float32(1.0)
        SIGMA[ispc] = SIGMAR[ispc]
        i1 = ISCT[ispc, 1]
        if i1 == Int32(0) || IFINT == Int32(0)
            @goto label_195_cal
        end
        i2   = ISCT[ispc, 2]
        irefi= IREF[ispc]
        dev  = Float32(0.0); devsq = Float32(0.0)
        n    = Int32(0)
        xnob = ATTEN[ispc]
        fn   = Float32(0.0)
        spopn= Float32(0.0); spopx = Float32(0.0)
        snp  = Float32(0.0); snx = Float32(0.0); sny = Float32(0.0)
        snxy = Float32(0.0); snxx= Float32(0.0); snyy= Float32(0.0)

        # Min/max DBH scan
        dn = Float32(999.0); dx = Float32(0.0)
        pn = Float32(0.0);   px = Float32(0.0)
        for i3 in i1:i2
            i = IND1[i3]
            if WK3[i] < Float32(3.0) || DG[i] <= Float32(0.0); continue; end
            if WK3[i] < dn; dn = WK3[i]; pn = exp(WK2[i]); end
            if WK3[i] > dx; dx = WK3[i]; px = exp(WK2[i]); end
        end

        for i3 in i1:i2
            i    = IND1[i3]
            OLDRN[i] = Float32(0.0)
            p    = PROB[i]
            bark = BRATIO(ispc, DBH[i], HT[i])
            if WK3[i] < dn || WK3[i] > dx; continue; end
            edds = exp(WK2[i])
            spopn += p
            spopx += edds * p
            if DG[i] <= Float32(0.0); continue; end
            if debug
                @printf(io_units[JOSTND],
                    "IN DGDRIV 157, I ,DG(I), BARK, WK3(I), WK2(I), SCALE=\n%5d%10.3f%10.3f%10.3f%10.3f%10.3f\n",
                    i, DG[i], bark, WK3[i], WK2[i], scale)
            end
            term = DG[i] * (Float32(2.0) * bark * WK3[i] + DG[i]) * scale
            if term == Float32(0.0); @goto label_159_cal; end
            fn    += Float32(1.0)
            reslog = log(term) - WK2[i]
            if DGSD >= Float32(1.0); OLDRN[i] = reslog; end
            dev   += reslog
            devsq += reslog * reslog
            @label label_159_cal
            if !LDGCAL[ispc]; continue; end
            snp  += p
            snx  += p * edds
            sny  += p * reslog
            snxx += p * edds * edds
            snxy += p * reslog * edds
            snyy += p * reslog * reslog
            n    += Int32(1)
        end

        if debug
            @printf(io_units[JOSTND],
                "\nSUMS FOR SPECIES %2d:  SPOPN=%10.2f;  SPOPX=%10.2f;  FN=%6.1f;  SNP=%10.2f;  SNX=%10.2f;\n                      SNY=%10.2f;  SNXX=%10.2f;  SNXY=%10.2f;  SNYY=%10.2f\n",
                ispc, spopn, spopx, fn, snp, snx, sny, snxx, snxy, snyy)
        end

        wc = Float32(0.0)
        if fn < FNMIN || !LDGCAL[ispc]; @goto label_190_cal; end

        bpopx = spopx / spopn
        bnx   = snx / snp
        bny   = sny / snp
        csnxy = snxy - bnx * bny * snp
        csnxx = snxx - bnx * bnx * snp
        if csnxx < Float32(0.0)
            @printf(io_units[JOSTND],
                "\n\nPOOR SELECTION OF GROWTH SAMPLE TREES DETECTED FOR SPECIES %3s. LARGE TREE DG CALIBRATION ABORTED FOR THIS SPECIES.\n",
                JSP[ispc])
            @goto label_190_cal
        end

        slop   = csnxy / csnxx
        ratio  = bny
        sdpred = sqrt(csnxx / (snp * (Float32(1.0) - Float32(1.0) / fn)))
        dist   = abs(bpopx - bnx) / sdpred
        if debug
            @printf(io_units[JOSTND], "SLOP RATIO DIST=  %10.2f  %10.2f  %10.2f\n", slop, ratio, dist)
        end
        regcor = bny + (bpopx - bnx) * slop

        if dist > Float32(3.0)
            cornew = ratio
        elseif dist <= Float32(1.0)
            cornew = regcor
        else
            cornew = ratio * (dist / Float32(2.0)) + regcor * (Float32(1.0) - dist / Float32(2.0))
        end
        COR[ispc] = cornew

        if DGSD >= Float32(1.0)
            rx = bny + (px - bnx) * slop
            rn = bny + (pn - bnx) * slop
            for i3 in i1:i2
                i = IND1[i3]
                if OLDRN[i] != Float32(0.0); continue; end
                edds     = exp(WK2[i])
                OLDRN[i] = bny + (edds - bnx) * slop
                if WK3[i] < dn; OLDRN[i] = rn; end
                if WK3[i] > dx; OLDRN[i] = rx; end
            end
        end

        sigmr1    = SIGMAR[ispc]^2
        svar      = devsq - (dev * dev) / fn
        SIGMA[ispc] = sqrt((svar + xnob * sigmr1) / (fn + xnob))
        svar_ratio  = svar / (fn - Float32(1.0))
        stdrat[irefi] = sqrt(svar_ratio / sigmr1)

        if !LDGCAL[ispc]; @goto label_194_cal; end
        cori  = COR[ispc]
        svar_v= svar_ratio / fn
        pvar  = PSIGSQ_DGDRIV
        temp  = cori * cori / pvar
        if temp > Float32(72.0); temp = Float32(72.0); end
        wc = Float32(1.0) / (Float32(1.0) + exp(Float32(-0.5) * temp) * sqrt(svar_v / pvar))
        COR[ispc] = wc * cori
        if debug
            @printf(io_units[JOSTND],
                "IN DGDRIV 9009,ISPC,COR(ISPC),SVAR,PVAR,TEMP,WC,CORI=\n%5d%10.3f%10.3f%10.3f%10.3f%10.3f%10.3f\n",
                ispc, COR[ispc], svar_v, pvar, temp, wc, cori)
        end
        @goto label_193_cal

        @label label_190_cal
        if DGSD < Float32(1.0); @goto label_193_cal; end
        for i3 in i1:i2
            i = IND1[i3]
            z = Float32(0.0)
            while true
                z = BACHLO(Float32(0.0), SIGMA[ispc])
                if z <= DGSD * SIGMA[ispc]; break; end
            end
            OLDRN[i] = z
        end

        @label label_193_cal
        wci_v[irefi]  = wc
        cortem[irefi] = exp(COR[ispc])

        # Trap out-of-range calibration
        if cortem[irefi] < Float32(0.0821) || cortem[irefi] > Float32(12.1825)
            ERRGRO(true, Int32(27))
            @printf(io_units[JOSTND],
                "                           LARGE TREE DG: SPECIES = %2d (%3s) CALCULATED CALIBRATION VALUE = %8.2f\n",
                ispc, JSP[ispc], cortem[irefi])
            cortem[irefi] = Float32(1.0)
            COR[ispc]     = Float32(0.0)
        end

        @label label_194_cal
        numcal[irefi] = n

        @label label_195_cal
        vtemp       = exp(SIGMA[ispc]^2)
        VARDG[ispc] = (vtemp - Float32(1.0)) * vtemp / VMLT
        FU[ispc]    = Float32( 1.271)
        FM[ispc]    = Float32(-0.14228)
        FL[ispc]    = Float32(-1.549)
    end

    # Clamp OLDRN
    for i in Int32(1):ITRN
        ispc = ISP[i]
        lim  = DGSD * SIGMA[ispc]
        if OLDRN[i] >  lim; OLDRN[i] =  lim; end
        if OLDRN[i] < -lim; OLDRN[i] = -lim; end
    end

    if IFINT == Int32(0)
        @printf(io_units[JOSTND],
            "\nNO CORRECTION TERMS ARE CALCULATED WHEN GROWTH MEASUREMENT PERIOD IS ZERO.\n")
        @goto label_215_cal
    end
    if ITRN == Int32(0); return nothing; end

    @printf(io_units[JOSTND],
        "\nNUMBER OF RECORDS AVAILABLE FOR SCALING\nTHE DIAMETER INCREMENT MODEL")
    for i in 1:NUMSP; @printf(io_units[JOSTND], "%5d ", numcal[i]); end

    @printf(io_units[JOSTND],
        "\nRATIO OF STANDARD ERRORS\n(INPUT DBH GROWTH DATA : MODEL)")
    for i in 1:NUMSP; @printf(io_units[JOSTND], "%5.2f ", stdrat[i]); end

    @printf(io_units[JOSTND],
        "\nWEIGHT GIVEN TO THE INPUT GROWTH DATA WHEN\nDBH GROWTH MODEL SCALE FACTORS WERE COMPUTED")
    for i in 1:NUMSP; @printf(io_units[JOSTND], "%5.2f ", wci_v[i]); end

    @printf(io_units[JOSTND],
        "\nINITIAL SCALE FACTORS FOR THE\nDBH INCREMENT MODEL")
    for i in 1:NUMSP; @printf(io_units[JOSTND], "%5.2f ", cortem[i]); end
    @printf(io_units[JOSTND], "\n")

    DBSCALIB(Int32(1), cortem, numcal, stdrat)

    if JOCALB > Int32(0)
        kout = Int32(0)
        for k in 1:MAXSP
            if cortem[k] != Float32(1.0) || numcal[k] >= Int32(round(FNMIN))
                ispec = MAXSP; spec = NSP[MAXSP,1][1:2]
                for kk in 1:MAXSP
                    if k != IREF[kk]; continue; end
                    ispec = kk; spec = NSP[kk,1][1:2]; break
                end
                @printf(io_units[JOCALB], " CAL: LD %2d %2s %4d %6.3f %6.3f %6.3f\n",
                        ispec, spec, numcal[k], cortem[k], stdrat[k], wci_v[k])
                kout += Int32(1)
            end
        end
        if kout == Int32(0)
            @printf(io_units[JOCALB], " NO LD VALUES COMPUTED\n")
        end
    end
    @goto label_215_cal

    @label label_215_cal
    DGF(WK3)
    global ICL6 = IFINT
    scale_back = Float32(1.0) / scale

    for i in Int32(1):ITRN
        ispc = ISP[i]
        bark = BRATIO(ispc, DBH[i], HT[i])
        d    = WK3[i] * bark
        if DG[i] > Float32(0.0) && HT[i] > Float32(4.5)
            if IDG < Int32(2) && DG[i] > DBH[i] * bark
                @printf(io_units[JOSTND],
                    "\nNOTE: FOR TREE %4d DG (%5.2f) IS GREATER THAN IB DBH (%5.2f)\n      DG RESET TO INSIDE BARK DBH.\n",
                    i, DG[i], DBH[i] * bark)
                DG[i] = DBH[i] * bark
            end
            WORK1[i] = DG[i]
        else
            if HT[i] <= Float32(4.5)
                DG[i] = Float32(0.0)
            else
                DG[i] = sqrt(d * d + exp(WK2[i] + OLDRN[i]) * scale_back) - d
                if DG[i] > d; DG[i] = d; end
                DG[i] = DGBND(ispc, DBH[i], DG[i])
            end
            WORK1[i] = Float32(0.0)
        end
    end

    return nothing
end

# ---------------------------------------------------------------------------
# Stubs for helpers called from DGDRIV (replaced by real implementations)
# ---------------------------------------------------------------------------
# AUTCOR → base/autcor.jl  MULTS → base/mults.jl  DGF → sn/dgf.jl
# REVISE → base/revise.jl  GRDTIM → base/grdtim.jl
# DGSCOR → base/dgscor.jl
MISDGF(i, ispc)                         = Float32(1.0)
# DBSCALIB — implemented in extensions/dbs/dbsqlite.jl
# DGBND implemented in base/dgbnd.jl
# BACHLO implemented in base/bachlo.jl
