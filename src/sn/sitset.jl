# sn/sitset.f — SITSET: load site index and volume specification defaults
# Translated from: bin/FVSsn_buildDir/sitset.f (879 lines)
#
# Computes a site index (SITEAR[i]) for every species not already set by keyword,
# using the Donnelly (1958) master-group transformation from the site-species SI.
# Also sets SDIDEF, volume merchantability specs (DBHMIN/TOPD/BFMIND/BFTOPD/
# SCFMIND/SCFTOPD), volume equation numbers (VEQNNB/VEQNNC), and HT-DBH
# coefficients (HT1/HT2).

function SITSET()
    # ── local DATA arrays ────────────────────────────────────────────────────
    sdicon = Float32[
        655, 354, 412, 499, 490, 385, 490, 332, 398, 398,
        310, 529, 480, 499, 692, 623, 518, 371, 344, 421,
        590, 371, 371, 400, 350, 375, 276, 492, 420, 422,
        257, 147, 364, 414, 408, 423, 414, 338, 492, 430,
        155, 283, 283, 430, 478, 492, 415, 492, 492, 492,
        422, 277, 726, 430, 704, 304, 164, 492, 499, 648,
        520, 384, 361, 315, 342, 405, 326, 387, 384, 326,
        417, 336, 365, 417, 414, 342, 311, 370, 410, 343,
        447, 492, 526, 282, 263, 282, 227, 354, 492, 421]

    # official FIA site species in the sn species list (43 entries)
    isnsis = Int32[
         5,  6, 11, 17, 64, 35, 47, 75, 78, 15,
        16, 44, 59, 76, 45,  8, 12, 13,  2,  1,
         3,  7,  4, 14, 34, 61, 65, 87, 74, 10,
        20, 22, 24, 25, 33, 60, 62, 63, 66, 69,
        71, 73, 83]

    # map from official site species to master group
    isngrp = Int32[
        1, 1, 1, 1, 2, 2, 2, 2, 2, 3,
        3, 3, 3, 3, 3, 4, 4, 4, 5, 5,
        5, 5, 5, 5, 6, 6, 6, 6, 7, 8,
        9, 9, 9, 9, 9, 9, 9, 9, 9, 9,
        9, 9, 9]

    # map from species index to master group (MAPSI, length = MAXSP)
    mapsi = Int32[
        5, 5, 5, 5, 1, 1, 5, 4, 9, 8,
        1, 4, 4, 5, 3, 3, 1, 9, 9, 9,
        9, 9, 9, 9, 9, 9, 9, 9, 9, 9,
        9, 9, 9, 6, 2, 9, 9, 9, 9, 9,
        9, 9, 9, 3, 3, 9, 2, 9, 9, 9,
        9, 9, 9, 9, 9, 9, 9, 9, 3, 9,
        6, 9, 9, 2, 6, 9, 9, 9, 9, 9,
        9, 9, 9, 7, 2, 3, 9, 2, 9, 9,
        9, 9, 9, 9, 9, 9, 6, 5, 9, 9]

    # master group representative species (group 1..9 → species index)
    mgsisp = Int32[5, 64, 45, 12, 14, 65, 74, 10, 63]

    simin = Float32[
        15, 15, 15, 35, 35, 35, 45, 45, 35, 25,
        35, 40, 40, 35, 30, 30, 35, 35, 35, 35,
        30, 35, 25, 35, 35, 15, 25, 30, 15, 15,
        15, 15, 35, 35, 35, 35, 35, 25, 15, 15,
        35, 35, 35, 30, 30, 35, 25, 35, 15, 35,
        15, 15, 30, 35, 35, 15, 15, 15, 30, 40,
        30, 35, 25, 25, 25, 30, 25, 25, 35, 25,
        35, 35, 30, 25, 25, 15, 25, 25, 30, 25,
        15, 15, 35, 35, 35, 35, 35, 15, 15, 15]

    simax = Float32[
        100,  70,  80, 100, 105, 105,  90, 125,  70,  95,
        105, 135, 125,  95, 120, 120,  90,  70,  70,  85,
        105, 100,  90,  85,  70,  40,  85,  90,  90,  40,
         45,  70,  85, 105,  95,  85, 105, 120,  50,  65,
         70,  85,  85, 125, 135, 125, 115, 125,  75, 125,
         40,  55, 105, 105,  95,  40,  70,  60, 120, 125,
         90, 105, 115, 115, 115, 125,  65,  65,  95,  65,
         95,  75, 115, 115, 115, 125,  85, 115,  65,  95,
        110,  80,  90,  90,  90,  90,  90,  55,  55,  55]

    # ── debug check ─────────────────────────────────────────────────────────
    debug = DBCHK(false, "SITSET", Int32(6), ICYC)

    # ── validate ISISP ───────────────────────────────────────────────────────
    if Int(ISISP) <= 0; global ISISP = Int32(63); end
    imapsp = 38   # default index if no match (ISISP=63 → index 38)
    found = false
    for i in 1:43
        if Int(ISISP) == Int(isnsis[i])
            imapsp = i
            found = true
            break
        end
    end
    if !found
        global ISISP = Int32(63)
        imapsp = 38
    end
    if SITEAR[Int(ISISP)] <= Float32(0); SITEAR[Int(ISISP)] = Float32(70); end

    # ── bound SITEAR[ISISP] to [simin, simax] ───────────────────────────────
    isisp_i = Int(ISISP)
    if SITEAR[isisp_i] <= simin[isisp_i]
        SITEAR[isisp_i] = simin[isisp_i]
        @printf(io_units[Int(JOSTND)],
            "***** WARNING - THE SITE SPECIES (%s) SITE INDEX  VALUE WAS OUTSIDE OF THE ALLOWABLE RANGE, THE VALUE USED WAS %5.1f\n",
            JSP[isisp_i], SITEAR[isisp_i])
        ERRGRO(true, Int32(54))
    end
    if SITEAR[isisp_i] >= simax[isisp_i]
        SITEAR[isisp_i] = simax[isisp_i]
        @printf(io_units[Int(JOSTND)],
            "***** WARNING - THE SITE SPECIES (%s) SITE INDEX  VALUE WAS OUTSIDE OF THE ALLOWABLE RANGE, THE VALUE USED WAS %5.1f\n",
            JSP[isisp_i], SITEAR[isisp_i])
        ERRGRO(true, Int32(54))
    end

    # ── relative site index for site species ─────────────────────────────────
    rsisp = (SITEAR[isisp_i] - simin[isisp_i]) / (simax[isisp_i] - simin[isisp_i])

    # ── A, B coefficients by master group (IGRP) ─────────────────────────────
    igrp = Int(isngrp[imapsp])
    a = Float32(0); b = Float32(0)
    pmom = length(PCOM) >= 1 && PCOM[1] == 'M'
    if igrp == 1
        if pmom; a = Float32(-7.1837); b = Float32(0.1633)
        else;    a = Float32(-10.0);   b = Float32(0.2)
        end
    elseif igrp == 2
        if pmom; a = Float32(-8.6809); b = Float32(0.1702)
        else
            a = Float32(-12.0); b = Float32(0.2)
            if Int(ISISP) == 78; a = Float32(-16.0); b = Float32(0.2667); end
        end
    elseif igrp == 3
        a = Float32(-4.0); b = Float32(0.1)
    elseif igrp == 4
        a = Float32(-9.4118); b = Float32(0.1569)
    elseif igrp == 5
        a = Float32(-9.3913); b = Float32(0.1739)
    elseif igrp == 6
        a = Float32(-10.0); b = Float32(0.2)
    elseif igrp == 7
        a = Float32(-8.6809); b = Float32(0.1702)
    elseif igrp == 8
        a = Float32(-7.1837); b = Float32(0.1633)
    elseif igrp == 9
        if pmom; a = Float32(-8.7442); b = Float32(0.186)
        else;    a = Float32(-10.0);   b = Float32(0.2)
        end
    end

    imgsp  = Int(mgsisp[igrp])
    mgsion = rsisp * (simax[imgsp] - simin[imgsp]) + simin[imgsp]
    mgspix = a + b * mgsion

    # ── compute MGRSI[1..9]: relative SI for each master group ───────────────
    mgrsi = zeros(Float32, 9)
    for i in 1:9
        c = Float32(0); d = Float32(0)
        if i == 1
            if pmom; c = Float32(44); d = Float32(6.13)
            else;    c = Float32(50); d = Float32(5)
            end
        elseif i == 2
            if pmom; c = Float32(51); d = Float32(5.88)
            else
                c = Float32(60); d = Float32(5)
                if Int(ISISP) == 78; c = Float32(60); d = Float32(3.75); end
            end
        elseif i == 3
            c = Float32(40); d = Float32(10)
        elseif i == 4
            c = Float32(60); d = Float32(6.38)
        elseif i == 5
            c = Float32(54); d = Float32(5.75)
        elseif i == 6
            c = Float32(50); d = Float32(5)
        elseif i == 7
            c = Float32(51); d = Float32(5.88)
        elseif i == 8
            c = Float32(44); d = Float32(6.13)
        elseif i == 9
            if pmom; c = Float32(47); d = Float32(5.38)
            else;    c = Float32(50); d = Float32(5)
            end
        end
        mgsi = c + d * mgspix
        msi = Int(mgsisp[i])
        mgrsi[i] = (mgsi - simin[msi]) / (simax[msi] - simin[msi])
    end

    # ── fill SITEAR for unset species ─────────────────────────────────────────
    for i in 1:Int(MAXSP)
        if SITEAR[i] == Float32(0)
            mi = Int(mapsi[i])
            SITEAR[i] = mgrsi[mi] * (simax[i] - simin[i]) + simin[i]
            if debug; @printf(io_units[Int(JOSTND)], "I, SITEAR=  %d    %f\n", i, SITEAR[i]); end
            if SITEAR[i] <= simin[i]
                if debug
                    @printf(io_units[Int(JOSTND)],
                        "*** WARNING - THE SITE SPECIES (%s%5.1f)SITE INDEX WAS OUTSIDE OF THE ALLOWABLE RANGE, THE VALUE USED WAS %5.1f\n",
                        JSP[i], SITEAR[i], simin[i])
                end
                SITEAR[i] = simin[i]
            end
            if SITEAR[i] >= simax[i]
                if debug
                    @printf(io_units[Int(JOSTND)],
                        "*** WARNING - THE SITE SPECIES (%s%5.1f)SITE INDEX WAS OUTSIDE OF THE ALLOWABLE RANGE, THE VALUE USED WAS %5.1f\n",
                        JSP[i], SITEAR[i], simax[i])
                end
                SITEAR[i] = simax[i]
            end
        end
    end

    # ── SDIDEF defaults ───────────────────────────────────────────────────────
    for i in 1:Int(MAXSP)
        if SDIDEF[i] <= Float32(0)
            if BAMAX > Float32(0)
                SDIDEF[i] = BAMAX / (Float32(0.5454154) * (PMSDIU / Float32(100)))
            else
                SDIDEF[i] = sdicon[i]
            end
        end
    end

    # ── IFORTP > 999: user-set constant forest type ───────────────────────────
    if Int(IFORTP) > 999
        xtmp  = Float32(Int(IFORTP))
        xtmp  = xtmp / Float32(1000) + Float32(0.00001)
        ixtmp = Int(xtmp)
        global IFORTP = Int32((xtmp - Float32(ixtmp)) * Float32(1000))
        global LFLAGV = true
    end

    # ── forest code parsing for IREGN / IFORST / DIST ───────────────────────
    local iregn::Int32, iforst::Int32, intdist::Int32
    local forst::String, dist::String
    var  = "SN"
    prod = "  "

    if Int(ISEFOR) != 0
        iregn  = Int32(Int(KODFOR) ÷ 10000)
        iforst = Int32(Int(KODFOR) ÷ 100 - Int(iregn) * 100)
        forst  = @sprintf("%02d", iforst)
        intdist = Int32(Int(KODFOR) - (Int(KODFOR) ÷ 100) * 100)
        dist    = @sprintf("%02d", intdist)
    else
        if Int(KODFOR) > 1000
            iforst = Int32(Int(KODFOR) ÷ 100 - 900)
        else
            iforst = Int32(Int(KODFOR) - 900)
        end
        dist  = "  "
        iregn = Int32(9)
        forst = @sprintf("%02d", iforst)
    end

    # ── volume merchantability defaults by species ────────────────────────────
    ifor_i = Int(IFOR)
    dist_i = Int(KODIST)
    for ispc in 1:Int(MAXSP)
        if Int(iregn) == 8
            # REGION 8
            if DBHMIN[ispc] <= Float32(0)
                if ispc <= 17 || ispc == 88   # softwoods
                    if ifor_i == 11
                        if dist_i == 3 || dist_i == 10
                            DBHMIN[ispc] = Float32(5.6)
                        else
                            DBHMIN[ispc] = Float32(8)
                        end
                    else
                        if ispc == 7 || ispc == 13
                            DBHMIN[ispc] = Float32(6)
                        else
                            DBHMIN[ispc] = Float32(4)
                        end
                    end
                else                           # hardwoods
                    if ifor_i == 11
                        if dist_i == 3 || dist_i == 10
                            DBHMIN[ispc] = Float32(6)
                        else
                            DBHMIN[ispc] = Float32(8)
                        end
                    else
                        if ispc ∈ (39, 43, 44, 52, 53, 55, 63)
                            DBHMIN[ispc] = Float32(6)
                        else
                            DBHMIN[ispc] = Float32(4)
                        end
                    end
                end
            end
            if TOPD[ispc] <= Float32(0)
                TOPD[ispc] = ifor_i == 11 ? Float32(3.5) : Float32(4)
            end
            if BFMIND[ispc] <= Float32(0)
                if ispc <= 17 || ispc == 88   # softwoods
                    if ifor_i == 10
                        BFMIND[ispc] = ispc == 2 ? Float32(9) : Float32(10)
                    elseif ifor_i == 11
                        if dist_i == 3 || dist_i == 10
                            BFMIND[ispc] = Float32(11)
                        elseif ispc ∈ (2, 12, 15, 16, 17)
                            BFMIND[ispc] = Float32(12)
                        else
                            BFMIND[ispc] = Float32(10)
                        end
                    else
                        BFMIND[ispc] = Float32(10)
                    end
                else                           # hardwoods
                    if ifor_i == 11
                        BFMIND[ispc] = (dist_i == 3 || dist_i == 10) ? Float32(13) : Float32(15)
                    else
                        BFMIND[ispc] = Float32(12)
                    end
                end
            end
            if BFTOPD[ispc] <= Float32(0)
                if ispc <= 17 || (length(JSP[ispc]) >= 2 && JSP[ispc][1:2] == "OS")
                    if ifor_i == 11
                        if dist_i == 3 || dist_i == 10
                            BFTOPD[ispc] = Float32(6.3)
                        elseif ispc ∈ (2, 12, 15, 16, 17)
                            BFTOPD[ispc] = Float32(9)
                        else
                            BFTOPD[ispc] = Float32(6.3)
                        end
                    else
                        BFTOPD[ispc] = Float32(7)
                    end
                else                           # hardwoods
                    if ifor_i == 11
                        BFTOPD[ispc] = (dist_i == 3 || dist_i == 10) ? Float32(8) : Float32(11)
                    else
                        BFTOPD[ispc] = Float32(9)
                    end
                end
            end
            if SCFMIND[ispc] <= Float32(0)
                if ispc <= 17 || ispc == 88   # softwoods
                    if ifor_i == 10
                        SCFMIND[ispc] = ispc == 2 ? Float32(9) : Float32(10)
                    elseif ifor_i == 11
                        if dist_i == 3 || dist_i == 10
                            SCFMIND[ispc] = Float32(11)
                        elseif ispc ∈ (2, 12, 15, 16, 17)
                            SCFMIND[ispc] = Float32(12)
                        else
                            SCFMIND[ispc] = Float32(10)
                        end
                    else
                        SCFMIND[ispc] = Float32(10)
                    end
                else                           # hardwoods
                    if ifor_i == 11
                        SCFMIND[ispc] = (dist_i == 3 || dist_i == 10) ? Float32(13) : Float32(15)
                    else
                        SCFMIND[ispc] = Float32(12)
                    end
                end
            end
            if SCFTOPD[ispc] <= Float32(0)
                if ispc <= 17 || (length(JSP[ispc]) >= 2 && JSP[ispc][1:2] == "OS")
                    if ifor_i == 11
                        if dist_i == 3 || dist_i == 10
                            SCFTOPD[ispc] = Float32(6.3)
                        elseif ispc ∈ (2, 12, 15, 16, 17)
                            SCFTOPD[ispc] = Float32(9)
                        else
                            SCFTOPD[ispc] = Float32(6.3)
                        end
                    else
                        SCFTOPD[ispc] = Float32(7)
                    end
                else                           # hardwoods
                    if ifor_i == 11
                        SCFTOPD[ispc] = (dist_i == 3 || dist_i == 10) ? Float32(8) : Float32(11)
                    else
                        SCFTOPD[ispc] = Float32(9)
                    end
                end
            end
        else
            # REGION 9
            if DBHMIN[ispc] <= Float32(0)
                if ispc <= 17 || ispc == 88
                    DBHMIN[ispc] = Float32(5)
                else
                    DBHMIN[ispc] = ifor_i == 14 ? Float32(5) : Float32(6)
                end
            end
            if TOPD[ispc] <= Float32(0)
                if ispc <= 17 || ispc == 88
                    TOPD[ispc] = Float32(4)
                else
                    TOPD[ispc] = ifor_i == 15 ? Float32(5) : Float32(4)
                end
            end
            if BFMIND[ispc] <= Float32(0)
                if ispc <= 17 || ispc == 88
                    BFMIND[ispc] = Float32(9)
                else
                    BFMIND[ispc] = ifor_i == 14 ? Float32(9) : Float32(11)
                end
            end
            if BFTOPD[ispc] <= Float32(0)
                if ispc <= 17 || ispc == 88
                    BFTOPD[ispc] = Float32(7.6)
                else
                    BFTOPD[ispc] = ifor_i == 14 ? Float32(7.6) : Float32(9.6)
                end
            end
            if SCFMIND[ispc] <= Float32(0)
                if ispc <= 17 || ispc == 88
                    SCFMIND[ispc] = Float32(9)
                else
                    SCFMIND[ispc] = ifor_i == 14 ? Float32(9) : Float32(11)
                end
            end
            if SCFTOPD[ispc] <= Float32(0)
                if ispc <= 17 || ispc == 88
                    SCFTOPD[ispc] = Float32(7.6)
                else
                    SCFTOPD[ispc] = ifor_i == 14 ? Float32(7.6) : Float32(9.6)
                end
            end
        end
    end

    # ── volume equation defaults ──────────────────────────────────────────────
    if LFIANVB; NVB_REGION_CHECK(); end
    for ispc in 1:Int(MAXSP)
        ifiasp = try parse(Int32, strip(FIAJSP[ispc])) catch; Int32(0); end
        voleq  = "           "
        if (Int(METHC[ispc]) == 6 || Int(METHC[ispc]) == 9) && VEQNNC[ispc] == "           "
            prod = "02"
            VOLEQDEF(var, iregn, forst, dist, ifiasp, prod, voleq)
            # stub leaves VEQNNC[ispc] as "           "
        elseif Int(METHC[ispc]) == 10
            NVBEQDEF(ifiasp, voleq)
            # stub leaves VEQNNC[ispc] as "           "
        end
        if debug
            @printf(io_units[Int32(16)],
                "VAR,IREGN,FORST,DIST,IFIASP,PROD,VOLEQ, ERRFLAG=  %s %d %s %s %d %s %s %d\n",
                var, iregn, forst, dist, ifiasp, prod, VEQNNC[ispc], 0)
        end
        if (Int(METHB[ispc]) == 6 || Int(METHB[ispc]) == 9) && VEQNNB[ispc] == "           "
            prod  = "01"
            voleq = "           "
            VOLEQDEF(var, iregn, forst, dist, ifiasp, prod, voleq)
        end
    end

    # ── HT-DBH coefficients ───────────────────────────────────────────────────
    HT1[1]  = Float32(4.5084); HT1[2]  = Float32(4.0374); HT1[3]  = Float32(4.5084)
    HT1[4]  = Float32(4.2899); HT1[5]  = Float32(4.6271); HT1[6]  = Float32(4.6561)
    HT1[7]  = Float32(4.7258); HT1[8]  = Float32(4.5991); HT1[9]  = Float32(4.2139)
    HT1[10] = Float32(4.3898); HT1[11] = Float32(4.5457); HT1[12] = Float32(4.6090)
    HT1[13] = Float32(4.6897); HT1[14] = Float32(4.4718); HT1[15] = Float32(4.6171)
    HT1[16] = Float32(4.4603); HT1[17] = Float32(4.5084); HT1[18] = Float32(4.3164)
    HT1[19] = Float32(4.2378); HT1[20] = Float32(4.3379); HT1[21] = Float32(4.5991)
    HT1[22] = Float32(4.4834); HT1[23] = Float32(4.5697); HT1[24] = Float32(4.4388)
    HT1[25] = Float32(4.4522); HT1[26] = Float32(3.8550); HT1[27] = Float32(4.5128)
    HT1[28] = Float32(4.9396); HT1[29] = Float32(4.4207); HT1[30] = Float32(3.7512)
    HT1[31] = Float32(3.7301); HT1[32] = Float32(4.4091); HT1[33] = Float32(4.4772)
    HT1[34] = Float32(4.4819); HT1[35] = Float32(4.5959); HT1[36] = Float32(4.6155)
    HT1[37] = Float32(4.6155); HT1[38] = Float32(4.3734); HT1[39] = Float32(4.4009)
    HT1[40] = Float32(4.4931); HT1[41] = Float32(4.0151); HT1[42] = Float32(4.5018)
    HT1[43] = Float32(4.5018); HT1[44] = Float32(4.5920); HT1[45] = Float32(4.6892)
    HT1[46] = Float32(4.4004); HT1[47] = Float32(4.6067); HT1[48] = Float32(4.4004)
    HT1[49] = Float32(4.3609); HT1[50] = Float32(4.4004); HT1[51] = Float32(3.9678)
    HT1[52] = Float32(3.9613); HT1[53] = Float32(4.4330); HT1[54] = Float32(4.3802)
    HT1[55] = Float32(4.4334); HT1[56] = Float32(4.0322); HT1[57] = Float32(4.1352)
    HT1[58] = Float32(4.0965); HT1[59] = Float32(4.6355); HT1[60] = Float32(4.9396)
    HT1[61] = Float32(4.9396); HT1[62] = Float32(4.3286); HT1[63] = Float32(4.5463)
    HT1[64] = Float32(4.5225); HT1[65] = Float32(4.5142); HT1[66] = Float32(4.7342)
    HT1[67] = Float32(3.9365); HT1[68] = Float32(4.4375); HT1[69] = Float32(4.5710)
    HT1[70] = Float32(3.9191); HT1[71] = Float32(4.6135); HT1[72] = Float32(4.3420)
    HT1[73] = Float32(4.5577); HT1[74] = Float32(4.4618); HT1[75] = Float32(4.5202)
    HT1[76] = Float32(4.6106); HT1[77] = Float32(4.2496); HT1[78] = Float32(4.4747)
    HT1[79] = Float32(4.2959); HT1[80] = Float32(4.4299); HT1[81] = Float32(4.4911)
    HT1[82] = Float32(4.3383); HT1[83] = Float32(4.5820); HT1[84] = Float32(4.3744)
    HT1[85] = Float32(4.5992); HT1[86] = Float32(4.6008); HT1[87] = Float32(4.6238)
    HT1[88] = Float32(4.3898); HT1[89] = Float32(3.9392); HT1[90] = Float32(3.9089)

    HT2[1]  = Float32(-6.0116); HT2[2]  = Float32(-4.2964); HT2[3]  = Float32(-6.0116)
    HT2[4]  = Float32(-4.1019); HT2[5]  = Float32(-6.4095); HT2[6]  = Float32(-6.2258)
    HT2[7]  = Float32(-6.7703); HT2[8]  = Float32(-5.9111); HT2[9]  = Float32(-4.5419)
    HT2[10] = Float32(-5.7183); HT2[11] = Float32(-6.8000); HT2[12] = Float32(-6.1896)
    HT2[13] = Float32(-6.8801); HT2[14] = Float32(-5.0078); HT2[15] = Float32(-6.2684)
    HT2[16] = Float32(-5.0577); HT2[17] = Float32(-6.0116); HT2[18] = Float32(-4.0582)
    HT2[19] = Float32(-4.1080); HT2[20] = Float32(-3.8214); HT2[21] = Float32(-6.6706)
    HT2[22] = Float32(-4.5431); HT2[23] = Float32(-5.7172); HT2[24] = Float32(-4.0872)
    HT2[25] = Float32(-4.5758); HT2[26] = Float32(-2.6623); HT2[27] = Float32(-4.9918)
    HT2[28] = Float32(-8.1838); HT2[29] = Float32(-5.1435); HT2[30] = Float32(-2.5539)
    HT2[31] = Float32(-2.7758); HT2[32] = Float32(-4.8464); HT2[33] = Float32(-4.7206)
    HT2[34] = Float32(-4.5314); HT2[35] = Float32(-6.4497); HT2[36] = Float32(-6.2945)
    HT2[37] = Float32(-6.2945); HT2[38] = Float32(-5.3135); HT2[39] = Float32(-5.0560)
    HT2[40] = Float32(-4.6501); HT2[41] = Float32(-4.3314); HT2[42] = Float32(-5.6123)
    HT2[43] = Float32(-5.6123); HT2[44] = Float32(-5.1719); HT2[45] = Float32(-4.9605)
    HT2[46] = Float32(-4.7519); HT2[47] = Float32(-5.2030); HT2[48] = Float32(-4.7519)
    HT2[49] = Float32(-4.1423); HT2[50] = Float32(-4.7519); HT2[51] = Float32(-3.2510)
    HT2[52] = Float32(-3.1993); HT2[53] = Float32(-4.5383); HT2[54] = Float32(-4.7903)
    HT2[55] = Float32(-4.5709); HT2[56] = Float32(-3.0833); HT2[57] = Float32(-3.7450)
    HT2[58] = Float32(-3.9250); HT2[59] = Float32(-5.2776); HT2[60] = Float32(-8.1838)
    HT2[61] = Float32(-8.1838); HT2[62] = Float32(-4.0922); HT2[63] = Float32(-5.2287)
    HT2[64] = Float32(-4.9401); HT2[65] = Float32(-5.2205); HT2[66] = Float32(-6.2674)
    HT2[67] = Float32(-4.4599); HT2[68] = Float32(-4.6654); HT2[69] = Float32(-6.0922)
    HT2[70] = Float32(-4.3503); HT2[71] = Float32(-5.7613); HT2[72] = Float32(-5.1193)
    HT2[73] = Float32(-4.9595); HT2[74] = Float32(-4.8786); HT2[75] = Float32(-4.8896)
    HT2[76] = Float32(-5.4380); HT2[77] = Float32(-4.8061); HT2[78] = Float32(-4.8698)
    HT2[79] = Float32(-5.3332); HT2[80] = Float32(-4.9920); HT2[81] = Float32(-5.7928)
    HT2[82] = Float32(-4.5018); HT2[83] = Float32(-5.0903); HT2[84] = Float32(-4.5257)
    HT2[85] = Float32(-7.7428); HT2[86] = Float32(-7.2732); HT2[87] = Float32(-7.4847)
    HT2[88] = Float32(-5.7183); HT2[89] = Float32(-3.4279); HT2[90] = Float32(-3.0149)

    # ── Fort Bragg overrides ──────────────────────────────────────────────────
    if Int(IFOR) == 20
        global ITYPE = Int32(176)
        global PCOM  = "232BQ   "
        HT1[5]  = Float32(4.705);  HT2[5]  = Float32(-7.904)
        HT1[6]  = Float32(4.787);  HT2[6]  = Float32(-8.015)
        HT1[8]  = Float32(4.562);  HT2[8]  = Float32(-7.314)
        HT1[11] = Float32(4.806);  HT2[11] = Float32(-9.573)
        HT1[13] = Float32(4.79);   HT2[13] = Float32(-8.5)
        @printf(io_units[Int(JOSTND)],
            "\n%12sECOLOGICAL UNIT CODE CHANGED TO 232BQ FOR FURTHER PROCESSING OF FORT BRAGG LOCATION.\n",
            "")
    end

    # ── FIA code translation table ────────────────────────────────────────────
    if LFIA
        FIAHEAD(Int(JOSTND))
        jostnd_io = io_units[Int(JOSTND)]
        col = 0
        for i in 1:Int(MAXSP)
            if col == 0
                @printf(jostnd_io, "%12s", "")
            end
            sp2 = length(NSP[i,1]) >= 2 ? NSP[i,1][1:2] : rpad(NSP[i,1], 2)
            fia = FIAJSP[i]
            if i < Int(MAXSP)
                @printf(jostnd_io, "%s=%-6s; ", sp2, fia)
            else
                @printf(jostnd_io, "%s=%-6s", sp2, fia)
            end
            col += 1
            if col == 8
                @printf(jostnd_io, "\n")
                col = 0
            end
        end
        if col > 0; @printf(jostnd_io, "\n"); end
    end

    # ── volume equation number table ──────────────────────────────────────────
    VOLEQHEAD(Int(JOSTND))
    jostnd_io = io_units[Int(JOSTND)]
    col = 0
    for j in 1:Int(MAXSP)
        sp2 = length(NSP[j,1]) >= 2 ? NSP[j,1][1:2] : rpad(NSP[j,1], 2)
        @printf(jostnd_io, "  %-2s    %-11s %-10s ", sp2, VEQNNC[j], VEQNNB[j])
        col += 1
        if col == 4; @printf(jostnd_io, "\n"); col = 0; end
    end
    if col > 0; @printf(jostnd_io, "\n"); end

    return nothing
end
