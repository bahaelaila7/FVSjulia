# bftopk.jl — BFTOPK: correct board foot volume for dead/damaged top
# Translated from: bftopk.f (70 lines)
#
# Adjusts BBFV downward if the truncation point is above the merchantable top.

function BFTOPK(ispc::Integer, d::Real, h::Real, bbfv_ref::Ref{Float32},
                lcone::Bool, bark::Real, vmax::Real, itht::Integer)

    if bbfv_ref[] <= Float32(0); return nothing; end
    d_f = Float32(d); h_f = Float32(h)
    lcone_r = Ref(lcone)
    BEHPRM(vmax, d_f, h_f, Float32(bark), lcone_r)
    htrunc = Float32(itht) / Float32(100)
    pht    = Float32(1) - htrunc / h_f
    dtrunc = pht / (AHAT * pht + BHAT)
    if dtrunc > BFTOPD[ispc] / d_f
        htmrch = (BHAT * BFTOPD[ispc] / d_f) / (Float32(1) - AHAT * BFTOPD[ispc] / d_f)
        stump  = Float32(1) - BFSTMP[ispc] / h_f
        voltk  = BEHRE(pht, stump)
        if lcone_r[]
            volm = stump^3 - htmrch^3
            voltk = stump^3 - pht^3
            bbfv_ref[] = bbfv_ref[] * voltk / volm
        else
            bbfv_ref[] = (bbfv_ref[] * voltk) / BEHRE(htmrch, stump)
        end
    end
    return nothing
end
