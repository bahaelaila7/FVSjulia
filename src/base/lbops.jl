# lbops.jl — Label set processing for the event monitor
# Translated from:
#   lb1mem.f (55 lines)   — LB1MEM: get first set member
#   lbmemr.f (53 lines)   — LBMEMR: test membership
#   lbunin.f (98 lines)   — LBUNIN: set union
#   lbintr.f (86 lines)   — LBINTR: set intersection
#   lbtrim.f (82 lines)   — LBTRIM: trim empty-intersection activity groups
#   lbget1.f (170 lines)  — LBGET1: read first member from IO stream
#   lbaglr.f (87 lines)   — LBAGLR: read activity group label from IO
#   lbsplr.f (71 lines)   — LBSPLR: read stand policy label from IO
#   lbstrd.f (93 lines)   — LBSTRD: read records into label set string
#   rcdset.f (26 lines)   — RCDSET: set model return code
#
# Label sets are comma-separated member lists stored in up to 250-char strings.
# Each member is a keyword-length token; members are separated by ", ".

# ---------------------------------------------------------------------------
# RCDSET — set the model return code
# ---------------------------------------------------------------------------
function RCDSET(ic::Integer, lretrn::Bool)
    global ICCODE
    if Int(ic) > Int(ICCODE); ICCODE = Int32(ic); end
    if !lretrn; fvsSetRtnCode(Int32(1)); end
    return nothing
end

# ---------------------------------------------------------------------------
# LB1MEM — return the first member of SETIN between positions IP1..IP2
# On return: LENONE=length of member, ONEMEM=member string
# ---------------------------------------------------------------------------
function LB1MEM(ip1::Integer, ip2::Integer, setin::AbstractString,
                lenone_ref::Ref{Int32}, onemem_ref::Ref{String})
    lenone_ref[] = Int32(0)
    onemem_ref[] = " "
    if ip1 <= 0 || ip2 <= 0 || ip2 < ip1; return nothing; end
    # Clamp to string length
    n = length(setin)
    p1 = min(Int(ip1), n)
    p2 = min(Int(ip2), n)
    sub = setin[p1:p2]
    lcomma = findfirst(',', sub)
    if lcomma === nothing
        lenone_ref[] = Int32(p2 - p1 + 1)
        onemem_ref[] = sub
    else
        lc = lcomma - 1   # 0-based length before comma
        if lc > 0
            lenone_ref[] = Int32(lc)
            onemem_ref[] = sub[1:lc]
        end
    end
    return nothing
end

# ---------------------------------------------------------------------------
# LBMEMR — true if MEM(1:LENMEM) is a member of SET(1:LENSET)
# ---------------------------------------------------------------------------
function LBMEMR(lenmem::Integer, mem::AbstractString,
                lenset::Integer, set::AbstractString)::Bool
    ip = 1
    lenmem_i = Int(lenmem); lenset_i = Int(lenset)
    lenone_r = Ref(Int32(0)); wrk_r = Ref("")
    while ip <= lenset_i
        LB1MEM(ip, lenset_i, set, lenone_r, wrk_r)
        lenwrk = Int(lenone_r[])
        if lenmem_i == lenwrk
            m1 = min(lenmem_i, length(mem))
            w1 = min(lenwrk, length(wrk_r[]))
            if m1 == w1 && mem[1:m1] == wrk_r[][1:w1]
                return true
            end
        end
        ip += lenwrk + 2
    end
    return false
end

# ---------------------------------------------------------------------------
# LBUNIN — set union of SET1 and SET2 → UNION; KODE: 0=OK, 1=overflow
# ---------------------------------------------------------------------------
function LBUNIN(len1::Integer, set1::AbstractString,
                len2::Integer, set2::AbstractString,
                lnunin_ref::Ref{Int32}, union_ref::Ref{String},
                kode_ref::Ref{Int32})
    kode_ref[]  = Int32(0)
    lnunin_ref[] = Int32(0)
    union_ref[]  = " "
    len1_i = Int(len1); len2_i = Int(len2)

    if len1_i <= 0
        if len2_i > 0; lnunin_ref[] = Int32(len2_i); union_ref[] = set2; end
        return nothing
    end
    if len2_i <= 0
        lnunin_ref[] = Int32(len1_i); union_ref[] = set1; return nothing
    end

    # Start with set1 as union
    union  = set1[1:min(len1_i, length(set1))]
    lnunin = len1_i
    lenone_r = Ref(Int32(0)); wrks1_r = Ref("")

    ip = 1
    while ip <= len2_i
        LB1MEM(ip, len2_i, set2, lenone_r, wrks1_r)
        lenwrk = Int(lenone_r[])
        if !LBMEMR(lenwrk, wrks1_r[], lnunin, union)
            if lnunin + lenwrk + 2 <= 250
                wrks1 = wrks1_r[][1:min(lenwrk, length(wrks1_r[]))]
                union = union[1:lnunin] * ", " * wrks1
                lnunin += lenwrk + 2
            else
                kode_ref[] = Int32(1)
            end
        end
        ip += lenwrk + 2
    end
    lnunin_ref[] = Int32(lnunin)
    union_ref[]  = union
    return nothing
end

# ---------------------------------------------------------------------------
# LBINTR — set intersection of SET1 and SET2 → INTRST; KODE: 0=OK, 1=overflow
# ---------------------------------------------------------------------------
function LBINTR(len1::Integer, set1::AbstractString,
                len2::Integer, set2::AbstractString,
                lnintr_ref::Ref{Int32}, intrst_ref::Ref{String},
                kode_ref::Ref{Int32})
    kode_ref[]  = Int32(0)
    lnintr_ref[] = Int32(0)
    intrst_ref[] = " "
    len1_i = Int(len1); len2_i = Int(len2)

    if len1_i <= 0 || len2_i <= 0; return nothing; end

    intrst = ""; lnintr = 0
    lenone_r = Ref(Int32(0)); wrks1_r = Ref("")

    ip = 1
    while ip <= len1_i
        LB1MEM(ip, len1_i, set1, lenone_r, wrks1_r)
        lenwrk = Int(lenone_r[])
        if LBMEMR(lenwrk, wrks1_r[], len2_i, set2)
            wrks1 = wrks1_r[][1:min(lenwrk, length(wrks1_r[]))]
            if lnintr == 0
                intrst = wrks1; lnintr = lenwrk
            else
                if lnintr + lenwrk + 2 <= 250
                    intrst = intrst[1:lnintr] * ", " * wrks1
                    lnintr += lenwrk + 2
                else
                    kode_ref[] = Int32(1)
                end
            end
        end
        ip += lenwrk + 2
    end
    lnintr_ref[] = Int32(lnintr)
    intrst_ref[] = intrst
    return nothing
end

# ---------------------------------------------------------------------------
# LBTRIM — delete from MAELNK activity groups whose label∩stand label is empty
# MAE_REF is updated to the compressed count.
# ---------------------------------------------------------------------------
function LBTRIM(mae_ref::Ref{Int32}, maelnk::AbstractMatrix{Int32})
    mae = Int(mae_ref[])
    if mae <= 0; return nothing; end
    idel = 0
    lnintr_r = Ref(Int32(0)); intrst_r = Ref(""); kode_r = Ref(Int32(0))
    for i in 1:mae
        j = Int(maelnk[1, i])
        if j > 0 && Int(LENAGL[j]) >= 0
            LBINTR(LENSLS, SLSET, Int(LENAGL[j]), AGLSET[j],
                   lnintr_r, intrst_r, kode_r)
            if Int(lnintr_r[]) == 0
                maelnk[1, i] = Int32(0)
                idel += 1
            end
        end
    end
    if idel > 0
        if idel == mae
            mae_ref[] = Int32(0)
        else
            len = 0
            for i in 1:mae
                if maelnk[1, i] <= 0; continue; end
                len += 1
                maelnk[1, len] = maelnk[1, i]
                maelnk[2, len] = maelnk[2, i]
            end
            mae_ref[] = Int32(len)
        end
    end
    return nothing
end

# ---------------------------------------------------------------------------
# LBGET1 — read first label member from IO unit IREAD into MEM
# KIND: 0=normal, 1=harvest policy label (keeps one period)
# KODE: 0=OK, 1=overflow, 2=end-of-data
# ---------------------------------------------------------------------------
function LBGET1(iread::Integer, irecnt_ref::Ref{Int32}, record_ref::Ref{String},
                irps_ref::Ref{Int32}, lenmem_ref::Ref{Int32}, mem_ref::Ref{String},
                kind::Integer, kode_ref::Ref{Int32})
    kode_ref[] = Int32(0)
    mxlen = kind == 0 ? 250 : 40
    lenmem_ref[] = Int32(0)
    mem_ref[] = " "

    lbkadd = false; lperd = false; lpdone = true
    io = get(io_units, Int32(iread), nothing)
    if io === nothing; kode_ref[] = Int32(2); return nothing; end

    while true
        irps = Int(irps_ref[])
        if irps == 0
            local rec::String
            try; rec = readline(io); catch; kode_ref[] = Int32(2); return nothing; end
            irecnt_ref[] += Int32(1)
            record_ref[] = rec
            irps = 0
        end

        record = record_ref[]
        rlen   = length(record)

        @label label_char_loop
        irps += 1
        irps_ref[] = Int32(irps)

        if irps > rlen
            # End of record — end of member by definition
            return nothing
        end

        c = record[irps]

        if c == '&'
            irps_ref[] = Int32(0)
            continue
        end

        lenmem = Int(lenmem_ref[])

        if lenmem == 0
            if c == ' ' || c == ',' || c == '.'; @goto label_char_loop; end
        end

        if c == ','
            return nothing
        end

        if c == ' '
            lbkadd = true; @goto label_char_loop
        end

        if c == '.'
            if kind == 0; @goto label_char_loop; end
            if lperd; @goto label_char_loop; end
            lperd = true; lpdone = false; @goto label_char_loop
        end

        # Non-special char — add to member
        lenmem = Int(lenmem_ref[])
        if lperd && !lpdone
            lpdone = true; lbkadd = false
            if lenmem + 3 <= mxlen
                mem_buf = (lenmem > 0 ? mem_ref[][1:lenmem] : "") * ". " * string(c)
                lenmem_ref[] = Int32(lenmem + 3)
                mem_ref[] = mem_buf
            else
                kode_ref[] = Int32(1)
                # drain continuation records
                @goto label_drain
            end
        elseif lbkadd
            if lenmem + 2 <= mxlen
                mem_buf = (lenmem > 0 ? mem_ref[][1:lenmem] : "") * " " * string(c)
                lenmem_ref[] = Int32(lenmem + 2)
                mem_ref[] = mem_buf
                lbkadd = false
            else
                kode_ref[] = Int32(1); @goto label_drain
            end
        else
            if lenmem + 1 <= mxlen
                mem_ref[] = (lenmem > 0 ? mem_ref[][1:lenmem] : "") * string(c)
                lenmem_ref[] = Int32(lenmem + 1)
            else
                kode_ref[] = Int32(1); @goto label_drain
            end
        end
        @goto label_char_loop

        @label label_drain
        # Drain any continuation lines (records ending with '&')
        i = Int(ISTLNB(record))
        if i > 0 && record[i] == '&'
            try; record_ref[] = readline(io); catch; return nothing; end
            irecnt_ref[] += Int32(1)
            @goto label_drain
        end
        return nothing
    end
end

# ---------------------------------------------------------------------------
# LBSTRD — read IO stream records and build a label set in SET/LENSET
# ---------------------------------------------------------------------------
function LBSTRD(iread::Integer, lenset_ref::Ref{Int32}, set_ref::Ref{String},
                irecnt_ref::Ref{Int32}, record_ref::Ref{String},
                kode_ref::Ref{Int32}, wrk1_ref::Ref{String}, wrk2_ref::Ref{String})
    kode_ref[]  = Int32(0)
    lenset_ref[] = Int32(0)
    set_ref[]    = " "
    irps_ref = Ref(Int32(0))
    lnwrk2_r = Ref(Int32(0)); lnwrk1_r = Ref(Int32(0))
    lnunin_r = Ref(Int32(0)); union_r = Ref(""); kode2 = Ref(Int32(0))

    while true
        wrk2_ref[] = " "
        LBGET1(iread, irecnt_ref, record_ref, irps_ref, lnwrk2_r, wrk2_ref, 0, kode_ref)
        if Int(kode_ref[]) > 0; return nothing; end
        if Int(lnwrk2_r[]) == 0; return nothing; end

        lnwrk1_r[] = lenset_ref[]
        wrk1_ref[] = set_ref[]
        LBUNIN(lnwrk1_r[], wrk1_ref[], lnwrk2_r[], wrk2_ref[],
               lnunin_r, union_r, kode2)
        if Int(kode2[]) > 0
            # Drain continuation
            record = record_ref[]
            i = Int(ISTLNB(record))
            if i > 0 && record[i] == '&'
                io = get(io_units, Int32(iread), nothing)
                if io !== nothing
                    try; record_ref[] = readline(io); catch; kode_ref[] = Int32(2); return nothing; end
                    irecnt_ref[] += Int32(1)
                end
            end
        end
        kode_ref[] = kode2[]
        if Int(kode_ref[]) > 0; return nothing; end
        lenset_ref[] = lnunin_r[]
        set_ref[]    = union_r[]
    end
end

# ---------------------------------------------------------------------------
# LBAGLR — read an activity group label set from keyword file and store in OPCOM
# Returns Int32 kode: 0=OK, 1=end-of-data (matching initre.jl calling convention)
# ---------------------------------------------------------------------------
function LBAGLR(keywrd::AbstractString, jostnd::Integer, iread::Integer,
                irecnt::Integer, record::AbstractString)::Int32
    wrk1_r = Ref(""); wrk2_r = Ref(""); lwrk_r = Ref(Int32(0))
    kode_r = Ref(Int32(0))
    irecnt_r = Ref(Int32(irecnt)); record_r = Ref(String(record))
    LBSTRD(iread, lwrk_r, wrk1_r, irecnt_r, record_r, kode_r, wrk1_r, wrk2_r)
    if Int(kode_r[]) > 1; return Int32(1); end

    out = get(io_units, Int32(jostnd), stdout)
    @printf(out, "\n%-8s   ACTIVITY GROUP LABEL SET: \n", keywrd)
    lwrk = Int(lwrk_r[])
    i1 = 1
    while i1 <= lwrk
        i2 = min(i1 + 99, lwrk)
        @printf(out, "%12s%s\n", "", wrk1_r[][i1:min(i2, length(wrk1_r[]))])
        i1 = i2 + 1
    end

    if Int(kode_r[]) == 1
        @printf(out, "\n ********   WARNING: THIS LABEL SET IS SHORTER THAN THE ONE YOU SPECIFIED.\n")
        RCDSET(1, true)
    end

    if LOPEVN
        global LBSETS = true
        AGLSET[Int(IEVA)] = wrk1_r[]
        LENAGL[Int(IEVA)] = lwrk_r[]
    else
        @printf(out, "\n ********   ERROR: THIS ACTIVITY GROUP LABEL IS NOT PART OF AN ACTIVITY GROUP AND WILL BE IGNORED.\n")
        RCDSET(1, true)
    end
    return Int32(0)
end

# ---------------------------------------------------------------------------
# LBSPLR — read stand policy label set from keyword file and store in OPCOM
# Returns Int32 kode: 0=OK, 1=end-of-data (matching initre.jl calling convention)
# ---------------------------------------------------------------------------
function LBSPLR(keywrd::AbstractString, jostnd::Integer, iread::Integer,
                irecnt::Integer, record::AbstractString, lkecho::Bool)::Int32
    wrk1_r = Ref(""); wrk2_r = Ref("")
    lenset_r = Ref(LENSLS); set_r = Ref(SLSET)
    kode_r = Ref(Int32(0))
    irecnt_r = Ref(Int32(irecnt)); record_r = Ref(String(record))
    LBSTRD(iread, lenset_r, set_r, irecnt_r, record_r, kode_r, wrk1_r, wrk2_r)
    if Int(kode_r[]) > 1; return Int32(1); end

    global SLSET  = set_r[]
    global LENSLS = lenset_r[]
    global LBSETS = true

    out = get(io_units, Int32(jostnd), stdout)
    if lkecho; @printf(out, "\n%-8s   STAND POLICY LABEL SET:\n", keywrd); end
    i1 = 1
    while i1 <= Int(LENSLS)
        i2 = min(i1 + 99, Int(LENSLS))
        if lkecho
            @printf(out, "%12s%s\n", "", SLSET[i1:min(i2, length(SLSET))])
        end
        i1 = i2 + 1
    end

    if Int(kode_r[]) == 1
        @printf(out, "\n********   WARNING: THIS LABEL SET IS SHORTER THAN THE ONE YOU SPECIFIED.\n")
        RCDSET(1, true)
    end
    return Int32(0)
end

# ---------------------------------------------------------------------------
# LBDSET — create default stand label set from all activity group labels
# ---------------------------------------------------------------------------
function LBDSET(jostnd::Integer, lkecho::Bool)
    if !LBSETS; return nothing; end
    ngrps = Int(IEVA) - 1
    out   = get(io_units, Int32(jostnd), stdout)

    if Int(LENSLS) == -1 && ngrps > 0
        lnunin_r = Ref(Int32(0)); union_r = Ref(""); kode_r = Ref(Int32(0))
        lens_ref = Ref(LENSLS); sl_ref = Ref(SLSET)
        for i in 1:ngrps
            LBUNIN(lens_ref[], sl_ref[], Int(LENAGL[i]), AGLSET[i],
                   lnunin_r, union_r, kode_r)
            if Int(kode_r[]) > 0
                @printf(out, "\n********   ERROR:  DEFAULT STAND LABEL SET IS TOO LONG.  THE FOLLOWING ACTIVITY GROUP IS NOT INCLUDED.\nACTIVITY LABEL:  %s\n",
                        AGLSET[i][1:min(Int(LENAGL[i]), length(AGLSET[i]))])
                RCDSET(2, true)
            end
            global SLSET = union_r[]
            global LENSLS = lnunin_r[]
            lens_ref[] = lnunin_r[]; sl_ref[] = union_r[]
        end

        if SLSET == " " || SLSET == ""
            global LBSETS = false; global LENSLS = Int32(-1); return nothing
        end

        if lkecho
            @printf(out, "\nSPLABEL   STAND POLICY LABEL SET: \n")
            i1 = 1
            while i1 <= Int(LENSLS)
                i2 = min(i1 + 99, Int(LENSLS))
                @printf(out, "%12s%s\n", "", SLSET[i1:min(i2,length(SLSET))])
                i1 = i2 + 1
            end
        end
    end

    # Assign stand label set to activity groups with no label
    j = 0
    for i in 1:ngrps
        if Int(LENAGL[i]) <= 0
            j += 1
            global LENAGL = copy(LENAGL)
            LENAGL[i] = LENSLS
            AGLSET[i] = SLSET
        end
    end
    if j > 0
        @printf(out, "\n********   WARNING: %2d ACTIVITY GROUP(S) HAD NO LABEL AND WERE ASSIGNED THE STAND POLICY LABEL SET.\n", j)
    end
    return nothing
end
