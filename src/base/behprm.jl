# behprm.jl — BEHPRM: compute Behre hyperbola taper parameters AHAT, BHAT
# Translated from: behprm.f (45 lines)
#
# Sets module globals AHAT and BHAT, also sets lcone_ref if |AHAT|<0.05.
# BEHRE function (evaluation of the hyperbola integral) is in utils.jl.

function BEHPRM(vmax::Real, d::Real, h::Real, bark::Real, lcone_ref::Ref{Bool})
    lcone_ref[] = false
    bhat_val = Float32(vmax) / (Float32(0.00545415) * Float32(d)^2 * Float32(bark)^2 * Float32(h))
    if bhat_val > Float32(0.95); bhat_val = Float32(0.95); end
    ahat_val = Float32(0.44277) - Float32(0.99167)/bhat_val - Float32(1.43237)*log(bhat_val) +
               Float32(1.68581)*sqrt(bhat_val) - Float32(0.13611)*bhat_val^2
    if abs(ahat_val) < Float32(0.05)
        lcone_ref[] = true
        ahat_val = ahat_val < Float32(0) ? Float32(-0.05) : Float32(0.05)
    end
    bhat_val = Float32(1) - ahat_val
    if bhat_val < Float32(0.0001); bhat_val = Float32(0.0001); end
    global AHAT = ahat_val
    global BHAT = bhat_val
    return nothing
end
