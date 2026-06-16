# base/opstus.jl — OPSTUS: check activity status without modifying it
# Translated from: bin/FVSsn_buildDir/opstus.f (108 lines)
#
# OPSTUS: search IOPSRT for an activity matching (IACTK, IYR1..IYR2, ISQNUM).
#   Returns NTIMES (count), NPRMS (param count), ISTAT (status: 0=pending, -1=deleted, >0=year),
#   IDT (date), KODE (0=found, 1=not found) via Refs.
#
# OPEVAC: count how many event-triggered occurrences of IACTK exist after IEPT.

function OPSTUS(iactk::Integer, iyr1::Integer, iyr2::Integer, isqnum::Integer,
                ntimes_ref::Ref{Int32}, idt_ref::Ref{Int32},
                nprms_ref::Ref{Int32}, istat_ref::Ref{Int32}, kode_ref::Ref{Int32})
    kode_ref[]   = Int32(0)
    ntimes_ref[] = Int32(0)
    nprms_ref[]  = Int32(0)
    istat_ref[]  = Int32(0)
    idt_ref[]    = Int32(0)

    ifind = 0
    i2    = Int(IMGL) - 1
    for ii in 1:i2
        i  = Int(IOPSRT[ii])
        id = Int(IDATE[i])
        if id < iyr1 || id > iyr2 || iactk != Int(IACT[i, 1])
            continue
        end
        ntimes_ref[] += Int32(1)
        if isqnum > 0
            if isqnum != Int(ntimes_ref[]); continue; end
            ifind = i
        else
            ifind = i
        end
    end

    if ifind == 0
        kode_ref[] = Int32(1)
        return nothing
    end

    # Load activity info for the found activity
    idt_ref[] = IDATE[ifind]
    j1 = Int(IACT[ifind, 2])
    nprms_ref[] = Int32(0)
    if j1 > 0
        j2 = Int(IACT[ifind, 3])
        nprms_ref[] = Int32(j2 - j1 + 1)
    end
    istat_ref[] = IACT[ifind, 4]
    return nothing
end

function OPEVAC(iactk::Integer, ntimes_ref::Ref{Int32})
    ntimes_ref[] = Int32(0)
    if Int(IEPT) >= Int(MAXACT_OP); return nothing; end
    nact = Int(IEPT) + 1
    for i in nact:Int(MAXACT_OP)
        if iactk == Int(IACT[i, 1])
            ntimes_ref[] += Int32(1)
        end
    end
    return nothing
end
