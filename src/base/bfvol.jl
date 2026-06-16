# bfvol.jl — BFVOL: board foot volume using user-defined equation (BFVOLEQU keyword)
# Translated from: bfvol.f (132 lines), originally from LS variant
#
# METHB controls equation form: 1-2=user polynomial, 3-4=R6 log rules (unsupported),
# 5=Western Sierra log rules (unsupported). SN variant uses METHB=0 → always returns 0.

function BFVOL(ispc::Integer, d::Real, h::Real, d2h::Real,
               bbfv_ref::Ref{Float32}, tkill::Bool, lcone_ref, bark::Real,
               vmax_ref, itht::Integer, btkflg_ref::Ref{Bool})

    bbfv_ref[] = Float32(0)
    btkflg_ref[] = false

    methb_val = Int(METHB[ispc])
    # METHB=3,4 → R6 log rules (not applicable to eastern/SN); METHB=5 → Sierra
    if methb_val == 3 || methb_val == 4 || methb_val == 5
        return nothing
    end

    d_f = Float32(d); h_f = Float32(h); d2h_f = Float32(d2h)
    tsize = d_f
    if IBTRAN[ispc] > 0; tsize = d2h_f; end

    if tsize < BTRAN[ispc]
        bbfv_ref[] = BFVEQS[1,ispc] + BFVEQS[2,ispc]*d_f + BFVEQS[3,ispc]*d_f*h_f +
                     BFVEQS[4,ispc]*d2h_f + BFVEQS[5,ispc]*(d_f^BFVEQS[6,ispc])*(h_f^BFVEQS[7,ispc])
    else
        bbfv_ref[] = BFVEQL[1,ispc] + BFVEQL[2,ispc]*d_f + BFVEQL[3,ispc]*d_f*h_f +
                     BFVEQL[4,ispc]*d2h_f + BFVEQL[5,ispc]*(d_f^BFVEQL[6,ispc])*(h_f^BFVEQL[7,ispc])
    end
    # Scribner round-up rule: < 10 BF rounds to 10
    if bbfv_ref[] < Float32(10) && bbfv_ref[] != Float32(0)
        bbfv_ref[] = Float32(10)
    end
    btkflg_ref[] = true
    return nothing
end
