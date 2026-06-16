# opnewc.jl — OPNEWC: add an activity with expression (PARMS keyword) parameters
# Translated from: opnewc.f (166 lines)
#
# Called from INITRE when a keyword has a PARMS continuation record.
# Parses the expression into CEXPRS, calls ALGCMP to compile it,
# then stores the activity with a negative J1 pointer.

function OPNEWC(jostnd_arg::Integer, iread_arg::Integer,
                idt::Integer, iactk::Integer,
                keywrd::AbstractString, kard::AbstractVector{<:AbstractString},
                iprmpt::Integer, irecnt_ignored, icyc_arg::Integer)

    io = io_units[Int32(jostnd_arg)]
    debug = DBCHK(false, "OPNEWC", Int32(6), Int32(icyc_arg))

    # Copy PARMS fields into CEXPRS (columns iprmpt..7, each 10 chars)
    icex = 0
    for j in Int(iprmpt):7
        for k in 1:10
            icex += 1
            if j <= length(kard) && k <= length(kard[j])
                ch = kard[j][k]
                CEXPRS[icex] = UPCASE(ch)
            else
                CEXPRS[icex] = ' '
            end
        end
    end

    @printf(io, "\n%-8s   DATE/CYCLE=%5d;  %s\n",
        keywrd, idt, String(CEXPRS[1:icex]))

    # Check for continuation ampersand
    iamp = 0
    for i in 1:icex
        if CEXPRS[i] == '&'
            iamp = i
            break
        end
    end

    irtncd = Ref(Int32(0))
    while iamp > 0
        icex = iamp
        io_r = get(io_units, Int32(iread_arg), nothing)
        if isnothing(io_r)
            ERRGRO(false, Int32(2))
            fvsGetRtnCode(irtncd)
            if irtncd[] != 0; return Int32(1); end
            return Int32(1)
        end
        line = readline(io_r)
        global IRECNT = IRECNT + Int32(1)
        j = ISTLNB(line); if j == 0; j = 1; end
        iamp = 0
        for i in 1:j
            ch = i <= length(line) ? UPCASE(line[i]) : ' '
            CEXPRS[icex] = ch
            if ch == '&'
                iamp = icex
                break
            end
            icex += 1
            if icex > Int(MXEXPR)
                ERRGRO(true, Int32(4))
                return Int32(1)
            end
        end
        if iamp == 0; icex -= 1; end
        @printf(io, "%11s%s\n", "", line[1:j])
    end

    # Trim trailing blanks
    while icex > 1 && CEXPRS[icex] == ' '; icex -= 1; end

    # Compile expression via ALGCMP (stub: returns IRC=1 indicating no compile)
    kode_val = Int(ICOD)
    irc = Ref(Int32(0))
    ALGCMP(irc, false, CEXPRS, icex, Int32(jostnd_arg), debug,
           Int32(1000), IPTODO, Int32(MXPTDO), IEVCOD,
           ICOD, Int32(MAXCOD), PARMS, IMPL, ITOPRM, MAXPRM)

    if irc[] > 0
        ERRGRO(true, Int32(12))
        return Int32(1)
    end

    # Store activity with negative J1 pointer (expression-based)
    i = LOPEVN ? Int(IEPT) : Int(IMGL)
    IACT[i, 1] = Int32(iactk)
    IACT[i, 4] = Int32(0)
    IACT[i, 5] = Int32(0)
    IACT[i, 2] = Int32(-kode_val)
    IACT[i, 3] = Int32(0)
    IDATE[i]   = Int32(idt)
    global LEVUSE = true

    if LOPEVN
        global IEPT = IEPT - Int32(1)
    else
        IOPSRT[Int(IMGL)] = IMGL
        global IMGL = IMGL + Int32(1)
    end
    return Int32(0)
end
