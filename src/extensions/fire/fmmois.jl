# fmmois.f — SN variant fire moisture model
# FMMOIS: preset moisture levels for fire behavior (Terrell & Vickers values for SN)
# Called from: FMBURN, FMPOFL, FMIN, FMTRET

function FMMOIS(fmois::Integer, mois::AbstractMatrix{Float32})
    debug = DBCHK("FMMOIS", 6, ICYC)
    if debug
        @printf(io_units[JOSTND], " ENTERING ROUTINE FMMOIS CYCLE = %2d\n", ICYC)
    end

    if fmois == 0
        return nothing
    elseif fmois == 1   # VERY DRY
        mois[1,1] = 0.05f0; mois[1,2] = 0.07f0; mois[1,3] = 0.12f0
        mois[1,4] = 0.17f0; mois[1,5] = 0.40f0
        mois[2,1] = 0.55f0; mois[2,2] = 0.55f0
    elseif fmois == 2   # DRY
        mois[1,1] = 0.06f0; mois[1,2] = 0.08f0; mois[1,3] = 0.13f0
        mois[1,4] = 0.18f0; mois[1,5] = 0.75f0
        mois[2,1] = 0.80f0; mois[2,2] = 0.80f0
    elseif fmois == 3   # WET
        mois[1,1] = 0.07f0; mois[1,2] = 0.09f0; mois[1,3] = 0.14f0
        mois[1,4] = 0.20f0; mois[1,5] = 1.0f0
        mois[2,1] = 1.0f0;  mois[2,2] = 1.0f0
    elseif fmois == 4   # VERY WET
        mois[1,1] = 0.16f0; mois[1,2] = 0.16f0; mois[1,3] = 0.18f0
        mois[1,4] = 0.50f0; mois[1,5] = 1.75f0
        mois[2,1] = 1.5f0;  mois[2,2] = 1.5f0
    end
    return nothing
end
