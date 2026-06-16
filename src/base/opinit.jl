# opinit.jl — OPINIT: initialize option processing (activity schedule) pointers
# Translated from: opinit.f (44 lines)

function OPINIT()
    global ISEQDN = Int32(0)
    global IMGL   = Int32(1)
    global IMPL   = Int32(1)
    global ITOPRM = MAXPRM
    global IEVA   = Int32(1)
    global ICOD   = Int32(1)
    global IEVT   = Int32(1)
    global ICACT  = Int32(1)
    global ILGNUM = Int32(0)
    global ITST5  = Int32(0)
    global IEPT   = MAXACT
    global LOPEVN = false
    for i in 1:Int(MXTST4)
        LTSTV4[i] = false
    end
    global LBSETS = false
    for i in 1:Int(MAXEVA)
        LENAGL[i] = Int32(-1)
    end
    global LENSLS = Int32(-1)
    return nothing
end
