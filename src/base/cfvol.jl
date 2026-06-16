# cfvol.jl — CFVOL: cubic foot volume using user-defined equation (CFVOLEQ keyword)
# Translated from: cfvol.f (244 lines), originally from LS variant
#
# Uses CFVEQS/CFVEQL coefficient tables (set by CFVOLEQ keyword or CUBRDS block data).
# CTRAN/ICTRAN control which coefficient set to use by tree size.
# Calls NBOLT to determine merchantable height to pulpwood/sawtimber tops.

function CFVOL(ispc::Integer, d::Real, hz::Real, d2h::Real,
               vn_ref::Ref{Float32}, vm_ref::Ref{Float32}, vmax_ref::Ref{Float32},
               tkill::Bool, lcone_ref, bark::Real, itht::Integer,
               ctkflg_ref::Ref{Bool})

    debug_val = DBCHK(false, "CFVOL", Int32(5), ICYC)
    if debug_val
        @printf(io_units[Int32(JOSTND)], "IN CFVOL, ICYC= %d\n", ICYC)
    end

    d_f = Float32(d); hz_f = Float32(hz); d2h_f = Float32(d2h); bark_f = Float32(bark)

    # Compute VMAX to total height
    h = hz_f
    tsize = d_f
    if ICTRAN[ispc] > 0; tsize = d2h_f; end
    coef = tsize < CTRAN[ispc] ? (@view CFVEQS[:, ispc]) : (@view CFVEQL[:, ispc])
    vmax = coef[1] + coef[2]*d_f + coef[3]*d_f*h + coef[4]*d_f*d_f*h +
           coef[5] * (d_f^coef[6]) * (h^coef[7])
    vmax = max(vmax, Float32(0))
    vmax_ref[] = vmax

    topdob = TOPD[ispc] / bark_f
    bftdob = BFTOPD[ispc] / bark_f
    sindx = SITEAR[ispc]

    iht1_r = Ref(Int32(0)); iht2_r = Ref(Int32(0))
    NBOLT(Int32(ispc), h, d_f, DBHMIN, BFMIND, sindx, topdob, bftdob,
          Int32(JOSTND), debug_val, iht1_r, iht2_r)
    hm1 = Float32(iht1_r[]) * Float32(8.333333)
    hm2 = Float32(iht2_r[]) * Float32(8.333333)

    done = false
    totcu = Float32(0); sawcu = Float32(0)

    if d_f < DBHMIN[ispc] || iht2_r[] <= 0
        totcu = Float32(0)
    elseif d_f < BFMIND[ispc] || iht1_r[] <= 0
        h = hm2
        tsize = d_f; if ICTRAN[ispc] > 0; tsize = d2h_f; end
        coef2 = tsize < CTRAN[ispc] ? (@view CFVEQS[:, ispc]) : (@view CFVEQL[:, ispc])
        totcu = coef2[1] + coef2[2]*d_f + coef2[3]*d_f*h + coef2[4]*d_f*d_f*h +
                coef2[5]*(d_f^coef2[6])*(h^coef2[7])
        totcu = max(totcu, Float32(0))
        sawcu = Float32(0)
        done = true
    else
        h = hm2
        tsize = d_f; if ICTRAN[ispc] > 0; tsize = d2h_f; end
        coef2 = tsize < CTRAN[ispc] ? (@view CFVEQS[:, ispc]) : (@view CFVEQL[:, ispc])
        totcu = coef2[1] + coef2[2]*d_f + coef2[3]*d_f*h + coef2[4]*d_f*d_f*h +
                coef2[5]*(d_f^coef2[6])*(h^coef2[7])
        totcu = max(totcu, Float32(0))
        h = hm1
        tsize = d_f; if ICTRAN[ispc] > 0; tsize = d2h_f; end
        coef3 = tsize < CTRAN[ispc] ? (@view CFVEQS[:, ispc]) : (@view CFVEQL[:, ispc])
        sawcu = coef3[1] + coef3[2]*d_f + coef3[3]*d_f*h + coef3[4]*d_f*d_f*h +
                coef3[5]*(d_f^coef3[6])*(h^coef3[7])
        sawcu = max(sawcu, Float32(0))
        done = true
    end

    if !done
        # Strange case: BFMIND < DBHMIN
        if d_f < BFMIND[ispc]
            sawcu = Float32(0)
        else
            h = hm1
            tsize = d_f; if ICTRAN[ispc] > 0; tsize = d2h_f; end
            coef4 = tsize < CTRAN[ispc] ? (@view CFVEQS[:, ispc]) : (@view CFVEQL[:, ispc])
            sawcu = coef4[1] + coef4[2]*d_f + coef4[3]*d_f*h + coef4[4]*d_f*d_f*h +
                    coef4[5]*(d_f^coef4[6])*(h^coef4[7])
            sawcu = max(sawcu, Float32(0))
        end
    end

    vn_ref[] = totcu
    vm_ref[] = sawcu
    ctkflg_ref[] = totcu > Float32(0)
    if totcu <= Float32(0); vn_ref[] = Float32(0); end
    if sawcu <= Float32(0); vm_ref[] = Float32(0); end
    return nothing
end
