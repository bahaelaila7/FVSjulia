# gradd.jl — Apply growth increments; end-of-cycle updates
# Translated from: base/gradd.f (367 lines)
#
# GRADD:
#   1. Bug kill models (MPB, DFB)
#   2. Scale DG to FINT-year basis
#   3. Pest / disease couplings (mistletoe, TM, BWE, fire, blister rust, root disease)
#   4. UPDATE — apply increments to tree records
#   5. Density stats (DENSE), cover model
#   6. Regeneration establishment (ESNUTR)
#   7. Crown/volume model update
#   8. Percentile distributions

"""
    GRADD(debug, ipmodi, ltmgo, lmpbgo, ldfbgo, lbwego, lcvatv)

Apply growth increments and update all tree records for the current cycle.
Called from TREGRO after GRINCR.
"""
function GRADD(debug::Bool, ipmodi::Int32,
               ltmgo::Bool, lmpbgo::Bool, ldfbgo::Bool,
               lbwego::Bool, lcvatv::Bool)
    spcnt = zeros(Float32, MAXSP, 3)

    istopres = fvsGetRestartCode()
    if debug
        @printf(io_units[JOSTND], "\n IN GRADD, NPLT=%s; ICYC=%2d; ISTOPRES=%2d\n",
                NPLT, ICYC, istopres)
    end
    if istopres == Int32(5); @goto label_57; end
    if istopres == Int32(6); @goto label_97; end

    # -------------------------------------------------------------------------
    # 1. Bug kill models
    # -------------------------------------------------------------------------
    if ipmodi == Int32(1) && lmpbgo
        if debug; @printf(io_units[JOSTND], " CALLING MPBCUP, CYCLE=%2d\n", ICYC); end
        MPBCUP()
    end

    DFBWIN(ldfbgo)
    if ipmodi == Int32(1) && ldfbgo; DFBDRV(); end

    # -------------------------------------------------------------------------
    # 2. Scale DG from YR-basis to FINT-year basis
    # -------------------------------------------------------------------------
    if ITRN > Int32(0) && FINT != YR
        scale = FINT / YR
        for i in Int32(1):ITRN
            is   = ISP[i]
            d    = DBH[i]
            bark = BRATIO(is, d, HT[i])
            if DG[i] > Float32(0.0)
                dds    = (DG[i] * (Float32(2.0) * bark * d + DG[i])) * scale
                DG[i]  = sqrt((d * bark)^2 + dds) - bark * d
            else
                DG[i] = Float32(0.0)
            end
        end
    end

    # -------------------------------------------------------------------------
    # 3. Disease / pest couplings
    # -------------------------------------------------------------------------
    MISTOE()

    if ipmodi == Int32(1) && ltmgo
        if debug; @printf(io_units[JOSTND], " CALLING TMCOUP, CYCLE=%2d\n", ICYC); end
        TMCOUP()
    end

    if ipmodi == Int32(1) && lbwego
        if debug; @printf(io_units[JOSTND], " CALLING BWECUP, CYCLE=%2d\n", ICYC); end
        BWECUP()
    end

    if debug; @printf(io_units[JOSTND], " CALLING FMMAIN, CYCLE=%2d\n", ICYC); end
    FMMAIN()
    irtncd = fvsGetRtnCode()
    if irtncd != Int32(0); return nothing; end
    FMKILL(Int32(1))

    BRTREG()
    RDTREG()
    FMKILL(Int32(2))

    # Detect SIMFIRE keyword this cycle → set LFIRE
    if ICYC <= Int32(0)
        iyr1 = IY[1]; iyr2 = IY[1]
    else
        iyr1 = IY[ICYC]; iyr2 = IY[ICYC+1]
    end
    ifires_r = Ref(Int32(0)); idt_r = Ref(Int32(0)); istat_r = Ref(Int32(0))
    kode_r   = Ref(Int32(0)); nprms_r = Ref(Int32(0))
    OPSTUS(Int32(2506), Int(iyr1), Int(iyr2), 0, ifires_r, idt_r, nprms_r, istat_r, kode_r)
    if istat_r[] > Int32(0) && idt_r[] >= iyr1 && idt_r[] <= iyr2
        global LFIRE = true
    end

    HTGSTP()

    if debug; @printf(io_units[JOSTND], " CALLING SVMORT, CYCLE=%2d\n", ICYC); end
    SVMORT(Int32(0), WK2, IY[ICYC])

    # Stop-point 5
    istopres2 = fvsStopPoint(Int32(5))
    if istopres2 != Int32(0); return nothing; end
    irtncd = fvsGetRtnCode()
    if irtncd != Int32(0); return nothing; end

    @label label_57

    # -------------------------------------------------------------------------
    # 4. Apply increments
    # -------------------------------------------------------------------------
    if debug; @printf(io_units[JOSTND], " CALLING UPDATE, CYCLE=%2d\n", ICYC); end
    UPDATE()

    # Resort on DBH
    if debug; @printf(io_units[JOSTND], " CALLING RDPSRT, CYCLE=%2d\n", ICYC); end
    if ITRN > Int32(0)
        RDPSRT(ITRN, DBH, IND, true)
    end

    # Density stats
    if debug; @printf(io_units[JOSTND], " CALLING DENSE, CYCLE=%2d\n", ICYC); end
    DENSE()

    # Cover model
    CVGO(lcvatv)
    if debug && lcvatv
        @printf(io_units[JOSTND], " CALLING CVBROW, CYCLE=%2d\n", ICYC)
    end
    if lcvatv; CVBROW(false); end

    # Increment birth ages
    for i in Int32(1):ITRN
        ABIRTH[i] += FINT
    end

    # Stop-point 6
    istopres3 = fvsStopPoint(Int32(6))
    if istopres3 != Int32(0); return nothing; end
    irtncd = fvsGetRtnCode()
    if irtncd != Int32(0); return nothing; end

    @label label_97

    # -------------------------------------------------------------------------
    # 5. Establishment
    # -------------------------------------------------------------------------
    if debug; @printf(io_units[JOSTND], " CALLING CLAUESTB, CYCLE=%2d\n", ICYC); end
    CLAUESTB()

    if debug; @printf(io_units[JOSTND], " CALLING ESNUTR, CYCLE=%2d\n", ICYC); end
    ESNUTR()

    if debug; @printf(io_units[JOSTND], " CALLING SVESTB, CYCLE=%2d\n", ICYC); end
    SVESTB(Int32(1))

    ECCALC(IY, ICYC, JSP, MGMID, NPLT, ITITLE)

    if debug; @printf(io_units[JOSTND], " CALLING DENSE, CYCLE=%2d\n", ICYC); end
    DENSE()

    # -------------------------------------------------------------------------
    # 6. Crown / volume updates
    # -------------------------------------------------------------------------
    if debug
        @printf(io_units[JOSTND], " CALLING CROWN, CYCLE=%2d  NPLT= %s\n", ICYC, NPLT)
    end
    CROWN()
    CWIDTH()

    if debug && lcvatv
        @printf(io_units[JOSTND], " CALLING CVCNOP, CYCLE=%3d\n", ICYC)
    end
    if lcvatv; CVCNOP(false); end

    # Save crown ratios
    if ITRN > Int32(0)
        OLDPCT[1:ITRN] .= PCT[1:ITRN]

        # Accumulate TPA by species and tree class
        for i in Int32(1):MAXSP
            spcnt[i,1] = Float32(0.0)
            spcnt[i,2] = Float32(0.0)
            spcnt[i,3] = Float32(0.0)
        end
        for i in Int32(1):ITRN
            is = ISP[i]; im = IMC[i]
            spcnt[is, im] += PROB[i]
        end
    end

    # -------------------------------------------------------------------------
    # 7. Percentile distributions
    # -------------------------------------------------------------------------
    ONTCUR[7] = PCTILE(Int(ITRN), IND, PROB, WK3)
    DIST(Int(ITRN), ONTCUR, WK3)
    COMP(OSPCT, IOSPCT, spcnt)

    # Scale volumes to per-acre
    if ITRN > Int32(0)
        for i in Int32(1):ITRN
            CFV[i]         *= PROB[i]
            BFV[i]         *= PROB[i]
            MCFV[i]        *= PROB[i]
            SCFV[i]        *= PROB[i]
            ABVGRD_BIO[i]  *= PROB[i]
            MERCH_BIO[i]   *= PROB[i]
            CUBSAW_BIO[i]  *= PROB[i]
            FOLI_BIO[i]    *= PROB[i]
            ABVGRD_CARB[i] *= PROB[i]
            MERCH_CARB[i]  *= PROB[i]
            CUBSAW_CARB[i] *= PROB[i]
            FOLI_CARB[i]   *= PROB[i]
        end
    end

    OCVCUR[7]      = PCTILE(Int(ITRN), IND, CFV,        WK3); DIST(Int(ITRN), OCVCUR, WK3)
    OBFCUR[7]      = PCTILE(Int(ITRN), IND, BFV,        WK3); DIST(Int(ITRN), OBFCUR, WK3)
    OMCCUR[7]      = PCTILE(Int(ITRN), IND, MCFV,       WK3); DIST(Int(ITRN), OMCCUR, WK3)
    OSCCUR[7]      = PCTILE(Int(ITRN), IND, SCFV,       WK3); DIST(Int(ITRN), OSCCUR, WK3)

    if LFIANVB
        OAGBIOCUR[7]   = PCTILE(Int(ITRN), IND, ABVGRD_BIO,  WK3); DIST(Int(ITRN), OAGBIOCUR, WK3)
        OMERBIOCUR[7]  = PCTILE(Int(ITRN), IND, MERCH_BIO,   WK3); DIST(Int(ITRN), OMERBIOCUR, WK3)
        OCSAWBIOCUR[7] = PCTILE(Int(ITRN), IND, CUBSAW_BIO,  WK3); DIST(Int(ITRN), OCSAWBIOCUR, WK3)
        OFOLIBIO[7]    = PCTILE(Int(ITRN), IND, FOLI_BIO,    WK3); DIST(Int(ITRN), OFOLIBIO, WK3)
        OAGCARBCUR[7]  = PCTILE(Int(ITRN), IND, ABVGRD_CARB, WK3); DIST(Int(ITRN), OAGCARBCUR, WK3)
        OMERCARBCUR[7] = PCTILE(Int(ITRN), IND, MERCH_CARB,  WK3); DIST(Int(ITRN), OMERCARBCUR, WK3)
        OCSAWCARBCUR[7]= PCTILE(Int(ITRN), IND, CUBSAW_CARB, WK3); DIST(Int(ITRN), OCSAWCARBCUR, WK3)
        OFOLICARB[7]   = PCTILE(Int(ITRN), IND, FOLI_CARB,   WK3); DIST(Int(ITRN), OFOLICARB, WK3)
    end

    # Divide volumes back to per-tree
    if ITRN > Int32(0)
        for i in Int32(1):ITRN
            if PROB[i] > Float32(0.0)
                CFV[i]         /= PROB[i]
                MCFV[i]        /= PROB[i]
                SCFV[i]        /= PROB[i]
                BFV[i]         /= PROB[i]
                if LFIANVB
                    ABVGRD_BIO[i]  /= PROB[i]
                    MERCH_BIO[i]   /= PROB[i]
                    CUBSAW_BIO[i]  /= PROB[i]
                    FOLI_BIO[i]    /= PROB[i]
                    ABVGRD_CARB[i] /= PROB[i]
                    MERCH_CARB[i]  /= PROB[i]
                    CUBSAW_CARB[i] /= PROB[i]
                    FOLI_CARB[i]   /= PROB[i]
                end
            end
        end
    end

    return nothing
end

# All stubs for GRADD call sites are now in base/extstubs.jl or their own .jl files.
