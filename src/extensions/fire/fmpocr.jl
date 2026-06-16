# fire/fmpocr.f — Crown base height and crown bulk density
# FMPOCR: fills CRFILL[400] crown fuel lbs/ft, 13-ft running average → ACTCBH + CBD
# Black Hills PP (LBHPP): Weibull distribution; standard case: uniform with partial intervals.
# Called from: FMCFMD3, FMMAIN (when BURNYR≠IYR)

function FMPOCR(iyr::Integer, icall::Integer)
    debug = DBCHK("FMPOCR", 6, ICYC)
    if debug
        @printf(get(io_units, Int32(JOSTND), stdout),
            " FMPOCR CYCLE=%2d IYR=%5d ICALL=%2d ITRN=%5d\n", ICYC, iyr, icall, ITRN)
    end

    local mxi = Int(ITRN)
    if mxi <= 0
        global ACTCBH = 0.0f0
        global CBD     = 0.0f0
        global TCLOAD  = 0.0f0
        return nothing
    end

    # Per-tree crown base heights (HT * (1 - ICR%))
    local cbh = [HT[i] * (1.0f0 - Float32(ICR[i]) * 0.01f0) for i in 1:mxi]

    # Save and restore RNG state (fire model has its own RNG stream)
    local saveso = RANNGET()

    # Seed RNG from IYR + stand-level state
    for i in 1:mod(iyr, 10); RANN(); end

    # CRFILL: lbs of crown fuel per vertical foot, from ground (ft 1) to 400 ft
    local crfill = zeros(Float32, 400)

    # Black Hills ponderosa pine flag
    local lbhpp = LBHPP

    # Per-species max relative density for Weibull (Black Hills PP only)
    local msdi = 0.0f0
    if lbhpp
        local bacount = 0.0f0
        for i in 1:mxi
            if Int(ISP[i]) == Int(IBHPP)
                msdi    += PROB[i] * DBH[i]^1.605f0
                bacount += PROB[i]
            end
        end
        msdi = msdi * 0.00545415f0  # BA-based SDI: π/576 * Σ(TPA*DBH^1.605)
    end

    for i in 1:mxi
        local ht_i   = Float32(HT[i])
        local cbh_i  = cbh[i]
        local prob_i = FMPROB[i]

        if ht_i <= 0.0f0 || cbh_i >= ht_i; continue; end

        local adcrwn::Float32
        if lbhpp && Int(ISP[i]) == Int(IBHPP)
            # Weibull distribution for Black Hills PP
            local ht_m = ht_i / 3.28084f0  # ft → m
            local mrd  = msdi > 0.0f0 ? msdi / SDIMX[Int(ISP[i])] : 0.0f0
            local bw   = 7.1386f0 - 0.0608f0 * ht_m
            local cw   = 3.3126f0 - 0.0214f0 * ht_m - 1.1622f0 * mrd
            bw = max(bw, 0.1f0); cw = max(cw, 0.1f0)
            local total_wt = (CROWNW[i, 1] + CROWNW[i, 2] * 0.5f0) * prob_i * P2T
            if total_wt <= 0.0f0; continue; end
            # Fill from base to top using Weibull CDF increments
            local i1 = max(1, Int(round(cbh_i)) + 1)
            local i2 = min(400, Int(round(ht_i)))
            local span = Float32(i2 - i1 + 1)
            if span <= 0.0f0; continue; end
            local prev_cdf = 0.0f0
            for j in i1:i2
                local frac = (Float32(j - i1 + 1)) / span
                local arg  = (frac / bw)^cw
                local cdf  = 1.0f0 - exp(-arg)
                crfill[j] += total_wt * (cdf - prev_cdf) / 1.0f0
                prev_cdf   = cdf
            end
        else
            # Standard: uniform crown fuel density over crown length
            adcrwn = (CROWNW[i, 1] + CROWNW[i, 2] * 0.5f0) * prob_i * P2T
            if adcrwn <= 0.0f0; continue; end
            local crown_len = ht_i - cbh_i
            if crown_len <= 0.0f0; continue; end
            local density = adcrwn / crown_len  # lbs per foot

            local i1f = cbh_i
            local i2f = ht_i
            local i1  = max(1, Int(floor(i1f)) + 1)
            local i2  = min(400, Int(floor(i2f)))

            if i1 > i2; continue; end

            # Partial intervals at top and bottom
            local bot_frac = Float32(i1) - i1f   # fraction of first cell above cbh
            local top_frac = i2f - Float32(i2)   # fraction of last cell below ht

            for j in i1:i2
                crfill[j] += density
            end
            # Correct partial bottom cell: only the fraction above cbh_i
            if i1 >= 1 && i1 <= 400
                crfill[i1] -= density * (1.0f0 - bot_frac)
            end
            # Correct partial top cell: only the fraction below ht_i
            if i2 >= 1 && i2 <= 400 && top_frac < 1.0f0
                crfill[i2] -= density * (1.0f0 - top_frac)
            end
        end
    end

    # 13-ft running average (window half-width = 6 ft, centred)
    local cbhcut = CBHCUT   # minimum CBH threshold (kg/m³ equivalent)
    local cbd_max  = 0.0f0
    local actcbh_j = 0

    for j in 1:400
        local j1 = max(1,   j - 6)
        local j2 = min(400, j + 6)
        local avg = sum(crfill[j1:j2]) / Float32(j2 - j1 + 1)
        if avg > cbd_max
            cbd_max  = avg
            actcbh_j = 0
        end
        if avg >= cbhcut && actcbh_j == 0 && j > 1
            actcbh_j = j
        end
    end

    # Convert lbs/ft → kg/m³ for CBD (1 lb/ft = 1.6018 kg/m³)
    local cbd_kgm3 = cbd_max * 1.6018f0
    cbd_kgm3 = min(cbd_kgm3, 0.35f0)

    global ACTCBH = Float32(actcbh_j)
    global CBD     = cbd_kgm3
    global TCLOAD  = sum(crfill) / 43560.0f0   # lbs → tons/acre

    if debug
        @printf(get(io_units, Int32(JOSTND), stdout),
            " FMPOCR ACTCBH=%8.2f CBD=%8.4f TCLOAD=%9.4f\n", ACTCBH, CBD, TCLOAD)
    end

    # Optionally write canopy profile to DBS
    if Int(ICFPB) != 9999 && Int(icall) == 2
        DBSFMCANPR(iyr, crfill)
    end

    RANNPUT(saveso)
    return nothing
end
