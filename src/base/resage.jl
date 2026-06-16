# resage.jl — RESAGE: reset stand age from RESETAGE keyword
# Translated from: resage.f (41 lines)

function RESAGE()
    myact2 = Int32[443]
    prms   = zeros(Float32, 1)
    ntodo  = Ref(Int32(0))
    kdt    = Int32(0)
    idt    = Ref(Int32(0))
    iactk  = Ref(Int32(0))
    np     = Ref(Int32(0))
    OPFIND(Int32(1), myact2, ntodo)
    if ntodo[] <= 0; return nothing; end
    kdt = IY[Int(ICYC)+1] - Int32(1)
    OPGET(ntodo[], Int32(1), idt, iactk, np, prms)
    if iactk[] < 0; return nothing; end
    OPDONE(ntodo[], kdt)
    global IAGE = Int32(floor(prms[1])) - idt[] + IY[1]
    return nothing
end
