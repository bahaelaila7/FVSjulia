# svkey.f — SVKEY: process SVS (Stand Visualization System) keyword (109 lines)
# Sets global SVS display parameters and opens the index output file.

function SVKEY(keywrd::AbstractString, lnotbk::AbstractVector{Bool},
               array::AbstractVector{Float32})
    io = io_units[Int32(JOSTND)]

    if lnotbk[1]
        global IPLGEM = Int32(floor(array[1]))
    end
    if IPLGEM < Int32(0) || IPLGEM > Int32(3); global IPLGEM = Int32(1); end

    if lnotbk[2]
        global IGRID = Int32(floor(array[2]))
    end
    if IGRID > Int32(256); global IGRID = Int32(256); end
    if IGRID < Int32(0);   global IGRID = Int32(0);   end

    if lnotbk[7]; global JSVOUT = Int32(-1); end

    if lnotbk[5]
        global ICOLIDX = Int32(floor(array[5]))
    end
    if ICOLIDX > Int32(20); global ICOLIDX = Int32(20); end

    @printf(io, "\n%-8s   PRODUCE SVS-READY DATA\n%12sPLOT GEOMETRY CODE = %2d (0=SQUARE, IGNORE POINTS; 1=SUBDIVIDED SQUARE; 2=ROUND, IGNORE POINTS; 3=SUBDIVIDED CIRCLE)\n%12sGROUND FILE GRID RESOLUTION (ZERO IMPLIES NO GROUND FILE)= %3d\n",
            keywrd, "", Int(IPLGEM), "", Int(IGRID))

    global IRPOLES = Int32(floor(array[3]))
    if IRPOLES > Int32(1); global IRPOLES = Int32(1); end
    if IRPOLES < Int32(0); global IRPOLES = Int32(0); end

    global IDPLOTS = Int32(floor(array[4]))
    if IDPLOTS > Int32(1); global IDPLOTS = Int32(1); end
    if IDPLOTS < Int32(0); global IDPLOTS = Int32(0); end

    global IMETRIC = Int32(floor(array[6]))
    if IMETRIC > Int32(1); global IMETRIC = Int32(1); end
    if IMETRIC < Int32(0); global IMETRIC = Int32(0); end

    if IRPOLES == Int32(0)
        @printf(io, "%12sRANGE POLES ARE NOT DRAWN.\n", "")
    else
        @printf(io, "%12sRANGE POLES ARE DRAWN.\n", "")
    end
    if IDPLOTS == Int32(0)
        @printf(io, "%12sSUBPLOT BOUNDARIES ARE NOT DRAWN.\n", "")
    else
        @printf(io, "%12sSUBPLOT BOUNDARIES ARE DRAWN.\n", "")
    end
    if IMETRIC == Int32(0)
        @printf(io, "%12sOUTPUT DATA ARE IMPERIAL.\n", "")
    else
        @printf(io, "%12sOUTPUT DATA ARE METRIC.\n", "")
    end
    @printf(io, "%12sCOLOR INDEX= %4d\n", "", Int(ICOLIDX))

    if lnotbk[7]; global JSVOUT = Int32(-1); end

    if JSVOUT < Int32(0)
        @printf(io, "%12sSVS RUNS BUT NO OUTPUT FILES ARE PRODUCED.\n", "")
        return nothing
    end

    global JSVOUT = Int32(90)
    suffix = "_index.svs"
    fname  = rstrip(KWDFIL) * suffix
    if haskey(io_units, JSVOUT)
        try; close(io_units[JSVOUT]); catch; end
    end
    try
        io_units[JSVOUT] = open(fname, "w")
        println(io_units[JSVOUT], "#TREELISTINDEX")
    catch
        @printf(io, "\n%12s**** FILE OPEN ERROR FOR FILE: %s\n", "", fname)
        RCDSET(Int32(2), true)
        global JSVOUT = Int32(0)
    end
    return nothing
end
