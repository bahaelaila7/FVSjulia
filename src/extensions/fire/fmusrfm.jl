# fmusrfm.f — Process FUELMODL, FUELTRET, and FIRECALC keywords
# FMUSRFM: updates FMD (static fuel model), FMOD/FWT (dynamic model weights),
#           FTREAT/HARTYP/DPMOD (fuel treatment), IFLOGIC/USAV/UBD/ULHV (FIRECALC)
# Called from: FMBURN

function FMUSRFM(iyr::Integer, fmd_ref::Ref{Int32})
    # Activity keyword codes
    local act_fuelmodl = Int32[2538]
    local act_fueltret = Int32[2525]
    local act_firecalc = Int32[2549]

    # Depth multiplier: DPMULT(harvest_type, fuel_treat+1)
    # harvest: 1=ground, 2=high-lead, 3=precomm/heli
    # treat:   1=none, 2=lopping, 3=trampling
    local dpmult = Float32[
        1.00f0, 1.30f0, 1.60f0,
        0.83f0, 0.83f0, 0.83f0,
        0.75f0, 0.75f0, 0.75f0]   # col-major: (hartyp, ftreat+1)

    # Initialize dynamic model weights
    for i in 1:Int(MXFMOD)
        FMOD[i] = Int32(0)
        FWT[i]  = 0.0f0
    end

    # --- Process FIRECALC keyword ---
    local ntodo_ref = Ref(Int32(0))
    OPFIND(Int32(1), act_firecalc, ntodo_ref)
    local ntodo::Int = Int(ntodo_ref[])
    if ntodo > 0
        for itodo in 1:ntodo
            local jyr_ref = Ref(Int32(0)); local iactk_ref = Ref(Int32(0))
            local nprm_ref = Ref(Int32(0)); local prms = zeros(Float32, 8)
            OPGET(Int32(itodo), Int32(8), jyr_ref, iactk_ref, nprm_ref, prms)
            OPDONE(Int32(itodo), Int32(iyr))
            global IFLOGIC = Int32(prms[1])
            global IFMSET  = Int32(prms[2])
            global USAV[1] = prms[3]; global USAV[2] = prms[4]; global USAV[3] = prms[5]
            global UBD[1]  = prms[6]; global UBD[2]  = prms[7]
            global ULHV    = prms[8]
        end
    end

    # --- Process FUELMODL keyword ---
    OPFIND(Int32(1), act_fuelmodl, ntodo_ref)
    ntodo = Int(ntodo_ref[])
    if ntodo > 0
        for itodo in 1:ntodo
            local prms = zeros(Float32, 8)
            local jyr_ref = Ref(Int32(0)); local iactk_ref = Ref(Int32(0)); local nprm_ref = Ref(Int32(0))
            OPGET(Int32(itodo), Int32(8), jyr_ref, iactk_ref, nprm_ref, prms)
            local nprm::Int = Int(nprm_ref[])

            # Invalid fuel model ranges — reject
            local bad_range = (x::Float32) -> begin
                xi = Int(x)
                (31 <= xi <= 100) || (110 <= xi <= 120) || (125 <= xi <= 140) ||
                (150 <= xi <= 160) || (166 <= xi <= 180) || (190 <= xi <= 200) || (205 <= xi <= 256)
            end

            if nprm <= 0 || prms[1] == 0.0f0
                global LUSRFM = false
                OPDONE(Int32(itodo), Int32(iyr))
            elseif Int(prms[1]) > Int(MXDFMD) || Int(prms[3]) > Int(MXDFMD) ||
                   Int(prms[5]) > Int(MXDFMD) || Int(prms[7]) > Int(MXDFMD)
                global LUSRFM = false
            elseif bad_range(prms[1]) || bad_range(prms[3]) || bad_range(prms[5]) || bad_range(prms[7])
                global LUSRFM = false
            else
                OPDONE(Int32(itodo), Int32(iyr))
                global LUSRFM = true
                # Normalize weights
                if isodd(nprm)
                    nprm += 1
                    prms[nprm] = 1.0f0
                end
                local wsum::Float32 = 0.0f0
                for i in 2:2:nprm
                    if prms[i] <= 0.0f0; prms[i] = 1.0f0; end
                    wsum += prms[i]
                end
                wsum = 1.0f0 / wsum
                for i in 2:2:nprm; prms[i] *= wsum; end
                for j in 1:4; FMDUSR[j] = Int32(0); FWTUSR[j] = 0.0f0; end
                local j::Int = 0
                for i in 1:2:nprm-1
                    j += 1
                    FMDUSR[j] = Int32(prms[i])
                    FWTUSR[j] = prms[i+1]
                end
            end
        end
    end

    if LUSRFM
        # Sort by descending weight into FMOD/FWT
        FMOD[Int(MXFMOD)] = Int32(0); FWT[Int(MXFMOD)] = 0.0f0
        local indx = zeros(Int32, 4)
        RDPSRT(Int32(4), FWTUSR, indx, true)
        for i in 1:4
            j = Int(indx[i])
            FMOD[i] = FMDUSR[j]
            FWT[i]  = FWTUSR[j]
        end

        local fmd::Int32 = Int32(-1)
        if FWT[1] > 1.0f-6; fmd = FMOD[1]; end
        if fmd < 0
            FMOD[1] = Int32(8); FWT[1] = 1.0f0; global NFMODS = Int32(1)
            for i in 2:Int(MXFMOD); FMOD[i] = Int32(0); FWT[i] = 0.0f0; end
            RCDSET(Int32(2), true)
        end

        local nf::Int = 0
        for i in 1:Int(MXFMOD)
            if FWT[i] <= 1.0f-6; nf = i - 1; break; end
            nf = i
        end
        global NFMODS = Int32(min(nf, 4))

        if !LDYNFM
            FMOD[1] = fmd; FWT[1] = 1.0f0; global NFMODS = Int32(1)
            for i in 2:Int(MXFMOD); FMOD[i] = Int32(0); FWT[i] = 0.0f0; end
        end
        fmd_ref[] = fmd
    else
        if Int(IFLOGIC) == 2
            fmd_ref[] = Int32(89)
            FMOD[1] = Int32(89); FWT[1] = 1.0f0; global NFMODS = Int32(1)
            for i in 2:Int(MXFMOD); FMOD[i] = Int32(0); FWT[i] = 0.0f0; end
        end
    end

    # --- Process FUELTRET keyword ---
    OPFIND(Int32(1), act_fueltret, ntodo_ref)
    ntodo = Int(ntodo_ref[])
    if ntodo > 0
        for jdo in 1:ntodo
            local prms2 = zeros(Float32, 3)
            local jyr2 = Ref(Int32(0)); local iactk2 = Ref(Int32(0)); local nprm2 = Ref(Int32(0))
            OPGET(Int32(jdo), Int32(3), jyr2, iactk2, nprm2, prms2)
            local lok::Bool = (0.0f0 <= prms2[1] <= 2.0f0) && (1.0f0 <= prms2[2] <= 3.0f0)
            if lok
                global FTREAT = Int32(prms2[1])
                global HARTYP = Int32(prms2[2])
                global DPMOD  = prms2[3]
                if DPMOD < 0.0f0
                    local hi::Int = Int(HARTYP)
                    local fi::Int = Int(FTREAT) + 1
                    global DPMOD = dpmult[(hi-1)*3 + fi]
                end
                global IFTYR = Int32(iyr)
                OPDONE(Int32(jdo), Int32(iyr))
            else
                OPDEL1(Int32(jdo))
            end
        end
    end

    if IFTYR > 0
        if (Int(iyr) - Int(IFTYR)) > 5
            global IFTYR = Int32(0); global FTREAT = Int32(0)
            global HARTYP = Int32(0); global DPMOD = 1.0f0
        end
    else
        global FTREAT = Int32(0); global HARTYP = Int32(0); global DPMOD = 1.0f0
    end

    return nothing
end
