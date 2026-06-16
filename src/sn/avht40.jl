# avht40.jl — AVHT40: average height of the 40 TPA of largest diameter
# Translated from: avht40.f (44 lines)
# Trees are sorted by IND in descending DBH order (set by SETUP/NOTRE).

function AVHT40()
    global AVH = Float32(0)
    if ITRN <= 0; return nothing; end
    ssumn = Float32(0)
    for i in 1:Int(ITRN)
        ii = Int(IND[i])
        p  = PROB[ii]
        if ssumn + p > Float32(40)
            p = Float32(40) - ssumn
        end
        ssumn += p
        global AVH = AVH + HT[ii] * p
        if ssumn >= Float32(40); break; end
    end
    if ssumn > Float32(0)
        global AVH = AVH / ssumn
    end
    return nothing
end
