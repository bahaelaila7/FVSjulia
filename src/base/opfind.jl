# base/opfind.jl — OPFIND + 7 entry points: activity query/update routines
# Translated from: bin/FVSsn_buildDir/opfind.f (261 lines)
#
# All entry points share module-level OPCOM state (IACT, IDATE, IPTODO, KTODO,
# PARMS, CACT, ISEQ, ISEQDN, IOPSRT, IMG1, IMG2, IMGL, IEPT, IMPL, ITOPRM,
# IOPCYC, MXPTDO, MXCACT, MAXACT — all declared in common/opcom.jl).
#
# OPFIND  — find activities this caller can service; fills IPTODO[1..NTODO]
# OPGET   — retrieve one scheduled activity's params
# OPGETC  — retrieve character string associated with an activity
# OPCHPR  — change stored parameters for an activity
# OPDONE  — mark activity accomplished at a given year
# OPDEL1  — mark one activity deleted
# OPDEL2  — delete all/selected occurrences of an activity code in a date range
# OPDEL3  — delete activity code from event-triggered schedule

function OPFIND(nmya::Integer, myacts::AbstractVector{Int32})::Int32
    ntodo_ref = Ref(Int32(0))
    OPMERG(nmya, myacts, ntodo_ref)
    global KTODO = ntodo_ref[]
    return KTODO
end

# 3-arg Ref overload: handles Fortran-style OPFIND(nmya, myacts, ntodo) with ntodo as output
function OPFIND(nmya::Integer, myacts::AbstractVector{Int32}, ntodo_ref::Ref{Int32})
    ntodo_ref[] = OPFIND(nmya, myacts)
    return ntodo_ref[]
end

function OPGET(itodo1::Integer, mxpm::Integer,
               prms::AbstractVector{Float32})::Tuple{Int32,Int32,Int32}
    # Returns (iactk, idt, nprms)
    if itodo1 > Int(KTODO)
        return (Int32(-1), Int32(0), Int32(0))
    end

    irefn = Int(IPTODO[itodo1])
    nprms = Int32(0)
    iactk = Int32(-1)

    # Evaluate expression parameters if pointer is negative
    if IACT[irefn, 2] < Int32(0)
        irc_ref = Ref(Int32(0))
        OPEVAL(Int32(irefn), irc_ref)
        if irc_ref[] != Int32(0)
            return (iactk, Int32(0), nprms)
        end
    end

    if IACT[irefn, 4] == Int32(0)
        iactk = Int32(1)
    end
    iactk = IACT[irefn, 1] * iactk
    idt   = IDATE[irefn]

    j1 = Int(IACT[irefn, 2])
    if j1 == 0
        return (iactk, idt, nprms)
    end
    j2 = Int(IACT[irefn, 3])
    nprms = Int32(j2 - j1 + 1)

    j2_use = j2
    if nprms > mxpm
        j2_use = j2 - (Int(nprms) - mxpm)
        nprms  = -nprms
    end
    for j in j1:j2_use
        prms[j - j1 + 1] = PARMS[j]
    end
    return (iactk, idt, nprms)
end

# 6-arg Ref-based overload: handles Fortran-style OPGET(itodo, mxpm, idt, iactk, np, prms)
# where idt/iactk/np are output args. The 3-arg form returns (iactk, idt, nprms).
function OPGET(itodo1::Integer, mxpm::Integer,
               idt_ref::Ref{Int32}, iactk_ref::Ref{Int32}, np_ref::Ref{Int32},
               prms::AbstractVector{Float32})
    iactk, idt, nprms = OPGET(itodo1, mxpm, prms)
    idt_ref[]   = idt
    iactk_ref[] = iactk
    np_ref[]    = nprms
    return nothing
end

function OPGETC(itodo5::Integer)::String
    if itodo5 > Int(KTODO)
        return " "
    end
    irefn = Int(IPTODO[itodo5])
    if IACT[irefn, 5] == Int32(0)
        return " "
    end
    buf = Char[]
    for i in Int(IACT[irefn, 5]):Int(MXCACT_OP)
        c = CACT[i]
        c == '\0' && break
        push!(buf, c)
        length(buf) >= 256 && return " "   # safety: if ever too long, return blank
    end
    return String(buf)
end

function OPCHPR(itodo2::Integer, nprms1::Integer, prms::AbstractVector{Float32})
    if itodo2 <= Int(KTODO)
        irefn = Int(IPTODO[itodo2])
        if (Int(IMPL) + nprms1 - 1 <= Int(ITOPRM)) && (IACT[irefn, 2] >= Int32(0))
            IACT[irefn, 2] = IMPL
            for j in 1:nprms1
                PARMS[Int(IMPL)] = prms[j]
                global IMPL = IMPL + Int32(1)
            end
            IACT[irefn, 3] = IMPL - Int32(1)
        end
    end
    return nothing
end

function OPDONE(itodo3::Integer, idt4::Integer)
    if itodo3 > Int(KTODO); return nothing; end
    irefn = Int(IPTODO[itodo3])
    global ISEQDN = ISEQDN + Int32(1)
    ISEQ[irefn]     = ISEQDN
    IACT[irefn, 4]  = idt4 == 0 ? Int32(1) : Int32(idt4)
    return nothing
end

function OPDEL1(itodo4::Integer)
    if itodo4 > Int(KTODO); return nothing; end
    irefn = Int(IPTODO[itodo4])
    IACT[irefn, 4] = Int32(-1)
    return nothing
end

function OPDEL2(iyr1::Integer, iyr2::Integer, iactk::Integer, isqnum::Integer)
    j1 = 0
    i2 = Int(IMGL) - 1
    for ii in 1:i2
        i3   = Int(IOPSRT[ii])
        idt3 = Int(IDATE[i3])
        if !(idt3 >= iyr1 && idt3 <= iyr2 &&
             IACT[i3, 4] == Int32(0) && IACT[i3, 1] == Int32(iactk))
            continue
        end
        if isqnum != 0
            j1 += 1
            if j1 != isqnum; continue; end
        end
        IACT[i3, 4] = Int32(-1)
        if isqnum > 0; return nothing; end
    end

    if isqnum >= 0; return nothing; end
    if -isqnum >= j1; return nothing; end

    # isqnum < 0 and more occurrences than -isqnum: delete all except -isqnum
    j2 = 0
    j1 = j1 + isqnum   # number of deletions to make
    for ii in 1:i2
        i3   = Int(IOPSRT[ii])
        idt3 = Int(IDATE[i3])
        if !(idt3 >= iyr1 && idt3 <= iyr2 &&
             IACT[i3, 4] == Int32(0) && IACT[i3, 1] == Int32(iactk))
            continue
        end
        IACT[i3, 4] = Int32(-1)
        j2 += 1
        if j2 >= j1; return nothing; end
    end
    return nothing
end

function OPDEL3(iactk::Integer)
    i2 = Int(IEPT) + 1
    if i2 > Int(MAXACT_OP); return nothing; end
    for i in i2:Int(MAXACT_OP)
        if IACT[i, 1] == Int32(iactk)
            IACT[i, 4] = Int32(-1)
        end
    end
    return nothing
end
