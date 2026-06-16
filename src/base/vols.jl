# vols.jl — Tree volume calculations and distribution statistics
# Translated from: base/vols.f (507 lines)
#
# VOLS computes total cubic, merchantable cubic, saw-log cubic, and board-foot
# volumes per tree, corrects for defect, loads CFV/BFV/MCFV/SCFV arrays,
# compiles species-class composition arrays, and drives PCTILE/DIST/COMP.
#
# Two-pass design: IPASS=1 for live trees (1..ITRN), IPASS=2 for cycle-0
# dead trees (IREC2..MAXTRE).

function VOLS()
    debug = DBCHK(false, "VOLS", Int32(4), ICYC)

    # Initialize HT2TD (height to top) for all trees, both merch standards
    for j in 1:2, i in 1:Int(MAXTRE)
        HT2TD[i, j] = Float32(0)
    end

    # Local species-tree-class accumulators (cleared at start of each call)
    spccc = zeros(Float32, Int(MAXSP), 3)  # total cubic by sp × class
    spcac = zeros(Float32, Int(MAXSP), 3)  # cubic accretion by sp × class
    spcmc = zeros(Float32, Int(MAXSP), 3)  # merch cubic by sp × class
    spcsc = zeros(Float32, Int(MAXSP), 3)  # saw-log cubic by sp × class
    spcbv = zeros(Float32, Int(MAXSP), 3)  # board-foot by sp × class

    # DBH class breakpoints for defect interpolation (9 values, 0..40)
    dbhcls = Float32[0, 5, 10, 15, 20, 25, 30, 35, 40]

    VOLKEY(debug)

    # Enforce minimum merchantable DBH for board-foot calcs
    for j in 1:Int(MAXSP)
        if BFMIND[j] < Float32(2); BFMIND[j] = Float32(2); end
        if BFTOPD[j] < Float32(2); BFTOPD[j] = Float32(2); end
    end

    ipass = 1
    ilow  = 1
    ihi   = Int(ITRN)

    # Two-pass loop: pass 1 = live trees, pass 2 = dead trees
    while true
        # Skip tree loop on pass 1 if no live trees
        if ipass == 1 && Int(ITRN) <= 0
            @goto label_205
        end

        for i in ilow:ihi
            WK5[i] = Float32(0)
            p = Float32(PROB[i])
            p <= Float32(0) && continue

            ispc_i = Int(ISP[i])
            d_val  = Float32(DBH[i])
            h_val  = Float32(HT[i])
            im_i   = Int(IMC[i])

            livedead = im_i >= 6 ? "D" : "L"

            # Topkill: if truncated, substitute normal height
            tkill = h_val >= Float32(4.5) && ITRUNC[i] > Int32(0)
            if tkill; h_val = Float32(NORMHT[i]) / Float32(100); end

            bark = BRATIO(ispc_i, d_val, h_val)
            if !LSTART; d_val = d_val + Float32(DG[i]) / bark; end
            d2h = d_val * d_val * h_val

            # Initialize volume estimates
            vn = Float32(0); vm = Float32(0)
            tcf  = Float32(0); mcf  = Float32(0)
            scf  = Float32(0); scfv = Float32(0)
            vmax = Float32(0); bfmax = Float32(0); bbfv = Float32(0)
            biomas = zeros(Float32, 15)
            lcone  = false; ctkflg = false; btkflg = false

            if debug
                @printf(io_units[Int(JOSTND)], " CUBIC SECTION, I,ISPC,METHC= %d %d %d\n",
                        i, ispc_i, METHC[ispc_i])
            end

            # --------------- Cubic volume ---------------
            it = i
            methc_i = Int(METHC[ispc_i])
            if (methc_i == 6 || methc_i == 10) ||
               (methc_i == 5 && VARACD ∈ ("CS", "LS", "NE"))
                tcf_r = Ref(tcf); mcf_r = Ref(mcf); scf_r = Ref(scf)
                bbfv_r = Ref(bbfv); vmax_r = Ref(vmax); bfmax_r = Ref(bfmax)
                ctkflg_r = Ref(ctkflg); btkflg_r = Ref(btkflg)
                NATCRS(tcf_r, mcf_r, scf_r, bbfv_r, ispc_i, d_val, h_val, tkill,
                       Int(ICR[i]), bark, Int(ITRUNC[i]), vmax_r, bfmax_r,
                       CULL[i], DECAYCD[i], WDLDSTEM[i], biomas, livedead,
                       ctkflg_r, btkflg_r, it)
                tcf = tcf_r[]; mcf = mcf_r[]; scf = scf_r[]
                bbfv = bbfv_r[]; vmax = vmax_r[]; bfmax = bfmax_r[]
                ctkflg = ctkflg_r[]; btkflg = btkflg_r[]
            elseif methc_i == 8
                vn_r = Ref(vn); vm_r = Ref(vm)
                vmax_r = Ref(vmax); lcone_r = Ref(lcone); ctkflg_r = Ref(ctkflg)
                OCFVOL(vn_r, vm_r, ispc_i, d_val, h_val, tkill, bark,
                       Int(ITRUNC[i]), vmax_r, lcone_r, ctkflg_r, it)
                vn = vn_r[]; vm = vm_r[]; vmax = vmax_r[]
                lcone = lcone_r[]; ctkflg = ctkflg_r[]
                tcf = vn; mcf = vm
            else
                vn_r = Ref(vn); vm_r = Ref(vm)
                vmax_r = Ref(vmax); lcone_r = Ref(lcone); ctkflg_r = Ref(ctkflg)
                CFVOL(ispc_i, d_val, h_val, d2h, vn_r, vm_r, vmax_r, tkill,
                      lcone_r, bark, Int(ITRUNC[i]), ctkflg_r)
                vn = vn_r[]; vm = vm_r[]; vmax = vmax_r[]
                lcone = lcone_r[]; ctkflg = ctkflg_r[]
                tcf = vn; mcf = vm
            end

            # Topkill correction for cubic volume
            if VEQNNC[ispc_i][1:3] != "NVB" && !LFIANVB &&
               (ctkflg && tkill && vmax > Float32(0))
                tcf_r = Ref(tcf); mcf_r = Ref(mcf); scf_r = Ref(scf)
                CFTOPK(ispc_i, d_val, h_val, tcf_r, mcf_r, scf_r, vmax, lcone, bark, Int(ITRUNC[i]))
                tcf = tcf_r[]; mcf = mcf_r[]; scf = scf_r[]
            end

            MCFV[i] = mcf
            if VARACD ∈ ("CS", "LS", "NE", "SN") || LFIANVB
                SCFV[i] = scf
            end

            # FIAVBC biomass (LFIANVB path)
            if LFIANVB
                # Read FIA species code as integer
                ifiasp = 0
                try; ifiasp = parse(Int, strip(FIAJSP[ispc_i])); catch; end
                # Binary search in sorted WDBKWT (sorted by FIA code, col 1)
                carbfactor = Float32(0.5)
                let lo = 1, hi = Int(WDBKWT_TOTSPC)
                    while lo <= hi
                        mid = (lo + hi) >>> 1
                        code = Int(WDBKWT[mid, 1])
                        if code == ifiasp; carbfactor = Float32(WDBKWT[mid, 12]); break
                        elseif code < ifiasp; lo = mid + 1
                        else; hi = mid - 1
                        end
                    end
                end

                ABVGRD_BIO[i] = biomas[1]
                FOLI_BIO[i]   = biomas[13]
                ABVGRD_CARB[i]= biomas[15]
                FOLI_CARB[i]  = biomas[13] * Float32(0.5)
                MERCH_BIO[i]    = Float32(0)
                MERCH_CARB[i]   = Float32(0)
                CUBSAW_BIO[i]   = Float32(0)
                CUBSAW_CARB[i]  = Float32(0)

                if livedead == 'L' && DECAYCD[i] > Int32(0); DECAYCD[i] = Int32(0); end
                if DECAYCD[i] > Int32(0)
                    dc = Int(DECAYCD[i])
                    if dc == 1; carbfactor = ifiasp >= 300 ? Float32(0.47)  : Float32(0.501)
                    elseif dc == 2; carbfactor = ifiasp >= 300 ? Float32(0.473) : Float32(0.504)
                    elseif dc == 3; carbfactor = ifiasp >= 300 ? Float32(0.481) : Float32(0.506)
                    elseif dc == 4; carbfactor = ifiasp >= 300 ? Float32(0.48)  : Float32(0.52)
                    elseif dc == 5; carbfactor = ifiasp >= 300 ? Float32(0.472) : Float32(0.527)
                    end
                end
                CARB_FRAC[i] = carbfactor

                # Zero volume for non-commercial species
                noncom = ifiasp ∈ (62,63,65,66,69,106,133,134,143,321,322,475,803,810,814,843)
                if noncom
                    MCFV[i]       = Float32(0); SCFV[i]       = Float32(0)
                    MERCH_BIO[i]  = Float32(0); MERCH_CARB[i] = Float32(0)
                    CUBSAW_BIO[i] = Float32(0); CUBSAW_CARB[i]= Float32(0)
                else
                    if d_val >= Float32(DBHMIN[ispc_i])
                        MERCH_BIO[i]  = biomas[6] + biomas[8]
                        MERCH_CARB[i] = MERCH_BIO[i] * carbfactor
                    end
                    if d_val >= Float32(SCFMIND[ispc_i])
                        CUBSAW_BIO[i]  = biomas[6]
                        CUBSAW_CARB[i] = CUBSAW_BIO[i] * carbfactor
                    end
                end
            end

            # Accretion and species-class summary (live trees only)
            if ipass == 2; @goto label_15; end
            if !LSTART
                if CFV[i] > tcf
                    WK5[i] = Float32(0)
                else
                    WK5[i] = (tcf - CFV[i]) * p / Float32(FINT)
                end
                spcac[ispc_i, im_i] += WK5[i]
            end
            spccc[ispc_i, im_i] += tcf * p

            @label label_15

            # Load CFV and compute cubic defect correction
            CFV[i] = tcf
            icdf = Int32(0)

            temvol = if VARACD ∈ ("CS", "LS", "NE", "SN")
                MCFV[i] - SCFV[i]
            else
                MCFV[i]
            end

            if MCFV[i] > Float32(0) && LCVOLS
                dlieqn = round(Int32, ALGSLP(d_val, dbhcls, @view(CFDEFT[1:9, ispc_i]), 9) * Float32(100))
                if dlieqn > icdf; icdf = dlieqn; end
                if CFLA0[ispc_i] == Float32(0) && CFLA1[ispc_i] == Float32(1)
                    volcor = temvol
                else
                    volcor = exp(Float32(CFLA0[ispc_i]) + Float32(CFLA1[ispc_i]) * log(temvol))
                end
                if temvol == Float32(0); @goto label_25; end
                dllmod = round(Int32, ((temvol - volcor) / temvol) * Float32(100))
                if dllmod > icdf; icdf = dllmod; end
                @label label_25
                if icdf > Int32(99); icdf = Int32(99); end
                if icdf < Int32(0);  icdf = Int32(0);  end
            end

            # Cubic defect correction
            pulpv = Float32(0)
            if VARACD ∈ ("CS", "LS", "NE", "SN")
                if icdf < Int32(99)
                    pulpv = (MCFV[i] - SCFV[i]) * (Float32(1) - Float32(icdf)/Float32(100))
                end
            else
                if icdf < Int32(99)
                    MCFV[i] = MCFV[i] * (Float32(1) - Float32(icdf)/Float32(100))
                else
                    MCFV[i] = Float32(0)
                end
            end

            if VARACD ∈ ("CS", "LS", "NE", "SN") || LFIANVB
                if SCFV[i] > Float32(0); ECVOL(it, LOGDIA, LOGVOL, true); end
            else
                if MCFV[i] > Float32(0); ECVOL(it, LOGDIA, LOGVOL, true); end
            end

            # --------------- Board-foot volume ---------------
            BFV[i] = Float32(0)
            ibdf = Int32(DEFECT[i]) ÷ Int32(10000) - (Int32(DEFECT[i]) ÷ Int32(1000000)) * Int32(100)

            bfmind_i = Float32(BFMIND[ispc_i])
            bftopd_i = Float32(BFTOPD[ispc_i])
            skip_d   = d_val < bfmind_i || d_val <= bftopd_i

            if skip_d && SCFV[i] > Float32(0)
                @goto label_100
            elseif skip_d
                @goto label_150
            end

            if debug
                @printf(io_units[Int(JOSTND)], " BOARD SECTION, I,ISPC,D,H,METHB= %d %d %g %g %d\n",
                        i, ispc_i, d_val, h_val, METHB[ispc_i])
            end

            methb_i = Int(METHB[ispc_i])
            if ((VARACD ∈ ("NE", "CS", "LS")) && methb_i == 5) ||
                methb_i == 6 || methb_i == 9
                if methc_i == 6 || methc_i == 10
                    @goto label_100
                else
                    tcf_r2 = Ref(tcf); mcf_r2 = Ref(mcf); scf_r2 = Ref(scf)
                    bbfv_r2 = Ref(bbfv); vmax_r2 = Ref(vmax); bfmax_r2 = Ref(bfmax)
                    ctkflg_r2 = Ref(ctkflg); btkflg_r2 = Ref(btkflg)
                    NATCRS(tcf_r2, mcf_r2, scf_r2, bbfv_r2, ispc_i, d_val, h_val, tkill,
                           Int(ICR[i]), bark, Int(ITRUNC[i]), vmax_r2, bfmax_r2,
                           CULL[i], DECAYCD[i], WDLDSTEM[i], biomas, livedead,
                           ctkflg_r2, btkflg_r2, it)
                    tcf = tcf_r2[]; mcf = mcf_r2[]; scf = scf_r2[]
                    bbfv = bbfv_r2[]; vmax = vmax_r2[]; bfmax = bfmax_r2[]
                    ctkflg = ctkflg_r2[]; btkflg = btkflg_r2[]
                end
            elseif methb_i == 8
                it = i
                bbfv_r3 = Ref(bbfv); vmax_r3 = Ref(vmax); lcone_r3 = Ref(lcone)
                btkflg_r3 = Ref(btkflg)
                OBFVOL(bbfv_r3, ispc_i, d_val, h_val, tkill, bark, Int(ITRUNC[i]),
                       vmax_r3, lcone_r3, btkflg_r3, it)
                bbfv = bbfv_r3[]; vmax = vmax_r3[]
                lcone = lcone_r3[]; btkflg = btkflg_r3[]
            else
                bbfv_r4 = Ref(bbfv); lcone_r4 = Ref(lcone)
                bfmax_r4 = Ref(bfmax); btkflg_r4 = Ref(btkflg)
                BFVOL(ispc_i, d_val, h_val, d2h, bbfv_r4, tkill, lcone_r4, bark,
                      bfmax_r4, Int(ITRUNC[i]), btkflg_r4)
                bbfv = bbfv_r4[]; lcone = lcone_r4[]
                bfmax = bfmax_r4[]; btkflg = btkflg_r4[]
            end

            @label label_100
            # BF topkill correction
            if btkflg && tkill && bfmax > Float32(0)
                bbfv_r5 = Ref(bbfv)
                BFTOPK(ispc_i, d_val, h_val, bbfv_r5, lcone, bark, bfmax, Int(ITRUNC[i]))
                bbfv = bbfv_r5[]
            end
            BFV[i] = bbfv

            if BFV[i] > Float32(0) && LBVOLS
                dlieqn_b = round(Int32, ALGSLP(d_val, dbhcls, @view(BFDEFT[1:9, ispc_i]), 9) * Float32(100))
                if dlieqn_b > ibdf; ibdf = dlieqn_b; end
                if BFLA0[ispc_i] == Float32(0) && BFLA1[ispc_i] == Float32(1)
                    volcor_b = BFV[i]
                else
                    volcor_b = exp(Float32(BFLA0[ispc_i]) + Float32(BFLA1[ispc_i]) * log(BFV[i]))
                end
                dllmod_b = round(Int32, ((BFV[i] - volcor_b) / BFV[i]) * Float32(100))
                if dllmod_b > ibdf; ibdf = dllmod_b; end
                if ibdf > Int32(99); ibdf = Int32(99); end
                if ibdf < Int32(0);  ibdf = Int32(0);  end
            end

            # BF defect correction
            if ibdf < Int32(99)
                BFV[i]  = BFV[i] * (Float32(1) - Float32(ibdf)/Float32(100))
                if !LFIANVB; SCFV[i] = SCFV[i] * (Float32(1) - Float32(ibdf)/Float32(100)); end
            else
                BFV[i] = Float32(0)
                if !LFIANVB; SCFV[i] = Float32(0); end
            end

            if BFV[i] > Float32(0); ECVOL(it, LOGDIA, LOGVOL, false); end
            if BFV[i] < Float32(0); BFV[i] = Float32(0); end

            @label label_150
            # Recombine pulpwood + cubic sawlog for eastern variants
            if VARACD ∈ ("NE", "CS", "LS", "SN")
                MCFV[i] = pulpv + SCFV[i]
            end

            if ipass == 1
                spcbv[ispc_i, im_i] += BFV[i]  * p
                spcmc[ispc_i, im_i] += MCFV[i] * p
                spcsc[ispc_i, im_i] += SCFV[i] * p
            end

            # Store actual defect percentages used: coded as 11223344
            DEFECT[i] = (Int32(DEFECT[i]) ÷ Int32(10000)) * Int32(10000) +
                        icdf * Int32(100) + ibdf

            if debug
                @printf(io_units[Int(JOSTND)], " IN VOLS, I= %d DEFECT= %d\n", i, DEFECT[i])
                @printf(io_units[Int(JOSTND)],
                    " IN VOLS, I=%4d TCF=%15.6e MCFV=%15.6e\n WK5=%15.6e CFV=%15.6e\n",
                    i, tcf, MCFV[i], WK5[i], CFV[i])
            end
        end  # end for i in ilow:ihi

        @label label_205
        if ipass == 2; break; end  # goto label_250

        # Composition vectors for all volume standards
        COMP(OSPCV, IOSPCV, spccc)
        COMP(OSPBV, IOSPBV, spcbv)
        COMP(OSPMC, IOSPMC, spcmc)
        COMP(OSPSC, IOSPSC, spcsc)

        # Accretion distribution (bypass on initial call)
        if !LSTART
            COMP(OSPAC, IOSPAC, spcac)
            OACC[7] = PCTILE(Int(ITRN), IND, WK5, WK3)
            DIST(Int(ITRN), OACC, WK3)
        end

        # Setup pass 2 for cycle-0 dead trees
        if Int(IREC2) > Int(MAXTRE); break; end  # goto label_250
        ipass = 2
        ilow  = Int(IREC2)
        ihi   = Int(MAXTRE)
        # continue while → restart for-loop with dead trees
    end  # end while

    # label_250: debug output
    if debug
        for i in 1:10
            @printf(io_units[Int(JOSTND)], " LEAVING VOLS, I,CFV,BFV= %d %e %e\n",
                    i, CFV[i], BFV[i])
        end
    end
    return nothing
end

# ---------------------------------------------------------------------------
# Stubs for volume library functions (to be replaced by real translations)
# ---------------------------------------------------------------------------
# VOLKEY implemented in base/volkey.jl
# NATCRS implemented in base/fvsvol.jl
# CFVOL implemented in base/cfvol.jl
# OCFVOL implemented in base/fvsvol.jl
# BFVOL implemented in base/bfvol.jl
# OBFVOL implemented in base/fvsvol.jl
# NATCRS implemented in base/fvsvol.jl
# CFTOPK implemented in base/cftopk.jl
# BFTOPK implemented in base/bftopk.jl
ECVOL(it,logdia,logvol,f)                                       = nothing
# ALGSLP implemented in base/algslp.jl (loaded before vols.jl)

# WDBKWT — defined in base/wdbkwt_data.jl (2677 FIA species × 12 columns)
