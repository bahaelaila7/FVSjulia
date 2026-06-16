# fire/fmcfmd2.f — Dynamic fuel model selection (Joe Scott, Oct 2008)
# FMCFMD2: departure-index selection from defined fuel model set;
# FMCFMD3: wrapper — optionally builds FM89 from modelled loads (IFLOGIC=2),
#           calls FMPOCR, then dispatches to FMCFMD or FMCFMD2 per IFLOGIC.
# CROWNW(I,0)→CROWNW[i,1]; CROWNW(I,1)→CROWNW[i,2]; SURFVL is Int32.
# Called from: FMBURN, FMPOFL (FMCFMD3); FMCFMD3 (FMCFMD2)

function FMCFMD2(iyr::Integer, fmd_ref::Ref{Int32})
    debug = DBCHK("FMCFMD2", 7, ICYC)
    if debug
        @printf(get(io_units, Int32(JOSTND), stdout),
            " FMCFMD2 CYCLE= %2d IYR=%5d LUSRFM=%s\n", ICYC, iyr, LUSRFM)
    end

    if LUSRFM; return nothing; end

    # Initialize FMOD/FWT
    for i in 1:Int(MXFMOD)
        FMOD[i] = Int32(0)
        FWT[i]  = 0.0f0
    end

    local lfuelmon = fill(false, Int(MXDFMD))
    local fmsav    = zeros(Float32, Int(MXDFMD))
    local fmbd     = zeros(Float32, Int(MXDFMD))
    local fmffl    = zeros(Float32, Int(MXDFMD))
    local dindex   = fill(9999.0f0, Int(MXDFMD))
    local lfm      = zeros(Int32, Int(MXDFMD))
    local ifm      = zeros(Int32, Int(MXDFMD))
    local lowdi    = zeros(Float32, Int(MXDFMD))

    # Check for FMODLIST keyword (activity code 2550)
    local ntodo_ref = Ref(Int32(0))
    OPFIND(Int32(1), Int32[2550], ntodo_ref)
    local ntodo = Int(ntodo_ref[])
    if ntodo > 0
        for itodo in 1:ntodo
            local jyr_ref   = Ref(Int32(0))
            local iactk_ref = Ref(Int32(0))
            local nprm_ref  = Ref(Int32(0))
            local prms      = zeros(Float32, 8)
            OPGET(itodo, 2, jyr_ref, iactk_ref, nprm_ref, prms)
            OPDONE(itodo, iyr)
            IFUELMON[round(Int32, prms[1])] = round(Int32, prms[2])
        end
    end

    # Sum CWD categories by size class
    local currcwd = zeros(Float32, Int(MXFLCL))
    for i in 1:2, j in 1:Int(MXFLCL), k in 1:2, l in 1:4
        currcwd[j] += CWD[i, j, k, l]
    end

    local herb  = FLIVE[1]

    # Live woody: foliage + half 0-0.25" branchwood of understory trees
    local woody = 0.0f0
    for i in 1:Int(ITRN)
        if HT[i] <= CANMHT
            woody += (CROWNW[i, 1] + 0.5f0 * CROWNW[i, 2]) * FMPROB[i] * P2T
        end
    end
    woody += FLIVE[2]

    local fbffl = currcwd[1] + currcwd[10] + herb + woody

    # Fire carrying fuel type: 1=GR, 2=GS, 3=SH/TU, 4=TL/SB
    local ifcft::Int32
    if fbffl <= 0.0f0
        ifcft = Int32(4)
    else
        local livefrac = (herb + woody) / fbffl
        local herbfrac = herb / fbffl
        local herbrat  = woody > 0.0f0 ? herb / woody : 10.0f0

        if livefrac <= 0.20f0
            ifcft = Int32(4)
        elseif herbfrac >= 0.75f0
            ifcft = Int32(1)
        elseif herbrat > 2.0f0
            ifcft = Int32(1)
        elseif herbrat > 0.25f0
            ifcft = Int32(2)
        else
            ifcft = Int32(3)
        end
    end

    if debug
        @printf(get(io_units, Int32(JOSTND), stdout),
            " FMCFMD2 HERB= %7.2f WOODY=%7.2f FBFFL=%7.2f 10hr=%7.2f 100hr=%7.2f IFCFT=%3d\n",
            herb, woody, fbffl, currcwd[2], currcwd[3], ifcft)
    end

    # Arid vs humid variant
    local larid = !(VARACD in ("AK","CS","LS","NE","OP","PN","SN","WC","ON"))

    # Fuel model pick list based on arid/humid and IFCFT
    if larid
        if ifcft == 1
            for i in Int(MXDFMD):-1:1
                if i in 1:3 || i in (101,102,104,107); lfuelmon[i] = true; end
            end
        elseif ifcft == 2
            for i in 1:Int(MXDFMD)
                if i in 1:3 || i==5 || i in (102,104,121,122,141,142); lfuelmon[i] = true; end
            end
        elseif ifcft == 3
            for i in 1:Int(MXDFMD)
                if i in (2,4,5,7,10,141,142,145,147,161,164,165); lfuelmon[i] = true; end
            end
        else
            for i in 1:Int(MXDFMD)
                if i in (8,9) || i in 11:13 || i in 181:189 || i in 201:204; lfuelmon[i] = true; end
            end
        end
    else
        if ifcft == 1
            for i in 1:Int(MXDFMD)
                if i in 1:3 || i in (101,103,105,106,108,109); lfuelmon[i] = true; end
            end
        elseif ifcft == 2
            for i in 1:Int(MXDFMD)
                if i in 1:3 || i==7 || i in (103,105,106,123,124,141,143,144); lfuelmon[i] = true; end
            end
        elseif ifcft == 3
            for i in 1:Int(MXDFMD)
                if i in (2,4,5,7,10,143,144,146,148,149) || i in 161:163; lfuelmon[i] = true; end
            end
        else
            for i in 1:Int(MXDFMD)
                if i in (8,9) || i in 11:13 || i in 181:189 || i in 201:204; lfuelmon[i] = true; end
            end
        end
    end

    # Apply fuel model set filter
    if Int(IFMSET) == 0
        for i in 101:Int(MXDFMD); lfuelmon[i] = false; end
    elseif Int(IFMSET) == 1
        for i in 1:13; lfuelmon[i] = false; end
    end

    # Fuelbed bulk density and SAV
    local fdfl = currcwd[1] + currcwd[10]
    local fbbd = if fbffl > 0.0f0
        local wf = fdfl / fbffl
        UBD[1] + wf * (UBD[2] - UBD[1])
    else
        0.0f0
    end

    local surfarea = zeros(Float32, 5)
    surfarea[1] = USAV[1] * fdfl
    surfarea[2] = 109.0f0 * currcwd[2]
    surfarea[3] = 30.0f0  * currcwd[3]
    surfarea[4] = USAV[3] * woody
    surfarea[5] = USAV[2] * herb

    local sadead = surfarea[1] + surfarea[2] + surfarea[3]
    local salive = max(0.0000001f0, surfarea[4] + surfarea[5])
    local wtft   = zeros(Float32, 5)

    for i in 1:3
        wtft[i]   = sadead > 0.0f0 ? surfarea[i] / sadead : 0.0f0
        if i < 3
            wtft[i+3] = salive > 0.0f0 ? surfarea[i+3] / salive : 0.0f0
        end
    end

    local fbsav = if salive <= 0.0f0 && sadead <= 0.0f0
        0.0f0
    else
        local weightdead = sadead / (salive + sadead)
        local weightlive = 1.0f0 - weightdead
        local savdead    = USAV[1]*wtft[1] + 109.0f0*wtft[2] + 30.0f0*wtft[3]
        local savlive    = USAV[3]*wtft[4] + USAV[2]*wtft[5]
        savlive * weightlive + savdead * weightdead
    end

    if debug
        @printf(get(io_units, Int32(JOSTND), stdout),
            " FMCFMD2 FBSAV= %8.2f FBBD=%7.2f FBFFL=%7.2f\n", fbsav, fbbd, fbffl)
    end

    # Compute fuel-model SAV, bulk density, fine fuel load, and departure index
    for j in 1:Int(MXDFMD)
        if !lfuelmon[j] && Int(IFUELMON[j]) != 0; continue; end
        surfarea[1] = Float32(SURFVL[j,1,1]) * FMLOAD[j,1,1] / 0.04591f0
        surfarea[2] = Float32(SURFVL[j,1,2]) * FMLOAD[j,1,2] / 0.04591f0
        surfarea[3] = Float32(SURFVL[j,1,3]) * FMLOAD[j,1,3] / 0.04591f0
        surfarea[4] = Float32(SURFVL[j,2,1]) * FMLOAD[j,2,1] / 0.04591f0
        surfarea[5] = Float32(SURFVL[j,2,2]) * FMLOAD[j,2,2] / 0.04591f0
        sadead = surfarea[1] + surfarea[2] + surfarea[3]
        salive = max(0.0000001f0, surfarea[4] + surfarea[5])
        for i in 1:3
            wtft[i]   = sadead > 0.0f0 ? surfarea[i] / sadead : 0.0f0
            if i < 3
                wtft[i+3] = salive > 0.0f0 ? surfarea[i+3] / salive : 0.0f0
            end
        end
        fmsav[j] = if salive <= 0.0f0 && sadead <= 0.0f0
            0.0f0
        else
            local weightdead = sadead / (salive + sadead)
            local weightlive = 1.0f0 - weightdead
            local savdead2   = Float32(SURFVL[j,1,1])*wtft[1] +
                               Float32(SURFVL[j,1,2])*wtft[2] +
                               Float32(SURFVL[j,1,3])*wtft[3]
            local savlive2   = Float32(SURFVL[j,2,1])*wtft[4] +
                               Float32(SURFVL[j,2,2])*wtft[5]
            savlive2 * weightlive + savdead2 * weightdead
        end
    end

    for i in 1:Int(MXDFMD)
        if !lfuelmon[i] && Int(IFUELMON[i]) != 0; continue; end
        fmffl[i] = (FMLOAD[i,1,1] + FMLOAD[i,2,1] + FMLOAD[i,2,2]) / 0.04591f0
        fmbd[i]  = (FMLOAD[i,1,1] + FMLOAD[i,1,2] + FMLOAD[i,1,3] +
                    FMLOAD[i,2,1] + FMLOAD[i,2,2]) / FMDEP[i]
        dindex[i] = 0.25f0 * ((fbsav - fmsav[i]) / 405.2f0)^2 +
                    0.25f0 * ((fbbd  - fmbd[i])  / 0.3992f0)^2 +
                    0.50f0 * ((fbffl - fmffl[i]) / 3.051f0)^2
        if debug
            @printf(get(io_units, Int32(JOSTND), stdout),
                " FMCFMD2 FM= %4d FMSAV= %8.2f FMBD=%7.2f FMFFL=%7.2f DINDEX=%8.2f\n",
                i, fmsav[i], fmbd[i], fmffl[i], dindex[i])
        end
    end

    # Sort by departure index (negate for descending, sort ascending, negate back)
    for i in 1:Int(MXDFMD); dindex[i] = -dindex[i]; end
    RDPSRT(Int(MXDFMD), dindex, ifm, true)
    for i in 1:Int(MXDFMD); dindex[i] = -dindex[i]; end

    # Build sorted list of eligible models
    local j2 = 0
    for i in 1:Int(MXDFMD)
        local idx = Int(ifm[i])
        if idx < 1 || idx > Int(MXDFMD); continue; end
        if (lfuelmon[idx] || Int(IFUELMON[idx]) == 0) && Int(IFUELMON[idx]) != 1
            j2 += 1
            lfm[j2]   = Int32(idx)
            lowdi[j2] = dindex[idx]
        end
    end

    if debug
        @printf(get(io_units, Int32(JOSTND), stdout),
            " FMCFMD2 LFM= %4d %4d %4d %4d LOWDI= %8.2f %8.2f %8.2f %8.2f\n",
            lfm[1], lfm[2], lfm[3], lfm[4], lowdi[1], lowdi[2], lowdi[3], lowdi[4])
    end

    j2 = min(j2, 2)

    if j2 == 0
        fmd_ref[]   = Int32(8)
        FMOD[1]     = Int32(8)
        FWT[1]      = 1.0f0
        global NFMODS = Int32(1)
        @printf(get(io_units, Int32(JOSTND), stdout),
            "\n *** FFE MODEL WARNING: NO AVAILABLE FUEL MODELS:\n *** FUEL MODEL SET TO FM 8\n\n")
        RCDSET(Int32(2), true)
    elseif lowdi[1] <= 0.0f0 || j2 == 1
        fmd_ref[]   = lfm[1]
        FMOD[1]     = lfm[1]
        FWT[1]      = 1.0f0
        global NFMODS = Int32(1)
    else
        fmd_ref[]   = lfm[1]
        local bot   = 0.0f0
        local sumwt = 0.0f0
        for i in 1:j2
            FMOD[i] = lfm[i]
            bot    += 1.0f0 / lowdi[i]
        end
        for i in 1:j2-1
            FWT[i]  = (1.0f0 / lowdi[i]) / bot
            sumwt  += FWT[i]
        end
        FWT[j2]     = 1.0f0 - sumwt
        global NFMODS = Int32(j2)
    end

    # If static fuel model, force single model
    if !LDYNFM
        FMOD[1] = fmd_ref[]
        FWT[1]  = 1.0f0
        global NFMODS = Int32(1)
        for i in 2:Int(MXFMOD)
            FMOD[i] = Int32(0)
            FWT[i]  = 0.0f0
        end
    end

    if debug
        @printf(get(io_units, Int32(JOSTND), stdout),
            " FMCFMD2 FMD= %4d NFMODS= %3d FMOD1=%4d FWT1=%7.2f FMOD2=%4d FWT2=%7.2f FMOD3=%4d FWT3=%7.2f FMOD4=%4d FWT4=%7.2f\n",
            fmd_ref[], NFMODS, FMOD[1], FWT[1], FMOD[2], FWT[2], FMOD[3], FWT[3], FMOD[4], FWT[4])
    end
    return nothing
end


function FMCFMD3(iyr::Integer, fmd_ref::Ref{Int32})
    debug = DBCHK("FMCFMD3", 6, ICYC)
    if debug
        @printf(get(io_units, Int32(JOSTND), stdout),
            " FMCFMD3 CYCLE=%2d IYR=%5d IFLOGIC=%2d\n", ICYC, iyr, IFLOGIC)
    end

    # If modelled loads (IFLOGIC=2): build custom fuel model 89 from stand state
    if Int(IFLOGIC) == 2
        local lok    = true
        local inl    = 0
        local indd   = 0
        local xsur   = zeros(Float32, 2, 3)
        local xfml   = zeros(Float32, 2, 3)
        local ifmd   = 89

        xsur[1,1] = USAV[1]; xsur[1,2] = 109.0f0; xsur[1,3] = 30.0f0
        xsur[2,1] = USAV[3]; xsur[2,2] = USAV[2]

        local currcwd2 = zeros(Float32, Int(MXFLCL))
        for i in 1:2, j in 1:Int(MXFLCL), k in 1:2, l in 1:4
            currcwd2[j] += CWD[i, j, k, l] * 0.04591f0
        end

        local herb2  = FLIVE[1] * 0.04591f0
        local woody2 = 0.0f0
        for i in 1:Int(ITRN)
            if HT[i] <= CANMHT
                woody2 += (CROWNW[i, 1] + 0.5f0 * CROWNW[i, 2]) * FMPROB[i] * P2T
            end
        end
        woody2 = (woody2 + FLIVE[2]) * 0.04591f0

        xfml[1,1] = max(0.0f0, currcwd2[1] + currcwd2[10])
        xfml[1,2] = max(0.0f0, currcwd2[2])
        xfml[1,3] = max(0.0f0, currcwd2[3])
        xfml[2,1] = max(0.0f0, woody2)
        xfml[2,2] = max(0.0f0, herb2)

        local fdfl2 = currcwd2[1] + currcwd2[10]
        local ffl   = fdfl2 + herb2 + woody2
        local xdep  = 0.0f0
        local xext  = 0.0f0
        if ffl > 0.0f0
            local wf2   = fdfl2 / ffl
            local bdavg = UBD[1] + wf2 * (UBD[2] - UBD[1])
            xdep  = (ffl + currcwd2[2] + currcwd2[3]) / bdavg
            xext  = (12.0f0 + 480.0f0 * bdavg / 32.0f0) / 100.0f0
            for i in 1:3
                if xfml[1,i] > 0.0f0; indd += 1; end
                if xfml[2,i] > 0.0f0; inl  += 1; end
            end
        end

        if xdep < 0.0f0;                      lok = false; end
        if xext < 0.0f0 || xext > 1.0f0;     lok = false; end
        if indd <= 0 && inl <= 0;             lok = false; end

        if lok
            for i in 1:2, j in 1:3
                SURFVL[ifmd, i, j] = round(Int32, xsur[i, j])
                FMLOAD[ifmd, i, j] = xfml[i, j]
            end
            global FMDEP[ifmd]  = xdep
            global MOISEX[ifmd] = xext
        end

        if debug
            @printf(get(io_units, Int32(JOSTND), stdout),
                " FMCFMD3, XDEP=%7.3f XEXT=%7.3f INDD=%2d INL=%2d\n",
                xdep, xext, indd, inl)
            for i in 1:2, j in 1:3
                @printf(get(io_units, Int32(JOSTND), stdout),
                    " FMCFMD3: I J =%3d%3d SURFVL=%7d FMLOAD=%12.4f\n",
                    i, j, SURFVL[89, i, j], FMLOAD[89, i, j])
            end
        end
    end

    # Compute canopy base height and crown bulk density (unless already done in FMMAIN)
    if Int(BURNYR) != Int(iyr)
        FMPOCR(iyr, Int32(1))
    end

    # Select fuel model
    if Int(IFLOGIC) == 0
        if !(VARACD in ("UT","TT","CR","LS","CS","SN","ON"))
            FMCFMD(iyr, fmd_ref)
        end
    elseif Int(IFLOGIC) == 1
        FMCFMD2(iyr, fmd_ref)
    end
    return nothing
end
