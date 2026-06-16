# opget2.jl — OPGET2: retrieve a scheduled activity by date range (pending activities)
# Translated from: opget2.f (105 lines)

function OPGET2(iactk::Integer, idt_ref::Ref{Int32}, iyr1::Integer, iyr2::Integer,
                isqnum::Integer, mxpm::Integer, nprms_ref::Ref{Int32},
                prms::AbstractVector{Float32}, kode_ref::Ref{Int32})
    @label label_10
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

    j1 = Int(IACT[ifind, 2])
    if j1 < 0
        irc = Ref(Int32(0))
        OPEVAL(ifind, irc)
        if irc[] > 0; @goto label_10; end
        j1 = Int(IACT[ifind, 2])
    end
    idt_ref[] = IDATE[ifind]
    nprms_ref[] = Int32(0)
    if j1 == 0; return nothing; end
    j2 = Int(IACT[ifind, 3])
    np = j2 - j1 + 1
    if np <= mxpm
        nprms_ref[] = Int32(np)
    else
        j2 -= np - mxpm
        nprms_ref[] = Int32(-np)
    end
    for j in j1:j2
        prms[j - j1 + 1] = PARMS[j]
    end
    return nothing
end
