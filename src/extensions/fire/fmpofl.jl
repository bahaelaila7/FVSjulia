# fire/fmpofl.f — Potential fire report (FMPOFL) + torching probability (FMPOFL_FMPTRH)
#                + standard normal CDF (FMPOFL_NPROB)
# FMPOFL: drives FMMOIS→FMFINT→FMCFIR→FMEFF→FMCONS for 3 wind/moisture scenarios;
#         writes to JPOTFL; calls DBSFMPFC (cycle 1 only) and DBSFMPF.
# FMPOFL_FMPTRH: Monte Carlo torching probability (30 reps, virtual plot PSIZE=0.025 ac).
# FMPOFL_NPROB: Adams (1969) standard normal CDF (double precision).
# Called from: FMMAIN

function FMPOFL(iyr::Integer, fmd::Integer=Int32(0), lnmout::Bool=true)
    debug = DBCHK("FMPOFL", 6, ICYC)

    # Year gate
    if !(iyr == 0 && iyr == Int(IPFLME))
        if Int(iyr) < Int(IPFLMB) || Int(iyr) > Int(IPFLME)
            return nothing
        end
    end

    local sn_cs = VARACD in ("SN","CS")
    local swind = Int32[20, 10, 5, 0]
    local oinit1 = zeros(Float32, 3)
    local oact1  = zeros(Float32, 3)
    local oinit2 = zeros(Float32, 3)
    local oact2  = zeros(Float32, 3)
    local pflam  = zeros(Float32, 4)

    local irtncd_ref = Ref(Int32(0))

    # Per-scenario potential-fire results, indexed by FMOIS (1=severe, 3=moderate)
    local pokill = zeros(Float32, 4)   # mortality fraction by FMOIS
    local povolk = zeros(Float32, 2)   # volume killed by IK
    local psmoke = zeros(Float32, 2)   # smoke (PM2.5) by IK

    # Canopy wind-reduction multiplier (fmpofl.f:81 — same as FMBURN)
    local wmult = ALGSLP(PERCOV, CANCLS, CORFAC, Int32(4))
    # Dominant fuel model for the scenario (set by FMCFMD below)
    local fmd_ref = Ref(Int32(0))
    # Severe-case fuel models/weights, saved during FMOIS=1 (fmpofl.f:230-236)
    local sfmod = zeros(Int32, 4)
    local sfwt  = zeros(Float32, 4)

    # Three wind/moisture scenarios: FMOIS=1 (severe), FMOIS=3 (moderate) → step 2 (1,3)
    for fmois in 1:2:3
        local idpl = fmois == 3 ? 2 : 1

        # Scenario wind, moisture preset, and PRESVL overrides (fmpofl.f:111-125)
        swind[fmois] = round(Int32, PREWND[idpl])
        FMMOIS(Int32(fmois), MOIS)
        if PRESVL[idpl, 1] == 1.0f0
            MOIS[1, 1] = PRESVL[idpl, 2]
            MOIS[1, 2] = PRESVL[idpl, 3]
            MOIS[1, 3] = PRESVL[idpl, 4]
            MOIS[1, 4] = PRESVL[idpl, 5]
            MOIS[1, 5] = PRESVL[idpl, 6]
            MOIS[2, 1] = PRESVL[idpl, 7]
            MOIS[2, 2] = PRESVL[idpl, 8]
        end
        # FMFINT reads the canopy-adjusted wind FWIND, not WNDSPD (fmpofl.f:125)
        global FWIND = Float32(swind[fmois]) * wmult

        # Set up the (departure) fuel model for this scenario — SN variant path
        # (fmpofl.f:132-141). Without this FMFINT has no fuel loads and returns 0.
        if Int(IFLOGIC) == 0 && VARACD in ("CR", "CS", "LS", "SN", "TT", "UT")
            FMCFMD(Int32(iyr), fmd_ref)
        end

        # Byram's fireline intensity + flame length for this scenario
        local byram_ref = Ref(Float32(0))
        local flame_ref = Ref(Float32(0))
        local hpa_ref   = Ref(Float32(0))
        FMFINT(Int32(iyr), byram_ref, flame_ref, Int32(fmois), hpa_ref, Int32(1))
        fvsGetRtnCode(irtncd_ref)
        if irtncd_ref[] != Int32(0)
            return nothing
        end

        # PFLAM(FMOIS) and PFLAM(FMOIS+1) hold the (surface) flame length
        pflam[fmois]   = flame_ref[]
        pflam[fmois+1] = flame_ref[]

        # Scorch height (fmpofl.f:161-163) — read by FMEFF for crown scorch.
        # Convert Byram intensity to BTU/ft/s first.
        local byr = byram_ref[] / 60.0f0
        global SCH = (63.0f0 / (140.0f0 - POTEMP[idpl])) *
                     (byr^(7.0f0 / 6.0f0) / sqrt(byr + FWIND^3.0f0))

        # SN/CS variants: surface fire only — no crown fire
        global CRBURN = 0.0f0
        local ik = fmois == 3 ? 2 : 1
        oinit1[ik] = -1.0f0
        oact1[ik]  = -1.0f0

        # Potential mortality (BA fraction) and volume killed from FMEFF
        local pomort_ref = Ref(Float32(0))
        local povolk_ref = Ref(Float32(0))
        local fmd_use = fmd_ref[] > 0 ? fmd_ref[] :
                        ((length(FMOD) >= 1 && FMOD[1] > 0) ? Int32(FMOD[1]) : Int32(8))
        # POTPAB(IK) = percent area burned (default 100) — gates per-tree mortality
        FMEFF(Int32(iyr), fmd_use, pflam[fmois], Int32(1),
              pomort_ref, povolk_ref, Int32(1), POTPAB[ik])
        fvsGetRtnCode(irtncd_ref)
        if irtncd_ref[] == Int32(0)
            pokill[fmois] = pomort_ref[]
            povolk[ik]    = povolk_ref[]
            # Potential smoke production (PM2.5)
            local psmoke_ref = Ref(Float32(0))
            FMCONS(Int32(fmois), Int32(0), Float32(0.0), Int32(iyr), Int32(1),
                   psmoke_ref, POTPAB[ik])
            fvsGetRtnCode(irtncd_ref)
            psmoke[ik] = irtncd_ref[] == Int32(0) ? psmoke_ref[] : 0.0f0
        end
        fvsSetRtnCode(Int32(0))

        # Save the severe-case fuel models (FMOIS=1); moderate uses live FMOD/FWT
        if fmois == 1
            for k in 1:min(4, length(FMOD))
                sfmod[k] = FMOD[k]
                sfwt[k]  = FWT[k]
            end
        end
    end

    # Torching probability
    local ptr1_ref = Ref(0.0f0)
    local ptr2_ref = Ref(0.0f0)
    FMPOFL_FMPTRH(iyr, Int32(ITRN), FMPROB, pflam[2], pflam[4],
                  ptr1_ref, ptr2_ref)

    # Event monitor output
    EVSET4(Int32(22), oact1[1])
    EVSET4(Int32(23), oact1[2])
    EVSET4(Int32(24), oact2[1])
    EVSET4(Int32(25), oact2[2])
    EVSET4(Int32(26), ptr1_ref[])
    EVSET4(Int32(27), ptr2_ref[])

    if !lnmout; return nothing; end

    # ── Database output — written before (and independent of) the text report
    #    file, matching the Fortran order (DBSFMPF precedes GETLUN(JPOTFL)). ──
    if Int(ICYC) == 1
        # FVS_PotFire_Cond: one row per scenario (idpm 1=Severe wild, 2=Moderate pres)
        for idpm in 1:2
            local m = idpm == 2 ? Int32(3) : Int32(1)
            FMMOIS(m, MOIS)
            if PRESVL[idpm, 1] == 1.0f0
                MOIS[1,1] = PRESVL[idpm,2]; MOIS[1,2] = PRESVL[idpm,3]
                MOIS[1,3] = PRESVL[idpm,4]; MOIS[1,4] = PRESVL[idpm,5]
                MOIS[1,5] = PRESVL[idpm,6]; MOIS[2,1] = PRESVL[idpm,7]
                MOIS[2,2] = PRESVL[idpm,8]
            end
            DBSFMPFC(NPLT, Float64(PREWND[idpm]), round(Int, POTEMP[idpm]),
                     100.0*MOIS[1,1], 100.0*MOIS[1,2], 100.0*MOIS[1,3],
                     100.0*MOIS[1,4], 100.0*MOIS[1,5], 100.0*MOIS[2,1],
                     100.0*MOIS[2,2], idpm)
        end
    end
    # FVS_PotFire_East row: flame (severe/moderate), canopy ht/density,
    # mortality (BA %, volume), and smoke (severe/moderate).
    DBSFMPF(iyr,
            pflam[2], pflam[4],                       # Flame_Len_Sev / _Mod
            Int(ACTCBH), Float64(CBD),                # Canopy_Ht / Canopy_Density
            trunc(Int, pokill[1] * 100.0f0), trunc(Int, pokill[3] * 100.0f0),  # Mortality_BA_Sev/_Mod
            trunc(Int, povolk[1]), trunc(Int, povolk[2]),   # Mortality_VOL_Sev/_Mod
            Float64(psmoke[1]) * Float64(P2T), Float64(psmoke[2]) * Float64(P2T),  # Pot_Smoke_Sev/_Mod
            FMOD, FWT, sfmod, sfwt)                    # moderate (live FMOD/FWT) / severe (saved)

    # ── Text report file (skipped when no JPOTFL unit is open) ──
    local jpf = Int(JPOTFL)
    if jpf <= 0 || !haskey(io_units, Int32(jpf))
        return nothing
    end
    local io = io_units[Int32(jpf)]
    if Int(ICYC) == 1
        @printf(io, "1%s\n", repeat(" ", 132))
        @printf(io, " %s POTENTIAL FIRE BEHAVIOR\n", MGMID[1:min(end,26)])
        @printf(io, "%s\n", repeat("-", 132))
    end
    @printf(io,
        " %4d  %6.0f %6.0f  %6.2f %6.2f  %6.4f %6.4f\n",
        iyr, oact1[1], oact1[2], pflam[2], pflam[4], ptr1_ref[], ptr2_ref[])

    if debug
        @printf(get(io_units, Int32(JOSTND), stdout),
            " FMPOFL IYR=%5d FINT=%8.1f CRBURN=%8.3f PTR1=%7.4f PTR2=%7.4f\n",
            iyr, FINT, CRBURN, ptr1_ref[], ptr2_ref[])
    end
    return nothing
end


function FMPOFL_FMPTRH(iyr::Integer, mxi_in::Integer, fmprob::AbstractVector{Float32},
                        pflam1::Real, pflam2::Real,
                        ptr1_ref::Ref{Float32}, ptr2_ref::Ref{Float32})
    local mxreps = 30
    local psize  = 0.0250f0    # virtual plot size in acres
    local mxi    = Int(mxi_in)

    ptr1_ref[] = 0.0f0
    ptr2_ref[] = 0.0f0

    if mxi <= 0; return nothing; end

    # Crown base heights
    local cbh = [HT[i] * (1.0 - Float32(ICR[i]) * 0.01f0) for i in 1:mxi]

    # Sort trees by CBH ascending (use Double for sort compatibility)
    local indx = zeros(Int32, mxi)
    RDPSRT(mxi, Float64.(cbh), indx, true)

    # Save RNG state, advance by iyr mod 10 steps
    local saveso = RANNGET()
    for i in 1:mod(iyr, 10); RANN(); end

    # Monte Carlo: MXREPS virtual plots
    local nptr1 = 0; local nptr2 = 0

    for irep in 1:mxreps
        # Randomly sample trees for this virtual plot
        local plot_ba = 0.0f0
        local plot_trees = Int[]

        for i in 1:mxi
            local ii = Int(indx[i])
            local tpa_i = fmprob[ii] * P2T * psize   # expected trees on plot
            if tpa_i <= 0.0f0; continue; end
            # Stochastic inclusion
            local frac = tpa_i - floor(tpa_i)
            local n    = Int(floor(tpa_i)) + (RANN() < Float64(frac) ? 1 : 0)
            for _ in 1:n
                push!(plot_trees, ii)
            end
        end

        if isempty(plot_trees)
            continue
        end

        # Torching model (lognormal, Scott & Reinhardt 2001)
        # FLM1 = surface fireline intensity for moisture scenario 1
        local flm1 = max(Float32(pflam1), 0.001f0)
        local flm2 = max(Float32(pflam2), 0.001f0)

        # Critical fireline intensity for each tree using lowest CBH
        local sort_cbh = [cbh[j] for j in plot_trees]
        sort!(sort_cbh)
        local cbh_low = isempty(sort_cbh) ? 99.0f0 : Float32(sort_cbh[1])

        # Lognormal parameters (Scott & Reinhardt Table 1)
        local mxnt1 = log(((flm1 / 0.0775f0)^1.45f0) / 30.5f0)
        local mxnt2 = log(((flm2 / 0.0775f0)^1.45f0) / 30.5f0)
        local sigma  = 0.90f0

        # Critical crown fire initiation for this CBH
        # I_0 = (0.010 * CBH * 460 + 25.9)^1.5 / (0.0775 * 30.5)
        local icrit = cbh_low > 0.0f0 ?
            ((0.010f0 * cbh_low * 460.0f0 + 25.9f0)^1.5f0) / (0.0775f0 * 30.5f0) : 9999.0f0
        local licrit = log(max(icrit, 0.001f0))

        local q1_ref  = Ref(0.0); local pt1_ref = Ref(0.0); local pdf_ref = Ref(0.0)
        local z1 = (licrit - mxnt1) / sigma
        FMPOFL_NPROB(z1, q1_ref, pt1_ref, pdf_ref)
        if Float32(q1_ref[]) > 0.5f0; nptr1 += 1; end

        local q2_ref  = Ref(0.0); local pt2_ref = Ref(0.0)
        local z2 = (licrit - mxnt2) / sigma
        FMPOFL_NPROB(z2, q2_ref, pt2_ref, pdf_ref)
        if Float32(q2_ref[]) > 0.5f0; nptr2 += 1; end
    end

    ptr1_ref[] = Float32(nptr1) / Float32(mxreps)
    ptr2_ref[] = Float32(nptr2) / Float32(mxreps)

    RANNPUT(saveso)
    return nothing
end


# Adams (1969) standard normal CDF
# Returns P (cumulative left of Z), Q (right of Z = 1-P), PDF
function FMPOFL_NPROB(z::Real,
                       q_ref::Ref{Float64}, p_ref::Ref{Float64}, pdf_ref::Ref{Float64})
    # Coefficients (Adams 1969)
    local a0 =  0.5000000000
    local a1 = -0.3989422804
    local a2 =  0.3989422804
    local a3 = -0.1330274429
    local a4 =  0.0
    local a5 =  0.3193815202
    local a6 = -0.3565637913
    local a7 =  1.7814779372

    local b0  =  0.2316419
    local b1  =  0.3193815202
    local b2  = -0.3565637913
    local b3  =  1.7814779372
    local b4  = -1.8212559978
    local b5  =  1.3302744293
    local b6  =  0.0
    local b7  = -0.2367914695
    local b8  =  0.0
    local b9  =  0.3193815202
    local b10 = -0.3565637913
    local b11 =  1.7814779372

    local zd  = Float64(z)
    local abz = abs(zd)

    local pdf_v = exp(-0.5 * zd * zd) / sqrt(2.0 * pi)
    pdf_ref[] = pdf_v

    local p_v::Float64
    local q_v::Float64

    if abz <= 1.28
        # Series expansion (small |Z|)
        local t = 1.0 / (1.0 + b0 * abz)
        local poly = b1 + t * (b2 + t * (b3 + t * (b4 + t * (b5))))
        p_v = 0.5 + pdf_v * poly * (zd < 0.0 ? -1.0 : 1.0)
        q_v = 1.0 - p_v
    elseif abz <= 12.7
        # Continued fraction
        local t = 1.0 / (1.0 + b0 * abz)
        local poly = t * (b9 + t * (b10 + t * b11))
        local tail = pdf_v * poly
        if zd >= 0.0
            p_v = 1.0 - tail
            q_v = tail
        else
            p_v = tail
            q_v = 1.0 - tail
        end
    else
        # Far tail
        if zd >= 0.0
            p_v = 1.0
            q_v = 0.0
        else
            p_v = 0.0
            q_v = 1.0
        end
    end

    p_ref[] = p_v
    q_ref[] = q_v
    return nothing
end
