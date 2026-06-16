# fmscro.f — Crown material fall schedule for newly dead snags
# FMSCRO: divides snag crown weight into future CWD2B pools
# ICALL: 1=after fire, 2=after cut, 4=mortality reconciliation
# Called from: FMSADD

function FMSCRO(i::Integer, sp::Integer, deadyr::Integer, dsnags::Real, icall::Integer)
    debug = DBCHK("FMSCRO", 6, ICYC)

    if Float32(dsnags) <= 0.0f0; return nothing; end

    local dkcl::Int = Int(DKRCLS[sp])
    local yrscyc::Float32 = Float32(IY[ICYC + 1] - deadyr)

    # Years between death and next simulated year
    local ynexty::Int
    if deadyr < IY[1]
        ynexty = Int(IY[1]) - Int(deadyr)
    else
        ynexty = 1
    end

    # If all material falls before simulation begins, skip
    if ynexty > Int(TFMAX); return nothing; end

    # Predict years-to-soft for this species+DBH
    local tsoft_ref = Ref(Float32(0))
    FMSNGDK(String(VARACD), Int32(sp), DBH[i], tsoft_ref)
    local tsoft::Float32 = tsoft_ref[]

    if debug
        @printf(get(io_units, Int32(JOSTND), stdout),
            " FMSCRO CYCLE=%2d TSOFT=%10.1f KODFOR=%5d VARACD=%s\n",
            ICYC, tsoft, KODFOR, VARACD)
    end

    # Fraction of crown change per year if called from CUTS (icall==2)
    local x::Float32 = 1.0f0
    if icall == 2
        local oldbot::Float32 = OLDHT[i] - OLDCRL[i]
        local newbot::Float32 = HT[i] - HT[i] * Float32(FMICR[i]) / 100.0f0
        if OLDCRL[i] > 0.0f0 && (newbot - oldbot) > 0.0f0
            x = ((newbot - oldbot) / OLDCRL[i]) / yrscyc
        else
            x = 0.0f0
        end
    end

    # SIZE=0:5 in Fortran → SIZE+1 in Julia (1:6)
    for size_f in 0:5
        local size_j::Int = size_f + 1

        local rlife::Float32 = TFALL[sp, size_j]
        if rlife > tsoft; rlife = tsoft; end

        local ilife::Int = Int(floor(rlife))
        if Float32(ilife) < rlife || ilife <= 0; ilife += 1; end
        rlife = Float32(ilife)

        local annual::Float32 = CROWNW[i, size_j]
        if icall != 4
            local oldcrw_val::Float32 = OLDCRW[i, size_j]
            if oldcrw_val < 0.0000625f0; oldcrw_val = 0.0f0; end
            if size_f > 0
                annual += yrscyc * oldcrw_val * x
            end
        end
        annual *= Float32(dsnags) / rlife

        if debug
            @printf(get(io_units, Int32(JOSTND), stdout),
                " annual=%g yrscyc=%g oldcrw=%g x=%g i=%d size=%d CROWNW=%g dsnags=%g rlife=%g\n",
                annual, yrscyc, OLDCRW[i, size_j], x, i, size_f, CROWNW[i, size_j], dsnags, rlife)
        end

        if annual > 0.0f0
            for iyr in ynexty:ilife
                local fallyr::Int = iyr + 1 - ynexty
                if icall != 4
                    CWD2B2[dkcl, size_j, fallyr] += annual
                else
                    CWD2B[dkcl, size_j, fallyr] += annual
                end
            end
        end
    end

    return nothing
end
