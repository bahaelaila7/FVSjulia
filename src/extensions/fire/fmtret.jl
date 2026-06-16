# SUBROUTINE FMTRET(IYR) — fuel treatment activation (jackpot burns, pile burns)
# SUBROUTINE FMFMOV(IYR) — FUELMOVE keyword: transfer fuel among CWD pools
# Translated from: fmtret.f (403 lines)
#
# FMTRET: keyword 2523 (FUELBURN). Moves CWD to piled category, burns with FMCONS,
#         returns remaining piled fuel to unpiled, optionally kills trees (TRMORT).
# FMFMOV: keyword 2530 (FUELMOVE). Transfers fuel tonnage between size classes,
#         then recomputes LARGE/SMALL/SLCHNG.

function FMTRET(iyr::Integer)
    local debug::Bool = false
    DBCHK(Ref(debug), "FMTRET", Int32(6), ICYC)
    if debug
        @printf(io_units[Int32(JOSTND)], " ENTERING FMTRET CYCLE=%3d\n", ICYC)
    end

    global LFLBRN = false
    local myacts = Int32[2523]
    local jtodo_ref = Ref(Int32(0))
    OPFIND(Int32(1), myacts, jtodo_ref)
    local jtodo::Int32 = jtodo_ref[]
    if jtodo <= 0; return; end

    local affect::Float32 = 0.0f0
    local atreat::Float32 = 0.0f0
    local fulcon::Float32 = 0.0f0
    local trmort::Float32 = 0.0f0

    for jdo in 1:jtodo
        local jyr_ref   = Ref(Int32(0))
        local iactk_ref = Ref(Int32(0))
        local nprm_ref  = Ref(Int32(0))
        local prms      = zeros(Float32, 5)
        OPGET(Int32(jdo), Int32(5), jyr_ref, iactk_ref, nprm_ref, prms)
        affect = prms[2] / 100.0f0
        atreat = prms[3] / 100.0f0
        fulcon = prms[4] / 100.0f0
        trmort = min(max(0.0f0, prms[5] / 100.0f0), 1.0f0)
        global LFLBRN = true
        OPDONE(Int32(jdo), Int32(iyr))
    end

    if !LFLBRN; return; end

    if debug
        @printf(io_units[Int32(JOSTND)],
                " IN FMTRET AFFECT=%10.3f ATREAT=%10.3f FULCON=%10.3f TRMORT=%10.3f LFLBRN=%s\n",
                affect, atreat, fulcon, trmort, LFLBRN)
    end

    # Move fuel into piled category for burning
    # Woody classes 1-9: multiply by AFFECT*FULCON
    # Litter/duff classes 10-11: multiply by AFFECT*ATREAT (only under piles)
    for k in 1:2, ispd in 1:4
        for isz in 1:9
            local pile::Float32 = CWD[1, isz, k, ispd] * affect * fulcon
            CWD[1, isz, k, ispd] -= pile
            CWD[2, isz, k, ispd] += pile
        end
        for isz in 10:11
            local pile2::Float32 = CWD[1, isz, k, ispd] * affect * atreat
            CWD[1, isz, k, ispd] -= pile2
            CWD[2, isz, k, ispd] += pile2
        end
    end

    # Burn the piled material (medium moisture level = 3)
    local fmois_val::Int32 = Int32(3)
    FMMOIS(fmois_val, MOIS)
    local psmoke_ref = Ref(Float32(0))
    FMCONS(fmois_val, Int32(1), affect * atreat, Int32(iyr), Int32(0), psmoke_ref, Float32(100.0))

    # Return any remaining piled fuel to unpiled
    for k in 1:2, ispd in 1:4, isz in 1:MXFLCL
        local pile3::Float32 = CWD[2, isz, k, ispd]
        CWD[2, isz, k, ispd] -= pile3
        CWD[1, isz, k, ispd] += pile3
    end

    # Optional tree mortality from pile burn
    global PBURNYR = Int32(iyr)
    if trmort > 0.0f0
        for i in 1:ITRN
            local trkil::Float32 = FMPROB[i] * trmort
            if trkil >= FMPROB[i]
                trkil = FMPROB[i]
                FMPROB[i] = 0.0f0
            else
                FMPROB[i] = max(0.0f0, FMPROB[i] - trkil)
            end
            CURKIL[i] += trkil
            FIRKIL[i] += trkil

            FMSSEE(i, ISP[i], DBH[i], HT[i], CURKIL[i],
                   Int32(1), debug, Int32(JOSTND))
            FMSCRO(Int32(i), ISP[i], Int32(iyr), trkil, Int32(1))
        end
        FMSADD(Int32(iyr), Int32(1))
    end

    return nothing
end

function FMFMOV(iyr::Integer)
    local debug::Bool = false
    DBCHK(Ref(debug), "FMFMOV", Int32(5), ICYC)
    if debug
        @printf(io_units[Int32(JOSTND)], " ENTERING FMFMOV CYCLE = %2d\n", ICYC)
    end

    global TONRMC = Float32(0.0)
    local myact = Int32[2530]
    local ntodo_ref = Ref(Int32(0))
    OPFIND(Int32(1), myact, ntodo_ref)
    local ntodo::Int32 = ntodo_ref[]

    if ntodo > 0
        # Accumulate total fuel per size class across all sub-pools
        local forg = zeros(Float32, MXFLCL+1)  # index 0..MXFLCL → julia 1..MXFLCL+1
        local ftrg = zeros(Float32, MXFLCL+1)
        for j1 in 1:MXFLCL
            for i in 1:2, k in 1:2, l in 1:4
                forg[j1+1] += CWD[i, j1, k, l]
            end
        end
        local fsrc = copy(forg)

        local lalter::Bool = false
        for i in 1:ntodo
            local jyr_ref   = Ref(Int32(0))
            local iactk_ref = Ref(Int32(0))
            local nprm_ref  = Ref(Int32(0))
            local prms      = zeros(Float32, 6)
            OPGET(Int32(i), Int32(6), jyr_ref, iactk_ref, nprm_ref, prms)

            if iactk_ref[] < 0; continue; end

            local ifrom::Int32 = Int32(prms[1])
            local ito::Int32   = Int32(prms[2])
            local x::Float32   = prms[3]
            local y::Float32   = prms[4]
            local z::Float32   = prms[5]
            local q::Float32   = prms[6]

            # Validate parameters (ifrom/ito: 0=remove/add from outside)
            if (ifrom >= 0) && (ifrom <= MXFLCL) &&
               (ito   >= 0) && (ito   <= MXFLCL) &&
               (ifrom != ito) &&
               (x >= 0.0f0) &&
               (y >= 0.0f0) && (y <= 1.0f0) &&
               (z >= 0.0f0)

                local xget::Float32 = 0.0f0
                local isrc::Int = ifrom + 1   # 0-based → 1-based
                local itgt::Int = ito   + 1

                if ifrom > 0
                    if fsrc[isrc] <= 0.0f0
                        OPDEL1(Int32(i))
                        continue   # GOTO 550 → skip to next iteration
                    end

                    if q >= 0.0f0
                        xget = max(x, y*fsrc[isrc], fsrc[isrc]-z, q-fsrc[itgt])
                    else
                        xget = max(x, y*fsrc[isrc], fsrc[isrc]-z)
                    end

                    if xget > fsrc[isrc]; xget = fsrc[isrc]; end
                    prms[3] = xget
                    prms[4] = xget / fsrc[isrc]
                    prms[5] = fsrc[isrc] - xget
                    prms[6] = fsrc[itgt] + xget
                    fsrc[isrc] -= xget
                    if ito == 0; global TONRMC += xget; end
                else
                    if q >= 0.0f0
                        xget = max(x, q - fsrc[itgt])
                    else
                        xget = x
                    end
                    prms[3] = xget
                    prms[4] = 0.0f0
                    prms[5] = 0.0f0
                    prms[6] = ftrg[itgt] + xget
                    global TONRMC -= xget
                end

                ftrg[itgt] += xget

                if xget > 0.0f0
                    OPCHPR(Int32(i), Int32(6), prms)
                    OPDONE(Int32(i), Int32(iyr))
                    lalter = true
                else
                    OPDEL1(Int32(i))
                end

            else
                OPDEL1(Int32(i))
            end
        end  # end of NTODO loop (label 550 = loop end = continue)

        # Apply fuel pool changes proportionally
        if lalter
            for i in 0:MXFLCL
                ftrg[i+1] = fsrc[i+1] + ftrg[i+1]
            end
            for j1 in 1:MXFLCL
                if abs(forg[j1+1] - ftrg[j1+1]) >= 1.0f-6
                    if forg[j1+1] <= 1.0f-6
                        CWD[1, j1, 2, 3] = ftrg[j1+1]
                    else
                        local xscale::Float32 = ftrg[j1+1] / forg[j1+1]
                        for k in 1:2, l in 1:4, ii in 1:2
                            CWD[ii, j1, k, l] *= xscale
                        end
                    end
                end
            end
        end
    end  # end ntodo > 0 block   (label 506 falls through here)

    # Compute large/small fuel totals and percent change
    global OLARGE = LARGE
    global OSMALL = SMALL
    global LARGE  = Float32(0.0)
    global SMALL  = Float32(0.0)

    for i in 1:2, k in 1:2, l in 1:4
        for j1 in 1:3
            global SMALL += CWD[i, j1, k, l]
        end
        global SMALL += CWD[i, 10, k, l]   # litter = small
        for j2 in 4:9
            global LARGE += CWD[i, j2, k, l]
        end
    end

    local x_prev::Float32 = OLARGE + OSMALL
    if x_prev > 1.0f-6
        global SLCHNG = 100.0f0 * (LARGE + SMALL - x_prev) / x_prev
    else
        global SLCHNG = Float32(0.0)
    end

    return nothing
end
