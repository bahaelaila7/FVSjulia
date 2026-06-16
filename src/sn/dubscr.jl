# sn/dubscr.jl — DUBSCR: crown ratio for cycle-0 dead trees
# Translated from: bin/FVSsn_buildDir/dubscr.f (49 lines)
#
# Returns crown ratio CR in [0.05, 0.95] as a linear function of DBH.
# For D <= 24: CR = 0.70 - 0.40/24 * D
# For D >  24: CR = 0.30
# (Random component exists in source but is commented out — not implemented)

function DUBSCR(d::Float32)::Float32
    cr = if d <= Float32(24)
        Float32(0.70) - Float32(0.40) / Float32(24) * d
    else
        Float32(0.30)
    end
    cr = max(cr, Float32(0.05))
    cr = min(cr, Float32(0.95))
    return cr
end
