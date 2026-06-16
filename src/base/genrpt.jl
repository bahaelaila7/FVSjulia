# genrpt.jl — GENRPT / GETID / GETLUN / GENPRT / GETNRPTS / SETNRPTS
# Translated from: genrpt.f (110 lines)
#
# Multiple-report scratch file mechanism: each extension writes its output
# to a shared scratch file tagged by report ID, then GENPRT replays them
# all in order to the main output unit.
#
# COMMON /GENRCM/ state → module-level globals (declared in glblcntl.jl
# if present, or here as Refs).

const _GENRCM_JOSCRT = Ref(Int32(93))
const _GENRCM_NRPTS  = Ref(Int32(0))
const _GENRCM_IFOPN  = Ref(Int32(0))

function GENRPT()
    joscrt = Int(_GENRCM_JOSCRT[])
    if haskey(io_units, Int32(joscrt))
        try; close(io_units[Int32(joscrt)]); catch; end
        delete!(io_units, Int32(joscrt))
    end
    _GENRCM_NRPTS[] = Int32(0)
    _GENRCM_IFOPN[] = Int32(0)
    return nothing
end

function GETID(ifid_ref::Ref{Int32})
    joscrt = Int32(_GENRCM_JOSCRT[])
    if _GENRCM_IFOPN[] == 0
        fname = strip(KWDFIL) * "_genrpt.txt"
        try
            io_units[joscrt] = open(fname, "a")
            _GENRCM_IFOPN[] = Int32(1)
        catch e
            ERRGRO(true, Int32(26))
            ifid_ref[] = Int32(-1)
            return nothing
        end
    end
    _GENRCM_NRPTS[] += Int32(1)
    ifid_ref[] = _GENRCM_NRPTS[]
    return nothing
end

function GETLUN(jrout_ref::Ref{Int32})
    joscrt = Int32(_GENRCM_JOSCRT[])
    if _GENRCM_IFOPN[] == 0
        fname = strip(KWDFIL) * "_genrpt.txt"
        try
            io_units[joscrt] = open(fname, "a")
            _GENRCM_IFOPN[] = Int32(1)
        catch e
            ERRGRO(true, Int32(26))
            jrout_ref[] = Int32(-1)
            return nothing
        end
    end
    jrout_ref[] = _GENRCM_JOSCRT[]
    return nothing
end

function GENPRT()
    if _GENRCM_IFOPN[] == 0 || _GENRCM_NRPTS[] == 0; return nothing; end

    joscrt = Int32(_GENRCM_JOSCRT[])
    io_s = get(io_units, joscrt, nothing)
    if isnothing(io_s); return nothing; end

    # Flush / end-of-file the scratch file
    flush(io_s)
    close(io_s)

    nrpts = Int(_GENRCM_NRPTS[])
    fname = strip(KWDFIL) * "_genrpt.txt"

    io_out = get(io_units, Int32(JOSTND), stdout)

    # Read scratch file, replay each report in order
    for id in 1:nrpts
        try
            io_r = open(fname, "r")
            in_section = false
            for line in eachline(io_r)
                if length(line) >= 6
                    tag = line[1:6]
                    # Section separator: " %5d " style header
                    m = match(r"^ *(\d+) ", line)
                    if !isnothing(m)
                        ir = parse(Int, m.captures[1])
                        rest = line[length(m.match)+1:end]
                        if rest == "\$#*%" || startswith(rest, "\$#*%")
                            in_section = (ir == id)
                            continue
                        end
                        if ir == id
                            println(io_out, rest)
                        end
                        continue
                    end
                end
                if in_section
                    println(io_out, line)
                end
            end
            close(io_r)
        catch
            break
        end
    end

    try; rm(fname); catch; end
    delete!(io_units, joscrt)
    _GENRCM_IFOPN[] = Int32(0)
    _GENRCM_NRPTS[] = Int32(0)
    return nothing
end

function GETNRPTS(ifid_ref::Ref{Int32})
    ifid_ref[] = _GENRCM_NRPTS[]
    return nothing
end

function SETNRPTS(ifid::Integer)
    _GENRCM_NRPTS[] = Int32(ifid)
    return nothing
end
