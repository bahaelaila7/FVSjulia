# revise.f — REVISE: return latest revision date for each FVS variant
# Translated from: bin/FVSsn_buildDir/revise.f (137 lines)

function REVISE(var::AbstractString, rev::Ref{String})
    v = length(var) >= 2 ? uppercase(var[1:2]) : uppercase(var)
    rev[] = "20260401"   # all active variants share this date
    return nothing
end
