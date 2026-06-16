# fire/fmscut.f — Add cut-tree material to fire model debris pools
# Processes crown material, downed snags, and carbon fate arrays for harvested trees.
# Must be called BEFORE CUTS removes tree records (needs DBH/HT/species info).
# Called from: CUTS

function FMSCUT(mxvol::AbstractMatrix{Float32}, nr::Integer, nc::Integer,
                ssng::AbstractVector{Float32}, dsng::AbstractVector{Float32},
                ctcrwn::AbstractVector{Float32}, tkcrwn::AbstractVector{Float32})
    debug = DBCHK("FMSCUT", 6, ICYC)
    if debug
        @printf(get(io_units, Int32(JOSTND), stdout),
            " ENTERING FMSCUT CYCLE = %2d LFMON=%s\n", ICYC, LFMON ? "T" : "F")
    end
    if !LFMON; return nothing; end

    local _ = mxvol[1, 1]   # suppress unused-argument warning

    local lvsnbm = 0.0f0
    local tkcrbm = 0.0f0
    local lvcrwn = 0.0f0
    local lmerch  = LVWEST
    local lmrch2  = false

    for i in 1:Int(ITRN)
        if ctcrwn[i] > 0.0f0 || dsng[i] > 0.0f0
            global HARVYR = IY[Int(ICYC)]
        end

        FMSSEE(i, Int(ISP[i]), DBH[i], HT[i], ssng[i], Int32(0), debug, Int32(JOSTND))

        local idc = Int(DKRCLS[Int(ISP[i])])
        local x   = ctcrwn[i] * P2T
        local y   = tkcrwn[i] * P2T
        local z   = (ctcrwn[i] - dsng[i]) * P2T

        # Foliage (size class 0 → index 1)
        CWD[1, 10, 2, idc] += CROWNW[i, 1] * x
        tkcrbm += CROWNW[i, 1] * y
        lvcrwn += CROWNW[i, 1] * z

        # Woody size classes 1:5 → indices 2:6
        for isz in 1:5
            CWD[1, isz, 2, idc] += CROWNW[i, isz+1] * x
            tkcrbm += CROWNW[i, isz+1] * y
            lvcrwn += CROWNW[i, isz+1] * z
        end

        CWD3(Int(ISP[i]), DBH[i], dsng[i], HT[i], Int(ICR[i]))

        # Volume of cut material left as snag or downed snag
        local v_ref = Ref(Float32(0))
        FMSVL2(Int(ISP[i]), DBH[i], HT[i], -1.0f0, v_ref,
               Int(ICR[i]), 'L', lmrch2, debug, Int32(JOSTND))
        lvsnbm += v_ref[] * V2T[Int(ISP[i])] * (ssng[i] + dsng[i])

        # Biomass for removed trees (not left as snag or downed snag)
        local hrvtre = WK3[i] - ssng[i] - dsng[i]

        local abio_ref = Ref(Float32(0))
        local mbio_ref = Ref(Float32(0))
        local rbio_ref = Ref(Float32(0))
        FMCBIO(DBH[i], Int(ISP[i]), abio_ref, mbio_ref, rbio_ref)
        global BIOROOT += rbio_ref[] * (WK3[i] - ssng[i])
        global BIOREM[1] += abio_ref[] * hrvtre

        # Carbon fate: merchantable volume by product/wood type
        local xcf = 0.0f0
        if Int(ICMETH) == 0   # FFE volume method
            if hrvtre > 0.0f0
                local vcf_ref = Ref(Float32(0))
                FMSVL2(Int(ISP[i]), DBH[i], HT[i], -1.0f0, vcf_ref,
                       Int(ICR[i]), 'L', lmerch, debug, Int32(JOSTND))
                xcf = vcf_ref[] * V2T[Int(ISP[i])] * hrvtre
            end
        else                  # Jenkins biomass method
            xcf = mbio_ref[] * hrvtre
        end
        local kk = BIOGRP[Int(ISP[i])] > 5 ? 2 : 1
        local jj = DBH[i] > CDBRK[kk] ? 2 : 1
        FATE[jj, kk, Int(ICYC)] += xcf
    end

    # Add new snags created by harvest to snag list
    FMSADD(IY[Int(ICYC)], Int32(2))

    # Compute total harvest removal volume and convert to tons
    global TONRMH = 0.0f0
    for i in 1:Int(ITRN)
        local vt_ref = Ref(Float32(0))
        FMSVL2(Int(ISP[i]), DBH[i], HT[i], -1.0f0, vt_ref,
               Int(ICR[i]), 'L', false, debug, Int32(JOSTND))
        global TONRMH += vt_ref[] * V2T[Int(ISP[i])] * WK3[i]
    end

    # Adjust: subtract left-behind snag volume, add removed crowns
    global TONRMH = TONRMH - lvsnbm + tkcrbm

    # Jenkins case: subtract crowns left in stand from removed biomass
    global BIOREM[1] -= lvcrwn
    if BIOREM[1] < 0.0f0; global BIOREM[1] = 0.0f0; end

    if debug
        @printf(get(io_units, Int32(JOSTND), stdout),
            " FMSCUT, TONRMH= %12.3f\n", TONRMH)
    end
    return nothing
end
