# fmgfmv.f — Load fuel model parameter values for a given fuel model number
# FMGFMV: populates ND/NL/FWG/MPS/DEPTH/MEXT globals from SURFVL/FMLOAD/FMDEP/MOISEX
# Called from: FMFINT, FMCFIR

function FMGFMV(iyr::Integer, ifmd::Integer)
    debug = DBCHK("FMGFMV", 6, 1)
    if debug
        @printf(get(io_units, Int32(JOSTND), stdout), " ENTERING ROUTINE FMGFMV\n")
    end

    # Zero all fuel category arrays
    for i in 1:2
        for j in 1:4
            MPS[i, j] = Int32(0)
        end
        for j in 1:7
            FWG[i, j] = 0.0f0
        end
    end
    MEXT[1] = 0.0f0; MEXT[2] = 0.0f0; MEXT[3] = 0.0f0

    global ND = Int32(0)
    global NL = Int32(0)
    local sumps::Float32 = 0.0f0

    # Set dead herb SAV equal to live herb SAV: SURFVL(IFMD,1,4)=SURFVL(IFMD,2,2)
    SURFVL[ifmd, 1, 4] = SURFVL[ifmd, 2, 2]

    for i in 1:2
        for j in 1:4
            MPS[i, j] = Int32(SURFVL[ifmd, i, j])
            FWG[i, j] = FMLOAD[ifmd, i, j]
        end
    end

    # Dynamic herb transfer: put some live herbs into dead herb based on moisture
    if FMLOAD[ifmd, 2, 2] > 0.0f0 && ifmd != 2 && MOIS[2, 2] < 1.2f0
        local x = Float32[0.30f0, 1.2f0]
        local y = Float32[0.0f0, 1.0f0]
        local wt::Float32 = ALGSLP(MOIS[2, 2], x, y, Int32(2))
        FWG[1, 4] = (1.0f0 - wt) * FMLOAD[ifmd, 2, 2]
        FWG[2, 2] = wt * FMLOAD[ifmd, 2, 2]
    end

    for i in 1:2
        for j in 1:4
            if i == 1 && FWG[i, j] > 0.0f0; global ND = ND + Int32(1); end
            if i == 2 && FWG[i, j] > 0.0f0; global NL = NL + Int32(1); end
            sumps += Float32(MPS[i, j])
        end
    end
    global DEPTH = FMDEP[ifmd]
    MEXT[1] = MOISEX[ifmd]

    if debug
        @printf(get(io_units, Int32(JOSTND), stdout),
            " FMGFMV, ND=%2d NL=%2d SUMPS=%10.3f DEPTH=%7.3f\n",
            ND, NL, sumps, DEPTH)
    end

    # Validate model completeness
    if (ND <= 0 && NL <= 0) || sumps <= 0.0f0 || DEPTH <= 0.0f0
        local jostnd_io = get(io_units, Int32(JOSTND), stdout)
        @printf(jostnd_io, "/ \n")
        @printf(jostnd_io, "/ *** FFE: FATAL PROBLEM: YEAR = %4d\n", iyr)
        @printf(jostnd_io, "/ *** FFE: FUEL MODEL = %2d\n", ifmd)
        @printf(jostnd_io, "/ *** FFE: NO LIVE OR DEAD CLASSES, NO FUEL SURF/VOL, OR NO DEPTH DEFINED\n")
        @printf(jostnd_io, "/ *** FFE: CHECK \"DEFULMOD\" AND \"FUELMODL\" KEYWORD USE\n")
        @printf(jostnd_io, "/ *** FFE: EXITING\n")
        ERRGRO(false, Int32(4))
        local irtncd_ref = Ref(Int32(0))
        fvsGetRtnCode(irtncd_ref)
        if irtncd_ref[] != 0; return nothing; end
    end

    # Apply depth modifier from fuel treatment activity
    global DEPTH = DEPTH * DPMOD

    return nothing
end
