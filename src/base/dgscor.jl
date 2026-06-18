# dgscor.jl — DGSCOR: compute auto-correlated DG prediction error for next cycle
# Translated from: dgscor.f (51 lines)
#
# When not tripling: draws FRM from bounded normal via BACHLO, applies AR(1) with OLDRN.
# When large DDS (>5): zeroes the error; tapers between 4..5.
# Sets OLDRN[it] for next cycle and returns FRM=exp(raw_error).

function DGSCOR(ssig::Real, frm_ref::Ref{Float32}, rho::Real, rhocp::Real, it::Integer)
    frm = Float32(0)
    if DGSD >= Float32(1)
        @label label_20
        frm = BACHLO(Float32(0), Float32(ssig))
        frm = Float32(frm) * Float32(rhocp) + Float32(rho) * OLDRN[it]
        if abs(frm) > DGSD * Float32(ssig)
            @goto label_20
        end
    end
    dds = WK2[it]
    if dds > Float32(5)
        frm = Float32(0)
    elseif dds > Float32(4)
        frm = (dds - Float32(4)) * frm
    end
    OLDRN[it] = frm
    frm_ref[] = exp(frm)
    return nothing
end
