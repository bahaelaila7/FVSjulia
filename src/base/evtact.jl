# evtact.f — EVTHEN/EVALSO/EVEND: event monitor IF-THEN/ALSOTRY/ENDIF keyword handlers (277 lines)
# Fortran ENTRY points → separate Julia functions with shared helper.

# Shared body entered at label 5 in Fortran (shared by EVALSO after IEVA increment, and EVTHEN)
function _evtact_body5(debug::Bool, jostnd::Integer, iread::Integer,
                        irecnt_ref::Ref{Int32},
                        keywrd::AbstractString, array::AbstractVector{Float32},
                        lnotbk::AbstractVector{Bool},
                        kard, iprmpt::Integer, lkecho::Bool)

    if IEVA > MAXEVA
        KEYDMP(Int32(jostnd), irecnt_ref[], keywrd, array, kard)
        ERRGRO(true, 16)
        return nothing
    end

    global ILGNUM = ILGNUM + Int32(1)

    if ILGNUM > 9
        ERRGRO(true, 22)
    end

    ieva = Int(IEVA)
    IEVACT[ieva, 1] = IEVT
    IEVACT[ieva, 2] = Int32(0)
    IEVACT[ieva, 3] = ILGNUM
    IEVACT[ieva, 4] = IEPT

    if lkecho
        io = io_units[Int32(jostnd)]
        @printf(io, "\n%-8s   ACTIVITIES WHICH FOLLOW WILL NOT BE SCHEDULED UNTIL THE EVENT HAPPENS (WHEN THE LOGICAL EXPRESSION IS TRUE).\n", keywrd)
    end

    if iprmpt == 0
        if lnotbk[1]
            if IMPL <= ITOPRM
                PARMS[Int(IMPL)] = array[1]
                IEVACT[ieva, 6] = IMPL
                global IMPL = IMPL + Int32(1)
                if lkecho
                    @printf(io_units[Int32(jostnd)], "            BRANCH WEIGHT MULTIPLIER = %12.5f\n", array[1])
                end
            else
                IEVACT[ieva, 6] = Int32(0)
                ERRGRO(true, 10)
                @printf(io_units[Int32(jostnd)], "            MULTIPLIER IGNORED.\n")
            end
        end
    else
        # Move expression into CEXPRS
        icex = 0
        for j in iprmpt:7
            for k in 1:10
                icex += 1
                ch = kard[j][k:k]
                CEXPRS[icex] = UInt8(uppercase(ch[1]))
            end
        end

        io = io_units[Int32(jostnd)]
        @printf(io, "            MULTIPLIER= %s\n", String(copy(CEXPRS[1:icex])))

        # Look for ampersand continuation
        iamp = 0
        for i in 1:icex
            if CEXPRS[i] == UInt8('&')
                iamp = i
                break
            end
        end

        while iamp > 0
            icex = iamp
            record = ""
            if haskey(io_units, Int32(iread))
                line = readline(io_units[Int32(iread)])
                record = length(line) >= 80 ? line[1:80] : rpad(line, 80)
            end
            irecnt_ref[] += Int32(1)
            j_end = 1
            for i in 80:-1:1
                if record[i:i] != " "
                    j_end = i
                    break
                end
            end
            iamp = 0
            for i in 1:j_end
                ch = uppercase(record[i:i])
                CEXPRS[icex] = UInt8(ch[1])
                if CEXPRS[icex] == UInt8('&')
                    iamp = icex
                    break
                end
                icex += 1
                if icex > Int(MXEXPR)
                    @printf(io, "            %s\n", record)
                    ERRGRO(true, 4)
                    IEVACT[ieva, 6] = Int32(-i)
                    return nothing
                end
            end
            icex -= 1
            @printf(io, "            %s\n", record)
        end

        # Trim trailing blanks
        while icex > 1 && CEXPRS[icex] == UInt8(' ')
            icex -= 1
        end

        i_save = Int(ICOD)
        irc_r  = Ref(Int32(0))
        icod_r   = Ref(ICOD)
        impl_r   = Ref(IMPL)
        itoprm_r = Ref(ITOPRM)
        ALGCMP(irc_r, false, CEXPRS, icex, Int32(jostnd), debug, 1000,
               IPTODO, Int(MXPTDO), IEVCOD, icod_r, Int(MAXCOD), PARMS, impl_r, itoprm_r, Int(MAXPRM))
        global ICOD   = icod_r[]
        global IMPL   = impl_r[]
        global ITOPRM = itoprm_r[]

        if irc_r[] > 0
            IEVACT[ieva, 6] = Int32(0)
            ERRGRO(true, 12)
        else
            IEVACT[ieva, 6] = Int32(-i_save)
        end
    end
    return nothing
end

# EVTHEN: called when THEN keyword is encountered
function EVTHEN(debug::Bool, jostnd::Integer, iread::Integer,
                irecnt::Integer, keywrd::AbstractString,
                array::AbstractVector{Float32},
                lnotbk::AbstractVector{Bool},
                kard, iprmpt::Integer, lkecho::Bool)

    if !LOPEVN || ILGNUM > 0
        KEYDMP(Int32(jostnd), irecnt, keywrd, array, kard)
        ERRGRO(true, 16)
        return nothing
    end

    irecnt_r = Ref(Int32(irecnt))
    _evtact_body5(debug, jostnd, iread, irecnt_r, keywrd, array, lnotbk, kard, iprmpt, lkecho)
    return nothing
end

# EVALSO: called when ALSOTRY keyword is encountered
function EVALSO(debug::Bool, jostnd::Integer, iread::Integer,
                irecnt::Integer, keywrd::AbstractString,
                array::AbstractVector{Float32},
                lnotbk::AbstractVector{Bool},
                kard, iprmpt::Integer)

    if !LOPEVN
        KEYDMP(Int32(jostnd), irecnt, keywrd, array, kard)
        ERRGRO(true, 16)
        return nothing
    end

    ieva = Int(IEVA)
    if IEVACT[ieva, 4] <= IEPT
        IEVACT[ieva, 4] = Int32(0)
        IEVACT[ieva, 5] = Int32(0)
    else
        IEVACT[ieva, 5] = IEPT + Int32(1)
    end

    global IEVA = IEVA + Int32(1)

    irecnt_r = Ref(Int32(irecnt))
    _evtact_body5(debug, jostnd, iread, irecnt_r, keywrd, array, lnotbk, kard, iprmpt, false)
    return nothing
end

# EVEND: called when ENDIF keyword is encountered
function EVEND(debug::Bool, jostnd::Integer, irecnt::Integer,
               keywrd::AbstractString, array::AbstractVector{Float32},
               lnotbk::AbstractVector{Bool},
               kard, iprmpt::Integer, lkecho::Bool)

    if !LOPEVN || ILGNUM <= 0
        if iprmpt <= -1
            return nothing
        end
        KEYDMP(Int32(jostnd), irecnt, keywrd, array, kard)
        ERRGRO(true, 16)
    else
        global LOPEVN = false
        global ILGNUM = Int32(0)
        global IEVT   = IEVT + Int32(1)

        ieva = Int(IEVA)
        if IEVACT[ieva, 4] <= IEPT
            IEVACT[ieva, 4] = Int32(0)
            IEVACT[ieva, 5] = Int32(0)
        else
            IEVACT[ieva, 5] = IEPT + Int32(1)
        end
        global IEVA = IEVA + Int32(1)

        if lkecho
            @printf(io_units[Int32(jostnd)], "\n%-8s   ACTIVITIES WHICH FOLLOW WILL BE SCHEDULED.\n", keywrd)
        end
    end
    return nothing
end
