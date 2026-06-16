# opdon2.jl — OPDON2: set activity status to 'done' (date-range version)
# Translated from: opdon2.f (61 lines)

function OPDON2(iactk::Integer, idt::Integer, iyr1::Integer, iyr2::Integer,
                isqnum::Integer, kode_ref::Ref{Int32})
    kode_ref[] = Int32(0)
    ifind  = 0
    ntimes = 0
    i2 = Int(IMGL) - 1
    for ii in 1:i2
        i  = Int(IOPSRT[ii])
        id = IDATE[i]
        if id < iyr1 || id > iyr2 || iactk != IACT[i, 1]; continue; end
        if IACT[i, 4] != 0; continue; end
        ntimes += 1
        if isqnum <= 0
            ifind = i
        elseif isqnum == ntimes
            ifind = i
            break
        end
    end
    if ifind <= 0
        kode_ref[] = Int32(1)
        return nothing
    end
    global ISEQDN = ISEQDN + Int32(1)
    ISEQ[ifind]    = ISEQDN
    IACT[ifind, 4] = Int32(idt)
    return nothing
end
