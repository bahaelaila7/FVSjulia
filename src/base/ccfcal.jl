# base/ccfcal.jl — CCFCAL: compute crown competition factor (CCF) for one tree
# Translated from: bin/FVSsn_buildDir/ccfcal.f (65 lines)
#
# Calls CWCALC to get the open-grown crown width for the tree,
# then converts to CCF = 0.001803 * CW² * TPA.
#
# Args:
#   ispc   — FVS species index (1..MAXSP)
#   d      — DBH (inches)
#   h      — height (feet)
#   jcr    — crown ratio percent (0-100)
#   p      — trees per acre
#   lthin  — true if thinning just occurred (unused, historic)
#   ccft   — output: CCF contribution of this tree
#   crwdth — output: crown width (set by CWCALC, optionally used by caller)
#   mode   — 1=CCF only, 2=CW only (historic, CWCALC is always called)

function CCFCAL(ispc::Integer, d::Real, h::Real, jcr::Integer, p::Real,
                lthin::Bool,
                ccft::Ref{Float32}, crwdth::Ref{Float32},
                mode::Integer)
    ccft[]   = Float32(0)
    crwdth[] = Float32(0)

    # Get open-grown crown width (CR=90 = full open-grown crown)
    temcw_ref = Ref(Float32(0))
    CWCALC(Int32(ispc), Float32(p), Float32(d), Float32(h),
           Float32(90),   # CR = 90 for open-grown crown
           Int32(jcr),    # IICR (unused in most equation paths)
           temcw_ref,
           Int32(1),      # IWHO=1 → open-grown crown
           Int32(JOSTND))
    temcw = temcw_ref[]
    crwdth[] = temcw

    if d > Float32(0.1)
        ccft[] = Float32(0.001803) * temcw * temcw * Float32(p)
    else
        ccft[] = Float32(0.001) * Float32(p)
    end

    return nothing
end
