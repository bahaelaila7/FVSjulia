# algmon.jl — Event monitor algebra: expression compiler + evaluator
# Translated from:
#   algptg.f (60 lines)   — ALGPTG: point-group code lookup
#   algspp.f (69 lines)   — ALGSPP: species code lookup
#   algkey.f (524 lines)  — ALGKEY: keyword token table lookup
#   algexp.f (185 lines)  — ALGEXP: read user-defined variable expressions
#   algcmp.f (703 lines)  — ALGCMP: infix→postfix expression compiler
#   algevl.f (663 lines)  — ALGEVL: postfix expression evaluator

# ---------------------------------------------------------------------------
# ALGPTG — convert token to point-group load opcode
# IRC: 0=found, 1=not found
# ---------------------------------------------------------------------------
function ALGPTG(ctok::AbstractString, len::Integer, num_ref::Ref{Int32}, irc_ref::Ref{Int32})
    ctemp = len == 1 ? (" " * ctok[1:1]) : ctok
    for i in 1:Int(NPTGRP)
        if ctok[1:min(Int(len),length(ctok))] == rstrip(PTGNAME[i])
            num_ref[] = Int32(-(i + 2000))
            irc_ref[] = Int32(0)
            return nothing
        end
    end
    irc_ref[] = Int32(1)
    return nothing
end

# ---------------------------------------------------------------------------
# ALGSPP — convert token to species or species-group load opcode
# IRC: 0=found, 1=not found
# ---------------------------------------------------------------------------
function ALGSPP(ctok::AbstractString, len::Integer, num_ref::Ref{Int32}, irc_ref::Ref{Int32})
    ctemp = len == 1 ? (" " * ctok[1:1]) : String(ctok[1:min(Int(len),length(ctok))])
    # Search 2-char alpha species codes (JSP array)
    for i in 1:Int(MAXSP)
        jname = rstrip(JSP[i])
        nc = min(Int(len), length(jname))
        if nc >= 1 && ctemp[1:nc] == jname[1:min(nc,length(jname))]
            num_ref[] = Int32(-i)
            irc_ref[] = Int32(0)
            return nothing
        end
    end
    # Search species group codes
    tok = ctok[1:min(Int(len),length(ctok))]
    for i in 1:Int(NSPGRP)
        if tok == rstrip(NAMGRP[i])
            num_ref[] = Int32(-(i + 1000))
            irc_ref[] = Int32(0)
            return nothing
        end
    end
    irc_ref[] = Int32(1)
    return nothing
end

# ---------------------------------------------------------------------------
# ALGKEY — keyword token table lookup
# Returns opcode NUM for a given token CTOK of length LEN.
# IRC: 0=found, 1=not found
# ---------------------------------------------------------------------------
function ALGKEY(ctok::AbstractString, len::Integer, num_ref::Ref{Int32}, irc_ref::Ref{Int32})
    num_ref[] = Int32(0)
    tok = uppercase(ctok[1:min(Int(len), length(ctok))])

    # 2-char table
    _T2 = ("GT","GE","LT","LE","EQ","NE","OR","NO")
    _O2 = (  6,   7,   8,   9,   4,   5,   3, 112)
    # 3-char table
    _T3 = ("AGE","BBA","ABA","ACC","PAI","MAI","DBA","AND","NOT","YES","EXP","INT",
            "SIN","COS","TAN","MOD","SMR","CUT","MIN","MAX","ABS","ALL","LAT","IRR",
            "PNV","SEV")
    _O3 = (102,107,205,301,303,145,307,2,1,111,23,27,
            28,29,30,10100,134,136,10900,11000,34,112,137,
            435,437,439)
    # 4-char table
    _T4 = ("YEAR","BTPA","BCCF","ATPA","RTPA","MORT","DTPA","DBA%","DCCF","ACCF",
            "RANN","SQRT","ALOG","FRAC","TIME","ELEV","SITE","BSDI","ASDI","FIRE",
            "LONG","BGMD","AGMD")
    _O4 = (101,103,108,201,209,302,305,308,309,206,
            900,22,24,26,10300,129,135,116,214,420,
            138,159,238)
    # 5-char table
    _T5 = ("BBDFT","BADBH","ABDFT","AADBH","RBDFT","DTPA%","DCCF%","TM%DF","TM%GF",
            "CYCLE","SLOPE","AVACC","PARMS","BOUND","AVBBA","SNAGS","STATE","INDEX",
            "BRDEN","ARDEN","ASDI2","BSDI2")
    _O5 = (106,110,204,208,212,306,310,402,403,113,
            127,7006,10700,11100,7005,11800,139,12000,117,215,
            218,150)
    # 6-char table
    _T6 = ("BTCUFT","BMCUFT","BTOPHT","ATCUFT","AMCUFT","ATOPHT","RTCUFT","RMCUFT",
            "ALOG10","ARCSIN","ARCCOS","ARCTAN","DECADE","ASPECT","SAMPWT","AVBTPA",
            "AVMORT","LININT","BCCFSP","ACCFSP","NORMAL","COUNTY","FORTYP","SIZCLS",
            "STKCLS","BMAXHS","AMAXHS","BMINHS","AMINHS","BNUMSS","ANUMSS","AGECMP",
            "BRDEN2","ARDEN2","HTDIST","DWDVAL","ECCUFT","ECBDFT","ACORNS","ORG%CC",
            "ORGAHT","BSCUFT","ASCUFT","RSCUFT")
    _O6 = (104,105,109,202,203,207,210,211,25,31,32,33,10200,
            128,130,7001,7007,10800,11200,11300,11600,140,
            141,142,143,440,441,442,443,444,445,146,118,217,
            13100,13300,449,450,13400,311,312,120,220,221)
    # 7-char table
    _T7 = ("TM%STND","MPBTPAK","BW%STND","SUMSTAT","HABTYPE","INVYEAR","TOTALWT",
            "AVBBDFT","DBHDIST","SPMCDBH","EVPHASE","MPBPROB","OLDTARG","BSDIMAX",
            "ASDIMAX","BSCLASS","ASCLASS","BSTRDBH","ASTRDBH","MINSOIL","BCANCOV",
            "ACANCOV","POTFLEN","PCTCOST","PROPSTK","SALVVOL","POINTID","STRSTAT",
            "TREEBIO","BHTWTBA","AHTWTBA","BABVBIO","BMERBIO","BSAWBIO","BFOLBIO",
            "BABVCRB","BMERCRB","BSAWCRB","BFOLCRB","AABVBIO","RABVBIO","AMERBIO",
            "RMERBIO","ASAWBIO","RSAWBIO","AABVCRB","RABVCRB","AMERCRB","RMERCRB",
            "ASAWCRB","RSAWCRB","AFOLBIO","RFOLBIO","AFOLCRB","RFOLCRB")
    _O7 = (401,404,405,10400,126,131,7008,7004,10500,
            10600,133,406,7009,115,213,416,417,418,
            419,421,424,425,11900,436,144,12300,12400,12500,
            12900,119,219,
            151,152,153,154,155,156,157,158,
            222,223,224,225,226,227,228,229,230,231,232,233,
            234,235,236,237)
    # 8-char table
    _T8 = ("NUMTREES","AVBTCUFT","AVBMCUFT","MSPERIOD","CENDYEAR","MININDEX","MAXINDEX",
            "FUELLOAD","FIREYEAR","CROWNIDX","CRBASEHT","TORCHIDX","CRBULKDN","DISCCOST",
            "DISCREVN","FORSTVAL","HARVCOST","HARVREVN","RPRODVAL","POTFMORT","FUELMODS",
            "DISCRATE","UNDISCST","UNDISRVN","BDBHWTBA","ADBHWTBA","POTFTYPE","POTSRATE",
            "POTREINT","CARBSTAT","SILVAHFT","FISHERIN","HERBSHRB","CLSPVIAB")
    _O8 = (114,7002,7003,7010,132,11400,11500,
            11700,423,422,426,427,428,430,431,432,433,434,
            438,12100,12200,446,447,448,147,216,12600,12700,12800,
            13000,148,149,13200,13500)

    n = Int(len)
    tables_ops = (
        (1, _T2, _O2), (2, _T3, _O3), (3, _T4, _O4),
        (4, _T5, _O5), (5, _T6, _O6), (6, _T7, _O7), (7, _T8, _O8)
    )
    for (_, tbl, ops) in tables_ops
        toklen = length(first(tbl))
        if n == toklen
            for (j, kw) in enumerate(tbl)
                if tok == kw
                    num_ref[] = Int32(ops[j])
                    irc_ref[] = Int32(0)
                    return nothing
                end
            end
            break   # no need to search other length tables
        end
    end

    # 1-char: just blank
    if n == 1
        irc_ref[] = Int32(1)
        return nothing
    end

    # Check species codes
    num_r = Ref(Int32(0)); irc_r = Ref(Int32(1))
    ALGSPP(ctok, len, num_r, irc_r)
    if irc_r[] == Int32(0)
        num_ref[] = num_r[]; irc_ref[] = Int32(0); return nothing
    end
    # Check point group codes
    ALGPTG(ctok, len, num_r, irc_r)
    if irc_r[] == Int32(0)
        num_ref[] = num_r[]; irc_ref[] = Int32(0); return nothing
    end
    # Check user-defined variable tables
    EVKEY(ctok[1:min(8,length(ctok))], num_r, irc_r)
    if irc_r[] == Int32(0)
        num_ref[] = num_r[]; irc_ref[] = Int32(0); return nothing
    end
    irc_ref[] = Int32(1)
    return nothing
end

# ---------------------------------------------------------------------------
# ALGEXP — read user-defined variable expressions from keyword file
# Called from EVUSRV (event monitor user variable block).
# Reads records from IO unit IREAD; fills CEXPRS char array with RHS.
# IRC: 0=OK, 1=END keyword found
# ---------------------------------------------------------------------------
function ALGEXP(cexprs::AbstractVector{UInt8}, lencex_ref::Ref{Int32}, mxexpr::Integer,
                cleft_ref::Ref{String}, lclft_ref::Ref{Int32}, record_ref::Ref{String},
                irecnt_ref::Ref{Int32}, iread::Integer, jostnd::Integer, irc_ref::Ref{Int32})
    CHRSPCL = "^!\"#%&'()*+,-./:;<=>?@[\\]^`{|}~"
    io = get(io_units, Int32(iread), nothing)
    if io === nothing; irc_ref[] = Int32(1); return nothing; end

    @label label_1
    cleft = ""
    lencex_ref[] = Int32(0)
    lclft_ref[]  = Int32(0)

    @label label_5
    local record::String
    try
        record = readline(io)
    catch
        ERRGRO(false, Int32(2))
        irc_ref[] = Int32(0)
        return nothing
    end
    irecnt_ref[] += Int32(1)
    record_ref[]  = record

    lencex = Int(lencex_ref[])
    # skip comment lines if no expression started yet
    if lencex == 0 && length(record) > 0 && (record[1] == '*' || record[1] == '!')
        out = get(io_units, Int32(jostnd), stdout)
        @printf(out, "%12s%s\n", "", rstrip(record))
        @goto label_5
    end

    # Check for END
    endtok = uppercase(rstrip(length(record) >= 5 ? record[1:5] : record))
    if startswith(endtok, "END")
        out = get(io_units, Int32(jostnd), stdout)
        @printf(out, "\nEND\n")
        irc_ref[] = Int32(1)
        return nothing
    end

    out2 = get(io_units, Int32(jostnd), stdout)
    @printf(out2, "%12s%s\n", "", rstrip(record))

    # Find '&' and '='
    iamp = 0; iequ = 0
    for (i,c) in enumerate(record)
        if c == '&'; iamp = i; break; end
        if c == '='; iequ = i; end
    end

    lclft = Int(lclft_ref[])
    if iequ > 0 || (lclft == 0 && iamp > 0)
        j = iequ > 0 ? iequ - 1 : iamp - 1
        for i in 1:j
            c = record[i]
            if c != ' '
                lclft += 1
                if lclft <= 20
                    cleft = cleft * uppercase(string(c))
                end
            end
        end
        # Check for invalid special chars in first 8 positions
        for i in 1:min(8, length(cleft))
            if cleft[i] in CHRSPCL
                ERRGRO(false, Int32(39))
                @goto label_1
            end
        end
        if lclft > 8
            lclft = 8
            cleft = cleft[1:8]
            @printf(out2, "\n            \"%s\" WILL BE SHORTENED TO \"%s\"\n",
                    record[1:iequ-1], cleft[1:8])
        end
        if iequ == 0 && iamp > 0
            lclft_ref[] = Int32(lclft)
            cleft_ref[] = cleft
            @goto label_5
        end
    end
    lclft_ref[] = Int32(lclft)
    cleft_ref[] = cleft

    if lclft <= 0; @goto label_1; end

    # Find RHS non-blank start and end
    j = iamp > 0 ? iamp - 1 : length(record)
    i2 = iequ + 1
    if i2 > j; i2 = j; end
    i1 = 0
    for i in i2:j
        i <= length(record) || break
        if record[i] != ' '; i1 = i; break; end
    end
    if i1 == 0; @goto label_5; end  # all blank
    # last non-blank
    i2t = j
    for i in 1:j
        k = j - i + 1
        k <= length(record) || continue
        if record[k] != ' '; i2t = k; break; end
    end

    lencex = Int(lencex_ref[])
    for i in i1:i2t
        i <= length(record) || break
        if lencex + 1 > mxexpr
            ERRGRO(true, Int32(5))
            @goto label_1
        end
        lencex += 1
        cexprs[lencex] = UInt8(uppercase(record[i])[1])
    end
    lencex_ref[] = Int32(lencex)

    if iamp > 0
        if lencex < mxexpr
            lencex += 1
            cexprs[lencex] = UInt8(' ')
            lencex_ref[] = Int32(lencex)
        end
        @goto label_5
    end
    irc_ref[] = Int32(0)
    return nothing
end

# ---------------------------------------------------------------------------
# ALGCMP — infix expression compiler (infix → postfix opcodes)
#
# Translates CEXPRS (char array) into postfix operation codes in IOPCOD.
# IRC: 0=OK, else error code
# ---------------------------------------------------------------------------
function ALGCMP(irc_ref::Ref{Int32}, lif::Bool,
                cexprs::AbstractVector{UInt8}, lenex::Integer, jostnd::Integer,
                ldebug::Bool, ibascn::Integer,
                istack::AbstractVector{Int32}, mxstck::Integer,
                iopcod::AbstractVector{Int32}, iops_ref::Ref{Int32}, mxops::Integer,
                consts::AbstractVector{Float32}, ilcons_ref::Ref{Int32},
                itcons_ref::Ref{Int32}, mxcons::Integer)

    irc_ref[] = Int32(0)
    isops  = Int(iops_ref[])
    islcon = Int(ilcons_ref[])
    istcon = Int(itcons_ref[])

    ILPAR   = Int32(-10001)
    IRPAR   = Int32(-10002)
    ICOMMA  = Int32(-10003)
    MXTOK   = 20
    MXTMP   = 50
    IPRMAP  = Int32[3,2,1,4,4,4,4,4,4,0,5,5,6,6,8,7]
    CNUMBS  = "0123456789."
    COPS    = "()+-*/, "

    itmp  = zeros(Int32, MXTMP)
    iops  = isops
    ilcons = islcon
    itcons = istcon

    icexp  = 1
    itop   = 1
    lstone = true     # unary flag: true if next +/- is unary

    out = get(io_units, Int32(jostnd), stdout)

    # Build token from cexprs characters
    function peek_char(pos::Int)
        pos <= lenex ? Char(cexprs[pos]) : '\0'
    end

    while icexp <= lenex
        cchar = Char(cexprs[icexp])

        if cchar == '('
            istack[itop] = ILPAR
            lstone = true
            itop += 1
            if itop > mxstck; @goto err_430; end
            icexp += 1
            continue
        elseif cchar == ')'
            istack[itop] = IRPAR
            lstone = false
            itop += 1
            if itop > mxstck; @goto err_430; end
            icexp += 1
            continue
        elseif cchar == ','
            istack[itop] = ICOMMA
            lstone = true
            itop += 1
            if itop > mxstck; @goto err_430; end
            icexp += 1
            continue
        elseif cchar == '+'
            if lstone
                lstone = false
                icexp += 1; continue   # unary plus: discard
            else
                istack[itop] = Int32(11)
                lstone = false
                itop += 1; if itop > mxstck; @goto err_430; end
                icexp += 1; continue
            end
        elseif cchar == '-'
            if lstone
                istack[itop] = Int32(16)   # unary minus
            else
                istack[itop] = Int32(12)   # binary minus
            end
            lstone = false
            itop += 1; if itop > mxstck; @goto err_430; end
            icexp += 1; continue
        elseif cchar == '/'
            istack[itop] = Int32(14)
            lstone = false
            itop += 1; if itop > mxstck; @goto err_430; end
            icexp += 1; continue
        elseif cchar == '*'
            if icexp < lenex && Char(cexprs[icexp+1]) == '*'
                istack[itop] = Int32(15)   # exponentiation
                icexp += 1
            else
                istack[itop] = Int32(13)   # multiplication
            end
            lstone = false
            itop += 1; if itop > mxstck; @goto err_430; end
            icexp += 1; continue
        elseif cchar == ' '
            icexp += 1; continue
        end

        # Must be a token (number or keyword)
        itoken = 1
        ctok_buf = Vector{UInt8}(undef, MXTOK)
        fill!(ctok_buf, UInt8(' '))
        ctok_buf[1] = UInt8(cchar)
        lnumb = cchar in CNUMBS
        icexp += 1

        # Scan rest of token
        while icexp <= lenex
            cchar2 = Char(cexprs[icexp])
            if lnumb && cchar2 == 'E'
                itoken += 1
                if itoken > MXTOK; @goto err_460; end
                ctok_buf[itoken] = UInt8('E')
                icexp += 1
                if icexp > lenex; break; end
                c3 = Char(cexprs[icexp])
                if c3 == '+' || c3 == '-'
                    itoken += 1
                    if itoken > MXTOK; @goto err_460; end
                    ctok_buf[itoken] = UInt8(c3)
                    icexp += 1
                end
                continue
            end
            if cchar2 in COPS; break; end
            itoken += 1
            if itoken > MXTOK; @goto err_460; end
            ctok_buf[itoken] = UInt8(uppercase(cchar2))
            icexp += 1
        end

        ctok = String(ctok_buf[1:itoken])
        if ldebug; @printf(out, "%s\n", ctok); end

        if lnumb
            # Ensure decimal point present
            if !('.' in ctok)
                ctok = ctok * "."
            end
            rlnum = parse(Float32, ctok)

            # Find or add constant
            nccn = 0
            if itcons > -1
                if ilcons > itcons; @goto err_450; end
                if itcons == mxcons
                    nccn = mxcons; itcons -= 1
                else
                    found = false
                    for iccn in mxcons:-1:itcons+1
                        if consts[iccn] == rlnum; nccn = iccn; found = true; break; end
                    end
                    if !found
                        nccn = itcons; itcons -= 1
                    end
                end
            else
                if ilcons > mxcons; @goto err_450; end
                if ilcons == 1
                    nccn = 1; ilcons += 1
                else
                    found = false
                    for iccn in 1:ilcons-1
                        if consts[iccn] == rlnum; nccn = iccn; found = true; break; end
                    end
                    if !found
                        nccn = ilcons; ilcons += 1
                    end
                end
            end
            consts[nccn] = rlnum
            istack[itop] = Int32(ibascn + nccn)
            lstone = false
        else
            num_r = Ref(Int32(0)); irc_r = Ref(Int32(1))
            ALGKEY(ctok, itoken, num_r, irc_r)
            if irc_r[] != Int32(0)
                EVMKV(ctok)
                ALGKEY(ctok, itoken, num_r, irc_r)
            end
            if irc_r[] != Int32(0); @goto err_470; end
            num = Int(num_r[])
            lstone = (num >= 1 && num <= 9)
            istack[itop] = Int32(num)
        end
        itop += 1
        if itop > mxstck; @goto err_430; end
    end

    # ---- Infix → Postfix conversion ----
    itop -= 1
    if itop <= 0; @goto err_490; end

    if ldebug
        for i in 1:itop
            @printf(out, " ISTACK(%4d)=%6d\n", i, istack[i])
        end
    end

    ntmp = 0; ncomma = 0
    for ii in 1:itop
        isym = Int(istack[ii])

        if (isym < 0 && isym > -10000) || (isym >= 100 && isym < 10000)
            # Load operand → directly to iopcod
            iopcod[iops] = Int32(isym)
            iops += 1
            if iops > mxops; @goto err_400; end
        else
            if ntmp == 0 || isym == Int(ILPAR)
                if isym == Int(IRPAR) || isym == Int(ICOMMA); @goto err_410; end
                ntmp += 1
                if ntmp > MXTMP; @goto err_430; end
                if isym > 10000; isym += ncomma; ncomma = 0; end
                itmp[ntmp] = Int32(isym)
            else
                if isym == Int(IRPAR) || isym == Int(ICOMMA)
                    j = ntmp
                    while j >= 1
                        if itmp[j] != ILPAR
                            if itmp[j] > 10000
                                icnt = Int(itmp[j]) % 100
                                iopcod[iops] = Int32((Int(itmp[j]) ÷ 100 * 100) + ncomma + 1)
                                ncomma = icnt
                            else
                                iopcod[iops] = itmp[j]
                            end
                            iops += 1
                            if iops > mxops; @goto err_400; end
                            j -= 1
                        else
                            if isym == Int(ICOMMA)
                                ncomma += 1
                                if ncomma > 98; @goto err_446; end
                            else
                                j -= 1
                            end
                            break
                        end
                    end
                    ntmp = j
                else
                    # Regular operator
                    @label label_330
                    if itmp[ntmp] == ILPAR
                        ntmp += 1
                        if ntmp > MXTMP; @goto err_430; end
                        if isym > 10000; isym += ncomma; ncomma = 0; end
                        itmp[ntmp] = Int32(isym)
                    else
                        j_prec = (isym >= 1 && isym <= 16) ? Int(IPRMAP[isym]) : 9
                        t_prec = (Int(itmp[ntmp]) >= 1 && Int(itmp[ntmp]) <= 16) ? Int(IPRMAP[Int(itmp[ntmp])]) : 9
                        if j_prec <= t_prec
                            if Int(itmp[ntmp]) > 10000
                                icnt = Int(itmp[ntmp]) % 100
                                iopcod[iops] = Int32((Int(itmp[ntmp]) ÷ 100 * 100) + ncomma + 1)
                                ncomma = icnt
                            else
                                iopcod[iops] = itmp[ntmp]
                            end
                            iops += 1
                            if iops > mxops; @goto err_400; end
                            if ntmp == 1 || j_prec == t_prec
                                itmp[ntmp] = Int32(isym)
                            else
                                ntmp -= 1
                                @goto label_330
                            end
                        else
                            ntmp += 1
                            if ntmp > MXTMP; @goto err_430; end
                            if isym > 10000; isym += ncomma; ncomma = 0; end
                            itmp[ntmp] = Int32(isym)
                        end
                    end
                end
            end
        end
    end  # for ii

    # Flush remaining operators from temp stack
    for ii in 1:ntmp
        j = ntmp - ii + 1
        if itmp[j] == ILPAR; @goto err_410; end
        if Int(itmp[j]) > 10000
            icnt = Int(itmp[j]) % 100
            iopcod[iops] = Int32((Int(itmp[j]) ÷ 100 * 100) + ncomma + 1)
            ncomma = icnt
        else
            iopcod[iops] = itmp[j]
        end
        iops += 1
        if iops > mxops; @goto err_400; end
    end

    if ncomma > 0; @goto err_440; end

    # Terminating zero
    iopcod[iops] = Int32(0)

    # Validate logical expression
    if lif
        icnt = 0; ibool = 0
        for k in isops:iops
            itest = Int(iopcod[k])
            if itest < 10
                if itest >= 2 && itest <= 3; ibool += 1; end
                if itest >= 4 && itest <= 9; icnt += 1; end
            end
        end
        if icnt - 1 != ibool; @goto err_480; end
    end

    iops_ref[] = Int32(iops + 1)
    ilcons_ref[] = Int32(ilcons)
    itcons_ref[] = Int32(itcons)
    if ldebug
        @printf(out, "\nLEAVING ALGCMP, IOPCOD(%d TO %d) =\n", isops, iops)
        for i in isops:iops; @printf(out, " %7d", iopcod[i]); end
        @printf(out, "\n")
    end
    return nothing

    @label err_400
    @printf(out, "\n            NOT ENOUGH STORAGE TO STORE EXPRESSION.\n")
    irc_ref[] = Int32(1); @goto err_600
    @label err_410
    @printf(out, "\n            MISMATCHED OR OTHER MISUSE OF PARENTHESIS.\n")
    irc_ref[] = Int32(2); @goto err_600
    @label err_430
    @printf(out, "\n            NOT ENOUGH STORAGE TO COMPILE EXPRESSION.\n")
    irc_ref[] = Int32(4); @goto err_600
    @label err_440
    @printf(out, "\n            A COMMA WAS USED WITHOUT AN OPERATOR THAT ALLOWS ONE.\n")
    irc_ref[] = Int32(5); @goto err_600
    @label err_446
    @printf(out, "\n            TOO MANY COMMAS IN ONE FUNCTION.\n")
    irc_ref[] = Int32(5); @goto err_600
    @label err_450
    @printf(out, "\n            NOT ENOUGH STORAGE TO STORE CONSTANTS IN THE EXPRESSION.\n")
    irc_ref[] = Int32(6); @goto err_600
    @label err_460
    @printf(out, "\n            A VARIABLE OR NUMBER (TOKEN) IS TOO LONG.\n")
    irc_ref[] = Int32(6); @goto err_600
    @label err_470
    @printf(out, "\n            AN ILLEGAL VARIABLE WAS FOUND.\n")
    irc_ref[] = Int32(7); @goto err_600
    @label err_480
    @printf(out, "\n            A LOGICAL EXPRESSION WAS EXPECTED BUT NOT FOUND.\n")
    irc_ref[] = Int32(8); @goto err_600
    @label err_490
    @printf(out, "\n            NO EXPRESSION WAS FOUND.\n")
    irc_ref[] = Int32(9); @goto err_600
    @label err_600
    iops_ref[]   = Int32(isops)
    ilcons_ref[] = Int32(islcon)
    itcons_ref[] = Int32(istcon)
    return nothing
end

# ---------------------------------------------------------------------------
# ALGEVL — postfix expression evaluator
#
# Evaluates opcodes compiled by ALGCMP. Uses XREG (real stack) and LREG
# (logical stack / undefined-status flags).
# IRC: 0=OK, 1=undefined var, 2=bad opcode, 3=stack imbalance, 4=overflow
# ---------------------------------------------------------------------------
function ALGEVL(lreg::AbstractVector{Bool}, mxl::Integer,
                xreg::AbstractVector{Float32}, mxx::Integer,
                iopcd::AbstractVector{Int32}, mxcd::Integer,
                iyr1::Integer, iyrcur::Integer,
                ldb::Bool, jout::Integer, irc_ref::Ref{Int32})

    ilstk = 0; ixstk = 0
    out = get(io_units, Int32(jout), stdout)

    if ldb
        @printf(out, "\n IN ALGEVL: MXL=%5d; MXX=%5d; MXCD=%5d; IYR1=%5d; IYRCUR=%5d\n",
                mxl, mxx, mxcd, iyr1, iyrcur)
    end

    for ipc in 1:mxcd
        instr = Int(iopcd[ipc])

        if ldb
            if ilstk > 0
                for ii in 1:ilstk; @printf(out, " %3s", lreg[ii] ? "T" : "F"); end; @printf(out, "\n")
            end
            if ixstk > 0
                for ii in 1:ixstk; @printf(out, " %14.6E", xreg[ii]); end; @printf(out, "\n")
            end
            @printf(out, " PROG COUNTER=%6d; INSTR= %5d; ILSTK= %4d; IXSTK=%4d\n",
                    ipc, instr, ilstk, ixstk)
        end

        if instr == 0; break; end   # end of expression

        # Negative: species or species-group code
        if instr < 0
            ixstk += 1
            if ixstk > mxx || ilstk >= mxl - ixstk + 1; @goto err_2040; end
            v = instr
            if instr < -2000
                v = instr + 2000   # point group
            elseif instr < -1000
                v = instr + 1000   # species group
            else
                v = -instr
            end
            xreg[ixstk] = Float32(v)
            lreg[mxl - ixstk + 1] = false
            continue
        end

        # Logical/boolean (1..9)
        if instr <= 9
            if instr == 1
                if ilstk == 0; @goto err_2040; end
                lreg[ilstk] = !lreg[ilstk]
                continue
            elseif instr <= 3
                if ilstk <= 1; @goto err_2040; end
                ilstk -= 1
                lreg[ilstk] = instr == 2 ? (lreg[ilstk+1] && lreg[ilstk]) :
                                            (lreg[ilstk+1] || lreg[ilstk])
                continue
            else  # 4..9 comparison
                ixstk -= 2
                if ixstk < 0; @goto err_2040; end
                ilstk += 1
                if ilstk > mxl - ixstk; @goto err_2040; end
                if lreg[mxl - ixstk] || lreg[mxl - ixstk - 1]
                    irc_ref[] = Int32(1); return nothing
                end
                i_rel = instr - 3
                x1 = xreg[ixstk+1]; x2 = xreg[ixstk+2]
                lreg[ilstk] = (i_rel == 1) ? (x1 == x2) :
                               (i_rel == 2) ? (x1 != x2) :
                               (i_rel == 3) ? (x1 >  x2) :
                               (i_rel == 4) ? (x1 >= x2) :
                               (i_rel == 5) ? (x1 <  x2) :
                                              (x1 <= x2)
                continue
            end
        end

        # Unary arithmetic (16, 22..34)
        if instr <= 34
            if instr == 16; j_uni = 1
            else
                j_uni = instr - 20
                if j_uni < 2 || j_uni > 14; @goto err_2020; end
            end
            if lreg[mxl - ixstk + 1]; continue; end   # undefined → propagate
            if j_uni == 1;  xreg[ixstk] = -xreg[ixstk]
            elseif j_uni == 2; xreg[ixstk] = sqrt(abs(xreg[ixstk]))
            elseif j_uni == 3; xreg[ixstk] = exp(xreg[ixstk])
            elseif j_uni == 4; xreg[ixstk] = log(xreg[ixstk])
            elseif j_uni == 5; xreg[ixstk] = log10(xreg[ixstk])
            elseif j_uni == 6; xreg[ixstk] = xreg[ixstk] - trunc(xreg[ixstk])
            elseif j_uni == 7; xreg[ixstk] = trunc(xreg[ixstk])
            elseif j_uni == 8; xreg[ixstk] = sin(xreg[ixstk])
            elseif j_uni == 9; xreg[ixstk] = cos(xreg[ixstk])
            elseif j_uni == 10; xreg[ixstk] = tan(xreg[ixstk])
            elseif j_uni == 11; xreg[ixstk] = asin(xreg[ixstk])
            elseif j_uni == 12; xreg[ixstk] = acos(xreg[ixstk])
            elseif j_uni == 13; xreg[ixstk] = atan(xreg[ixstk])
            elseif j_uni == 14; xreg[ixstk] = abs(xreg[ixstk])
            end
            continue
        end

        # Binary arithmetic (11..15) — handled by: instr > 10 && instr <= 15
        if instr > 10 && instr <= 15
            ixstk -= 1
            if ixstk <= 0; @goto err_2040; end
            lreg[mxl - ixstk + 1] = lreg[mxl - ixstk + 1] || lreg[mxl - ixstk]
            if lreg[mxl - ixstk + 1]; xreg[ixstk] = Float32(0); continue; end
            j_bin = instr - 10
            if j_bin == 1; xreg[ixstk] += xreg[ixstk+1]
            elseif j_bin == 2; xreg[ixstk] -= xreg[ixstk+1]
            elseif j_bin == 3; xreg[ixstk] *= xreg[ixstk+1]
            elseif j_bin == 4
                if xreg[ixstk+1] == 0.0f0
                    lreg[mxl - ixstk + 1] = true
                else
                    xreg[ixstk] /= xreg[ixstk+1]
                end
            elseif j_bin == 5; xreg[ixstk] = xreg[ixstk] ^ xreg[ixstk+1]
            end
            continue
        end

        # Load variable (100 < instr < 10000)
        if instr > 100 && instr < 10000
            ixstk += 1
            if ixstk > mxx || ilstk >= mxl - ixstk + 1; @goto err_2040; end
            xldreg = Ref(Float32(0)); ievrc = Ref(Int32(0))
            # EVLDX is called with a sub-array starting at ixstk
            # Using our stub, which returns nothing and doesn't set the ref
            # We must call it properly with a temp array
            tmp_arr = zeros(Float32, max(1, mxx - ixstk + 1))
            EVLDX(tmp_arr, max(1, mxx - ixstk + 1), instr, ievrc)
            xreg[ixstk] = length(tmp_arr) > 0 ? tmp_arr[1] : Float32(0)
            lreg[mxl - ixstk + 1] = !(ievrc[] == Int32(0))
            if ievrc[] == Int32(2); @goto err_2020; end
            continue
        end

        # Multi-argument functions (instr > 10000)
        if instr > 10000
            i_fn = instr ÷ 100 - 100
            j_fn = instr % 100   # number of arguments

            if ixstk - j_fn < 0; @goto err_2040; end
            ixstk -= j_fn - 1   # result goes to ixstk

            if i_fn == 1  # MOD
                lreg[mxl - ixstk + 1] = lreg[mxl - ixstk + 1] || lreg[mxl - ixstk]
                if lreg[mxl - ixstk + 1]; continue; end
                if xreg[ixstk+1] == 0.0f0
                    lreg[mxl - ixstk + 1] = true
                else
                    xreg[ixstk] = xreg[ixstk] % xreg[ixstk+1]
                end
            elseif i_fn == 2  # DECADE
                ndc = ((Int(iyrcur) - Int(iyr1)) ÷ 10) + 1
                if ndc > j_fn; ndc = j_fn; end
                lreg[mxl - ixstk + 1] = lreg[mxl - ixstk - ndc + 2]
                if !lreg[mxl - ixstk + 1]
                    xreg[ixstk] = xreg[ixstk + ndc - 1]
                end
            elseif i_fn == 3  # TIME
                if j_fn > 2
                    ndc_s = ixstk + 1
                    ndc_e = ixstk + j_fn - 1
                    ndc_cur = ndc_s
                    xreg[ixstk] = xreg[ndc_cur - 1]
                    lreg[mxl - ixstk + 1] = lreg[mxl - ndc_cur + 2]
                    while ndc_cur <= ndc_e - 1
                        if lreg[mxl - ndc_cur + 1]
                            lreg[mxl - ixstk + 1] = true
                            break
                        end
                        if Int(iyrcur) >= Int(round(xreg[ndc_cur]))
                            xreg[ixstk] = xreg[ndc_cur + 1]
                            lreg[mxl - ixstk + 1] = lreg[mxl - ndc_cur]
                        else
                            break
                        end
                        ndc_cur += 2
                    end
                end
            elseif i_fn == 8  # LININT — stack: x, x1,y1, x2,y2, ...
                # j_fn must be 2*n+1 for n pairs; pairs are interleaved on stack
                if j_fn >= 3 && (j_fn - 1) % 2 == 0
                    n_pairs = (j_fn - 1) ÷ 2
                    all_def = true
                    for k in 1:j_fn
                        if lreg[mxl - ixstk - k + 2]; all_def = false; break; end
                    end
                    if all_def
                        # Extract interleaved (x1,y1, x2,y2, ...) pairs
                        xv = [xreg[ixstk + 2*k - 1] for k in 1:n_pairs]
                        yv = [xreg[ixstk + 2*k]     for k in 1:n_pairs]
                        xreg[ixstk] = ALGSLP(xreg[ixstk], xv, yv, n_pairs)
                        lreg[mxl - ixstk + 1] = false
                    else
                        lreg[mxl - ixstk + 1] = true; xreg[ixstk] = Float32(0)
                    end
                else
                    lreg[mxl - ixstk + 1] = true; xreg[ixstk] = Float32(0)
                end
            elseif i_fn == 7  # PARMS
                if j_fn + 1 > mxx || j_fn * 2 + 1 > mxl; @goto err_2040; end
                lreg[1] = true
                k = mxl
                for ndc in j_fn+1:-1:2
                    xreg[ndc] = xreg[ndc - 1]
                    lreg[ndc] = lreg[k]; k -= 1
                    lreg[1] = lreg[1] && !lreg[ndc]
                end
                xreg[1] = Float32(j_fn)
                lreg[mxl] = !lreg[1]
            elseif i_fn == 9 || i_fn == 10  # MIN / MAX
                if j_fn == 1
                    if lreg[mxl - ixstk + 1]; lreg[mxl - ixstk + 1] = true; end
                else
                    all_def = true
                    for k in 2:j_fn
                        if lreg[mxl - ixstk + 2 - k]; all_def = false; break; end
                        if i_fn == 9
                            xreg[ixstk] = min(xreg[ixstk], xreg[ixstk + k - 1])
                        else
                            xreg[ixstk] = max(xreg[ixstk], xreg[ixstk + k - 1])
                        end
                    end
                    if !all_def
                        lreg[mxl - ixstk + 1] = true; xreg[ixstk] = Float32(0)
                    end
                end
            elseif i_fn == 11  # BOUND
                if j_fn != 3; @goto err_2040; end
                if lreg[mxl - ixstk + 1] || lreg[mxl - ixstk] || lreg[mxl - ixstk - 1] ||
                   xreg[ixstk] >= xreg[ixstk+2]
                    lreg[mxl - ixstk + 1] = true; xreg[ixstk] = Float32(0)
                else
                    xreg[ixstk] = min(max(xreg[ixstk], xreg[ixstk+1]), xreg[ixstk+2])
                end
            elseif i_fn == 14 || i_fn == 15  # MININDEX / MAXINDEX
                if j_fn == 1
                    if lreg[mxl - ixstk + 1]; lreg[mxl - ixstk + 1] = true; xreg[ixstk] = Float32(0)
                    else xreg[ixstk] = Float32(1); end
                else
                    n_idx = 0
                    x_best = i_fn == 14 ? Float32(1e30) : Float32(-1e30)
                    found_idx = false
                    for k in 1:j_fn
                        if lreg[mxl - ixstk + 2 - k]
                            lreg[mxl - ixstk + 1] = true; xreg[ixstk] = Float32(0)
                            found_idx = true; break
                        end
                        v = xreg[ixstk + k - 1]
                        if (i_fn == 14 && v < x_best) || (i_fn == 15 && v > x_best)
                            n_idx = k; x_best = v
                        end
                    end
                    if !found_idx
                        if n_idx == 0; @goto err_2040; end
                        xreg[ixstk] = Float32(n_idx)
                    end
                end
            elseif i_fn == 16  # NORMAL
                lreg[mxl - ixstk + 1] = (j_fn != 2) || lreg[mxl - ixstk + 1] || lreg[mxl - ixstk]
                if !lreg[mxl - ixstk + 1]
                    xreg[ixstk] = BACHLO(xreg[ixstk], xreg[ixstk+1])
                end
            elseif i_fn == 20  # INDEX
                if j_fn < 2
                    lreg[mxl - ixstk + 1] = true; xreg[ixstk] = Float32(0)
                elseif lreg[mxl - ixstk + 1]
                    xreg[ixstk] = Float32(0)
                else
                    k_idx = Int(round(xreg[ixstk] + 0.5f0))
                    if k_idx < 1; k_idx = 1; end
                    if k_idx > j_fn - 1; k_idx = j_fn - 1; end
                    if lreg[mxl - ixstk + 1 - k_idx]
                        lreg[mxl - ixstk + 1] = true; xreg[ixstk] = Float32(0)
                    else
                        xreg[ixstk] = xreg[ixstk + k_idx]
                        lreg[mxl - ixstk + 1] = false
                    end
                end
            else  # other multi-arg functions (SUMSTAT, DBHDIST, etc.) → call EVLDX
                all_def = true
                for ndc in ixstk+1:ixstk+j_fn-1
                    if lreg[mxl - ixstk + 1]; all_def = false; break; end
                end
                if all_def
                    tmp_arr2 = zeros(Float32, max(1, mxx - ixstk + 1))
                    ievrc2 = Ref(Int32(0))
                    EVLDX(tmp_arr2, max(1, mxx - ixstk + 1), instr, ievrc2)
                    xreg[ixstk] = length(tmp_arr2) > 0 ? tmp_arr2[1] : Float32(0)
                    lreg[mxl - ixstk + 1] = !(ievrc2[] == Int32(0))
                    if ievrc2[] == Int32(2); @goto err_2020; end
                end
            end
            continue
        end

        @goto err_2020
    end  # for ipc

    # End of computations: check stack balance
    if ilstk + ixstk == 1
        irc_ref[] = Int32(0)
    else
        irc_ref[] = Int32(3)
    end
    if mxl > 0 && lreg[mxl]; irc_ref[] = Int32(1); end
    return nothing

    @label err_2020; irc_ref[] = Int32(2); return nothing
    @label err_2040; irc_ref[] = Int32(4); return nothing
end
