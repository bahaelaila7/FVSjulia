# basdam.jl — BASDAM: process special tree status and percent defect codes
# Translated from: basdam.f (64 lines)
#
# DEFECT(itree) is packed as: (mc_defect_pct * 1000000) + (bf_defect_pct * 10000)
# where damage codes 25/26 → cubic defect, 25/27 → board-foot defect, 55 → special status.

function BASDAM(itree::Integer, icodes::AbstractVector{<:Integer})
    ISPECL[itree] = Int32(0)
    DEFECT[itree] = Int32(0)
    for j in 1:2:5
        c = Int(icodes[j]); v = Int(icodes[j+1])
        if c == 25 || c == 26
            itemp = clamp(v, 0, 99)
            DEFECT[itree] = DEFECT[itree] + Int32(itemp * 1000000)
        end
        if c == 25 || c == 27
            itemp = clamp(v, 0, 99)
            DEFECT[itree] = DEFECT[itree] + Int32(itemp * 10000)
        end
        if c == 55
            ISPECL[itree] = Int32(clamp(v, 0, 99))
        end
    end
    return nothing
end
