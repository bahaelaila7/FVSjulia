# fmeff.f — Fire-caused tree mortality probability + crown fate
# FMEFF: per-tree fire mortality, crown material accounting, snag seeding
# Called from: FMBURN, FMPOFL
# SN-variant: uses Regelbrugge & Smith (1994) equations for key spp groups

const _FMEFF_MORTB0 = Float32[1.0229f0, 0.1683f0, 1.2165f0, 0.8221f0, 2.775f0]
const _FMEFF_MORTB1 = Float32[-0.2646f0,-0.1332f0,-0.4758f0,-0.4098f0,-1.1224f0]
const _FMEFF_MORTB2 = Float32[2.6232f0, 3.4152f0, 6.0415f0, 8.4682f0, 2.8312f0]

function FMEFF(iyr::Integer, fm::Integer, flame::Real, icall::Integer,
               pomort_ref::Ref{Float32}, pvolkl_ref::Ref{Float32},
               mkode::Integer, psburn::Real)
    debug = DBCHK("FMEFF", 5, ICYC)
    if debug
        @printf(io_units[JOSTND],
            " ENTERING FMEFF CYCLE = %2d IYR=%5d FM=%3d FLAME=%14.4f CRBURN=%10.4f ICALL=%2d\n",
            ICYC, iyr, fm, flame, CRBURN, icall)
    end

    local yrscyc::Float32 = Float32(IY[ICYC+1] - iyr)
    local bamort::Float32  = 0.0f0
    local totba::Float32   = 0.0f0
    pomort_ref[] = 0.0f0
    pvolkl_ref[] = 0.0f0

    # Burn crowns of pre-existing snags caught in crown fire portion
    local bcrown::Float32 = 0.0f0
    if CRBURN > 0.0f0
        for isz in 0:5
            for idc in 1:4
                for itm in 1:Int(TFMAX)
                    local bcr::Float32 = CRBURN * CWD2B[idc, isz+1, itm] * Float32(psburn) / 100.0f0
                    if icall == 0
                        CWD2B[idc, isz+1, itm] -= bcr
                    end
                    bcrown += bcr * P2T
                    bcr = CRBURN * CWD2B2[idc, isz+1, itm] * Float32(psburn) / 100.0f0
                    if icall == 0
                        CWD2B2[idc, isz+1, itm] -= bcr
                    end
                    bcrown += bcr * P2T
                end
            end
        end
    end

    local saveso::Float64 = RANNGET()

    for i in 1:Int(ITRN)
        local pmort::Float32 = 0.0f0
        local lpsburn::Bool  = true
        local xran::Float32  = RANN() * 100.0f0

        if debug
            @printf(io_units[JOSTND],
                " FMEFF YEAR = %5d I=%5d XRAN=%6.4f KSP=%4d DBH=%6.2f\n",
                iyr, i, xran/100.0f0, ISP[i], DBH[i])
        end

        if xran > Float32(psburn)
            lpsburn = false
            @goto label_90
        end

        local ksp::Int32 = ISP[i]
        local crl::Float32 = HT[i] * (Float32(FMICR[i]) / 100.0f0)
        local sl::Float32  = SCH - (HT[i] - crl)
        sl = clamp(sl, 0.0f0, crl)

        if FMPROB[i] > 0.0f0 && mkode != 0
            local csv::Float32
            if crl > 0.0f0
                local clsp::Float32 = min(100.0f0 * sl / crl, 100.0f0)
                csv = 100.0f0 * (sl * (2.0f0 * crl - sl) / (crl * crl))
            else
                csv = 100.0f0
            end

            local xm::Float32 = exp(-1.941f0 + 6.316f0 * (1.0f0 - exp(-FMBRKT(DBH[i], ksp)))
                                    - 0.000535f0 * csv * csv)
            pmort = 1.0f0 / (1.0f0 + xm)

            # SN/CS species-specific adjustment (Regelbrugge & Smith 1994)
            if VARACD == "SN" || VARACD == "CS"
                local charht::Float32 = Float32(flame) * 0.7f0
                local mortgp::Int32
                if VARACD == "SN"
                    if ksp == Int32(63) || ksp == Int32(74)
                        mortgp = Int32(1)  # white/chestnut oak
                    elseif ksp == Int32(64) || ksp == Int32(75) || ksp == Int32(78)
                        mortgp = Int32(2)  # scarlet/black/NR oak
                    elseif ksp == Int32(27)
                        mortgp = Int32(3)  # hickory
                    elseif ksp == Int32(20)
                        mortgp = Int32(4)  # red maple
                    elseif ksp == Int32(54)
                        mortgp = Int32(5)  # black gum
                    else
                        mortgp = Int32(6)
                    end
                else  # CS
                    if ksp == Int32(47) || ksp == Int32(59)
                        mortgp = Int32(1)
                    elseif Int32(48) <= ksp <= Int32(51)
                        mortgp = Int32(2)
                    elseif Int32(14) <= ksp <= Int32(23)
                        mortgp = Int32(3)
                    elseif ksp == Int32(29)
                        mortgp = Int32(4)
                    elseif ksp == Int32(11) || ksp == Int32(13)
                        mortgp = Int32(5)
                    else
                        mortgp = Int32(6)
                    end
                end
                if mortgp <= 5
                    xm = -1.0f0 * (_FMEFF_MORTB0[mortgp]
                                   + _FMEFF_MORTB1[mortgp] * DBH[i] * 2.54f0
                                   + _FMEFF_MORTB2[mortgp] * charht / 3.28f0)
                    local mnmort::Float32 = log(1.0f0/0.000001f0 - 1.0f0)
                    if xm >= mnmort
                        pmort = 0.0f0
                    else
                        pmort = 1.0f0 / (1.0f0 + exp(xm))
                    end
                end
                # mortgp == 6: keep FOFEM estimate
            end

            # Engelmann spruce minimum mortality 0.8 (IE/EM/KT variants)
            if VARACD == "IE" || VARACD == "EM" || VARACD == "KT"
                if ksp == Int32(8); pmort = max(0.8f0, pmort); end
            end

            # Lake States (LS/ON) adjustments
            if VARACD == "LS" || VARACD == "ON"
                if BURNSEAS <= Int32(2) && ksp <= Int32(14); pmort /= 2.0f0; end
                if ksp == Int32(8); pmort = max(0.7f0, pmort); end
                if ksp in (Int32(18),Int32(19),Int32(26),Int32(27),Int32(51),Int32(52))
                    if DBH[i] < 4.0f0; pmort = 1.0f0; end
                end
                if BURNSEAS <= Int32(2) && ksp > Int32(14)
                    if Int32(30) <= ksp <= Int32(36)
                        pmort = DBH[i] >= 2.5f0 ? pmort / 2.0f0 : pmort * 0.8f0
                    else
                        pmort *= 0.8f0
                    end
                end
                if ksp > Int32(14) && DBH[i] <= 1.0f0; pmort = 1.0f0; end
            end

            # NE variant adjustments
            if VARACD == "NE"
                if BURNSEAS <= Int32(2) && ksp <= Int32(25); pmort /= 2.0f0; end
                if ksp == Int32(1); pmort = max(0.7f0, pmort); end
                if ksp in (Int32(26),Int32(27),Int32(28),Int32(29),Int32(99),Int32(100))
                    if DBH[i] < 4.0f0; pmort = 1.0f0; end
                end
                if BURNSEAS <= Int32(2) && ksp > Int32(25)
                    if (Int32(55) <= ksp <= Int32(70)) || ksp == Int32(89)
                        pmort = DBH[i] >= 2.5f0 ? pmort / 2.0f0 : pmort * 0.8f0
                    else
                        pmort *= 0.8f0
                    end
                end
                if ksp > Int32(25) && DBH[i] <= 1.0f0; pmort = 1.0f0; end
            end

            if DBH[i] <= 1.0f0 && csv > 50.0f0; pmort = 1.0f0; end
        end

        # Apply multiplier
        pmort = clamp(pmort * FMORTMLT[i], 0.0f0, 1.0f0)

        if debug
            @printf(io_units[JOSTND], " ENTERING FMEFF CYCLE = %2d IYR=%5d PSBURN=%6.1f\n",
                    ICYC, iyr, psburn)
        end

        if FMPROB[i] <= 0.0f0; @goto label_90; end

        # Crown fire portion: burn all foliage + 50% of 0-0.25" material
        if CRBURN > 0.0f0 && mkode != 0
            # Save original crown weights
            local tcrown = copy(view(CROWNW, i, :))  # indices 1..6 (0..5 shifted)
            local toldcr = copy(view(OLDCRW, i, :))

            bcrown += CRBURN * FMPROB[i] * P2T * CROWNW[i, 1]   # foliage (ISZ=0 → col 1)
            bcrown += 0.5f0 * CRBURN * FMPROB[i] * P2T *
                     (CROWNW[i, 2] + yrscyc * OLDCRW[i, 2])  # 0-0.25" (ISZ=1 → col 2)

            if icall == 0
                CROWNW[i, 1] = 0.0f0
                CROWNW[i, 2] = 0.5f0 * CROWNW[i, 2]
                OLDCRW[i, 2] = 0.5f0 * OLDCRW[i, 2]
                local dthisc::Float32 = FMPROB[i] * CRBURN
                FMSCRO(Int32(i), Int32(ISP[i]), Int32(iyr), dthisc, Int32(1))
                # Restore original crown weights
                for isz in 1:6; CROWNW[i, isz] = tcrown[isz]; end
                OLDCRW[i, 2] = toldcr[2]
            end
        end

        if CRBURN >= 1.0f0; @goto label_90; end

        # Surface fire: partial crown burning where flame reaches crown bottom
        local crbot::Float32 = HT[i] - crl
        local tcrown2 = copy(view(CROWNW, i, :))
        local toldcr2 = copy(view(OLDCRW, i, :))

        if SCH > crbot
            local crbnl::Float32 = min(SCH - crbot, crl)
            local propcr::Float32 = crl > 0.0f0 ? crbnl / crl : 0.0f0
            local crw1bn::Float32 = 0.5f0 * propcr * CROWNW[i, 2]

            if mkode != 0
                bcrown += (1.0f0 - CRBURN) * FMPROB[i] * P2T * CROWNW[i, 1] * propcr
                bcrown += (crw1bn + 0.5f0 * yrscyc * OLDCRW[i, 2]) *
                          (1.0f0 - CRBURN) * FMPROB[i] * P2T
            else
                bcrown += FMPROB[i] * P2T * CROWNW[i, 1] * propcr
                bcrown += (crw1bn + 0.5f0 * yrscyc * OLDCRW[i, 2]) * FMPROB[i] * P2T
            end

            if icall == 0
                CROWNW[i, 1] -= propcr * CROWNW[i, 1]
                CROWNW[i, 2] -= crw1bn
                OLDCRW[i, 2] = 0.5f0 * OLDCRW[i, 2]
                local dthisc2::Float32 = (1.0f0 - CRBURN) * pmort * FMPROB[i]
                FMSCRO(Int32(i), Int32(ISP[i]), Int32(iyr), dthisc2, Int32(1))

                # Pool the killed portion of crown in CWD2B
                for isz in 1:6
                    if isz == 1
                        CROWNW[i, isz] = 0.0f0
                    elseif isz == 2
                        CROWNW[i, isz] = propcr * (CROWNW[i, isz] + crw1bn) - crw1bn
                    else
                        CROWNW[i, isz] = propcr * CROWNW[i, isz]
                    end
                    OLDCRW[i, isz] = 0.0f0
                end

                local dthisc3::Float32 = mkode != 0 ?
                    ((1.0f0 - CRBURN) - (1.0f0 - CRBURN) * pmort) * FMPROB[i] :
                    FMPROB[i]
                FMSCRO(Int32(i), Int32(ISP[i]), Int32(iyr), dthisc3, Int32(1))

                # Restore final crown weights (original minus consumed/killed)
                for isz in 1:6
                    CROWNW[i, isz] = tcrown2[isz] * (1.0f0 - propcr)
                    OLDCRW[i, isz] = isz == 2 ? toldcr2[isz] * 0.5f0 : toldcr2[isz]
                end

                GROW_FM[i] = Int32(-1)
                FMICR[i] = Int32(floor(100.0f0 * (crl - crbnl) / HT[i]))
            end
        elseif icall == 0
            local dthisc4::Float32 = (1.0f0 - CRBURN) * pmort * FMPROB[i]
            FMSCRO(Int32(i), Int32(ISP[i]), Int32(iyr), dthisc4, Int32(1))
        end

        @label label_90
        # Kill calculation
        if icall == 0
            CURKIL[i] = pmort * FMPROB[i]
            if mkode != 0 && lpsburn
                CURKIL[i] += CRBURN * (FMPROB[i] - CURKIL[i])
            end
            FIRKIL[i] += CURKIL[i]
            FMPROB[i] -= CURKIL[i]
            if FMPROB[i] < 0.0f0; FMPROB[i] = 0.0f0; end
            FMSSEE(Int32(i), Int32(ISP[i]), DBH[i], HT[i], CURKIL[i], Int32(1), debug, Int32(JOSTND))
        else
            local pomort_i::Float32 = pmort * FMPROB[i]
            if lpsburn; pomort_i += CRBURN * (FMPROB[i] - pomort_i); end
            bamort += pomort_i * (DBH[i] / 24.0f0)^2
            totba  += FMPROB[i] * (DBH[i] / 24.0f0)^2
            if VARACD == "CS" || VARACD == "LS" || VARACD == "NE" || VARACD == "SN"
                pvolkl_ref[] += MCFV[i] * pomort_i
            else
                pvolkl_ref[] += CFV[i] * pomort_i
            end
        end
    end  # i loop

    RANNPUT(saveso)

    # Post-loop: SVS outputs and snag pool additions
    if icall == 0
        FMSVTOBJ(Int32(FIRTYPE))
        SVMORT(Int32(1), FIRKIL, Int32(iyr))
        fill!(TCWD2, 0.0f0)
        for p in 1:2; for h in 1:2; for d in 1:4
            TCWD2[1] += CWD[p,10,h,d]
            TCWD2[2] += CWD[p,11,h,d]
            TCWD2[3] += CWD[p,1,h,d] + CWD[p,2,h,d] + CWD[p,3,h,d]
            TCWD2[4] += CWD[p,4,h,d]
            TCWD2[5] += CWD[p,5,h,d]
            TCWD2[6] += CWD[p,6,h,d] + CWD[p,7,h,d] + CWD[p,8,h,d] + CWD[p,9,h,d]
        end; end; end
        FMSVOUT(Int32(iyr), Float32(flame), Int32(FIRTYPE))
    end

    if icall != 0 && totba != 0.0f0
        pomort_ref[] = bamort / totba
    end

    if icall == 0
        FMSADD(Int32(iyr), Int32(1))
        global BURNCR = bcrown
    else
        global PBRNCR = bcrown
    end
    return nothing
end
