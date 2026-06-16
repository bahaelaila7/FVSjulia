# fmcons.f — Fuel consumption, smoke production, mineral soil exposure
# FMCONS: dynamic fuel consumed + smoke per fire event
# Called from: FMBURN, FMPOFL

# Emission factors: EMMFAC(moisture_class 1-3, fuel_class 1-MXFLCL, piled/unpiled 1-2, PM2.5/PM10 1-2)
# Laid out in Fortran column-major order for DATA statement
const _FMCONS_EMMFAC = let
    raw = Float32[
        # IP=1 (unpiled), IPM=1 (PM2.5)
        7.9f0,7.9f0,7.9f0, 7.9f0,7.9f0,7.9f0, 11.9f0,11.9f0,11.9f0,
        22.5f0,18.3f0,16.2f0, 22.5f0,18.3f0,16.2f0, 22.5f0,18.3f0,16.2f0,
        22.5f0,18.3f0,16.2f0, 22.5f0,18.3f0,16.2f0, 22.5f0,18.3f0,16.2f0,
        7.9f0,7.9f0,7.9f0, 23.9f0,25.8f0,25.8f0,
        # IP=2 (piled), IPM=1
        17.0f0,17.0f0,17.0f0, 17.0f0,17.0f0,17.0f0, 17.0f0,17.0f0,17.0f0,
        17.0f0,17.0f0,17.0f0, 17.0f0,17.0f0,17.0f0, 17.0f0,17.0f0,17.0f0,
        17.0f0,17.0f0,17.0f0, 17.0f0,17.0f0,17.0f0, 17.0f0,17.0f0,17.0f0,
        17.0f0,17.0f0,17.0f0, 17.0f0,17.0f0,17.0f0,
        # IP=1 (unpiled), IPM=2 (PM10)
        9.3f0,9.3f0,9.3f0, 9.3f0,9.3f0,9.3f0, 14.0f0,14.0f0,14.0f0,
        26.6f0,21.6f0,19.1f0, 26.6f0,21.6f0,19.1f0, 26.6f0,21.6f0,19.1f0,
        26.6f0,21.6f0,19.1f0, 26.6f0,21.6f0,19.1f0, 26.6f0,21.6f0,19.1f0,
        9.3f0,9.3f0,9.3f0, 28.2f0,30.4f0,30.4f0,
        # IP=2 (piled), IPM=2
        20.0f0,20.0f0,20.0f0, 20.0f0,20.0f0,20.0f0, 20.0f0,20.0f0,20.0f0,
        20.0f0,20.0f0,20.0f0, 20.0f0,20.0f0,20.0f0, 20.0f0,20.0f0,20.0f0,
        20.0f0,20.0f0,20.0f0, 20.0f0,20.0f0,20.0f0, 20.0f0,20.0f0,20.0f0,
        20.0f0,20.0f0,20.0f0, 20.0f0,20.0f0,20.0f0,
    ]
    # reshape to (3, MXFLCL, 2, 2): (moisture, fuelclass, pile, pmsize)
    reshape(raw, 3, 11, 2, 2)
end

# Live fuel emission factors: EMFACL(4, 2): rows=(live_herb, live_shrub, ?, crown), cols=(PM2.5, PM10)
const _FMCONS_EMFACL = Float32[21.3f0 25.1f0; 21.3f0 25.1f0; 21.3f0 25.1f0; 21.3f0 25.1f0]

const _FMCONS_PDIA = Float32[4.0f0, 8.0f0, 15.0f0, 15.0f0, 15.0f0, 15.0f0]

function FMCONS(fmois::Integer, btype::Integer, plarea::Real, iyr::Integer, icall::Integer,
                psmoke_ref::Ref{Float32}, psburn::Real)
    debug = DBCHK("FMCONS", 6, ICYC)
    if debug
        @printf(io_units[JOSTND], " ENTERING ROUTINE FMCONS CYCLE = %2d ICALL=%2d\n", ICYC, icall)
    end

    if icall == 0
        EVSET4(Int32(20), 1.0f0)
        EVSET4(Int32(23), Float32(iyr))
    end

    local burnz  = zeros(Float32, 2, Int(MXFLCL))
    local prburn = zeros(Float32, 2, Int(MXFLCL))
    local plvbrn = zeros(Float32, 2)

    for i in 1:2
        for j in 1:Int(MXFLCL)
            if (btype == 0 && i == 1) || (btype == 1 && i == 2)
                for k in 1:2; for l in 1:4
                    burnz[i,j] += CWD[i,j,k,l]
                end; end
            end
        end
    end

    if btype == 0
        # Unpiled fuels: 1-3" class
        if (iyr - HARVYR) > 5   # natural
            prburn[1,3] = 0.65f0
        else                     # activity fuels
            if MOIS[1,2] < 0.137f0
                prburn[1,3] = 1.0f0
            elseif MOIS[1,2] <= 0.34f0
                local cons::Float32 = (167.0f0 - 4.89f0 * MOIS[1,2] * 100.0f0) / 100.0f0
                prburn[1,3] = clamp(cons, 0.0f0, 1.0f0)
            end
        end

        # <3" classes
        if burnz[1,3] > 0.0f0
            if prburn[1,3] > 0.9f0
                prburn[1,1] = 1.0f0; prburn[1,2] = 1.0f0
            else
                prburn[1,1] = 0.9f0; prburn[1,2] = 0.9f0
            end
        else
            prburn[1,1] = 1.0f0; prburn[1,2] = 1.0f0
        end

        # >3" classes
        for il in 4:9
            local diared::Float32
            local cons2::Float32
            if (iyr - HARVYR) > 5
                diared = 3.38f0 - 0.027f0 * MOIS[1,4] * 100.0f0
                if MOIS[1,4] > 1.25f0 || diared < 0.0f0; diared = 0.0f0; end
                cons2 = 1.0f0 - ((_FMCONS_PDIA[il-3] - diared) / _FMCONS_PDIA[il-3])^2
            else
                diared = 4.35f0 - 0.096f0 * MOIS[1,4] * 100.0f0
                if MOIS[1,4] > 0.45f0 || diared < 0.0f0; diared = 0.0f0; end
                cons2 = 1.0f0 - ((_FMCONS_PDIA[il-3] - diared) / _FMCONS_PDIA[il-3])^2
            end
            prburn[1,il] = cons2
        end

        # Duff
        local prduf::Float32 = 83.7f0 - 0.426f0 * MOIS[1,5] * 100.0f0
        if prduf < 0.0f0; prduf = 0.0f0; end
        prburn[1,11] = clamp(prduf / 100.0f0, 0.0f0, 1.0f0)
        global EXPOSR = -8.98f0 + 0.899f0 * prduf
        if prduf < 10.0f0; global EXPOSR = Float32(0.0); end

        # Litter (100% consumed)
        prburn[1,10] = 1.0f0

        # Live fuels
        plvbrn[1] = 1.0f0; plvbrn[2] = 0.6f0

        for i in 1:Int(MXFLCL)
            prburn[1,i] *= Float32(psburn) / 100.0f0
        end
        plvbrn[1] *= Float32(psburn) / 100.0f0
        plvbrn[2] *= Float32(psburn) / 100.0f0
        global EXPOSR = EXPOSR * Float32(psburn) / 100.0f0
    else
        # Piled fuels
        prburn[2,1] = 1.0f0; prburn[2,2] = 1.0f0
        for il in 3:9; prburn[2,il] = 0.9f0; end
        prburn[2,11] = 1.0f0; prburn[2,10] = 1.0f0
        plvbrn[1] = 0.0f0; plvbrn[2] = 0.0f0
        global EXPOSR = Float32(plarea) * 100.0f0
    end

    if icall != 1
        EVSET4(Int32(21), EXPOSR)

        if LAUTAL
            local prms = Float32[EXPOSR]
            local kode_ref = Ref(Int32(0))
            OPADD(Int32(iyr), Int32(491), Int32(0), Int32(1), prms, kode_ref)
            prms[1] = Float32(iyr)
            OPADD(Int32(iyr), Int32(427), Int32(0), Int32(1), prms, kode_ref)
            OPINCR(IY, ICYC, NCYC)
        end

        # Accumulate pre-burn CWD into TCWD (compressed)
        fill!(TCWD, 0.0f0)
        for p in 1:2; for h in 1:2; for d in 1:4
            TCWD[1] += CWD[p,10,h,d]
            TCWD[2] += CWD[p,11,h,d]
            TCWD[3] += CWD[p,1,h,d] + CWD[p,2,h,d] + CWD[p,3,h,d]
            TCWD[4] += CWD[p,4,h,d]
            TCWD[5] += CWD[p,5,h,d]
            TCWD[6] += CWD[p,6,h,d] + CWD[p,7,h,d] + CWD[p,8,h,d] + CWD[p,9,h,d]
        end; end; end

        local ip_idx = btype == 1 ? 2 : 1
        for j in 1:Int(MXFLCL)
            if burnz[ip_idx, j] > 0.0f0
                BURNED[ip_idx, j] = burnz[ip_idx, j] * prburn[ip_idx, j]
                BURNED[3, j] += BURNED[ip_idx, j]
                for k in 1:2; for l in 1:4
                    CWD[ip_idx, j, k, l] *= (1.0f0 - prburn[ip_idx, j])
                end; end
            end
        end

        BURNLV[1] = plvbrn[1] * FLIVE[1]
        BURNLV[2] = plvbrn[2] * FLIVE[2]
    end

    # Smoke production
    local im::Int32 = MOIS[1,4] <= 0.20f0 ? Int32(3) :
                      MOIS[1,4] <= 0.375f0 ? Int32(2) : Int32(1)
    local ip::Int32 = btype == 1 ? Int32(2) : Int32(1)

    for ipm in 1:2
        local tsmoke::Float32 = 0.0f0
        for il in 1:Int(MXFLCL)
            tsmoke += prburn[ip,il] * burnz[ip,il] * _FMCONS_EMMFAC[im, il, ip, ipm]
        end
        if btype == 0
            for il in 1:2
                tsmoke += plvbrn[il] * FLIVE[il] * _FMCONS_EMFACL[il, ipm]
            end
            local crown_src = icall == 0 ? BURNCR : PBRNCR
            tsmoke += crown_src * _FMCONS_EMFACL[4, ipm]
        end
        if icall == 0
            SMOKE[ipm] += tsmoke
        elseif icall == 1 && ipm == 1
            psmoke_ref[] = tsmoke
        end
    end

    if debug
        @printf(io_units[JOSTND], " FMCONS CYCLE = %2d PSMOKE=%10.4f\n", ICYC, psmoke_ref[])
    end
    return nothing
end
