# fire/fmpofl.f — Potential fire report (FMPOFL) + torching probability (FMPOFL_FMPTRH)
#                + standard normal CDF (FMPOFL_NPROB)
# FMPOFL: drives FMMOIS→FMFINT→FMCFIR→FMEFF→FMCONS for 3 wind/moisture scenarios;
#         writes to JPOTFL; calls DBSFMPFC (cycle 1 only) and DBSFMPF.
# FMPOFL_FMPTRH: Monte Carlo torching probability (30 reps, virtual plot PSIZE=0.025 ac).
# FMPOFL_NPROB: Adams (1969) standard normal CDF (double precision).
# Called from: FMMAIN

function FMPOFL(iyr::Integer)
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

    # Three wind/moisture scenarios: FMOIS=1 (high), FMOIS=3 (low) → step 2 (1,3)
    local iscen = 0
    for fmois in 1:2:3
        iscen += 1
        local idpl = fmois == 3 ? 2 : 1

        # Override wind with scenario wind
        swind[fmois] = round(Int32, PREWND[idpl])
        local save_wndspd = WNDSPD
        global WNDSPD = Float32(swind[fmois])

        FMMOIS(Int32(fmois))
        FMFINT(Int32(0), Int32(0))
        fvsGetRtnCode(irtncd_ref)
        if irtncd_ref[] != Int32(0)
            global WNDSPD = save_wndspd
            return nothing
        end
        FMCFIR(Int32(0))
        FMEFF(Int32(0))
        FMCONS(Int32(0))

        if sn_cs
            # SN/CS: no crown fire, force surface only
            global CRBURN   = 0.0f0
            local cftype_tmp = Int32(-1)
            oinit1[iscen]   = FINT
            oact1[iscen]    = FINT
            oinit2[iscen]   = 0.0f0
            oact2[iscen]    = 0.0f0
        else
            oinit1[iscen] = FINT
            oact1[iscen]  = FINT
            oinit2[iscen] = CRBURN
            oact2[iscen]  = CRBURN
        end

        pflam[iscen] = FINT > 0.0f0 ? 1.0f0 : 0.0f0

        global WNDSPD = save_wndspd
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

    if !LNMOUT; return nothing; end

    # Open potential fire output file if needed
    local jpf = Int(JPOTFL)
    if jpf <= 0 || !haskey(io_units, Int32(jpf))
        return nothing
    end
    local io = io_units[Int32(jpf)]

    # Write header (first call of this stand)
    if Int(ICYC) == 1
        if sn_cs
            @printf(io, "1%s\n", repeat(" ", 132))
            @printf(io, " %s POTENTIAL FIRE BEHAVIOR\n", MGMID[1:min(end,26)])
            @printf(io, "%s\n", repeat("-", 132))
        else
            @printf(io, "1%s\n", repeat(" ", 132))
            @printf(io, " %s POTENTIAL FIRE BEHAVIOR\n", MGMID[1:min(end,26)])
            @printf(io, "%s\n", repeat("-", 132))
        end
        DBSFMPFC(iyr)
    end

    # Write per-year row
    if sn_cs
        # Format 51 (SN/CS): two columns surface only
        local snfms1 = round(Int32, oact1[1])
        local snfms2 = round(Int32, oact1[2])
        @printf(io,
            " %4d  %6.0f %6.0f  %6.2f %6.2f  %6.4f %6.4f\n",
            iyr, oact1[1], oact1[2], pflam[2], pflam[4], ptr1_ref[], ptr2_ref[])
    else
        # Format 49 (other variants): surface + crown
        @printf(io,
            " %4d  %6.0f %6.0f  %6.0f %6.0f  %6.2f %6.2f  %6.4f %6.4f\n",
            iyr, oact1[1], oact1[2], oact2[1], oact2[2],
            pflam[2], pflam[4], ptr1_ref[], ptr2_ref[])
    end

    DBSFMPF(iyr, oact1[1], oact1[2], oact2[1], oact2[2],
            pflam[2], pflam[4], ptr1_ref[], ptr2_ref[])

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
            local n    = Int(floor(tpa_i)) + (RANN() < Double64(frac) ? 1 : 0)
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
