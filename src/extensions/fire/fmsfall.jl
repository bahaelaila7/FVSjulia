# SUBROUTINE FMSFALL(IYR,KSP,D,ORIGDEN,DENTTL,ISWTCH,RSOFT,RSMAL,DFALLN)
# Translated from: fmsfall.f (182 lines), FIRE-SN
#
# Calculates base snag fall rates given species, DBH, current/original density,
# and post-burn timing. Outputs RSOFT, RSMAL (post-burn exponential fall rates)
# and DFALLN (normal-conditions fall density).
# Called from: FMSNAG, SVSNAGE

function FMSFALL(iyr::Integer, ksp::Integer, d::Real, origden::Real, denttl::Real,
                 iswtch::Integer,
                 rsoft_ref::Ref{Float32}, rsmal_ref::Ref{Float32}, dfalln_ref::Ref{Float32})
    rsoft_ref[] = 0.0f0
    rsmal_ref[] = 0.0f0
    dfalln_ref[] = 0.0f0

    if Float32(denttl) <= 0.0f0; return nothing; end

    # Post-burn period: compute constant annual fall fractions RSOFT and RSMAL
    if (iyr - Int(BURNYR)) < Int(PBTIME)
        local dzero::Float32 = Float32(NZERO) / 50.0f0
        if PBSOFT > 0.0f0
            if PBSOFT < 1.0f0
                rsoft_ref[] = 1.0f0 - exp(log(1.0f0 - PBSOFT) / Float32(PBTIME))
            else
                rsoft_ref[] = 1.0f0 - exp(log(dzero / Float32(denttl)) / Float32(PBTIME))
            end
        end
        if PBSMAL > 0.0f0
            if PBSMAL < 1.0f0
                rsmal_ref[] = 1.0f0 - exp(log(1.0f0 - PBSMAL) / Float32(PBTIME))
            else
                rsmal_ref[] = 1.0f0 - exp(log(dzero / Float32(denttl)) / Float32(PBTIME))
            end
        end
    end

    # Base fall rate (linear with DBH, minimum 1%)
    local base::Float32 = -0.001679f0 * Float32(d) + 0.064311f0
    if base < 0.01f0; base = 0.01f0; end

    # Species-adjusted fall rate capped at 1.0
    local modrate::Float32 = base * FALLX[ksp]
    if modrate > 1.0f0; modrate = 1.0f0; end

    if Float32(d) < 12.0f0 && ksp != 2
        # Small trees (< 12 in DBH), not redcedar: simple proportional fall
        dfalln_ref[] = modrate * Float32(origden)
    else
        # Large trees: near-5% threshold gets an accelerated fall rate
        # X = time (years) when proportion standing reaches 5%: solve 1 - modrate*t = 0.05
        local x::Float32 = (0.05f0 - 1.0f0) / (-modrate)

        # FALLM2 = slope of line from 5% at time X to 0% at ALLDWN
        local fallm2::Float32
        if ALLDWN[ksp] <= x
            fallm2 = 2.0f0
        else
            fallm2 = 0.05f0 / (ALLDWN[ksp] - x)
        end

        if Float32(denttl) <= 0.05f0 * Float32(origden)
            dfalln_ref[] = fallm2 * Float32(origden)
        else
            local dfalln::Float32 = modrate * Float32(origden)
            if Float32(denttl) < (dfalln + 0.05f0 * Float32(origden))
                dfalln = Float32(denttl) - Float32(origden) * (0.05f0 - fallm2)
            end
            dfalln_ref[] = dfalln
        end
    end
    return nothing
end
