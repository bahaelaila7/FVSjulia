# lbsplw.jl — LBSPLW: write stand policy label set to output unit
# Translated from: lbsplw.f (54 lines)

function LBSPLW(jostnd::Integer)
    if !LBSETS; return nothing; end
    if LENSLS == -1; return nothing; end

    io  = io_units[Int32(jostnd)]
    i1  = 1
    i2  = 100
    while true
        if i2 > LENSLS; i2 = LENSLS; end
        chunk = SLSET[i1:i2]
        if i1 == 1
            @printf(io, "\nSTAND POLICIES:                  %s\n", chunk)
        else
            @printf(io, "                                 %s\n", chunk)
        end
        if i2 >= LENSLS; break; end
        i1 = i2 + 1
        i2 = i2 + 100
    end
    return nothing
end
