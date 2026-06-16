# cratet.jl — Stand initialization: calibration, height dubbing, crown dubbing
# Translated from: base/cratet.f (631 lines)
#
# Called once per stand at cycle 0, prior to any projection.
# Functions:
#   1. Print SDI max by species
#   2. Call RCON, DENSE (initial density)
#   3. Convert DG codes to increments
#   4. Dub missing heights via Wykoff HT-DBH model
#   5. Dub missing crown ratios via CROWN
#   6. Calibrate diameter growth (DGDRIV) and height growth
#   7. Estimate missing tree ages (FINDAG)
#   8. Call REGENT for small-tree height calibration
#   9. Compute PCTILE/DIST/COMP for TPA distribution

function CRATET()
    debug = DBCHK(false, "CRATET", Int32(6), ICYC)

    # Print SDI max by species (10 per line)
    i = 1
    while i <= Int(MAXSP)
        j  = i
        jj = min(j + 9, Int(MAXSP))
        @printf(io_units[Int(JOSTND)], "\nSPECIES     ")
        for k in j:jj
            @printf(io_units[Int(JOSTND)], "  %-2s      ", length(NSP[k,1])>=2 ? NSP[k,1][1:2] : NSP[k,1])
        end
        @printf(io_units[Int(JOSTND)], "\n")
        @printf(io_units[Int(JOSTND)], "SDI MAX  ")
        for k in j:jj
            @printf(io_units[Int(JOSTND)], "%8.0f", SDIDEF[k])
        end
        @printf(io_units[Int(JOSTND)], "\n")
        i += 10
    end

    ax = Float32(0)
    knt2 = zeros(Int32, Int(MAXSP))
    knt  = zeros(Int32, Int(MAXSP))
    spcnt = zeros(Float32, Int(MAXSP), 3)

    if Int(ITRN) > 0; @goto label_1; end

    # No live trees: still run minimal setup
    MAICAL()
    RCON()
    ONTREM[7] = Float32(0)
    DENSE()
    DGDRIV()
    REGENT(false, Int32(1))

    @label label_1

    for i in 1:Int(MAXSP)
        spcnt[i,1] = Float32(0); spcnt[i,2] = Float32(0); spcnt[i,3] = Float32(0)
        if ISCT[i,1] == Int32(0); continue; end
        j = Int(IREF[i])
        IUSED[j] = NSP[i,1]
    end

    if Int(ITRN) <= 0 && Int(IREC2) >= Int(MAXTP1); @goto label_245; end

    # Calibration statistics header
    @printf(io_units[Int(JOSTND)], "\n\nCALIBRATION STATISTICS:\n\n\n")
    @printf(io_units[Int(JOSTND)], "                                                ")
    for i in 1:Int(NUMSP)
        @printf(io_units[Int(JOSTND)], " %-2s   ", IUSED[i])
    end
    @printf(io_units[Int(JOSTND)], "\n")
    @printf(io_units[Int(JOSTND)], "                                                ")
    n_under = min(Int(NUMSP), 11)
    for i in 1:n_under; @printf(io_units[Int(JOSTND)], "----  "); end
    @printf(io_units[Int(JOSTND)], "\n")
    @printf(io_units[Int(JOSTND)], "\nNUMBER OF RECORDS PER SPECIES                   ")
    for i in 1:Int(NUMSP)
        @printf(io_units[Int(JOSTND)], "%4d  ", KOUNT[i])
    end
    @printf(io_units[Int(JOSTND)], "\n")

    for i in 1:Int(MAXSP); knt[i] = Int32(0); knt2[i] = Int32(0); end

    MBACAL()
    MAICAL()
    RCON()

    for i in 1:Int(ITRN)
        IND[i] = IND1[i]
    end
    RDPSRT(Int(ITRN), DBH, @view(IND[1:Int(ITRN)]), false)
    ONTREM[7] = Float32(0)

    # Convert DG codes to increments (IDG=1: past DBH → DG; IDG=3: current DBH → DG)
    q = Float32(1)
    if Int(IDG) == 3; q = Float32(-1); end
    for ii in 1:Int(ITRN)
        i = Int(IND1[ii])
        i >= Int(IREC2) && continue
        if DG[i] <= Float32(0)
            DG[i] = Float32(-1)
            continue
        end
        (Int(IDG) == 0 || Int(IDG) == 2) && continue
        DG[i] = q * (DBH[i] - DG[i])
    end

    global LBKDEN = Int(IDG) < 2
    DENSE()
    global LBKDEN = false

    # Remove cycle-0 dead trees from species-ordered sort
    if Int(IREC2) == Int(MAXTP1); @goto label_60; end

    for i in Int(IREC2):Int(MAXTRE)
        ispc = Int(ISP[i])
        iptr = Int(IREF[ispc])
        if Int(IMC[i]) == 7; knt[iptr] += Int32(1); end
        if debug
            @printf(io_units[Int(JOSTND)], "IN CRATET: DEAD TREE RECORD:  I=%4d,  IMC=%2d,  SPECIES=%2d (9003 CRATET)\n",
                    i, IMC[i], ispc)
        end
        if Int(ITRN) > 0
            i1 = Int(ISCT[ispc, 1])
            i2 = Int(ISCT[ispc, 2])
            i3 = i1
            for _i3 in i1:i2
                if Int(IND1[_i3]) == i; i3 = _i3; break; end
            end
            IND1[i3] = IND1[i2]
            ISCT[ispc, 2] = Int32(i2 - 1)
            if Int(ISCT[ispc, 2]) < Int(ISCT[ispc, 1])
                ISCT[ispc, 1] = Int32(0)
                ISCT[ispc, 2] = Int32(0)
            end
        end
    end

    # Print dead-tree count
    @printf(io_units[Int(JOSTND)], "\nNUMBER OF RECORDS CODED AS RECENT MORTALITY                    ")
    for i in 1:Int(NUMSP); @printf(io_units[Int(JOSTND)], "%4d  ", knt[i]); end
    @printf(io_units[Int(JOSTND)], "\n")

    global ITRN = IREC1
    if Int(ITRN) <= 0 && Int(IREC2) >= Int(MAXTP1); @goto label_245; end
    if Int(ITRN) <= 0; @goto label_60; end

    # Reshuffle species sort if needed
    ispc_old = Int(NUMSP)
    for i in 1:Int(MAXSP); knt[i] = IREF[i]; end
    SPESRT()
    if ispc_old != Int(NUMSP)
        @printf(io_units[Int(JOSTND)], "\n***** NOTE:  SPECIES HAVE BEEN DROPPED.\n")
        for i in 1:Int(MAXSP)
            Int(ISCT[i,1]) == 0 && continue
            j = Int(IREF[i])
            IUSED[j] = NSP[i,1]
        end
        @printf(io_units[Int(JOSTND)], "                                                ")
        for i in 1:Int(NUMSP); @printf(io_units[Int(JOSTND)], " %-2s   ", IUSED[i]); end
        @printf(io_units[Int(JOSTND)], "\n")
        @printf(io_units[Int(JOSTND)], "                                                ")
        for i in 1:min(Int(NUMSP),11); @printf(io_units[Int(JOSTND)], "----  "); end
        @printf(io_units[Int(JOSTND)], "\n")
    else
        for i in 1:Int(MAXSP); IREF[i] = knt[i]; end
    end

    RDPSRT(Int(ITRN), DBH, @view(IND[1:Int(ITRN)]), true)

    @label label_60
    for i in 1:Int(MAXSP); knt[i] = Int32(0); end

    # Height-DBH calibration and dubbing loop (over species)
    for ispc in 1:Int(MAXSP)
        AA[ispc] = Float32(0); BB[ispc] = Float32(0)
        i1 = Int(ISCT[ispc, 1])
        iptr = 0

        if i1 > 0
            i2   = Int(ISCT[ispc, 2])
            iptr = Int(IREF[ispc])
            k1 = 0; k2 = 0; k3 = 0; k4 = 0; sumx = Float32(0)

            # Summation for Wykoff height-DBH fit
            for i3 in i1:i2
                i    = Int(IND1[i3])
                h_v  = Float32(HT[i])
                nh_v = Int(NORMHT[i])
                d_v  = Float32(DBH[i])
                bx   = Float32(HT2[ispc])

                if h_v > Float32(4.5) && nh_v >= 0 && d_v >= Float32(3)
                    k1 += 1
                    xx = bx / (d_v + Float32(1))
                    yy = log(h_v - Float32(4.5))
                    sumx += yy - xx
                else
                    if nh_v < 0; k3 += 1; end
                    if h_v > Float32(0) && nh_v == 0; continue; end
                    k2 += 1
                    IND2[k2] = Int32(i)
                end
                if HT[i] <= Float32(0.1); HTG[i] = Float32(0); end
            end

            knt[iptr] = Int32(k3)
            if k1 >= 3 && LHTDRG[ispc]
                xn = Float32(k1)
                AA[ispc] = sumx / xn
                if AA[ispc] >= Float32(0); IABFLG[ispc] = Int32(0); end
            end

            # Dub missing heights for live trees
            ax = Float32(HT1[ispc]); bx_v = Float32(HT2[ispc])
            if Int(IABFLG[ispc]) == 0; ax = AA[ispc]; end

            if k2 > 0
                for jj in 1:k2
                    ii  = Int(IND2[jj])
                    d_v = Float32(DBH[ii])
                    tkill = Int(NORMHT[ii]) < 0
                    if d_v <= Float32(0.1)
                        h_v = Float32(1.01)
                    else
                        h_v = exp(ax + bx_v / (d_v + Float32(1))) + Float32(4.5)
                        if debug
                            @printf(io_units[Int(JOSTND)], "CRATET DUBBED HEIGHT: AX,BX,D,H= %8.2f %8.2f %8.2f %8.2f\n",
                                    ax, bx_v, d_v, h_v)
                        end
                        use_inv = !LHTDRG[ispc] || (LHTDRG[ispc] && Int(IABFLG[ispc]) == 1)
                        if use_inv
                            href = Ref(h_v)
                            HTDBH(Int(IFOR), ispc, d_v, href, Int32(0))
                            h_v = href[]
                            if debug
                                @printf(io_units[Int(JOSTND)], "INVENTORY EQN DUBBING IFOR,ISPC,D,H=  %d %d %f %f\n",
                                        IFOR, ispc, d_v, h_v)
                            end
                        end
                        if h_v < Float32(4.5); h_v = Float32(4.5); end
                    end

                    if !tkill
                        HT[ii] = h_v; k4 += 1
                    else
                        NORMHT[ii] = round(Int32, h_v * Float32(100) + Float32(0.5))
                        if Int(ITRUNC[ii]) == 0
                            if HT[ii] > Float32(0)
                                ITRUNC[ii] = round(Int32, Float32(80) * HT[ii] + Float32(0.5))
                            else
                                ITRUNC[ii] = round(Int32, Float32(80) * h_v + Float32(0.5))
                                HT[ii] = h_v
                            end
                        else
                            if HT[ii] > Float32(0)
                                if HT[ii] < Float32(ITRUNC[ii]) * Float32(0.01)
                                    HT[ii] = Float32(ITRUNC[ii]) * Float32(0.01)
                                end
                            else
                                HT[ii] = Float32(ITRUNC[ii]) * Float32(0.01)
                            end
                        end
                        if Float32(NORMHT[ii]) * Float32(0.01) < HT[ii]
                            NORMHT[ii] = round(Int32, HT[ii] * Float32(100))
                        end
                    end
                end
                knt2[iptr] = Int32(k4)
            end

            if debug
                @printf(io_units[Int(JOSTND)], "HEIGHT-DIAMETER COEFFICIENTS FOR SPECIES %2d:  INTERCEPT=%10.6f  SLOPE=%10.6f  FLAG=%3d (9005 CRATET)\n",
                        ispc, AA[ispc], Float32(HT2[ispc]), IABFLG[ispc])
            end
        end  # i1 > 0

        # Dead tree height dubbing for this species
        Int(IREC2) > Int(MAXTRE) && continue

        ax_dead = Float32(HT1[ispc]); bx_dead = Float32(HT2[ispc])
        if Int(IABFLG[ispc]) == 0; ax_dead = AA[ispc]; end

        for ii_d in Int(IREC2):Int(MAXTRE)
            Int(ISP[ii_d]) != ispc && continue
            d_v = Float32(DBH[ii_d])
            tkill = Int(NORMHT[ii_d]) < 0

            if HT[ii_d] > Float32(0) && tkill
                # topkilled with known height: just update NORMHT
                NORMHT[ii_d] = round(Int32, HT[ii_d] * Float32(100) + Float32(0.5))
            elseif HT[ii_d] > Float32(0)
                # height known, no dubbing needed
            else
                # need to dub
                if d_v <= Float32(0.1)
                    h_v = Float32(1.01)
                else
                    h_v = exp(ax_dead + bx_dead / (d_v + Float32(1))) + Float32(4.5)
                    use_inv = !LHTDRG[ispc] || (LHTDRG[ispc] && Int(IABFLG[ispc]) == 1)
                    if use_inv
                        href = Ref(h_v)
                        HTDBH(Int(IFOR), ispc, d_v, href, Int32(0))
                        h_v = href[]
                        if debug
                            @printf(io_units[Int(JOSTND)], "INVENTORY EQN DUBBING IFOR,ISPC,D,H=  %d %d %f %f\n",
                                    IFOR, ispc, d_v, h_v)
                        end
                    end
                    if h_v < Float32(4.5); h_v = Float32(4.5); end
                end
                if tkill
                    NORMHT[ii_d] = round(Int32, h_v * Float32(100) + Float32(0.5))
                else
                    HT[ii_d] = h_v
                end
            end

            # Handle topkill geometry
            if tkill
                if Int(ITRUNC[ii_d]) == 0
                    if HT[ii_d] > Float32(0)
                        ITRUNC[ii_d] = round(Int32, Float32(80) * HT[ii_d] + Float32(0.5))
                    else
                        h_v2 = Float32(NORMHT[ii_d]) * Float32(0.01)
                        ITRUNC[ii_d] = round(Int32, Float32(80) * h_v2 + Float32(0.5))
                        HT[ii_d] = h_v2
                    end
                else
                    if HT[ii_d] > Float32(0)
                        if HT[ii_d] < Float32(ITRUNC[ii_d]) * Float32(0.01)
                            HT[ii_d] = Float32(ITRUNC[ii_d]) * Float32(0.01)
                        end
                    else
                        HT[ii_d] = Float32(ITRUNC[ii_d]) * Float32(0.01)
                    end
                end
                if Float32(NORMHT[ii_d]) * Float32(0.01) < HT[ii_d]
                    NORMHT[ii_d] = round(Int32, HT[ii_d] * Float32(100))
                end
            end

            hs = tkill ? Float32(ITRUNC[ii_d]) * Float32(0.01) : HT[ii_d]
            FMSSEE(ii_d, ispc, d_v, hs, Float32(PROB[ii_d]) / (Float32(FINT)/Float32(FINTM)),
                   Int32(3), false, Int(JOSTND))
        end
    end  # species loop

    # Print height dubbing summary
    @printf(io_units[Int(JOSTND)], "\nNUMBER OF RECORDS WITH MISSING HEIGHTS                          ")
    for i in 1:Int(NUMSP); @printf(io_units[Int(JOSTND)], "%4d  ", knt2[i]); end
    @printf(io_units[Int(JOSTND)], "\n")
    @printf(io_units[Int(JOSTND)], "\nNUMBER OF RECORDS WITH BROKEN OR DEAD TOPS                      ")
    for i in 1:Int(NUMSP); @printf(io_units[Int(JOSTND)], "%4d  ", knt[i]); end
    @printf(io_units[Int(JOSTND)], "\n")
    for i in 1:Int(MAXSP); knt[i] = Int32(0); knt2[i] = Int32(0); end

    # Check for missing crown ratios
    misscr = false
    for i in 1:Int(ITRN)
        OLDPCT[i] = PCT[i]
        if Int(ICR[i]) <= 0
            misscr = true
            ispc_v = Int(ISP[i])
            iptr_v = Int(IREF[ispc_v])
            knt2[iptr_v] += Int32(1)
        end
        if Int(ITRE[i]) <= 0; ITRE[i] = Int32(9999); end
    end
    if Int(IREC2) <= Int(MAXTRE)
        for i in Int(IREC2):Int(MAXTRE)
            if Int(ICR[i]) <= 0; misscr = true; end
        end
    end
    if misscr; CROWN(); end

    @printf(io_units[Int(JOSTND)], "\nNUMBER OF RECORDS WITH MISSING CROWN RATIOS                     ")
    for i in 1:Int(NUMSP); @printf(io_units[Int(JOSTND)], "%4d  ", knt2[i]); end
    @printf(io_units[Int(JOSTND)], "\n")
    for i in 1:Int(MAXSP); knt2[i] = Int32(0); end

    AVHT40()
    if debug; @printf(io_units[Int(JOSTND)], "CALL DGDRIV FROM CRATET SECOND TIME\n"); end
    DGDRIV()

    # Height growth calibration data conversion
    if Int(IHTG) != 0 && Int(IHTG) != 2
        q_ht = Float32(1)
        if Int(IHTG) == 3; q_ht = Float32(-1); end
        for i in 1:Int(ITRN)
            HTG[i] <= Float32(0) && continue
            HTG[i] = q_ht * (HT[i] - HTG[i])
            if HT[i] <= Float32(0); HTG[i] = Float32(0); end
        end
    end

    # Estimate missing tree ages via FINDAG
    if debug; @printf(io_units[Int(JOSTND)], "IN CRATET, CALLING FINDAG\n"); end
    for i in 1:Int(ITRN)
        if ABIRTH[i] <= Float32(0)
            sitage = Float32(0); sitht = Float32(0)
            agmax  = Float32(0); htmax = Float32(0); htmax2 = Float32(0)
            ispc_v = Int(ISP[i])
            d_v  = Float32(DBH[i]); h_v = Float32(HT[i]); d2_v = Float32(0)
            FINDAG(i, ispc_v, d_v, d2_v, h_v, sitage, sitht, agmax, htmax, htmax2, debug)
            if sitage > Float32(0); ABIRTH[i] = sitage; end
        end
    end

    REGENT(false, Int32(1))

    # TPA-by-species-class accumulation
    for i in 1:Int(ITRN)
        is_v = Int(ISP[i])
        im_v = Int(IMC[i])
        spcnt[is_v, im_v] += Float32(PROB[i])
    end

    @label label_245
    ONTCUR[7] = PCTILE(Int(ITRN), IND, PROB, WK3)
    DIST(Int(ITRN), ONTCUR, WK3)
    COMP(OSPCT, IOSPCT, spcnt)

    if Int(ITRN) <= 0; @goto label_500; end

    if debug; @printf(io_units[Int(JOSTND)], "CALLING DENSE, CYCLE= %2d\n", ICYC); end
    DENSE()

    MISCNT(knt)
    @printf(io_units[Int(JOSTND)], "\nNUMBER OF RECORDS WITH MISTLETOE                                ")
    for i in 1:Int(NUMSP); @printf(io_units[Int(JOSTND)], "%4d  ", knt[i]); end
    @printf(io_units[Int(JOSTND)], "\n")

    SDICHK()

    @label label_500
    if debug; @printf(io_units[Int(JOSTND)], "LEAVING SUBROUTINE CRATET  CYCLE = %5d\n", ICYC); end
    return nothing
end

# MISCNT → base/extstubs.jl  FMSSEE → extensions/fire/fmssee.jl  HTDBH → base/htdbh.jl
