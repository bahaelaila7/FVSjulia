# opnew.f — OPNEW: add activity to the activity list; OPMODE: query storage mode
# Translated from: bin/FVSsn_buildDir/opnew.f (129 lines)
#
# OPNEW returns kode: 0=OK, 1=storage full
# ENTRY OPMODE → split into separate function OPMODE(lmode)

function OPNEW(idt::Int32, iactk::Int32, nprms::Int32, prms::AbstractVector{Float32})::Int32
    ldeb = DBCHK("OPNEW", ICYC)

    ipend = IMPL + nprms - Int32(1)

    if ldeb
        @printf(io_units[JOSTND], " OPNEW: IPEND, IMPL, NPRMS=%d %d %d\n", ipend, IMPL, nprms)
        @printf(io_units[JOSTND], " OPNEW: IMGL, IEPT, ITOPRM=%d %d %d\n", IMGL, IEPT, ITOPRM)
    end

    if !(IMGL <= IEPT + Int32(1) && ipend <= ITOPRM)
        ERRGRO(true, Int32(10))
        if ldeb
            @printf(io_units[JOSTND], " IN OPNEW: IACTK=%4d NPRMS=%3d LOPEVN=%s IDT=%4d IMPL=%5d IMGL=%5d I=%5d IPEND=%5d KODE=%2d\n",
                    iactk, nprms, LOPEVN, idt, IMPL, IMGL, 0, ipend, 1)
        end
        return Int32(1)
    end

    # choose insertion point
    i = LOPEVN ? IEPT : IMGL

    IACT[i, 1] = iactk
    IACT[i, 4] = Int32(0)
    IACT[i, 5] = Int32(0)

    if nprms <= Int32(0)
        IACT[i, 2]  = Int32(0)
        IACT[i, 3]  = Int32(0)
        IDATE[i]    = idt
    else
        IACT[i, 2] = IMPL
        IACT[i, 3] = ipend
        IDATE[i]   = idt
        for j in IMPL:ipend
            PARMS[j] = prms[j - IMPL + 1]
        end
        global IMPL = ipend + Int32(1)
    end

    if LOPEVN
        global IEPT = IEPT - Int32(1)
    else
        IOPSRT[IMGL] = IMGL
        global IMGL  = IMGL + Int32(1)
    end

    if ldeb
        @printf(io_units[JOSTND], " IN OPNEW: IACTK=%4d NPRMS=%3d LOPEVN=%s IDT=%4d IMPL=%5d IMGL=%5d I=%5d IPEND=%5d KODE=%2d\n",
                iactk, nprms, LOPEVN, idt, IMPL, IMGL, i, ipend, 0)
    end
    return Int32(0)
end

function OPMODE(lmode::Ref{Bool})
    lmode[] = LOPEVN
    return nothing
end
