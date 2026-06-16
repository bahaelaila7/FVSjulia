# fmcfir.f — Crown fire type and torching/crowning index
# FMCFIR: determines CFTMP (fire type label), CRBURN, FIRTYPE, RFINAL
# Called from: FMBURN, FMPOFL

function FMCFIR(iyr::Integer, fmois::Integer, wmult::Real, swind::Integer,
                cftmp_ref::Ref{String},
                oinit1::AbstractVector{Float32}, oact1::AbstractVector{Float32},
                hpa::Real)
    debug = DBCHK("FMCFIR", 6, ICYC)
    if debug
        @printf(io_units[JOSTND], " ENTERING FMCFIR CYCLE=%3d FMOIS=%2d CBD=%7.3f\n",
                ICYC, fmois, CBD)
    end

    if CBD <= 0.0f0
        cftmp_ref[] = "SURFACE"
        global CRBURN = Float32(0.0)
        oinit1[fmois] = -1.0f0
        oact1[fmois]  = -1.0f0
        return nothing
    end

    local init1::Float32 = 0.0f0
    if ACTCBH != Float32(-1)
        init1 = ((460.0f0 + 25.9f0 * FOLMC)) * 0.001333f0
        init1 = (init1 * ACTCBH)^1.5f0
    end

    # Save current fuel model state, then load FM10 for crown fire calcs
    local oldnd::Int32 = ND
    local oldnl::Int32 = NL
    local oldept::Float32 = DEPTH
    local oldfwg = copy(FWG)
    local oldmps = copy(MPS)
    local oldmex = copy(MEXT)

    MPS[1,1] = Int32(2000); MPS[1,2] = Int32(109); MPS[1,3] = Int32(30)
    MPS[2,1] = Int32(1500)
    global ND = Int32(3); global NL = Int32(1)
    FWG[1,1] = 0.138f0; FWG[1,2] = 0.092f0; FWG[1,3] = 0.23f0
    FWG[2,1] = 0.092f0
    global DEPTH = 1.0f0
    MEXT[1] = 0.25f0

    local savwnd::Float32 = FWIND
    global FWIND = Float32(swind) * 0.4f0

    local byram2::Float32 = 0.0f0; local byram2_ref = Ref(byram2)
    local flame2::Float32 = 0.0f0; local flame2_ref = Ref(flame2)
    local hpa2_ref = Ref(Float32(0.0))
    local irtncd_ref = Ref(Int32(0))
    FMFINT(Int32(iyr), byram2_ref, flame2_ref, Int32(2), hpa2_ref, Int32(1))
    fvsGetRtnCode(irtncd_ref)
    if irtncd_ref[] != 0
        # Restore state before returning
        global FWIND = savwnd
        global ND = oldnd; global NL = oldnl; global DEPTH = oldept
        copyto!(FWG, oldfwg); copyto!(MPS, oldmps); copyto!(MEXT, oldmex)
        return nothing
    end

    global FWIND = savwnd

    # Crowning index
    local b::Float32 = 0.02526f0 * (SSIGMA[fmois]^0.54f0)

    if SIRXI[2] < 0.00001f0
        oact1[fmois] = -1.0f0
    else
        oact1[fmois] = (2.95f0 * SRHOBQ[2] / (SIRXI[2] * CBD) - SPHIS[2] - 1.0f0) / 0.001612f0
        if oact1[fmois] > 0.0f0
            oact1[fmois] = (oact1[fmois]^0.7f0) * 0.01137f0 / 0.4f0
        else
            oact1[fmois] = 0.0f0
        end
    end

    local ract::Float32   = 3.34f0 * SFRATE[2]
    local rinit1::Float32 = hpa > 0.0 ? 60.0f0 * init1 / Float32(hpa) : 0.0f0

    # Restore fuel model state
    global ND = oldnd; global NL = oldnl; global DEPTH = oldept
    copyto!(FWG, oldfwg); copyto!(MPS, oldmps); copyto!(MEXT, oldmex)

    # Torching index (iterative binary search)
    if ACTCBH != Float32(-1) && hpa > 0.0
        if SCBE[fmois] != 0.0f0
            oinit1[fmois] = (60.0f0 * init1 * SRHOBQ[fmois] /
                            (Float32(hpa) * SIRXI[fmois]) - SPHIS[fmois] - 1.0f0) / SCBE[fmois]
        else
            oinit1[fmois] = 0.0f0
        end
        if oinit1[fmois] > 0.0f0
            oinit1[fmois] = (oinit1[fmois]^(1.0f0/b)) * 0.01137f0 / Float32(wmult)
        else
            oinit1[fmois] = 0.0f0
        end

        savwnd = FWIND
        global FWIND = 999.0f0 * Float32(wmult)
        local byram_x = Ref(Float32(0)); local flame_x = Ref(Float32(0)); local hpa3 = Ref(Float32(0))
        FMFINT(Int32(iyr), byram_x, flame_x, Int32(2), hpa3, Int32(2))
        fvsGetRtnCode(irtncd_ref)
        if irtncd_ref[] != 0; global FWIND = savwnd; return; end

        if SFRATE[2] < rinit1
            oinit1[fmois] = 999.0f0
            @goto label_205
        end
        if oinit1[fmois] >= 999.0f0; oinit1[fmois] = 999.0f0; end

        global FWIND = oinit1[fmois] * Float32(wmult)
        FMFINT(Int32(iyr), byram_x, flame_x, Int32(2), hpa3, Int32(2))
        fvsGetRtnCode(irtncd_ref)
        if irtncd_ref[] != 0; global FWIND = savwnd; return; end

        local diff::Float32 = SFRATE[2] - rinit1
        if diff <= 0.001f0 && diff >= -0.001f0; @goto label_205; end

        local boundl::Float32 = 0.0f0; local boundu::Float32 = 0.0f0
        for iter in 1:1000
            if iter == 1
                if diff > 0.001f0
                    boundl = 0.0f0; boundu = oinit1[fmois]
                else
                    boundl = oinit1[fmois]; boundu = 999.0f0
                end
            end
            oinit1[fmois] = (boundu + boundl) / 2.0f0
            global FWIND = oinit1[fmois] * Float32(wmult)
            FMFINT(Int32(iyr), byram_x, flame_x, Int32(2), hpa3, Int32(2))
            fvsGetRtnCode(irtncd_ref)
            if irtncd_ref[] != 0; global FWIND = savwnd; return; end
            diff = SFRATE[2] - rinit1
            if diff <= 0.001f0 && diff >= -0.001f0; break; end
            if diff >  0.001f0; boundu = oinit1[fmois]; end
            if diff < -0.001f0; boundl = oinit1[fmois]; end
            if boundu <= 0.0f0; break; end
            if boundu > 0.0f0 && boundu < 1f-10; oinit1[fmois] = 0.0f0; break; end
        end

        @label label_205
        oinit1[fmois] = min(oinit1[fmois], 999.0f0)
        global FWIND = savwnd
    else
        oinit1[fmois] = -1.0f0
    end

    # Determine fire type
    if oinit1[fmois] > Float32(swind)
        if oact1[fmois] > Float32(swind)
            cftmp_ref[] = "SURFACE "
            global CRBURN  = Float32(0.0)
            global FIRTYPE = Int32(3)
            global RFINAL  = SFRATE[fmois]
        else
            cftmp_ref[] = "COND_CRN"
            global CRBURN  = Float32(1.0)
            global FIRTYPE = Int32(1)
            global RFINAL  = ract
        end
    elseif oact1[fmois] > Float32(swind)
        cftmp_ref[] = "PASSIVE "
        global FIRTYPE = Int32(2)
    else
        cftmp_ref[] = "ACTIVE  "
        global CRBURN  = Float32(1.0)
        global FIRTYPE = Int32(1)
        global RFINAL  = ract
    end

    if oinit1[fmois] == -1.0f0 || oact1[fmois] == -1.0f0
        cftmp_ref[] = "SURFACE "
        global CRBURN  = Float32(0.0)
        global FIRTYPE = Int32(3)
        global RFINAL  = SFRATE[fmois]
    end

    # Passive crown fire: compute crown fraction burned (CFB)
    if cftmp_ref[] == "PASSIVE "
        savwnd = FWIND
        global FWIND = oact1[fmois] * Float32(wmult)
        local byram_p = Ref(Float32(0)); local flame_p = Ref(Float32(0)); local hpa2b = Ref(Float32(0))
        FMFINT(Int32(iyr), byram_p, flame_p, Int32(2), hpa2b, Int32(2))
        fvsGetRtnCode(irtncd_ref)
        if irtncd_ref[] != 0; global FWIND = savwnd; return; end
        global FWIND = savwnd
        local cfb::Float32 = (SFRATE[fmois] - rinit1) / (SFRATE[2] - rinit1 + 1f-9)
        global RFINAL = SFRATE[fmois] + cfb * (ract - SFRATE[fmois])
        global CRBURN = min(cfb, 1.0f0)
    end

    if debug
        @printf(io_units[JOSTND],
            " FMCFIR FMOIS=%2d CFTMP=%s OINIT1=%13.3f OACT1=%13.3f RFINAL=%13.3f\n",
            fmois, cftmp_ref[], oinit1[fmois], oact1[fmois], RFINAL)
    end
    return nothing
end
