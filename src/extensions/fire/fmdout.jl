# fire/fmdout.f — Fuels and debris output report (589 lines)
# Three sections: all-fuels (LPRINT), down wood volume (LPRINT2), down wood cover (LPRINT3).
# CWD(3,J,K,5) = summed pile categories (unpiled+piled); CWD2B[idc,isz+1,itm] (0-based isz).
# CROWNW[i,1]=foliage (ISZ=0); CROWNW[i,j+1] for j=1:3; OLDCRW same.
# Accumulates BIOLIVE/BIOSNAG/BIODDW/BIOFLR/BIOSHRB/BIOREM/BIOCON; resets TONRMS/H/C.
# Called from: FMMAIN

function FMDOUT(iyr::Integer)
    debug = DBCHK("FMDOUT", 6, ICYC)
    if debug
        @printf(get(io_units, Int32(JOSTND), stdout),
            " ENTERING FMDOUT CYCLE = %2d\n", ICYC)
    end

    local jrout_ref = Ref(Int32(0))
    GETLUN(jrout_ref)
    local jrout = jrout_ref[]

    if debug
        @printf(get(io_units, Int32(JOSTND), stdout),
            " FMDOUT: IFLALB=%5d IFLALE=%5d IDFLAL=%5d JROUT=%3d NSNAG=%5d\n",
            IFLALB, IFLALE, IDFLAL, jrout, NSNAG)
    end

    # Determine which reports to print this year
    local lprint  = true
    if !(iyr == 0 && iyr == Int(IFLALE))
        if iyr < Int(IFLALB) || iyr > Int(IFLALE); lprint  = false; end
    end

    local lprint2 = true
    if !(iyr == 0 && iyr == Int(IDWRPE))
        if iyr < Int(IDWRPB) || iyr > Int(IDWRPE); lprint2 = false; end
    end

    local lprint3 = true
    if !(iyr == 0 && iyr == Int(IDWCVE))
        if iyr < Int(IDWCVB) || iyr > Int(IDWCVE); lprint3 = false; end
    end

    # Zero summed pile categories (index 3 = unpiled+piled total, category 5)
    for i in 1:Int(MXFLCL)
        CWD[3, i, 1, 5] = 0.0f0
        CWD[3, i, 2, 5] = 0.0f0
    end

    # Accumulate unpiled (i=1) and piled (i=2) categories into summed (i=3)
    for i in 1:2
        for j in 1:Int(MXFLCL)
            for k in 1:2
                for l in 1:4
                    CWD[3, j, k, 5] += CWD[i, j, k, l]
                end
            end
        end
    end

    # Surface fuel totals
    local small2  = 0.0f0
    local large2  = 0.0f0
    local large12 = 0.0f0
    for isz in 1:3
        local jsz = isz + 3
        local ksz = isz + 6
        small2 += CWD[3, isz, 1, 5] + CWD[3, isz, 2, 5]
        large2 += CWD[3, jsz, 1, 5] + CWD[3, jsz, 2, 5] +
                  CWD[3, ksz, 1, 5] + CWD[3, ksz, 2, 5]
    end
    large12 = CWD[3,6,1,5]+CWD[3,6,2,5]+CWD[3,7,1,5]+CWD[3,7,2,5] +
              CWD[3,8,1,5]+CWD[3,8,2,5]+CWD[3,9,1,5]+CWD[3,9,2,5]

    local totduf = CWD[3,11,1,5] + CWD[3,11,2,5]
    local totlit = CWD[3,10,1,5] + CWD[3,10,2,5]
    local totsur = FLIVE[1] + FLIVE[2] + small2 + large2 + totduf + totlit

    # Snag volume totals (small ≤3" and large >3")
    local totsng = zeros(Float32, 2)
    for i in 1:Int(NSNAG)
        if (DENIH[i] + DENIS[i]) > 0.0f0
            local snvis = 0.0f0
            local snvih = 0.0f0
            if DENIH[i] > 0.0f0
                local snvih_ref = Ref(Float32(0))
                FMSVOL(i, HTIH[i], snvih_ref, debug, Int32(JOSTND))
                snvih = snvih_ref[] * DENIH[i]
            end
            if DENIS[i] > 0.0f0
                local snvis_ref = Ref(Float32(0))
                FMSVOL(i, HTIS[i], snvis_ref, debug, Int32(JOSTND))
                snvis = snvis_ref[] * DENIS[i]
            end
            local ksp = Int(SPS[i])
            if DBHS[i] <= 3.0f0
                totsng[1] += (snvis + snvih) * V2T[ksp]
            else
                totsng[2] += (snvis + snvih) * V2T[ksp]
            end
            if debug
                @printf(get(io_units, Int32(JOSTND), stdout),
                    " FMDOUT: I=%5d DENIH,HTIH,SNVIH=%10.3f%10.3f%10.3f DENIS,HTIS,SNVIS=%10.3f%10.3f%10.3f KSP=%3d\n V2T=%6.3f TOTSNG(1&2)=%10.4f%10.4f\n",
                    i, DENIH[i], HTIH[i], snvih, DENIS[i], HTIS[i], snvis, ksp,
                    V2T[ksp], totsng[1], totsng[2])
            end
        end
    end

    # Add pending snag crown debris (CWD2B/CWD2B2) to snag totals
    # ISZ=0:3 → Julia CWD2B[idc, isz+1, itm]; ISZ+3 → CWD2B[idc, isz+4, itm]
    for isz in 0:3
        for idc in 1:4
            for itm in 1:Int(TFMAX)
                totsng[1] += P2T * (CWD2B[idc, isz+1, itm] + CWD2B2[idc, isz+1, itm])
                if isz > 0 && isz < 3
                    totsng[2] += P2T * (CWD2B[idc, isz+4, itm] + CWD2B2[idc, isz+4, itm])
                end
                if debug
                    @printf(get(io_units, Int32(JOSTND), stdout),
                        " FMDOUT: ISZ,IDC,ITM=%3d%3d%3d CWD2B=%10.2f CWD2B2=%10.2f TOTSNG(1&2)=%10.4f%10.4f\n",
                        isz, idc, itm, CWD2B[idc, isz+1, itm], CWD2B2[idc, isz+1, itm],
                        totsng[1], totsng[2])
                end
            end
        end
    end

    # Landscape area distribution (JLOUT(1) > 0 check; SPLAAR not called)
    if JLOUT[1] > Int32(0)
        local acres = 0.0f0
        local iton  = Int(small2 / 10) + 1
        if iton > 4; iton = 4; end
        FUAREA[1, iton] += acres

        iton = Int(large2 / 10) + 1
        if iton > 4; iton = 4; end
        FUAREA[2, iton] += acres

        iton = Int((small2 + large2) / 10) + 1
        if iton > 4; iton = 4; end
        FUAREA[3, iton] += acres

        iton = Int((CWD[3,11,1,5] + CWD[3,11,2,5]) / 10) + 1
        if iton > 4; iton = 4; end
        FUAREA[4, iton] += acres

        iton = Int((totsng[1] + totsng[2]) / 10) + 1
        if iton > 4; iton = 4; end
        FUAREA[5, iton] += acres
    end

    # Live tree biomass totals
    local totliv = zeros(Float32, 2)
    local totfol = 0.0f0
    local totcon = 0.0f0

    for i in 1:Int(ITRN)
        # CROWNW[i,1] = foliage (Fortran CROWNW(I,0))
        totfol += CROWNW[i, 1] * FMPROB[i] * P2T

        # Crown sizes j=1:3 → CROWNW[i, j+1]; j+3 → CROWNW[i, j+4]; OLDCRW same
        for j in 1:3
            totliv[1] += (CROWNW[i, j+1] + OLDCRW[i, j+1]) * P2T * FMPROB[i]
            if j < 3
                totliv[2] += P2T * FMPROB[i] *
                              (CROWNW[i, j+4] + OLDCRW[i, j+4])
            end
        end

        # Live tree volume via FMSVL2
        local js      = Int(ISP[i])
        local d       = DBH[i]
        local h       = HT[i]
        local crwnrto = Int(ICR[i])
        local vt_ref  = Ref(Float32(0))
        FMSVL2(js, d, h, -1.0f0, vt_ref, crwnrto, "L", false, debug, Int32(JOSTND))
        local vt = vt_ref[]

        if debug
            @printf(get(io_units, Int32(JOSTND), stdout),
                " FMDOUT (LIVE): I=%5d FMPROB=%10.3f ISP=%3d D,H,VT=%10.3f%10.3f%10.3f\n",
                i, FMPROB[i], js, d, h, vt)
        end

        if d <= 3.0f0
            totliv[1] += FMPROB[i] * vt * V2T[js]
        else
            totliv[2] += FMPROB[i] * vt * V2T[js]
        end
    end

    local totstd = totliv[1] + totliv[2] + totfol + totsng[1] + totsng[2]
    local totful = totstd + totsur

    # Total consumed
    for ii in 1:Int(MXFLCL)
        totcon += BURNED[3, ii]
    end
    totcon += BURNLV[1] + BURNLV[2] + BURNCR

    # Volume removed (salvage + harvest + CWD transfer), in tons
    local tonrem = TONRMS + TONRMH + TONRMC

    # Accumulate into carbon report pools
    global BIOLIVE    = totfol + totliv[1] + totliv[2]
    global BIOSNAG    = totsng[1] + totsng[2]
    global BIODDW     = small2 + large2
    global BIOFLR     = totlit + totduf
    global BIOSHRB    = FLIVE[1] + FLIVE[2]
    global BIOREM[1] += TONRMS + TONRMC
    global BIOREM[2]  = tonrem
    global BIOCON[1]  = BURNED[3,10] + BURNED[3,11]
    global BIOCON[2]  = totcon - BIOCON[1]

    global TONRMS = 0.0f0
    global TONRMH = 0.0f0
    global TONRMC = 0.0f0

    # Down wood volume and cover arrays — clear first
    fill!(CWDVOL, 0.0f0)
    fill!(CWDCOV, 0.0f0)

    # Density constants: 1=soft (SG 0.3 = 18.72 lbs/cuft), 2=hard (SG 0.4 = 24.96 lbs/cuft)
    local cwdden = Float32[18.72f0 24.96f0; 18.72f0 24.96f0; 18.72f0 24.96f0; 18.72f0 24.96f0]

    # Compute CWDVOL for unpiled (i=1) and piled (i=2); sizes j=1:9
    for i in 1:2
        for j in 1:9
            for k in 1:2
                for l in 1:4
                    CWDVOL[i, j, k, l] = CWD[i, j, k, l] * 2000.0f0 / cwdden[l, k]
                end
            end
        end
    end

    # Total: i=3 = sum of i=1,2
    for i in 1:2
        for j in 1:9
            for k in 1:2
                for l in 1:4
                    CWDVOL[3, j, k, l] += CWDVOL[i, j, k, l]
                end
            end
        end
    end

    # Column 5 = total across decay classes 1:4
    for i in 1:3
        for j in 1:9
            for k in 1:2
                for l in 1:4
                    CWDVOL[i, j, k, 5] += CWDVOL[i, j, k, l]
                end
            end
        end
    end

    # Row 10 = total across size classes 1:9
    for i in 1:3
        for j in 1:9
            for k in 1:2
                for l in 1:5
                    CWDVOL[i, 10, k, l] += CWDVOL[i, j, k, l]
                end
            end
        end
    end

    # Cover equations (power-law) for i=3 only, sizes 4:9, decay total (l=5)
    for j in 1:9
        for k in 1:2
            local v = CWDVOL[3, j, k, 5]
            local cv = if     j <= 3; 0.0f0
                       elseif j == 4; 0.0166f0 * v^0.8715f0
                       elseif j == 5; 0.0092f0 * v^0.8795f0
                       elseif j == 6; 0.0063f0 * v^0.8728f0
                       elseif j == 7; 0.0069f0 * v^0.8134f0
                       elseif j == 8; 0.0033f0 * v^0.8617f0
                       else;          0.0949f0 * v^0.5f0      # j==9
                       end
            CWDCOV[3, j, k, 5] = cv
            CWDCOV[3, 10, k, 5] += cv
        end
    end

    # ── Section 1: all-fuels report ──────────────────────────────────────────
    if !lprint; @goto label_750; end

    if debug
        @printf(get(io_units, Int32(JOSTND), stdout),
            " FMDOUT: DBSFUELS- TOTLIT,TOTDUF,SMALL2,LARGE2,...\n")
        @printf(get(io_units, Int32(JOSTND), stdout),
            " %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %d %d %d %d %d\n",
            totlit, totduf, small2, large2,
            CWD[3,4,1,5]+CWD[3,4,2,5], CWD[3,5,1,5]+CWD[3,5,2,5],
            large12, FLIVE[1], FLIVE[2], totsur,
            totsng[1], totsng[2], totfol, totliv[1], totliv[2],
            totstd, totful, totcon, tonrem)
    end

    local dbskode = Ref(Int32(1))
    DBSFUELS(iyr, NPLT, totlit, totduf, small2, large2,
             CWD[3,4,1,5]+CWD[3,4,2,5], CWD[3,5,1,5]+CWD[3,5,2,5],
             large12, FLIVE[1], FLIVE[2], totsur,
             totsng[1], totsng[2], totfol, totliv[1],
             round(Int32, totliv[2]), round(Int32, totstd),
             round(Int32, totful), round(Int32, totcon), round(Int32, tonrem),
             dbskode)
    if debug
        @printf(get(io_units, Int32(JOSTND), stdout), " FMDOUT: AFTER DBSFUELS\n")
    end

    if dbskode[] == Int32(0); @goto label_750; end

    global IFAPAS += Int32(1)
    local io = get(io_units, jrout, stdout)
    if Int(IFAPAS) == 1
        @printf(io, "\n%6d \n\n%6d %s\n", IDFLAL, IDFLAL, "-"^122)
        @printf(io, "%6d %42s******  FIRE MODEL VERSION 1.0 ******\n", IDFLAL, "")
        @printf(io, "%6d %52sALL FUELS REPORT (BASED ON STOCKABLE AREA)\n", IDFLAL, "")
        @printf(io, "%6d  STAND ID: %-26s    MGMT ID: %s\n", IDFLAL, NPLT, MGMID)
        @printf(io, "%6d %s\n", IDFLAL, "-"^122)
        @printf(io, "%6d %52sESTIMATED FUEL LOADINGS\n", IDFLAL, "")
        @printf(io, "%6d %22sSURFACE FUEL (TONS/ACRE) %26sSTANDING WOOD (TONS/ACRE)\n",
                IDFLAL, "", "")
        @printf(io, "%6d%7s%s  %s\n", IDFLAL, "", "-"^59, "-"^35)
        @printf(io, "%6d %21sDEAD FUEL %21sLIVE%15sDEAD%12sLIVE\n",
                IDFLAL, "", "", "", "")
        @printf(io, "%6d %5s%s--  ---------- SURF   -----------   ---------------        TOTAL TOTAL BIOMASS\n",
                IDFLAL, "", "-"^39)
        @printf(io, "%6d  YEAR LITT.  DUFF  0-3\"   >3\"  3-6\" 6-12\"  >12\"  HERB SHRUB TOTAL   0-3\"   >3\"   FOL  0-3\"   >3\" TOTAL BIOMASS CONS REMOVED\n",
                IDFLAL)
        @printf(io, "%6d %s\n", IDFLAL, "-"^122)
    end

    @printf(io, " %5d  %4d %5.2f %5.1f %5.1f %5.1f %5.1f %5.1f %5.1f %5.2f %5.2f %5.1f %6.2f %5.1f %5.1f %5.1f %5d %5d %5d %6d %6d\n",
            IDFLAL, iyr, totlit, totduf, small2, large2,
            CWD[3,4,1,5]+CWD[3,4,2,5], CWD[3,5,1,5]+CWD[3,5,2,5],
            large12, FLIVE[1], FLIVE[2], totsur,
            totsng[1], totsng[2], totfol, totliv[1],
            round(Int32, totliv[2]), round(Int32, totstd),
            round(Int32, totful), round(Int32, totcon), round(Int32, tonrem))

    @label label_750

    # ── Section 2: down wood volume report ───────────────────────────────────
    if !lprint2; @goto label_850; end

    local v1 = zeros(Float32, 16)
    v1[ 1] = CWDVOL[3,1,2,5]+CWDVOL[3,2,2,5]+CWDVOL[3,3,2,5]
    v1[ 2] = CWDVOL[3,4,2,5]
    v1[ 3] = CWDVOL[3,5,2,5]
    v1[ 4] = CWDVOL[3,6,2,5]
    v1[ 5] = CWDVOL[3,7,2,5]
    v1[ 6] = CWDVOL[3,8,2,5]
    v1[ 7] = CWDVOL[3,9,2,5]
    v1[ 8] = CWDVOL[3,10,2,5]
    v1[ 9] = CWDVOL[3,1,1,5]+CWDVOL[3,2,1,5]+CWDVOL[3,3,1,5]
    v1[10] = CWDVOL[3,4,1,5]
    v1[11] = CWDVOL[3,5,1,5]
    v1[12] = CWDVOL[3,6,1,5]
    v1[13] = CWDVOL[3,7,1,5]
    v1[14] = CWDVOL[3,8,1,5]
    v1[15] = CWDVOL[3,9,1,5]
    v1[16] = CWDVOL[3,10,1,5]

    local dbskode2 = Ref(Int32(1))
    DBSFMDWVOL(iyr, NPLT, v1, Int32(16), dbskode2)
    if dbskode2[] == Int32(0); @goto label_850; end

    global IDWPAS += Int32(1)
    local io2 = get(io_units, jrout, stdout)
    if Int(IDWPAS) == 1
        @printf(io2, "\n%6d \n\n%6d %s\n", IDDWRP, IDDWRP, "-"^134)
        @printf(io2, "%6d %42s******  FIRE MODEL VERSION 1.0 ******\n", IDDWRP, "")
        @printf(io2, "%6d %46sDOWN DEAD WOOD VOLUME REPORT (BASED ON STOCKABLE AREA)\n", IDDWRP, "")
        @printf(io2, "%6d  STAND ID: %-26s    MGMT ID: %s\n", IDDWRP, NPLT, MGMID)
        @printf(io2, "%6d %s\n", IDDWRP, "-"^134)
        @printf(io2, "%6d %30sESTIMATED DOWN WOOD VOLUME (CUFT/ACRE) BY SIZE CLASS (INCHES)\n", IDDWRP, "")
        @printf(io2, "%6d %34sHARD %61sSOFT\n", IDDWRP, "", "")
        @printf(io2, "%6d%8s%s    %s\n", IDDWRP, "", "-"^62, "-"^62)
        @printf(io2, "%6d  YEAR    0-3    3-6   6-12   12-20   20-35   35-50     >=50      TOT       0-3    3-6   6-12   12-20   20-35   35-50     >=50      TOT \n",
                IDDWRP)
        @printf(io2, "%6d %s\n", IDDWRP, "-"^134)
    end

    @printf(io2, " %5d  %4d %6d %6d %6d %7d %7d %7d %8d %8d    %6d %6d %6d %7d %7d %7d %8d %8d\n",
            IDDWRP, iyr,
            round(Int32, v1[1]), round(Int32, v1[2]), round(Int32, v1[3]),
            round(Int32, v1[4]), round(Int32, v1[5]), round(Int32, v1[6]),
            round(Int32, v1[7]), round(Int32, v1[8]),
            round(Int32, v1[9]), round(Int32, v1[10]), round(Int32, v1[11]),
            round(Int32, v1[12]), round(Int32, v1[13]), round(Int32, v1[14]),
            round(Int32, v1[15]), round(Int32, v1[16]))

    @label label_850

    # ── Section 3: down wood cover report ────────────────────────────────────
    if !lprint3; return nothing; end

    local v2 = zeros(Float32, 14)
    v2[ 1] = CWDCOV[3,4,2,5]
    v2[ 2] = CWDCOV[3,5,2,5]
    v2[ 3] = CWDCOV[3,6,2,5]
    v2[ 4] = CWDCOV[3,7,2,5]
    v2[ 5] = CWDCOV[3,8,2,5]
    v2[ 6] = CWDCOV[3,9,2,5]
    v2[ 7] = CWDCOV[3,10,2,5]
    v2[ 8] = CWDCOV[3,4,1,5]
    v2[ 9] = CWDCOV[3,5,1,5]
    v2[10] = CWDCOV[3,6,1,5]
    v2[11] = CWDCOV[3,7,1,5]
    v2[12] = CWDCOV[3,8,1,5]
    v2[13] = CWDCOV[3,9,1,5]
    v2[14] = CWDCOV[3,10,1,5]

    local dbskode3 = Ref(Int32(1))
    DBSFMDWCOV(iyr, NPLT, v2, Int32(14), dbskode3)
    if dbskode3[] == Int32(0); return nothing; end

    global IDCPAS += Int32(1)
    local io3 = get(io_units, jrout, stdout)
    if Int(IDCPAS) == 1
        @printf(io3, "\n%6d \n\n%6d %s\n", IDDWCV, IDDWCV, "-"^122)
        @printf(io3, "%6d %42s******  FIRE MODEL VERSION 1.0 ******\n", IDDWCV, "")
        @printf(io3, "%6d %46sDOWN DEAD WOOD COVER REPORT (BASED ON STOCKABLE AREA)\n", IDDWCV, "")
        @printf(io3, "%6d  STAND ID: %-26s    MGMT ID: %s\n", IDDWCV, NPLT, MGMID)
        @printf(io3, "%6d %s\n", IDDWCV, "-"^122)
        @printf(io3, "%6d %30sESTIMATED DOWN WOOD PERCENT COVER (%%) BY SIZE CLASS (INCHES)\n", IDDWCV, "")
        @printf(io3, "%6d %31sHARD %53sSOFT\n", IDDWCV, "", "")
        @printf(io3, "%6d%8s%s  %s\n", IDDWCV, "", "-"^56, "-"^58)
        @printf(io3, "%6d  YEAR    3-6    6-12   12-20   20-35   35-50    >=50     TOT       3-6    6-12   12-20   20-35   35-50    >=50     TOT \n",
                IDDWCV)
        @printf(io3, "%6d %s\n", IDDWCV, "-"^122)
    end

    @printf(io3, " %5d  %4d %6.1f  %6.1f  %6.1f  %6.1f  %6.1f  %6.1f  %6.1f  %6.1f  %6.1f  %6.1f  %6.1f  %6.1f  %6.1f  %6.1f\n",
            IDDWCV, iyr,
            v2[1], v2[2], v2[3], v2[4], v2[5], v2[6], v2[7],
            v2[8], v2[9], v2[10], v2[11], v2[12], v2[13], v2[14])
    return nothing
end
