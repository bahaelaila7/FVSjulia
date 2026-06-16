# dampro.jl — DAMPRO: dispatch damage codes to extension handlers for all trees
# Translated from: dampro.f (71 lines)
#
# Processes live trees (indices 1..IREC1), then dead trees (IREC2..MAXTRE)
# if dead trees are present. Calls extension-specific damage handlers.

function DAMPRO()
    icodes = zeros(Int32, 6)
    i1 = 1
    i2 = Int(IREC1)
    @label loop_100
    for ii in i1:i2
        for i in 1:6; icodes[i] = DAMSEV[i, ii]; end
        # Damage code 54: Acadian form and risk code → special status
        for i in 1:2:5
            if icodes[i] == Int32(54); ISPECL[ii] = icodes[i+1]; end
        end
        MISDAM(ii, icodes)
        RDDAM(ii, icodes)
        TMDAM(ii, icodes)
        MPBDAM(ii, icodes)
        DFBDAM(ii, icodes)
        BRDAM(ii, icodes)
        BMDAM(ii, icodes)
    end
    if i1 == 1 && IREC2 != Int(MAXTRE) + 1
        i1 = Int(IREC2)
        i2 = Int(MAXTRE)
        @goto loop_100
    end
    return nothing
end
