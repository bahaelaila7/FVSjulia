# spesrt.jl — SPESRT: realign species-order sort after compression/establishment
# Translated from: spesrt.f (54 lines)
#
# Resets ISCT/IBEGIN/IREF/KOUNT and rebuilds IND1 chain sort via LNKCHN+SETUP.

function SPESRT()
    global NUMSP = Int32(0)
    for i in 1:MAXSP
        ISCT[i, 1] = Int32(0)
        ISCT[i, 2] = Int32(0)
        IBEGIN[i]  = Int32(0)
        IREF[i]    = Int32(0)
        KOUNT[i]   = Int32(0)
    end
    if IREC1 == 0
        global ITRN = Int32(0)
    else
        for i in 1:Int(IREC1)
            LNKCHN(Int32(i))
        end
        SETUP()
    end
    return nothing
end
