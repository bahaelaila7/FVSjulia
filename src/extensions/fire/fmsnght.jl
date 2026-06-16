# SUBROUTINE FMSNGHT(VAR,KSP,HTD,HTCURR,IHRD,HTSNEW)
# Translated from: fmsnght.f (168 lines), FIRE-VBASE
#
# Predicts snag height loss due to top breakage. Uses variant-specific rules;
# SN falls into DEFAULT case: exponential decay using HTR1/HTR2 × HTX coefficients.
# HTSNEW = 0 if result < 1.5 ft (snag becomes fuel).
# Called from: FMSNAG, SVSNAGE

function FMSNGHT(varacd::AbstractString, ksp::Integer, htd::Real, htcurr::Real,
                 ihrd::Integer, htsnew_ref::Ref{Float32})
    # Array indices for hard (1,2) vs soft (3,4) height-loss coefficients
    local htindx1::Int32
    local htindx2::Int32
    local sftmult::Float32
    if ihrd == 1
        htindx1 = Int32(1); htindx2 = Int32(2); sftmult = 1.0f0
    else
        htindx1 = Int32(3); htindx2 = Int32(4); sftmult = HTXSFT
    end

    local htsnew::Float32
    if varacd == "CI"
        # CI variant: WP (1) and RC (6) stop losing height at 75% of original
        if ksp == 1 || ksp == 6
            if Float32(htcurr) > 0.75f0 * Float32(htd)
                htsnew = Float32(htcurr) * (1.0f0 - HTR1 * HTX[ksp, htindx1] * sftmult)^Int(NYRS)
            else
                htsnew = Float32(htcurr)
            end
        else
            if Float32(htcurr) > 0.5f0 * Float32(htd)
                htsnew = Float32(htcurr) * (1.0f0 - HTR1 * HTX[ksp, htindx1] * sftmult)^Int(NYRS)
            else
                htsnew = Float32(htcurr) * (1.0f0 - HTR2 * HTX[ksp, htindx2] * sftmult)^Int(NYRS)
            end
        end
    elseif varacd ∈ ("PN", "WC", "BM", "EC", "OP")
        # R6 variants: use FMR6HTLS for base rate; user override via HTX ≠ 1.0
        local x2_ref = Ref(Float32(0))
        FMR6HTLS(Int32(ksp), x2_ref)
        local x2::Float32 = x2_ref[]
        if Float32(htcurr) > 0.5f0 * Float32(htd)
            if HTX[ksp, htindx1] > 1.01f0 || HTX[ksp, htindx1] < 0.99f0
                htsnew = Float32(htcurr) * (1.0f0 - HTR1 * HTX[ksp, htindx1] * sftmult)^Int(NYRS)
            else
                htsnew = Float32(htcurr) * (1.0f0 - x2)^Int(NYRS)
            end
        else
            if HTX[ksp, htindx2] > 1.01f0 || HTX[ksp, htindx2] < 0.99f0
                htsnew = Float32(htcurr) * (1.0f0 - HTR2 * HTX[ksp, htindx2] * sftmult)^Int(NYRS)
            else
                htsnew = Float32(htcurr) * (1.0f0 - x2)^Int(NYRS)
            end
        end
    elseif varacd == "SO"
        if KODFOR ∈ (505, 506, 509, 511, 701, 514)   # California
            if Float32(htcurr) > 0.5f0 * Float32(htd)
                htsnew = Float32(htcurr) * (1.0f0 - HTR1 * HTX[ksp, htindx1] * sftmult)^Int(NYRS)
            else
                htsnew = Float32(htcurr) * (1.0f0 - HTR2 * HTX[ksp, htindx2] * sftmult)^Int(NYRS)
            end
        else   # Oregon: use FMR6HTLS
            local x2so_ref = Ref(Float32(0))
            FMR6HTLS(Int32(ksp), x2so_ref)
            local x2so::Float32 = x2so_ref[]
            if Float32(htcurr) > 0.5f0 * Float32(htd)
                if HTX[ksp, htindx1] > 1.01f0 || HTX[ksp, htindx1] < 0.99f0
                    htsnew = Float32(htcurr) * (1.0f0 - HTR1 * HTX[ksp, htindx1] * sftmult)^Int(NYRS)
                else
                    htsnew = Float32(htcurr) * (1.0f0 - x2so)^Int(NYRS)
                end
            else
                if HTX[ksp, htindx2] > 1.01f0 || HTX[ksp, htindx2] < 0.99f0
                    htsnew = Float32(htcurr) * (1.0f0 - HTR2 * HTX[ksp, htindx2] * sftmult)^Int(NYRS)
                else
                    htsnew = Float32(htcurr) * (1.0f0 - x2so)^Int(NYRS)
                end
            end
        end
    else   # DEFAULT (SN and all other variants)
        if Float32(htcurr) > 0.5f0 * Float32(htd)
            htsnew = Float32(htcurr) * (1.0f0 - HTR1 * HTX[ksp, htindx1] * sftmult)^Int(NYRS)
        else
            htsnew = Float32(htcurr) * (1.0f0 - HTR2 * HTX[ksp, htindx2] * sftmult)^Int(NYRS)
        end
    end

    if htsnew < 1.5f0; htsnew = 0.0f0; end
    htsnew_ref[] = htsnew
    return nothing
end
