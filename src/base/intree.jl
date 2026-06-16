# intree.f — Stand tree data reader
# Translated from: base/intree.f (661 lines)
#
# Reads the .tre file (or DBS database) and populates all per-tree arrays.
# Dead trees (ITH 6-9) are stored in the bottom of the arrays (IREC2..MAXTP1).
# Live trees are stored in the top half (1..IREC1).

# COMMON /INTREECOM/ CSPI — shared with SPCTRN and other species routines
CSPI_INTREE::String = "        "   # 8-char species code scratch (replaces COMMON /INTREECOM/)

# Module-level constant (Fortran DATA IDCMP1/10000000/)
const IDCMP1_INTREE = Int32(10000000)

"""
    INTREE(record, irdplv, isdsp, sdlo, sdhi, lkecho)

Read stand tree data records from `.tre` file or DBS database.
Populates all per-tree arrays (DBH, HT, ISP, PROB, ...) and site-tree tables.

Arguments:
- `record`  : current keyword file record (path hint for .tre file)
- `irdplv`  : 0 = no plot-specific site vars; 1 = plot site vars present
- `isdsp`   : species/DBH screen species code (0=no screen)
- `sdlo`    : lower DBH screen limit
- `sdhi`    : upper DBH screen limit
- `lkecho`  : true = echo keyword listing
"""
function INTREE(record::String, irdplv::Int32, isdsp::Int32,
                sdlo::Float32, sdhi::Float32, lkecho::Bool)
    global CSPI_INTREE, IRECRD, IREC2, LSTKNT, NSTKNT, IOSTAT_INTREE
    global IREC1, NSITET, JSPINDEF, MORDAT

    debug_mode = DBCHK("INTREE", Int32(6))

    if debug_mode
        t1 = TREFMT[1:80]
        t2 = TREFMT[81:min(160, length(TREFMT))]
        @printf(io_units[JOSTND],
            "\n ENTERING SUBROUTINE INTREE.\n DATA SET REFERENCE NUMBER =%2d\n TREE DATA FORMAT:\n%30s%s\n%30s%s\n MORDAT: %s; IRDPLV=%3d\n",
            ISTDAT, "", t1, "", t2, MORDAT ? "T" : "F", irdplv)
    end

    # Initialize species-not-found tracking
    inospc = 0
    anospc = fill("        ", 1000)

    lconn = false   # true once we've confirmed ISTDAT is open

    # On a fresh stand (not MORDAT continuation): reset pointers
    if !MORDAT
        global IRECRD = Int32(0)
        global IREC2  = MAXTP1
        imax          = MAXTP1
        global LSTKNT = Int32(1)
        global NSTKNT = Int32(0)
        # Initialize damage/severity to zero
        fill!(DAMSEV, Int32(0))
    end

    iptknt = Int32(0)
    if LSTKNT > Int32(1); iptknt = LSTKNT - Int32(1); end
    iscrn  = Int32(0)

    ipvars = zeros(Int32, 5)

    # Upper limit on IPVARS values read per record
    npnvrs = (irdplv > Int32(0)) ? Int32(5) : Int32(1)

    # Check if Western Root Disease model is active
    lrdgo = false; lrdte = false
    RDATV(lrdgo, lrdte)
    if lrdgo && lrdte
        itrrr, itp1rr = RDTRES()
        imax = itp1rr
    else
        imax = MAXTP1
    end

    # -----------------------------------------------------------------------
    # Main record-read loop
    # -----------------------------------------------------------------------
    @label label_10
    # Check for array space
    if IREC1 + Int32(1) < min(IREC2, imax)
        @goto label_30
    end
    @label label_15
    global LSTKNT = iptknt

    if lrdgo && lrdte
        @printf(io_units[JOSTND],
            "**** MAX NUMBER OF TREE RECORDS%5d EXCEEDED FOR WESTERN ROOT DISEASE MODEL VER 3.0 ****\n",
            itrrr)
    end

    ERRGRO(false, Int32(13))
    irtncd = fvsGetRtnCode()
    if irtncd != 0; @goto label_900; end

    @label label_30
    i = IREC1 + Int32(1)

    # -----------------------------------------------------------------------
    # Attempt to read from DBS (database) first
    # -----------------------------------------------------------------------
    @label label_31
    dbskode = Int32(1)
    itrei = Int32(0)
    ith   = Int32(0)
    tht   = Float32(0.0)
    imc1  = Int32(0)
    idamcd = zeros(Int32, 6)

    DBSTREESIN(i, itrei, ith, CSPI_INTREE,
               idamcd, imc1, ipvars, dbskode, debug_mode,
               lkecho, lrdgo, lrdte)

    # Fix decay code consistency
    if ith > Int32(5) && (DECAYCD[i] < Int32(1) || DECAYCD[i] > Int32(5))
        DECAYCD[i] = Int32(3)
    elseif ith <= Int32(5) && DECAYCD[i] != Int32(0)
        DECAYCD[i] = Int32(0)
    end

    if dbskode == Int32(0)
        # DBS returned nothing; try reading from ISTDAT text file
        if !lconn
            lconn = haskey(io_units, ISTDAT)
        end
        if !lconn
            # Try to auto-discover the .tre file next to the keyword file
            kwdfn = strip(KWDFIL)
            if isempty(kwdfn)
                @goto label_900
            end
            ii = findfirst(".k", lowercase(kwdfn))
            if ii !== nothing
                kwdfn = kwdfn[1:first(ii)-1]
            else
                kwdfn = rstrip(kwdfn)
            end
            # Try .TRE then .tre
            for ext in [".TRE", ".tre"]
                fpath = kwdfn * ext
                if isfile(fpath)
                    io_units[ISTDAT] = open(fpath, "r")
                    lconn = true
                    break
                end
            end
            if !lconn
                @goto label_900
            end
        end

        # Read one text record
        local line
        try
            line = readline(io_units[ISTDAT])
        catch
            @goto label_900
        end
        if isempty(line)
            @goto label_900
        end
        if startswith(line, '*')
            @goto label_31
        end
        if occursin("-999", line)
            @goto label_900
        end

        # Parse the tree record using TREFMT pattern
        fields = parse_tree_record(line)
        if fields === nothing
            @goto label_900
        end

        (itrei, IDTREE[i], PROB[i], ith, CSPI_INTREE,
         DBH[i], DG[i], HT[i], tht, HTG[i], ICR[i],
         idamcd[1], idamcd[2], idamcd[3], idamcd[4], idamcd[5], idamcd[6],
         imc1, KUTKOD[i],
         ipvars[1], ipvars[2], ipvars[3], ipvars[4], ipvars[5],
         ABIRTH[i]) = fields

        if ABIRTH[i] <= Float32(0.0)
            ABIRTH[i] = Float32(0.0)
            LBIRTH[i] = false
        else
            LBIRTH[i] = true
        end

    elseif dbskode == Int32(-1)
        @goto label_900
    end

    # Zero out IPVARS if not reading plot-specific data
    if npnvrs == Int32(1)
        fill!(ipvars, Int32(0))
    end

    global IRECRD = IRECRD + Int32(1)

    if debug_mode
        @printf(io_units[JOSTND],
            "  %d IRECRD=%d ITREI=%d IDT=%d PROB=%g ITH=%d CSPI=%s DBH=%g DG=%g HT=%g THT=%g\n",
            i, IRECRD, itrei, IDTREE[i], PROB[i], ith, CSPI_INTREE, DBH[i], DG[i], HT[i], tht)
        @printf(io_units[JOSTND],
            "  %d HTG=%g ICR=%d IMC1=%d KUTKOD=%d ABIRTH=%g DBSKODE=%d LBIRTH=%s\n",
            i, HTG[i], ICR[i], imc1, KUTKOD[i], ABIRTH[i], dbskode, LBIRTH[i] ? "T" : "F")
    end

    if IDTREE[i] > IDCMP1_INTREE - Int32(1)
        @printf(io_units[JOSTND],
            "IN INTREE: TREE ID NUMBER IS LARGER THAN MAXIMUM ALLOWED\n")
    end

    # -----------------------------------------------------------------------
    # Site tree detection — damage code 28 in slots 1, 3, or 5
    # -----------------------------------------------------------------------
    ihit1 = (idamcd[1] == Int32(28)) ? Int32(1) : Int32(0)
    ihit2 = (idamcd[3] == Int32(28)) ? Int32(1) : Int32(0)
    ihit3 = (idamcd[5] == Int32(28)) ? Int32(1) : Int32(0)

    if ihit1 > Int32(0) || ihit2 > Int32(0) || ihit3 > Int32(0)
        global NSITET = NSITET + Int32(1)
        if NSITET > MAXSTR
            @goto label_34
        end
        cspi_loc = CSPI_INTREE
        if strip(cspi_loc) == ""
            cspi_loc = "OT      "
        end
        cspi_loc = uppercase(strip(cspi_loc))

        ispi = MAXSP   # default: unknown species
        @label label_site_sp_loop
        for j2 in Int32(1):MAXSP
            jstr = strip(JSP[j2])
            fstr = strip(FIAJSP[j2])
            pstr = strip(PLNJSP[j2])
            if cspi_loc == jstr
                JSPIN[j2] = Int32(1)
                if JSPINDEF <= Int32(0); global JSPINDEF = Int32(1); end
                ispi = j2
                @goto label_33
            elseif cspi_loc == fstr
                JSPIN[j2] = Int32(2)
                if JSPINDEF <= Int32(0); global JSPINDEF = Int32(2); end
                ispi = j2
                @goto label_33
            elseif cspi_loc == pstr
                JSPIN[j2] = Int32(3)
                if JSPINDEF <= Int32(0); global JSPINDEF = Int32(3); end
                ispi = j2
                @goto label_33
            end
        end
        ispi = SPCTRN(cspi_loc, ispi)

        @label label_33
        SITETR[NSITET, 1] = Float32(ispi)
        SITETR[NSITET, 2] = DBH[i]
        SITETR[NSITET, 3] = HT[i]
        SITETR[NSITET, 4] = ABIRTH[i]

        iaxe = Int32(0)
        if ihit1 > Int32(0)
            d2 = idamcd[2]
            if d2 == Int32(1) || d2 == Int32(3); SITETR[NSITET, 5] = Float32(1); end
            if d2 == Int32(2) || d2 == Int32(4); SITETR[NSITET, 5] = Float32(2); end
            if d2 == Int32(1) || d2 == Int32(2); SITETR[NSITET, 6] = Float32(1); end
            if d2 == Int32(3) || d2 == Int32(4)
                SITETR[NSITET, 6] = Float32(2)
                iaxe = Int32(1)
            end
        elseif ihit2 > Int32(0)
            d4 = idamcd[4]
            if d4 == Int32(1) || d4 == Int32(3); SITETR[NSITET, 5] = Float32(1); end
            if d4 == Int32(2) || d4 == Int32(4); SITETR[NSITET, 5] = Float32(2); end
            if d4 == Int32(1) || d4 == Int32(2); SITETR[NSITET, 6] = Float32(1); end
            if d4 == Int32(3) || d4 == Int32(4)
                SITETR[NSITET, 6] = Float32(2)
                iaxe = Int32(1)
            end
        else
            d6 = idamcd[6]
            if d6 == Int32(1) || d6 == Int32(3); SITETR[NSITET, 5] = Float32(1); end
            if d6 == Int32(2) || d6 == Int32(4); SITETR[NSITET, 5] = Float32(2); end
            if d6 == Int32(1) || d6 == Int32(2); SITETR[NSITET, 6] = Float32(1); end
            if d6 == Int32(3) || d6 == Int32(4)
                SITETR[NSITET, 6] = Float32(2)
                iaxe = Int32(1)
            end
        end

        if iaxe == Int32(1)
            @goto label_10
        end
    end

    @label label_34

    # -----------------------------------------------------------------------
    # Crown class conversion: 1–9 → percent crown ratio
    # -----------------------------------------------------------------------
    if ICR[i] > Int32(0)
        if ICR[i] < Int32(10)
            ICR[i] = ICR[i] * Int32(10) - Int32(5)
        else
            if ICR[i] > Int32(99); ICR[i] = Int32(99); end
        end
    end

    # -----------------------------------------------------------------------
    # Plot ID counting (subplot vector)
    # -----------------------------------------------------------------------
    if iptknt >= LSTKNT
        found_plot = false
        for ipp in LSTKNT:iptknt
            if IPVEC[ipp] == itrei
                found_plot = true
                ITRE[i] = ipp
                @goto label_65
            else
                if IPTINV == Int32(1)
                    itrei = Int32(1)
                    IPVEC[ipp] = Int32(1)
                    ITRE[i] = ipp
                    @goto label_65
                end
            end
        end
    end

    # New subplot
    iptknt = iptknt + Int32(1)
    if iptknt > MAXPLT
        @goto label_15
    end
    IPVEC[iptknt] = itrei
    ITRE[i]       = iptknt

    # Call establishment system for plot site data
    ESPLT1(itrei, imc1, npnvrs, ipvars[1])
    irtncd = fvsGetRtnCode()
    if irtncd != 0; return nothing; end
    @goto label_65

    @label label_65

    # -----------------------------------------------------------------------
    # Mark as existing tree (not established this cycle)
    # -----------------------------------------------------------------------
    IESTAT[i] = Int32(0)

    # Initialize serial correlation scratch
    ZRAND[i] = Float32(-999.0)

    # -----------------------------------------------------------------------
    # Non-stockable plot (IMC1 == 8)
    # -----------------------------------------------------------------------
    if imc1 == Int32(8)
        global NSTKNT = NSTKNT + Int32(1)
        @goto label_10
    end

    # -----------------------------------------------------------------------
    # Species code translation → ISP index (1..MAXSP)
    # -----------------------------------------------------------------------
    cspi_loc = CSPI_INTREE
    if strip(cspi_loc) == ""; cspi_loc = "OT"; end
    cspi_loc = uppercase(strip(cspi_loc))

    ispi = MAXSP  # default
    for j2 in Int32(1):MAXSP
        if cspi_loc == strip(JSP[j2])
            JSPIN[j2] = Int32(1)
            if JSPINDEF <= Int32(0); global JSPINDEF = Int32(1); end
            ispi = j2
            @goto label_72
        elseif cspi_loc == strip(FIAJSP[j2])
            JSPIN[j2] = Int32(2)
            if JSPINDEF <= Int32(0); global JSPINDEF = Int32(2); end
            ispi = j2
            @goto label_72
        elseif cspi_loc == strip(PLNJSP[j2])
            JSPIN[j2] = Int32(3)
            global LFIA = true
            if JSPINDEF <= Int32(0); global JSPINDEF = Int32(3); end
            ispi = j2
            @goto label_72
        end
    end

    # Unknown species — translate via SPCTRN
    ispi = SPCTRN(cspi_loc, ispi)

    # Print unknown species warning (once per unique code)
    if inospc == 0
        @printf(io_units[JOSTND], "\n")
        inospc = Int32(1)
    end
    already_warned = false
    for ic2 in 1:inospc
        if cspi_loc == strip(anospc[ic2])
            already_warned = true
            break
        end
    end
    if !already_warned
        @printf(io_units[JOSTND],
            "            NOTE: INPUT SPECIES CODE (%8s)WAS SET TO (%4s) FOR THIS PROJECTION.\n",
            cspi_loc, strip(JSP[ispi]))
        inospc = min(inospc + Int32(1), Int32(1000))
        anospc[inospc] = rpad(cspi_loc, 8)
    end

    @label label_72
    ISP[i] = ispi

    # -----------------------------------------------------------------------
    # Woodland species stem count
    # -----------------------------------------------------------------------
    fiaspcd_str = strip(FIAJSP[ispi])
    fiaspcd = tryparse(Int32, fiaspcd_str)
    if fiaspcd !== nothing
        woodland_spcds = (62,63,65,66,69,106,133,134,143,321,322,475,803,810,814,843)
        if fiaspcd in woodland_spcds
            if WDLDSTEM[i] == Int32(0); WDLDSTEM[i] = Int32(1); end
        else
            WDLDSTEM[i] = Int32(0)
        end
    end

    # -----------------------------------------------------------------------
    # Height < 4.5 with missing DBH → set DBH to 0.1
    # -----------------------------------------------------------------------
    if HT[i] > Float32(0.0) && HT[i] < Float32(4.5) && DBH[i] == Float32(0.0)
        DBH[i] = Float32(0.1)
    end

    # -----------------------------------------------------------------------
    # Species/DBH screen
    # -----------------------------------------------------------------------
    lincl = false
    if isdsp == Int32(0) || isdsp == ISP[i]
        lincl = true
    elseif isdsp < Int32(0)
        igrp = -isdsp
        iulim = ISPGRP[igrp, 1] + Int32(1)
        for ig in Int32(2):iulim
            if ISP[i] == ISPGRP[igrp, ig]
                lincl = true
                break
            end
        end
    end

    ldeltr = (DBH[i] < Float32(0.0001)) ||
             (lincl && (DBH[i] < sdlo || DBH[i] >= sdhi))

    # Process damage codes
    DAMCDS(i, idamcd)

    if ldeltr
        if DBH[i] >= Float32(0.0001); iscrn = iscrn + Int32(1); end
        @goto label_10
    end

    # -----------------------------------------------------------------------
    # Topkill / broken top detection
    # -----------------------------------------------------------------------
    ITRUNC[i] = Int32(0)
    NORMHT[i]  = Int32(0)

    topkilled = false
    for k in 1:2:5
        if idamcd[k] == Int32(96) || idamcd[k] == Int32(97)
            topkilled = true
            break
        end
    end

    if topkilled || tht > Float32(0.0)
        @goto label_82
    end
    @goto label_90

    @label label_82
    NORMHT[i] = Int32(-1)
    if tht > Float32(0.0)
        ITRUNC[i] = Int32(round(tht * Float32(100.0) + Float32(0.5)))
        if HT[i] <= tht
            HT[i] = Float32(0.0)
        end
    end

    @label label_90

    # Missing height → zero height growth (when IHTG==3)
    if HT[i] == Float32(0.0) && IHTG == Int32(3)
        HTG[i] = Float32(0.0)
    end

    # Store remeasurement data if needed
    if IDG == Int32(1) || IDG == Int32(3); PDBH[i] = DG[i]; end
    if IHTG == Int32(1) || IHTG == Int32(3); PHT[i] = HTG[i]; end

    # -----------------------------------------------------------------------
    # Dead trees: store at bottom of arrays (IREC2..MAXTP1)
    # -----------------------------------------------------------------------
    if ith < Int32(6) || ith > Int32(9)
        @goto label_100
    end

    global IREC2 = IREC2 - Int32(1)
    # Copy all fields from slot i to slot IREC2
    ITRE[IREC2]   = ITRE[i]
    IDTREE[IREC2] = IDTREE[i]
    PROB[IREC2]   = PROB[i]
    DBH[IREC2]    = DBH[i]
    DG[IREC2]     = DG[i]
    HT[IREC2]     = HT[i]
    ITRUNC[IREC2] = ITRUNC[i]
    NORMHT[IREC2] = NORMHT[i]
    ICR[IREC2]    = ICR[i]
    ISP[IREC2]    = ISP[i]
    ISPECL[IREC2] = ISPECL[i]
    DEFECT[IREC2] = DEFECT[i]
    IMC[IREC2]    = (ith == Int32(8) || ith == Int32(9)) ? Int32(9) : Int32(7)
    ABIRTH[IREC2] = ABIRTH[i]
    LBIRTH[IREC2] = LBIRTH[i]
    KUTKOD[IREC2] = KUTKOD[i]
    CULL[IREC2]   = CULL[i]
    DECAYCD[IREC2]= DECAYCD[i]

    # Dead woodland stem count
    fiaspcd_dead = tryparse(Int32, strip(FIAJSP[ISP[i]]))
    if fiaspcd_dead !== nothing
        woodland_spcds = (62,63,65,66,69,106,133,134,143,321,322,475,803,810,814,843)
        if fiaspcd_dead in woodland_spcds
            WDLDSTEM[IREC2] = (WDLDSTEM[i] == Int32(0)) ? Int32(1) : WDLDSTEM[i]
        else
            WDLDSTEM[IREC2] = Int32(0)
        end
    end

    for i3 in 1:6
        DAMSEV[i3, IREC2] = DAMSEV[i3, i]
    end

    # Clear slot i so it does not persist
    PROB[i]    = Float32(0.0)
    DBH[i]     = Float32(0.0)
    DG[i]      = Float32(0.0)
    HT[i]      = Float32(0.0)
    ITRUNC[i]  = Int32(0)
    NORMHT[i]  = Int32(0)
    ICR[i]     = Int32(0)
    ISP[i]     = Int32(0)
    ISPECL[i]  = Int32(0)
    DEFECT[i]  = Int32(0)
    IDTREE[i]  = Int32(0)
    HTG[i]     = Float32(0.0)
    ITRE[i]    = Int32(0)
    PDBH[i]    = Float32(0.0)
    PHT[i]     = Float32(0.0)
    ZRAND[i]   = Float32(-999.0)
    ABIRTH[i]  = Float32(0.0)
    LBIRTH[i]  = false
    KUTKOD[i]  = Int32(0)
    CULL[i]    = Int32(0)
    DECAYCD[i] = Int32(0)
    WDLDSTEM[i]= Int32(0)
    for i3 in 1:6; DAMSEV[i3, i] = Int32(0); end

    i = IREC2
    @goto label_200

    @label label_100
    if imc1 > Int32(3); imc1 = Int32(3); end
    if imc1 <= Int32(0); imc1 = Int32(1); end
    IMC[i] = imc1
    global IREC1 = i

    @label label_200
    # Chain sort: establish this tree as a link
    LNKCHN(i)

    @goto label_10

    # -----------------------------------------------------------------------
    # End of tree data
    # -----------------------------------------------------------------------
    @label label_900
    global LSTKNT = iptknt + Int32(1)
    if NSITET > MAXSTR; global NSITET = MAXSTR; end

    if iscrn > Int32(0)
        @printf(io_units[JOSTND],
            "\n            **** NOTE: %5d TREE RECORDS HAVE BEEN SCREENED OUT BY THE DIAMETER SCREEN.\n",
            iscrn)
    end

    if dbskode == Int32(-1) && lkecho
        @printf(io_units[JOSTND], "            NUMBER ROWS PROCESSED:%5d\n", IRECRD)
    end

    if debug_mode
        @printf(io_units[JOSTND],
            "\n LEAVING SUBROUTINE INTREE.   RECORDS READ=%5d; PLOTS COUNTED = %5d; DBSKODE=%4d\n",
            IRECRD, iptknt, dbskode)
        if NSITET > Int32(0)
            @printf(io_units[JOSTND], "\n SITE INDEX TREES:\n")
            @printf(io_units[JOSTND], "       ISPC       DBH        HT       AGE    T OR B    ON OFF\n")
            for si in 1:NSITET
                @printf(io_units[JOSTND], "  %10.0f%10.1f%10.1f%10.0f%10.0f%10.0f\n",
                    SITETR[si, 1], SITETR[si, 2], SITETR[si, 3],
                    SITETR[si, 4], SITETR[si, 5], SITETR[si, 6])
            end
        end
    end

    return nothing
end

# ---------------------------------------------------------------------------
# parse_tree_record — parse a fixed-format .tre text line using TREFMT fields
#
# Fortran FORMAT: (I4,T1,I7,F6.0,I1,A3,F4.1,F3.1,2F3.0,F4.1,I1,3(I2,I2),2I1,I2,2I3,2I1,F3.0)
# Field layout (1-based columns):
#   1-4   : plot number (ITREI)          I4
#   1-7   : tree number (IDTREE)         I7  (T1 resets; overlaps)
#   8-13  : TPA (PROB)                   F6.0
#   14    : history (ITH)                I1
#   15-17 : species (CSPI)               A3
#   18-21 : DBH (DG input)              F4.1
#   22-24 : DG                           F3.1
#   25-27 : HT                           F3.0
#   28-30 : THT                          F3.0
#   31-34 : HTG                          F4.1
#   35    : ICR                          I1
#   36-37 : IDAMCD(1)                    I2
#   38-39 : IDAMCD(2)                    I2
#   40-41 : IDAMCD(3)                    I2
#   42-43 : IDAMCD(4)                    I2
#   44-45 : IDAMCD(5)                    I2
#   46-47 : IDAMCD(6)                    I2
#   48    : IMC1                         I1
#   49    : KUTKOD                       I1
#   50-51 : IPVARS(1)                    I2
#   52-54 : IPVARS(2)                    I3
#   55-57 : IPVARS(3)                    I3
#   58-59 : IPVARS(4)                    I2
#   60-61 : IPVARS(5)                    I2
#   62-64 : ABIRTH                       F3.0
#
# Returns a tuple of parsed values, or nothing on error.
# ---------------------------------------------------------------------------
function parse_tree_record(line::AbstractString)
    # Pad to 80 chars if shorter
    rec = rpad(line, 80)
    try
        itrei   = parse_int_field(rec,  1,  4)
        idtree  = parse_int_field(rec,  1,  7)
        prob    = parse_real_field(rec, 8, 13)
        ith     = parse_int_field(rec,  14, 14)
        cspi    = rpad(strip(rec[15:17]), 8)
        dbh_val = parse_real_field(rec, 18, 21)   # DBH from F4.1
        dg_val  = parse_real_field(rec, 22, 24)
        ht_val  = parse_real_field(rec, 25, 27)
        tht_val = parse_real_field(rec, 28, 30)
        htg_val = parse_real_field(rec, 31, 34)
        icr_val = parse_int_field(rec,  35, 35)
        dam1    = parse_int_field(rec,  36, 37)
        dam2    = parse_int_field(rec,  38, 39)
        dam3    = parse_int_field(rec,  40, 41)
        dam4    = parse_int_field(rec,  42, 43)
        dam5    = parse_int_field(rec,  44, 45)
        dam6    = parse_int_field(rec,  46, 47)
        imc1    = parse_int_field(rec,  48, 48)
        kutkod  = parse_int_field(rec,  49, 49)
        ipv1    = parse_int_field(rec,  50, 51)
        ipv2    = parse_int_field(rec,  52, 54)
        ipv3    = parse_int_field(rec,  55, 57)
        ipv4    = parse_int_field(rec,  58, 59)
        ipv5    = parse_int_field(rec,  60, 61)
        abirth  = (length(rec) >= 64) ? parse_real_field(rec, 62, 64) : Float32(0.0)

        return (Int32(itrei), Int32(idtree), Float32(prob), Int32(ith), cspi,
                Float32(dbh_val), Float32(dg_val), Float32(ht_val), Float32(tht_val),
                Float32(htg_val), Int32(icr_val),
                Int32(dam1), Int32(dam2), Int32(dam3), Int32(dam4), Int32(dam5), Int32(dam6),
                Int32(imc1), Int32(kutkod),
                Int32(ipv1), Int32(ipv2), Int32(ipv3), Int32(ipv4), Int32(ipv5),
                Float32(abirth))
    catch
        return nothing
    end
end

function parse_int_field(rec::AbstractString, col1::Int, col2::Int)::Int32
    s = strip(rec[col1:min(col2, length(rec))])
    isempty(s) && return Int32(0)
    v = tryparse(Int32, s)
    v === nothing ? Int32(0) : v
end

function parse_real_field(rec::AbstractString, col1::Int, col2::Int)::Float32
    s = strip(rec[col1:min(col2, length(rec))])
    isempty(s) && return Float32(0.0)
    v = tryparse(Float32, s)
    v === nothing ? Float32(0.0) : v
end

# All stubs for INTREE call sites are in base/extstubs.jl or their own .jl files.
# DBSTREESIN → extensions/dbs/dbsqlite.jl
# RDATV, ESPLT1 → base/extstubs.jl
# LNKCHN → base/lnk.jl
# ERRGRO → base/errgro.jl
# DBCHK → base/dbchk.jl
# SPCTRN → base/spctrn.jl
RDTRES() = (Int32(MAXTRE), Int32(MAXTP1))

# Mutable global for IOSTAT used by INTREE loop
IOSTAT_INTREE::Int32 = Int32(0)
