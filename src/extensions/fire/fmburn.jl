# SUBROUTINE FMBURN(IYR, FMD, LNMOUT) — fire behavior and effects driver
# Translated from: fmburn.f (624 lines)
#
# Called from FMMAIN once per cycle. Determines fire environment, selects fuel
# model, computes flame length/scorch height, calls crown fire model, then
# calls FMEFF (tree mortality) and FMCONS (fuel consumption + smoke).
#
# SN-variant note: crown fire model (FMCFIR) is bypassed; FIRTYPE=3/CRBURN=0.

function FMBURN(iyr::Integer, fmd::Integer, lnmout::Bool)
    # fmd is an output in Fortran (set by FMCFMD/FMCFMD3 internally); use a local ref
    local fmd_ref = Ref(Int32(fmd))
    local debug::Bool = false
    debug = DBCHK(false, "FMBURN", Int32(6), ICYC)
    if debug
        @printf(io_units[Int32(JOSTND)], " FMBURN CYCLE=%2d IYR=%5d\n", ICYC, iyr)
    end

    # Check for SIMFIRE keyword (2506) — just to note if any conditions set
    local icond::Int32 = Int32(0)
    local ntodo_ref = Ref(Int32(0))
    OPFIND(Int32(1), Int32[2506], ntodo_ref)
    if ntodo_ref[] > 0
        for ift in 1:ntodo_ref[]
            local jyr_ref   = Ref(Int32(0))
            local iactk_ref = Ref(Int32(0))
            local nprm_ref  = Ref(Int32(0))
            local cprms     = zeros(Float32, 6)
            OPGET(Int32(ift), Int32(3), jyr_ref, iactk_ref, nprm_ref, cprms)
            icond = Int32(1)
        end
    end

    # Check for DROUGHT keyword (2529)
    OPFIND(Int32(1), Int32[2529], ntodo_ref)
    if ntodo_ref[] > 0
        for jdo in 1:ntodo_ref[]
            local jyr2_ref   = Ref(Int32(0))
            local iactk2_ref = Ref(Int32(0))
            local nprm2_ref  = Ref(Int32(0))
            local dprms      = zeros(Float32, 1)
            OPGET(Int32(jdo), Int32(1), jyr2_ref, iactk2_ref, nprm2_ref, dprms)
            OPDONE(Int32(jdo), Int32(iyr))
            global IDRYB = jyr2_ref[]
            global IDRYE = Int32(Float32(jyr2_ref[]) + dprms[1] - 1.0f0)
        end
    end

    # Check for FUELDEFS keyword (2539) — user-specified fuel model parameters
    OPFIND(Int32(1), Int32[2539], ntodo_ref)
    if ntodo_ref[] > 0
        for jdo in 1:ntodo_ref[]
            local jyr3_ref   = Ref(Int32(0))
            local iactk3_ref = Ref(Int32(0))
            local nprm3_ref  = Ref(Int32(0))
            local prms = zeros(Float32, 13)
            OPGET(Int32(jdo), Int32(13), jyr3_ref, iactk3_ref, nprm3_ref, prms)

            local lok::Bool = true
            local ifmd::Int32 = Int32(prms[1])
            if ifmd < 1 || ifmd > MXDFMD; lok = false; end

            if lok
                # Validate/copy surface-to-volume ratios
                local xsur = zeros(Float32, 2, 3)
                local sumps::Float32 = 0.0f0
                for i in 2:4
                    xsur[1, i-1] = prms[i] < 0f0 ? Float32(SURFVL[ifmd, 1, i-1]) : prms[i]
                end
                xsur[2, 1] = prms[5]  < 0f0 ? Float32(SURFVL[ifmd, 2, 1]) : prms[5]
                xsur[2, 2] = prms[12] < 0f0 ? Float32(SURFVL[ifmd, 2, 2]) : prms[12]
                for i in 1:2, j in 1:3; sumps += xsur[i, j]; end
                if sumps <= 0.0001f0; lok = false; end

                if lok
                    # Validate/copy fuel model loadings
                    local xfml = zeros(Float32, 2, 3)
                    for i in 6:8
                        xfml[1, i-5] = prms[i] < 0f0 ? FMLOAD[ifmd, 1, i-5] : prms[i]
                    end
                    xfml[2, 1] = prms[9]  < 0f0 ? FMLOAD[ifmd, 2, 1] : prms[9]
                    xfml[2, 2] = prms[13] < 0f0 ? FMLOAD[ifmd, 2, 2] : prms[13]
                    local indd::Int = sum(xfml[1, i] > 0f0 ? 1 : 0 for i in 1:3)
                    local inl::Int  = sum(xfml[2, i] > 0f0 ? 1 : 0 for i in 1:3)
                    if indd <= 0 && inl <= 0; lok = false; end

                    if lok
                        local xdep::Float32 = prms[10] < 0f0 ? FMDEP[ifmd] : prms[10]
                        if xdep < 0f0; lok = false; end

                        if lok
                            local xext::Float32 = prms[11] < 0f0 ? MOISEX[ifmd] : prms[11]
                            if xext < 0f0 || xext > 1.0f0; lok = false; end

                            if lok
                                for i in 1:2, j in 1:3
                                    SURFVL[ifmd, i, j] = Int32(xsur[i, j])
                                    FMLOAD[ifmd, i, j] = xfml[i, j]
                                end
                                FMDEP[ifmd]  = xdep
                                MOISEX[ifmd] = xext
                                OPDONE(Int32(jdo), Int32(iyr))
                            else
                                OPDEL1(Int32(jdo))
                            end
                        else
                            OPDEL1(Int32(jdo))
                        end
                    else
                        OPDEL1(Int32(jdo))
                    end
                else
                    OPDEL1(Int32(jdo))
                end
            else
                OPDEL1(Int32(jdo))
            end
        end
    end

    # Load fuel model info
    FMCFMD3(Int32(iyr), fmd_ref)

    # Re-check for SIMFIRE keyword (2506) — get actual fire parameters
    icond = Int32(0)
    local swind::Float32  = 0.0f0
    local fmois_val::Int32 = Int32(1)
    local mkode::Int32     = Int32(1)
    local psburn::Float32  = 100.0f0

    OPFIND(Int32(1), Int32[2506], ntodo_ref)
    if ntodo_ref[] > 0
        for ift in 1:ntodo_ref[]
            local jyr_f = Ref(Int32(0))
            local iak_f = Ref(Int32(0))
            local np_f  = Ref(Int32(0))
            local cp    = zeros(Float32, 6)
            OPGET(Int32(ift), Int32(6), jyr_f, iak_f, np_f, cp)
            OPDONE(Int32(ift), Int32(iyr))
            swind     = cp[1]
            fmois_val = Int32(cp[2])
            global ATEMP    = Int32(cp[3])
            mkode     = Int32(round(cp[4]))
            psburn    = cp[5]
            global BURNSEAS = Int32(round(cp[6]))
            icond = Int32(1)
        end
    end

    if icond == 0
        swind     = 20.0f0
        global ATEMP    = Int32(70)
        fmois_val = Int32(1)
        mkode     = Int32(1)
        psburn    = 100.0f0
        global BURNSEAS = Int32(1)
    end

    if debug
        @printf(io_units[Int32(JOSTND)], " FMBURN, ICOND=%3d COVTYP=%4d LFLBRN=%s\n",
                icond, COVTYP, LFLBRN)
    end

    if icond == 0 || COVTYP <= 0
        if !LFLBRN
            FMFOUT(Int32(iyr), Float32(0.0), Int32(0), Int32(-1), "  NONE  ")
        end
        return
    end

    # FLAMEADJ keyword (2507) — user-specified flame length / crown burn fraction
    local iftype::Int32    = Int32(0)
    local flame::Float32   = -1.0f0
    local flmult::Float32  = 1.0f0
    local usrfl::Bool      = false
    local cftmp::String    = "*NOT_SET"

    OPFIND(Int32(1), Int32[2507], ntodo_ref)
    if ntodo_ref[] > 0
        for ifc in 1:ntodo_ref[]
            local jyr_a = Ref(Int32(0))
            local iak_a = Ref(Int32(0))
            local np_a  = Ref(Int32(0))
            local fp    = zeros(Float32, 4)
            OPGET(Int32(ifc), Int32(4), jyr_a, iak_a, np_a, fp)
            OPDONE(Int32(ifc), Int32(iyr))
            flame  = fp[2]
            flmult = fp[1]
            global CRBURN = fp[3]
            if np_a[] >= 4
                global SCH = fp[4]
            else
                global SCH = -1.0f0
            end
            if CRBURN > -1.0f0; global CRBURN = CRBURN * 0.01f0; end
            cftmp  = "USER_DEF"
            iftype = Int32(1)
            usrfl  = flame > 0.0f0
        end
    end

    if iftype == 0
        flame        = -1.0f0
        flmult       = 1.0f0
        global CRBURN = -1.0f0
        global SCH    = -1.0f0
        usrfl         = false
        cftmp         = "*NOT_SET"
    end

    # MOISTURE keyword (2505) — user-supplied fuel moistures
    OPFIND(Int32(1), Int32[2505], ntodo_ref)
    if ntodo_ref[] > 0
        for jdo_m in 1:ntodo_ref[]
            local jyr_m = Ref(Int32(0))
            local iak_m = Ref(Int32(0))
            local np_m  = Ref(Int32(0))
            local mp    = zeros(Float32, 7)
            OPGET(Int32(jdo_m), Int32(7), jyr_m, iak_m, np_m, mp)
            OPDONE(Int32(jdo_m), IY[ICYC])
            fmois_val  = Int32(0)
            MOIS[1, 1] = mp[1] * 0.01f0
            MOIS[1, 2] = mp[2] * 0.01f0
            MOIS[1, 3] = mp[3] * 0.01f0
            MOIS[1, 4] = mp[4] * 0.01f0
            MOIS[1, 5] = mp[5] * 0.01f0
            MOIS[2, 1] = mp[6] * 0.01f0
            MOIS[2, 2] = mp[7] * 0.01f0
        end
    end

    # Set fuel moisture values
    FMMOIS(fmois_val, MOIS)

    # Wind correction for canopy closure
    local wmult::Float32 = ALGSLP(PERCOV, CANCLS, CORFAC, Int32(4))
    global FWIND = swind * wmult

    # In SN (and other variants with IFLOGIC=0), recompute fuel model with wind/moisture known
    if IFLOGIC == 0 && VARACD ∈ ("CR","CS","LS","SN","TT","UT")
        FMCFMD(Int32(iyr), fmd_ref)
    end

    if debug
        @printf(io_units[Int32(JOSTND)], " FMBURN, SWIND=%7.3f FWIND=%7.3f WMULT=%7.3f PERCOV=%7.3f\n",
                swind, FWIND, wmult, PERCOV)
    end

    # If user specified SCH, FLAME, and CRBURN, skip fire behavior calculations
    if SCH > -1.0f0 && flame > -1.0f0 && CRBURN > -1.0f0
        cftmp = "USER_DEF"
        if SCH > PBSCOR; global BURNYR = Int32(iyr); end
        if CRBURN > 0.0f0
            global FIRTYPE = CRBURN < 100.0f0 ? Int32(2) : Int32(1)
        else
            global FIRTYPE = Int32(3)
        end
        @goto label_490
    end

    # Compute fire behavior (Byram fireline intensity, flame length)
    local oldfl::Float32  = 0.0f0
    local byram::Float32  = 0.0f0
    local hpa::Float32    = 0.0f0
    local irtncd_ref = Ref(Int32(0))
    local finten::Float32 = 0.0f0

    if flame <= 0.0f0
        local byram_ref = Ref(Float32(0))
        local flame_ref = Ref(Float32(0))
        local hpa_ref   = Ref(Float32(0))
        FMFINT(Int32(iyr), byram_ref, flame_ref, Int32(1), hpa_ref, Int32(1))
        fvsGetRtnCode(irtncd_ref)
        if irtncd_ref[] != 0; return; end
        byram = byram_ref[]
        flame = flame_ref[]
        hpa   = hpa_ref[]
        oldfl = flame
        if flmult != 1.0f0; flame = oldfl * flmult; end
    else
        local byram2_ref = Ref(Float32(0))
        local oldfl_ref  = Ref(Float32(0))
        local hpa2_ref   = Ref(Float32(0))
        FMFINT(Int32(iyr), byram2_ref, oldfl_ref, Int32(1), hpa2_ref, Int32(1))
        fvsGetRtnCode(irtncd_ref)
        if irtncd_ref[] != 0; return; end
        byram = byram2_ref[]
        hpa   = hpa2_ref[]
        oldfl = 0.0f0
    end

    # Recalculate Byram if flame was modified
    if flame != oldfl
        byram = 60.0f0 * (flame / 0.45f0)^(1.0f0 / 0.46f0)
    end

    # Compute scorch height
    byram = byram / 60.0f0
    global SCH = (63.0f0 / (140.0f0 - Float32(ATEMP))) *
                 (byram^(7.0f0/6.0f0) / (byram + FWIND^3.0f0)^0.5f0)

    if FLAG[1] == 1; @goto label_500; end

    if SCH > PBSCOR; global BURNYR = Int32(iyr); end

    # Crown fire / fire type determination
    local crrate::Float32 = 0.0f0
    local crtcbh::Float32 = 0.0f0

    if debug
        @printf(io_units[Int32(JOSTND)], " FMBURN MAY CALL FMCFIR,IFTYPE=%2d CRBURN=%.1f\n",
                iftype, CRBURN)
    end

    if VARACD == "SN" || VARACD == "CS"
        # SN/CS: no crown fire model; always surface fire
        global FIRTYPE = Int32(3)
        global CRBURN  = Float32(0.0)
        cftmp          = "SURFACE"
    else
        if CRBURN == -1.0f0 || !usrfl
            local ucrburn::Float32 = CRBURN
            local lcftmp::Bool = (cftmp == "USER_DEF")
            local tmp2 = zeros(Float32, 3)
            local tmp3 = zeros(Float32, 3)
            local cftmp_ref = Ref{String}(cftmp)
            FMCFIR(Int32(iyr), Int32(1), wmult, Int32(swind), cftmp_ref, tmp2, tmp3, Float32(hpa))
            fvsGetRtnCode(irtncd_ref)
            if irtncd_ref[] != 0; return; end
            cftmp = cftmp_ref[]
            if ucrburn >= 0.0f0; global CRBURN = ucrburn; end
            if lcftmp; cftmp = "USER_DEF"; end
        else
            if CRBURN > 0.0f0
                global FIRTYPE = CRBURN < 100.0f0 ? Int32(2) : Int32(1)
            else
                global FIRTYPE = Int32(3)
            end
        end
    end

    # Adjust flame length and scorch height for crown fire contribution
    if CRBURN > 0.0f0
        if !usrfl
            finten = (hpa + TCLOAD * 7744.8f0 * CRBURN) * RFINAL / 60.0f0
            local flb::Float32 = 0.45f0 * finten^0.46f0
            local flt::Float32 = 0.2f0  * finten^0.667f0
            flame = flb + CRBURN * (flt - flb)
            if flmult != 1.0f0; flame *= flmult; end
        end

        if usrfl || flmult != 1.0f0
            # Iterative solve for intensity given combined flame length
            local tmpint::Float32  = CRBURN * (flame/0.2f0)^(1f0/0.667f0) +
                                     (1f0 - CRBURN) * (flame/0.45f0)^(1f0/0.46f0)
            local maxint::Float32  = max((flame/0.21f0)^(1f0/0.667f0), (flame/0.45f0)^(1f0/0.46f0))
            local minint::Float32  = min((flame/0.21f0)^(1f0/0.667f0), (flame/0.45f0)^(1f0/0.46f0))
            finten = tmpint
            for ii in 1:200
                local flb2::Float32 = 0.45f0 * tmpint^0.46f0
                local flt2::Float32 = 0.2f0  * tmpint^0.667f0
                local tmpflame::Float32 = flb2 + CRBURN * (flt2 - flb2)
                if tmpflame >= flame * 0.99f0 && tmpflame <= flame * 1.01f0
                    finten = tmpint
                    break
                elseif tmpflame < flame
                    minint = tmpint
                    tmpint = 0.5f0 * tmpint + 0.5f0 * maxint
                else
                    maxint = tmpint
                    tmpint = 0.5f0 * tmpint + 0.5f0 * minint
                end
                if ii == 200; finten = tmpint; end
            end
        end

        global SCH = (63.0f0 / (140.0f0 - Float32(ATEMP))) *
                     (finten^(7.0f0/6.0f0) / (finten + FWIND^3.0f0)^0.5f0)
    end

    @label label_490

    # Update live fuels if fire occurred in SN variant
    if BURNYR == iyr && VARACD == "SN"
        FMCBA(Int32(iyr), Int32(0))
    end

    # Soil heating
    FMSOILHEAT(Int32(iyr), lnmout)

    # Tree mortality from fire effects
    local pmrt_ref   = Ref(Float32(0))
    local pvolkl_ref = Ref(Float32(0))
    FMEFF(Int32(iyr), Int32(fmd_ref[]), flame, Int32(0), pmrt_ref, pvolkl_ref, mkode, psburn)

    # Fuel consumption and smoke
    local psmoke_ref2 = Ref(Float32(0))
    FMCONS(fmois_val, Int32(0), Float32(0.0), Int32(iyr), Int32(0), psmoke_ref2, psburn)

    @label label_500

    # Print fire reports
    local ifire::Int32 = LFLBRN ? Int32(2) : Int32(1)

    if debug
        @printf(io_units[Int32(JOSTND)], " FMBURN CALLING FMFOUT, FLAME=%7.2f FMD=%7d IFIRE=%2d CFTMP=%s\n",
                flame, fmd_ref[], ifire, cftmp)
    end

    if lnmout
        FMFOUT(Int32(iyr), flame, Int32(fmd_ref[]), ifire, cftmp)
    end

    return nothing
end
