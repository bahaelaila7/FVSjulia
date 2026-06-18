# fire/fmpocr.f — Crown base height (ACTCBH) and crown bulk density (CBD)
# Fills CRFILL[400] (crown fuel lbs/acre per vertical foot), then finds the
# crown bulk density (max 13-ft running average) and the base of the live crown.
# TCLOAD = total canopy fuel load (lbs/sqft).
# Hardwoods (LSW false) do NOT contribute unless ICANSP==1 (Jan 2003).
# Black Hills PP (LBHPP: CR forest 203/207 sp13, IE/EM/KT sp10) uses a Weibull
# crown-mass distribution; the standard case is uniform with partial end intervals.
# Called from: FMCFMD2 (BURNYR≠IYR), FMMAIN.

function FMPOCR(iyr::Integer, icall::Integer)
    debug = DBCHK("FMPOCR", 6, ICYC)
    if debug
        @printf(get(io_units, Int32(JOSTND), stdout),
            " ENTERING FMPOCR CYCLE = %2d ITRN=%5d\n", ICYC, ITRN)
    end

    local crfill = zeros(Float32, 400)
    local mxi = Int(ITRN)

    # Metric relative density (Keyser & Smith 2010) for the Weibull (Black Hills PP)
    local msdi = 0.0f0
    for i in 1:mxi
        local dcm = DBH[i] * 2.54f0
        msdi += (FMPROB[i] * 2.47f0) * (dcm / 25.4f0)^1.6f0
    end
    local mrd = msdi / 1111.97f0
    if mrd > 1.0f0; mrd = 1.0f0; end

    for i in 1:mxi
        # Hardwoods do not contribute unless ICANSP==1; require live crown + min ht
        if !((LSW[Int(ISP[i])] || Int(ICANSP) == 1) &&
             Int(FMICR[i]) > 0 && HT[i] > CANMHT)
            continue
        end

        # Black Hills ponderosa pine special-shape flag
        local lbhpp = false
        if VARACD == "CR"
            if (Int(KODFOR) == 203 || Int(KODFOR) == 207) && Int(ISP[i]) == 13
                lbhpp = true
            end
        elseif VARACD in ("IE", "EM", "KT")
            if Int(ISP[i]) == 10; lbhpp = true; end
        end

        local crbot = HT[i] * (1.0f0 - Float32(FMICR[i]) * 0.01f0)
        if crbot < 0.0f0; crbot = 0.0f0; end

        if !lbhpp
            # ── Standard: uniform crown fuel density over the crown length ──
            local adcrwn = (CROWNW[i, 1] + CROWNW[i, 2] * 0.5f0) *
                           FMPROB[i] / (HT[i] - crbot)

            local i1 = Int(trunc(crbot)) + 1
            local i2 = Int(trunc(HT[i])) + 1
            if i1 > 400; i1 = 400; end
            if i2 > 400; i2 = 400; end

            if i1 <= i2 && adcrwn > 0.0f0
                for j in i1:i2
                    if j == i1
                        local adj = max(0.0f0, min(1.0f0, Float32(i1) - crbot))
                        crfill[j] += adcrwn * adj
                    elseif j == i2
                        local adj = max(0.0f0, min(1.0f0, Float32(i2) - HT[i]))
                        crfill[j] += adcrwn * (1.0f0 - adj)
                    else
                        crfill[j] += adcrwn
                    end
                end
            end
        else
            # ── Black Hills PP: Weibull-distributed crown mass ──
            local crbio = (CROWNW[i, 1] + CROWNW[i, 2] * 0.5f0) * FMPROB[i]
            local i1 = Int(trunc(crbot)) + 1
            local i2 = Int(trunc(HT[i])) + 1
            if (Float32(i2) - HT[i]) >= 1.0f0; i2 -= 1; end
            if i1 > 400; i1 = 400; end
            if i2 > 400; i2 = 400; end

            if i1 <= i2 && crbio > 0.0f0
                local ht_m = HT[i] / 3.28f0
                local weibb = 7.1386f0 - 0.0608f0 * ht_m
                local weibc = 3.3126f0 - 0.0214f0 * ht_m - 1.1622f0 * mrd
                local wtradj = 1.0f0 - exp(-((10.0f0 / weibb)^weibc))

                local tscl = Float32(i2 - i1)
                local secint = 10.0f0 / (tscl + 1.0f0)
                local adcrn = zeros(Float32, 400)
                local adcrwn = 0.0f0
                local secbnd = 0.0f0
                for j in i2:-1:i1
                    secbnd += secint
                    local wprop::Float32
                    if j == i2
                        wprop = 1.0f0 - exp(-((secbnd / weibb)^weibc))
                    else
                        wprop = (1.0f0 - exp(-((secbnd / weibb)^weibc))) -
                                (1.0f0 - exp(-(((secbnd - secint) / weibb)^weibc)))
                    end
                    adcrn[j] = (crbio * wprop) / wtradj
                    adcrwn += adcrn[j]
                end
                if i1 <= i2 && adcrwn > 0.0f0
                    for j in i1:i2
                        crfill[j] += adcrn[j]
                    end
                end
            end
        end
    end

    # Total canopy fuel load: lbs/acre summed, then converted to lbs/sqft
    local tcload = 0.0f0
    for j in 1:400
        tcload += crfill[j]
    end
    global TCLOAD = tcload / 43560.0f0
    if debug
        @printf(get(io_units, Int32(JOSTND), stdout), " TCLOAD = %g\n", TCLOAD)
    end

    # Pass the canopy profile to the DB (post-activity values only)
    if Int(ICFPB) != 9999 && Int(icall) == 2
        DBSFMCANPR(iyr, crfill, NPLT)
    end

    # ── Crown bulk density (max 13-ft running avg) + base of live crown ──
    global CBD    = 0.0f0
    global ACTCBH = Int32(-1)
    local mxj    = -1
    local abotmx = 0.0f0

    # Find the lowest foot with > 5 lbs/acre-ft (crown "starts")
    local j1 = 0
    for j in 1:400
        if crfill[j] > 5.0f0; j1 = j; break; end
    end

    if j1 != 0
        # Effective top of canopy
        local j2 = 201
        for j in 400:-1:1
            if crfill[j] > 5.0f0; j2 = j; break; end
        end

        if j1 == j2
            global CBD = crfill[j1]
            if crfill[j1] >= 5.0f0; global ACTCBH = Int32(j1); end
        else
            for j in j1:j2
                local i1 = max(j - 6, j1)
                local i2 = min(j + 6, j2)
                local a = 0.0f0
                for ii in i1:i2; a += crfill[ii]; end
                a /= Float32(i2 - i1 + 1)
                if a > CBD; global CBD = a; end

                # 3-ft running average for the base of the live crown
                i1 = max(j - 1, j1)
                i2 = min(j + 1, j2)
                local abot = 0.0f0
                for ii in i1:i2; abot += crfill[ii]; end
                abot /= Float32(i2 - i1 + 1)

                if abot > (abotmx + 0.1f0)
                    abotmx = abot
                    mxj = j
                end
                if abot >= CBHCUT && Int(ACTCBH) == -1
                    global ACTCBH = Int32(j)
                end
            end
        end

        if Int(ACTCBH) == -1 && abotmx > 5.0f0
            global ACTCBH = Int32(mxj)
        end
    end

    # Convert CBD lbs/acre-ft → kg/m³, cap at 0.35
    global CBD = CBD * 0.45359237f0 / (4046.856422f0 * 0.3048f0)
    if CBD > 0.35f0; global CBD = 0.35f0; end

    if debug
        @printf(get(io_units, Int32(JOSTND), stdout),
            " FMPOCR, CBD=%8.4f ACTCBH=%4d\n", CBD, ACTCBH)
    end

    return nothing
end
