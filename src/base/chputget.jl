# base/chputget.jl — CHPUT / CHGET: character variable serialization for stop/restart
# Translated from: bin/FVSsn_buildDir/chput.f (185 lines), chget.f (186 lines)
#
# CHPUT writes all FVS character globals to the stash character buffer.
# CHGET reads them back in the same order.
# Both use CHWRIT/CHREAD (putgetsubs.jl) for buffered I/O via CHSTSH/CHDSTH.
#
# Key character globals covered:
#   MGMID(4), NPLT(26), DBCN(40), SLSET/AGLSET (event monitor, conditional),
#   IOSPxx(4×3), IONSP(6×3), ALLSUB(6), SUBNAM(ITOP bytes), CTSTV5, CACT,
#   NAMGRP(30×10), VEQNNB/VEQNNC(MAXSP×11), CPVREF(10), ITITLE(72),
#   PTGNAME(30×10), VARACD(2), CALCSDI(7), BFCTYPE(1), CFCTYPE(1)
# Then extension-specific character data via DBSCHPUT/VARCHPUT/MSCHPUT.

const _CHPUTGET_LNCBUF = Int32(1024 * 4)

# ---------------------------------------------------------------------------
# Local helpers: write/read N characters of a String through the char buffer.
# `ibeg_ref[]` tracks first/middle/last ibegin state (1 = first, 2 = middle).
# The CALLER is responsible for issuing the final CHWRIT with ibegin=3.
# ---------------------------------------------------------------------------
@inline function _chwrit_str!(cbuff::Vector{UInt8}, ipnt_ref::Ref{Int32},
                               lncbuf::Int32, ibeg_ref::Ref{Int32},
                               s::AbstractString)
    for c in s
        CHWRIT(cbuff, ipnt_ref, lncbuf, UInt8(c), ibeg_ref[])
        ibeg_ref[] = Int32(2)
    end
end

@inline function _chwrit_bytes!(cbuff::Vector{UInt8}, ipnt_ref::Ref{Int32},
                                lncbuf::Int32, ibeg_ref::Ref{Int32},
                                bytes::AbstractVector{UInt8}, n::Integer)
    for i in 1:n
        CHWRIT(cbuff, ipnt_ref, lncbuf, bytes[i], ibeg_ref[])
        ibeg_ref[] = Int32(2)
    end
end

@inline function _chread_str!(cbuff::Vector{UInt8}, ipnt_ref::Ref{Int32},
                               lncbuf::Int32, ibeg_ref::Ref{Int32},
                               n::Integer)::String
    buf = Vector{UInt8}(undef, n)
    tmp = Ref{UInt8}(UInt8(' '))
    for i in 1:n
        CHREAD(cbuff, ipnt_ref, lncbuf, tmp, ibeg_ref[])
        buf[i] = tmp[]
        ibeg_ref[] = Int32(2)
    end
    return String(buf)
end

@inline function _chread_bytes!(cbuff::Vector{UInt8}, ipnt_ref::Ref{Int32},
                                lncbuf::Int32, ibeg_ref::Ref{Int32},
                                dest::AbstractVector{UInt8}, n::Integer)
    tmp = Ref{UInt8}(UInt8(' '))
    for i in 1:n
        CHREAD(cbuff, ipnt_ref, lncbuf, tmp, ibeg_ref[])
        dest[i] = tmp[]
        ibeg_ref[] = Int32(2)
    end
end

# ---------------------------------------------------------------------------
# CHPUT — write all character variables to stash
# ---------------------------------------------------------------------------
function CHPUT()
    cbuff   = Vector{UInt8}(undef, _CHPUTGET_LNCBUF)
    ipnt    = Ref{Int32}(Int32(0))
    ibeg    = Ref{Int32}(Int32(1))   # first call → ibegin=1

    # MGMID (4 chars)
    _chwrit_str!(cbuff, ipnt, _CHPUTGET_LNCBUF, ibeg, MGMID[1:min(4,end)] * repeat(' ', max(0,4-length(MGMID))))

    # NPLT (26 chars)
    nplt26 = rpad(NPLT, 26)[1:26]
    _chwrit_str!(cbuff, ipnt, _CHPUTGET_LNCBUF, ibeg, nplt26)

    # DBCN — variable length (LEN(DBCN) in Fortran)
    _chwrit_str!(cbuff, ipnt, _CHPUTGET_LNCBUF, ibeg, DBCN)

    # Event monitor label sets (conditional on LBSETS)
    if LBSETS
        if LENSLS > Int32(0)
            for k in 1:Int(LENSLS)
                b = k <= length(SLSET) ? UInt8(SLSET[k]) : UInt8(' ')
                CHWRIT(cbuff, ipnt, _CHPUTGET_LNCBUF, b, ibeg[])
                ibeg[] = Int32(2)
            end
        end
        if Int(IEVA) > 1
            for i in 1:Int(IEVA)-1
                j = Int(LENAGL[i])
                if j >= 1
                    s = AGLSET[i]
                    for k in 1:j
                        b = k <= length(s) ? UInt8(s[k]) : UInt8(' ')
                        CHWRIT(cbuff, ipnt, _CHPUTGET_LNCBUF, b, ibeg[])
                        ibeg[] = Int32(2)
                    end
                end
            end
        end
    end

    # IOSP arrays — 4 entries of 3 chars each: IOSPTT, IOSPBR, IOSPTV, IOSPMR,
    #               IOSPSR, IOSPAC, IOSPCT, IOSPCV, IOSPMC, IOSPSC, IOSPBV,
    #               IOSPRT, IOSPMO  (13 arrays × 4 entries × 3 chars)
    for j in 1:4
        for s in (IOSPTT, IOSPBR, IOSPTV, IOSPMR, IOSPSR,
                  IOSPAC, IOSPCT, IOSPCV, IOSPMC, IOSPSC, IOSPBV, IOSPRT, IOSPMO)
            _chwrit_str!(cbuff, ipnt, _CHPUTGET_LNCBUF, ibeg, rpad(s[j], 3)[1:3])
        end
    end

    # IONSP — 6 entries of 3 chars each
    for j in 1:6
        _chwrit_str!(cbuff, ipnt, _CHPUTGET_LNCBUF, ibeg, rpad(IONSP[j], 3)[1:3])
    end

    # ALLSUB (6 chars)
    _chwrit_str!(cbuff, ipnt, _CHPUTGET_LNCBUF, ibeg, rpad(ALLSUB, 6)[1:6])

    # SUBNAM (ITOP bytes, variable length)
    if Int(ITOP) > 0
        _chwrit_bytes!(cbuff, ipnt, _CHPUTGET_LNCBUF, ibeg, SUBNAM, Int(ITOP))
    end

    # CTSTV5 (ITST5 entries × 8 chars)
    if Int(ITST5) > 0
        for j in 1:Int(ITST5)
            _chwrit_str!(cbuff, ipnt, _CHPUTGET_LNCBUF, ibeg, rpad(CTSTV5[j], 8)[1:8])
        end
    end

    # CACT (ICACT entries × 1 char)
    if Int(ICACT) > 0
        for i in 1:Int(ICACT)
            CHWRIT(cbuff, ipnt, _CHPUTGET_LNCBUF, UInt8(CACT[i]), ibeg[])
            ibeg[] = Int32(2)
        end
    end

    # NAMGRP (30 × 10 chars)
    for j in 1:30
        _chwrit_str!(cbuff, ipnt, _CHPUTGET_LNCBUF, ibeg, rpad(NAMGRP[j], 10)[1:10])
    end

    # VEQNNB (MAXSP × 11 chars)
    for j in 1:MAXSP
        _chwrit_str!(cbuff, ipnt, _CHPUTGET_LNCBUF, ibeg, rpad(VEQNNB[j], 11)[1:11])
    end

    # VEQNNC (MAXSP × 11 chars)
    for j in 1:MAXSP
        _chwrit_str!(cbuff, ipnt, _CHPUTGET_LNCBUF, ibeg, rpad(VEQNNC[j], 11)[1:11])
    end

    # CPVREF (10 chars)
    _chwrit_str!(cbuff, ipnt, _CHPUTGET_LNCBUF, ibeg, rpad(CPVREF, 10)[1:10])

    # ITITLE (72 chars)
    _chwrit_str!(cbuff, ipnt, _CHPUTGET_LNCBUF, ibeg, rpad(ITITLE, 72)[1:72])

    # PTGNAME (30 × 10 chars)
    for j in 1:30
        _chwrit_str!(cbuff, ipnt, _CHPUTGET_LNCBUF, ibeg, rpad(PTGNAME[j], 10)[1:10])
    end

    # VARACD (2 chars)
    _chwrit_str!(cbuff, ipnt, _CHPUTGET_LNCBUF, ibeg, rpad(VARACD, 2)[1:2])

    # CALCSDI (7 chars)
    _chwrit_str!(cbuff, ipnt, _CHPUTGET_LNCBUF, ibeg, rpad(CALCSDI, 7)[1:7])

    # BFCTYPE (1 char), CFCTYPE (1 char)
    CHWRIT(cbuff, ipnt, _CHPUTGET_LNCBUF, UInt8(isempty(BFCTYPE) ? ' ' : BFCTYPE[1]), ibeg[])
    ibeg[] = Int32(2)
    CHWRIT(cbuff, ipnt, _CHPUTGET_LNCBUF, UInt8(isempty(CFCTYPE) ? ' ' : CFCTYPE[1]), ibeg[])
    ibeg[] = Int32(2)

    # Extension-specific character variables
    DBSCHPUT(cbuff, ipnt, _CHPUTGET_LNCBUF)
    VARCHPUT(cbuff, ipnt, _CHPUTGET_LNCBUF)
    MSCHPUT(cbuff, ipnt, _CHPUTGET_LNCBUF)

    # Final dummy character with ibegin=3 to flush
    CHWRIT(cbuff, ipnt, _CHPUTGET_LNCBUF, UInt8('X'), Int32(3))
    return nothing
end

# ---------------------------------------------------------------------------
# CHGET — read all character variables from stash
# ---------------------------------------------------------------------------
function CHGET()
    cbuff   = Vector{UInt8}(undef, _CHPUTGET_LNCBUF)
    ipnt    = Ref{Int32}(Int32(_CHPUTGET_LNCBUF))  # triggers reload on first CHREAD
    ibeg    = Ref{Int32}(Int32(1))

    # MGMID (4 chars)
    global MGMID = _chread_str!(cbuff, ipnt, _CHPUTGET_LNCBUF, ibeg, 4)

    # NPLT (26 chars)
    global NPLT = _chread_str!(cbuff, ipnt, _CHPUTGET_LNCBUF, ibeg, 26)

    # DBCN — same length as the current DBCN (LEN(DBCN))
    dbcn_len = length(DBCN)
    global DBCN = _chread_str!(cbuff, ipnt, _CHPUTGET_LNCBUF, ibeg, dbcn_len)

    # Event monitor label sets (conditional on LBSETS)
    if LBSETS
        if LENSLS > Int32(0)
            s = _chread_str!(cbuff, ipnt, _CHPUTGET_LNCBUF, ibeg, Int(LENSLS))
            global SLSET = s
        end
        if Int(IEVA) > 1
            for i in 1:Int(IEVA)-1
                j = Int(LENAGL[i])
                if j >= 1
                    AGLSET[i] = _chread_str!(cbuff, ipnt, _CHPUTGET_LNCBUF, ibeg, j)
                end
            end
        end
    end

    # IOSP arrays (same order as CHPUT)
    for j in 1:4
        for v in (IOSPTT, IOSPBR, IOSPTV, IOSPMR, IOSPSR,
                  IOSPAC, IOSPCT, IOSPCV, IOSPMC, IOSPSC, IOSPBV, IOSPRT, IOSPMO)
            v[j] = _chread_str!(cbuff, ipnt, _CHPUTGET_LNCBUF, ibeg, 3)
        end
    end

    # IONSP (6 entries × 3 chars)
    for j in 1:6
        IONSP[j] = _chread_str!(cbuff, ipnt, _CHPUTGET_LNCBUF, ibeg, 3)
    end

    # ALLSUB (6 chars)
    global ALLSUB = _chread_str!(cbuff, ipnt, _CHPUTGET_LNCBUF, ibeg, 6)

    # SUBNAM (ITOP bytes)
    if Int(ITOP) > 0
        _chread_bytes!(cbuff, ipnt, _CHPUTGET_LNCBUF, ibeg, SUBNAM, Int(ITOP))
    end

    # CTSTV5 (ITST5 × 8 chars)
    if Int(ITST5) > 0
        for j in 1:Int(ITST5)
            CTSTV5[j] = _chread_str!(cbuff, ipnt, _CHPUTGET_LNCBUF, ibeg, 8)
        end
    end

    # CACT (ICACT × 1 char)
    if Int(ICACT) > 0
        tmp = Ref{UInt8}(UInt8(' '))
        for i in 1:Int(ICACT)
            CHREAD(cbuff, ipnt, _CHPUTGET_LNCBUF, tmp, ibeg[])
            ibeg[] = Int32(2)
            CACT[i] = Char(tmp[])
        end
    end

    # NAMGRP (30 × 10 chars)
    for j in 1:30
        NAMGRP[j] = _chread_str!(cbuff, ipnt, _CHPUTGET_LNCBUF, ibeg, 10)
    end

    # VEQNNB (MAXSP × 11 chars)
    for j in 1:MAXSP
        VEQNNB[j] = _chread_str!(cbuff, ipnt, _CHPUTGET_LNCBUF, ibeg, 11)
    end

    # VEQNNC (MAXSP × 11 chars)
    for j in 1:MAXSP
        VEQNNC[j] = _chread_str!(cbuff, ipnt, _CHPUTGET_LNCBUF, ibeg, 11)
    end

    # CPVREF (10 chars)
    global CPVREF = _chread_str!(cbuff, ipnt, _CHPUTGET_LNCBUF, ibeg, 10)

    # ITITLE (72 chars)
    global ITITLE = _chread_str!(cbuff, ipnt, _CHPUTGET_LNCBUF, ibeg, 72)

    # PTGNAME (30 × 10 chars)
    for j in 1:30
        PTGNAME[j] = _chread_str!(cbuff, ipnt, _CHPUTGET_LNCBUF, ibeg, 10)
    end

    # VARACD (2 chars)
    global VARACD = _chread_str!(cbuff, ipnt, _CHPUTGET_LNCBUF, ibeg, 2)

    # CALCSDI (7 chars)
    global CALCSDI = _chread_str!(cbuff, ipnt, _CHPUTGET_LNCBUF, ibeg, 7)

    # BFCTYPE (1 char), CFCTYPE (1 char)
    global BFCTYPE = _chread_str!(cbuff, ipnt, _CHPUTGET_LNCBUF, ibeg, 1)
    global CFCTYPE = _chread_str!(cbuff, ipnt, _CHPUTGET_LNCBUF, ibeg, 1)

    # Extension-specific character variables
    DBSCHGET(cbuff, ipnt, _CHPUTGET_LNCBUF)
    VARCHGET(cbuff, ipnt, _CHPUTGET_LNCBUF)
    MSCHGET(cbuff, ipnt, _CHPUTGET_LNCBUF)

    # Final dummy character read with ibegin=3
    tmp = Ref{UInt8}(UInt8(' '))
    CHREAD(cbuff, ipnt, _CHPUTGET_LNCBUF, tmp, Int32(3))
    return nothing
end

# ---------------------------------------------------------------------------
# Extension stubs for character serialization (implemented elsewhere or no-op)
# DBSCHPUT/DBSCHGET → extensions/dbs/dbsqlite.jl (or stub below)
# VARCHPUT/VARCHGET → sn/varput.jl, sn/varget.jl
# MSCHPUT/MSCHGET  → mistletoe extension (no-op)
# ---------------------------------------------------------------------------
# DBSCHPUT/DBSCHGET: real implementations in extensions/dbs/dbsqlite.jl (loaded later)
function MSCHPUT(cbuff::AbstractVector{UInt8}, ipnt_ref::Ref{Int32}, lncbuf::Int32)
    return nothing   # stub: mistletoe extension
end
function MSCHGET(cbuff::AbstractVector{UInt8}, ipnt_ref::Ref{Int32}, lncbuf::Int32)
    return nothing   # stub
end
