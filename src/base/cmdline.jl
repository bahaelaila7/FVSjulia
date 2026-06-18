# cmdline.jl — FVS command-line / stop-point / restart interface
# Translated from: cmdline.f (489 lines)
#
# Stash file I/O (putstd/getstd) for stop-restart uses binary serialization
# that would require translating all of FVS state to/from binary.  For now,
# those paths are stubbed — the normal run-to-completion path is fully functional.

# Serialize / deserialize the full stand state to the stash file.
# The real work lives in PUTSTD()/GETSTD() (base/putstd.jl, base/getstd.jl),
# which pack every COMMON-block global into the WK3 buffer via the BFWRIT/
# BFREAD helpers and flush through STASH/DSTASH to units jstash/jdstash.
function putstd(); PUTSTD(); return nothing; end
function getstd(); GETSTD(); return nothing; end

function fvsSetCmdLine(theCmdLine::AbstractString, lenCL::Integer, irtncd_ref::Ref{Int32})
    # Reset global state
    if fvsRtnCode != 0 || restartcode != 0
        FILClose()
    end

    GENRPT()

    global keywordfile = ""
    global maxStoppts  = Int32(7)
    global stopptfile  = ""
    global fvsRtnCode  = Int32(0)
    global restartcode = Int32(0)
    global minorstopptcode = Int32(0)
    global minorstopptyear = Int32(0)
    global majorstopptcode = Int32(0)
    global majorstopptyear = Int32(0)
    global stopstatcd  = Int32(0)
    global originalRestartCode = Int32(0)
    global readFilePos = Int32(-1)
    global oldstopyr   = Int32(-1)
    global firstWrite  = Int32(1)
    global jstash      = Int32(-1)
    global jdstash     = Int32(-1)

    # Build command line string
    n = Int(lenCL)
    cmdline_str = if n > 0
        String(theCmdLine[1:min(n, length(theCmdLine))])
    else
        join(ARGS, " ")
    end

    if isempty(strip(cmdline_str))
        @goto label_100
    end

    # Parse --key=value pairs
    pos = 1
    while pos < length(cmdline_str)
        idx = findnext("--", cmdline_str, pos)
        if isnothing(idx); break; end
        pos = first(idx)
        ieq_m = findnext("=", cmdline_str, pos)
        if isnothing(ieq_m); break; end
        ieq = first(ieq_m)
        iend_m = findnext(" ", cmdline_str, ieq+1)
        iend = isnothing(iend_m) ? length(cmdline_str) : first(iend_m) - 1

        kw  = cmdline_str[pos:ieq]
        val = cmdline_str[ieq+1:iend]

        if kw == "--keywordfile="
            global keywordfile = val
        elseif kw == "--stoppoint="
            global stopptfile = val
            parts = split(val, ",")
            if length(parts) >= 2
                global majorstopptcode = Int32(parse(Int, strip(parts[1])))
                global majorstopptyear = Int32(parse(Int, strip(parts[2])))
                if majorstopptcode < -1; global majorstopptcode = Int32(-1); end
                if majorstopptcode > maxStoppts; global majorstopptcode = maxStoppts; end
                global stopptfile = length(parts) >= 3 ? strip(parts[3]) : "[none]"
                if isempty(stopptfile); global stopptfile = "[none]"; end
            end
        elseif kw == "--restart="
            global restartcode = Int32(1)
            if !isempty(val)
                global restartfile = val
            end
        end
        pos = iend + 1
    end

    if restartcode != 0
        if !isempty(keywordfile)
            println(stderr, "Specifying a keyword file conflicts with using a restart file; keyword file is ignored.")
            global keywordfile = ""
        end
        global jdstash = Int32(72)
        try
            io_restart = open(restartfile, "r")
            io_units[Int32(72)] = io_restart
            # Read restart header: restartcode, oldstopyr, nch, keywordfile[:nch]
            rc = read(io_restart, Int32)
            oy = read(io_restart, Int32)
            nch = read(io_restart, Int32)
            kf = String(read(io_restart, nch))
            global restartcode    = rc
            global oldstopyr      = oy
            global keywordfile    = kf
            global originalRestartCode = restartcode
            global stopstatcd = Int32(1)
            @printf(stderr, " Restarting from file=%s Year=%5d Stop point code=%2d\n",
                restartfile, oldstopyr, restartcode)
        catch e
            println(stderr, "Restart open error on file=", restartfile, ": ", e)
            global fvsRtnCode = Int32(1)
            irtncd_ref[] = fvsRtnCode
            return nothing
        end
    end

    if majorstopptcode != 0 && stopptfile != "[none]"
        global jstash = Int32(71)
        try
            io_stash = open(stopptfile, "w")
            io_units[Int32(71)] = io_stash
            @printf(stderr, " Stop point code=%2d Year=%5d File= %s\n",
                majorstopptcode, majorstopptyear, stopptfile)
        catch e
            println(stderr, "Stop point open error on file=", stopptfile, ": ", e)
            global fvsRtnCode = Int32(1)
            irtncd_ref[] = fvsRtnCode
            return nothing
        end
    elseif majorstopptcode != 0
        @printf(stderr, " Stop point code=%2d Year=%5d Will stop without saving data.\n",
            majorstopptcode, majorstopptyear)
    end

    @label label_100
    # Bridge API variable → CONTRL common block so FILOPN can read it
    global KWDFIL = keywordfile
    FILOPN()
    rtncd = Ref(Int32(0)); fvsGetRtnCode(rtncd)
    irtncd_ref[] = rtncd[]
    return nothing
end

function fvsGetStoppointCodes(spptcd_ref::Ref{Int32}, spptyr_ref::Ref{Int32})
    spptcd_ref[] = minorstopptcode
    spptyr_ref[] = minorstopptyear
    return nothing
end

function fvsSetStoppointCodes(spptcd::Integer, spptyr::Integer)
    global minorstopptcode = Int32(spptcd)
    global minorstopptyear = Int32(spptyr)
    return nothing
end

function fvsGetRestartCode(restrtcd_ref::Ref{Int32})
    restrtcd_ref[] = fvsRtnCode == 0 ? restartcode : Int32(0)
    return nothing
end

function clearrestartcode()
    global restartcode = Int32(0)
    return nothing
end

function fvsRestart(restrtcd_ref::Ref{Int32})
    if fvsRtnCode != 0
        global restartcode = Int32(-1)
        restrtcd_ref[] = restartcode
        return nothing
    end

    if stopstatcd == 0
        global restartcode = Int32(0)
    elseif stopstatcd == 1 || stopstatcd == 2
        if jdstash != -1
            global readFilePos = Int32(position(io_units[Int32(jdstash)]))
            global seekReadPos = readFilePos
            getstd()
            global restartcode = Int32(-originalRestartCode)
            global stopstatcd  = Int32(4)
        else
            global stopstatcd  = Int32(0)
            global restartcode = Int32(0)
        end
    elseif stopstatcd == 3
        global stopstatcd = Int32(0)
    elseif stopstatcd == 4
        global stopstatcd  = Int32(0)
        global restartcode = originalRestartCode
    end
    restrtcd_ref[] = restartcode
    return nothing
end

function fvsRestartLastStand(restrtcd_ref::Ref{Int32})
    if readFilePos == -1
        fvsSetRtnCode(Int32(1))
    else
        global seekReadPos = readFilePos
        getstd()
        global restartcode = Int32(-1)
        global stopstatcd  = Int32(4)
    end
    restrtcd_ref[] = fvsRtnCode
    return nothing
end

function fvsGetKeywordFileName(fn_ref::Ref{String}, mxch::Integer, nch_ref::Ref{Int32})
    if nch_ref[] == 251
        global keywordfile = fn_ref[]
        return nothing
    end
    fn_ref[] = " "
    if mxch < 1; return nothing; end
    n = min(mxch, length(keywordfile))
    if n > 0
        fn_ref[] = keywordfile[1:n]
    end
    nch_ref[] = Int32(n)
    return nothing
end

function fvsSetRtnCode(rtnCode::Integer)
    global fvsRtnCode = Int32(rtnCode)
    if fvsRtnCode != 0
        FILClose()
    end
    return nothing
end

function fvsGetRtnCode(rtnCode_ref::Ref{Int32})
    rtnCode_ref[] = fvsRtnCode
    return nothing
end

function fvsGetRtnCode()::Int32
    return fvsRtnCode
end

function fvsStopPoint(locode::Integer, istopdone_ref::Ref{Int32})
    istopdone_ref[] = Int32(0)
    global stopstatcd = Int32(0)

    if locode == -1
        global restartcode = Int32(100)
        global stopstatcd  = Int32(2)
        istopdone_ref[] = Int32(1)
        return nothing
    end
    if locode == 0; return nothing; end

    if majorstopptyear != 0 && majorstopptcode != 0
        if majorstopptcode > 0 && majorstopptcode != locode
            @goto label_100
        end
        icy = Int(ICYC)
        if majorstopptyear > 0 &&
           (majorstopptyear < IY[icy] || majorstopptyear >= IY[icy+1])
            @goto label_100
        end
        tmpyr = majorstopptyear > 0 ? majorstopptyear : IY[icy]

        if jstash != -1
            if firstWrite == 1
                io_s = io_units[Int32(jstash)]
                nch  = length(keywordfile)
                write(io_s, Int32(locode), Int32(tmpyr), Int32(nch))
                write(io_s, Vector{UInt8}(keywordfile))
                flush(io_s)
                global firstWrite = Int32(0)
            end
            putstd()
        end

        global stopstatcd  = Int32(1)
        global restartcode = Int32(locode)
        istopdone_ref[]    = Int32(1)
        return nothing
    end

    @label label_100
    if minorstopptcode == 0; return nothing; end
    if minorstopptcode > 0 && minorstopptcode != locode; return nothing; end
    icy = Int(ICYC)
    if minorstopptyear > 0 &&
       (minorstopptyear < IY[icy] || minorstopptyear >= IY[icy+1])
        return nothing
    end
    global stopstatcd  = Int32(3)
    global restartcode = Int32(locode)
    istopdone_ref[] = Int32(1)
    return nothing
end

function getAmStopping(istopdone_ref::Ref{Int32})
    istopdone_ref[] = stopstatcd > 0 ? Int32(1) : Int32(0)
    return nothing
end
