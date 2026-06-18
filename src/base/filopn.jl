# filopn.f — File open/close routines
# Translated from: base/filopn.f (311 lines)
#
# FILOPN: open keyword, tree-data, output files.
# FILClose (ENTRY): close all open FVS files.
# openIfClosed: open a unit with a suffix if not already connected.

"""
    FILOPN()

Open the FVS keyword (.key), tree-data (.tre), and all output files.
If a keyword file was set via fvsGetKeywordFileName (non-interactive mode),
opens files automatically using base name derived from keyword file path.
Otherwise prompts stdin for file names.
"""
function FILOPN()
    # Get keyword file name from API
    global KWDFIL
    kwdfil_api = strip(KWDFIL)

    if !isempty(kwdfil_api) && kwdfil_api != " "
        # Non-interactive: keyword file already specified
        # Close unit IREAD if open
        if haskey(io_units, IREAD)
            close(io_units[IREAD])
            delete!(io_units, IREAD)
        end

        # Open keyword file (skip on restart)
        restart_code = fvsGetRestartCode()
        if restart_code == Int32(0)
            try
                io_units[IREAD] = open(kwdfil_api, "r")
            catch e
                println("File open error on: $(kwdfil_api)")
                fvsSetRtnCode(Int32(1))
                return nothing
            end
        end

        # Derive base name (strip .key/.KEY extension if present)
        lenkey = findfirst(".k", kwdfil_api)
        if lenkey === nothing
            lenkey = findfirst(".K", kwdfil_api)
        end
        if lenkey !== nothing
            kwdfil_api = kwdfil_api[1:first(lenkey)-1]
        end
        global KWDFIL = kwdfil_api
        lenkey2 = length(rstrip(kwdfil_api))
        base = kwdfil_api[1:lenkey2]

        # Open main output file (.out) — don't close if it's still stdout
        if haskey(io_units, JOSTND)
            prev = io_units[JOSTND]
            if prev !== stdout && prev !== stderr
                try close(prev) catch; end
            end
            delete!(io_units, JOSTND)
        end
        cname = base * ".out"
        try
            if restart_code == Int32(0)
                io_units[JOSTND] = open(cname, "w")
            else
                io_units[JOSTND] = open(cname, "a")
            end
        catch e
            println("File open error on: $(cname)")
            fvsSetRtnCode(Int32(1))
            return nothing
        end

        # Clear pre-existing tree list / stand data files if NOT a restart
        if restart_code == Int32(0)
            for (unit, suffix) in [(JOLIST, ".trl"), (KOLIST, ".fst"), (JOLIST, ".sng")]
                if !haskey(io_units, unit)
                    fpath = base * suffix
                    try
                        f = open(fpath, "w"); close(f)   # create/truncate, then delete
                        rm(fpath, force=true)
                    catch; end
                end
            end
        end

        # Open summary file (.sum) — primary output that test diffs against
        if !haskey(io_units, JOSUM)
            sumname = base * ".sum"
            try
                io_units[JOSUM] = restart_code == Int32(0) ? open(sumname, "w") : open(sumname, "a")
            catch e
                println("File open error on: $(sumname)")
            end
        end

        # Open cheapo/calibstat file (.chp) — written by some keyword handlers
        if !haskey(io_units, JOSUME)
            chpname = base * ".chp"
            try
                io_units[JOSUME] = restart_code == Int32(0) ? open(chpname, "w") : open(chpname, "a")
            catch e; end
        end

        KEYFN(kwdfil_api)
        DBSVKFN(kwdfil_api)

        # Scratch file for sample trees (unformatted in Fortran → tempname in Julia)
        io_units[JOTREE] = IOBuffer()

        return nothing
    end

    # Interactive mode: prompt for file names
    CALL_REVISE_prompt()

    print("  ENTER KEYWORD FILE NAME ($(lpad(IREAD, 2, '0'))): ")
    kwdfil_api = readline()
    kwdfil_api, lenkey = UNBLNK(kwdfil_api)
    if lenkey <= 0
        println("  A KEYWORD FILE NAME IS REQUIRED")
        RCDSET(Int32(3), false)
        irtncd = fvsGetRtnCode()
        if irtncd != 0; return nothing; end
        return nothing
    end

    kode = MYOPEN(IREAD, kwdfil_api, Int32(3), Int32(150), Int32(0), Int32(1), Int32(1), Int32(0))
    if kode > 0
        println("  OPEN FAILED FOR $(rstrip(kwdfil_api))")
        println("  A KEYWORD FILE IS REQUIRED")
        RCDSET(Int32(3), false)
        irtncd = fvsGetRtnCode()
        if irtncd != 0; return nothing; end
        return nothing
    end

    DBSVKFN(kwdfil_api)
    KEYFN(kwdfil_api)
    fvsGetKeywordFileName_store(kwdfil_api)

    # Strip extension from keyword file name
    for i in length(rstrip(kwdfil_api)):-1:1
        if kwdfil_api[i] == '.'
            global KWDFIL = kwdfil_api[1:i-1] * repeat(' ', length(kwdfil_api)-(i-1))
            break
        end
    end

    # Tree data file
    print("  ENTER TREE DATA FILE NAME ($(lpad(ISTDAT, 2, '0'))): ")
    cname = readline()
    cname, lennam = UNBLNK(cname)
    if lennam > 0
        kode = MYOPEN(ISTDAT, cname, Int32(1), Int32(150), Int32(0), Int32(1), Int32(1), Int32(0))
        if kode > 0
            println("  OPEN FAILED FOR $(rstrip(cname))")
        end
    end

    # Main output file
    print("  ENTER MAIN OUTPUT FILE NAME ($(lpad(JOSTND, 2, '0'))): ")
    cname = readline()
    cname, lennam = UNBLNK(cname)
    if lennam <= 0
        cname = rstrip(KWDFIL) * ".out"
    end
    kode = MYOPEN(JOSTND, cname, Int32(5), Int32(133), Int32(0), Int32(1), Int32(1), Int32(1))
    if kode > 0
        println("  OPEN FAILED FOR $(rstrip(cname))")
        println("  ALL OUTPUT IS SENT TO STANDARD OUT")
        global JOSTND = Int32(6)
    end

    # Tree list output file
    print("  ENTER TREELIST OUTPUT FILE NAME ($(lpad(JOLIST, 2, '0'))):  ")
    cname = readline()
    cname, lennam = UNBLNK(cname)
    if lennam <= 0
        cname = rstrip(KWDFIL) * ".trl"
    end
    cname, lennam = UNBLNK(cname)
    kode = MYOPEN(JOLIST, cname, Int32(5), Int32(133), Int32(0), Int32(1), Int32(1), Int32(1))
    if kode > 0
        println("  OPEN FAILED FOR $(rstrip(cname))")
    end

    # Summary output file
    print("  ENTER SUMMARY OUTPUT FILE NAME ($(lpad(JOSUM, 2, '0'))): ")
    cname = readline()
    cname, lennam = UNBLNK(cname)
    if lennam <= 0
        cname = rstrip(KWDFIL) * ".sum"
    end
    cname, lennam = UNBLNK(cname)
    kode = MYOPEN(JOSUM, cname, Int32(5), Int32(133), Int32(0), Int32(1), Int32(1), Int32(0))
    if kode > 0
        println("  OPEN FAILED FOR $(rstrip(cname))")
    end

    # CHEAPOII / CALBSTAT auxiliary file
    print("  ENTER CHEAPOII/CALBSTAT OUTPUT FILE NAME ($(lpad(JOSUME, 2, '0'))): ")
    cname = readline()
    cname, lennam = UNBLNK(cname)
    if lennam <= 0
        cname = rstrip(KWDFIL) * ".chp"
    end
    kode = MYOPEN(JOSUME, cname, Int32(5), Int32(91), Int32(0), Int32(1), Int32(1), Int32(0))
    if kode > 0
        println("  OPEN FAILED FOR $(rstrip(cname))")
    end

    # FFE Snag output file (open then delete to clear it)
    cname = rstrip(KWDFIL) * ".sng"
    kode = MYOPEN(JSNOUT, cname, Int32(5), Int32(91), Int32(0), Int32(1), Int32(1), Int32(0))
    if kode > 0
        println("  OPEN FAILED FOR $(rstrip(cname))")
    else
        if haskey(io_units, JSNOUT)
            close(io_units[JSNOUT])
            delete!(io_units, JSNOUT)
            rm(cname, force=true)
        end
    end

    # Sample tree scratch file (temporary)
    io_units[JOTREE] = IOBuffer()

    return nothing
end

"""
    FILClose()

Close all open FVS IO units. Equivalent to the Fortran ENTRY FILClose.
"""
function FILClose()
    DBSCLOSE(true, true)

    for unit in [IREAD, ISTDAT, JOTREE, JOSUM, JOLIST, JOSUME]
        if haskey(io_units, unit)
            try close(io_units[unit]) catch; end
            delete!(io_units, unit)
        end
    end

    # Close JOSTND only if it is not stdout (unit 6)
    if JOSTND != Int32(6) && haskey(io_units, JOSTND)
        try close(io_units[JOSTND]) catch; end
        delete!(io_units, JOSTND)
    end

    if JSVOUT > Int32(0) && haskey(io_units, JSVOUT)
        try close(io_units[JSVOUT]) catch; end
        delete!(io_units, JSVOUT)
    end

    return nothing
end

"""
    openIfClosed(ifileref, sufx) → Bool

Open IO unit `ifileref` appending suffix `sufx` to the keyword file base name,
but only if it is not already open. Returns true on success, false on failure.
"""
function openIfClosed(ifileref::Int32, sufx::AbstractString)::Bool
    if haskey(io_units, ifileref)
        return true   # already connected
    end

    keywrdfn = strip(KWDFIL)
    if isempty(keywrdfn)
        return true
    end

    # Strip existing extension from keyword filename
    i = findlast(".k", keywrdfn)
    if i === nothing; i = findlast(".K", keywrdfn); end
    if i === nothing
        i = length(rstrip(keywrdfn))
        path = rstrip(keywrdfn) * "." * strip(sufx)
    else
        path = keywrdfn[1:first(i)-1] * "." * strip(sufx)
    end

    try
        io_units[ifileref] = open(path, "a")
        return true
    catch
        return false
    end
end

# ---------------------------------------------------------------------------
# MYOPEN helper — translates the 8-argument Fortran MYOPEN to Julia open()
# kode: integer mode selector used by Fortran; here we only need read vs write.
# Returns 0 on success, 1 on error.
# ---------------------------------------------------------------------------
"""
    MYOPEN(unit, fname, mode, reclen, share, ifound, icre, iapl) → Int32

Open a file on `unit` with the given parameters. Maps Fortran MYOPEN semantics:
- mode 1-3: read  (existing file)
- mode 4:   scratch (temp)
- mode 5:   write/append
Returns 0 on success, >0 on error.
"""
function MYOPEN(unit::Int32, fname::AbstractString, mode::Int32,
                reclen::Int32, share::Int32, ifound::Int32,
                icre::Int32, iapl::Int32)::Int32
    fname_stripped = strip(fname)
    try
        if mode == Int32(4)
            # Scratch (unformatted scratch in Fortran → IOBuffer in Julia)
            io_units[unit] = IOBuffer()
        elseif mode <= Int32(3)
            # Read existing
            io_units[unit] = open(fname_stripped, "r")
        else
            # Write or append
            if iapl == Int32(1)
                io_units[unit] = open(fname_stripped, "a")
            else
                io_units[unit] = open(fname_stripped, "w")
            end
        end
        return Int32(0)
    catch
        return Int32(1)
    end
end

# Stubs for API calls not yet implemented (will be filled by main entry point)
fvsGetRestartCode()  = Int32(0)
# fvsGetRtnCode/fvsSetRtnCode → base/cmdline.jl
# KEYFN — real impl in keywd.jl (included after filopn.jl)
DBSVKFN(fn)          = nothing
# DBSCLOSE → implemented in extensions/dbs/dbsqlite.jl (included after filopn.jl)
CALL_REVISE_prompt() = nothing
fvsGetKeywordFileName_store(fn) = nothing
