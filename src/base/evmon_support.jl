# evmon_support.jl — Event monitor support subroutines
# Translated from:
#   evage.f   (60 lines)  — EVAGE: age posted events, reset for recurrence
#   evalnk.f  (43 lines)  — EVALNK: link event → first activity group
#   evcomp.f  (108 lines) — EVCOMP: read and compile IF-expression
#   evif.f    (80 lines)  — EVIF: compile and store an IF expression
#   evpost.f  (62 lines)  — EVPOST: post occurrence of an event
#   evpred.f  (237 lines) — EVPRED stub + FISHER entry: fisher habitat suitability
#   evusrv.f  (121 lines) — EVUSRV: read, compile, store user-defined variables

# ---------------------------------------------------------------------------
# EVAGE — age posted events; reset for re-occurrence when due
# IDTE = current year (posting date)
# ---------------------------------------------------------------------------
function EVAGE(idte::Integer)
    if Int(IEVT) <= 1; return nothing; end
    istrt = 1
    neva  = Int(IEVA) - 1
    ne    = Int(IEVT) - 1
    for ien in 1:ne
        if Int(IEVNTS[ien, 2]) == -1; continue; end
        if Int(IEVNTS[ien, 2]) + Int(IEVNTS[ien, 3]) > Int(idte); continue; end
        IEVNTS[ien, 2] = Int32(-1)
        i1 = istrt
        for i in i1:neva
            istrt = i
            if Int(IEVACT[i, 1]) < ien; continue; end
            if Int(IEVACT[i, 1]) > ien; break; end
            if Int(IEVACT[i, 2]) > -1
                IEVACT[i, 2] = Int32(0)
            end
        end
    end
    return nothing
end

# ---------------------------------------------------------------------------
# EVALNK — find pointer to first activity group row for event IEN
# ---------------------------------------------------------------------------
function EVALNK(jostnd::Integer, ien::Integer, ialnk_ref::Ref{Int32})
    n    = Int(IEVA) - 1
    ialnk_ref[] = Int32(0)
    for i in Int(ien):n
        if Int(IEVACT[i, 1]) == Int(ien)
            ialnk_ref[] = Int32(i)
            return nothing
        end
    end
    # Not found → error
    out = get(io_units, Int32(jostnd), stdout)
    @printf(out, "\n IEVA,IEN,IEVACT(1 TO IEVA-1,1)=\n")
    for i in 1:n; @printf(out, " %6d", IEVACT[i,1]); end
    @printf(out, "\n")
    ERRGRO(true, Int32(18))
    return nothing
end

# ---------------------------------------------------------------------------
# EVCOMP — read logical expression from IREAD into CEXPRS, then compile it
# IRC: 0=OK, 1=error
# ---------------------------------------------------------------------------
function EVCOMP(irc_ref::Ref{Int32}, iread::Integer, jostnd::Integer,
                record_ref::Ref{String}, ldebug::Bool,
                irecnt_ref::Ref{Int32}, lkecho::Bool)
    irc_ref[] = Int32(0)
    io  = get(io_units, Int32(iread), nothing)
    out = get(io_units, Int32(jostnd), stdout)
    if lkecho; @printf(out, "\n"); end

    fill!(CEXPRS, UInt8(0))
    icex = 1   # running position in CEXPRS

    @label label_5
    local rec::String
    try
        rec = readline(io)
    catch
        ERRGRO(false, Int32(2))
        irtncd = fvsGetRtnCode()
        if irtncd != Int32(0); return nothing; end
        return nothing
    end
    irecnt_ref[] += Int32(1)
    record_ref[] = rec

    # Uppercase the record
    rec = uppercase(rec)
    record_ref[] = rec
    if lkecho
        lnb = Int(ISTLNB(rec))
        @printf(out, "%12s%s\n", "", lnb > 0 ? rec[1:lnb] : "")
    end

    rlen = length(rec)
    i1 = icex
    i2 = min(i1 + rlen - 1, Int(MXEXPR))
    ii = 0
    for j in i1:i2
        ii += 1
        CEXPRS[j] = ii <= rlen ? UInt8(rec[ii]) : UInt8(' ')
    end

    if ii < rlen && rec[ii+1:rlen] != " "^(rlen - ii)
        @printf(out, "%12s%2d CHARS IGNORED: %s\n", "", rlen - ii, rec[ii+1:rlen])
        RCDSET(2, true)
    end

    # Check for ampersand continuation
    for j in i1:i2
        if CEXPRS[j] == UInt8('&')
            icex = j + 1
            CEXPRS[j] = UInt8(' ')
            @goto label_5
        end
    end

    # Find last non-blank
    i = 0
    for j in 1:i2
        k = i2 - j + 1
        if CEXPRS[k] != UInt8(' ') && CEXPRS[k] != UInt8(0)
            i = k; break
        end
    end

    if ldebug
        @printf(out, " IN EVCOMP, LENGTH=%4d; ICOD=%5d; IMPL=%5d\n", i, ICOD, IMPL)
    end

    icod_r = Ref(ICOD); impl_r = Ref(IMPL); itoprm_r = Ref(ITOPRM)
    ALGCMP(irc_ref, true, CEXPRS, i, jostnd, ldebug, 1000,
           IPTODO, Int(MXPTDO), IEVCOD, icod_r,
           Int(MAXCOD), PARMS, impl_r, itoprm_r,
           Int(MAXPRM))
    global ICOD   = icod_r[]
    global IMPL   = impl_r[]
    global ITOPRM = itoprm_r[]
    if Int(irc_ref[]) > 0
        irc_ref[] = Int32(1)
        ERRGRO(true, Int32(12))
    end
    return nothing
end

# ---------------------------------------------------------------------------
# EVIF — compile and store an IF expression (keyword handler)
# ---------------------------------------------------------------------------
function EVIF(keywrd::AbstractString, array::AbstractVector{Float32},
              lnotbk::AbstractVector{Bool}, irecnt::Integer,
              iread::Integer, record::AbstractString,
              kard, jostnd::Integer, ldebug::Bool, lkecho::Bool)
    if LOPEVN
        EVEND(ldebug, jostnd, irecnt, keywrd, array, lnotbk, kard, -1, lkecho)
    end

    if Int(IEVT) > Int(MAXEVT)
        ERRGRO(false, Int32(10))
    end
    if fvsGetRtnCode() != Int32(0); return nothing; end

    iwait = 1
    if length(lnotbk) >= 1 && lnotbk[1]
        iwait = Int(trunc(array[1]))
    end

    if lkecho
        out = get(io_units, Int32(jostnd), stdout)
        @printf(out, "\n%-8s   MINIMUM DELAY TIME BETWEEN RESPONSES TO THE EVENT = %5d\n",
                keywrd, iwait)
    end

    # Set up the event array pointers
    IEVNTS[Int(IEVT), 1] = ICOD
    IEVNTS[Int(IEVT), 2] = Int32(-1)
    IEVNTS[Int(IEVT), 3] = Int32(iwait)
    global LEVUSE = true

    irc_r    = Ref(Int32(0))
    irecnt_r = Ref(Int32(irecnt))
    record_r = Ref(String(record))
    EVCOMP(irc_r, iread, jostnd, record_r, ldebug, irecnt_r, lkecho)
    if fvsGetRtnCode() != Int32(0); return nothing; end

    global LOPEVN = true
    return nothing
end

# ---------------------------------------------------------------------------
# EVPOST — post occurrence of an event; set up activity group scheduling
# ---------------------------------------------------------------------------
function EVPOST(jostnd::Integer, ien::Integer, idte::Integer,
                ngrps_ref::Ref{Int32}, ialnk_ref::Ref{Int32})
    ngrps_ref[] = Int32(0)
    IEVNTS[ien, 2] = Int32(idte)
    EVALNK(jostnd, ien, ialnk_ref)
    if Int(ialnk_ref[]) == 0; return nothing; end
    neva = Int(IEVA) - 1
    for i in Int(ialnk_ref[]):neva
        if Int(IEVACT[i, 1]) > ien; break; end
        ngrps_ref[] += Int32(1)
        IEVACT[i, 2] = Int32(1)
    end
    return nothing
end

# ---------------------------------------------------------------------------
# FISHER_SN — Fisher resting habitat suitability index
# Translated from the ENTRY FISHER in evpred.f
# Stores result in findx_ref; requires fire model to be active.
# This overrides the stub in evtstv.jl with a full implementation.
# ---------------------------------------------------------------------------
function FISHER_SN(findx_ref::Ref{Float32})
    ldebug = DBCHK(false, "FISHER", Int32(6), ICYC)
    out    = get(io_units, Int32(JOSTND), stdout)
    if ldebug; @printf(out, " ENTERING SUBROUTINE EVPDEF, ENTRY FISHER, CYCLE =%4d\n", ICYC); end

    findx = Float32(0); temp = Float32(0)
    basm = Float32(0); ccpct = Float32(0)
    adhw = Float32(0); dmax = Float32(0); dsnmax = Float32(0)

    # Requires fire model active
    lfire2_r = Ref(false)
    FMATV(lfire2_r)
    if !lfire2_r[]; return Float32(0); end

    # Variant/region check
    varok = false
    if VARACD == "NC" && (Int(IFOR) == 4 || Int(IFOR) == 5); varok = true; end
    if (VARACD == "CA" || VARACD == "OC") && Int(IFOR) >= 6; varok = true; end
    if VARACD == "SO" && Int(IFOR) >= 4 && Int(IFOR) <= 9; varok = true; end
    if VARACD == "WS"; varok = true; end
    if !varok; return Float32(0); end
    if Int(ITRN) <= 0; return Float32(0); end

    # Sort by HT descending
    idx = collect(Int32(1):Int32(ITRN))
    RDPSRT(Int(ITRN), HT, idx, false)

    sumpin = Float32(0); htmax = Float32(0)
    for ii in 1:Int(ITRN)
        isrti = Int(idx[ii])
        p = PROB[isrti]
        if DBH[isrti] < Float32(1); continue; end
        if Int(ICR[isrti]) < 31; continue; end
        if HT[isrti] >= htmax
            ccpct  += p * CRWDTH[isrti]^2
            sumpin += p
        end
        if sumpin > TPROB * Float32(0.10) && htmax == Float32(0)
            htmax = HT[isrti] * Float32(0.50)
        end
    end
    ccpct = Float32(100.0) * ccpct * Float32(0.785398) / Float32(43560.0)

    sumtpa = Float32(0)
    for i in 1:Int(ITRN)
        ispc = Int(ISP[i])
        d    = DBH[i]
        p    = PROB[i]
        if d > dmax; dmax = d; end
        if d >= Float32(5.0) && d < Float32(20.0787)
            basm += Float32(0.0054542) * p * d * d
        end
        is_hw = (VARACD == "WS"  && (ispc == 7 || ispc == 11)) ||
                (VARACD == "NC"  && ispc in (5,7,8,11)) ||
                ((VARACD == "CA" || VARACD == "OC") && ispc >= 26) ||
                (VARACD == "SO"  && ((ispc >= 21 && ispc <= 31) || ispc == 33))
        if is_hw
            adhw   += d * p
            sumtpa += p
        end
    end

    dsnmax_r = Ref(Float32(0)); FMEVMSN(dsnmax_r); dsnmax = dsnmax_r[]

    # Convert to metric
    dmax   = dmax   * Float32(2.54)
    dsnmax = dsnmax * Float32(2.54)
    adhw   = sumtpa > Float32(0) ? (adhw / sumtpa) * Float32(2.54) : Float32(0)
    basm   = basm   * Float32(0.2295643)

    x1 = ccpct  > Float32(0) ? log10(ccpct)         : Float32(0)
    x2 = basm   > Float32(0) ? log10(basm)           : Float32(0)
    x3 = adhw   > Float32(0) ? log10(adhw)           : Float32(0)
    x4 = dmax   > Float32(0) ? log10(dmax)           : Float32(0)
    x5 = SLOPE  > Float32(0) ? log10(SLOPE * Float32(100)) : Float32(0)

    temp = -22.1217941f0 + 2.461062f0*x1 + 2.15615937f0*x2 + 0.47133361f0*x3 +
            4.55271635f0*x4 + 2.16130549f0*x5 + 0.00793579f0*dsnmax
    findx = exp(temp) / (Float32(1) + exp(temp))

    if ldebug
        @printf(out, " LEAVING FISHER, TEMP,FINDX= %g %g\n", temp, findx)
    end
    findx_ref[] = findx
    return nothing
end

# ---------------------------------------------------------------------------
# EVUSRV — read, compile, and schedule user-defined variable expressions
# Called from INITRE option 33 (COMPUTE keyword)
# ---------------------------------------------------------------------------
function EVUSRV(record::AbstractString, keywrd::AbstractString,
                array::AbstractVector{Float32}, lnotbk::AbstractVector{Bool},
                iread::Integer, jostnd::Integer, ldebug::Bool, irecnt::Integer)
    out     = get(io_units, Int32(jostnd), stdout)
    irtncd  = Ref(Int32(0))

    idt = 1
    if length(lnotbk) >= 1 && lnotbk[1]
        idt = Int(trunc(array[1]))
    end
    @printf(out, "\n%-8s   DATE/CYCLE=%5d; DEFINE THE FOLLOWING:\n\n", keywrd, idt)

    irecnt_r = Ref(Int32(irecnt))
    record_r = Ref(String(record))
    lencex_r = Ref(Int32(0))
    lclft_r  = Ref(Int32(0))
    cleft_r  = Ref("")
    irc_r    = Ref(Int32(0))

    @label label_10
    fill!(CEXPRS, UInt8(0))
    lencex_r[] = Int32(0); lclft_r[] = Int32(0); cleft_r[] = ""
    ALGEXP(CEXPRS, lencex_r, Int(MXEXPR), cleft_r, lclft_r, record_r, irecnt_r,
           iread, jostnd, irc_r)
    irtncd[] = fvsGetRtnCode()
    if irtncd[] != Int32(0); return nothing; end

    if Int(irc_r[]) == 1; return nothing; end   # END found

    # Check left-hand token
    cleft = cleft_r[]; lclft = Int(lclft_r[])
    ikey_r = Ref(Int32(0)); irckey_r = Ref(Int32(1))
    ALGKEY(cleft, lclft, ikey_r, irckey_r)
    if Int(irckey_r[]) != 0
        EVMKV(cleft)
        ALGKEY(cleft, lclft, ikey_r, irckey_r)
    end

    ikey = Int(ikey_r[])
    if Int(irckey_r[]) == 0
        if ikey < 500 || ikey > 500 + Int(MXTST5)
            ERRGRO(true, Int32(15))
            @goto label_10
        end
    end
    if Int(irckey_r[]) == 1
        ERRGRO(true, Int32(10))
        ERRGRO(true, Int32(12))
        @printf(out, " ISSUED IN EVUSRV CANNOT DEFINE VARIABLE\n")
        @goto label_10
    end

    array4 = Float32(ICOD)
    icod_r = Ref(ICOD); impl_r = Ref(IMPL); itoprm_r = Ref(ITOPRM)
    ALGCMP(irc_r, false, CEXPRS, Int(lencex_r[]), jostnd, ldebug, 1000,
           IPTODO, Int(MXPTDO), IEVCOD, icod_r, Int(MAXCOD), PARMS,
           impl_r, itoprm_r, Int(MAXPRM))
    global ICOD   = icod_r[]
    global IMPL   = impl_r[]
    global ITOPRM = itoprm_r[]

    if Int(irc_r[]) > 0
        ERRGRO(true, Int32(12))
        @goto label_10
    end

    arr2_ref = zeros(Float32, 12)
    arr2_ref[1] = Float32(0)
    arr2_ref[2] = Float32(0)
    arr2_ref[3] = Float32(ikey)
    irc2_r = Ref(Int32(0))
    OPNEW(irc2_r, idt, 33, 3, arr2_ref)
    if Int(irc2_r[]) > 0; @goto label_10; end
    @goto label_10
end
