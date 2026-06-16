# SUBROUTINE FMSNAG(IYR, YR1) — annual snag dynamics
# Translated from: fmsnag.f (299 lines)
#
# Called from FMMAIN inner year loop. Processes each snag record:
#   - Adds user-specified initial snags on first year
#   - Computes fall rates (normal + post-burn) for hard/soft snags
#   - Removes fallen snags, adds debris to CWD pools
#   - Updates snag heights (top breakage via FMSNGHT)
#   - Transitions hard → soft snags via FMSNGDK
#
# Note: HARD in Fortran → HARD_FM in Julia (avoidance of Base.HARD if any; matches fmcom.jl)

function FMSNAG(iyr::Integer, yr1::Integer)
    local debug::Bool = false
    DBCHK(Ref(debug), "FMSNAG", Int32(6), ICYC)
    if debug
        @printf(io_units[Int32(JOSTND)], " FMSNAG CYCLE=%2d IYR=%5d YR1=%5d NSNAG=%5d\n",
                ICYC, iyr, yr1, NSNAG)
    end

    # On first year: process any user-specified initial snags (keyword 2522)
    if iyr == yr1
        local myact = Int32[2522]
        local ntodo_ref = Ref(Int32(0))
        OPFIND(Int32(1), myact, ntodo_ref)
        local ntodo = ntodo_ref[]
        for jdo in 1:ntodo
            local jyr_ref  = Ref(Int32(0))
            local iactk_ref= Ref(Int32(0))
            local nprm_ref = Ref(Int32(0))
            local prms     = zeros(Float32, 6)
            OPGET(Int32(jdo), Int32(6), jyr_ref, iactk_ref, nprm_ref, prms)
            local jsp::Int32  = Int32(prms[1])
            local d::Float32  = prms[2]
            local htd::Float32= prms[3]
            local age::Float32= prms[5]
            local year::Int32 = Int32(Float32(iyr) - age)
            local snum::Float32= prms[6]
            if debug
                @printf(io_units[Int32(JOSTND)], " IN FMSNAG JDO=%d JSP=%d\n", jdo, jsp)
            end
            FMSSEE(Int32(1), jsp, d, htd, snum, Int32(4), debug, Int32(JOSTND))
            FMSADD(year, Int32(-jdo))
            OPDONE(Int32(jdo), Int32(iyr))
        end
    end

    local dzero::Float32 = NZERO / 50.0f0

    if NSNAG <= 0; return; end

    # RNG state save/restore for stochastic variants (not SN, but faithful translation)
    local rng_save::Bool = VARACD ∈ ("BM","EC","OP","PN","SO","WC")
    local saveso::Float64 = rng_save ? RANNGET() : 0.0

    for i in 1:NSNAG

        if debug
            @printf(io_units[Int32(JOSTND)], " IN FMSNAG I=%d DENIS=%.4f DENIH=%.4f\n",
                    i, DENIS[i], DENIH[i])
        end

        if (DENIS[i] + DENIH[i]) <= 0.0f0; continue; end

        local jsp::Int32 = SPS[i]

        # Species-specific aspen/cottonwood/birch flag for UT, TT, CR, BC variants
        local lasco::Bool = false
        if VARACD == "UT"
            lasco = (jsp == 6 || jsp == 18 || jsp == 19)
        elseif VARACD == "TT"
            lasco = (jsp == 6 || jsp == 15)
        elseif VARACD == "CR"
            lasco = (jsp == 20 || jsp == 21 || jsp == 22 || jsp == 28)
        elseif VARACD == "BC"
            lasco = (jsp == 11 || jsp == 12 || jsp == 13 || jsp == 15)
        end

        # Compute base fall rates under normal and post-burn conditions
        jsp = SPS[i]
        local denttl::Float32 = DENIH[i] + DENIS[i]
        local rsoft_ref  = Ref(Float32(0))
        local rsmal_ref  = Ref(Float32(0))
        local dfalln_ref = Ref(Float32(0))
        FMSFALL(Int32(iyr), jsp, DBHS[i], DEND[i], denttl, Int32(1),
                rsoft_ref, rsmal_ref, dfalln_ref)
        local rsoft::Float32  = rsoft_ref[]
        local rsmal::Float32  = rsmal_ref[]
        local dfalln::Float32 = dfalln_ref[]

        # Set post-burn fall rates (year of or year after fire)
        if (iyr - BURNYR) <= 1
            PBFRIS[i] = rsoft
            PBFRIH[i] = 0.0f0
            if DBHS[i] < PBSIZE
                PBFRIH[i] = rsmal
                if (PBFRIH[i] < PBFRIS[i]) && (!HARD_FM[i])
                    PBFRIH[i] = PBFRIS[i]
                end
                if PBFRIH[i] > PBFRIS[i]
                    PBFRIS[i] = PBFRIH[i]
                end
            end
        end

        # Proportion of hard/soft snags falling (split by density fraction)
        local dfis::Float32 = DENIS[i] * dfalln / (DENIS[i] + DENIH[i])
        local dfih::Float32 = DENIH[i] * dfalln / (DENIS[i] + DENIH[i])

        if (BURNYR > 0) && (YRDEAD[i] <= BURNYR)
            if lasco && ((iyr - BURNYR) <= 10)
                dfis *= 0.5f0
                dfih *= 0.5f0
                local xs::Float32 = PBFRIS[i] * DENIS[i]
                local xh::Float32 = PBFRIH[i] * DENIH[i]
                if dfis < xs; dfis = xs; end
                if dfih < xh; dfih = xh; end
            elseif (iyr - BURNYR) <= Int32(PBTIME)
                local xs2::Float32 = PBFRIS[i] * DENIS[i]
                local xh2::Float32 = PBFRIH[i] * DENIH[i]
                if dfis < xs2; dfis = xs2; end
                if dfih < xh2; dfih = xh2; end
            end
        end

        # Clamp: if fewer than DZERO would remain, remove all
        if dfis > (DENIS[i] - dzero); dfis = DENIS[i]; end
        if dfih > (DENIH[i] - dzero); dfih = DENIH[i]; end
        DENIS[i] -= dfis
        DENIH[i] -= dfih

        # Add fallen snag material to down debris pools
        CWD1(Int32(i), dfih, dfis)

        # Skip further processing if this record is now empty
        if (DENIS[i] + DENIH[i]) <= dzero
            DENIS[i] = 0.0f0
            DENIH[i] = 0.0f0
            continue
        end

        # Predict snag height loss due to top breakage
        local oldhth::Float32 = -1.0f0
        local oldhts::Float32 = -1.0f0
        local htsnew_ref = Ref(Float32(0))

        if DENIH[i] > 0.0f0
            oldhth = HTIH[i]
            FMSNGHT(VARACD, jsp, HTDEAD[i], HTIH[i], Int32(1), htsnew_ref)
            HTIH[i] = htsnew_ref[]
        end
        if DENIS[i] > 0.0f0
            oldhts = HTIS[i]
            FMSNGHT(VARACD, jsp, HTDEAD[i], HTIS[i], Int32(0), htsnew_ref)
            HTIS[i] = htsnew_ref[]
        end

        CWD2(Int32(i), DENIH[i], DENIS[i], oldhth, oldhts)

        # Zero-height snags are removed (threshold varies by variant)
        if VARACD ∈ ("CR","TT","UT")
            if (DENIH[i] > 0.0f0) && (HTIH[i] < 1.5f0); DENIH[i] = 0.0f0; end
            if (DENIS[i] > 0.0f0) && (HTIS[i] < 1.5f0); DENIS[i] = 0.0f0; end
        else
            if (DENIH[i] > 0.0f0) && (HTIH[i] < 1.0f0); DENIH[i] = 0.0f0; end
            if (DENIS[i] > 0.0f0) && (HTIS[i] < 1.0f0); DENIS[i] = 0.0f0; end
        end

        if (DENIS[i] + DENIH[i]) <= 0.0f0; continue; end

        # Hard → soft transition: check if elapsed time since death exceeds decay time
        if (DENIH[i] > 0.0f0) && HARD_FM[i]
            local dktime_ref = Ref(Float32(0))
            FMSNGDK(VARACD, jsp, DBHS[i], dktime_ref)
            local dktime::Float32 = dktime_ref[]
            if (iyr - YRDEAD[i]) >= Int32(dktime)
                HARD_FM[i] = false
            end
        end

    end

    if rng_save; RANNPUT(saveso); end

    return nothing
end
