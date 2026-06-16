# isstag.jl — ISSTAG/RQSSTG: initialize stand structural stage classification
# Translated from: isstag.f (53 lines)
# Also: KSSTAG: process STRCLASS keyword

function ISSTAG()
    global ISTRCL = Int32(0)
    global LCALC  = false
    global LPRNT  = true
    global SSDBH  = Float32(5)
    global SAWDBH = Float32(25)
    global GAPPCT = Float32(30)
    global PCTSMX = Float32(30)
    global CCMIN  = Float32(5)
    global TPAMIN = Float32(200)
    global IRREF  = Int32(-1)
    for i in 1:33, j in 1:2
        OSTRST[i, j] = Int32(0)
    end
    return nothing
end

function RQSSTG(lon::Bool, lprt::Bool)
    global LCALC = lon
    global LPRNT = lprt
    return nothing
end

function KSSTAG(iprint::Integer, keywrd::AbstractString,
                lnotbk::AbstractVector{Bool}, array::AbstractVector{Float32},
                lkecho::Bool)
    io = io_units[Int32(iprint)]
    global LCALC = true

    if lnotbk[1]
        if array[1] == Float32(0)
            global LPRNT = false
        else
            global LPRNT = true
        end
    end
    array[1] = LPRNT ? Float32(1) : Float32(0)

    if lnotbk[2]; global GAPPCT = array[2]; end
    if lnotbk[3]; global SSDBH  = array[3]; end
    if lnotbk[4]; global SAWDBH = array[4]; end
    if lnotbk[5]; global CCMIN  = array[5]; end
    if lnotbk[6]; global TPAMIN = array[6]; end
    if lnotbk[7]; global PCTSMX = array[7]; end

    if lkecho
        @printf(io, "\n%-8s   STAND STRUCTURAL CLASSES WILL BE COMPUTED.\n", keywrd)
        @printf(io, "            OUTPUT PRINTING CODE = %3.0f (0=NO OUTPUT, 1=PRINT)\n", array[1])
        @printf(io, "            THE PERCENTAGE OF A TREE HEIGHT THAT A GAP MUST EXCEED =%6.1f\n", GAPPCT)
        @printf(io, "            THE DBH BREAK BETWEEN SEEDLING/SAPLINGS AND POLE-SIZED TREES =%6.1f\n", SSDBH)
        @printf(io, "            THE DBH BREAK BETWEEN POLE-SIZED AND LARGE, OLDER, TREES =%6.1f\n", SAWDBH)
        @printf(io, "            THE MINIMUM COVER PERCENT TO QUALIFY A POTENTIAL STRATUM =%6.1f\n", CCMIN)
        @printf(io, "            THE MINIMUM TREE/ACRE TO BE CLASSIFIED STAND INITIATION =%6.1f\n", TPAMIN)
        @printf(io, "            THE MINIMUM PERCENT OF MAXSDI TO BE CLASSIFIED STEM EXCLUSION =%6.1f\n", PCTSMX)
    end
    return nothing
end
