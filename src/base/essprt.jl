# essprt.f — establishment stump-sprout helper routines (ENTRY points in Fortran).
# Translated SN-variant branches (with generic defaults for other variants).
#   ESSPRT — TPA represented by each sprout record, by variant/species (Keyser &
#            Loftis short-term stump-sprout dynamics, 24 upland hardwoods).
#   NSPREC — number of sprout records to create for a cut tree.
#   SPRTHT — sprout height (HT = (0.1 + SI/baseage)*age).
#   ASSPTN — quaking-aspen sprouts/acre (not used by SN; no aspen).
# (ESASID is the real implementation in base/estump.jl — not redefined here.)
# Called from: ESUCKR.

# ESSPRT(var, ispc, prem_ref, dstmp) — scales prem_ref[] in place.
function ESSPRT(var_::AbstractString, ispc::Integer, prem_ref::Ref{Float32}, dstmp::Real)
    local d = Float32(dstmp)
    local p = prem_ref[]
    if var_ == "SN"
        local isefor_burn = Int(ISEFOR) in (809, 810, 905, 908)
        local i = Int(ispc)
        if i == 5
            p *= 0.42f0
        elseif i in (18, 19, 26, 30, 31, 32, 41, 51, 52, 56, 82)
            p *= 0.94f0
        elseif i == 20
            p *= 1f0 / (1f0 + exp(-(4.1975f0 + (-0.1821f0 * d))))
        elseif i == 22
            p *= 0.73f0
        elseif i == 23
            p *= 0.96f0
        elseif i == 24 || i == 25
            p *= 1f0 / (1f0 + exp(-(3.3670f0 + (-0.5159f0 * d))))
        elseif i == 27
            p *= 0.95f0
        elseif i == 33
            p *= 0.93f0
        elseif i == 45
            p *= 0.79f0
        elseif i == 46
            p *= 0.95f0
        elseif i == 47
            p *= 0.69f0
        elseif i == 54
            p *= 0.72f0
        elseif i == 57
            p *= 0.97f0
        elseif i == 63
            p *= 1f0 / (1f0 + exp(-(2.4608f0 + (-0.3093f0 * d))))
        elseif i == 64
            p *= isefor_burn ? ((57.3f0 - 0.0032f0 * d^3) / 100f0) :
                               1f0 / (1f0 + exp(-(3.8897f0 + (-0.2260f0 * d))))
        elseif i == 66
            p *= isefor_burn ? ((57.3f0 - 0.0032f0 * d^3) / 100f0) :
                               1f0 / (1f0 + exp(-(2.7386f0 + (-0.1076f0 * d))))
        elseif i == 70
            p *= isefor_burn ? 1f0 / (1f0 + exp(-(2.3656f0 + (-0.2781f0 * (d / 0.7801f0))))) :
                               1f0 / (1f0 + exp(-(2.7386f0 + (-0.1076f0 * d))))
        elseif i == 74
            p *= 0.78f0
        elseif i == 75
            p *= isefor_burn ? ((57.3f0 - 0.0032f0 * d^3) / 100f0) :
                               1f0 / (1f0 + exp(-(3.2586f0 + (-0.1120f0 * d))))
        elseif i == 77
            p *= isefor_burn ? (1f0 / (1f0 + exp(-(-2.8058f0 +
                                  22.6839f0 * (1f0 / ((d / 0.7788f0) - 0.4403f0)))))) :
                               1f0 / (1f0 + exp(-(2.7386f0 + (-0.1076f0 * d))))
        elseif i == 78
            p *= 1f0 / (1f0 + exp(-(3.1070f0 + (-0.2128f0 * d))))
        elseif i == 80
            p *= 0.86f0
        elseif i == 83
            p *= 0.99f0
        else
            p *= 1f0 / (1f0 + exp(-(2.7386f0 + (-0.1076f0 * d))))
        end
    else
        p *= 1f0   # generic default (other variants)
    end
    prem_ref[] = p
    return nothing
end

# NSPREC(var, ispc, nmsprc_ref, dstmp) — number of sprout records.
function NSPREC(var_::AbstractString, ispc::Integer, nmsprc_ref::Ref{Int32}, dstmp::Real)
    local d = Float32(dstmp)
    local i = Int(ispc)
    if var_ == "SN"
        if i == 5
            nmsprc_ref[] = d < 7.0f0 ? Int32(1) : Int32(0)
        elseif i == 33 || i == 61 || i == 80 || i == 82
            if d < 5.0f0
                nmsprc_ref[] = Int32(1)
            elseif d >= 5.0f0 && d <= 10.0f0
                nmsprc_ref[] = Int32(round(-1.0f0 + 0.4f0 * d))
            else
                nmsprc_ref[] = Int32(3)
            end
        else
            nmsprc_ref[] = Int32(1)
        end
    else
        nmsprc_ref[] = Int32(2)   # generic default ("OTHERWISE SET TO 2")
    end
    return nothing
end

# SPRTHT(var, ispc, si, iag, htsprt_ref) — sprout height (ft).
function SPRTHT(var_::AbstractString, ispc::Integer, si::Real, iag::Integer,
                htsprt_ref::Ref{Float32})
    local s = Float32(si)
    local a = Float32(iag)
    local i = Int(ispc)
    if var_ == "SN"
        if i == 5 || i == 15 || i == 16 || (i >= 18 && i <= 57) || (i >= 59 && i <= 87)
            htsprt_ref[] = (0.1f0 + s / 50.0f0) * a
        else
            htsprt_ref[] = 0.5f0 + 0.5f0 * a
        end
    else
        htsprt_ref[] = 0.5f0 + 0.5f0 * a
    end
    return nothing
end

# ASSPTN(ishag, asbar, astpar, prem, trees_ref) — quaking-aspen sprouts/acre.
function ASSPTN(ishag::Integer, asbar::Real, astpar::Real, prem::Real,
                trees_ref::Ref{Float32})
    local rshag = Float32(ishag)
    local spa = 40100.45f0 - 3574.02f0 * rshag^2 + 554.02f0 * rshag^3 -
                3.5208f0 * rshag^5 + 0.011797f0 * rshag^7
    spa < 2608.0f0 && (spa = 2608.0f0)
    spa > 30125.0f0 && (spa = 30125.0f0)
    spa = spa * Float32(asbar) / 198.0f0
    trees_ref[] = (Float32(prem) / (Float32(astpar) * 2.0f0)) * spa
    return nothing
end
