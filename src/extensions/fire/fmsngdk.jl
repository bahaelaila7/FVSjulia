# SUBROUTINE FMSNGDK(VAR,KSP,D,DKTIME)
# Translated from: fmsngdk.f (86 lines), FIRE-VBASE
#
# Calculates years since death for a snag to become soft, based on species,
# DBH, and variant. SN variant → DEFAULT case: linear DBH formula.
# Called from: FMSNAG, FMSCRO, SVSNAGE

function FMSNGDK(varacd::AbstractString, ksp::Integer, d::Real, dktime_ref::Ref{Float32})
    local xmod_ref = Ref(Float32(1.0))
    SVHABT(xmod_ref)
    local xmod::Float32 = xmod_ref[]

    local dktime::Float32
    if varacd ∈ ("LS", "ON")
        dktime = 0.65f0 * DECAYX[ksp] * Float32(d)
        dktime *= xmod
    elseif varacd ∈ ("PN", "WC", "BM", "EC", "AK", "OP")
        local jyrsoft_ref = Ref(Int32(0))
        local jadj_ref    = Ref(Int32(0))
        local jsml_ref    = Ref(Int32(0))
        FMR6SDCY(Int32(ksp), Float32(d), jyrsoft_ref, jadj_ref, jsml_ref)
        dktime = Float32(jyrsoft_ref[]) * DECAYX[ksp]
    elseif varacd == "SO"
        if KODFOR ∈ (601, 602, 620, 799)   # Oregon
            local jyrsoft2_ref = Ref(Int32(0))
            local jadj2_ref    = Ref(Int32(0))
            local jsml2_ref    = Ref(Int32(0))
            FMR6SDCY(Int32(ksp), Float32(d), jyrsoft2_ref, jadj2_ref, jsml2_ref)
            dktime = Float32(jyrsoft2_ref[]) * DECAYX[ksp]
        else   # California
            dktime = (1.24f0 * DECAYX[ksp] * Float32(d)) + (13.82f0 * DECAYX[ksp])
            dktime *= xmod
        end
    else   # DEFAULT (SN and all other variants)
        dktime = (1.24f0 * DECAYX[ksp] * Float32(d)) + (13.82f0 * DECAYX[ksp])
        dktime *= xmod
    end

    dktime_ref[] = dktime
    return nothing
end
