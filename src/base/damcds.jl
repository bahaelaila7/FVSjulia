# base/damcds.jl — DAMCDS: dispatch damage codes to base model + store
# Translated from: bin/FVSsn_buildDir/damcds.f (33 lines)
#
# Calls BASDAM for base model processing (special status, defect).
# Copies ICODES into DAMSEV for later pest extension processing.

function DAMCDS(ii::Integer, icodes::AbstractVector{Int32})
    BASDAM(Int(ii), icodes)
    for k in 1:6
        DAMSEV[k, Int(ii)] = icodes[k]
    end
    return nothing
end
