# opadd.jl — OPADD/OPREDT/OPCOPY/OPSCHD/OPINCR: dynamic activity scheduling
# Translated from: opadd.f (269 lines)
#
# These routines manage dynamic additions to the activity schedule at runtime
# (as opposed to keyword-file-driven scheduling in INITRE/OPNEW).

# Special activity codes that need the event date prepended to params
const _OPADD_ISPACT = Int32[33, 427, 428, 429]

function OPADD(idt::Integer, iactk::Integer, istus::Integer,
               nprms::Integer, prms::AbstractVector{Float32},
               kode_ref::Ref{Int32})
    if idt <= 0
        kode_ref[] = Int32(2)
        return nothing
    end
    id = Int32(idt)
    global ISEQDN = ISEQDN + Int32(1)
    ISEQ[Int(IMGL)] = ISEQDN
    kode_ref2 = Ref(Int32(0))
    OPNEW(kode_ref2, id, Int32(iactk), Int32(nprms), prms)
    kode_ref[] = kode_ref2[]
    if !LOPEVN
        IACT[Int(IMGL)-1, 4] = Int32(istus)
    end
    return nothing
end

function OPREDT(iactk::Integer, iyr1::Integer, iyr2::Integer, nredts_ref::Ref{Int32})
    nredts_ref[] = Int32(0)
    i2 = Int(IMGL) - 1
    for i in 1:i2
        id = IDATE[i]
        if id != iyr1 || iactk != IACT[i, 1] || IACT[i, 4] != 0; continue; end
        nredts_ref[] += Int32(1)
        IDATE[i] = Int32(iyr2)
    end
    return nothing
end

function OPCOPY(iactk::Integer, iyr1::Integer, iyr2::Integer,
                ncopys_ref::Ref{Int32}, kode_ref::Ref{Int32})
    kode_ref[]   = Int32(0)
    ncopys_ref[] = Int32(0)
    i2 = Int(IMGL) - 1
    for ii in 1:i2
        i = Int(IOPSRT[ii])
        if iactk != IACT[i, 1]; continue; end
        id = IDATE[i]
        if id != iyr1 || IACT[i, 4] < 0; continue; end
        if IMGL > IEPT
            kode_ref[] = Int32(1)
            ERRGRO(true, Int32(10))
            @printf(io_units[Int32(16)], " ISSUED IN OPADD ENTRY OPCOPY\n")
            return nothing
        end
        ncopys_ref[] += Int32(1)
        im = Int(IMGL)
        IOPSRT[im] = IMGL
        IDATE[im]  = Int32(iyr2)
        ISEQ[im]   = IMGL
        for k in 1:5
            IACT[im, k] = IACT[i, k]
        end
        IACT[im, 4] = Int32(0)
        global IMGL = IMGL + Int32(1)
    end
    return nothing
end

function OPSCHD(idt::Integer, ip1::Integer, ip2::Integer,
                nschds_ref::Ref{Int32}, kode_ref::Ref{Int32})
    nschds_ref[] = Int32(0)
    kode_ref[]   = Int32(0)
    n = Int(ip1) - Int(ip2) + 1
    if ip1 * ip2 != 0 && n > 0
        # OK
    else
        kode_ref[] = Int32(1)
        return nothing
    end
    if n + Int(IMGL) > Int(IEPT) + 1
        kode_ref[] = Int32(2)
        ERRGRO(true, Int32(10))
        @printf(io_units[Int32(16)], " ISSUED IN OPADD ENTRY OPSCHD 1\n")
        return nothing
    end

    for i in 1:n
        ii = ip1 - i + 1
        if IACT[ii, 4] < 0; continue; end
        im = Int(IMGL)
        IOPSRT[im] = IMGL
        IDATE[im]  = Int32(idt) + IDATE[ii]
        global ISEQDN = ISEQDN + Int32(1)
        ISEQ[im]   = ISEQDN
        for k in 1:5
            IACT[im, k] = IACT[ii, k]
        end
        IACT[im, 4] = Int32(0)

        # If this activity code needs the event date in params:
        ia = IACT[im, 1]
        needs_date = any(ia .== _OPADD_ISPACT)
        if needs_date
            i1 = Int(IACT[im, 2])
            if i1 > 0
                i2v = Int(IACT[im, 3])
                npar = i2v - i1 + 1
                if Int(IMPL) + npar - 1 > Int(ITOPRM)
                    kode_ref[] = Int32(2)
                    ERRGRO(true, Int32(10))
                    @printf(io_units[Int32(16)], " ISSUED IN OPADD ENTRY OPSCHD DATE %d\n", idt)
                    return nothing
                end
                IACT[im, 2] = IMPL
                for j in i1:i2v
                    PARMS[Int(IMPL)] = PARMS[j]
                    global IMPL = IMPL + Int32(1)
                end
                IACT[im, 3] = IMPL - Int32(1)
                PARMS[Int(IACT[im, 2])] = Float32(idt)
            else
                if Int(IMPL) > Int(ITOPRM)
                    kode_ref[] = Int32(2)
                    ERRGRO(true, Int32(10))
                    @printf(io_units[Int32(16)], " ISSUED IN OPADD ENTRY OPSCHD NO PARAMS\n")
                    return nothing
                end
                PARMS[Int(IMPL)] = Float32(idt)
                IACT[im, 2] = IMPL
                IACT[im, 3] = IMPL
                global IMPL = IMPL + Int32(1)
            end
        end
        global IMGL = IMGL + Int32(1)
        nschds_ref[] += Int32(1)
    end
    return nothing
end

function OPINCR(iy::AbstractVector{Int32}, icyc::Integer, ncyc::Integer)
    OPSORT(Int32(Int(IMGL)-1), IDATE, ISEQ, IOPSRT, false)
    OPCYCL(Int32(ncyc), iy[1])
    OPCSET(Int32(icyc))
    return nothing
end
