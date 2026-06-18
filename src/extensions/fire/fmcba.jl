# SUBROUTINE FMCBA(IYR, ISWTCH) — fire crown bulk area and initial fuel setup
# Translated from: fmcba.f (414 lines)
#
# Called from FMMAIN each cycle (ISWTCH=0) or from SVSTART (ISWTCH=1).
# Sets COVTYP, PERCOV, FLIVE (live fuels), and on first year loads dead fuels
# into CWD from FIA forest type, then adjusts for user keywords 2521/2548/2553.
# ENTRY SNGCOE → separate no-op function (called from SVSTART in SO variant).

function FMCBA(iyr::Integer, iswtch::Integer)
    local debug::Bool = false
    debug = DBCHK(false, "FMCBA", Int32(5), ICYC)
    if debug
        @printf(io_units[Int32(JOSTND)], " ENTERING FMCBA CYCLE = %2d\n", ICYC)
    end

    # Herb/shrub loadings by FFE forest type (1=pine,2=hardwood,3=redcedar,4=oak savannah)
    # Fortran FULIV(2,4): first dim=fuel type (1=herb,2=shrub), second dim=forest type
    local fuliv = Float32[
        0.1f0, 0.25f0,    # pines
        0.01f0, 0.03f0,   # hardwoods
        1.0f0, 5.0f0,     # redcedar
        0.02f0, 0.13f0    # oak savannah
    ]  # linearized column-major: fuliv[(i-1)*2 + j] = FULIV(j, i) where j=1:2, i=1:4
    # Access: fuliv_at(herb_shrub, ftype) = fuliv[(ftype-1)*2 + herb_shrub]
    fuliv_at(j::Int, i::Int) = fuliv[(i-1)*2 + j]

    # Shrub/herb loadings by age of rough × site index group (Coastal Plain / Piedmont)
    # Fortran FULIV2(8,6): 8 age breakpoints × 6 site index classes
    local fuliv2 = reshape(Float32[
        0.4f0, 0.4f0, 0.5f0, 0.6f0, 0.9f0, 1.4f0, 2.6f0, 4.2f0,   # si < 50
        1.2f0, 1.3f0, 1.3f0, 1.5f0, 1.7f0, 2.2f0, 3.4f0, 5.1f0,   # si 50-65
        2.6f0, 2.6f0, 2.7f0, 2.8f0, 3.1f0, 3.5f0, 4.7f0, 6.4f0,   # si 65-80
        4.5f0, 4.5f0, 4.6f0, 4.7f0, 5.0f0, 5.5f0, 6.6f0, 8.3f0,   # si 80-95
        7.0f0, 7.0f0, 7.0f0, 7.2f0, 7.4f0, 7.9f0, 9.1f0,10.8f0,   # si 95-110
       10.0f0,10.0f0,10.0f0,10.2f0,10.4f0,10.9f0,12.1f0,13.8f0    # si >= 110
    ], 8, 6)   # 8 rows (age), 6 cols (si class) — column-major matches Fortran DATA

    # Age of rough breakpoints for ALGSLP
    local y_ages = Float32[1f0, 2f0, 3f0, 5f0, 7f0, 10f0, 15f0, 20f0]

    # Initial dead surface fuel loadings by FIA forest type
    # Fortran FUINI(MXFLCL=11, 9 forest types): 11 fuel classes, 9 FIA forest type groups
    local fuini = reshape(Float32[
        # <.25 0.25-1 1-3  3-6  6-12 12-20 20-35 35-50 >50   Lit   Duf
        0.10f0,0.50f0,1.68f0,0.55f0,0.64f0,0.07f0,0f0,0f0,0f0,4.02f0,12.52f0, # EWP 100s
        0.10f0,0.66f0,0.98f0,0.12f0,0.29f0,0.26f0,0f0,0f0,0f0,6.38f0, 8.66f0, # LL-slash 140s
        0.14f0,0.72f0,1.54f0,0.25f0,0.44f0,0.33f0,0f0,0f0,0f0,4.90f0, 6.03f0, # loblolly 160s
        0.24f0,1.24f0,2.72f0,0.36f0,0.97f0,0.33f0,0f0,0f0,0f0,3.82f0, 3.80f0, # redcedar 181/402
        0.18f0,0.77f0,2.17f0,0.31f0,0.86f0,0.78f0,0f0,0f0,0f0,4.07f0, 6.15f0, # oak-pine 400s
        0.13f0,0.68f0,1.93f0,0.43f0,1.01f0,1.01f0,0f0,0f0,0f0,4.28f0, 5.91f0, # oak-hickory 500s
        0.13f0,0.67f0,1.83f0,0.18f0,0.57f0,0.77f0,0f0,0f0,0f0,2.49f0, 5.68f0, # oak-gum-cypress 600s
        0.22f0,1.09f0,2.68f0,0.26f0,0.76f0,0.43f0,0f0,0f0,0f0,2.33f0, 1.60f0, # elm-ash-cottonwood 700s
        0.09f0,0.64f0,2.03f0,0.43f0,1.18f0,3.38f0,0f0,0f0,0f0,3.75f0, 4.10f0  # maple-beech-birch 800s
    ], 11, 9)  # 11 rows (MXFLCL fuel classes), 9 cols (forest types)

    local myact = Int32[2521, 2548, 2553]

    # Reset stand-level fire variables
    global COVTYP = Int32(0)
    global PERCOV = Float32(0.0)
    local bigdbh::Float32 = 0.0f0
    local totba::Float32  = 0.0f0

    # --- Live fuel levels ---
    # Coastal Plain / Mountain Laurel ecoregions (232, 231, M221)
    if (length(PCOM) >= 3 && PCOM[1:3] == "232") ||
       (length(PCOM) >= 3 && PCOM[1:3] == "231") ||
       (length(PCOM) >= 4 && PCOM[1:4] == "M221")

        # Select site index class for shrub lookup
        local si::Float32 = SITEAR[ISISP]
        local j_si::Int = si < 50f0 ? 1 : si < 65f0 ? 2 : si < 80f0 ? 3 :
                          si < 95f0 ? 4 : si < 110f0 ? 5 : 6

        local shrubage::Float32
        if BURNYR > 0
            shrubage = Float32(iyr - BURNYR)
        else
            shrubage = Float32(iyr - IY[1] + 5)
        end
        shrubage = Float32(min(20, max(1, Int32(shrubage))))

        local fuliv3 = Float32[fuliv2[l, j_si] for l in 1:8]

        FLIVE[1] = 0.0f0
        FLIVE[2] = ALGSLP(shrubage, y_ages, fuliv3, Int32(8))
        if (length(PCOM) >= 3 && PCOM[1:3] == "231") ||
           (length(PCOM) >= 4 && PCOM[1:4] == "M221")
            FLIVE[2] *= 0.40f0
        end

    else
        # Determine FFE forest type (1 of 8) from FIA forest type
        local iffeft_ref = Ref(Int32(0))
        FMSNFT(iffeft_ref)
        local iffeft::Int32 = iffeft_ref[]

        local ftlivefu::Int32
        if iffeft ∈ (3,4,5)
            ftlivefu = Int32(1)   # pines
        elseif iffeft == 7
            ftlivefu = Int32(3)   # redcedar
        elseif iffeft == 6
            ftlivefu = Int32(4)   # oak savannah
        else
            ftlivefu = Int32(2)   # hardwoods
        end

        for i in 1:2
            FLIVE[i] = fuliv_at(i, Int(ftlivefu))
        end
    end

    # --- Per-tree loop: basal area, cover type, crown area ---
    if ITRN > 0
        local bamost::Float32 = 0.0f0
        local totcra::Float32 = 0.0f0
        local tba = zeros(Float32, MAXSP)

        for i in 1:ITRN
            if FMPROB[i] > 0.0f0
                local ksp::Int32 = ISP[i]
                local ba1::Float32 = 3.14159f0 * (DBH[i] / 24.0f0) * (DBH[i] / 24.0f0)
                tba[ksp] += ba1 * FMPROB[i]

                if DBH[i] > bigdbh; bigdbh = DBH[i]; end

                # Crown area from pre-computed per-tree crown width
                local cw::Float32 = CRWDTH[i]
                totcra += 3.1415927f0 * cw * cw / 4.0f0 * FMPROB[i]
            end
            CURKIL[i] = 0.0f0
        end

        for ksp in 1:MAXSP
            if tba[ksp] > bamost
                bamost  = tba[ksp]
                global COVTYP = Int32(ksp)
            end
            totba += tba[ksp]
        end

        # Percent cover: Poisson model for randomly distributed crowns
        global PERCOV = (1.0f0 - exp(-totcra / 43560.0f0)) * 100.0f0
    end

    if debug
        @printf(io_units[Int32(JOSTND)], " PERCOV = %.4f\n", PERCOV)
    end

    # Default cover type if no trees present
    if COVTYP == 0
        if iyr == IY[1]
            @printf(io_units[Int32(JOSTND)],
                    "\n *** FFE MODEL WARNING: NO INITIAL BASAL AREA\n *** COVER TYPE SET TO RED OAK\n\n")
            RCDSET(Int32(2), true)
            global COVTYP = Int32(75)
        else
            global COVTYP = OLDCOVTYP
        end
    end
    global OLDCOVTYP = COVTYP

    # --- Initialize dead fuels on first year only ---
    if iyr == IY[1]

        # Map FIA forest type to FFE dead fuel group
        local ftdeadfu::Int32
        if 101 <= IFORTP <= 105
            ftdeadfu = Int32(1)   # eastern white pine
        elseif IFORTP == 141 || IFORTP == 142
            ftdeadfu = Int32(2)   # longleaf-slash pine
        elseif 161 <= IFORTP <= 168
            ftdeadfu = Int32(3)   # loblolly-shortleaf pine
        elseif IFORTP == 181 || IFORTP == 402
            ftdeadfu = Int32(4)   # eastern redcedar
        elseif IFORTP == 401 || (403 <= IFORTP <= 409)
            ftdeadfu = Int32(5)   # oak-pine
        elseif 501 <= IFORTP <= 520
            ftdeadfu = Int32(6)   # oak-hickory
        elseif 601 <= IFORTP <= 608
            ftdeadfu = Int32(7)   # oak-gum-cypress
        elseif 701 <= IFORTP <= 709
            ftdeadfu = Int32(8)   # elm-ash-cottonwood
        elseif 801 <= IFORTP <= 809
            ftdeadfu = Int32(9)   # maple-beech-birch
        else
            ftdeadfu = Int32(6)   # default: oak-hickory
        end

        local stfuel = zeros(Float32, MXFLCL, 2)
        for isz in 1:MXFLCL
            stfuel[isz, 2] = fuini[isz, ftdeadfu]
            stfuel[isz, 1] = 0.0f0
        end

        # Adjust from photo series (keyword 2548)
        local ntodo_ref = Ref(Int32(0))
        OPFIND(Int32(1), Int32[myact[2]], ntodo_ref)
        local j_op::Int32 = ntodo_ref[]
        if j_op > 0
            local jyr_ref  = Ref(Int32(0))
            local iactk_ref= Ref(Int32(0))
            local nprm_ref = Ref(Int32(0))
            local prms     = zeros(Float32, 12)
            OPGET(Int32(j_op), Int32(2), jyr_ref, iactk_ref, nprm_ref, prms)
            if (prms[1] >= 0f0) && (prms[2] >= 0f0)
                local fotoval  = zeros(Float32, MXFLCL)
                local fotovals = zeros(Float32, 9)
                FMPHOTOVAL(Int32(round(prms[1])), Int32(round(prms[2])), fotoval, fotovals)
                for i in 1:MXFLCL
                    if fotoval[i] >= 0f0; stfuel[i, 2] = fotoval[i]; end
                    if i <= 9; stfuel[i, 1] = fotovals[i]; end
                end
                if (fotoval[1] >= 0f0) && (iswtch != 1)
                    OPDONE(Int32(j_op), Int32(iyr))
                end
            else
                @printf(io_units[Int32(JOSTND)],
                        "\n *** FFE MODEL WARNING: INCORRECT PHOTO REFERENCE OR PHOTO CODE ENTERED.  BOTH FIELDS ARE REQUIRED.\n\n")
                RCDSET(Int32(2), true)
            end
        end

        # Adjust from FUELINIT keyword (2521)
        OPFIND(Int32(1), Int32[myact[1]], ntodo_ref)
        j_op = ntodo_ref[]
        if j_op > 0
            local jyr2_ref   = Ref(Int32(0))
            local iactk2_ref = Ref(Int32(0))
            local nprm2_ref  = Ref(Int32(0))
            local prms2 = zeros(Float32, 12)
            OPGET(Int32(j_op), Int32(12), jyr2_ref, iactk2_ref, nprm2_ref, prms2)
            if prms2[2]  >= 0f0; stfuel[3,  2] = prms2[2];  end
            if prms2[3]  >= 0f0; stfuel[4,  2] = prms2[3];  end
            if prms2[4]  >= 0f0; stfuel[5,  2] = prms2[4];  end
            if prms2[5]  >= 0f0; stfuel[6,  2] = prms2[5];  end
            if prms2[6]  >= 0f0; stfuel[10, 2] = prms2[6];  end
            if prms2[7]  >= 0f0; stfuel[11, 2] = prms2[7];  end
            if prms2[8]  >= 0f0; stfuel[1,  2] = prms2[8];  end
            if prms2[9]  >= 0f0; stfuel[2,  2] = prms2[9];  end
            if prms2[1] >= 0f0
                if (prms2[8] < 0f0) && (prms2[9] < 0f0)
                    stfuel[1, 2] = prms2[1] * 0.5f0
                    stfuel[2, 2] = prms2[1] * 0.5f0
                end
                if (prms2[8] < 0f0) && (prms2[9] >= 0f0)
                    stfuel[1, 2] = max(prms2[1] - prms2[9], 0.0f0)
                end
                if (prms2[8] >= 0f0) && (prms2[9] < 0f0)
                    stfuel[2, 2] = max(prms2[1] - prms2[8], 0.0f0)
                end
            end
            if prms2[10] >= 0f0; stfuel[7, 2] = prms2[10]; end
            if prms2[11] >= 0f0; stfuel[8, 2] = prms2[11]; end
            if prms2[12] >= 0f0; stfuel[9, 2] = prms2[12]; end
            if iswtch != 1
                OPDONE(Int32(j_op), Int32(iyr))
            end
        end

        # Adjust from FUELSOFT keyword (2553)
        OPFIND(Int32(1), Int32[myact[3]], ntodo_ref)
        j_op = ntodo_ref[]
        if j_op > 0
            local jyr3_ref   = Ref(Int32(0))
            local iactk3_ref = Ref(Int32(0))
            local nprm3_ref  = Ref(Int32(0))
            local prms3 = zeros(Float32, 9)
            OPGET(Int32(j_op), Int32(9), jyr3_ref, iactk3_ref, nprm3_ref, prms3)
            if prms3[1] >= 0f0; stfuel[1, 1] = prms3[1]; end
            if prms3[2] >= 0f0; stfuel[2, 1] = prms3[2]; end
            if prms3[3] >= 0f0; stfuel[3, 1] = prms3[3]; end
            if prms3[4] >= 0f0; stfuel[4, 1] = prms3[4]; end
            if prms3[5] >= 0f0; stfuel[5, 1] = prms3[5]; end
            if prms3[6] >= 0f0; stfuel[6, 1] = prms3[6]; end
            if prms3[7] >= 0f0; stfuel[7, 1] = prms3[7]; end
            if prms3[8] >= 0f0; stfuel[8, 1] = prms3[8]; end
            if prms3[9] >= 0f0; stfuel[9, 1] = prms3[9]; end
            if iswtch != 1
                OPDONE(Int32(j_op), Int32(iyr))
            end
        end

        # Distribute initial dead fuels across decay classes (proportional to species BA)
        local tba_local = zeros(Float32, MAXSP)
        if ITRN > 0
            for i in 1:ITRN
                if FMPROB[i] > 0.0f0
                    local ksp2::Int32 = ISP[i]
                    local ba2::Float32 = 3.14159f0 * (DBH[i]/24.0f0)^2
                    tba_local[ksp2] += ba2 * FMPROB[i]
                end
            end
        end
        local totba2::Float32 = sum(tba_local)

        for isz in 1:MXFLCL
            if totba2 > 0.0f0
                for ksp in 1:MAXSP
                    if tba_local[ksp] > 0.0f0
                        local prcl::Float32 = tba_local[ksp] / totba2
                        local idc::Int32    = DKRCLS[ksp]
                        for jj in 1:2
                            CWD[1, isz, jj, idc] += prcl * stfuel[isz, jj]
                        end
                    end
                end
            else
                local idc2::Int32 = DKRCLS[COVTYP]
                for jj in 1:2
                    CWD[1, isz, jj, idc2] += stfuel[isz, jj]
                end
            end
        end

        # Set carbon reporting region from KODFOR (first year only)
        local ifk::Int32 = Int32(KODFOR ÷ 100)
        if ifk ∈ (803, 805, 808, 811, 812)
            global ICHABT = Int32(2)
        end
    end

    return nothing
end

# ENTRY SNGCOE — sets snag fall/decay parameters when FFE is not active (SO variant only)
function SNGCOE()
    return nothing
end
