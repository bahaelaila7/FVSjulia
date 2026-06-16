# autcor.jl — AUTCOR: ARMA(1,1) autocorrelation multipliers for DG variance
# Translated from: autcor.f (95 lines)
#
# Computes variance (VRNEXT) and covariance (COV) multipliers for the
# random component of diameter increment across a growth cycle.

function AUTCOR(cov_ref::Ref{Float32}, vrnext_ref::Ref{Float32})
    new_val  = Int32(0)
    nold_val = Int32(0)

    if LSTART
        # Initialize serial correlation from ARMA(1,1) parameters BJPHI, BJTHET
        BJRHO[1] = (Float32(1) - BJPHI * BJTHET) * (BJPHI - BJTHET) /
                   (Float32(1) + BJTHET * (BJTHET - Float32(2) * BJPHI))
        for i in 2:40
            BJRHO[i] = BJRHO[i-1] * BJPHI
        end
        new_val  = Int32(floor(YR))
        nold_val = Int32(floor(YR))
    else
        new_val  = IFINT
        nold_val = Int32(floor(OLDFNT))
    end

    # Variance multiplier for current cycle
    nlim = Int(new_val) - 1
    var  = Float32(0)
    for i in 1:nlim
        var += BJRHO[i] * Float32(Int(new_val) - i)
    end
    var = Float32(new_val) + Float32(2) * var
    vrnext_ref[] = var

    # Covariance multiplier between current and preceding cycles
    covar = Float32(0)
    l = Int(new_val) + Int(nold_val) - 1
    if l > 40; l = 40; end

    nbig = Int(new_val)
    nsml = Int(nold_val)
    if new_val <= nold_val
        nbig = Int(nold_val)
        nsml = Int(new_val)
    end

    t  = Float32(0)
    dt = Float32(1)
    for i in 1:l
        t    += dt
        covar += BJRHO[i] * t
        if i == nsml; dt = Float32(0); end
        if i == nbig; dt = Float32(-1); end
    end
    cov_ref[] = covar
    return nothing
end
