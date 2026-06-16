# gheads.jl — GHEADS / FIAHEAD / VOLEQHEAD: print table headings
# Translated from: gheads.f (146 lines)

function GHEADS(nplt::AbstractString, mgmid::AbstractString,
                kostnd::Integer, kotree::Integer, ititle::AbstractString)
    _dash122 = repeat("-", 122)
    _dash126 = repeat("-", 126)

    if kostnd != 0
        io_s = get(io_units, Int32(kostnd), stdout)
        GROHED(Int32(kostnd))
        title_trimmed = rstrip(ititle)
        @printf(io_s, "\nSTAND ID: %-26s    MGMT ID: %-4s    %s\n\n", nplt, mgmid, title_trimmed)

        if VARACD ∈ ("CS","LS","NE")
            @printf(io_s, "\n%41sSTAND COMPOSITION (BASED ON STOCKABLE AREA)\n%s\n%29sPERCENTILE POINTS IN THE\n",
                "", _dash122, "")
            @printf(io_s, "%22sDISTRIBUTION OF STAND ATTRIBUTES BY DBH      TOTAL/ACRE\n", "")
            @printf(io_s, "%9sSTAND       %41s      OF STAND         DISTRIBUTION OF STAND ATTRIBUTES BY\n", "","")
            @printf(io_s, "YEAR  ATTRIBUTES      10     30     50     70     90    100       ATTRIBUTES       SPECIES AND 3 USER-DEFINED SUBCLASSES\n")
            @printf(io_s, "----  -----------  %s  %s  %s\n%34s(DBH IN INCHES)\n",
                repeat(repeat("-",6)*" ", 6), repeat("-",14), repeat("-",42), "")
        else
            @printf(io_s, "\n%41sSTAND COMPOSITION (BASED ON STOCKABLE AREA)\n%s\n%29sPERCENTILE POINTS IN THE\n",
                "", _dash122, "")
            @printf(io_s, "%22sDISTRIBUTION OF STAND ATTRIBUTES BY DBH      TOTAL/ACRE\n", "")
            @printf(io_s, "%9sSTAND       %41s      OF STAND         DISTRIBUTION OF STAND ATTRIBUTES BY\n", "","")
            @printf(io_s, "YEAR  ATTRIBUTES      10     30     50     70     90    100       ATTRIBUTES       SPECIES AND 3 USER-DEFINED SUBCLASSES\n")
            @printf(io_s, "----  -----------  %s  %s  %s\n%34s(DBH IN INCHES)\n",
                repeat(repeat("-",6)*" ", 6), repeat("-",14), repeat("-",42), "")
        end
    end

    if kotree != 0
        io_t = get(io_units, Int32(kotree), stdout)
        GROHED(Int32(kotree))
        title_trimmed = rstrip(ititle)
        @printf(io_t, "\nSTAND ID: %-26s    MGMT ID: %-4s    %s\n\n", nplt, mgmid, title_trimmed)

        @printf(io_t, "\n%s\n", _dash126)
        @printf(io_t, "%22sATTRIBUTES OF SELECTED SAMPLE TREES                 ADDITIONAL STAND ATTRIBUTES (BASED ON STOCKABLE AREA)\n", "")
        @printf(io_t, "%6s%s  %s\n", "", repeat("-",65), repeat("-",53))

        if VARACD ∈ ("CS","LS","NE")
            @printf(io_t, "%6sINITIAL%27sLIVE   PAST DBH  BASAL   TREES%10sQUADRATIC   TREES%4sBASAL  TOP HEIGHT\n", "","","","")
            @printf(io_t, "%6sTREES/A%12sDBH    HEIGHT  CROWN   GROWTH   AREA     PER    STAND   MEAN DBH    PER%5sAREA     LARGEST\n", "","","")
            @printf(io_t, "YEAR   %%TILE  SPECIES (INCHES)  (FEET)  RATIO  (INCHES)  %%TILE    ACRE   AGE     (INCHES)%4sACRE   (SQFT/A) 40/A (FT)\n", "")
        else
            @printf(io_t, "%6sINITIAL%27sLIVE   PAST DBH  BASAL   TREES%10sQUADRATIC   TREES%4sBASAL  TOP HEIGHT  CROWN\n", "","","","")
            @printf(io_t, "%6sTREES/A%12sDBH    HEIGHT  CROWN   GROWTH   AREA     PER    STAND   MEAN DBH    PER%5sAREA     LARGEST   COMP\n", "","","")
            @printf(io_t, "YEAR   %%TILE  SPECIES (INCHES)  (FEET)  RATIO  (INCHES)  %%TILE    ACRE   AGE     (INCHES)%4sACRE   (SQFT/A) 40/A (FT)  FACTOR\n", "")
        end
        @printf(io_t, "----  %s  %s  %s  %s  %s  %s  %s  %s  %s  %s  %s  %s  %s  %s\n",
            repeat("-",7), repeat("-",7), repeat("-",8), repeat("-",8),
            repeat("-",6), repeat("-",9), repeat("-",7), repeat("-",6),
            repeat("-",5), repeat("-",9), repeat("-",6), repeat("-",9),
            repeat("-",9), repeat("-",7))
    end

    return nothing
end

function FIAHEAD(kostnd::Integer)
    io_s = get(io_units, Int32(kostnd), stdout)
    @printf(io_s, "\n%12sALPHA SPECIES - FIA CODE CROSS REFERENCE:\n", "")
    return nothing
end

function VOLEQHEAD(kostnd::Integer)
    io_s = get(io_units, Int32(kostnd), stdout)
    @printf(io_s, "\n%35sNATIONAL VOLUME ESTIMATOR LIBRARY EQUATION NUMBERS\n", "")
    hdr = "SPECIES  CUBIC FOOT BOARD FOOT "
    @printf(io_s, "%s%s%s%s\n", hdr, hdr, hdr, hdr)
    dash = "------- ----------- ---------- "
    @printf(io_s, "%s%s%s%s\n", dash, dash, dash, dash)
    return nothing
end
