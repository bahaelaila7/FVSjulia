# initre.jl — Keyword initialization dispatcher (147 options)
# Translated from: base/initre.f (6476 lines)
#
# INITRE reads the keyword (.key) file and dispatches to one of 147 handlers
# via a computed-GOTO table.  The PROCESS keyword (option 1) ends with RETURN;
# all other keywords loop back to label_10 for the next keyword.

function INITRE()
    # -----------------------------------------------------------------------
    # ALL locals must be declared before the first @label
    # -----------------------------------------------------------------------
    jrecnt::Int32   = Int32(0)
    kode::Int32     = Int32(0)
    number::Int32   = Int32(0)
    lkecho::Bool    = true
    lfirst::Bool    = true
    lnotre::Bool    = false
    ltrerd::Bool    = false
    debug::Bool     = false
    sdlo::Float32   = Float32(0.0)
    sdhi::Float32   = Float32(999.0)
    isdsp::Int32    = Int32(0)
    igndef::Int32   = Int32(0)
    ipsi::Int32     = Int32(0)
    iptknt::Int32   = Int32(0)
    iprmpt::Int32   = Int32(0)
    idt::Int32      = Int32(0)    # date index (0=no date, else year index)
    iact::Int32     = Int32(0)    # action code for label_4081 shared handler
    i_mult::Int32   = Int32(0)    # multiplier action code for label_6005
    irdplv::Int32   = Int32(0)    # plot-level site vars flag for INTREE
    array  = zeros(Float32, 12)
    prms   = zeros(Float32, 10)
    lnotbk = falses(12)
    kard   = fill("          ", 12)   # CHARACTER*10 in Fortran
    keywrd = "        "
    record = repeat(' ', 250)          # CHARACTER*250 in Fortran
    irecnt_new::Int32 = Int32(0)
    lflag_new::Bool   = false
    irtncd::Int32     = Int32(0)
    newyr::Int32      = Int32(0)
    is::Int32         = Int32(0)   # species index (from SPDECD)
    np::Int32         = Int32(0)   # parameter count
    i_tmp::Int32      = Int32(0)
    i1::Int32         = Int32(0)   # general-purpose index 1
    i2::Int32         = Int32(0)   # general-purpose index 2 / TIMEINT period
    i_k::Int32        = Int32(0)   # STDIDENT parsing loop variable
    idbcyc::Int32     = Int32(0)   # DEBUG cycle number
    irc::Int32        = Int32(0)   # return code from DBPRSE
    ispc::Int32       = Int32(0)   # CWEQN species code
    igrp::Int32       = Int32(0)   # species group index
    iulim::Int32      = Int32(0)   # species group upper limit
    igsp::Int32       = Int32(0)   # species in group
    ig::Int32         = Int32(0)   # group loop variable
    ifsp::Int32       = Int32(0)   # first species in group (VOLUME/BFVOLUME scheduled)
    tc::Float32       = Float32(0.0)  # CWEQN transition size
    xxg::Float32      = Float32(0.0)  # DESIGN GROSPC scratch
    ilen::Int32       = Int32(0)   # string length for echo
    iunit::Int32      = Int32(0)   # REWIND unit number
    iisp::Int32       = Int32(0)   # species index for site tree loop
    iagerf::String    = "        "  # 8-char age reference for site tree table
    ipltrf::String    = "        "  # 8-char plot reference for site tree table
    lopevn::Bool      = false       # LOPEVN — event monitor open flag
    sp_str::String    = ""          # scratch for species code string in echo output
    raw_line::String  = ""          # scratch for reading supplemental records
    line1::String     = ""          # TREEFMT first 80-char line
    line2::String     = ""          # TREEFMT second 80-char line

    # -----------------------------------------------------------------------
    # label_10: top of keyword read loop
    # -----------------------------------------------------------------------
    @label label_10
    irtncd = fvsGetRtnCode()
    if irtncd != Int32(0); return; end

    keywrd, lnotbk, array, irecnt_new, kode, kard, lflag_new =
        KEYRDR(IREAD, JOSTND, debug, lnotbk, array, IRECNT, kode, kard, LFLAG, lkecho)
    global IRECNT = irecnt_new
    global LFLAG  = lflag_new

    iprmpt = kode < Int32(0) ? Int32(-kode) : Int32(0)

    if kode == Int32(3)
        fvsSetRtnCode(Int32(2))
        return
    end
    if kode <= Int32(0); @goto label_30; end
    if kode != Int32(2); @goto label_20; end
    # kode==2: secondary file exhausted — restore primary
    if ICL1 == Int32(0)
        ERRGRO(false, Int32(2))
        irtncd = fvsGetRtnCode()
        if irtncd != Int32(0); return; end
    end
    global IREAD = ICL1
    global ICL1  = Int32(0)
    @goto label_10

    @label label_20
    ERRGRO(true, Int32(6))
    @goto label_10

    # -----------------------------------------------------------------------
    # label_30: keyword read OK — look it up in TABLE
    # -----------------------------------------------------------------------
    @label label_30
    number, kode = FNDKEY(keywrd, TABLE, JOSTND)
    if kode == Int32(1)
        ERRGRO(true, Int32(1))
        @goto label_10
    end
    if !lfirst; @goto label_90; end

    # First keyword of a new stand: initialize all extensions
    lfirst = false
    lnotre = false
    GRINIT()
    OPINIT()
    RANSED(false, WK6)
    ESINIT()
    MPBINT()
    DFBINT()
    TMINIT()
    BWEINT()
    CVINIT()
    RDINIT()
    MISIN0()
    MISINT()
    BRINIT()
    ISSTAG()
    FMINIT()
    SVINIT()
    ECINIT()
    DBSINIT()
    CLINIT()
    rrgo_r = Ref(false)
    rrt_r  = Ref(false)
    RDATV(rrgo_r, rrt_r)
    if rrgo_r[]; RDESIN(); end
    global ITITLE = repeat(' ', 72)
    ltrerd = false
    @goto label_90

    # -----------------------------------------------------------------------
    # label_80: EOF / read error — try graceful shutdown
    # -----------------------------------------------------------------------
    @label label_80
    ERRGRO(false, Int32(2))
    irtncd = fvsGetRtnCode()
    if irtncd != Int32(0); return; end

    # -----------------------------------------------------------------------
    # label_90: 147-way dispatch on NUMBER
    # Fortran computed GOTO table (initre.f lines 221-236):
    #   NUMBER 1→label_100 ... 147→label_14700
    # -----------------------------------------------------------------------
    @label label_90
    if     number == Int32(1);   @goto label_100
    elseif number == Int32(2);   @goto label_1200
    elseif number == Int32(3);   @goto label_1300
    elseif number == Int32(4);   @goto label_1400
    elseif number == Int32(5);   @goto label_1500
    elseif number == Int32(6);   @goto label_1600
    elseif number == Int32(7);   @goto label_1700
    elseif number == Int32(8);   @goto label_1800
    elseif number == Int32(9);   @goto label_1900
    elseif number == Int32(10);  @goto label_2000
    elseif number == Int32(11);  @goto label_2100
    elseif number == Int32(12);  @goto label_2200
    elseif number == Int32(13);  @goto label_2300
    elseif number == Int32(14);  @goto label_2400
    elseif number == Int32(15);  @goto label_2500
    elseif number == Int32(16);  @goto label_2600
    elseif number == Int32(17);  @goto label_2700
    elseif number == Int32(18);  @goto label_2800
    elseif number == Int32(19);  @goto label_2900
    elseif number == Int32(20);  @goto label_3000
    elseif number == Int32(21);  @goto label_3100
    elseif number == Int32(22);  @goto label_3200
    elseif number == Int32(23);  @goto label_3300
    elseif number == Int32(24);  @goto label_3400
    elseif number == Int32(25);  @goto label_3500
    elseif number == Int32(26);  @goto label_3600
    elseif number == Int32(27);  @goto label_3700
    elseif number == Int32(28);  @goto label_3800
    elseif number == Int32(29);  @goto label_3900
    elseif number == Int32(30);  @goto label_4000
    elseif number == Int32(31);  @goto label_4010
    elseif number == Int32(32);  @goto label_4020
    elseif number == Int32(33);  @goto label_4030
    elseif number == Int32(34);  @goto label_4040
    elseif number == Int32(35);  @goto label_4050
    elseif number == Int32(36);  @goto label_4060
    elseif number == Int32(37);  @goto label_4070
    elseif number == Int32(38);  @goto label_4080
    elseif number == Int32(39);  @goto label_4100
    elseif number == Int32(40);  @goto label_4200
    elseif number == Int32(41);  @goto label_4300
    elseif number == Int32(42);  @goto label_4400
    elseif number == Int32(43);  @goto label_4500
    elseif number == Int32(44);  @goto label_4600
    elseif number == Int32(45);  @goto label_4700
    elseif number == Int32(46);  @goto label_4800
    elseif number == Int32(47);  @goto label_4900
    elseif number == Int32(48);  @goto label_5000
    elseif number == Int32(49);  @goto label_5100
    elseif number == Int32(50);  @goto label_5200
    elseif number == Int32(51);  @goto label_5300
    elseif number == Int32(52);  @goto label_5400
    elseif number == Int32(53);  @goto label_5500
    elseif number == Int32(54);  @goto label_5600
    elseif number == Int32(55);  @goto label_5700
    elseif number == Int32(56);  @goto label_5800
    elseif number == Int32(57);  @goto label_5900
    elseif number == Int32(58);  @goto label_6000
    elseif number == Int32(59);  @goto label_6100
    elseif number == Int32(60);  @goto label_6200
    elseif number == Int32(61);  @goto label_6300
    elseif number == Int32(62);  @goto label_6400
    elseif number == Int32(63);  @goto label_6500
    elseif number == Int32(64);  @goto label_6600
    elseif number == Int32(65);  @goto label_6700
    elseif number == Int32(66);  @goto label_6800
    elseif number == Int32(67);  @goto label_6900
    elseif number == Int32(68);  @goto label_7000
    elseif number == Int32(69);  @goto label_7100
    elseif number == Int32(70);  @goto label_7200
    elseif number == Int32(71);  @goto label_7300
    elseif number == Int32(72);  @goto label_7400
    elseif number == Int32(73);  @goto label_7500
    elseif number == Int32(74);  @goto label_7600
    elseif number == Int32(75);  @goto label_7700
    elseif number == Int32(76);  @goto label_7800
    elseif number == Int32(77);  @goto label_7900
    elseif number == Int32(78);  @goto label_8000
    elseif number == Int32(79);  @goto label_8100
    elseif number == Int32(80);  @goto label_8200
    elseif number == Int32(81);  @goto label_8300
    elseif number == Int32(82);  @goto label_8400
    elseif number == Int32(83);  @goto label_8500
    elseif number == Int32(84);  @goto label_8600
    elseif number == Int32(85);  @goto label_8700
    elseif number == Int32(86);  @goto label_8800
    elseif number == Int32(87);  @goto label_8900
    elseif number == Int32(88);  @goto label_9000
    elseif number == Int32(89);  @goto label_9100
    elseif number == Int32(90);  @goto label_9200
    elseif number == Int32(91);  @goto label_9300
    elseif number == Int32(92);  @goto label_9400
    elseif number == Int32(93);  @goto label_9500
    elseif number == Int32(94);  @goto label_9600
    elseif number == Int32(95);  @goto label_9700
    elseif number == Int32(96);  @goto label_9800
    elseif number == Int32(97);  @goto label_9900
    elseif number == Int32(98);  @goto label_9950
    elseif number == Int32(99);  @goto label_9975
    elseif number == Int32(100); @goto label_9985
    elseif number == Int32(101); @goto label_9995
    elseif number == Int32(102); @goto label_10000
    elseif number == Int32(103); @goto label_10100
    elseif number == Int32(104); @goto label_10200
    elseif number == Int32(105); @goto label_10300
    elseif number == Int32(106); @goto label_10400
    elseif number == Int32(107); @goto label_10500
    elseif number == Int32(108); @goto label_10600
    elseif number == Int32(109); @goto label_10900
    elseif number == Int32(110); @goto label_11000
    elseif number == Int32(111); @goto label_11100
    elseif number == Int32(112); @goto label_11200
    elseif number == Int32(113); @goto label_11300
    elseif number == Int32(114); @goto label_11400
    elseif number == Int32(115); @goto label_11500
    elseif number == Int32(116); @goto label_11600
    elseif number == Int32(117); @goto label_11700
    elseif number == Int32(118); @goto label_11800
    elseif number == Int32(119); @goto label_11900
    elseif number == Int32(120); @goto label_12000
    elseif number == Int32(121); @goto label_12100
    elseif number == Int32(122); @goto label_12200
    elseif number == Int32(123); @goto label_12300
    elseif number == Int32(124); @goto label_12400
    elseif number == Int32(125); @goto label_12500
    elseif number == Int32(126); @goto label_12600
    elseif number == Int32(127); @goto label_12700
    elseif number == Int32(128); @goto label_12800
    elseif number == Int32(129); @goto label_12900
    elseif number == Int32(130); @goto label_13000
    elseif number == Int32(131); @goto label_13100
    elseif number == Int32(132); @goto label_13200
    elseif number == Int32(133); @goto label_13300
    elseif number == Int32(134); @goto label_13400
    elseif number == Int32(135); @goto label_13500
    elseif number == Int32(136); @goto label_13600
    elseif number == Int32(137); @goto label_13700
    elseif number == Int32(138); @goto label_13800
    elseif number == Int32(139); @goto label_13900
    elseif number == Int32(140); @goto label_14000
    elseif number == Int32(141); @goto label_14100
    elseif number == Int32(142); @goto label_14200
    elseif number == Int32(143); @goto label_14300
    elseif number == Int32(144); @goto label_14400
    elseif number == Int32(145); @goto label_14500
    elseif number == Int32(146); @goto label_14600
    elseif number == Int32(147); @goto label_14700
    end
    @goto label_10

    # =======================================================================
    # OPTION 1 — PROCESS  (label_100)
    # Triggers stand simulation.  Ends with RETURN, not @goto label_10.
    # =======================================================================
    @label label_100
    # PROCESS — verified against initre.f lines 241-527
    # Print count of skipped keyword records when echoing is off
    if !lkecho
        if IRECNT > jrecnt
            jrecnt = IRECNT - jrecnt - Int32(1)
        else
            jrecnt = IRECNT
        end
        @printf(io_units[JOSTND], "\n           THERE WERE%8d KEYWORD RECORDS PROCESSED.\n", jrecnt)
    end
    @printf(io_units[JOSTND], "\n%-8s   PROCESS THE STAND.\n", keywrd)

    # Close any still-open events (IPRMPT=-1 signals close-all)
    iprmpt = Int32(-1)
    EVEND(debug, JOSTND, IRECNT, keywrd, array, lnotbk, kard, iprmpt, lkecho)

    # If NOTREES keyword used with no tree data, set empty stand counts
    if !MORDAT && lnotre
        global LSTKNT = Int32(1)
        global NSTKNT = Int32(0)
        global MORDAT = true
    end

    # Ensure INTREE was called at least once (reads tree data file)
    if !MORDAT
        INTREE(record, Int32(0), isdsp, sdlo, sdhi, lkecho)
        irtncd = fvsGetRtnCode()
        if irtncd != Int32(0); return; end
        global MORDAT = true
    end

    # Warn if too few projectable trees; auto-invoke NOTREES
    if IREC1 < Int32(1) && !lnotre
        ERRGRO(true, Int32(8))
        @printf(io_units[JOSTND], "           (NOTREES OPTION IS AUTOMATICALLY INVOKED.)\n")
        lnotre = true
        ESEZCR(JOSTND, lkecho)
        global IREC1  = Int32(0)
        global ITRN   = Int32(0)
        global LSTKNT = Int32(1)
        global NSTKNT = Int32(0)
    end

    # Process damage codes stored on input tree data
    DAMPRO()

    # Match tree ID numbers to tree index numbers from INTREE
    TRESOR()

    # Compute and validate plot counts
    iptknt = LSTKNT - Int32(1)
    if IPTINV == Int32(-9999); global IPTINV = iptknt; end
    if NONSTK == Int32(-9999); global NONSTK = NSTKNT; end
    if IPTINV <= Int32(0);     global IPTINV = Int32(1); end
    if IPTINV > Int32(MAXPLT); global IPTINV = iptknt; end

    if IPTINV > Int32(1) && IPTINV < iptknt
        ERRGRO(false, Int32(38))
    end
    if (IPTINV != iptknt || NONSTK != NSTKNT) && !lnotre
        ERRGRO(true, Int32(9))
    end

    global PI   = Float32(IPTINV)
    if SAMWT < Float32(0.0); global SAMWT = Float32(IPTINV); end

    # Update database case record with final plot count
    DBSCASE(Int32(2))

    # Compute proportion of stand that is stockable
    if GROSPC < Float32(0.0)
        global GROSPC = (PI - Float32(NONSTK)) / PI
        if GROSPC > Float32(1.0); global GROSPC = Float32(1.0); end
        if (PI - Float32(NONSTK)) <= Float32(0.0)
            global GROSPC = Float32(1.0)
            ERRGRO(true, Int32(35))
        end
    end

    # Write delimiter and "OPTIONS SELECTED BY DEFAULT" header
    @printf(io_units[JOSTND], "%s\n", repeat('-', 130))
    @printf(io_units[JOSTND], "\n%48s OPTIONS SELECTED BY DEFAULT\n\n%s\n",
        "", repeat('-', 130))

    # Echo tree format if not set via TREEFMT keyword
    if !ltrerd
        @printf(io_units[JOSTND], "\nTREEFMT    %-80s\n           %-80s\n",
            TREFMT[1:min(80, length(TREFMT))],
            length(TREFMT) >= 81 ? TREFMT[81:min(160, length(TREFMT))] : "")
    end

    # Write DESIGN parameters (FORMAT 2010, initre.f lines 792-797)
    @printf(io_units[JOSTND],
        "\n%-8s   BASAL AREA FACTOR= %6.1f; INVERSE OF FIXED PLOT AREA= %6.1f; BREAK DBH= %6.1f\n           NUMBER OF PLOTS= %5d; NON-STOCKABLE PLOTS= %5d; STAND SAMPLING WEIGHT=%12.5f\n           PROPORTION OF STAND CONSIDERED STOCKABLE= %6.3f\n",
        "DESIGN", BAF, FPA, BRK, IPTINV, NONSTK, SAMWT, GROSPC)

    if GROSPC != Float32(1.0)
        @printf(io_units[JOSTND],
            "           STAND ATTRIBUTES ARE CALCULATED PER ACRE OF STOCKABLE AREA.  STAND STATISTICS\n           IN SUMMARY TABLE ARE MULTIPLIED BY %5.3f TO INCLUDE TOTAL STAND AREA.\n",
            GROSPC)
    end

    # Convert GROSPC from proportion to reciprocal multiplier
    global GROSPC = Float32(1.0) / GROSPC

    # Compute forest type code if not set via STDINFO keyword
    if KODFOR == Int32(0); FORKOD(); end

    # Compute habitat type if not set via STDINFO keyword
    if KODTYP == Int32(0)
        array[2] = Float32(0.0)
        kard[2]  = "          "
        HABTYP(kard[2], array[2])
    end

    # Write site info header (format depends on variant)
    if VARACD == "CR" || VARACD == "UT" || VARACD == "TT" || VARACD == "WS"
        @printf(io_units[JOSTND],
            "\nSTDINFO    FOREST-LOCATION CODE=%6d; HABITAT TYPE=%-10s (CODE %3d); AGE=%5d; ASPECT AZIMUTH IN DEGREES= %4.0f;\n           SLOPE= %4.0f%%; ELEVATION(100'S FEET)=%5.1f; REFERENCE CODE= %-4s; ECOREGION=%-10s\n",
            KODFOR, strip(kard[2]), KODTYP, IAGE, ASPECT, SLOPE, ELEV,
            strip(CPVREF), strip(ECOREG))
    elseif VARACD == "AK"
        @printf(io_units[JOSTND],
            "\nSTDINFO    FOREST-LOCATION CODE=%8d; HABITAT TYPE=%3d; AGE=%5d; ASPECT AZIMUTH IN DEGREES= %4.0f; SLOPE= %4.0f%%\n           ELEVATION(100'S FEET)=%5.1f;  REFERENCE CODE= %-4s; ECOREGION= %-10s\n",
            KODFOR, KODTYP, IAGE, ASPECT, SLOPE, ELEV,
            strip(CPVREF), strip(ECOREG))
    elseif VARACD == "SN"
        @printf(io_units[JOSTND],
            "\nSTDINFO    FOREST-LOCATION CODE=%8d; ECOLOGICAL UNIT=%-10s; AGE=%5d; ASPECT AZIMUTH IN DEGREES= %4.0f; SLOPE= %4.0f%%\n           ELEVATION(100'S FEET)=%5.1f; REFERENCE CODE= %-4s; ECOREGION= %-10s\n",
            KODFOR, strip(PCOM), IAGE, ASPECT, SLOPE, ELEV,
            strip(CPVREF), strip(ECOREG))
    else
        @printf(io_units[JOSTND],
            "\nSTDINFO    FOREST-LOCATION CODE=%8d; HABITAT TYPE=%3d; AGE=%5d; ASPECT AZIMUTH IN DEGREES= %4.0f; SLOPE= %4.0f%%\n           ELEVATION(100'S FEET)=%5.1f; REFERENCE CODE= %-4s; ECOREGION= %-10s\n",
            KODFOR, KODTYP, IAGE, ASPECT, SLOPE, ELEV,
            strip(CPVREF), strip(ECOREG))
    end

    # Save undecoded slope and aspect for later use
    global IASPEC = Int32(trunc(ASPECT))
    global ISLOP  = Int32(trunc(SLOPE))

    # Set controlling site values not set via keywords; dump site index array
    SITSET()
    if ISISP > Int32(0) && ISISP <= Int32(MAXSP)
        global STNDSI = SITEAR[ISISP]
    else
        global STNDSI = Float32(0.0)
    end

    # Wipe defect percentages from input if DEFECT keyword requested it
    if igndef > Int32(0)
        for _i in Int32(1):Int32(MAXTRE)
            DEFECT[_i] = Int32(0)
        end
    end

    # Write site index cross reference table
    if ipsi > Int32(0) || ISISP > Int32(0)
        @printf(io_units[JOSTND], "\n%-8s   SITE INDEX INFORMATION:\n", TABLE[94])
        # Write species site index table (8 per line with '; ' separator)
        for _i in Int32(1):Int32(MAXSP)
            if (_i - Int32(1)) % Int32(9) == Int32(0)
                @printf(io_units[JOSTND], "           ")
            end
            sp2 = length(NSP[_i,1]) >= 2 ? NSP[_i,1][1:2] : rpad(NSP[_i,1],2)
            @printf(io_units[JOSTND], "%2s=%6.0f", sp2, Float32(round(SITEAR[_i])))
            if _i < Int32(MAXSP)
                @printf(io_units[JOSTND], "; ")
                if _i % Int32(9) == Int32(0)
                    @printf(io_units[JOSTND], "\n")
                end
            else
                @printf(io_units[JOSTND], "\n")
            end
        end
        if ISISP > Int32(0)
            sp2 = length(NSP[ISISP,1]) >= 2 ? NSP[ISISP,1][1:2] : rpad(NSP[ISISP,1],2)
            @printf(io_units[JOSTND], "           SITE SPECIES=%2s CODE=%5d\n", sp2, ISISP)
        else
            @printf(io_units[JOSTND], "           SITE SPECIES NOT SPECIFIED.  CODE=%5d\n", ISISP)
        end
        if VARACD == "NI" || VARACD == "KT"
            @printf(io_units[JOSTND],
                "           NOTE: SITE INDEX IS NOT USED IN THIS VARIANT.  VALUES ARE PRINTED FOR INFORMATIONAL PURPOSES.\n")
        end
        if NSITET > Int32(0)
            @printf(io_units[JOSTND],
                "\n           SITE INDEX TREE INPUT SUMMARY TABLE:\n           SPECIES  DIAMETER    HEIGHT       AGE    AGE REF    PLOT REF\n           -------  --------    ------       ---    -------    --------\n")
            for _i in Int32(1):Int32(NSITET)
                iagerf = "        "
                ipltrf = "        "
                if Int32(SITETR[_i,5]) == Int32(1); iagerf = "   TOTAL"; end
                if Int32(SITETR[_i,5]) == Int32(2); iagerf = "  BREAST"; end
                if Int32(SITETR[_i,6]) == Int32(1); ipltrf = "      ON"; end
                if Int32(SITETR[_i,6]) == Int32(2); ipltrf = "     OFF"; end
                iisp = Int32(SITETR[_i,1])
                sp2 = length(NSP[iisp,1]) >= 2 ? NSP[iisp,1][1:2] : rpad(NSP[iisp,1],2)
                @printf(io_units[JOSTND], "         %3d (%2s)%10.1f%10.1f%10.0f   %8s  %8s\n",
                    iisp, sp2, SITETR[_i,2], SITETR[_i,3], SITETR[_i,4], iagerf, ipltrf)
            end
        end
    end

    # Write inventory point cross reference table
    @printf(io_units[JOSTND],
        "\nINVENTORY POINT CROSS REFERENCE (FVS SEQUENTIAL POINT NUMBER = POINT NUMBER AS ENTERED IN THE INPUT DATA):\n")
    for _i in Int32(1):Int32(IPTINV)
        @printf(io_units[JOSTND], "%3d=%8d", _i, IPVEC[_i])
        if _i < Int32(IPTINV)
            @printf(io_units[JOSTND], "; ")
            if _i % Int32(9) == Int32(0)
                @printf(io_units[JOSTND], "\n")
            end
        else
            @printf(io_units[JOSTND], "\n")
        end
    end

    # Write final delimiter, then transform terrain variables
    LBDSET(JOSTND, lkecho)
    if lkecho
        @printf(io_units[JOSTND], "%s\n", repeat('-', 130))
    end
    TRNSLO()
    TRNASP()

    # Run establishment per-plot processing then return to caller (FVS!)
    ESPLT2(iptknt)
    return  # verified: PROCESS ends with RETURN not @goto label_10

    # =======================================================================
    # OPTION 2 — TIMEINT  (label_1200)
    # Set simulation year schedule: ARRAY(1..np) → IY(1..np+1?)
    # =======================================================================
    # OPTION 2 — TIMEINT  (label_1200) verified against initre.f 535-557
    # =======================================================================
    @label label_1200
    i2 = Int32(10)
    if lnotbk[2]; i2 = Int32(array[2]); end
    if lnotbk[1]
        i_tmp = abs(Int32(array[1])) + Int32(1)
        if i_tmp != Int32(1)
            if i_tmp > Int32(MAXCY1)
                KEYDMP(JOSTND, IRECNT, keywrd, array, kard)
                ERRGRO(true, Int32(4))
                @goto label_10
            end
            IY[i_tmp] = i2
            if lkecho; @printf(io_units[JOSTND], "\n%-8s   CYCLE=%3d; PERIOD LENGTH=%3d\n", keywrd, i_tmp-Int32(1), i2); end
            @goto label_10
        end
    end
    # label_1220: fill all cycles
    for i_j in Int32(2):Int32(MAXCY1)
        IY[i_j] = i2
    end
    if lkecho; @printf(io_units[JOSTND], "\n%-8s   ALL CYCLES;  PERIOD LENGTH=%3d\n", keywrd, i2); end
    @goto label_10

    # =======================================================================
    # OPTION 3 — FIXCW  (label_1300) verified against initre.f 561-596
    # Fixed crown-width equation: OPNEWC/OPNEW act=90, SPDECD field 2
    # =======================================================================
    @label label_1300
    idt = Int32(1)
    if lnotbk[1]; idt = Int32(array[1]); end
    if iprmpt > Int32(0)
        if iprmpt != Int32(2)
            KEYDMP(JOSTND, IRECNT, keywrd, array, kard)
            ERRGRO(true, Int32(25))
        else
            kode = OPNEWC(JOSTND, IREAD, idt, Int32(90), keywrd, kard, iprmpt, IRECNT, ICYC)
            irtncd = fvsGetRtnCode()
            if irtncd != Int32(0); return; end
        end
    else
        is = SPDECD(Int32(2), NSP, JOSTND, IRECNT, keywrd, array, kard)
        if is == Int32(-999); @goto label_10; end
        if !lnotbk[3]; array[3] = Float32(1.0); end
        if !lnotbk[4]; array[4] = Float32(0.0); end
        if !lnotbk[5]; array[5] = Float32(999.0); end
        ilen = Int32(3)
        if is < Int32(0); ilen = ISPGRP(-is, Int32(92)); end
        if lkecho
            sp_str = length(kard[2]) >= ilen ? kard[2][1:ilen] : rpad(kard[2], ilen)
            @printf(io_units[JOSTND], "\n%-8s   DATE/CYCLE=%5d; SPECIES=%s (CODE=%3d); CROWN WIDTH MULTIPLIER=%10.4f\n           ONLY TREES GREATER THAN OR EQUAL TO %7.2f AND LESS THAN %7.2f INCHES DBH ARE AFFECTED.\n",
                keywrd, idt, sp_str, is, array[3], array[4], array[5])
        end
        kode = OPNEW(idt, Int32(90), Int32(4), array)
        if kode > Int32(0); @goto label_10; end
    end
    @goto label_10

    # =======================================================================
    # OPTION 4 — TREEDATA  (label_1400) verified against initre.f 600-641
    # Alternate tree data file: ISTDAT, SDLO/SDHI, ISDSP, INTREE
    # =======================================================================
    @label label_1400
    if lnotbk[1]; global ISTDAT = Int32(array[1]); end
    i_tmp = Int32(0)
    if lnotbk[2]; i_tmp = Int32(1); end
    if lnotbk[3]; sdlo = array[3]; end
    if lnotbk[4]; sdhi = array[4]; end
    is = Int32(0)
    if lnotbk[5]
        is = SPDECD(Int32(5), NSP, JOSTND, IRECNT, keywrd, array, kard)
        if is == Int32(-999); @goto label_10; end
        isdsp = is
    end
    if lkecho; @printf(io_units[JOSTND], "\n%-8s   DATA SET REFERENCE NUMBER=%3d\n", keywrd, ISTDAT); end
    if is != Int32(0) && lkecho && lnotbk[5]
        ilen = Int32(3)
        if is < Int32(0); ilen = ISPGRP(-is, Int32(92)); end
        sp_str = length(kard[5]) >= ilen ? kard[5][1:ilen] : rpad(kard[5], ilen)
        @printf(io_units[JOSTND], "           SPECIES= %s (CODE= %3d) IS TARGETED FOR SCREENING.\n", sp_str, is)
    elseif lkecho && lnotbk[5]
        @printf(io_units[JOSTND], "           ALL SPECIES (CODE= %3d) ARE TARGETED FOR SCREENING.\n", is)
    end
    if (lnotbk[3] || lnotbk[4]) && lkecho
        @printf(io_units[JOSTND], "           ONLY RECORDS WITH DIAMETERS GE%6.1f INCHES OR LT%6.1f INCHES WILL BE READ FROM THE DATA.\n           ALL OTHER INPUT RECORDS WILL BE SCREENED OUT.\n", sdlo, sdhi)
    end
    if i_tmp == Int32(1) && lkecho
        @printf(io_units[JOSTND], "           PLOT SPECIFIC SITE DATA READ FROM TREE RECORDS.\n")
    end
    INTREE(record, i_tmp, isdsp, sdlo, sdhi, lkecho)
    irtncd = fvsGetRtnCode()
    if irtncd != Int32(0); return; end
    global MORDAT = true
    @goto label_10

    # =======================================================================
    # OPTION 5 — TREEFMT  (label_1500) verified against initre.f 645-654
    # User-supplied tree record format: reads 2×80 chars from keyword file
    # =======================================================================
    @label label_1500
    ltrerd = true
    if lkecho; @printf(io_units[JOSTND], "\n%-8s\n", keywrd); end
    line1 = readline(io_units[IREAD])
    line2 = readline(io_units[IREAD])
    global IRECNT = IRECNT + Int32(2)
    global TREFMT = rpad(line1, 80)[1:80] * rpad(line2, 80)[1:80]
    if lkecho
        @printf(io_units[JOSTND], "           %-80s\n           %-80s\n", TREFMT[1:80], TREFMT[81:160])
    end
    if MORDAT; ERRGRO(true, Int32(7)); end
    @goto label_10

    # =======================================================================
    # OPTION 6 — MPB  (label_1600) verified against initre.f 658-662
    # =======================================================================
    @label label_1600
    if lkecho; @printf(io_units[JOSTND], "\n%-8s   MOUNTAIN PINE BEETLE OPTIONS:\n", keywrd); end
    MPBIN(keywrd, array, lnotbk, lkecho)
    @goto label_10

    # =======================================================================
    # OPTION 7 — DFTM  (label_1700) verified against initre.f 666-670
    # =======================================================================
    @label label_1700
    if lkecho; @printf(io_units[JOSTND], "\n%-8s   DOUGLAS-FIR TUSSOCK MOTH OPTIONS:\n", keywrd); end
    DFTMIN(lkecho)
    @goto label_10

    # =======================================================================
    # OPTION 8 — WSBW  (label_1800) verified against initre.f 674-681
    # =======================================================================
    @label label_1800
    if lkecho; @printf(io_units[JOSTND], "\n%-8s   WESTERN SPRUCE BUDWORM OPTIONS:\n", keywrd); end
    BWEIN(lkecho)
    @goto label_10

    # =======================================================================
    # OPTION 9 — CWEQN  (label_1900) verified against initre.f 685-768
    # Crown-width user equations: reads 8F10 supplemental record into WK6
    # =======================================================================
    @label label_1900
    # Read 8 coefficients from supplemental record
    raw_line = readline(io_units[IREAD])
    global IRECNT = IRECNT + Int32(1)
    for j in 1:8
        s = length(raw_line) >= j*10 ? raw_line[(j-1)*10+1:j*10] : "          "
        WK6[j] = something(tryparse(Float32, strip(s)), Float32(0.0))
    end
    is = SPDECD(Int32(1), NSP, JOSTND, IRECNT, keywrd, array, kard)
    if is == Int32(-999); @goto label_10; end
    tc = array[2]
    if is < Int32(0)
        igrp = -is
        iulim = ISPGRP(igrp, Int32(1)) + Int32(1)
        for ig in Int32(2):iulim
            igsp = ISPGRP(igrp, ig)
            LSPCWE[igsp] = true
            CWTDBH[igsp] = tc
            CWDS0[igsp] = WK6[1]; CWDS1[igsp] = WK6[2]; CWDS2[igsp] = WK6[3]; CWDS3[igsp] = WK6[4]
            CWDL0[igsp] = WK6[5]; CWDL1[igsp] = WK6[6]; CWDL2[igsp] = WK6[7]; CWDL3[igsp] = WK6[8]
        end
        ilen = ISPGRP(-is, Int32(92))
        if lkecho
            sp_str = length(kard[1]) >= ilen ? kard[1][1:ilen] : rpad(kard[1], ilen)
            @printf(io_units[JOSTND], "\n%-8s           DEFAULT COEFFICIENTS FOR CROWN WIDTH EQUATIONS REPLACED FOR SPECIES= %s (CODE= %3d).\n", keywrd, sp_str, is)
        end
    elseif is == Int32(0)
        for ispc in Int32(1):Int32(MAXSP)
            LSPCWE[ispc] = true
            CWTDBH[ispc] = tc
            CWDS0[ispc] = WK6[1]; CWDS1[ispc] = WK6[2]; CWDS2[ispc] = WK6[3]; CWDS3[ispc] = WK6[4]
            CWDL0[ispc] = WK6[5]; CWDL1[ispc] = WK6[6]; CWDL2[ispc] = WK6[7]; CWDL3[ispc] = WK6[8]
        end
        if lkecho
            @printf(io_units[JOSTND], "\n%-8s           DEFAULT COEFFICIENTS FOR CROWN WIDTH EQUATIONS REPLACED FOR ALL SPECIES.\n", keywrd)
        end
    else
        LSPCWE[is] = true
        CWTDBH[is] = tc
        CWDS0[is] = WK6[1]; CWDS1[is] = WK6[2]; CWDS2[is] = WK6[3]; CWDS3[is] = WK6[4]
        CWDL0[is] = WK6[5]; CWDL1[is] = WK6[6]; CWDL2[is] = WK6[7]; CWDL3[is] = WK6[8]
        if lkecho
            sp_str = kard[1][1:min(3, length(kard[1]))]
            @printf(io_units[JOSTND], "\n%-8s           DEFAULT COEFFICIENTS FOR CROWN WIDTH EQUATIONS REPLACED FOR SPECIES= %s (CODE= %3d).\n", keywrd, sp_str, is)
        end
    end
    if lkecho
        @printf(io_units[JOSTND], "           TRANSITION SIZE = %10.2f INCHES DBH.   EQUATION FORM: C0 + C1*DBH +C2*DBH**C3\n           COEFFICIENTS FOR TREES THAT ARE SMALLER THAN TRANSITION SIZE:\n           C0= %12.5f  C1= %12.5f  C2= %12.5f  C3= %12.5f\n           COEFFICIENTS FOR TREES THAT ARE LARGER THAN TRANSITION SIZE:\n           C0= %12.5f  C1= %12.5f  C2= %12.5f  C3= %12.5f\n",
            tc, WK6[1], WK6[2], WK6[3], WK6[4], WK6[5], WK6[6], WK6[7], WK6[8])
    end
    @goto label_10

    # =======================================================================
    # OPTION 10 — DESIGN  (label_2000) verified against initre.f 772-801
    # Plot design: BAF, FPA, BRK, IPTINV, NONSTK, SAMWT, GROSPC
    # =======================================================================
    @label label_2000
    if lnotbk[1]; global BAF    = array[1]; end
    if lnotbk[2]; global FPA    = array[2]; end
    if lnotbk[3]; global BRK    = array[3]; end
    if lnotbk[4]; global IPTINV = Int32(array[4]); end
    if lnotbk[5]; global NONSTK = Int32(array[5]); end
    if lnotbk[6]; global SAMWT  = array[6]; end
    if SAMWT <= Float32(0.0) && IPTINV > Int32(0); global SAMWT = Float32(IPTINV); end
    if array[7] > Float32(1.0) && array[7] <= Float32(100.0); array[7] = array[7] * Float32(0.01); end
    if array[7] > Float32(0.0) && array[7] <= Float32(1.0);   global GROSPC = array[7]; end
    if GROSPC < Float32(0.0)
        xxg = Float32(1.0)
        if IPTINV > Int32(0) && NONSTK > Int32(0) && (IPTINV - NONSTK) > Int32(0)
            xxg = (Float32(IPTINV) - Float32(NONSTK)) / Float32(IPTINV)
        end
    else
        xxg = GROSPC
    end
    if lkecho
        @printf(io_units[JOSTND], "\n%-8s   BASAL AREA FACTOR= %6.1f; INVERSE OF FIXED PLOT AREA= %6.1f; BREAK DBH= %6.1f\n           NUMBER OF PLOTS= %5d; NON-STOCKABLE PLOTS= %5d; STAND SAMPLING WEIGHT=%12.5f\n           PROPORTION OF STAND CONSIDERED STOCKABLE= %6.3f\n",
            keywrd, BAF, FPA, BRK, max(Int32(0), IPTINV), max(Int32(0), NONSTK), max(Float32(0.0), SAMWT), xxg)
        @printf(io_units[JOSTND], "           SEE \"OPTIONS SELECTED BY DEFAULT\" FOR FINAL DESIGN VALUES.\n")
    end
    @goto label_10

    # =======================================================================
    # OPTION 11 — NUMCYCLE  (label_2100) verified against initre.f 805-814
    # =======================================================================
    @label label_2100
    if !(array[1] >= Float32(1.0) && Int32(array[1]) <= Int32(MAXCYC))
        KEYDMP(JOSTND, IRECNT, keywrd, array, kard)
        ERRGRO(true, Int32(4))
        @goto label_10
    end
    global NCYC = Int32(array[1])
    if lkecho; @printf(io_units[JOSTND], "\n%-8s   NUMBER OF CYCLES=%3d\n", keywrd, NCYC); end
    @goto label_10

    # =======================================================================
    # OPTION 12 — TFIXAREA  (label_2200) verified against initre.f 818-822
    # =======================================================================
    @label label_2200
    if lnotbk[1]; global TFPA = array[1]; end
    if lkecho; @printf(io_units[JOSTND], "\n%-8s   TOTAL FIXED PLOT AREA=%10.3f\n", keywrd, TFPA); end
    @goto label_10

    # =======================================================================
    # OPTION 13 — GROWTH  (label_2300) verified against initre.f 826-855
    # =======================================================================
    @label label_2300
    if lnotbk[1]; global IDG   = Int32(array[1]); end
    if lnotbk[2] && array[2] > Float32(0.0); global FINT  = array[2]; end
    if lnotbk[3]; global IHTG  = Int32(array[3]); end
    if lnotbk[4] && array[4] > Float32(0.0); global FINTH = array[4]; end
    if lnotbk[5] && array[5] > Float32(0.0); global FINTM = array[5]; end
    if lkecho
        @printf(io_units[JOSTND], "\n%-8s   DIAMETER GROWTH DATA TYPE CODE= %1d, %4.1f YEAR MEASUREMENT PERIOD;\n           HEIGHT GROWTH DATA TYPE CODE  = %1d, %4.1f YEAR MEASUREMENT PERIOD;\n           MORTALITY MEASUREMENT PERIOD  =%4.1f\n",
            keywrd, IDG, FINT, IHTG, FINTH, FINTM)
    end
    @goto label_10

    # =======================================================================
    # OPTION 14 — STDINFO  (label_2400) verified against initre.f 859-942
    # Stand information: KODFOR, FORKOD, HABTYP, IAGE, ASPECT, SLOPE, ...
    # =======================================================================
    @label label_2400
    global KODFOR = Int32(array[1])
    FORKOD()
    if lnotbk[7]
        global CPVREF = @sprintf("%10d", Int32(array[7]))
    else
        global CPVREF = "          "
    end
    if lnotbk[2]
        global KODTYP = Int32(array[2])
        global ICL5   = KODTYP
        HABTYP(kard[2], array[2])
        if ICL5 <= Int32(0); global ICL5 = KODTYP; end
    end
    if lnotbk[3]; global IAGE   = Int32(array[3]); end
    if lnotbk[4]; global ASPECT = array[4]; end
    if lnotbk[5]; global SLOPE  = array[5]; end
    if lnotbk[6] && array[6] > Float32(0.0); global ELEV = array[6]; end
    if VARACD == "SN" && lnotbk[2] && !lnotbk[8]
        global ECOREG = kard[2]
    end
    if lnotbk[8]
        global ECOREG = lstrip(kard[8])
        NVB_REGION_CHECK()
    end
    if lnotbk[9]
        global ISTDORG = Int32(array[9])
        if ISTDORG > Int32(1) || ISTDORG < Int32(0)
            ERRGRO(true, Int32(42))
            @printf(io_units[JOSTND], "           STDINFO FIELD 9, STAND ORIGIN CODE OF %3d INVALID.  DEFAULT CODE OF 0 (NATURAL ORIGIN) WILL BE USED.\n", ISTDORG)
            global ISTDORG = Int32(0)
        end
    end
    if lkecho
        if VARACD == "CR" || VARACD == "UT" || VARACD == "TT" || VARACD == "WS"
            @printf(io_units[JOSTND], "\n%-8s   FOREST-LOCATION CODE=%6d; HABITAT TYPE=%-10s (CODE %3d); AGE=%5d; ASPECT AZIMUTH IN DEGREES= %4.0f;\n            SLOPE= %4.0f%%;  ELEVATION(100'S FEET)=%5.1f; REFERENCE CODE= %-4s; ECOREGION= %-10s; STAND ORIGIN=%2d\n",
                keywrd, KODFOR, strip(kard[2]), KODTYP, IAGE, ASPECT, SLOPE, ELEV, strip(CPVREF), strip(ECOREG), ISTDORG)
        elseif VARACD == "AK"
            @printf(io_units[JOSTND], "\n%-8s   FOREST-LOCATION CODE=%8d; HABITAT TYPE=%3d; AGE=%5d; ASPECT AZIMUTH IN DEGREES= %4.0f; SLOPE= %4.0f%%\n           ELEVATION(100'S FEET)=%5.1f; REFERENCE CODE= %-4s; ECOREGION= %-10s; STAND ORIGIN=%2d\n",
                keywrd, KODFOR, KODTYP, IAGE, ASPECT, SLOPE, ELEV, strip(CPVREF), strip(ECOREG), ISTDORG)
        elseif VARACD == "SN"
            @printf(io_units[JOSTND], "\n%-8s   FOREST-LOCATION CODE=%8d; ECOLOGICAL UNIT=%-10s; AGE=%5d; ASPECT AZIMUTH IN DEGREES= %4.0f; SLOPE= %4.0f%%\n           ELEVATION(100'S FEET)=%5.1f; REFERENCE CODE= %-4s; ECOREGION= %-10s; STAND ORIGIN=%2d\n",
                keywrd, KODFOR, strip(PCOM), IAGE, ASPECT, SLOPE, ELEV, strip(CPVREF), strip(ECOREG), ISTDORG)
        else
            @printf(io_units[JOSTND], "\n%-8s   FOREST-LOCATION CODE=%8d; HABITAT TYPE=%3d; AGE=%5d; ASPECT AZIMUTH IN DEGREES= %4.0f; SLOPE= %4.0f%%\n           ELEVATION(100'S FEET)=%5.1f; REFERENCE CODE= %-4s; ECOREGION= %-10s; STAND ORIGIN=%2d\n",
                keywrd, KODFOR, KODTYP, IAGE, ASPECT, SLOPE, ELEV, strip(CPVREF), strip(ECOREG), ISTDORG)
        end
    end
    @goto label_10

    # =======================================================================
    # OPTION 15 — STDIDENT  (label_2500) verified against initre.f 946-974
    # Stand identifier: reads supplemental record; NPLT (first word) + ITITLE
    # =======================================================================
    @label label_2500
    if lkecho; @printf(io_units[JOSTND], "\n%-8s\n", keywrd); end
    record = rpad(readline(io_units[IREAD]), 250)[1:250]
    global IRECNT = IRECNT + Int32(1)
    # Find first non-blank character
    i1 = Int32(0)
    for i_k in Int32(1):Int32(26)
        if record[i_k] != ' '
            i1 = i_k
            break
        end
    end
    i2 = Int32(26)
    if i1 > Int32(0)
        for i_k in i1:Int32(26)
            if record[i_k] == ' '
                i2 = i_k
                break
            end
        end
        raw_nplt = record[i1:i2]
        global NPLT = length(raw_nplt) <= 26 ? rpad(raw_nplt, 26) : raw_nplt[1:26]
    else
        global NPLT = rpad(" ", 26)
    end
    raw_line = length(record) >= i2+1 ? record[i2+1:end] : ""
    global ITITLE = length(raw_line) >= 72 ? raw_line[1:72] : rpad(raw_line, 72)
    if lkecho; @printf(io_units[JOSTND], "           STAND ID= %-26s        %-72s\n", NPLT, ITITLE); end
    @goto label_10

    # =======================================================================
    # OPTION 16 — INVYEAR  (label_2600) verified against initre.f 978-982
    # =======================================================================
    @label label_2600
    if lnotbk[1]; IY[1] = Int32(array[1]); end
    if lkecho; @printf(io_units[JOSTND], "\n%-8s   INVENTORY YEAR=%5d\n", keywrd, IY[1]); end
    @goto label_10

    # =======================================================================
    # OPTION 17 — TREELIST  (label_2700) verified against initre.f 986-1013
    # Tree list output: OPNEW act=80, NP=2..6
    # =======================================================================
    @label label_2700
    idt = Int32(1)
    if lnotbk[1]; idt = Int32(array[1]); end
    if !lnotbk[2]; array[2] = Float32(JOLIST); end
    np = Int32(2)
    if lnotbk[4]; np = Int32(3); end
    if lnotbk[5] && array[5] > Float32(0.0); np = Int32(4); end
    if lnotbk[6] && array[6] > Float32(0.0); np = Int32(5); end
    if lnotbk[7] && array[7] > Float32(0.0) && (idt == Int32(0) || idt == Int32(1)) &&
       !(lnotbk[4] && array[4] == Float32(1.0))
        np = Int32(6)
    end
    kode = OPNEW(idt, Int32(80), np, array)
    if kode > Int32(0); @goto label_10; end
    if lkecho
        @printf(io_units[JOSTND], "\n%-8s   DATE/CYCLE=%5d; DATA SET REFERENCE NUMBER =%4.0f; HEADING SUPPRESSION CODE =%3.0f\n           (0=WITH HEADING, OTHER VALUES=SUPPRESS HEADING).\n",
            keywrd, idt, array[2], array[3])
        if np >= Int32(3) && array[4] == Float32(1.0); @printf(io_units[JOSTND], "           CYCLE ZERO TREELIST SUPPRESSED.\n"); end
        if np >= Int32(3) && array[4] == Float32(2.0); @printf(io_units[JOSTND], "           CYCLE ONE TREELIST SUPPRESSED.\n"); end
        if array[5] > Float32(0.0); @printf(io_units[JOSTND], "           TREELIST WILL REPORT DEAD TREE STATISTICS.\n"); end
        if np == Int32(6); @printf(io_units[JOSTND], "           ESTIMATED DIAMETER GROWTHS WILL BE PRINTED ON THE CYCLE 0 TREELIST FOR TREES WITH NO MEASURED DIAMETER GROWTH.\n"); end
    end
    @goto label_10

    # =======================================================================
    # OPTION 18 — REWIND  (label_2800) verified against initre.f 1017-1022
    # =======================================================================
    @label label_2800
    iunit = ISTDAT
    if array[1] >= Float32(1.0); iunit = Int32(array[1]); end
    if lkecho; @printf(io_units[JOSTND], "\n%-8s   DATA SET REFERENCE NUMBER=%3d\n", keywrd, iunit); end
    if haskey(io_units, iunit); seekstart(io_units[iunit]); end
    @goto label_10

    # =======================================================================
    # OPTION 19 — NOSUM  (label_2900) verified against initre.f 1026-1030
    # =======================================================================
    @label label_2900
    if lkecho; @printf(io_units[JOSTND], "\n%-8s   NO SUMMARY OUTPUT WILL BE WRITTEN.\n", keywrd); end
    global LSUMRY = false
    @goto label_10

    # =======================================================================
    # OPTION 20 — DEBUG  (label_3000) verified against initre.f 1034-1055
    # =======================================================================
    @label label_3000
    if lnotbk[3]; global JOSTND = Int32(array[3]); end
    idbcyc = Int32(array[1])
    if idbcyc < Int32(0) || idbcyc > Int32(MAXCYC); idbcyc = Int32(0); end
    if idbcyc == Int32(0)
        if lkecho; @printf(io_units[JOSTND], "\n%-8s   DEBUG, ALL CYCLES. \n", keywrd); end
    else
        if lkecho; @printf(io_units[JOSTND], "\n%-8s   DEBUG, CYCLE=%2d. \n", keywrd, idbcyc); end
    end
    if lnotbk[2]
        irc = DBPRSE(IREAD, record, JOSTND, idbcyc)
        if irc == Int32(1); @goto label_80; end
    else
        DBALL(idbcyc)
    end
    DBCHK(debug, "INITRE", Int32(6), Int32(0))
    @goto label_10

    # =======================================================================
    # OPTION 21 — ECHOSUM  (label_3100) verified against initre.f 1059-1065
    # =======================================================================
    @label label_3100
    global LSUMRY = true
    if array[1] >= Float32(1.0); global JOSUM = Int32(array[1]); end
    if lkecho; @printf(io_units[JOSTND], "\n%-8s   SUMMARY OUTPUT WILL BE WRITTEN TO FILE REFERENCED BY NUMBER %2d\n", keywrd, JOSUM); end
    @goto label_10

    # =======================================================================
    # OPTION 22 — ADDFILE  (label_3200) verified against initre.f 1069-1078
    # =======================================================================
    @label label_3200
    if !lnotbk[1]
        KEYDMP(JOSTND, IRECNT, keywrd, array, kard)
        ERRGRO(true, Int32(4))
        @goto label_10
    end
    global ICL1  = IREAD
    global IREAD = Int32(array[1])
    if lkecho; @printf(io_units[JOSTND], "\n%-8s   DATA SET REFERENCE NUMBER=%3d\n", keywrd, IREAD); end
    @goto label_10

    # =======================================================================
    # OPTION 23 — THINAUTO  (label_3300) verified against initre.f 1082-1113
    # =======================================================================
    @label label_3300
    idt = Int32(1)
    if lnotbk[1]; idt = Int32(array[1]); end
    if iprmpt > Int32(0)
        if iprmpt != Int32(2)
            KEYDMP(JOSTND, IRECNT, keywrd, array, kard)
            ERRGRO(true, Int32(25))
        else
            kode = OPNEWC(JOSTND, IREAD, idt, Int32(222), keywrd, kard, iprmpt, IRECNT, ICYC)
            irtncd = fvsGetRtnCode()
            if irtncd != Int32(0); return; end
        end
        @goto label_10
    end
    prms[1] = AUTMIN
    prms[2] = AUTMAX
    prms[3] = EFF
    if lnotbk[2]; prms[1] = array[2]; end
    if lnotbk[3]; prms[2] = array[3]; end
    if lnotbk[4]; prms[3] = array[4]; end
    kode = OPNEW(idt, Int32(222), Int32(3), prms)
    if kode > Int32(0); @goto label_10; end
    if lkecho
        @printf(io_units[JOSTND], "\n%-8s   DATE/CYCLE=%5d; MIN=%8.1f; MAX=%8.1f PERCENT OF FULL STOCKING;  PROPORTION OF SELECTED TREES REMOVED=%6.3f\n",
            keywrd, idt, prms[1], prms[2], prms[3])
    end
    @goto label_10

    # =======================================================================
    # OPTION 24 — THINBTA  (label_3400) → shared label_4090, ICFLAG=223
    # =======================================================================
    @label label_3400
    global ICFLAG = Int32(223)
    @goto label_4090

    # =======================================================================
    # OPTION 25 — THINATA  (label_3500) → shared label_4090, ICFLAG=224
    # =======================================================================
    @label label_3500
    global ICFLAG = Int32(224)
    @goto label_4090

    # =======================================================================
    # OPTION 26 — THINBBA  (label_3600) → shared label_4090, ICFLAG=225
    # =======================================================================
    @label label_3600
    global ICFLAG = Int32(225)
    @goto label_4090

    # =======================================================================
    # OPTION 27 — THINABA  (label_3700) → shared label_4090, ICFLAG=226
    # =======================================================================
    @label label_3700
    global ICFLAG = Int32(226)
    @goto label_4090

    # =======================================================================
    # OPTION 28 — THINPRSC  (label_3800) → shared label_3805, ICFLAG=227
    # =======================================================================
    @label label_3800
    global ICFLAG = Int32(227)
    @goto label_3805

    # =======================================================================
    # OPTION 29 — THINDBH  (label_3900) → shared label_3901, ICFLAG=228
    # =======================================================================
    @label label_3900
    global ICFLAG = Int32(228)
    @goto label_3901

    # =======================================================================
    # OPTION 30 — xSALVAGE  (label_4000) → shared label_3805, ICFLAG=229
    # =======================================================================
    @label label_4000
    global ICFLAG = Int32(229)
    @goto label_3805

    # =======================================================================
    # OPTION 31 — SPLABEL  (label_4010)
    # =======================================================================
    @label label_4010
    kode = LBSPLR(keywrd, JOSTND, IREAD, IRECNT, record, lkecho)
    if kode >= Int32(1); @goto label_80; end
    @goto label_10

    # =======================================================================
    # OPTION 32 — AGPLABEL  (label_4020)
    # =======================================================================
    @label label_4020
    kode = LBAGLR(keywrd, JOSTND, IREAD, IRECNT, record)
    if kode >= Int32(1); @goto label_80; end
    @goto label_10

    # =======================================================================
    # OPTION 33 — COMPUTE  (label_4030)
    # Event Monitor user variable evaluation: EVUSRV
    # =======================================================================
    @label label_4030
    EVUSRV(record, keywrd, array, lnotbk, IREAD, JOSTND, debug, IRECNT)
    irtncd = fvsGetRtnCode()
    if irtncd != Int32(0); return; end
    @goto label_10

    # =======================================================================
    # OPTION 34 — FERTILIZE  (label_4040)
    # =======================================================================
    @label label_4040
    FFIN(JOSTND, IRECNT, keywrd, array, lnotbk, kard, IPRMPT, ICYC, IREAD, lkecho)
    @goto label_10

    # =======================================================================
    # OPTION 35 — THINHT  (label_4050) → shared label_3901, ICFLAG=232
    # =======================================================================
    @label label_4050
    global ICFLAG = Int32(232)
    @goto label_3901

    # =======================================================================
    # OPTION 36 — STATS  (label_4060)
    # =======================================================================
    @label label_4060
    global LSTATS = true
    if lnotbk[1]; global ALPHA_V = array[1]; end
    if ALPHA_V <= Float32(0.0) || ALPHA_V >= Float32(1.0)
        if lkecho; @printf(io_units[JOSTND], "%11s   SPECIFIED PROBABILITY LEVEL IS INVALID; 0.05 WILL BE USED.\n", ""); end
        global ALPHA_V = Float32(0.05)
    end
    if lkecho; @printf(io_units[JOSTND], "\n%-8s   STATISTICAL DESCRIPTION OF INPUT DATA WILL BE PROVIDED; CONFIDENCE LIMITS AT %4.2f LEVEL.\n", keywrd, ALPHA_V); end
    @goto label_10

    # =======================================================================
    # OPTION 37 — TOPKILL  (label_4070) → shared label_4081, IACT=111
    # =======================================================================
    @label label_4070
    iact = Int32(111)
    @goto label_4081

    # =======================================================================
    # OPTION 38 — HTGSTOP  (label_4080) → shared label_4081, IACT=110
    # =======================================================================
    @label label_4080
    iact = Int32(110)
    @goto label_4081

    # =======================================================================
    # OPTION 39 — MCFDLN  (label_4100)
    # Cubic-foot defect line: LCVOLS=true; LFIANVB check; SDEFLN
    # =======================================================================
    @label label_4100
    if LFIANVB
        if lkecho; @printf(io_units[JOSTND], "\n%-8s   KEYWORD REQUEST HAS BEEN RECOGNIZED BUT HAS \n%11s   BEEN DEACTIVIATED BY A PREVIOUS CALL TO USE FIAVBC \n%11s   FOR COMPUTATION OF CUBIC FOOT VOLUMES\n", keywrd, "", ""); end
        ERRGRO(true, Int32(50))
        @goto label_10
    end
    global LCVOLS = true
    is = SDEFLN(lnotbk, array, keywrd, CFLA0, CFLA1, kard)
    if is == Int32(-999); @goto label_10; end
    if lkecho
        if VARACD ∈ ("CS", "LS", "NE", "SN")
            @printf(io_units[JOSTND], "%12s   DEFECT CORRECTIONS WILL BE APPLIED TO PULPWOOD VOLUME.\n", "")
        else
            @printf(io_units[JOSTND], "%12s   DEFECT CORRECTIONS WILL BE APPLIED TO MERCHANTABLE CUBIC FOOT VOLUME.\n", "")
        end
    end
    @goto label_10

    # =======================================================================
    # OPTION 40 — BFFDLN  (label_4200)
    # Board-foot defect line: LBVOLS=true; SDEFLN
    # =======================================================================
    @label label_4200
    if LFIANVB
        if lkecho; @printf(io_units[JOSTND], "\n%-8s   KEYWORD REQUEST HAS BEEN RECOGNIZED. \n%12s   DUE TO PREVIOUS REQUEST FOR FIAVBC, MODIFICATIONS WILL BE MADE TO BOARD FOOT VOLUMES ONLY.\n", keywrd, ""); end
        ERRGRO(true, Int32(51))
    end
    global LBVOLS = true
    is = SDEFLN(lnotbk, array, keywrd, BFLA0, BFLA1, kard)
    if is == Int32(-999); @goto label_10; end
    if lkecho
        if VARACD ∈ ("CS", "LS", "NE", "SN")
            @printf(io_units[JOSTND], "%12s   DEFECT CORRECTIONS WILL BE APPLIED TO SAWLOG VOLUME.\n", "")
        else
            @printf(io_units[JOSTND], "%12s   DEFECT CORRECTIONS WILL BE APPLIED TO BOARD FOOT VOLUME.\n", "")
        end
    end
    @goto label_10

    # =======================================================================
    # OPTION 41 — MCDEFECT  (label_4300)
    # Cubic-foot defect proportions: CFDEFT 2D array; SDEFET(215) if date present
    # =======================================================================
    @label label_4300
    if LFIANVB
        if lkecho; @printf(io_units[JOSTND], "\n%-8s   KEYWORD REQUEST HAS BEEN RECOGNIZED BUT HAS BEEN DEACTIVIATED BY A PREVIOUS CALL TO USE FIAVBC FOR COMPUTATION OF CUBIC FOOT VOLUMES\n", keywrd); end
        ERRGRO(true, Int32(50))
        @goto label_10
    end
    global LCVOLS = true
    if lnotbk[1] && array[1] > Float32(0.0)
        SDEFET(lnotbk, array, keywrd, LOPEVN, Int32(215), kard, IPRMPT)
        irtncd = fvsGetRtnCode()
        if irtncd != Int32(0); return; end
        @goto label_10
    end
    is = SPDECD(Int32(2), NSP, JOSTND, IRECNT, keywrd, array, kard)
    if is == Int32(-999); @goto label_10; end
    if is < Int32(0)
        igrp = -is
        iulim = ISPGRP(igrp, Int32(1)) + Int32(1)
        for ig in Int32(2):iulim
            igsp = ISPGRP(igrp, ig)
            if lnotbk[3]; CFDEFT[2, igsp] = array[3]; end
            if lnotbk[4]; CFDEFT[3, igsp] = array[4]; end
            if lnotbk[5]; CFDEFT[4, igsp] = array[5]; end
            if lnotbk[6]; CFDEFT[5, igsp] = array[6]; end
            if lnotbk[7]; CFDEFT[6, igsp] = array[7]; CFDEFT[7, igsp] = array[7]; CFDEFT[8, igsp] = array[7]; CFDEFT[9, igsp] = array[7]; end
        end
        ilen = ISPGRP(-is, Int32(92))
        sp_str = kard[2][1:min(Int(ilen), length(kard[2]))]
        if lkecho; @printf(io_units[JOSTND], "\n%-8s%12s   CF DEFECT PROPORTIONS FOR GROUP %s (CODE=%3d): 5\"=%6.2f 10\"=%6.2f 15\"=%6.2f 20\"=%6.2f 25+\"=%6.2f\n", keywrd, "", sp_str, is, array[3], array[4], array[5], array[6], array[7]); end
    elseif is == Int32(0)
        for isp in Int32(1):MAXSP
            if lnotbk[3]; CFDEFT[2, isp] = array[3]; end
            if lnotbk[4]; CFDEFT[3, isp] = array[4]; end
            if lnotbk[5]; CFDEFT[4, isp] = array[5]; end
            if lnotbk[6]; CFDEFT[5, isp] = array[6]; end
            if lnotbk[7]; CFDEFT[6, isp] = array[7]; CFDEFT[7, isp] = array[7]; CFDEFT[8, isp] = array[7]; CFDEFT[9, isp] = array[7]; end
        end
        if lkecho; @printf(io_units[JOSTND], "\n%-8s%12s   CF DEFECT PROPORTIONS FOR ALL SPECIES: 5\"=%6.2f 10\"=%6.2f 15\"=%6.2f 20\"=%6.2f 25+\"=%6.2f\n", keywrd, "", array[3], array[4], array[5], array[6], array[7]); end
    else
        if lnotbk[3]; CFDEFT[2, is] = array[3]; end
        if lnotbk[4]; CFDEFT[3, is] = array[4]; end
        if lnotbk[5]; CFDEFT[4, is] = array[5]; end
        if lnotbk[6]; CFDEFT[5, is] = array[6]; end
        if lnotbk[7]; CFDEFT[6, is] = array[7]; CFDEFT[7, is] = array[7]; CFDEFT[8, is] = array[7]; CFDEFT[9, is] = array[7]; end
        sp_str = kard[2][1:min(3, length(kard[2]))]
        if lkecho; @printf(io_units[JOSTND], "\n%-8s%12s   CF DEFECT PROPORTIONS FOR SPECIES %s (CODE=%3d): 5\"=%6.2f 10\"=%6.2f 15\"=%6.2f 20\"=%6.2f 25+\"=%6.2f\n", keywrd, "", sp_str, is, array[3], array[4], array[5], array[6], array[7]); end
    end
    @goto label_10

    # =======================================================================
    # OPTION 42 — BFDEFECT  (label_4400)
    # Board-foot defect proportions: BFDEFT 2D array; SDEFET(216) if date present
    # =======================================================================
    @label label_4400
    global LBVOLS = true
    if lnotbk[1] && array[1] > Float32(0.0)
        SDEFET(lnotbk, array, keywrd, LOPEVN, Int32(216), kard, IPRMPT)
        irtncd = fvsGetRtnCode()
        if irtncd != Int32(0); return; end
        @goto label_10
    end
    is = SPDECD(Int32(2), NSP, JOSTND, IRECNT, keywrd, array, kard)
    if is == Int32(-999); @goto label_10; end
    if is < Int32(0)
        igrp = -is
        iulim = ISPGRP(igrp, Int32(1)) + Int32(1)
        for ig in Int32(2):iulim
            igsp = ISPGRP(igrp, ig)
            if lnotbk[3]; BFDEFT[2, igsp] = array[3]; end
            if lnotbk[4]; BFDEFT[3, igsp] = array[4]; end
            if lnotbk[5]; BFDEFT[4, igsp] = array[5]; end
            if lnotbk[6]; BFDEFT[5, igsp] = array[6]; end
            if lnotbk[7]; BFDEFT[6, igsp] = array[7]; BFDEFT[7, igsp] = array[7]; BFDEFT[8, igsp] = array[7]; BFDEFT[9, igsp] = array[7]; end
        end
        ilen = ISPGRP(-is, Int32(92))
        sp_str = kard[2][1:min(Int(ilen), length(kard[2]))]
        if lkecho; @printf(io_units[JOSTND], "\n%-8s%12s   BF DEFECT PROPORTIONS FOR GROUP %s (CODE=%3d): 5\"=%6.2f 10\"=%6.2f 15\"=%6.2f 20\"=%6.2f 25+\"=%6.2f\n", keywrd, "", sp_str, is, array[3], array[4], array[5], array[6], array[7]); end
    elseif is == Int32(0)
        for isp in Int32(1):MAXSP
            if lnotbk[3]; BFDEFT[2, isp] = array[3]; end
            if lnotbk[4]; BFDEFT[3, isp] = array[4]; end
            if lnotbk[5]; BFDEFT[4, isp] = array[5]; end
            if lnotbk[6]; BFDEFT[5, isp] = array[6]; end
            if lnotbk[7]; BFDEFT[6, isp] = array[7]; BFDEFT[7, isp] = array[7]; BFDEFT[8, isp] = array[7]; BFDEFT[9, isp] = array[7]; end
        end
        if lkecho; @printf(io_units[JOSTND], "\n%-8s%12s   BF DEFECT PROPORTIONS FOR ALL SPECIES: 5\"=%6.2f 10\"=%6.2f 15\"=%6.2f 20\"=%6.2f 25+\"=%6.2f\n", keywrd, "", array[3], array[4], array[5], array[6], array[7]); end
    else
        if lnotbk[3]; BFDEFT[2, is] = array[3]; end
        if lnotbk[4]; BFDEFT[3, is] = array[4]; end
        if lnotbk[5]; BFDEFT[4, is] = array[5]; end
        if lnotbk[6]; BFDEFT[5, is] = array[6]; end
        if lnotbk[7]; BFDEFT[6, is] = array[7]; BFDEFT[7, is] = array[7]; BFDEFT[8, is] = array[7]; BFDEFT[9, is] = array[7]; end
        sp_str = kard[2][1:min(3, length(kard[2]))]
        if lkecho; @printf(io_units[JOSTND], "\n%-8s%12s   BF DEFECT PROPORTIONS FOR SPECIES %s (CODE=%3d): 5\"=%6.2f 10\"=%6.2f 15\"=%6.2f 20\"=%6.2f 25+\"=%6.2f\n", keywrd, "", sp_str, is, array[3], array[4], array[5], array[6], array[7]); end
    end
    @goto label_10

    # =======================================================================
    # OPTION 43 — VOLUME  (label_4500)
    # Cubic-foot merchantability standards: LCVOLS; deprecated method check;
    # SPDECD field 2; IS<0/0/>0 branches; scheduled case calls OPNEW(217)
    # =======================================================================
    @label label_4500
    if LFIANVB
        if lkecho; @printf(io_units[JOSTND], "\n%-8s   KEYWORD REQUEST HAS BEEN RECOGNIZED BUT HAS BEEN DEACTIVIATED BY A PREVIOUS CALL TO USE FIAVBC FOR COMPUTATION OF CUBIC FOOT VOLUMES\n", keywrd); end
        ERRGRO(true, Int32(49))
        @goto label_10
    end
    if Int32(array[7]) ∈ (Int32(1),Int32(2),Int32(3),Int32(4),Int32(7),Int32(8))
        if lkecho; @printf(io_units[JOSTND], "\n%-8s   A DEPRECATED VOLUME CALCULATION METHOD (VOLUME METHOD %6d) HAS BEEN REQUESTED.\n%12s   METHOD CODE 6 (NATIONAL VOLUME ESTIMATOR LIBRARY) WILL BE USED FOR COMPUTATION OF CUBIC FOOT VOLUMES\n", keywrd, Int32(array[7]), ""); end
        array[7] = Float32(6)
        ERRGRO(true, Int32(48))
    end
    global LCVOLS = true
    is = SPDECD(Int32(2), NSP, JOSTND, IRECNT, keywrd, array, kard)
    if is == Int32(-999); @goto label_10; end
    if lnotbk[1] && array[1] > Float32(0.0)
        idt = Int32(array[1])
        if is < Int32(0)
            igrp = -is
            ifsp = ISPGRP(igrp, Int32(2))
            if !lnotbk[3]; array[3] = DBHMIN[ifsp]; end
            if !lnotbk[4]; array[4] = TOPD[ifsp]; end
            if !lnotbk[5]; array[5] = STMP[ifsp]; end
            if !lnotbk[6]; array[6] = FRMCLS[ifsp]; end
            if !lnotbk[7]; array[7] = Float32(METHC[ifsp]); end
            if VARACD ∈ ("CS","LS","NE","SN")
                if !lnotbk[8]; array[8] = SCFMIND[ifsp]; end
                if !lnotbk[9]; array[9] = SCFTOPD[ifsp]; end
                if !lnotbk[10]; array[10] = SCFSTMP[ifsp]; end
            end
        elseif is == Int32(0)
            if !lnotbk[3]; array[3] = DBHMIN[1]; end
            if !lnotbk[4]; array[4] = TOPD[1]; end
            if !lnotbk[5]; array[5] = STMP[1]; end
            if !lnotbk[6]; array[6] = FRMCLS[1]; end
            if !lnotbk[7]; array[7] = Float32(METHC[1]); end
            if VARACD ∈ ("CS","LS","NE","SN")
                if !lnotbk[8]; array[8] = SCFMIND[1]; end
                if !lnotbk[9]; array[9] = SCFTOPD[1]; end
                if !lnotbk[10]; array[10] = SCFSTMP[1]; end
            end
            array[2] = Float32(0)
        else
            if !lnotbk[3]; array[3] = DBHMIN[is]; end
            if !lnotbk[4]; array[4] = TOPD[is]; end
            if !lnotbk[5]; array[5] = STMP[is]; end
            if !lnotbk[6]; array[6] = FRMCLS[is]; end
            if !lnotbk[7]; array[7] = Float32(METHC[is]); end
            if VARACD ∈ ("CS","LS","NE","SN")
                if !lnotbk[8]; array[8] = SCFMIND[is]; end
                if !lnotbk[9]; array[9] = SCFTOPD[is]; end
                if !lnotbk[10]; array[10] = SCFSTMP[is]; end
            end
        end
        kode = OPNEW(idt, Int32(217), Int32(9), view(array, 2:12))
        @goto label_10
    end
    if is < Int32(0)
        igrp = -is
        iulim = ISPGRP(igrp, Int32(1)) + Int32(1)
        for ig in Int32(2):iulim
            igsp = ISPGRP(igrp, ig)
            if lnotbk[3]; DBHMIN[igsp] = array[3]; end
            if lnotbk[4]; TOPD[igsp]   = array[4]; end
            if lnotbk[5]; STMP[igsp]   = array[5]; end
            if lnotbk[6]; FRMCLS[igsp] = array[6]; end
            if lnotbk[7]; METHC[igsp]  = Int32(array[7]); end
            if VARACD ∈ ("CS","LS","NE","SN")
                if lnotbk[8];  SCFMIND[igsp] = array[8]; end
                if lnotbk[9];  SCFTOPD[igsp] = array[9]; end
                if lnotbk[10]; SCFSTMP[igsp] = array[10]; end
            end
        end
    elseif is == Int32(0)
        for isp in Int32(1):MAXSP
            if lnotbk[3]; DBHMIN[isp] = array[3]; end
            if lnotbk[4]; TOPD[isp]   = array[4]; end
            if lnotbk[5]; STMP[isp]   = array[5]; end
            if lnotbk[6]; FRMCLS[isp] = array[6]; end
            if lnotbk[7]; METHC[isp]  = Int32(array[7]); end
            if VARACD ∈ ("CS","LS","NE","SN")
                if lnotbk[8];  SCFMIND[isp] = array[8]; end
                if lnotbk[9];  SCFTOPD[isp] = array[9]; end
                if lnotbk[10]; SCFSTMP[isp] = array[10]; end
            end
        end
    else
        if lnotbk[3]; DBHMIN[is] = array[3]; end
        if lnotbk[4]; TOPD[is]   = array[4]; end
        if lnotbk[5]; STMP[is]   = array[5]; end
        if lnotbk[6]; FRMCLS[is] = array[6]; end
        if lnotbk[7]; METHC[is]  = Int32(array[7]); end
        if VARACD ∈ ("CS","LS","NE","SN")
            if lnotbk[8];  SCFMIND[is] = array[8]; end
            if lnotbk[9];  SCFTOPD[is] = array[9]; end
            if lnotbk[10]; SCFSTMP[is] = array[10]; end
        end
    end
    if lkecho; @printf(io_units[JOSTND], "\n%-8s   MERCHANTABILITY STANDARDS UPDATED (IS=%3d)\n", keywrd, is); end
    @goto label_10

    # =======================================================================
    # OPTION 44 — BFVOLUME  (label_4600)
    # Board-foot merchantability standards: LBVOLS; deprecated check;
    # SPDECD field 2; IS<0/0/>0 branches; scheduled case calls OPNEW(218)
    # =======================================================================
    @label label_4600
    if Int32(array[7]) ∈ (Int32(1),Int32(2),Int32(3),Int32(4),Int32(7),Int32(8))
        if lkecho; @printf(io_units[JOSTND], "\n%-8s   A DEPRECATED BOARD FOOT VOLUME CALCULATION METHOD (VOLUME METHOD %6d) HAS BEEN REQUESTED.\n%12s   METHOD CODE 6 (NATIONAL VOLUME ESTIMATOR LIBRARY) WILL BE USED FOR COMPUTATION OF BOARD FOOT VOLUMES\n", keywrd, Int32(array[7]), ""); end
        array[7] = Float32(6)
        ERRGRO(true, Int32(47))
    end
    global LBVOLS = true
    is = SPDECD(Int32(2), NSP, JOSTND, IRECNT, keywrd, array, kard)
    if is == Int32(-999); @goto label_10; end
    if lnotbk[1] && array[1] > Float32(0.0)
        idt = Int32(array[1])
        if is < Int32(0)
            igrp = -is
            ifsp = ISPGRP(igrp, Int32(2))
            if !lnotbk[3]; array[3] = BFMIND[ifsp]; end
            if !lnotbk[4]; array[4] = BFTOPD[ifsp]; end
            if !lnotbk[5]; array[5] = BFSTMP[ifsp]; end
            if !lnotbk[6]; array[6] = FRMCLS[ifsp]; end
            if !lnotbk[7]; array[7] = Float32(METHB[ifsp]); end
        elseif is == Int32(0)
            if !lnotbk[3]; array[3] = BFMIND[1]; end
            if !lnotbk[4]; array[4] = BFTOPD[1]; end
            if !lnotbk[5]; array[5] = BFSTMP[1]; end
            if !lnotbk[6]; array[6] = FRMCLS[1]; end
            if !lnotbk[7]; array[7] = Float32(METHB[1]); end
            array[2] = Float32(0)
        else
            if !lnotbk[3]; array[3] = BFMIND[is]; end
            if !lnotbk[5]; array[5] = BFSTMP[is]; end
            if !lnotbk[6]; array[6] = FRMCLS[is]; end
            if !lnotbk[7]; array[7] = Float32(METHB[is]); end
        end
        kode = OPNEW(idt, Int32(218), Int32(6), view(array, 2:12))
        @goto label_10
    end
    if is < Int32(0)
        igrp = -is
        iulim = ISPGRP(igrp, Int32(1)) + Int32(1)
        for ig in Int32(2):iulim
            igsp = ISPGRP(igrp, ig)
            if lnotbk[3]; BFMIND[igsp]  = array[3]; end
            if lnotbk[4]; BFTOPD[igsp]  = array[4]; end
            if lnotbk[5]; BFSTMP[igsp]  = array[5]; end
            if lnotbk[6]; FRMCLS[igsp]  = array[6]; end
            if lnotbk[7]; METHB[igsp]   = Int32(array[7]); end
        end
    elseif is == Int32(0)
        for isp in Int32(1):MAXSP
            if lnotbk[3]; BFMIND[isp]  = array[3]; end
            if lnotbk[4]; BFTOPD[isp]  = array[4]; end
            if lnotbk[5]; BFSTMP[isp]  = array[5]; end
            if lnotbk[6]; FRMCLS[isp]  = array[6]; end
            if lnotbk[7]; METHB[isp]   = Int32(array[7]); end
        end
    else
        if lnotbk[3]; BFMIND[is]  = array[3]; end
        if lnotbk[4]; BFTOPD[is]  = array[4]; end
        if lnotbk[5]; BFSTMP[is]  = array[5]; end
        if lnotbk[6]; FRMCLS[is]  = array[6]; end
        if lnotbk[7]; METHB[is]   = Int32(array[7]); end
    end
    if lkecho; @printf(io_units[JOSTND], "\n%-8s   BF MERCHANTABILITY STANDARDS UPDATED (IS=%3d)\n", keywrd, is); end
    @goto label_10

    # =======================================================================
    # OPTION 45 — REGDMULT  (label_4700) → shared label_6005, I=96
    # =======================================================================
    @label label_4700
    i_mult = Int32(96)
    @goto label_6005

    # =======================================================================
    # OPTION 46 — COVER  (label_4800)
    # =======================================================================
    @label label_4800
    CVIN(keywrd, array, lnotbk, lkecho)
    irtncd = fvsGetRtnCode()
    if irtncd != Int32(0); return; end
    @goto label_10

    # =======================================================================
    # OPTION 47 — ESTAB  (label_4900)
    # =======================================================================
    @label label_4900
    if lkecho; @printf(io_units[JOSTND], "\n%-8s   REGENERATION ESTABLISHMENT OPTIONS:\n", keywrd); end
    ESIN(keywrd, array, lnotbk, kard, lkecho)
    irtncd = fvsGetRtnCode()
    if irtncd != Int32(0); return; end
    @goto label_10

    # =======================================================================
    # OPTION 48 — MINHARV  (label_5000)
    # Minimum harvest: OPNEWC/OPNEW act=200, 5 params (ARRAY(2..6))
    # =======================================================================
    @label label_5000
    idt = Int32(1)
    if lnotbk[1]; idt = Int32(array[1]); end
    if iprmpt > Int32(0)
        if iprmpt != Int32(2)
            KEYDMP(JOSTND, IRECNT, keywrd, array, kard)
            ERRGRO(true, Int32(25))
        else
            kode = OPNEWC(JOSTND, IREAD, idt, Int32(200), keywrd, kard, iprmpt, IRECNT, ICYC)
            irtncd = fvsGetRtnCode()
            if irtncd != Int32(0); return; end
        end
        @goto label_10
    end
    kode = OPNEW(idt, Int32(200), Int32(5), view(array, 2:12))
    if kode > Int32(0); @goto label_10; end
    if lkecho; @printf(io_units[JOSTND], "\n%-8s   DATE/CYCLE=%5d; CUTTING MUST EXCEED: %8.1f SQFT BASAL AREA, %8.1f TOTAL CUFT, %6.1f MERCH CUFT, %8.1f SAWLOG CUFT, AND %8.1f MERCH BDFT\n", keywrd, idt, array[2], array[3], array[4], array[5], array[6]); end
    @goto label_10

    # =======================================================================
    # OPTION 49 — SPECPREF  (label_5100)
    # Species preference: OPNEWC/OPNEW act=201; SPDECD field 2; need field 3
    # =======================================================================
    @label label_5100
    idt = Int32(1)
    if lnotbk[1]; idt = Int32(array[1]); end
    if iprmpt > Int32(0)
        if iprmpt != Int32(2)
            KEYDMP(JOSTND, IRECNT, keywrd, array, kard)
            ERRGRO(true, Int32(25))
        else
            kode = OPNEWC(JOSTND, IREAD, idt, Int32(201), keywrd, kard, iprmpt, IRECNT, ICYC)
            irtncd = fvsGetRtnCode()
            if irtncd != Int32(0); return; end
        end
        @goto label_10
    end
    is = SPDECD(Int32(2), NSP, JOSTND, IRECNT, keywrd, array, kard)
    if is == Int32(-999); @goto label_10; end
    if !lnotbk[3]
        KEYDMP(JOSTND, IRECNT, keywrd, array, kard)
        ERRGRO(true, Int32(4))
        @goto label_10
    end
    kode = OPNEW(idt, Int32(201), Int32(2), view(array, 2:12))
    if kode > Int32(0); @goto label_10; end
    ilen = Int32(3)
    if is < Int32(0); ilen = ISPGRP(-is, Int32(92)); end
    sp_str = kard[2][1:min(Int(ilen), length(kard[2]))]
    if lkecho; @printf(io_units[JOSTND], "\n%-8s   DATE/CYCLE=%5d; SPECIES= %s (CODE=%3d); THINNING SELECTION PRIORITY=%6.0f\n", keywrd, idt, sp_str, is, array[3]); end
    @goto label_10

    # =======================================================================
    # OPTION 50 — SPCODES  (label_5200)
    # Species codes: SPDECD field 1; IS<0 → error; IS=0 → read all JSP; IS>0 → read JSP(IS)
    # =======================================================================
    @label label_5200
    is = SPDECD(Int32(1), NSP, JOSTND, IRECNT, keywrd, array, kard)
    if is < Int32(0)
        KEYDMP(JOSTND, IRECNT, keywrd, array, kard)
        ERRGRO(true, Int32(4))
        @goto label_10
    end
    if is == Int32(0)
        if lkecho; @printf(io_units[JOSTND], "\n%-8s   PREVIOUS CODES: (see listing)\n", keywrd); end
        if eof(io_units[IREAD]); @goto label_80; end
        raw_line = readline(io_units[IREAD])
        global IRECNT += Int32(1)
        for j in Int32(1):MAXSP
            sc = (j-1)*4 + 1
            ec = j*4
            if sc <= length(raw_line)
                JSP[j] = rpad(raw_line[sc:min(ec,length(raw_line))], 4)
            else
                JSP[j] = "    "
            end
        end
        if lkecho; @printf(io_units[JOSTND], "%12s   NEW CODES: (see listing)\n", ""); end
        if MORDAT; ERRGRO(true, Int32(7)); end
    else
        if lkecho; @printf(io_units[JOSTND], "\n%-8s   PREVIOUS CODE FOR SPECIES= %s (CODE=%3d) IS= '%s'\n", keywrd, kard[1][1:3], is, JSP[is]); end
        if eof(io_units[IREAD]); @goto label_80; end
        raw_line = readline(io_units[IREAD])
        global IRECNT += Int32(1)
        JSP[is] = length(raw_line) >= 4 ? rpad(raw_line[1:4], 4) : rpad(raw_line, 4)
        if lkecho; @printf(io_units[JOSTND], "%17s   NEW CODE FOR SPECIES= %s (CODE=%3d) IS= '%s'\n", "", kard[1][1:3], is, JSP[is]); end
        if MORDAT; ERRGRO(true, Int32(7)); end
    end
    @goto label_10

    # =======================================================================
    # OPTION 51 — NODEBUG  (label_5300)
    # =======================================================================
    @label label_5300
    DBINIT()
    debug = false
    if lkecho; @printf(io_units[JOSTND], "\n%-8s\n", keywrd); end
    @goto label_10

    # =======================================================================
    # OPTION 52 — CUTEFF  (label_5400)
    # Cutting effectiveness: EFF = ARRAY(1)
    # =======================================================================
    @label label_5400
    if lnotbk[1]; global EFF = array[1]; end
    if lkecho; @printf(io_units[JOSTND], "\n%-8s   PROPORTION OF SELECTED TREES REMOVED=%6.3f (REPLACES THE DEFAULT)\n", keywrd, EFF); end
    @goto label_10

    # =======================================================================
    # OPTION 53 — NOTRIPLE  (label_5500)
    # Disable tripling: NOTRIP = true
    # =======================================================================
    @label label_5500
    global NOTRIP = true
    if lkecho; @printf(io_units[JOSTND], "\n%-8s\n", keywrd); end
    @goto label_10

    # =======================================================================
    # OPTION 54 — READCORD  (label_5600)
    # Read DG correction terms: LDCOR2=true; ceil(MAXSP/8) records of 8F10.0
    # =======================================================================
    @label label_5600
    global LDCOR2 = true
    if lkecho; @printf(io_units[JOSTND], "\n%-8s   LARGE TREE DIAMETER GROWTH MODELS ARE MODIFIED WITH CORRECTION TERMS PRIOR TO CALIBRATION.\n", keywrd); end
    begin
        nrecs_cor2 = div(MAXSP - 1, 8) + 1   # ceil(MAXSP/8)
        cor2_idx = Int32(1)
        for _ in 1:nrecs_cor2
            if eof(io_units[IREAD]); @goto label_80; end
            raw_line = readline(io_units[IREAD])
            global IRECNT += Int32(1)
            for j in 1:8
                if cor2_idx <= MAXSP
                    sc = (j-1)*10 + 1
                    ec = j*10
                    s = sc <= length(raw_line) ? strip(raw_line[sc:min(ec,length(raw_line))]) : "0"
                    COR2[cor2_idx] = isempty(s) ? Float32(0) : parse(Float32, s)
                    cor2_idx += Int32(1)
                end
            end
        end
    end
    if lkecho; @printf(io_units[JOSTND], "%12s   LARGE TREE DG CORRECTION TERMS BY SPECIES: (see listing)\n", ""); end
    @goto label_10

    # =======================================================================
    # OPTION 55 — REUSCORD  (label_5700)
    # Reuse correlation: LDCOR2=true (no re-read; correction terms already loaded)
    # =======================================================================
    @label label_5700
    if lkecho; @printf(io_units[JOSTND], "\n%-8s   LARGE TREE DIAMETER GROWTH MODELS ARE MODIFIED WITH CORRECTION TERMS PRIOR TO CALIBRATION.\n", keywrd); end
    global LDCOR2 = true
    @goto label_10

    # =======================================================================
    # OPTION 56 — NOCALIB  (label_5800)
    # Disable calibration: SPDECD; IS<0=group, IS=0=all, IS>0=single
    # =======================================================================
    @label label_5800
    is = SPDECD(Int32(1), NSP, JOSTND, IRECNT, keywrd, array, kard)
    if is == Int32(-999); @goto label_10; end
    if is < Int32(0)
        igrp = -is
        iulim = ISPGRP(igrp, Int32(1)) + Int32(1)
        for ig in Int32(2):iulim
            igsp = ISPGRP(igrp, ig)
            LDGCAL[igsp] = false
            LHTCAL[igsp] = false
        end
        ilen = ISPGRP(-is, Int32(92))
        sp_str = kard[1][1:min(Int(ilen), length(kard[1]))]
        if lkecho; @printf(io_units[JOSTND], "\n%-8s   CALIBRATION USING GROWTH DATA FROM TREE RECORDS WILL BE SUPPRESSED FOR GROUP %s (CODE=%3d)\n", keywrd, sp_str, is); end
    elseif is == Int32(0)
        for j in Int32(1):MAXSP
            LDGCAL[j] = false
            LHTCAL[j] = false
        end
        if lkecho; @printf(io_units[JOSTND], "\n%-8s   CALIBRATION USING GROWTH DATA FROM TREE RECORDS HAS BEEN SUPPRESSED FOR ALL SPECIES\n", keywrd); end
    else
        LDGCAL[is] = false
        LHTCAL[is] = false
        sp_str = kard[1][1:min(3, length(kard[1]))]
        if lkecho; @printf(io_units[JOSTND], "\n%-8s   CALIBRATION USING GROWTH DATA FROM TREE RECORDS WILL BE SUPPRESSED FOR SPECIES= %s (CODE=%3d)\n", keywrd, sp_str, is); end
    end
    @goto label_10

    # =======================================================================
    # OPTION 57 — DGSTDEV  (label_5900)
    # DG standard deviation bound: DGSD = ARRAY(1) if lnotbk[1]
    # =======================================================================
    @label label_5900
    if lnotbk[1]; global DGSD = array[1]; end
    if lkecho
        @printf(io_units[JOSTND], "\n%-8s   RANDOM VARIATION THAT IS ADDED TO PREDICTED DIAMETER GROWTH IS BOUNDED TO %4.1f STANDARD DEVIATIONS.\n", keywrd, DGSD)
        if DGSD < Float32(1.0)
            @printf(io_units[JOSTND], "%12s   NO RANDOM VARIATION IS ADDED TO DIAMETER GROWTH PREDICTIONS.\n", "")
        end
    end
    @goto label_10

    # =======================================================================
    # OPTION 58 — BAIMULT  (label_6000) → shared label_6005, I=91
    # =======================================================================
    @label label_6000
    i_mult = Int32(91)
    @goto label_6005

    # =======================================================================
    # OPTION 59 — MORTMULT  (label_6100)
    # =======================================================================
    @label label_6100
    global LMORT = true
    idt = Int32(1)
    if lnotbk[1]; idt = Int32(array[1]); end
    if iprmpt > Int32(0)
        if iprmpt != Int32(2)
            KEYDMP(JOSTND, IRECNT, keywrd, array, kard)
            ERRGRO(true, Int32(25))
        else
            kode = OPNEWC(JOSTND, IREAD, idt, Int32(94), keywrd, kard, iprmpt, IRECNT, ICYC)
            irtncd = fvsGetRtnCode()
            if irtncd != Int32(0); return; end
        end
        @goto label_10
    end
    is = SPDECD(Int32(2), NSP, JOSTND, IRECNT, keywrd, array, kard)
    if is == Int32(-999); @goto label_10; end
    if !lnotbk[3]; array[3] = Float32(1.0); end
    if !lnotbk[5]; array[5] = Float32(999.0); end
    array[6] = Float32(0.0)
    if array[4] >= array[5]
        ERRGRO(true, Int32(4))
        KEYDMP(JOSTND, IRECNT, keywrd, array, kard)
    else
        kode = OPNEW(idt, Int32(94), Int32(4), view(array, 2:12))
        if kode > Int32(0); @goto label_10; end
        ilen = Int32(3)
        if is < Int32(0); ilen = Int32(ISPGRP(-is, Int32(92))); end
        sp_str = kard[2][1:min(Int(ilen), length(kard[2]))]
        if lkecho
            @printf(io_units[JOSTND], "\n%-8s   DATE/CYCLE=%5d; SPECIES= %s (CODE= %3d); MULTIPLIER=%10.2f\n", keywrd, idt, sp_str, is, array[3])
            if array[3] > Float32(0.0)
                @printf(io_units[JOSTND], "            ONLY TREES GREATER THAN %7.2f AND LESS THAN %7.2f INCHES DBH ARE AFFECTED.\n", array[4], array[5])
            end
        end
    end
    @goto label_10

    # =======================================================================
    # OPTION 60 — NOHTDREG  (label_6200)
    # =======================================================================
    @label label_6200
    is = SPDECD(Int32(1), NSP, JOSTND, IRECNT, keywrd, array, kard)
    if is == Int32(-999); @goto label_10; end
    if is < Int32(0)
        igrp = -is
        iulim = Int32(ISPGRP(igrp, Int32(1))) + Int32(1)
        for ig in Int32(2):iulim
            igsp = Int32(ISPGRP(igrp, ig))
            LHTDRG[igsp] = lnotbk[2] && array[2] > Float32(0.0)
        end
        ilen = Int32(ISPGRP(-is, Int32(92)))
        sp_str = kard[1][1:min(Int(ilen), length(kard[1]))]
        if lnotbk[2] && array[2] > Float32(0.0)
            if lkecho; @printf(io_units[JOSTND], "\n%-8s   CALIBRATION OF HEIGHT-DIAMETER RELATIONSHIP WILL BE  INVOKED   FOR SPECIES= %s (CODE= %3d)\n", keywrd, sp_str, is); end
        else
            if lkecho; @printf(io_units[JOSTND], "\n%-8s   CALIBRATION OF HEIGHT-DIAMETER RELATIONSHIP WILL BE SUPPRESSED FOR SPECIES= %s (CODE= %3d)\n", keywrd, sp_str, is); end
        end
    elseif is == Int32(0)
        if lnotbk[2] && array[2] > Float32(0.0)
            for j in 1:MAXSP; LHTDRG[j] = true; end
            if lkecho; @printf(io_units[JOSTND], "\n%-8s   CALIBRATION OF HEIGHT-DIAMETER RELATIONSHIP WILL BE  INVOKED   FOR ALL SPECIES\n", keywrd); end
        else
            for j in 1:MAXSP; LHTDRG[j] = false; end
            if lkecho; @printf(io_units[JOSTND], "\n%-8s   CALIBRATION OF HEIGHT-DIAMETER RELATIONSHIP WILL BE SUPPRESSED FOR ALL SPECIES\n", keywrd); end
        end
    else
        ilen = Int32(3)
        sp_str = kard[1][1:min(Int(ilen), length(kard[1]))]
        if lnotbk[2] && array[2] > Float32(0.0)
            LHTDRG[is] = true
            if lkecho; @printf(io_units[JOSTND], "\n%-8s   CALIBRATION OF HEIGHT-DIAMETER RELATIONSHIP WILL BE  INVOKED   FOR SPECIES= %s (CODE= %3d)\n", keywrd, sp_str, is); end
        else
            LHTDRG[is] = false
            if lkecho; @printf(io_units[JOSTND], "\n%-8s   CALIBRATION OF HEIGHT-DIAMETER RELATIONSHIP WILL BE SUPPRESSED FOR SPECIES= %s (CODE= %3d)\n", keywrd, sp_str, is); end
        end
    end
    @goto label_10

    # =======================================================================
    # OPTION 61 — RANNSEED  (label_6300)
    # =======================================================================
    @label label_6300
    if lnotbk[1] && array[1] == Float32(0.0)
        GETSED(array)
    end
    RANSED(lnotbk[1], array[1])
    if lkecho; @printf(io_units[JOSTND], "\n%-8s   RANDOM SEED IS:%14.1f\n", keywrd, array[1]); end
    @goto label_10

    # =======================================================================
    # OPTION 62 — HTGMULT  (label_6400) → shared label_6005, I=92
    # =======================================================================
    @label label_6400
    i_mult = Int32(92)
    @goto label_6005

    # =======================================================================
    # OPTION 63 — CHEAPO  (label_6500)
    # =======================================================================
    @label label_6500
    if lnotbk[1]; global JOSUME = Int32(array[1]); end
    global LECBUG = lnotbk[6]
    global LECON = true
    if lkecho; @printf(io_units[JOSTND], "\n%-8s   DATA SET REFERENCE NUMBER=%3d\n", keywrd, JOSUME); end
    global LECON = true
    if LECBUG && lkecho; @printf(io_units[JOSTND], "            ECONOMIC SUMMARY DEBUG REQUESTED.  LECBUG=%2s\n", LECBUG ? " T" : " F"); end
    ECAVAL()
    @goto label_10

    # =======================================================================
    # OPTION 64 — NUMTRIP  (label_6600)
    # =======================================================================
    @label label_6600
    if lnotbk[1]; global ICL4 = Int32(array[1]); end
    if lkecho; @printf(io_units[JOSTND], "\n%-8s   NUMBER OF TRIPLES LIMITED TO%3d\n", keywrd, ICL4); end
    @goto label_10

    # =======================================================================
    # OPTION 65 — ENDFILE  (label_6700)
    # =======================================================================
    @label label_6700
    i_tmp = Int32(JOSUM)
    if array[1] >= Float32(1.0); i_tmp = Int32(array[1]); end
    if haskey(io_units, i_tmp)
        try; truncate(io_units[i_tmp], position(io_units[i_tmp])); catch; end
    end
    if lkecho; @printf(io_units[JOSTND], "\n%-8s   DATA SET REFERENCE NUMBER=%3d\n", keywrd, i_tmp); end
    @goto label_10

    # =======================================================================
    # OPTION 66 — BAMAX  (label_6800)
    # =======================================================================
    @label label_6800
    global LMORT = true
    if array[1] > Float32(0.0)
        global BAMAX = array[1]
        global LBAMAX = true
    end
    if lkecho; @printf(io_units[JOSTND], "\n%-8s   MAXIMUM BASAL AREA=%10.2f\n", keywrd, BAMAX); end
    @goto label_10

    # =======================================================================
    # OPTION 67 — READCORH  (label_6900)
    # =======================================================================
    @label label_6900
    global LHCOR2 = true
    if lkecho; @printf(io_units[JOSTND], "\n%-8s   LARGE TREE HEIGHT GROWTH MODELS ARE MODIFIED WITH CORRECTION TERMS PRIOR TO CALIBRATION.\n", keywrd); end
    begin
        nrecs_cor = div(MAXSP - 1, 8) + 1
        cor_idx = Int32(1)
        for _ in 1:nrecs_cor
            if eof(io_units[IREAD]); @goto label_80; end
            raw_line = readline(io_units[IREAD])
            global IRECNT += Int32(1)
            for j in 1:8
                if cor_idx <= MAXSP
                    sc = (j-1)*10+1; ec = j*10
                    s = sc <= length(raw_line) ? strip(raw_line[sc:min(ec,length(raw_line))]) : "0"
                    HCOR2[cor_idx] = isempty(s) ? Float32(0) : parse(Float32, s)
                    cor_idx += Int32(1)
                end
            end
        end
    end
    if lkecho
        @printf(io_units[JOSTND], "            LARGE TREE HEIGHT GROWTH MODEL CORRECTION TERMS BY SPECIES:\n")
        i_tmp = Int32(1)
        while i_tmp <= MAXSP
            iend = min(i_tmp + Int32(7), Int32(MAXSP))
            @printf(io_units[JOSTND], "            ")
            for j in i_tmp:iend
                sp2 = length(NSP[j,1]) >= 2 ? NSP[j,1][1:2] : rpad(NSP[j,1],2)
                if j == iend
                    @printf(io_units[JOSTND], "%2s =%5.2f", sp2, HCOR2[j])
                else
                    @printf(io_units[JOSTND], "%2s =%5.2f; ", sp2, HCOR2[j])
                end
            end
            @printf(io_units[JOSTND], "\n")
            i_tmp += Int32(8)
        end
    end
    @goto label_10

    # =======================================================================
    # OPTION 68 — REUSCORH  (label_7000)
    # =======================================================================
    @label label_7000
    global LHCOR2 = true
    if lkecho; @printf(io_units[JOSTND], "\n%-8s   LARGE TREE HEIGHT GROWTH MODELS ARE MODIFIED WITH CORRECTION TERMS PRIOR TO CALIBRATION.\n", keywrd); end
    @goto label_10

    # =======================================================================
    # OPTION 69 — MGMTID  (label_7100)
    # =======================================================================
    @label label_7100
    if lkecho; @printf(io_units[JOSTND], "\n%-8s\n", keywrd); end
    if eof(io_units[IREAD]); @goto label_80; end
    raw_line = readline(io_units[IREAD])
    global IRECNT += Int32(1)
    global MGMID = length(raw_line) >= 4 ? raw_line[1:4] : rpad(raw_line, 4)
    if lkecho; @printf(io_units[JOSTND], "            MANAGEMENT ID= %4s\n", MGMID); end
    @goto label_10

    # =======================================================================
    # OPTION 70 — REGHMULT  (label_7200) → shared label_6005, I=93
    # =======================================================================
    @label label_7200
    i_mult = Int32(93)
    @goto label_6005

    # =======================================================================
    # OPTION 71 — TCONDMLT  (label_7300)
    # =======================================================================
    @label label_7300
    idt = Int32(1)
    if lnotbk[1]; idt = Int32(array[1]); end
    if iprmpt > Int32(0)
        if iprmpt != Int32(2)
            KEYDMP(JOSTND, IRECNT, keywrd, array, kard)
            ERRGRO(true, Int32(25))
        else
            kode = OPNEWC(JOSTND, IREAD, idt, Int32(202), keywrd, kard, iprmpt, IRECNT, ICYC)
            irtncd = fvsGetRtnCode()
            if irtncd != Int32(0); return; end
        end
        @goto label_10
    end
    if !(lnotbk[2] || lnotbk[3] || lnotbk[4] || lnotbk[5] || lnotbk[6])
        KEYDMP(JOSTND, IRECNT, keywrd, array, kard)
        ERRGRO(true, Int32(4))
        @goto label_10
    end
    kode = OPNEW(idt, Int32(202), Int32(5), view(array, 2:12))
    if kode > Int32(0); @goto label_10; end
    if lkecho
        @printf(io_units[JOSTND], "\n%-8s   DATE/CYCLE=%5d; TREE SUBCLASS MULTIPLIER=%6.1f; SPECIAL TREE STATUS MULTIPLIER=%8.1f;\n            POINT BASAL AREA MULTIPLIER=%8.1f; POINT CCF MULTIPLIER=%8.1f; POINT TPA MULTIPLIER=%8.1f\n",
            keywrd, idt, array[2], array[3], array[4], array[5], array[6])
    end
    @goto label_10

    # =======================================================================
    # OPTION 72 — NOAUTOES  (label_7400)
    # =======================================================================
    @label label_7400
    ESNOAU(keywrd, lkecho)
    @goto label_10

    # =======================================================================
    # OPTION 73 — READCORR  (label_7500)
    # =======================================================================
    @label label_7500
    global LRCOR2 = true
    if lkecho; @printf(io_units[JOSTND], "\n%-8s   SMALL TREE HEIGHT GROWTH MODELS ARE MODIFIED WITH CORRECTION TERMS PRIOR TO CALIBRATION.\n", keywrd); end
    begin
        nrecs_cor = div(MAXSP - 1, 8) + 1
        cor_idx = Int32(1)
        for _ in 1:nrecs_cor
            if eof(io_units[IREAD]); @goto label_80; end
            raw_line = readline(io_units[IREAD])
            global IRECNT += Int32(1)
            for j in 1:8
                if cor_idx <= MAXSP
                    sc = (j-1)*10+1; ec = j*10
                    s = sc <= length(raw_line) ? strip(raw_line[sc:min(ec,length(raw_line))]) : "0"
                    RCOR2[cor_idx] = isempty(s) ? Float32(0) : parse(Float32, s)
                    cor_idx += Int32(1)
                end
            end
        end
    end
    if lkecho
        @printf(io_units[JOSTND], "            SMALL TREE HEIGHT GROWTH MODEL CORRECTION TERMS BY SPECIES:\n")
        i_tmp = Int32(1)
        while i_tmp <= MAXSP
            iend = min(i_tmp + Int32(7), Int32(MAXSP))
            @printf(io_units[JOSTND], "            ")
            for j in i_tmp:iend
                sp2 = length(NSP[j,1]) >= 2 ? NSP[j,1][1:2] : rpad(NSP[j,1],2)
                if j == iend
                    @printf(io_units[JOSTND], "%2s =%5.2f", sp2, RCOR2[j])
                else
                    @printf(io_units[JOSTND], "%2s =%5.2f; ", sp2, RCOR2[j])
                end
            end
            @printf(io_units[JOSTND], "\n")
            i_tmp += Int32(8)
        end
    end
    @goto label_10

    # =======================================================================
    # OPTION 74 — REUSCORR  (label_7600)
    # =======================================================================
    @label label_7600
    global LRCOR2 = true
    if lkecho; @printf(io_units[JOSTND], "\n%-8s   SMALL TREE HEIGHT GROWTH MODELS ARE MODIFIED WITH CORRECTION TERMS PRIOR TO CALIBRATION.\n", keywrd); end
    @goto label_10

    # =======================================================================
    # OPTION 75 — BRUST  (label_7700)
    # =======================================================================
    @label label_7700
    if lkecho; @printf(io_units[JOSTND], "\n%-8s   BLISTER RUST KEYWORDS:\n", keywrd); end
    BRIN(keywrd, array, lnotbk, lkecho)
    @goto label_10

    # =======================================================================
    # OPTION 76 — IF  (label_7800)
    # =======================================================================
    @label label_7800
    EVIF(keywrd, array, lnotbk, IRECNT, IREAD, record, kard, JOSTND, debug, lkecho)
    irtncd = fvsGetRtnCode()
    if irtncd != Int32(0); return; end
    @goto label_10

    # =======================================================================
    # OPTION 77 — SCREEN  (label_7900)
    # =======================================================================
    @label label_7900
    global LSCRN = true
    if lnotbk[1]; global JOSCRN = Int32(array[1]); end
    if lkecho; @printf(io_units[JOSTND], "\n%-8s   SUMMARY TABLE WILL BE PRINTED TO DATA SET REFERENCE NUMBER %5d AS RUN PROGRESSES.\n", keywrd, JOSCRN); end
    @goto label_10

    # =======================================================================
    # OPTION 78 — COMPRESS  (label_8000)
    # =======================================================================
    @label label_8000
    if !lnotbk[2]; array[2] = Float32(MAXTRE / 2); end
    if !lnotbk[3]; array[3] = Float32(50.0); end
    idt = Int32(1)
    if lnotbk[1]; idt = Int32(array[1]); end
    kode = OPNEW(idt, Int32(250), Int32(2), view(array, 2:12))
    if kode > Int32(0); @goto label_10; end
    if lkecho
        @printf(io_units[JOSTND], "\n%-8s   DATE/CYCLE=%5d; TARGET TREE RECORDS=%5.0f; FIND %5.0f PERCENT OF THE NEW RECORDS BY DEFINING\n            TREE-CLASS BOUNDARIES WHERE THE LARGEST DIFFERENCES ARE BETWEEN TREES.  DEFINE THE REMAINING\n            CLASSES BY SPLITTING THOSE WHICH HAVE THE LARGEST RANGES.\n",
            keywrd, idt, array[2], array[3])
    end
    @goto label_10

    # =======================================================================
    # OPTION 79 — THEN  (label_8100)
    # =======================================================================
    @label label_8100
    EVTHEN(debug, JOSTND, IREAD, IRECNT, keywrd, array, lnotbk, kard, iprmpt, lkecho)
    irtncd = fvsGetRtnCode()
    if irtncd != Int32(0); return; end
    @goto label_10

    # =======================================================================
    # OPTION 80 — ALSOTRY  (label_8200)
    # =======================================================================
    @label label_8200
    EVALSO(debug, JOSTND, IREAD, IRECNT, keywrd, array, lnotbk, kard, iprmpt)
    @goto label_10

    # =======================================================================
    # OPTION 81 — ENDIF  (label_8300)
    # =======================================================================
    @label label_8300
    iprmpt = Int32(0)
    EVEND(debug, JOSTND, IRECNT, keywrd, array, lnotbk, kard, iprmpt, lkecho)
    @goto label_10

    # =======================================================================
    # OPTION 82 — NOTREES  (label_8400)
    # =======================================================================
    @label label_8400
    lnotre = true
    if lkecho; @printf(io_units[JOSTND], "\n%-8s   NO PROJECTABLE TREE RECORDS EXPECTED.\n", keywrd); end
    ESEZCR(JOSTND, lkecho)
    @goto label_10

    # =======================================================================
    # OPTION 83 — CALBSTAT  (label_8500)
    # =======================================================================
    @label label_8500
    global JOCALB = Int32(JOSUME)
    if lnotbk[1]; global JOCALB = Int32(array[1]); end
    if lnotbk[2]; global FNMIN = array[2]; end
    if FNMIN < Float32(3.0); global FNMIN = Float32(3.0); end
    if lnotbk[3]; global NCALHT = Int32(array[3]); end
    if NCALHT < Int32(3); global NCALHT = Int32(3); end
    if lkecho
        @printf(io_units[JOSTND], "\n%-8s   CALIBRATION STATISTICS WILL BE WRITTEN TO FILE REFERENCED BY NUMBER %2d\n            MINIMUM NUMBER OF DIA. GROWTH OBSERVATIONS PER SPECIES TO CALIBRATE \n            THE LARGE TREE DIAMETER INCREMENT MODEL FOR LOCAL CONDITIONS= %6.0f\n            MINIMUM NUMBER OF HEIGHT GROWTH OBSERVATIONS PER SPECIES TO CALIBRATE \n            THE SMALL TREE HEIGHT INCREMENT MODEL FOR LOCAL CONDITIONS= %6d\n",
            keywrd, JOCALB, FNMIN, NCALHT)
    end
    @goto label_10

    # =======================================================================
    # OPTION 84 — OPEN  (label_8600)
    # =======================================================================
    @label label_8600
    KEYOPN(IREAD, JOSTND, IRECNT, keywrd, array, kard)
    irtncd = fvsGetRtnCode()
    if irtncd != Int32(0); return; end
    @goto label_10

    # =======================================================================
    # OPTION 85 — CLOSE  (label_8700)
    # =======================================================================
    @label label_8700
    if array[1] <= Float32(0.0)
        KEYDMP(JOSTND, IRECNT, keywrd, array, kard)
        ERRGRO(true, Int32(4))
        @goto label_10
    end
    i_tmp = Int32(array[1])
    i2 = array[2] > Float32(0.0) ? Int32(array[2]) : Int32(15)
    if lkecho
        @printf(io_units[JOSTND], "\n%-8s   CLOSE DATA SET REFERENCE NUMBER = %5d\n            INPUT RETURNED TO FILE ASSIGNED TO REFERENCE NUMBER =%5d\n", keywrd, i_tmp, i2)
    end
    if haskey(io_units, i_tmp)
        close(io_units[i_tmp])
        delete!(io_units, i_tmp)
    end
    global IREAD = i2
    @goto label_10

    # =======================================================================
    # OPTION 86 — NOSCREEN  (label_8800)
    # =======================================================================
    @label label_8800
    global LSCRN = false
    if lkecho; @printf(io_units[JOSTND], "\n%-8s   SCREEN OUTPUT DEACTIVATED.\n", keywrd); end
    @goto label_10

    # =======================================================================
    # OPTION 87 — RRIN  (label_8900)
    # =======================================================================
    @label label_8900
    if lkecho
        @printf(io_units[JOSTND], "\n%-8s   ROOT DISEASE MODEL IS OBSOLETE, USE\n WESTERN ROOT DISEASE MODEL VER. 3.0:\n", keywrd)
    end
    @goto label_10

    # =======================================================================
    # OPTION 88 — FIXMORT  (label_9000)
    # =======================================================================
    @label label_9000
    global LMORT = true
    idt = Int32(1)
    if lnotbk[1]; idt = Int32(array[1]); end
    if iprmpt > Int32(0)
        if iprmpt != Int32(2)
            KEYDMP(JOSTND, IRECNT, keywrd, array, kard)
            ERRGRO(true, Int32(25))
        else
            kode = OPNEWC(JOSTND, IREAD, idt, Int32(97), keywrd, kard, iprmpt, IRECNT, ICYC)
            irtncd = fvsGetRtnCode()
            if irtncd != Int32(0); return; end
        end
    else
        is = SPDECD(Int32(2), NSP, JOSTND, IRECNT, keywrd, array, kard)
        if is == Int32(-999); @goto label_10; end
        if !lnotbk[3]; array[3] = Float32(0.0); end
        if !lnotbk[4]; array[4] = Float32(0.0); end
        if !lnotbk[5]; array[5] = Float32(999.0); end
        if array[3] > Float32(1.0) && array[6] < Float32(3.0); array[3] = Float32(1.0); end
        if array[3] < Float32(0.0) && array[6] < Float32(3.0); array[3] = Float32(0.0); end
        ilen = Int32(3)
        if is < Int32(0); ilen = Int32(ISPGRP(-is, Int32(92))); end
        sp_str = kard[2][1:min(Int(ilen), length(kard[2]))]
        if lkecho
            @printf(io_units[JOSTND], "\n%-8s   DATE/CYCLE=%5d; SPECIES=%s (CODE=%3d); MORTALITY RATE=%10.4f\n            ONLY TREES GREATER THAN %7.2f AND LESS THAN %7.2f INCHES DBH ARE AFFECTED.\n            TYPE CODE = %3.0f; (0=REPLACE MODEL PREDICTION, 1=ADD TO MODEL PREDICTION, 2=USE MAXIMUM RATE, 3=MULTIPLY MODEL BY).\n",
                keywrd, idt, sp_str, is, array[3], array[4], array[5], array[6])
            if lnotbk[7] && array[7] > Float32(0.0)
                v7 = array[7]
                if v7 == Float32(1.0)
                    @printf(io_units[JOSTND], "            FIXMORT MORTALITY CONCENTRATION CODE = %4.0f; (BY POINT)\n", v7)
                elseif v7 == Float32(10.0)
                    @printf(io_units[JOSTND], "            FIXMORT MORTALITY CONCENTRATION CODE = %4.0f; (BY SIZE: SMALLEST TO LARGEST DBH)\n", v7)
                elseif v7 == Float32(11.0)
                    @printf(io_units[JOSTND], "            FIXMORT MORTALITY CONCENTRATION CODE = %4.0f; (BY POINT BY SIZE: SMALLEST TO LARGEST DBH)\n", v7)
                elseif v7 == Float32(20.0)
                    @printf(io_units[JOSTND], "            FIXMORT MORTALITY CONCENTRATION CODE = %4.0f; (BY SIZE: LARGEST TO SMALLEST DBH)\n", v7)
                elseif v7 == Float32(21.0)
                    @printf(io_units[JOSTND], "            FIXMORT MORTALITY CONCENTRATION CODE = %4.0f; (BY POINT BY SIZE: LARGEST TO SMALLEST DBH)\n", v7)
                else
                    @printf(io_units[JOSTND], "            FIXMORT MORTALITY CONCENTRATION CODE = %4.0f; (CODE NOT RECOGNIZED, IT WILL BE IGNORED)\n", v7)
                end
            end
        end
        kode = OPNEW(idt, Int32(97), Int32(6), view(array, 2:12))
        if kode > Int32(0); @goto label_10; end
    end
    @goto label_10

    # =======================================================================
    # OPTION 89 — SDIMAX  (label_9100)
    # =======================================================================
    @label label_9100
    is = SPDECD(Int32(1), NSP, JOSTND, IRECNT, keywrd, array, kard)
    if is == Int32(-999); @goto label_10; end
    global LMORT = true
    if lkecho; @printf(io_units[JOSTND], "\n%-8s\n", keywrd); end
    if array[2] > Float32(0.0)
        if is < Int32(0)
            igrp = -is
            iulim = Int32(ISPGRP(igrp, Int32(1))) + Int32(1)
            for ig in Int32(2):iulim
                igsp = Int32(ISPGRP(igrp, ig))
                SDIDEF[igsp] = array[2]
                MAXSDI[igsp] = Int32(1)
            end
            ilen = Int32(ISPGRP(-is, Int32(92)))
            sp_str = kard[1][1:min(Int(ilen), length(kard[1]))]
            if lkecho; @printf(io_units[JOSTND], "        MAXIMUM PERMISSABLE STAND DENSITY INDEX WILL BE CHANGED FOR SPECIES= %s (CODE= %3d); MAX SDI=%6.0f\n", sp_str, is, array[2]); end
        elseif is == Int32(0)
            for j in 1:MAXSP; SDIDEF[j] = array[2]; MAXSDI[j] = Int32(1); end
            if lkecho; @printf(io_units[JOSTND], "        MAXIMUM PERMISSABLE STAND DENSITY INDEX WILL BE CHANGED FOR ALL SPECIES ; MAX SDI=%6.0f\n", array[2]); end
        else
            SDIDEF[is] = array[2]
            MAXSDI[is] = Int32(1)
            ilen = Int32(3)
            sp_str = kard[1][1:min(Int(ilen), length(kard[1]))]
            if lkecho; @printf(io_units[JOSTND], "        MAXIMUM PERMISSABLE STAND DENSITY INDEX WILL BE CHANGED FOR SPECIES= %s (CODE= %3d); MAX SDI=%6.0f\n", sp_str, is, array[2]); end
        end
    end
    if lnotbk[5]; global PMSDIL = array[5]; end
    if PMSDIL < Float32(10.0); global PMSDIL = Float32(10.0); end
    if lnotbk[6]; global PMSDIU = array[6]; end
    if PMSDIU > Float32(95.0); global PMSDIU = Float32(95.0); end
    if lkecho
        @printf(io_units[JOSTND], "            PERCENT OF MAX SDI TO INVOKE DENSITY RELATED MORTALITY=%5.1f; PERCENT OF MAX SDI WHERE STAND REACHES MAX DENSITY=%5.1f\n", PMSDIL, PMSDIU)
    end
    if lnotbk[7]
        if VARACD ∈ ("CR", "TT", "UT")
            if is < Int32(0)
                igrp = -is
                iulim = Int32(ISPGRP(igrp, Int32(1))) + Int32(1)
                for ig in Int32(2):iulim
                    igsp = Int32(ISPGRP(igrp, ig))
                    ISTAGF[igsp] = Int32(array[7])
                end
                ilen = Int32(ISPGRP(-is, Int32(92)))
                sp_str = kard[1][1:min(Int(ilen), length(kard[1]))]
                if lkecho; @printf(io_units[JOSTND], "        STAGNATION EFFECTS INDICATOR WILL BE CHANGED FOR SPECIES= %s (CODE= %3d); INDICATOR =%4.0f\n", sp_str, is, array[7]); end
            elseif is == Int32(0)
                for j in 1:MAXSP; ISTAGF[j] = Int32(array[7]); end
                if lkecho; @printf(io_units[JOSTND], "        STAGNATION EFFECTS INDICATOR WILL BE CHANGED FOR ALL SPECIES ; INDICATOR =%4.0f\n", array[7]); end
            else
                ISTAGF[is] = Int32(array[7])
                ilen = Int32(3)
                sp_str = kard[1][1:min(Int(ilen), length(kard[1]))]
                if lkecho; @printf(io_units[JOSTND], "        STAGNATION EFFECTS INDICATOR WILL BE CHANGED FOR SPECIES= %s (CODE= %3d); INDICATOR =%4.0f\n", sp_str, is, array[7]); end
            end
        else
            if lkecho; @printf(io_units[JOSTND], "        STAGNATION EFFECTS NOT USED IN THIS VARIANT.\n"); end
        end
    end
    @goto label_10

    # =======================================================================
    # OPTION 90 — DELOTAB  (label_9200)
    # =======================================================================
    @label label_9200
    i_tmp = Int32(0)
    if lnotbk[1]; i_tmp = Int32(array[1]); end
    if i_tmp == Int32(0)
        for j in 1:5; ITABLE[j] = Int32(1); end
        if lkecho; @printf(io_units[JOSTND], "\n%-8s   NO TABLE SPECIFIED, ALL OPTIONAL TABLES WILL BE DELETED.\n", keywrd); end
        @goto label_10
    end
    if i_tmp > Int32(4)
        if lkecho; @printf(io_units[JOSTND], "\n%-8s   TABLE NUMBER%4d  SPECIFIED. THIS IS AN INVALID TABLE NUMBER. KEYWORD IGNORED.\n", keywrd, i_tmp); end
        @goto label_10
    end
    ITABLE[i_tmp] = Int32(1)
    if i_tmp == Int32(1) && lkecho; @printf(io_units[JOSTND], "\n%-8s   TABLE NUMBER%4d  SPECIFIED.  STAND COMPOSITION TABLE WILL BE DELETED.\n", keywrd, i_tmp); end
    if i_tmp == Int32(2) && lkecho; @printf(io_units[JOSTND], "\n%-8s   TABLE NUMBER%4d  SPECIFIED.  SAMPLE TREE TABLE WILL BE DELETED.\n", keywrd, i_tmp); end
    if i_tmp == Int32(3) && lkecho; @printf(io_units[JOSTND], "\n%-8s   TABLE NUMBER%4d  SPECIFIED.  SUMMARY OUTPUT TABLE WILL BE DELETED.\n", keywrd, i_tmp); end
    if i_tmp == Int32(4) && lkecho; @printf(io_units[JOSTND], "\n%-8s   TABLE NUMBER%4d  SPECIFIED.  ACTIVITY SCHEDULE TABLE WILL BE DELETED.\n", keywrd, i_tmp); end
    if i_tmp == Int32(5) && lkecho; @printf(io_units[JOSTND], "\n%-8s   TABLE NUMBER%4d  SPECIFIED.  THIS IS NOT FUNCTIONAL AT THIS TIME.\n", keywrd, i_tmp); end
    @goto label_10

    # =======================================================================
    # OPTION 91 — SERLCORR  (label_9300)
    # =======================================================================
    @label label_9300
    if lnotbk[1]; global BJPHI  = array[1]; end
    if lnotbk[2]; global BJTHET = array[2]; end
    if lkecho; @printf(io_units[JOSTND], "\n%-8s   ARMA(1,1) SERIAL CORRELATION PARAMETERS: PHI=%5.2f; THETA=%5.2f\n", keywrd, BJPHI, BJTHET); end
    @goto label_10

    # =======================================================================
    # OPTION 92 — CUTLIST  (label_9400)
    # verified against initre.f lines 3237-3254
    # =======================================================================
    @label label_9400
    idt = Int32(1)
    if lnotbk[1]; idt = Int32(array[1]); end
    np = Int32(2)
    if lnotbk[4]; np = Int32(3); end
    if lnotbk[6]; np = Int32(5); end
    if !lnotbk[2]; array[2] = Float32(JOLIST); end
    kode = OPNEW(idt, Int32(199), np, view(array, 2:12))
    if kode > Int32(0); @goto label_10; end
    if lkecho
        @printf(io_units[JOSTND], "\n%-8s   DATE/CYCLE=%5d; DATA SET REFERENCE NUMBER =%4.0f; HEADING SUPPRESSION CODE =%3.0f\n           (0=WITH HEADING, OTHER VALUES=SUPPRESS HEADING).\n", keywrd, idt, array[2], array[3])
        if np == Int32(3) && array[4] == Float32(2.0)
            @printf(io_units[JOSTND], "           CYCLE ONE CUTLIST SUPRESSED\n")
        end
        if np == Int32(5) && array[6] > Float32(0.0)
            @printf(io_units[JOSTND], "           CUTLIST WILL BE IN OLD FORMAT\n")
        end
    end
    @goto label_10

    # =======================================================================
    # OPTION 93 — RESETAGE  (label_9500)
    # verified against initre.f lines 3258-3282
    # =======================================================================
    @label label_9500
    idt = Int32(1)
    if iprmpt > Int32(0)
        if iprmpt != Int32(2)
            KEYDMP(JOSTND, IRECNT, keywrd, array, kard)
            ERRGRO(true, Int32(25))
        else
            kode = OPNEWC(JOSTND, IREAD, idt, Int32(443), keywrd, kard, iprmpt, IRECNT, ICYC)
            irtncd = fvsGetRtnCode()
            if irtncd != Int32(0); return; end
        end
        @goto label_10
    end
    if lnotbk[1]; idt = Int32(array[1]); end
    kode = OPNEW(idt, Int32(443), Int32(1), view(array, 2:12))
    if kode > Int32(0); @goto label_10; end
    if lkecho; @printf(io_units[JOSTND], "\n%-8s   DATE/CYCLE=%5d; NEW AGE=%6.0f\n", keywrd, idt, array[2]); end
    @goto label_10

    # =======================================================================
    # OPTION 94 — SITECODE  (label_9600)
    # verified against initre.f lines 3286-3377
    # =======================================================================
    @label label_9600
    is = SPDECD(Int32(1), NSP, JOSTND, IRECNT, keywrd, array, kard)
    if is == Int32(-999); @goto label_10; end
    if is < Int32(0)
        igrp = -is
        iulim = Int32(ISPGRP(igrp, Int32(1))) + Int32(1)
        if ISISP == Int32(0); global ISISP = Int32(ISPGRP(igrp, Int32(2))); end
        global LSITE = true
        for ig in Int32(2):iulim
            igsp = Int32(ISPGRP(igrp, ig))
            if lnotbk[2] && array[2] > Float32(5.0); SITEAR[igsp] = array[2]; end
        end
        ilen = Int32(ISPGRP(-is, Int32(92)))
        sp_str = kard[1][1:min(Int(ilen), length(kard[1]))]
        if lkecho; @printf(io_units[JOSTND], "\n%-8s   SITE INDEX SPECIES= %s (CODE= %3d);  SITE CODE FOR LARGE AND SMALL TREES=%8.1f\n", keywrd, sp_str, is, array[2]); end
    elseif is == Int32(0)
        if lnotbk[2]
            if array[2] > Float32(5.0)
                for k in 1:MAXSP; SITEAR[k] = array[2]; end
            end
            if lkecho; @printf(io_units[JOSTND], "\n%-8s   SITE CODE CHANGED FOR ALL SPECIES;  SITE CODE FOR LARGE AND SMALL TREES=%8.1f\n", keywrd, array[2]); end
        else
            KEYDMP(JOSTND, IRECNT, keywrd, array, kard)
            ERRGRO(true, Int32(4))
            @goto label_10
        end
    else
        if ISISP == Int32(0); global ISISP = is; end
        global LSITE = true
        if lnotbk[2] && array[2] > Float32(7.0); SITEAR[is] = array[2]; end
        ilen = Int32(3)
        sp_str = kard[1][1:min(Int(ilen), length(kard[1]))]
        if lkecho; @printf(io_units[JOSTND], "\n%-8s   SITE INDEX SPECIES= %s (CODE= %3d);  SITE CODE FOR LARGE AND SMALL TREES=%8.1f\n", keywrd, sp_str, is, array[2]); end
        if lnotbk[3] && array[3] > Float32(0.0)
            global ISISP = is
            if lkecho; @printf(io_units[JOSTND], "           SITE INDEX SPECIES WILL BE USED AS THE SITE SPECIES.\n"); end
        end
    end
    if lnotbk[2] && array[2] <= Float32(7.0)
        if VARACD ∈ ("CA", "NC", "SO", "WS", "OC")
            if lkecho; @printf(io_units[JOSTND], "           FIELD 2 OF THE SITECODE KEWORD IS LESS THAN 8 AND WILL BE INTERPRETED AS A DUNNING CODE.\n"); end
        end
        DUNN(array[2])
    end
    @goto label_10

    # =======================================================================
    # OPTION 95 — MISTOE  (label_9700)
    # verified against initre.f lines 3381-3387
    # =======================================================================
    @label label_9700
    if lkecho; @printf(io_units[JOSTND], "\n%-8s   MISTLETOE KEYWORDS:\n", keywrd); end
    MISIN(keywrd, array, lnotbk, lkecho)
    irtncd = fvsGetRtnCode()
    if irtncd != Int32(0); return; end
    @goto label_10

    # =======================================================================
    # OPTION 96 — CRNMULT  (label_9800)
    # verified against initre.f lines 3391-3422
    # =======================================================================
    @label label_9800
    idt = Int32(1)
    if lnotbk[1]; idt = Int32(array[1]); end
    if iprmpt > Int32(0)
        if iprmpt != Int32(2)
            KEYDMP(JOSTND, IRECNT, keywrd, array, kard)
            ERRGRO(true, Int32(25))
        else
            kode = OPNEWC(JOSTND, IREAD, idt, Int32(81), keywrd, kard, iprmpt, IRECNT, ICYC)
            irtncd = fvsGetRtnCode()
            if irtncd != Int32(0); return; end
        end
        @goto label_10
    end
    is = SPDECD(Int32(2), NSP, JOSTND, IRECNT, keywrd, array, kard)
    if is == Int32(-999); @goto label_10; end
    kode = OPNEW(idt, Int32(81), Int32(5), view(array, 2:12))
    if kode > Int32(0); @goto label_10; end
    if array[5] <= Float32(0.0); array[5] = Float32(99.0); end
    ilen = Int32(3)
    if is < Int32(0); ilen = Int32(ISPGRP(-is, Int32(92))); end
    sp_str = kard[2][1:min(Int(ilen), length(kard[2]))]
    if lkecho
        @printf(io_units[JOSTND], "\n%-8s   DATE/CYCLE=%5d;  SPECIES=%s (CODE= %3d);  MULTIPLIER=%7.2f;  LOWER DBH=%6.1f;  UPPER DBH=%6.1f;  DUB FLAG=%6.0f\n", keywrd, idt, sp_str, is, array[3], array[4], array[5], array[6])
    end
    @goto label_10

    # =======================================================================
    # OPTION 97 — CFVOLEQU  (label_9900) — obsolete
    # verified against initre.f lines 3426-3504
    # =======================================================================
    @label label_9900
    if lkecho; @printf(io_units[JOSTND], "\n%-8s   THIS KEYWORD IS NO LONGER ACTIVE\n", keywrd); end
    ERRGRO(true, Int32(46))
    @goto label_10

    # =======================================================================
    # OPTION 98 — BFVOLEQU  (label_9950) — obsolete
    # verified against initre.f lines 3508-3585
    # =======================================================================
    @label label_9950
    if lkecho; @printf(io_units[JOSTND], "\n%-8s   THIS KEYWORD IS NO LONGER ACTIVE\n", keywrd); end
    ERRGRO(true, Int32(45))
    @goto label_10

    # =======================================================================
    # OPTION 99 — ANIN  (label_9975) — obsolete
    # verified against initre.f lines 3589-3593
    # =======================================================================
    @label label_9975
    if lkecho; @printf(io_units[JOSTND], "\n%-8s   ANNOSUS ROOT DISEASE MODEL IS OBSOLETE, USE\n WESTERN ROOT DISEASE MODEL VER. 3.0:\n", keywrd); end
    @goto label_10

    # =======================================================================
    # OPTION 100 — DFB  (label_9985)
    # verified against initre.f lines 3597-3601
    # =======================================================================
    @label label_9985
    if lkecho; @printf(io_units[JOSTND], "\n%-8s   DOUGLAS-FIR BEETLE OPTIONS:\n", keywrd); end
    DFBIN(keywrd, array, lnotbk, lkecho)
    @goto label_10

    # =======================================================================
    # OPTION 101 — RDIN  (label_9995)
    # verified against initre.f lines 3605-3609
    # =======================================================================
    @label label_9995
    if lkecho; @printf(io_units[JOSTND], "\n%-8s   WESTERN ROOT DISEASE MODEL OPTIONS:\n", keywrd); end
    RDIN(keywrd, array, lnotbk, lkecho)
    @goto label_10

    # =======================================================================
    # OPTION 102 — MANAGED  (label_10000)
    # verified against initre.f lines 3613-3632
    # =======================================================================
    @label label_10000
    idt = Int32(0)
    if lnotbk[1]; idt = Int32(array[1]); end
    if idt > Int32(0)
        kode = OPNEW(idt, Int32(82), Int32(1), view(array, 2:12))
        if kode > Int32(0); @goto label_10; end
        if lkecho; @printf(io_units[JOSTND], "\n%-8s   DATE/CYCLE=%5d; MANAGED = %5.0f\n", keywrd, idt, array[2]); end
    else
        if lnotbk[2] && array[2] == Float32(0.0)
            if lkecho; @printf(io_units[JOSTND], "\n%-8s   DATE/CYCLE=%5d; MANAGED = 0 (NO)\n", keywrd, idt); end
        else
            if lkecho; @printf(io_units[JOSTND], "\n%-8s   DATE/CYCLE=%5d; MANAGED = 1 (YES)\n", keywrd, idt); end
            array[2] = Float32(1.0)
        end
    end
    if idt <= Int32(0); global MANAGD = Int32(array[2]); end
    @goto label_10

    # =======================================================================
    # OPTION 103 — YARDLOSS  (label_10100)
    # verified against initre.f lines 3636-3692
    # =======================================================================
    @label label_10100
    idt = Int32(1)
    if lnotbk[1]; idt = Int32(array[1]); end
    if iprmpt > Int32(0)
        if iprmpt != Int32(2)
            KEYDMP(JOSTND, IRECNT, keywrd, array, kard)
            ERRGRO(true, Int32(25))
        else
            kode = OPNEWC(JOSTND, IREAD, idt, Int32(203), keywrd, kard, iprmpt, IRECNT, ICYC)
            irtncd = fvsGetRtnCode()
            if irtncd != Int32(0); return; end
        end
        @goto label_10
    end
    begin
        x_tmp = Float32(0.0)
        if lnotbk[2]; x_tmp = max(Float32(0.0), array[2]); x_tmp = min(Float32(1.0), x_tmp); end
        array[2] = x_tmp
        x_tmp = Float32(0.0)
        if lnotbk[3]; x_tmp = max(Float32(0.0), array[3]); x_tmp = min(Float32(1.0), x_tmp); end
        array[3] = x_tmp
        x_tmp = Float32(1.0)
        if lnotbk[4]; x_tmp = max(Float32(0.0), array[4]); x_tmp = min(Float32(1.0), x_tmp); end
        array[4] = x_tmp
    end
    kode = OPNEW(idt, Int32(203), Int32(3), view(array, 2:12))
    if kode > Int32(0); @goto label_10; end
    if lkecho
        @printf(io_units[JOSTND], "\n%-8s   DATE/CYCLE=%5d; PROPORTION OF HARVESTED STEMS LEFT IN STAND = %6.4f\n           PROPORTION OF NON-REMOVED HARVEST THAT IS DOWN = %6.4f\n           PROPORTION OF CROWNS REMAINING IN STAND FROM REMOVED STEMS = %6.4f\n", keywrd, idt, array[2], array[3], array[4])
    end
    @goto label_10

    # =======================================================================
    # OPTION 104 — FMIN  (label_10200)
    # verified against initre.f lines 3696-3702
    # =======================================================================
    @label label_10200
    if lkecho; @printf(io_units[JOSTND], "\n%-8s   FIRE MODEL KEYWORDS:\n", keywrd); end
    FMIN(Int32(1), NSP, lkecho)
    irtncd = fvsGetRtnCode()
    if irtncd != Int32(0); return; end
    @goto label_10

    # =======================================================================
    # OPTION 105 — STRCLASS  (label_10300)
    # verified against initre.f lines 3706-3708
    # =======================================================================
    @label label_10300
    KSSTAG(JOSTND, keywrd, lnotbk, array, lkecho)
    @goto label_10

    # =======================================================================
    # OPTION 106 — MODTYPE  (label_10400)
    # verified against initre.f lines 3712-3758
    # =======================================================================
    @label label_10400
    if VARACD == "CR"
        if lnotbk[1]; global IMODTY = Int32(array[1]); end
        if lkecho; @printf(io_units[JOSTND], "\n%-8s   MODEL TYPE =%5d\n", keywrd, IMODTY); end
        if lkecho; @printf(io_units[JOSTND], "           (SEE MODTYPE KEYWORD DISCUSSION FOLLOWING --- PROCESS --- KEYWORD.)\n"); end
    end
    if lnotbk[3]; global IFORTP = Int32(array[3]); end
    if IFORTP > Int32(999)
        begin
            xtmp_mt = Float32(IFORTP)
            xtmp_mt = xtmp_mt / Float32(1000.0) + Float32(0.00001)
            ixtmp_mt = Int32(xtmp_mt)
            global IFORTP = Int32((xtmp_mt - Float32(ixtmp_mt)) * Float32(1000.0))
            global LFLAGV = true
        end
    end
    begin
        dum1_mt = Float32(0.0)
        ixf_mt  = Int32(1)
        FORTYP(ixf_mt, dum1_mt)
    end
    if lkecho; @printf(io_units[JOSTND], "\n%-8s            FOREST TYPE =%5d\n", keywrd, IFORTP); end
    @goto label_10

    # =======================================================================
    # OPTION 107 — FVSSTAND  (label_10500)
    # verified against initre.f lines 3762-3784
    # =======================================================================
    @label label_10500
    idt = Int32(1)
    if lnotbk[1]; idt = Int32(array[1]); end
    np = Int32(1)
    if lnotbk[2]; np = Int32(2); end
    kode = OPNEW(idt, Int32(204), np, view(array, 2:12))
    if kode > Int32(0); @goto label_10; end
    if np == Int32(2) && array[2] == Float32(1.0)
        if lkecho; @printf(io_units[JOSTND], "\n%-8s   DATE/CYCLE=%5d; CYCLE 0 FVSSTAND SUPPRESSED; CYCLE 1 FVSSTAND DONE\n", keywrd, idt); end
    elseif np == Int32(2) && array[2] == Float32(2.0)
        if lkecho; @printf(io_units[JOSTND], "\n%-8s   DATE/CYCLE=%5d; CYCLE 0 FVSSTAND DONE; CYCLE 1 FVSSTAND SUPPRESSED\n", keywrd, idt); end
    else
        if lkecho; @printf(io_units[JOSTND], "\n%-8s   DATE/CYCLE=%5d\n", keywrd, idt); end
    end
    @goto label_10

    # =======================================================================
    # OPTION 108 — PRUNE  (label_10600)
    # verified against initre.f lines 3788-3823
    # =======================================================================
    @label label_10600
    idt = Int32(1)
    if lnotbk[1]; idt = Int32(array[1]); end
    if array[2] <= Float32(0.0); array[2] = Float32(2.0); end
    if array[4] <= Float32(0.0); array[4] = Float32(0.5); end
    if array[4] > Float32(1.0);  array[4] = Float32(1.0); end
    if array[7] <= Float32(0.0); array[7] = Float32(99.0); end
    if iprmpt > Int32(0)
        if iprmpt != Int32(2)
            KEYDMP(JOSTND, IRECNT, keywrd, array, kard)
            ERRGRO(true, Int32(25))
        else
            kode = OPNEWC(JOSTND, IREAD, idt, Int32(249), keywrd, kard, iprmpt, IRECNT, ICYC)
            irtncd = fvsGetRtnCode()
            if irtncd != Int32(0); return; end
        end
        @goto label_10
    end
    is = SPDECD(Int32(5), NSP, JOSTND, IRECNT, keywrd, array, kard)
    if is == Int32(-999); @goto label_10; end
    kode = OPNEW(idt, Int32(249), Int32(6), view(array, 2:12))
    if kode > Int32(0); @goto label_10; end
    ilen = Int32(3)
    if is < Int32(0); ilen = Int32(ISPGRP(-is, Int32(92))); end
    sp_str = kard[5][1:min(Int(ilen), length(kard[5]))]
    if lkecho
        @printf(io_units[JOSTND], "\n%-8s   DATE/CYCLE=%5d;  METHOD=%5.0f;  FEET=%7.2f;  MAX CR REMOVAL PROPORTION=%6.1f;\n           SPECIES=%s (CODE= %3d);  LOWER DBH=%6.1f;  UPPER DBH=%6.1f\n", keywrd, idt, array[2], array[3], array[4], sp_str, is, array[6], array[7])
    end
    @goto label_10

    # =======================================================================
    # OPTION 109 — SVS  (label_10900)
    # verified against initre.f lines 3827-3829
    # =======================================================================
    @label label_10900
    SVKEY(keywrd, lnotbk, array)
    @goto label_10

    # =======================================================================
    # OPTION 110 — FIXDG  (label_11000)
    # verified against initre.f lines 3833-3868
    # =======================================================================
    @label label_11000
    idt = Int32(1)
    if lnotbk[1]; idt = Int32(array[1]); end
    if iprmpt > Int32(0)
        if iprmpt != Int32(2)
            KEYDMP(JOSTND, IRECNT, keywrd, array, kard)
            ERRGRO(true, Int32(25))
        else
            kode = OPNEWC(JOSTND, IREAD, idt, Int32(98), keywrd, kard, iprmpt, IRECNT, ICYC)
            irtncd = fvsGetRtnCode()
            if irtncd != Int32(0); return; end
        end
    else
        is = SPDECD(Int32(2), NSP, JOSTND, IRECNT, keywrd, array, kard)
        if is == Int32(-999); @goto label_10; end
        if !lnotbk[3]; array[3] = Float32(1.0); end
        if !lnotbk[4]; array[4] = Float32(0.0); end
        if !lnotbk[5]; array[5] = Float32(999.0); end
        ilen = Int32(3)
        if is < Int32(0); ilen = Int32(ISPGRP(-is, Int32(92))); end
        sp_str = kard[2][1:min(Int(ilen), length(kard[2]))]
        if lkecho
            @printf(io_units[JOSTND], "\n%-8s   DATE/CYCLE=%5d; SPECIES=%s (CODE=%3d); DIAMETER GROWTH MULTIPLIER=%10.4f\n           ONLY TREES GREATER THAN OR EQUAL TO %7.2f AND LESS THAN %7.2f INCHES DBH ARE AFFECTED.\n", keywrd, idt, sp_str, is, array[3], array[4], array[5])
        end
        kode = OPNEW(idt, Int32(98), Int32(4), view(array, 2:12))
        if kode > Int32(0); @goto label_10; end
    end
    @goto label_10

    # =======================================================================
    # OPTION 111 — FIXHTG  (label_11100)
    # verified against initre.f lines 3872-3907
    # =======================================================================
    @label label_11100
    idt = Int32(1)
    if lnotbk[1]; idt = Int32(array[1]); end
    if iprmpt > Int32(0)
        if iprmpt != Int32(2)
            KEYDMP(JOSTND, IRECNT, keywrd, array, kard)
            ERRGRO(true, Int32(25))
        else
            kode = OPNEWC(JOSTND, IREAD, idt, Int32(99), keywrd, kard, iprmpt, IRECNT, ICYC)
            irtncd = fvsGetRtnCode()
            if irtncd != Int32(0); return; end
        end
    else
        is = SPDECD(Int32(2), NSP, JOSTND, IRECNT, keywrd, array, kard)
        if is == Int32(-999); @goto label_10; end
        if !lnotbk[3]; array[3] = Float32(1.0); end
        if !lnotbk[4]; array[4] = Float32(0.0); end
        if !lnotbk[5]; array[5] = Float32(999.0); end
        ilen = Int32(3)
        if is < Int32(0); ilen = Int32(ISPGRP(-is, Int32(92))); end
        sp_str = kard[2][1:min(Int(ilen), length(kard[2]))]
        if lkecho
            @printf(io_units[JOSTND], "\n%-8s   DATE/CYCLE=%5d; SPECIES=%s (CODE=%3d); HEIGHT GROWTH MULTIPLIER=%10.4f\n           ONLY TREES GREATER THAN OR EQUAL TO %7.2f AND LESS THAN %7.2f INCHES DBH ARE AFFECTED.\n", keywrd, idt, sp_str, is, array[3], array[4], array[5])
        end
        kode = OPNEW(idt, Int32(99), Int32(4), view(array, 2:12))
        if kode > Int32(0); @goto label_10; end
    end
    @goto label_10

    # =======================================================================
    # OPTION 112 — THINSDI  (label_11200)
    # verified against initre.f lines 3911-4003
    # =======================================================================
    @label label_11200
    global ICFLAG = Int32(230)
    idt = Int32(1)
    if lnotbk[1]; idt = Int32(array[1]); end
    if iprmpt > Int32(0)
        if iprmpt != Int32(2)
            KEYDMP(JOSTND, IRECNT, keywrd, array, kard)
            ERRGRO(true, Int32(25))
        else
            kode = OPNEWC(JOSTND, IREAD, idt, ICFLAG, keywrd, kard, iprmpt, IRECNT, ICYC)
            irtncd = fvsGetRtnCode()
            if irtncd != Int32(0); return; end
        end
        @goto label_10
    end
    if lnotbk[2]
        prms[1] = array[2]
    else
        KEYDMP(JOSTND, IRECNT, keywrd, array, kard)
        ERRGRO(true, Int32(4))
        @goto label_10
    end
    prms[2] = EFF
    if lnotbk[3]; prms[2] = array[3]; end
    is = SPDECD(Int32(4), NSP, JOSTND, IRECNT, keywrd, array, kard)
    if is == Int32(-999); @goto label_10; end
    prms[3] = Float32(is)
    prms[4] = Float32(0.0)
    if lnotbk[5]; prms[4] = array[5]; end
    prms[5] = Float32(999.0)
    if lnotbk[6]; prms[5] = array[6]; end
    if prms[5] <= prms[4]
        KEYDMP(JOSTND, IRECNT, keywrd, array, kard)
        ERRGRO(true, Int32(4))
        @goto label_10
    end
    prms[6] = Float32(0.0)
    if lnotbk[7]; prms[6] = array[7]; end
    if prms[6] == Float32(0.0) && prms[2] > Float32(0.0); prms[2] = Float32(0.0); end
    kode = OPNEW(idt, ICFLAG, Int32(6), prms)
    if kode > Int32(0); @goto label_10; end
    if lkecho
        @printf(io_units[JOSTND], "\n%-8s   DATE/CYCLE=%5d; RESIDUAL=%8.2f\n", keywrd, idt, prms[1])
        ilen = Int32(3)
        if is < Int32(0); ilen = Int32(ISPGRP(-is, Int32(92))); end
        sp_str = kard[4][1:min(Int(ilen), length(kard[4]))]
        if prms[2] == Float32(0.0)
            @printf(io_units[JOSTND], "           PROPORTION OF SELECTED TREES REMOVED WILL BE COMPUTED BY THE MODEL\n           SPECIES=%s (CODE=%3d); DBH OF REMOVED TREES WILL RANGE FROM %5.1f TO %5.1f INCHES.\n", sp_str, is, prms[4], prms[5])
        else
            @printf(io_units[JOSTND], "           PROPORTION OF SELECTED TREES REMOVED= %6.3f;\n           SPECIES=%s (CODE=%3d); DBH OF REMOVED TREES WILL RANGE FROM %5.1f TO %5.1f INCHES.\n", prms[2], sp_str, is, prms[4], prms[5])
        end
        if prms[6] == Float32(0.0)
            @printf(io_units[JOSTND], "           CUTTING WILL BE DISTRIBUTED THROUGHOUT THE SPECIFIED DIAMETER CLASS.\n")
        elseif prms[6] == Float32(1.0)
            @printf(io_units[JOSTND], "           CUTTING WILL BE FROM BELOW IN THE SPECIFIED DIAMETER CLASS.\n")
        else
            @printf(io_units[JOSTND], "           CUTTING WILL BE FROM ABOVE IN THE SPECIFIED DIAMETER CLASS.\n")
        end
    end
    @goto label_10

    # =======================================================================
    # OPTION 113 — LOCATE  (label_11300)
    # verified against initre.f lines 4007-4015
    # =======================================================================
    @label label_11300
    if lnotbk[1]; global TLAT   = array[1]; end
    if lnotbk[2]; global TLONG  = array[2]; end
    if lnotbk[3]; global ISTATE = Int32(array[3]); end
    if lnotbk[4]; global ICNTY  = Int32(array[4]); end
    if lkecho; @printf(io_units[JOSTND], "\n%-8s   LATITUDE =%9.4f;  LONGITUDE = %9.4f;  STATE CODE = %2d;  COUNTY CODE = %3d\n", keywrd, TLAT, TLONG, ISTATE, ICNTY); end
    @goto label_10

    # =======================================================================
    # OPTION 114 — available  (label_11400) — BGC extension retired
    # verified against initre.f lines 4019-4025
    # =======================================================================
    @label label_11400
    @goto label_10

    # =======================================================================
    # OPTION 115 — THINCC  (label_11500)
    # verified against initre.f lines 4029-4121
    # =======================================================================
    @label label_11500
    global ICFLAG = Int32(231)
    idt = Int32(1)
    if lnotbk[1]; idt = Int32(array[1]); end
    if iprmpt > Int32(0)
        if iprmpt != Int32(2)
            KEYDMP(JOSTND, IRECNT, keywrd, array, kard)
            ERRGRO(true, Int32(25))
        else
            kode = OPNEWC(JOSTND, IREAD, idt, ICFLAG, keywrd, kard, iprmpt, IRECNT, ICYC)
            irtncd = fvsGetRtnCode()
            if irtncd != Int32(0); return; end
        end
        @goto label_10
    end
    if lnotbk[2]
        prms[1] = array[2]
    else
        KEYDMP(JOSTND, IRECNT, keywrd, array, kard)
        ERRGRO(true, Int32(4))
        @goto label_10
    end
    prms[2] = EFF
    if lnotbk[3]; prms[2] = array[3]; end
    is = SPDECD(Int32(4), NSP, JOSTND, IRECNT, keywrd, array, kard)
    if is == Int32(-999); @goto label_10; end
    prms[3] = Float32(is)
    prms[4] = Float32(0.0)
    if lnotbk[5]; prms[4] = array[5]; end
    prms[5] = Float32(999.0)
    if lnotbk[6]; prms[5] = array[6]; end
    if prms[5] <= prms[4]
        KEYDMP(JOSTND, IRECNT, keywrd, array, kard)
        ERRGRO(true, Int32(4))
        @goto label_10
    end
    prms[6] = Float32(0.0)
    if lnotbk[7]; prms[6] = array[7]; end
    if prms[6] == Float32(0.0) && prms[2] > Float32(0.0); prms[2] = Float32(0.0); end
    kode = OPNEW(idt, ICFLAG, Int32(6), prms)
    if kode > Int32(0); @goto label_10; end
    if lkecho
        @printf(io_units[JOSTND], "\n%-8s   DATE/CYCLE=%5d; RESIDUAL=%8.2f\n", keywrd, idt, prms[1])
        ilen = Int32(3)
        if is < Int32(0); ilen = Int32(ISPGRP(-is, Int32(92))); end
        sp_str = kard[4][1:min(Int(ilen), length(kard[4]))]
        if prms[2] == Float32(0.0)
            @printf(io_units[JOSTND], "           PROPORTION OF SELECTED TREES REMOVED WILL BE COMPUTED BY THE MODEL\n           SPECIES=%s (CODE=%3d); DBH OF REMOVED TREES WILL RANGE FROM %5.1f TO %5.1f INCHES.\n", sp_str, is, prms[4], prms[5])
        else
            @printf(io_units[JOSTND], "           PROPORTION OF SELECTED TREES REMOVED= %6.3f;\n           SPECIES=%s (CODE=%3d); DBH OF REMOVED TREES WILL RANGE FROM %5.1f TO %5.1f INCHES.\n", prms[2], sp_str, is, prms[4], prms[5])
        end
        if prms[6] == Float32(0.0)
            @printf(io_units[JOSTND], "           CUTTING WILL BE DISTRIBUTED THROUGHOUT THE SPECIFIED DIAMETER CLASS.\n")
        elseif prms[6] == Float32(1.0)
            @printf(io_units[JOSTND], "           CUTTING WILL BE FROM BELOW IN THE SPECIFIED DIAMETER CLASS.\n")
        else
            @printf(io_units[JOSTND], "           CUTTING WILL BE FROM ABOVE IN THE SPECIFIED DIAMETER CLASS.\n")
        end
    end
    @goto label_10

    # =======================================================================
    # OPTION 116 — ECON  (label_11600)
    # verified against initre.f lines 4125-4131
    # =======================================================================
    @label label_11600
    if lkecho; @printf(io_units[JOSTND], "\n%-8s   ECONOMIC EXTENSION KEYWORDS:\n", keywrd); end
    ECIN(IRECNT, IREAD, JOSTND, NSP, ICYC, lkecho, ISPGRP)
    irtncd = fvsGetRtnCode()
    if irtncd != Int32(0); return; end
    @goto label_10

    # =======================================================================
    # OPTION 117 — DATABASE  (label_11700)
    # verified against initre.f lines 4135-4141
    # =======================================================================
    @label label_11700
    if lkecho; @printf(io_units[JOSTND], "\n%-8s   DATABASE KEYWORDS:\n", keywrd); end
    DBSIN(keywrd, array, isdsp, sdlo, sdhi, lnotbk, lkecho)
    irtncd = fvsGetRtnCode()
    if irtncd != Int32(0); return; end
    @goto label_10

    # =======================================================================
    # OPTION 118 — available  (label_11800) — BGC activity slot retired
    # verified against initre.f lines 4145-4152
    # =======================================================================
    @label label_11800
    @goto label_10

    # =======================================================================
    # OPTION 119 — DEFECT  (label_11900)
    # verified against initre.f lines 4156-4472
    # =======================================================================
    @label label_11900
    begin
        if eof(io_units[IREAD]); @goto label_80; end
        raw_line = readline(io_units[IREAD])
        global IRECNT += Int32(1)
        for i_def in 1:8
            sc = (i_def - 1) * 10 + 1; ec = i_def * 10
            s_def = sc <= length(raw_line) ? strip(raw_line[sc:min(ec, length(raw_line))]) : ""
            WK6[i_def] = isempty(s_def) ? Float32(0) : parse(Float32, s_def)
        end
        idtype_def = Int32(0)
        i_errcnt = Int32(0)
        if lnotbk[1] && array[1] == Float32(1.0)
            idtype_def = Int32(1)
            global LCVOLS = true
        elseif lnotbk[1] && array[1] == Float32(2.0)
            idtype_def = Int32(2)
            global LBVOLS = true
        elseif lnotbk[1] && (array[1] > Float32(2.0) || array[1] < Float32(0.0))
            KEYDMP(JOSTND, IRECNT, keywrd, array, kard)
            ERRGRO(true, Int32(25))
            @goto label_10
        else
            global LCVOLS = true
            global LBVOLS = true
        end
        if lnotbk[3] && array[3] > Float32(0.0); igndef = Int32(1); end
        is = SPDECD(Int32(2), NSP, JOSTND, IRECNT, keywrd, array, kard)
        if is == Int32(-999); @goto label_10; end
        if is < Int32(0)
            igrp = -is
            iulim = Int32(ISPGRP(igrp, Int32(1))) + Int32(1)
            for ig in Int32(2):iulim
                igsp = Int32(ISPGRP(igrp, ig))
                if idtype_def == Int32(0) || idtype_def == Int32(1)
                    if LFIANVB
                        if i_errcnt < Int32(1); ERRGRO(true, Int32(50)); end
                        i_errcnt += Int32(1)
                    else
                        for k_def in 1:8; CFDEFT[k_def+1, igsp] = WK6[k_def]; end
                    end
                end
                if idtype_def == Int32(0) || idtype_def == Int32(2)
                    for k_def in 1:8; BFDEFT[k_def+1, igsp] = WK6[k_def]; end
                end
            end
            ilen = Int32(ISPGRP(-is, Int32(92)))
            sp_str = kard[2][1:min(Int(ilen), length(kard[2]))]
            if lkecho
                if VARACD ∈ ("CS", "LS", "NE", "SN")
                    if idtype_def == Int32(0) || idtype_def == Int32(1)
                        if LFIANVB
                            @printf(io_units[JOSTND], "\n%-8s            CUBIC FOOT VOLUME DEFECT MODIFICATION HAS BEEN DISABLED DUE TO PREVIOUS CALL TO FIAVBC.\n", keywrd)
                        else
                            @printf(io_units[JOSTND], "\n%-8s            PULPWOOD VOLUME DEFECT PROPORTIONS HAVE BEEN CHANGED FOR SPECIES:%s (CODE=%3d)\n           5 INCH TREES=%6.2f; 10 INCH TREES=%6.2f; 15 INCH TREES=%6.2f\n           20 INCH TREES=%6.2f; 25 INCH TREES=%6.2f; 30 INCH TREES=%6.2f\n           35 INCH TREES=%6.2f; 40 INCH AND LARGER TREES=%6.2f\n", keywrd, sp_str, is, WK6[1], WK6[2], WK6[3], WK6[4], WK6[5], WK6[6], WK6[7], WK6[8])
                        end
                    end
                    if idtype_def == Int32(0) || idtype_def == Int32(2)
                        if LFIANVB
                            @printf(io_units[JOSTND], "\n%-8s            CUBIC FOOT VOLUME DEFECT MODIFICATION HAS BEEN DISABLED DUE TO PREVIOUS CALL TO FIAVBC.\n           BOARD FOOT VOLUME DEFECT MODIFICATIONS STILL PERMITTED\n", keywrd)
                        else
                            @printf(io_units[JOSTND], "\n%-8s            SAWLOG VOLUME DEFECT PROPORTIONS HAVE BEEN CHANGED FOR SPECIES:%s (CODE=%3d)\n           5 INCH TREES=%6.2f; 10 INCH TREES=%6.2f; 15 INCH TREES=%6.2f\n           20 INCH TREES=%6.2f; 25 INCH TREES=%6.2f; 30 INCH TREES=%6.2f\n           35 INCH TREES=%6.2f; 40 INCH AND LARGER TREES=%6.2f\n", keywrd, sp_str, is, WK6[1], WK6[2], WK6[3], WK6[4], WK6[5], WK6[6], WK6[7], WK6[8])
                        end
                    end
                else
                    if idtype_def == Int32(0) || idtype_def == Int32(1)
                        if LFIANVB
                            @printf(io_units[JOSTND], "\n%-8s            CUBIC FOOT VOLUME DEFECT MODIFICATION HAS BEEN DISABLED DUE TO PREVIOUS CALL TO FIAVBC.\n", keywrd)
                        else
                            @printf(io_units[JOSTND], "\n%-8s            CUBIC FOOT VOLUME DEFECT PROPORTIONS HAVE BEEN CHANGED FOR SPECIES:%s (CODE=%3d)\n           5 INCH TREES=%6.2f; 10 INCH TREES=%6.2f; 15 INCH TREES=%6.2f\n           20 INCH TREES=%6.2f; 25 INCH TREES=%6.2f; 30 INCH TREES=%6.2f\n           35 INCH TREES=%6.2f; 40 INCH AND LARGER TREES=%6.2f\n", keywrd, sp_str, is, WK6[1], WK6[2], WK6[3], WK6[4], WK6[5], WK6[6], WK6[7], WK6[8])
                        end
                    end
                    if idtype_def == Int32(0) || idtype_def == Int32(2)
                        @printf(io_units[JOSTND], "\n%-8s            BOARD FOOT VOLUME DEFECT PROPORTIONS HAVE BEEN CHANGED FOR SPECIES:%s (CODE=%3d)\n           5 INCH TREES=%6.2f; 10 INCH TREES=%6.2f; 15 INCH TREES=%6.2f\n           20 INCH TREES=%6.2f; 25 INCH TREES=%6.2f; 30 INCH TREES=%6.2f\n           35 INCH TREES=%6.2f; 40 INCH AND LARGER TREES=%6.2f\n", keywrd, sp_str, is, WK6[1], WK6[2], WK6[3], WK6[4], WK6[5], WK6[6], WK6[7], WK6[8])
                    end
                end
            end
        elseif is == Int32(0)
            for is_k in 1:MAXSP
                if idtype_def == Int32(0) || idtype_def == Int32(1)
                    if LFIANVB
                        if i_errcnt < Int32(1); ERRGRO(true, Int32(50)); end
                        i_errcnt += Int32(1)
                    else
                        for k_def in 1:8; CFDEFT[k_def+1, is_k] = WK6[k_def]; end
                    end
                end
                if idtype_def == Int32(0) || idtype_def == Int32(2)
                    for k_def in 1:8; BFDEFT[k_def+1, is_k] = WK6[k_def]; end
                end
            end
            if VARACD ∈ ("CS", "LS", "NE", "SN")
                if (idtype_def == Int32(0) || (idtype_def == Int32(1) && lkecho))
                    if LFIANVB
                        @printf(io_units[JOSTND], "\n%-8s            CUBIC FOOT VOLUME DEFECT MODIFICATION HAS BEEN DISABLED DUE TO PREVIOUS CALL TO FIAVBC.\n", keywrd)
                    else
                        @printf(io_units[JOSTND], "\n%-8s            PULPWOOD VOLUME DEFECT PROPORTIONS HAVE BEEN CHANGED FOR ALL SPECIES:\n           5 INCH TREES=%6.2f; 10 INCH TREES=%6.2f; 15 INCH TREES=%6.2f\n           20 INCH TREES=%6.2f; 25 INCH TREES=%6.2f; 30 INCH TREES=%6.2f\n           35 INCH TREES=%6.2f; 40 INCH AND LARGER TREES=%6.2f\n", keywrd, WK6[1], WK6[2], WK6[3], WK6[4], WK6[5], WK6[6], WK6[7], WK6[8])
                        if igndef > Int32(0); @printf(io_units[JOSTND], "           DEFECT PERCENTAGES READ AS PART OF THE TREE RECORD INPUT FOR ALL SPECIES WILL BE IGNORED.\n"); end
                    end
                end
                if (idtype_def == Int32(0) || (idtype_def == Int32(2) && lkecho))
                    if LFIANVB
                        @printf(io_units[JOSTND], "\n%-8s            CUBIC FOOT VOLUME DEFECT MODIFICATION HAS BEEN DISABLED DUE TO PREVIOUS CALL TO FIAVBC.\n           BOARD FOOT VOLUME DEFECT MODIFICATIONS STILL PERMITTED\n", keywrd)
                    else
                        @printf(io_units[JOSTND], "\n%-8s            SAWLOG VOLUME DEFECT PROPORTIONS HAVE BEEN CHANGED FOR ALL SPECIES:\n           5 INCH TREES=%6.2f; 10 INCH TREES=%6.2f; 15 INCH TREES=%6.2f\n           20 INCH TREES=%6.2f; 25 INCH TREES=%6.2f; 30 INCH TREES=%6.2f\n           35 INCH TREES=%6.2f; 40 INCH AND LARGER TREES=%6.2f\n", keywrd, WK6[1], WK6[2], WK6[3], WK6[4], WK6[5], WK6[6], WK6[7], WK6[8])
                        if igndef > Int32(0); @printf(io_units[JOSTND], "           DEFECT PERCENTAGES READ AS PART OF THE TREE RECORD INPUT FOR ALL SPECIES WILL BE IGNORED.\n"); end
                    end
                end
            else
                if (idtype_def == Int32(0) || (idtype_def == Int32(1) && lkecho))
                    if LFIANVB
                        @printf(io_units[JOSTND], "\n%-8s            CUBIC FOOT VOLUME DEFECT MODIFICATION HAS BEEN DISABLED DUE TO PREVIOUS CALL TO FIAVBC.\n", keywrd)
                    else
                        @printf(io_units[JOSTND], "\n%-8s            CUBIC FOOT VOLUME DEFECT PROPORTIONS HAVE BEEN CHANGED FOR ALL SPECIES:\n           5 INCH TREES=%6.2f; 10 INCH TREES=%6.2f; 15 INCH TREES=%6.2f\n           20 INCH TREES=%6.2f; 25 INCH TREES=%6.2f; 30 INCH TREES=%6.2f\n           35 INCH TREES=%6.2f; 40 INCH AND LARGER TREES=%6.2f\n", keywrd, WK6[1], WK6[2], WK6[3], WK6[4], WK6[5], WK6[6], WK6[7], WK6[8])
                        if igndef > Int32(0); @printf(io_units[JOSTND], "           DEFECT PERCENTAGES READ AS PART OF THE TREE RECORD INPUT FOR ALL SPECIES WILL BE IGNORED.\n"); end
                    end
                end
                if (idtype_def == Int32(0) || (idtype_def == Int32(2) && lkecho))
                    @printf(io_units[JOSTND], "\n%-8s            BOARD FOOT VOLUME DEFECT PROPORTIONS HAVE BEEN CHANGED FOR ALL SPECIES:\n           5 INCH TREES=%6.2f; 10 INCH TREES=%6.2f; 15 INCH TREES=%6.2f\n           20 INCH TREES=%6.2f; 25 INCH TREES=%6.2f; 30 INCH TREES=%6.2f\n           35 INCH TREES=%6.2f; 40 INCH AND LARGER TREES=%6.2f\n", keywrd, WK6[1], WK6[2], WK6[3], WK6[4], WK6[5], WK6[6], WK6[7], WK6[8])
                    if igndef > Int32(0); @printf(io_units[JOSTND], "           DEFECT PERCENTAGES READ AS PART OF THE TREE RECORD INPUT FOR ALL SPECIES WILL BE IGNORED.\n"); end
                end
            end
        else
            if idtype_def == Int32(0) || idtype_def == Int32(1)
                if LFIANVB
                    if i_errcnt < Int32(1); ERRGRO(true, Int32(50)); end
                    i_errcnt += Int32(1)
                else
                    for k_def in 1:8; CFDEFT[k_def+1, is] = WK6[k_def]; end
                end
            end
            if idtype_def == Int32(0) || idtype_def == Int32(2)
                for k_def in 1:8; BFDEFT[k_def+1, is] = WK6[k_def]; end
            end
            ilen = Int32(3)
            sp_str = kard[2][1:min(Int(ilen), length(kard[2]))]
            if lkecho
                if VARACD ∈ ("CS", "LS", "NE", "SN")
                    if idtype_def == Int32(0) || idtype_def == Int32(1)
                        if LFIANVB
                            @printf(io_units[JOSTND], "\n%-8s            CUBIC FOOT VOLUME DEFECT MODIFICATION HAS BEEN DISABLED DUE TO PREVIOUS CALL TO FIAVBC.\n", keywrd)
                        else
                            @printf(io_units[JOSTND], "\n%-8s            PULPWOOD VOLUME DEFECT PROPORTIONS HAVE BEEN CHANGED FOR SPECIES:%s (CODE=%3d)\n           5 INCH TREES=%6.2f; 10 INCH TREES=%6.2f; 15 INCH TREES=%6.2f\n           20 INCH TREES=%6.2f; 25 INCH TREES=%6.2f; 30 INCH TREES=%6.2f\n           35 INCH TREES=%6.2f; 40 INCH AND LARGER TREES=%6.2f\n", keywrd, sp_str, is, WK6[1], WK6[2], WK6[3], WK6[4], WK6[5], WK6[6], WK6[7], WK6[8])
                            if igndef > Int32(0); @printf(io_units[JOSTND], "           DEFECT PERCENTAGES READ AS PART OF THE TREE RECORD INPUT FOR ALL SPECIES WILL BE IGNORED.\n"); end
                        end
                    end
                    if idtype_def == Int32(0) || idtype_def == Int32(2)
                        if LFIANVB && idtype_def == Int32(0)
                            @printf(io_units[JOSTND], "\n%-8s            CUBIC FOOT VOLUME DEFECT MODIFICATION HAS BEEN DISABLED DUE TO PREVIOUS CALL TO FIAVBC.\n           BOARD FOOT VOLUME DEFECT MODIFICATIONS STILL PERMITTED\n", keywrd)
                        else
                            @printf(io_units[JOSTND], "\n%-8s            SAWLOG VOLUME DEFECT PROPORTIONS HAVE BEEN CHANGED FOR SPECIES:%s (CODE=%3d)\n           5 INCH TREES=%6.2f; 10 INCH TREES=%6.2f; 15 INCH TREES=%6.2f\n           20 INCH TREES=%6.2f; 25 INCH TREES=%6.2f; 30 INCH TREES=%6.2f\n           35 INCH TREES=%6.2f; 40 INCH AND LARGER TREES=%6.2f\n", keywrd, sp_str, is, WK6[1], WK6[2], WK6[3], WK6[4], WK6[5], WK6[6], WK6[7], WK6[8])
                            if igndef > Int32(0); @printf(io_units[JOSTND], "           DEFECT PERCENTAGES READ AS PART OF THE TREE RECORD INPUT FOR ALL SPECIES WILL BE IGNORED.\n"); end
                        end
                    end
                else
                    if idtype_def == Int32(0) || idtype_def == Int32(1)
                        if LFIANVB
                            @printf(io_units[JOSTND], "\n%-8s            CUBIC FOOT VOLUME DEFECT MODIFICATION HAS BEEN DISABLED DUE TO PREVIOUS CALL TO FIAVBC.\n", keywrd)
                        else
                            @printf(io_units[JOSTND], "\n%-8s            CUBIC FOOT VOLUME DEFECT PROPORTIONS HAVE BEEN CHANGED FOR SPECIES:%s (CODE=%3d)\n           5 INCH TREES=%6.2f; 10 INCH TREES=%6.2f; 15 INCH TREES=%6.2f\n           20 INCH TREES=%6.2f; 25 INCH TREES=%6.2f; 30 INCH TREES=%6.2f\n           35 INCH TREES=%6.2f; 40 INCH AND LARGER TREES=%6.2f\n", keywrd, sp_str, is, WK6[1], WK6[2], WK6[3], WK6[4], WK6[5], WK6[6], WK6[7], WK6[8])
                            if igndef > Int32(0); @printf(io_units[JOSTND], "           DEFECT PERCENTAGES READ AS PART OF THE TREE RECORD INPUT FOR ALL SPECIES WILL BE IGNORED.\n"); end
                        end
                    end
                    if idtype_def == Int32(0) || idtype_def == Int32(2)
                        @printf(io_units[JOSTND], "\n%-8s            BOARD FOOT VOLUME DEFECT PROPORTIONS HAVE BEEN CHANGED FOR SPECIES:%s (CODE=%3d)\n           5 INCH TREES=%6.2f; 10 INCH TREES=%6.2f; 15 INCH TREES=%6.2f\n           20 INCH TREES=%6.2f; 25 INCH TREES=%6.2f; 30 INCH TREES=%6.2f\n           35 INCH TREES=%6.2f; 40 INCH AND LARGER TREES=%6.2f\n", keywrd, sp_str, is, WK6[1], WK6[2], WK6[3], WK6[4], WK6[5], WK6[6], WK6[7], WK6[8])
                        if igndef > Int32(0); @printf(io_units[JOSTND], "           DEFECT PERCENTAGES READ AS PART OF THE TREE RECORD INPUT FOR ALL SPECIES WILL BE IGNORED.\n"); end
                    end
                end
            end
        end
    end
    @goto label_10

    # =======================================================================
    # OPTION 120 — available  (label_12000) — CRUZFILE retired 2021-07-23
    # verified against initre.f lines 4476-4482
    # =======================================================================
    @label label_12000
    @goto label_10

    # =======================================================================
    # OPTION 121 — STANDCN  (label_12100)
    # Stand control number: read supplemental record into DBCN
    # verified against initre.f lines 4485-4493
    # =======================================================================
    @label label_12100
    if eof(io_units[IREAD]); @goto label_80; end
    raw_line = readline(io_units[IREAD])
    global IRECNT += Int32(1)
    global DBCN = strip(raw_line)
    if lkecho; @printf(io_units[JOSTND], "\n%-8s   DATA BASE CONTROL NUMBER=%s\n", keywrd, DBCN); end
    @goto label_10

    # =======================================================================
    # OPTION 122 — THINMIST  (label_12200)
    # Mistletoe thinning: ICFLAG=233; DMR-based; 4-param OPNEW
    # verified against initre.f lines 4495-4556
    # =======================================================================
    @label label_12200
    global ICFLAG = Int32(233)
    idt = Int32(1)
    if lnotbk[1]; idt = Int32(array[1]); end
    if iprmpt > Int32(0)
        if iprmpt != Int32(2)
            KEYDMP(JOSTND, IRECNT, keywrd, array, kard)
            ERRGRO(true, Int32(25))
        else
            kode = OPNEWC(JOSTND, IREAD, idt, ICFLAG, keywrd, kard, iprmpt, IRECNT, ICYC)
            irtncd = fvsGetRtnCode()
            if irtncd != Int32(0); return; end
        end
        @goto label_10
    end
    prms[1] = Float32(0.0)
    if lnotbk[2]; prms[1] = array[2]; end
    if prms[1] < Float32(0.0) || prms[1] > Float32(6.0); prms[1] = Float32(0.0); end
    prms[2] = Float32(0.0)
    if lnotbk[3]; prms[2] = array[3]; end
    if prms[2] < Float32(0.0); prms[2] = Float32(0.0); end
    prms[3] = Float32(999.0)
    if lnotbk[4]; prms[3] = array[4]; end
    if prms[3] <= prms[2]
        KEYDMP(JOSTND, IRECNT, keywrd, array, kard)
        ERRGRO(true, Int32(4))
        @goto label_10
    end
    prms[4] = EFF
    if lnotbk[5]; prms[4] = array[5]; end
    kode = OPNEW(idt, ICFLAG, Int32(4), prms)
    if kode > Int32(0); @goto label_10; end
    if lkecho
        if prms[1] == Float32(0.0)
            @printf(io_units[JOSTND], "\n%-8s   DATE/CYCLE=%5d; TREES WITH A DMR OF 1-6 WILL BE REMOVED.\n", keywrd, idt)
        else
            @printf(io_units[JOSTND], "\n%-8s   DATE/CYCLE=%5d; TREES WITH A DMR OF%5.0f WILL BE REMOVED.\n", keywrd, idt, prms[1])
        end
        @printf(io_units[JOSTND], "           DBH OF REMOVED TREES WILL RANGE FROM %5.1f TO %5.1f INCHES. PROPORTION OF SELECTED TREES REMOVED= %6.3f\n", prms[2], prms[3], prms[4])
    end
    @goto label_10

    # =======================================================================
    # OPTION 123 — TREESZCP  (label_12300)
    # Tree size cap for mortality: SPDECD field 1; SIZCAP(sp,1..4)
    # verified against initre.f lines 4558-4628
    # =======================================================================
    @label label_12300
    begin
        ispc_sz = SPDECD(Int32(1), NSP, JOSTND, IRECNT, keywrd, array, kard)
        if ispc_sz == Int32(-999); @goto label_10; end
        global LMORT = true
        capdbh_sz = Float32(999.0)
        if lnotbk[2]; capdbh_sz = array[2]; end
        capprp_sz = Float32(1.0)
        if lnotbk[3]; capprp_sz = array[3]; end
        capflg_sz = Float32(0.0)
        if lnotbk[4]; capflg_sz = array[4]; end
        idflg_sz  = Int32(capflg_sz)
        capht_sz  = Float32(999.0)
        if lnotbk[5]; capht_sz = array[5]; end
        if capprp_sz < Float32(0.0) || capprp_sz > Float32(1.0) ||
           capdbh_sz < Float32(0.0) || capht_sz < Float32(0.0) ||
           capflg_sz < Float32(0.0) || capflg_sz > Float32(2.0)
            KEYDMP(JOSTND, IRECNT, keywrd, array, kard)
            ERRGRO(true, Int32(4))
            @goto label_10
        end
        if ispc_sz < Int32(0)
            igrp = -ispc_sz
            iulim = Int32(ISPGRP[igrp, 1]) + Int32(1)
            for ig in Int32(2):iulim
                igsp = Int32(ISPGRP[igrp, ig])
                SIZCAP[igsp, 1] = capdbh_sz; SIZCAP[igsp, 2] = capprp_sz
                SIZCAP[igsp, 3] = capflg_sz; SIZCAP[igsp, 4] = capht_sz
            end
            ilen = Int32(ISPGRP[-ispc_sz, 92])
            sp_str = kard[1][1:min(Int(ilen), length(kard[1]))]
            if lkecho; @printf(io_units[JOSTND], "\n%-8s   SPECIES= %s (CODE=%3d);  DBH=%6.1f;  MORTALITY PROPORTION=%7.4f;  DBH USE CODE=%2d;  HT=%6.1f\n", keywrd, sp_str, ispc_sz, capdbh_sz, capprp_sz, idflg_sz, capht_sz); end
        elseif ispc_sz == Int32(0)
            for iss_sz in 1:MAXSP
                SIZCAP[iss_sz, 1] = capdbh_sz; SIZCAP[iss_sz, 2] = capprp_sz
                SIZCAP[iss_sz, 3] = capflg_sz; SIZCAP[iss_sz, 4] = capht_sz
            end
            if lkecho; @printf(io_units[JOSTND], "\n%-8s   SPECIES= ALL (CODE=  0);  DBH=%6.1f;  MORTALITY PROPORTION=%7.4f;  DBH USE CODE=%2d;  HT=%6.1f\n", keywrd, capdbh_sz, capprp_sz, idflg_sz, capht_sz); end
        else
            SIZCAP[ispc_sz, 1] = capdbh_sz; SIZCAP[ispc_sz, 2] = capprp_sz
            SIZCAP[ispc_sz, 3] = capflg_sz; SIZCAP[ispc_sz, 4] = capht_sz
            ilen = Int32(3)
            sp_str = kard[1][1:min(3, length(kard[1]))]
            if lkecho; @printf(io_units[JOSTND], "\n%-8s   SPECIES= %s (CODE=%3d);  DBH=%6.1f;  MORTALITY PROPORTION=%7.4f;  DBH USE CODE=%2d;  HT=%6.1f\n", keywrd, sp_str, ispc_sz, capdbh_sz, capprp_sz, idflg_sz, capht_sz); end
        end
    end
    @goto label_10

    # =======================================================================
    # OPTION 124 — THINRDEN  (label_12400)
    # Relative density thinning: ICFLAG=234; 6-param OPNEW; SPDECD field 4
    # verified against initre.f lines 4630-4724
    # =======================================================================
    @label label_12400
    global ICFLAG = Int32(234)
    idt = Int32(1)
    if lnotbk[1]; idt = Int32(array[1]); end
    if iprmpt > Int32(0)
        if iprmpt != Int32(2)
            KEYDMP(JOSTND, IRECNT, keywrd, array, kard)
            ERRGRO(true, Int32(25))
        else
            kode = OPNEWC(JOSTND, IREAD, idt, ICFLAG, keywrd, kard, iprmpt, IRECNT, ICYC)
            irtncd = fvsGetRtnCode()
            if irtncd != Int32(0); return; end
        end
        @goto label_10
    end
    if lnotbk[2]
        prms[1] = array[2]
    else
        KEYDMP(JOSTND, IRECNT, keywrd, array, kard)
        ERRGRO(true, Int32(4))
        @goto label_10
    end
    prms[2] = EFF
    if lnotbk[3]; prms[2] = array[3]; end
    is = SPDECD(Int32(4), NSP, JOSTND, IRECNT, keywrd, array, kard)
    if is == Int32(-999); @goto label_10; end
    prms[3] = Float32(is)
    prms[4] = Float32(0.0); if lnotbk[5]; prms[4] = array[5]; end
    prms[5] = Float32(999.0); if lnotbk[6]; prms[5] = array[6]; end
    if prms[5] <= prms[4]
        KEYDMP(JOSTND, IRECNT, keywrd, array, kard)
        ERRGRO(true, Int32(4))
        @goto label_10
    end
    prms[6] = Float32(0.0); if lnotbk[7]; prms[6] = array[7]; end
    if prms[6] == Float32(0.0) && prms[2] > Float32(0.0); prms[2] = Float32(0.0); end
    kode = OPNEW(idt, ICFLAG, Int32(6), prms)
    if kode > Int32(0); @goto label_10; end
    if lkecho
        @printf(io_units[JOSTND], "\n%-8s   DATE/CYCLE=%5d; RESIDUAL=%8.2f\n", keywrd, idt, prms[1])
        ilen = Int32(3)
        if is < Int32(0); ilen = Int32(ISPGRP[-is, 92]); end
        sp_str = kard[4][1:min(Int(ilen), length(kard[4]))]
        if prms[2] == Float32(0.0)
            @printf(io_units[JOSTND], "           PROPORTION OF SELECTED TREES REMOVED WILL BE COMPUTED BY THE MODEL\n           SPECIES=%s (CODE=%3d); DBH OF REMOVED TREES WILL RANGE FROM %5.1f TO %5.1f INCHES.\n", sp_str, is, prms[4], prms[5])
        else
            @printf(io_units[JOSTND], "           PROPORTION OF SELECTED TREES REMOVED= %6.3f;\n           SPECIES=%s (CODE=%3d); DBH OF REMOVED TREES WILL RANGE FROM %5.1f TO %5.1f INCHES.\n", prms[2], sp_str, is, prms[4], prms[5])
        end
        if prms[6] == Float32(0.0)
            @printf(io_units[JOSTND], "           CUTTING WILL BE DISTRIBUTED THROUGHOUT THE SPECIFIED DIAMETER CLASS.\n")
        elseif prms[6] == Float32(1.0)
            @printf(io_units[JOSTND], "           CUTTING WILL BE FROM BELOW IN THE SPECIFIED DIAMETER CLASS.\n")
        else
            @printf(io_units[JOSTND], "           CUTTING WILL BE FROM ABOVE IN THE SPECIFIED DIAMETER CLASS.\n")
        end
    end
    @goto label_10

    # =======================================================================
    # OPTION 125 — SPGROUP  (label_12500)
    # Species group builder: multi-record token-based parsing
    # verified against initre.f lines 4726-4832
    # =======================================================================
    @label label_12500
    begin
        if NSPGRP >= Int32(30)
            if lkecho; @printf(io_units[JOSTND], "\nCARD NUM =%5d; KEYWORD FIELD = %-8s   GROUP NAME: %-10s\n", IRECNT, keywrd, kard[1]); end
            ERRGRO(true, Int32(28))
            while true
                if eof(io_units[IREAD]); @goto label_80; end
                rec_sg = readline(io_units[IREAD])
                global IRECNT += Int32(1)
                rlen_sg = length(rstrip(rec_sg))
                if lkecho; @printf(io_units[JOSTND], " SKIPPED RECORD=%s\n", rlen_sg > 0 ? rec_sg[1:rlen_sg] : ""); end
                if rlen_sg == 0 || rec_sg[rlen_sg] != '&'; break; end
            end
            @goto label_10
        end
        global NSPGRP = NSPGRP + Int32(1)
        if lnotbk[1]
            global NAMGRP[NSPGRP] = uppercase(lstrip(kard[1]))
            ilen = Int32(length(rstrip(NAMGRP[NSPGRP])))
        else
            global NAMGRP[NSPGRP] = @sprintf("GROUP%02d   ", NSPGRP)[1:10]
            ilen = Int32(7)
        end
        global ISPGRP[NSPGRP, 92] = ilen
        inum_sg = Int32(0)
        kard   = fill("          ", 12)
        array .= Float32(0)
        while true
            if eof(io_units[IREAD]); @goto label_80; end
            rec_sg = readline(io_units[IREAD])
            global IRECNT += Int32(1)
            has_amp_sg = false
            for tok_sg in split(rec_sg)
                if tok_sg == "&"; has_amp_sg = true; break; end
                uts_sg = uppercase(tok_sg)
                if uts_sg == "ALL"; continue; end
                kard[1] = rpad(uts_sg, 10)
                array[1] = Float32(0.0)
                tryv_sg = tryparse(Float32, tok_sg)
                if tryv_sg !== nothing; array[1] = tryv_sg; end
                ispc_sg = SPDECD(Int32(1), NSP, JOSTND, IRECNT, keywrd, array, kard)
                if array[1] == Float32(0.0); continue; end
                if ispc_sg == Int32(-999); continue; end
                inum_sg += Int32(1)
                if inum_sg > Int32(90); inum_sg = Int32(90); end
                is_dup_sg = false
                if inum_sg > Int32(1)
                    for jdup_sg in 2:Int(inum_sg)
                        if ISPGRP[NSPGRP, jdup_sg] == ispc_sg; is_dup_sg = true; break; end
                    end
                end
                if is_dup_sg
                    inum_sg -= Int32(1)
                else
                    ISPGRP[NSPGRP, inum_sg + 1] = ispc_sg
                end
            end
            if !has_amp_sg; break; end
        end
        global ISPGRP[NSPGRP, 1] = inum_sg
        if lkecho
            @printf(io_units[JOSTND], "\n%-8s   GROUP NUMBER:%4d  GROUP NAME: %-10s  NUMBER OF SPECIES IN THIS GROUP:%3d  SPECIES:\n", keywrd, -Int(NSPGRP), NAMGRP[NSPGRP], inum_sg)
            for jj_sg in 2:Int(inum_sg)+1
                igsp_e = Int(ISPGRP[NSPGRP, jj_sg])
                @printf(io_units[JOSTND], "%3d =%s; ", igsp_e, NSP[igsp_e, 1])
            end
            if inum_sg > Int32(0); @printf(io_units[JOSTND], "\n"); end
        end
    end
    @goto label_10

    # =======================================================================
    # OPTION 126 — BMIN  (label_12600)
    # verified against initre.f lines 4834-4840
    # =======================================================================
    @label label_12600
    if lkecho; @printf(io_units[JOSTND], "\n%-8s   INDIVIDUAL STAND WWPB MODEL OPTIONS:\n", keywrd); end
    BMIN(lkecho)
    @goto label_10

    # =======================================================================
    # OPTION 127 — DATASCRN  (label_12700)
    # Data screen: SDLO=ARRAY(1), SDHI=ARRAY(2); SPDECD field 3 → ISDSP
    # verified against initre.f lines 4842-4873
    # =======================================================================
    @label label_12700
    if lnotbk[1]; sdlo = array[1]; end
    if lnotbk[2]; sdhi = array[2]; end
    is = SPDECD(Int32(3), NSP, JOSTND, IRECNT, keywrd, array, kard)
    if is == Int32(-999); @goto label_10; end
    isdsp = is
    if lkecho
        @printf(io_units[JOSTND], "\n%-8s\n", keywrd)
        if is != Int32(0)
            ilen = Int32(3)
            if is < Int32(0); ilen = Int32(ISPGRP[-is, 92]); end
            @printf(io_units[JOSTND], "           SPECIES= %s (CODE=%3d) IS TARGETED FOR SCREENING.\n", kard[3][1:min(Int(ilen),length(kard[3]))], is)
        else
            @printf(io_units[JOSTND], "           ALL SPECIES (CODE=%3d) ARE TARGETED FOR SCREENING.\n", is)
        end
        @printf(io_units[JOSTND], "           ONLY RECORDS WITH DIAMETERS GE%6.1f INCHES OR LT%6.1f INCHES WILL BE READ FROM THE DATA.\n           ALL OTHER INPUT RECORDS WILL BE SCREENED OUT.\n", sdlo, sdhi)
    end
    @goto label_10

    # =======================================================================
    # OPTION 128 — SETPTHIN  (label_12800)
    # Point thin setup: ICFLAG=248; PTGDECD; ITHNPN/ITHNPA; 6-type echo
    # verified against initre.f lines 4875-4960
    # =======================================================================
    @label label_12800
    global ICFLAG = Int32(248)
    idt = Int32(1)
    if lnotbk[1]; idt = Int32(array[1]); end
    if iprmpt > Int32(0)
        if iprmpt != Int32(2)
            KEYDMP(JOSTND, IRECNT, keywrd, array, kard)
            ERRGRO(true, Int32(25))
        else
            kode = OPNEWC(JOSTND, IREAD, idt, ICFLAG, keywrd, kard, iprmpt, IRECNT, ICYC)
            irtncd = fvsGetRtnCode()
            if irtncd != Int32(0); return; end
        end
        @goto label_10
    end
    begin
        prms[1] = Float32(ITHNPN)
        if lnotbk[2]; prms[1] = array[2]; end
        pointno_pt = Int32(prms[1])
        iflag_pt = PTGDECD(pointno_pt, kard[2])
        if iflag_pt >= Int32(1)
            global ITHNPN = pointno_pt
            prms[1] = Float32(ITHNPN)
            ilen = Int32(IPTGRP[ITHNPN, 52])
            if lkecho; @printf(io_units[JOSTND], "           POINT= %s%3d TARGETED FOR THIS CUT.\n", kard[2][1:min(Int(ilen),length(kard[2]))], Int(ITHNPN)); end
        end
        prms[2] = Float32(ITHNPA)
        if lnotbk[3] && array[3] > Float32(0.0); prms[2] = array[3]; end
        if prms[2] <= Float32(0.0) || prms[2] > Float32(6.0)
            KEYDMP(JOSTND, IRECNT, keywrd, array, kard)
            ERRGRO(true, Int32(4))
            if lkecho; @printf(io_units[JOSTND], "           POINT THINNING RESIDUAL ATTRIBUTE IS MISSING OR INVALID.\n"); end
            @goto label_10
        end
        kode = OPNEW(idt, ICFLAG, Int32(2), prms)
        if kode > Int32(0); @goto label_10; end
        if lkecho
            if prms[2] == Float32(1.0)
                @printf(io_units[JOSTND], "\n%-8s   DATE/CYCLE=%5d; POINT NUMBER=%5.0f; POINT THINNING RESIDUAL ATTRIBUTE=%5.0f (TREES PER ACRE).\n", keywrd, idt, prms[1], prms[2])
            elseif prms[2] == Float32(2.0)
                @printf(io_units[JOSTND], "\n%-8s   DATE/CYCLE=%5d; POINT NUMBER=%5.0f; POINT THINNING RESIDUAL ATTRIBUTE=%5.0f (BASAL AREA PER ACRE).\n", keywrd, idt, prms[1], prms[2])
            elseif prms[2] == Float32(3.0)
                @printf(io_units[JOSTND], "\n%-8s   DATE/CYCLE=%5d; POINT NUMBER=%5.0f; POINT THINNING RESIDUAL ATTRIBUTE=%5.0f (STAND DENSITY INDEX).\n", keywrd, idt, prms[1], prms[2])
            elseif prms[2] == Float32(4.0)
                @printf(io_units[JOSTND], "\n%-8s   DATE/CYCLE=%5d; POINT NUMBER=%5.0f; POINT THINNING RESIDUAL ATTRIBUTE=%5.0f (PERCENT CANOPY COVER).\n", keywrd, idt, prms[1], prms[2])
            elseif prms[2] == Float32(5.0)
                @printf(io_units[JOSTND], "\n%-8s   DATE/CYCLE=%5d; POINT NUMBER=%5.0f; POINT THINNING RESIDUAL ATTRIBUTE=%5.0f (CURTIS RELATIVE DENSITY).\n", keywrd, idt, prms[1], prms[2])
            else
                @printf(io_units[JOSTND], "\n%-8s   DATE/CYCLE=%5d; POINT NUMBER=%5.0f; POINT THINNING RESIDUAL ATTRIBUTE=%5.0f (SILVAH RELATIVE DENSITY).\n", keywrd, idt, prms[1], prms[2])
            end
        end
    end
    @goto label_10

    # =======================================================================
    # OPTION 129 — THINPT  (label_12900)
    # Point thinning: ICFLAG=235; 6-param OPNEW; adds SETPTHIN note in echo
    # verified against initre.f lines 4962-5059
    # =======================================================================
    @label label_12900
    global ICFLAG = Int32(235)
    idt = Int32(1)
    if lnotbk[1]; idt = Int32(array[1]); end
    if iprmpt > Int32(0)
        if iprmpt != Int32(2)
            KEYDMP(JOSTND, IRECNT, keywrd, array, kard)
            ERRGRO(true, Int32(25))
        else
            kode = OPNEWC(JOSTND, IREAD, idt, ICFLAG, keywrd, kard, iprmpt, IRECNT, ICYC)
            irtncd = fvsGetRtnCode()
            if irtncd != Int32(0); return; end
        end
        @goto label_10
    end
    if lnotbk[2]
        prms[1] = array[2]
    else
        KEYDMP(JOSTND, IRECNT, keywrd, array, kard)
        ERRGRO(true, Int32(4))
        @goto label_10
    end
    prms[2] = EFF
    if lnotbk[3]; prms[2] = array[3]; end
    is = SPDECD(Int32(4), NSP, JOSTND, IRECNT, keywrd, array, kard)
    if is == Int32(-999); @goto label_10; end
    prms[3] = Float32(is)
    prms[4] = Float32(0.0); if lnotbk[5]; prms[4] = array[5]; end
    prms[5] = Float32(999.0); if lnotbk[6]; prms[5] = array[6]; end
    if prms[5] <= prms[4]
        KEYDMP(JOSTND, IRECNT, keywrd, array, kard)
        ERRGRO(true, Int32(4))
        @goto label_10
    end
    prms[6] = Float32(0.0); if lnotbk[7]; prms[6] = array[7]; end
    if prms[6] == Float32(0.0) && prms[2] > Float32(0.0); prms[2] = Float32(0.0); end
    kode = OPNEW(idt, ICFLAG, Int32(6), prms)
    if kode > Int32(0); @goto label_10; end
    if lkecho
        @printf(io_units[JOSTND], "\n%-8s   DATE/CYCLE=%5d; RESIDUAL=%8.2f\n", keywrd, idt, prms[1])
        ilen = Int32(3)
        if is < Int32(0); ilen = Int32(ISPGRP[-is, 92]); end
        sp_str = kard[4][1:min(Int(ilen), length(kard[4]))]
        if prms[2] == Float32(0.0)
            @printf(io_units[JOSTND], "           PROPORTION OF SELECTED TREES REMOVED WILL BE COMPUTED BY THE MODEL\n           SPECIES=%s (CODE=%3d); DBH OF REMOVED TREES WILL RANGE FROM %5.1f TO %5.1f INCHES.\n", sp_str, is, prms[4], prms[5])
        else
            @printf(io_units[JOSTND], "           PROPORTION OF SELECTED TREES REMOVED= %6.3f;\n           SPECIES=%s (CODE=%3d); DBH OF REMOVED TREES WILL RANGE FROM %5.1f TO %5.1f INCHES.\n", prms[2], sp_str, is, prms[4], prms[5])
        end
        if prms[6] == Float32(0.0)
            @printf(io_units[JOSTND], "           CUTTING WILL BE DISTRIBUTED THROUGHOUT THE SPECIFIED DIAMETER CLASS,\n")
        elseif prms[6] == Float32(1.0)
            @printf(io_units[JOSTND], "           CUTTING WILL BE FROM BELOW IN THE SPECIFIED DIAMETER CLASS,\n")
        else
            @printf(io_units[JOSTND], "           CUTTING WILL BE FROM ABOVE IN THE SPECIFIED DIAMETER CLASS,\n")
        end
        @printf(io_units[JOSTND], "           ON THE POINT SPECIFIED WITH THE SETPTHIN KEYWORD PRIOR TO THIS THINNING REQUEST.\n")
    end
    @goto label_10

    # =======================================================================
    # OPTION 130 — VOLEQNUM  (label_13000)
    # Volume equation numbers: LFIANVB check; IRDUM from KODFOR/VARACD;
    # VEQNNC/VEQNNB; VOLEQDEF validation
    # verified against initre.f lines 5061-5579
    # =======================================================================
    @label label_13000
    begin
        if LFIANVB
            if lkecho; @printf(io_units[JOSTND], "\n%-8s   KEYWORD REQUEST HAS BEEN RECOGNIZED BUT HAS BEEN DEACTIVIATED BY A PREVIOUS CALL TO USE FIA VBC FOR COMPUTATION OF CUBIC FOOT VOLUMES\n", keywrd); end
            @goto label_10
        end
        irdum_vn   = Int32(0)
        forst_vn   = "  "
        dist_vn    = "  "
        fordum_vn  = "  "
        iregn_vn   = Int32(0)
        errflag_vn = false
        if KODFOR <= Int32(0)
            if     VARACD ∈ ("EM","KT","NI","IE"); irdum_vn = Int32(1)
            elseif VARACD == "CR";                 irdum_vn = Int32(2)
            elseif VARACD ∈ ("CI","TT","UT");      irdum_vn = Int32(4)
            elseif VARACD ∈ ("CA","NC","SO","WS"); irdum_vn = Int32(5)
            elseif VARACD ∈ ("BM","PN","WC","EC"); irdum_vn = Int32(6)
            elseif VARACD ∈ ("OC","OP");           irdum_vn = Int32(7)
            elseif VARACD == "SN";                 irdum_vn = Int32(8)
            elseif VARACD ∈ ("CS","LS","NE");      irdum_vn = Int32(9)
            elseif VARACD == "AK";                 irdum_vn = Int32(10)
            end
        else
            if VARACD == "SN" && KODFOR >= Int32(1000)
                iregn_vn  = Int32(KODFOR) ÷ Int32(10000)
                irdum_vn  = iregn_vn
                iforst_vn = Int32(KODFOR) ÷ Int32(100) - iregn_vn * Int32(100)
                forst_vn  = iforst_vn < 10 ? @sprintf("0%d", iforst_vn) : @sprintf("%d", iforst_vn)
                intdist_vn = Int32(KODFOR) - (Int32(KODFOR) ÷ Int32(100)) * Int32(100)
                dist_vn   = intdist_vn < 10 ? @sprintf("0%d", intdist_vn) : @sprintf("%d", intdist_vn)
            elseif VARACD == "AK"
                iregn_vn  = Int32(10)
                irdum_vn  = Int32(10)
                forst_vn  = "02"
            else
                iregn_vn  = Int32(KODFOR) ÷ Int32(100)
                irdum_vn  = iregn_vn
                iforest_vn = Int32(KODFOR) - Int32(900)
                forst_vn  = iforest_vn < 10 ? @sprintf("0%d", iforest_vn) : @sprintf("%d", iforest_vn)
            end
            if VARACD ∈ ("PN","OP")
                if iregn_vn == Int32(8); irdum_vn = Int32(6); fordum_vn = "09"
                else;                    irdum_vn = iregn_vn; fordum_vn = forst_vn; end
            elseif VARACD == "NC"
                if iregn_vn == Int32(8); irdum_vn = Int32(5); fordum_vn = "10"
                else;                    irdum_vn = iregn_vn; fordum_vn = forst_vn; end
            elseif VARACD == "SO"
                if iregn_vn == Int32(7)
                    if   KODFOR == Int32(701); irdum_vn = Int32(5); fordum_vn = "05"
                    elseif KODFOR == Int32(799); irdum_vn = Int32(6); fordum_vn = "01"
                    end
                else; irdum_vn = iregn_vn; fordum_vn = forst_vn; end
            else
                irdum_vn  = iregn_vn
                fordum_vn = forst_vn
            end
        end
        is_vn = SPDECD(Int32(1), NSP, JOSTND, IRECNT, keywrd, array, kard)
        if is_vn == Int32(-999); @goto label_10; end
        ispec_vn = Int32(9999)
        if is_vn < Int32(0)
            igrp_vn  = -is_vn
            iulim_vn = Int32(ISPGRP[igrp_vn, 1]) + Int32(1)
            ilen_vn  = Int32(ISPGRP[-is_vn, 92])
            igsp_vn  = Int32(ISPGRP[igrp_vn, Int(iulim_vn)])
            if lnotbk[2]
                for ig_vn in 2:Int(iulim_vn); VEQNNC[ISPGRP[igrp_vn, ig_vn]] = kard[2]; end
                ispec_vn = Int32(9999)
                ispec_vn, errflag_vn = VOLEQDEF(VARACD, irdum_vn, fordum_vn, dist_vn, ispec_vn, "02", VEQNNC[igsp_vn])
                if ispec_vn != Int32(8888) && KODFOR <= Int32(0)
                    if irdum_vn==Int32(1) && VARACD=="IE"; irdum_vn=Int32(6); ispec_vn,errflag_vn=VOLEQDEF(VARACD,irdum_vn,fordum_vn,dist_vn,ispec_vn,"02",VEQNNC[igsp_vn]); end
                    if irdum_vn==Int32(2) && VARACD=="CR"; irdum_vn=Int32(3); ispec_vn,errflag_vn=VOLEQDEF(VARACD,irdum_vn,fordum_vn,dist_vn,ispec_vn,"02",VEQNNC[igsp_vn]); end
                    if irdum_vn==Int32(5) && VARACD∈("CA","NC","SO","OC"); irdum_vn=Int32(6); ispec_vn,errflag_vn=VOLEQDEF(VARACD,irdum_vn,fordum_vn,dist_vn,ispec_vn,"02",VEQNNC[igsp_vn]); end
                    if irdum_vn==Int32(7) && VARACD=="OC"
                        irdum_vn=Int32(6); ispec_vn,errflag_vn=VOLEQDEF(VARACD,irdum_vn,fordum_vn,dist_vn,ispec_vn,"02",VEQNNC[igsp_vn])
                        if ispec_vn!=Int32(8888); irdum_vn=Int32(5); ispec_vn,errflag_vn=VOLEQDEF(VARACD,irdum_vn,fordum_vn,dist_vn,ispec_vn,"02",VEQNNC[igsp_vn]); end
                    end
                end
                if ispec_vn != Int32(8888)
                    for ig_vn in 2:Int(iulim_vn); VEQNNC[ISPGRP[igrp_vn,ig_vn]] = "           "; end
                    @printf(io_units[JOSTND], "\n%-8s   INVALID VOLUME EQUATION NUMBER: THE DEFAULT CUBIC FT EQUATION NUMBER WILL BE USED FOR SPECIES GROUP=%s (CODE=%3d);\n", keywrd, kard[1][1:min(Int(ilen_vn),length(kard[1]))], is_vn)
                else
                    if lkecho; @printf(io_units[JOSTND], "\n%-8s   NATIONAL CRUISE SYSTEM CUBIC FT VOLUME EQUATION NUMBERS CHANGED FOR SPECIES GROUP=%s (CODE=%3d);\n", keywrd, kard[1][1:min(Int(ilen_vn),length(kard[1]))], is_vn); end
                end
            end
            if lnotbk[3]
                for ig_vn in 2:Int(iulim_vn); VEQNNB[ISPGRP[igrp_vn, ig_vn]] = kard[3]; end
                ispec_vn = Int32(9999)
                ispec_vn, errflag_vn = VOLEQDEF(VARACD, irdum_vn, fordum_vn, dist_vn, ispec_vn, "01", VEQNNB[igsp_vn])
                kw_bf_sg = lnotbk[2] ? "        " : keywrd
                if ispec_vn != Int32(8888)
                    for ig_vn in 2:Int(iulim_vn); VEQNNB[ISPGRP[igrp_vn,ig_vn]] = "           "; end
                    @printf(io_units[JOSTND], "\n%-8s   INVALID VOLUME EQUATION NUMBER: THE DEFAULT BOARD FT EQUATION NUMBER WILL BE USED FOR SPECIES GROUP=%s (CODE=%3d);\n", kw_bf_sg, kard[1][1:min(Int(ilen_vn),length(kard[1]))], is_vn)
                else
                    if lkecho; @printf(io_units[JOSTND], "\n%-8s   NATIONAL CRUISE SYSTEM BOARD FT VOLUME EQUATION NUMBERS CHANGED FOR SPECIES GROUP=%s (CODE=%3d);\n", kw_bf_sg, kard[1][1:min(Int(ilen_vn),length(kard[1]))], is_vn); end
                end
            end
        elseif is_vn == Int32(0)
            if lnotbk[2]
                for iss_vn in 1:MAXSP; VEQNNC[iss_vn] = kard[2]; end
                ispec_vn = Int32(9999)
                ispec_vn, errflag_vn = VOLEQDEF(VARACD, irdum_vn, fordum_vn, dist_vn, ispec_vn, "02", VEQNNC[1])
                if ispec_vn != Int32(8888) && KODFOR <= Int32(0)
                    if irdum_vn==Int32(1) && VARACD=="IE"; irdum_vn=Int32(6); ispec_vn,errflag_vn=VOLEQDEF(VARACD,irdum_vn,fordum_vn,dist_vn,ispec_vn,"02",VEQNNC[1]); end
                    if irdum_vn==Int32(2) && VARACD=="CR"; irdum_vn=Int32(3); ispec_vn,errflag_vn=VOLEQDEF(VARACD,irdum_vn,fordum_vn,dist_vn,ispec_vn,"02",VEQNNC[1]); end
                    if irdum_vn==Int32(5) && VARACD∈("CA","NC","SO","OC"); irdum_vn=Int32(6); ispec_vn,errflag_vn=VOLEQDEF(VARACD,irdum_vn,fordum_vn,dist_vn,ispec_vn,"02",VEQNNC[1]); end
                    if irdum_vn==Int32(7) && VARACD=="OC"
                        irdum_vn=Int32(6); ispec_vn,errflag_vn=VOLEQDEF(VARACD,irdum_vn,fordum_vn,dist_vn,ispec_vn,"02",VEQNNC[1])
                        if ispec_vn!=Int32(8888); irdum_vn=Int32(5); ispec_vn,errflag_vn=VOLEQDEF(VARACD,irdum_vn,fordum_vn,dist_vn,ispec_vn,"02",VEQNNC[1]); end
                    end
                end
                if ispec_vn != Int32(8888)
                    for iss_vn in 1:MAXSP; VEQNNC[iss_vn] = "           "; end
                    @printf(io_units[JOSTND], "\n%-8s   INVALID VOLUME EQUATION NUMBER: THE DEFAULT CUBIC FT EQUATION NUMBERS WILL BE USED FOR ALL SPECIES:\n", keywrd)
                else
                    if lkecho; @printf(io_units[JOSTND], "\n%-8s   NATIONAL CRUISE SYSTEM CUBIC FT VOLUME EQUATION NUMBERS CHANGED FOR ALL SPECIES:\n", keywrd); end
                end
            end
            if lnotbk[3]
                for iss_vn in 1:MAXSP; VEQNNB[iss_vn] = kard[3]; end
                ispec_vn = Int32(9999)
                ispec_vn, errflag_vn = VOLEQDEF(VARACD, irdum_vn, fordum_vn, dist_vn, ispec_vn, "01", VEQNNB[1])
                kw_bf_all = lnotbk[2] ? "        " : keywrd
                if ispec_vn != Int32(8888)
                    for iss_vn in 1:MAXSP; VEQNNB[iss_vn] = "           "; end
                    @printf(io_units[JOSTND], "\n%-8s   INVALID VOLUME EQUATION NUMBER: THE DEFAULT BOARD FT EQUATION NUMBERS WILL BE USED FOR ALL SPECIES:\n", kw_bf_all)
                else
                    if lkecho; @printf(io_units[JOSTND], "\n%-8s   NATIONAL CRUISE SYSTEM BOARD FT VOLUME EQUATION NUMBERS CHANGED FOR ALL SPECIES:\n", kw_bf_all); end
                end
            end
        else
            if lnotbk[2]
                VEQNNC[is_vn] = kard[2]
                ispec_vn = Int32(9999)
                ispec_vn, errflag_vn = VOLEQDEF(VARACD, irdum_vn, fordum_vn, dist_vn, ispec_vn, "02", VEQNNC[is_vn])
                if ispec_vn != Int32(8888) && KODFOR <= Int32(0)
                    if irdum_vn==Int32(1) && VARACD=="IE"; irdum_vn=Int32(6); ispec_vn,errflag_vn=VOLEQDEF(VARACD,irdum_vn,fordum_vn,dist_vn,ispec_vn,"02",VEQNNC[is_vn]); end
                    if irdum_vn==Int32(2) && VARACD=="CR"; irdum_vn=Int32(3); ispec_vn,errflag_vn=VOLEQDEF(VARACD,irdum_vn,fordum_vn,dist_vn,ispec_vn,"02",VEQNNC[is_vn]); end
                    if irdum_vn==Int32(5) && VARACD∈("CA","NC","SO","OC"); irdum_vn=Int32(6); ispec_vn,errflag_vn=VOLEQDEF(VARACD,irdum_vn,fordum_vn,dist_vn,ispec_vn,"02",VEQNNC[is_vn]); end
                    if irdum_vn==Int32(7) && VARACD=="OC"
                        irdum_vn=Int32(6); ispec_vn,errflag_vn=VOLEQDEF(VARACD,irdum_vn,fordum_vn,dist_vn,ispec_vn,"02",VEQNNC[is_vn])
                        if ispec_vn!=Int32(8888); irdum_vn=Int32(5); ispec_vn,errflag_vn=VOLEQDEF(VARACD,irdum_vn,fordum_vn,dist_vn,ispec_vn,"02",VEQNNC[is_vn]); end
                    end
                end
                if ispec_vn != Int32(8888)
                    VEQNNC[is_vn] = "           "; kard[2] = "***INVALID"
                    @printf(io_units[JOSTND], "\n%-8s   NATIONAL CRUISE SYSTEM VOLUME EQUATION NUMBERS CHANGED FOR SPECIES=%s (CODE=%3d);\n", keywrd, kard[1][1:3], is_vn)
                else
                    if lkecho; @printf(io_units[JOSTND], "\n%-8s   NATIONAL CRUISE SYSTEM VOLUME EQUATION NUMBERS CHANGED FOR SPECIES=%s (CODE=%3d);\n", keywrd, kard[1][1:3], is_vn); end
                end
            end
            if lnotbk[3]
                VEQNNB[is_vn] = kard[3]
                ispec_vn = Int32(9999)
                ispec_vn, errflag_vn = VOLEQDEF(VARACD, irdum_vn, fordum_vn, dist_vn, ispec_vn, "01", VEQNNB[is_vn])
                if ispec_vn != Int32(8888)
                    if KODFOR <= Int32(0)
                        if irdum_vn==Int32(1) && VARACD=="IE"; irdum_vn=Int32(6); ispec_vn,errflag_vn=VOLEQDEF(VARACD,irdum_vn,fordum_vn,dist_vn,ispec_vn,"01",VEQNNB[is_vn]); end
                        if irdum_vn==Int32(2) && VARACD=="CR"; irdum_vn=Int32(3); ispec_vn,errflag_vn=VOLEQDEF(VARACD,irdum_vn,fordum_vn,dist_vn,ispec_vn,"01",VEQNNB[is_vn]); end
                        if irdum_vn==Int32(5) && VARACD∈("CA","NC","SO","OC"); irdum_vn=Int32(6); ispec_vn,errflag_vn=VOLEQDEF(VARACD,irdum_vn,fordum_vn,dist_vn,ispec_vn,"01",VEQNNB[is_vn]); end
                        if irdum_vn==Int32(7) && VARACD=="OC"
                            irdum_vn=Int32(6); ispec_vn,errflag_vn=VOLEQDEF(VARACD,irdum_vn,fordum_vn,dist_vn,ispec_vn,"01",VEQNNB[is_vn])
                            if ispec_vn!=Int32(8888); irdum_vn=Int32(5); ispec_vn,errflag_vn=VOLEQDEF(VARACD,irdum_vn,fordum_vn,dist_vn,ispec_vn,"01",VEQNNB[is_vn]); end
                        end
                    end
                end
                if ispec_vn != Int32(8888)
                    VEQNNB[is_vn] = "           "; kard[3] = "***INVALID"
                    if !lnotbk[2]; @printf(io_units[JOSTND], "\n%-8s   NATIONAL CRUISE SYSTEM VOLUME EQUATION NUMBERS CHANGED FOR SPECIES=%s (CODE=%3d);\n", keywrd, kard[1][1:3], is_vn); end
                else
                    if !lnotbk[2] && lkecho; @printf(io_units[JOSTND], "\n%-8s   NATIONAL CRUISE SYSTEM VOLUME EQUATION NUMBERS CHANGED FOR SPECIES=%s (CODE=%3d);\n", keywrd, kard[1][1:3], is_vn); end
                end
            end
        end
        if lnotbk[2] && lnotbk[3]
            if lkecho; @printf(io_units[JOSTND], "         CUBIC FOOT = %-10s   BOARD FOOT = %-10s\n", kard[2], kard[3]); end
        elseif lnotbk[2]
            if lkecho; @printf(io_units[JOSTND], "         CUBIC FOOT = %-10s\n", kard[2]); end
        elseif lnotbk[3]
            if lkecho; @printf(io_units[JOSTND], "         BOARD FOOT = %-10s\n", kard[3]); end
        else
            @printf(io_units[JOSTND], "          EQUATION NUMBERS NOT SPECIFIED.  REQUEST CANCELLED.\n")
        end
    end
    @goto label_10

    # =======================================================================
    # OPTION 131 — POINTREF  (label_13100)
    # Point reference indicator: ITHNPI from ARRAY(1); validated [0,2]
    # verified against initre.f lines 5581-5602
    # =======================================================================
    @label label_13100
    if lnotbk[1]; global ITHNPI = Int32(array[1] + Float32(0.5)); end
    if ITHNPI < Int32(0) || ITHNPI > Int32(2)
        KEYDMP(JOSTND, IRECNT, keywrd, array, kard)
        ERRGRO(true, Int32(4))
        @printf(io_units[JOSTND], "           INVALID POINT INDICATOR. POINT INDICATOR BEING RESET TO 1 (POINT NUMBERS FROM DATA) FOR FURTHER PROCESSING.\n")
        global ITHNPI = Int32(1)
        @goto label_10
    end
    if lkecho
        if ITHNPI == Int32(1)
            @printf(io_units[JOSTND], "\n%-8s   POINT NUMBERS ARE AS INPUT IN THE TREE DATA.\n", keywrd)
        else
            @printf(io_units[JOSTND], "\n%-8s   POINT NUMBERS ARE THE FVS SEQUENTIAL POINT NUMBERS.\n", keywrd)
        end
    end
    @goto label_10

    # =======================================================================
    # OPTION 132 — ECHO  (label_13200)
    # Enable keyword echo: lkecho=true; count and report skipped records
    # verified against initre.f lines 5604-5616
    # =======================================================================
    @label label_13200
    lkecho = true
    if IRECNT > jrecnt
        jrecnt = IRECNT - jrecnt - Int32(1)
    else
        jrecnt = IRECNT
    end
    @printf(io_units[JOSTND], "\n%-8s   THERE WERE%8d KEYWORD RECORDS PROCESSED. KEYWORD ECHO WILL RESUME.\n", keywrd, jrecnt)
    @goto label_10

    # =======================================================================
    # OPTION 133 — NOECHO  (label_13300)
    # Suppress keyword echo: lkecho=false; save IRECNT for count in ECHO
    # verified against initre.f lines 5618-5626
    # =======================================================================
    @label label_13300
    lkecho = false
    jrecnt = IRECNT
    @printf(io_units[JOSTND], "\n%-8s   KEYWORDS WILL **NOT** BE ECHOED TO THE MAIN OUTPUT FILE.\n", keywrd)
    @goto label_10

    # =======================================================================
    # OPTION 134 — CYCLEAT  (label_13400)
    # Add cycle year to IWORK1 list (not IY): NEWYR from ARRAY(1)
    # verified against initre.f lines 5628-5656
    # =======================================================================
    @label label_13400
    newyr = Int32(array[1])
    if newyr <= Int32(0)
        KEYDMP(JOSTND, IRECNT, keywrd, array, kard)
        ERRGRO(true, Int32(4))
    else
        if IWORK1[1] == Int32(0)
            IWORK1[1] = Int32(1)
            IWORK1[2] = newyr
        else
            i1 = IWORK1[1] + Int32(1)
            i2 = Int32(0)
            for k_cy in 2:Int(i1)
                if IWORK1[k_cy] == newyr; i2 = Int32(k_cy); break; end
            end
            if i2 == Int32(0)
                IWORK1[1] = i1
                IWORK1[i1 + 1] = newyr
            end
        end
        if lkecho; @printf(io_units[JOSTND], "\n%-8s   REQUESTED YEAR FOR A CYCLE =%4d\n", keywrd, newyr); end
    end
    @goto label_10

    # =======================================================================
    # OPTION 135 — ATRTLIST  (label_13500)
    # Attribute tree list: OPNEW act=198; NP=2 (or 3 if lnotbk[4]); no IPRMPT
    # verified against initre.f lines 5658-5672
    # =======================================================================
    @label label_13500
    idt = Int32(1)
    if lnotbk[1]; idt = Int32(array[1]); end
    np = Int32(2)
    if lnotbk[4]; np = Int32(3); end
    if !lnotbk[2]; array[2] = Float32(JOLIST); end
    kode = OPNEW(idt, Int32(198), np, view(array, 2:12))
    if kode > Int32(0); @goto label_10; end
    if lkecho
        @printf(io_units[JOSTND], "\n%-8s   DATE/CYCLE=%5d; DATA SET REFERENCE NUMBER =%4.0f; HEADING SUPPRESSION CODE =%3.0f\n           (0=WITH HEADING, OTHER VALUES=SUPPRESS HEADING).\n", keywrd, idt, array[2], array[3])
    end
    @goto label_10

    # =======================================================================
    # OPTION 136 — THINRDSL  (label_13600)
    # NE-variant relative density thinning: VARACD check; ICFLAG=236
    # verified against initre.f lines 5674-5757
    # =======================================================================
    @label label_13600
    if VARACD != "NE"
        KEYDMP(JOSTND, IRECNT, keywrd, array, kard)
        @printf(io_units[JOSTND], "\n********   THIS KEYWORD IS NOT VALID FOR THIS VARIANT. KEYWORD IGNORED.\n")
        @goto label_10
    end
    global ICFLAG = Int32(236)
    idt = Int32(1)
    if lnotbk[1]; idt = Int32(array[1]); end
    if iprmpt > Int32(0)
        if iprmpt != Int32(2)
            KEYDMP(JOSTND, IRECNT, keywrd, array, kard)
            ERRGRO(true, Int32(25))
        else
            kode = OPNEWC(JOSTND, IREAD, idt, ICFLAG, keywrd, kard, iprmpt, IRECNT, ICYC)
            irtncd = fvsGetRtnCode()
            if irtncd != Int32(0); return; end
        end
        @goto label_10
    end
    if lnotbk[2]
        prms[1] = array[2]
    else
        KEYDMP(JOSTND, IRECNT, keywrd, array, kard)
        ERRGRO(true, Int32(4))
        @goto label_10
    end
    prms[2] = EFF; if lnotbk[3]; prms[2] = array[3]; end
    is = SPDECD(Int32(4), NSP, JOSTND, IRECNT, keywrd, array, kard)
    if is == Int32(-999); @goto label_10; end
    prms[3] = Float32(is)
    prms[4] = Float32(0.0); if lnotbk[5]; prms[4] = array[5]; end
    prms[5] = Float32(999.0); if lnotbk[6]; prms[5] = array[6]; end
    if prms[5] <= prms[4]
        KEYDMP(JOSTND, IRECNT, keywrd, array, kard)
        ERRGRO(true, Int32(4))
        @goto label_10
    end
    prms[6] = Float32(0.0); if lnotbk[7]; prms[6] = array[7]; end
    if prms[6] == Float32(0.0) && prms[2] > Float32(0.0); prms[2] = Float32(0.0); end
    kode = OPNEW(idt, ICFLAG, Int32(6), prms)
    if kode > Int32(0); @goto label_10; end
    if lkecho
        @printf(io_units[JOSTND], "\n%-8s   DATE/CYCLE=%5d; RESIDUAL=%8.2f\n", keywrd, idt, prms[1])
        ilen = Int32(3)
        if is < Int32(0); ilen = Int32(ISPGRP[-is, 92]); end
        sp_str = kard[4][1:min(Int(ilen), length(kard[4]))]
        if prms[2] == Float32(0.0)
            @printf(io_units[JOSTND], "           PROPORTION OF SELECTED TREES REMOVED WILL BE COMPUTED BY THE MODEL\n           SPECIES=%s (CODE=%3d); DBH OF REMOVED TREES WILL RANGE FROM %5.1f TO %5.1f INCHES.\n", sp_str, is, prms[4], prms[5])
        else
            @printf(io_units[JOSTND], "           PROPORTION OF SELECTED TREES REMOVED= %6.3f;\n           SPECIES=%s (CODE=%3d); DBH OF REMOVED TREES WILL RANGE FROM %5.1f TO %5.1f INCHES.\n", prms[2], sp_str, is, prms[4], prms[5])
        end
        if prms[6] == Float32(0.0)
            @printf(io_units[JOSTND], "           CUTTING WILL BE DISTRIBUTED THROUGHOUT THE SPECIFIED DIAMETER CLASS.\n")
        elseif prms[6] == Float32(1.0)
            @printf(io_units[JOSTND], "           CUTTING WILL BE FROM BELOW IN THE SPECIFIED DIAMETER CLASS.\n")
        else
            @printf(io_units[JOSTND], "           CUTTING WILL BE FROM ABOVE IN THE SPECIFIED DIAMETER CLASS.\n")
        end
    end
    @goto label_10

    # =======================================================================
    # OPTION 137 — MORTMSB  (label_13700)
    # Mature stand boundary mortality: validated QMDMSB/SLPMSB/EFFMSB/etc.
    # verified against initre.f lines 5759-5840
    # =======================================================================
    @label label_13700
    if lnotbk[1]
        if array[1] > Float32(0.0)
            global QMDMSB = array[1]
        else
            KEYDMP(JOSTND, IRECNT, keywrd, array, kard)
            ERRGRO(true, Int32(4))
            @goto label_13714
        end
    end
    if lnotbk[2]
        if array[2] <= Float32(-1.605) && array[2] >= Float32(-10.0)
            global SLPMSB = array[2]
        else
            KEYDMP(JOSTND, IRECNT, keywrd, array, kard)
            ERRGRO(true, Int32(4))
            @goto label_13714
        end
    end
    if lnotbk[3]
        if array[3] > Float32(0.0) && array[3] <= Float32(1.0)
            global EFFMSB = array[3]
        else
            KEYDMP(JOSTND, IRECNT, keywrd, array, kard)
            ERRGRO(true, Int32(4))
            @goto label_13714
        end
    end
    if lnotbk[4] && array[4] >= Float32(0.0); global DLOMSB = array[4]; end
    if lnotbk[5] && array[5] >= Float32(0.0); global DHIMSB = array[5]; end
    if DLOMSB >= DHIMSB
        KEYDMP(JOSTND, IRECNT, keywrd, array, kard)
        ERRGRO(true, Int32(4))
        @goto label_13714
    end
    if lnotbk[6]
        if array[6] >= Float32(1.0) && array[6] <= Float32(3.0)
            global MFLMSB = Int32(array[6])
        else
            KEYDMP(JOSTND, IRECNT, keywrd, array, kard)
            ERRGRO(true, Int32(4))
            @goto label_13714
        end
    end
    if lkecho
        @printf(io_units[JOSTND], "\n%-8s   MATURE STAND BOUNDARY: QMD =%9.4f;  SLOPE = %9.4f;  MORTALITY EFFICIENCY = %9.4f;\n           LOWER DBH (GE) = %6.1f;  UPPER DBH (LT) = %6.1f;  MORTALITY FLAG = %1d\n", keywrd, QMDMSB, SLPMSB, EFFMSB, DLOMSB, DHIMSB, MFLMSB)
        if MFLMSB == Int32(1)
            @printf(io_units[JOSTND], "           (MORTALITY WILL BE FROM ABOVE WITHIN THE SPECIFIED DBH RANGE.)\n")
        elseif MFLMSB == Int32(2)
            @printf(io_units[JOSTND], "           (MORTALITY WILL BE FROM BELOW WITHIN THE SPECIFIED DBH RANGE.)\n")
        else
            @printf(io_units[JOSTND], "           (MORTALITY WILL BE SPREAD THROUGHOUT THE SPECIFIED DBH RANGE.)\n")
        end
    end
    @goto label_10
    @label label_13714
    global QMDMSB = Float32(999.0); global SLPMSB = Float32(0.0); global CEPMSB = Float32(0.0)
    global EFFMSB = Float32(0.90);  global DLOMSB = Float32(0.0); global DHIMSB = Float32(999.0)
    global MFLMSB = Int32(1)
    @goto label_10

    # =======================================================================
    # OPTION 138 — SETSITE  (label_13800)
    # Set site: IPRMPT; HABTYP save/restore; SPDECD field 4; OPNEW act=120 NP=6
    # verified against initre.f lines 5842-5944
    # =======================================================================
    @label label_13800
    idt = Int32(1)
    if lnotbk[1]; idt = Int32(array[1]); end
    if iprmpt > Int32(0)
        if iprmpt != Int32(2)
            KEYDMP(JOSTND, IRECNT, keywrd, array, kard)
            ERRGRO(true, Int32(25))
        else
            kode = OPNEWC(JOSTND, IREAD, idt, Int32(120), keywrd, kard, iprmpt, IRECNT, ICYC)
            irtncd = fvsGetRtnCode()
            if irtncd != Int32(0); return; end
        end
        @goto label_10
    end
    begin
        ihab_ss = Int32(0)
        if lnotbk[2]
            idum1_ss = ICL5; idum2_ss = ITYPE; idum3_ss = KODTYP; pvrdum_ss = CPVREF; tpcom_ss = PCOM
            global KODTYP = Int32(array[2]); global ICL5 = KODTYP; global CPVREF = "          "
            HABTYP(kard[2], array[2])
            array[2] = Float32(KODTYP)
            ihab_ss = KODTYP
            global ICL5 = idum1_ss; global ITYPE = idum2_ss; global KODTYP = idum3_ss
            global CPVREF = pvrdum_ss; global PCOM = tpcom_ss
        end
        if !lnotbk[3]; array[3] = Float32(0.0); end
        is = SPDECD(Int32(4), NSP, JOSTND, IRECNT, keywrd, array, kard)
        if is == Int32(-999); @goto label_10; end
        if !lnotbk[5]; array[5] = Float32(0.0); end
        if !lnotbk[6]; array[6] = Float32(0.0); end
        if !lnotbk[7]; array[7] = Float32(0.0); end
        ilen = Int32(3)
        if is < Int32(0); ilen = Int32(ISPGRP[-is, 92]); end
        if lkecho
            @printf(io_units[JOSTND], "\n%-8s   DATE/CYCLE=%5d\n", keywrd, idt)
            if array[2] != Float32(0.0); @printf(io_units[JOSTND], "           HABITAT TYPE=%5d\n", ihab_ss); end
            if array[3] != Float32(0.0); @printf(io_units[JOSTND], "           BASAL AREA MAXIMUM=%5.0f\n", array[3]); end
            if array[5] != Float32(0.0)
                @printf(io_units[JOSTND], "           SPECIES=%s (CODE=%3d); SITE INDEX=%10.1f\n", kard[4][1:min(Int(ilen),length(kard[4]))], is, array[5])
                if array[6] == Float32(0.0)
                    @printf(io_units[JOSTND], "           SITE INDEX VALUE IS ENTERED DIRECTLY\n")
                else
                    @printf(io_units[JOSTND], "           SITE INDEX VALUE ENTERED AS A PERCENT CHANGE\n")
                end
            end
            if array[7] != Float32(0.0); @printf(io_units[JOSTND], "           STAND DENSITY INDEX=%5.0f\n", array[7]); end
        end
        kode = OPNEW(idt, Int32(120), Int32(6), view(array, 2:12))
    end
    @goto label_10

    # =======================================================================
    # OPTION 139 — CLIMATE  (label_13900)
    # verified against initre.f lines 5946-5954
    # =======================================================================
    @label label_13900
    if lkecho; @printf(io_units[JOSTND], "\n%-8s   CLIMATE EXTENSION KEYWORDS:\n", keywrd); end
    CLIN(debug, lkecho)
    irtncd = fvsGetRtnCode()
    if irtncd != Int32(0); return; end
    @goto label_10

    # =======================================================================
    # OPTION 140 — SDICALC  (label_14000)
    # SDI method: always reset DBHSTAGE/DBHZEIDE first; echo
    # verified against initre.f lines 5956-5979
    # =======================================================================
    @label label_14000
    global DBHSTAGE = Float32(0.0)
    if lnotbk[1]; global DBHSTAGE = array[1]; end
    global DBHZEIDE = Float32(0.0)
    if lnotbk[2]; global DBHZEIDE = array[2]; end
    if array[3] >= Float32(1.0)
        global LZEIDE  = true
        global CALCSDI = "ZEIDE  "
    else
        global LZEIDE  = false
        global CALCSDI = "REINEKE"
    end
    if lkecho; @printf(io_units[JOSTND], "\n%-8s   THE %-7s METHOD WILL BE USED TO CALCULATE SDI.\n           THE MINIMUM DIAMETER USED IN REINEKE SDI CALCULATIONS = %6.2f IN\n           THE MINIMUM DIAMETER USED IN ZEIDE SDI CALCULATIONS = %6.2f IN\n", keywrd, CALCSDI, DBHSTAGE, DBHZEIDE); end
    @goto label_10

    # =======================================================================
    # OPTION 141 — THINQFA  (label_14100)
    # Q-factor thinning: SPDECD field 4; raw READ(IREAD,'(I1)') for ISETQFA
    # verified against initre.f lines 5981-6063
    # =======================================================================
    @label label_14100
    global ICFLAG = Int32(237)
    idt = Int32(1)
    if lnotbk[1]; idt = Int32(array[1]); end
    if iprmpt > Int32(0)
        if iprmpt != Int32(2)
            KEYDMP(JOSTND, IRECNT, keywrd, array, kard)
            ERRGRO(true, Int32(25))
        else
            kode = OPNEWC(JOSTND, IREAD, idt, ICFLAG, keywrd, kard, iprmpt, IRECNT, ICYC)
            irtncd = fvsGetRtnCode()
            if irtncd != Int32(0); return; end
        end
        @goto label_10
    end
    is = SPDECD(Int32(4), NSP, JOSTND, IRECNT, keywrd, array, kard)
    if is == Int32(-999); @goto label_10; end
    prms[3] = Float32(is)
    prms[1] = Float32(0.0);   if lnotbk[2]; prms[1] = array[2]; end
    prms[2] = Float32(24.0);  if lnotbk[3]; prms[2] = array[3]; end
    prms[4] = Float32(1.4);   if lnotbk[5]; prms[4] = array[5]; end
    prms[5] = Float32(2.0);   if lnotbk[6]; prms[5] = array[6]; end
    prms[6] = Float32(0.0);   if lnotbk[7]; prms[6] = array[7]; end
    begin
        isetqfa_v = Int32(0)
        if eof(io_units[IREAD]); @goto label_80; end
        raw_line = readline(io_units[IREAD])
        global IRECNT += Int32(1)
        if !isempty(raw_line)
            tv = tryparse(Int32, raw_line[1:1])
            if tv !== nothing; isetqfa_v = tv; end
        end
        ctarget_v = "TARGET BA= "
        if isetqfa_v <= Int32(0);       prms[7] = Float32(0.0); ctarget_v = "TARGET BA= "
        elseif isetqfa_v <= Int32(1);   prms[7] = Float32(1.0); ctarget_v = "TARGET TPA="
        else;                            prms[7] = Float32(2.0); ctarget_v = "TARGET SDI="
        end
        kode = OPNEW(idt, ICFLAG, Int32(7), prms)
        if kode > Int32(0); @goto label_10; end
        if lkecho
            @printf(io_units[JOSTND], "\n%-8s   DATE/CYCLE=%5d; MINIMUM %8.1f; MAXIMUM %8.1f\n", keywrd, idt, prms[1], prms[2])
            if is != Int32(0)
                ilen = Int32(3)
                if is < Int32(0); ilen = Int32(ISPGRP[-is, 92]); end
                @printf(io_units[JOSTND], "            SPECIES= %s (CODE=%3d) IS TARGETED FOR THIS CUT.\n", kard[4][1:min(Int(ilen),length(kard[4]))], is)
            else
                @printf(io_units[JOSTND], "             ALL SPECIES (CODE=%3d) ARE TARGETED FOR THIS CUT.\n", is)
            end
            @printf(io_units[JOSTND], "           Q FACTOR= %8.3f\n           DIA. CLASS WIDTH= %6.1f\n           %s%6.1f\n", prms[4], prms[5], ctarget_v, prms[6])
        end
    end
    @goto label_10

    # =======================================================================
    # OPTION 142 — PTGROUP  (label_14200)
    # Point group builder: multi-record, like SPGROUP but for plot numbers
    # verified against initre.f lines 6065-6159
    # =======================================================================
    @label label_14200
    begin
        if NPTGRP >= Int32(30)
            if lkecho; @printf(io_units[JOSTND], "\nCARD NUM =%5d; KEYWORD FIELD = %-8s   GROUP NAME: %-10s\n", IRECNT, keywrd, kard[1]); end
            ERRGRO(true, Int32(37))
            while true
                if eof(io_units[IREAD]); @goto label_80; end
                rec_pt = readline(io_units[IREAD])
                global IRECNT += Int32(1)
                rlen_pt = length(rstrip(rec_pt))
                if lkecho; @printf(io_units[JOSTND], " SKIPPED RECORD=%s\n", rlen_pt > 0 ? rec_pt[1:rlen_pt] : ""); end
                if rlen_pt == 0 || rec_pt[rlen_pt] != '&'; break; end
            end
            @goto label_10
        end
        global NPTGRP = NPTGRP + Int32(1)
        if lnotbk[1]
            PTGNAME[NPTGRP] = uppercase(lstrip(kard[1]))
            ilen = Int32(length(rstrip(PTGNAME[NPTGRP])))
        else
            PTGNAME[NPTGRP] = @sprintf("PTGROUP%02d ", NPTGRP)[1:10]
            ilen = Int32(9)
        end
        global IPTGRP[NPTGRP, 52] = ilen
        inum_pt = Int32(0)
        kard   = fill("          ", 12)
        array .= Float32(0)
        while true
            if eof(io_units[IREAD]); @goto label_80; end
            rec_pt = readline(io_units[IREAD])
            global IRECNT += Int32(1)
            has_amp_pt = false
            for tok_pt in split(rec_pt)
                if tok_pt == "&"; has_amp_pt = true; break; end
                array[1] = Float32(0.0)
                tryv_pt = tryparse(Float32, tok_pt)
                if tryv_pt !== nothing; array[1] = tryv_pt; end
                if array[1] == Float32(0.0); continue; end
                inum_pt += Int32(1)
                if inum_pt > Int32(50); inum_pt = Int32(50); end
                is_dup_pt = false
                if inum_pt > Int32(1)
                    for jdup_pt in 2:Int(inum_pt)
                        if IPTGRP[NPTGRP, jdup_pt] == Int32(array[1]); is_dup_pt = true; break; end
                    end
                end
                if is_dup_pt
                    inum_pt -= Int32(1)
                else
                    IPTGRP[NPTGRP, inum_pt + 1] = Int32(array[1])
                end
            end
            if !has_amp_pt; break; end
        end
        global IPTGRP[NPTGRP, 1] = inum_pt
        if lkecho
            @printf(io_units[JOSTND], "\n%-8s   GROUP NUMBER:%4d  GROUP NAME: %-10s  NUMBER OF POINTS IN THIS GROUP:%3d  POINTS:\n", keywrd, -Int(NPTGRP), PTGNAME[NPTGRP], inum_pt)
            for jj_pt in 2:Int(inum_pt)+1
                @printf(io_units[JOSTND], "%10d", IPTGRP[NPTGRP, jj_pt])
            end
            if inum_pt > Int32(0); @printf(io_units[JOSTND], "\n"); end
        end
    end
    @goto label_10

    # =======================================================================
    # OPTION 143 — ORGANON  (label_14300)
    # ORGANON growth model: ORIN(DEBUG,LKECHO,LNOTRE) for OC/OP variants
    # verified against initre.f lines 6161-6181
    # =======================================================================
    @label label_14300
    if VARACD == "OC" || VARACD == "OP"
        if lkecho; @printf(io_units[JOSTND], "\n%-8s   START OF ORGANON KEYWORDS:\n", keywrd); end
        ORIN(debug, lkecho, lnotre)
    else
        if lkecho; @printf(io_units[JOSTND], "\n%-8s   ORGANON KEYWORDS NOT RECOGNIZED IN THIS VARIANT\n", keywrd); end
    end
    @goto label_10

    # =======================================================================
    # OPTION 144 — SPLEAVE  (label_14400)
    # Species leave trees: require lnotbk[2]; SPDECD field 2; OPNEW act=206
    # verified against initre.f lines 6183-6243
    # =======================================================================
    @label label_14400
    idt = Int32(1)
    if lnotbk[1]; idt = Int32(array[1]); end
    if iprmpt > Int32(0)
        if iprmpt != Int32(2)
            KEYDMP(JOSTND, IRECNT, keywrd, array, kard)
            ERRGRO(true, Int32(25))
        else
            kode = OPNEWC(JOSTND, IREAD, idt, Int32(206), keywrd, kard, iprmpt, IRECNT, ICYC)
            irtncd = fvsGetRtnCode()
            if irtncd != Int32(0); return; end
        end
        @goto label_10
    end
    if !lnotbk[2]
        KEYDMP(JOSTND, IRECNT, keywrd, array, kard)
        ERRGRO(true, Int32(4))
        @goto label_10
    end
    is = SPDECD(Int32(2), NSP, JOSTND, IRECNT, keywrd, array, kard)
    if is == Int32(-999); @goto label_10; end
    prms[1] = Float32(is)
    prms[2] = Float32(1.0)
    if lnotbk[3]; prms[2] = array[3]; end
    kode = OPNEW(idt, Int32(206), Int32(2), prms)
    if kode > Int32(0); @goto label_10; end
    begin
        ilen = Int32(3)
        if is < Int32(0); ilen = Int32(ISPGRP[-is, 92]); end
        sp_str_sl = kard[2][1:min(Int(ilen),length(kard[2]))]
        if lkecho
            if prms[2] > Float32(0.0)
                @printf(io_units[JOSTND], "\n%-8s   DATE/CYCLE=%5d; SPECIES= %s (CODE=%3d); WILL NOT BE INCLUDED IN THE FOLLOWING THINNING ACTIVITIES\n", keywrd, idt, sp_str_sl, is)
            else
                @printf(io_units[JOSTND], "\n%-8s   DATE/CYCLE=%5d; SPECIES= %s (CODE=%3d); WILL BE INCLUDED IN THE FOLLOWING THINNING ACTIVITIES\n", keywrd, idt, sp_str_sl, is)
            end
        end
    end
    @goto label_10

    # =======================================================================
    # OPTION 145 — CCADJ  (label_14500)
    # Crown comp factor: if no date → set/show CCCOEF; else OPNEW act=444 NP=1
    # verified against initre.f lines 6245-6288
    # =======================================================================
    @label label_14500
    idt = Int32(1)
    if lnotbk[1]; idt = Int32(array[1]); end
    if iprmpt > Int32(0)
        if iprmpt != Int32(2)
            KEYDMP(JOSTND, IRECNT, keywrd, array, kard)
            ERRGRO(true, Int32(25))
        else
            kode = OPNEWC(JOSTND, IREAD, idt, Int32(444), keywrd, kard, iprmpt, IRECNT, ICYC)
            irtncd = fvsGetRtnCode()
            if irtncd != Int32(0); return; end
        end
        @goto label_10
    end
    if !lnotbk[1]
        if !lnotbk[2]; array[2] = CCCOEF; else; global CCCOEF = array[2]; end
        if lkecho; @printf(io_units[JOSTND], "\n%-8s   OVERLAP COEFFICIENT=%8.6f\n", keywrd, array[2]); end
    else
        prms[1] = array[2]
        kode = OPNEW(idt, Int32(444), Int32(1), prms)
        if kode > Int32(0); @goto label_10; end
        if lkecho; @printf(io_units[JOSTND], "\n%-8s   DATE/CYCLE=%5d; OVERLAP COEFICCIENT=%8.6f\n", keywrd, idt, array[2]); end
    end
    @goto label_10

    # =======================================================================
    # OPTION 146 — PRMFROST  (label_14600)
    # Permafrost: require lnotbk[2]; OPNEW act=445 NP=1; echo ON/OFF
    # verified against initre.f lines 6290-6329
    # =======================================================================
    @label label_14600
    idt = Int32(1)
    if lnotbk[1]; idt = Int32(array[1]); end
    if iprmpt > Int32(0)
        if iprmpt != Int32(2)
            KEYDMP(JOSTND, IRECNT, keywrd, array, kard)
            ERRGRO(true, Int32(25))
        else
            kode = OPNEWC(JOSTND, IREAD, idt, Int32(445), keywrd, kard, iprmpt, IRECNT, ICYC)
            irtncd = fvsGetRtnCode()
            if irtncd != Int32(0); return; end
        end
        @goto label_10
    end
    if !lnotbk[2]
        KEYDMP(JOSTND, IRECNT, keywrd, array, kard)
        ERRGRO(true, Int32(4))
        @goto label_10
    end
    kode = OPNEW(idt, Int32(445), Int32(1), view(array, 2:12))
    if kode > Int32(0); @goto label_10; end
    begin
        onoff_pf = array[2] == Float32(1.0) ? "ON " : "OFF"
        if lkecho; @printf(io_units[JOSTND], "\n%-8s   DATE/CYCLE=%5d; PERMAFROST EFFECT %s\n", keywrd, idt, onoff_pf); end
    end
    @goto label_10

    # =======================================================================
    # OPTION 147 — FIAVBC  (label_14700)
    # FIA Volume/Biomass Consistency: reset defaults; MRCHLMTS; CFCTYPE; SPDECD
    # verified against initre.f lines 6331-6477
    # =======================================================================
    @label label_14700
    begin
        global LFIANVB = true
        mrchlmts_fv = Int32(0)
        global CFCTYPE = "I"
        if lnotbk[1]
            if array[1] == Float32(0.0) || array[1] == Float32(1.0)
                mrchlmts_fv = Int32(array[1])
            else
                if lkecho; @printf(io_units[JOSTND], "\n%-8s   INVALID MERCHANTABILITY STANDARD REQUESTED.  FIA STANDARDS WILL BE USED BY DEFAULT.\n", keywrd); end
                ERRGRO(true, Int32(42))
            end
        end
        if lnotbk[2]
            if array[2] == Float32(0.0); global CFCTYPE = "I"
            elseif array[2] == Float32(1.0); global CFCTYPE = "F"
            else
                if lkecho; @printf(io_units[JOSTND], "\n%-8s   INVALID CRUISE TYPE REQUESTED.  CRUISE TYPE \"I\" (FIA) WILL BE USED BY DEFAULT.\n", keywrd); end
                ERRGRO(true, Int32(42))
                global CFCTYPE = "I"
            end
        end
        for ispc_fv in 1:MAXSP; METHC[ispc_fv] = Int32(10); end
        if mrchlmts_fv == Int32(0)
            for ispc_fv in 1:MAXSP
                ifiacode_fv = Int32(0)
                tryv_fv = tryparse(Int32, strip(FIAJSP[ispc_fv]))
                if tryv_fv !== nothing; ifiacode_fv = tryv_fv; end
                if ifiacode_fv > Int32(0) || (VARACD == "AK" && JSP[ispc_fv] == "LS")
                    DBHMIN[ispc_fv] = Float32(5.0); TOPD[ispc_fv] = Float32(4.0)
                    STMP[ispc_fv]   = Float32(1.0); SCFSTMP[ispc_fv] = Float32(1.0)
                    if ifiacode_fv < Int32(300)
                        SCFMIND[ispc_fv] = Float32(9.0); SCFTOPD[ispc_fv] = Float32(7.0)
                    else
                        SCFMIND[ispc_fv] = Float32(11.0); SCFTOPD[ispc_fv] = Float32(9.0)
                    end
                end
            end
        else
            SETCUBICDFLTS()
        end
        CFLA0 .= Float32(0.0); CFLA1 .= Float32(1.0); CFDEFT .= Float32(0.0)
        if lkecho; @printf(io_units[JOSTND], "\n%-8s   KEYWORD HAS BEEN REQUESTED. ALL CUBIC FOOT VOLUME COMPUTATIONS WILL BE BASED ON FIA METHODOLOGIES.\n           NO OTHER USER REQUESTS TO ALTER CUBIC FOOT VOLUME ESTIMATES OR DEFECT WILL BE PERMITTED.\n", keywrd); end
        is = SPDECD(Int32(3), NSP, JOSTND, IRECNT, keywrd, array, kard)
        if is == Int32(-999); @goto label_10; end
        if is < Int32(0)
            igrp = -is
            iulim = Int32(ISPGRP[igrp, 1]) + Int32(1)
            for ig in Int32(2):iulim
                igsp = Int32(ISPGRP[igrp, ig])
                if lnotbk[4]; DBHMIN[igsp]  = array[4]; end
                if lnotbk[5]; TOPD[igsp]    = array[5]; end
                if lnotbk[6]; STMP[igsp]    = array[6]; end
                if lnotbk[7]; SCFMIND[igsp] = array[7]; end
                if lnotbk[8]; SCFTOPD[igsp] = array[8]; end
                if lnotbk[9]; SCFSTMP[igsp] = array[9]; end
                ilen = Int32(ISPGRP[igrp, 92])
                if lkecho; @printf(io_units[JOSTND], "\n%-8s   MERCHANTABILITY STANDARDS FOR SPECIES= %s (CODE=%3d) ARE:  MINIMUM DBH=%6.2f; TOP DIAMETER=%6.2f; STUMP HEIGHT=%6.2f;\n           ; MINIMUM SAWLOG CUBIC DBH=%6.2f; SAWLOG CUBIC TOP DIAMETER=%6.2f; SAWLOG CUBIC STUMP HT=%6.2f\n", keywrd, kard[2][1:min(Int(ilen),length(kard[2]))], igsp, DBHMIN[igsp], TOPD[igsp], STMP[igsp], SCFMIND[igsp], SCFTOPD[igsp], SCFSTMP[igsp]); end
            end
        elseif is == Int32(0)
            for iss_fv in 1:MAXSP
                if lnotbk[4]; DBHMIN[iss_fv]  = array[4]; end
                if lnotbk[5]; TOPD[iss_fv]    = array[5]; end
                if lnotbk[6]; STMP[iss_fv]    = array[6]; end
                if lnotbk[7]; SCFMIND[iss_fv] = array[7]; end
                if lnotbk[8]; SCFTOPD[iss_fv] = array[8]; end
                if lnotbk[9]; SCFSTMP[iss_fv] = array[9]; end
            end
            if lkecho; @printf(io_units[JOSTND], "\n%-8s   ALL SPECIES (CODE= 0); MINIMUM DBH=%6.2f; TOP DIAMETER=%6.2f; STUMP HEIGHT=%6.2f;\n           CUBIC SAWLOG MINDBH=%6.2f; CUBIC SAWLOG TOP DIA=%6.2f; CUBIC SAWLOG STUMP HT=%6.2f\n", keywrd, array[4], array[5], array[6], array[7], array[8], array[9]); end
        else
            if lnotbk[4]; DBHMIN[is]  = array[4]; end
            if lnotbk[5]; TOPD[is]    = array[5]; end
            if lnotbk[6]; STMP[is]    = array[6]; end
            if lnotbk[7]; SCFMIND[is] = array[7]; end
            if lnotbk[8]; SCFTOPD[is] = array[8]; end
            if lnotbk[9]; SCFSTMP[is] = array[9]; end
            ilen = Int32(3)
            if lkecho; @printf(io_units[JOSTND], "\n%-8s   MERCHANTABILITY STANDARDS FOR SPECIES= %s (CODE=%3d) ARE:  MINIMUM DBH=%6.2f; TOP DIAMETER=%6.2f; STUMP HEIGHT=%6.2f;\n           ; MINIMUM SAWLOG CUBIC DBH=%6.2f; SAWLOG CUBIC TOP DIAMETER=%6.2f; SAWLOG CUBIC STUMP HT=%6.2f\n", keywrd, kard[2][1:min(3,length(kard[2]))], is, DBHMIN[is], TOPD[is], STMP[is], SCFMIND[is], SCFTOPD[is], SCFSTMP[is]); end
        end
    end
    @goto label_10

    # =======================================================================
    # SHARED LABEL — label_3805: THINPRSC / xSALVAGE
    # ICFLAG pre-set by caller (227=THINPRSC, 229=xSALVAGE)
    # verified against initre.f 1143-1182
    # =======================================================================
    @label label_3805
    idt = Int32(1)
    if lnotbk[1]; idt = Int32(array[1]); end
    if iprmpt > Int32(0)
        if iprmpt != Int32(2)
            KEYDMP(JOSTND, IRECNT, keywrd, array, kard)
            ERRGRO(true, Int32(25))
        else
            kode = OPNEWC(JOSTND, IREAD, idt, ICFLAG, keywrd, kard, iprmpt, IRECNT, ICYC)
            irtncd = fvsGetRtnCode()
            if irtncd != Int32(0); return; end
        end
        @goto label_10
    end
    prms[1] = EFF
    if lnotbk[2]; prms[1] = array[2]; end
    if prms[1] < Float32(0.0)
        KEYDMP(JOSTND, IRECNT, keywrd, array, kard)
        ERRGRO(true, Int32(4))
        @goto label_10
    end
    i_tmp = Int32(1)
    if lnotbk[3]
        prms[2] = array[3]
        i_tmp = Int32(2)
    end
    kode = OPNEW(idt, ICFLAG, i_tmp, prms)
    if kode > Int32(0); @goto label_10; end
    if lkecho; @printf(io_units[JOSTND], "\n%-8s   DATE/CYCLE=%5d; PROPORTION OF SELECTED TREES REMOVED=%6.3f\n", keywrd, idt, prms[1]); end
    if i_tmp == Int32(2) && lkecho; @printf(io_units[JOSTND], "           TREES CODED %4d ARE SELECTED.\n", Int32(prms[2])); end
    @goto label_10

    # =======================================================================
    # SHARED LABEL — label_3901: THINDBH / THINHT / THINCC variant
    # ICFLAG pre-set by caller (228=THINDBH, 232=THINHT, 233=THINCC, etc.)
    # verified against initre.f 1188-1244
    # =======================================================================
    @label label_3901
    idt = Int32(1)
    if lnotbk[1]; idt = Int32(array[1]); end
    if iprmpt > Int32(0)
        if iprmpt != Int32(2)
            KEYDMP(JOSTND, IRECNT, keywrd, array, kard)
            ERRGRO(true, Int32(25))
        else
            kode = OPNEWC(JOSTND, IREAD, idt, ICFLAG, keywrd, kard, iprmpt, IRECNT, ICYC)
            irtncd = fvsGetRtnCode()
            if irtncd != Int32(0); return; end
        end
        @goto label_10
    end
    if !lnotbk[3]; array[3] = Float32(999.0); end
    if !lnotbk[4]; array[4] = EFF; end
    is = SPDECD(Int32(5), NSP, JOSTND, IRECNT, keywrd, array, kard)
    if is == Int32(-999); @goto label_10; end
    if array[7] < Float32(0.0) || array[6] > Float32(0.0); array[7] = Float32(0.0); end
    if array[6] < Float32(0.0); array[6] = Float32(0.0); end
    kode = OPNEW(idt, ICFLAG, Int32(6), array)
    if kode > Int32(0); @goto label_10; end
    if lkecho
        if ICFLAG == Int32(228)
            @printf(io_units[JOSTND], "\n%-8s   DATE/CYCLE=%5d; MINIMUM DBH=%8.1f; MAXIMUM DBH=%8.1f; PROPORTION OF SELECTED TREES REMOVED=%6.3f\n",
                keywrd, idt, array[2], array[3], array[4])
        else
            @printf(io_units[JOSTND], "\n%-8s   DATE/CYCLE=%5d; MINIMUM HEIGHT=%8.1f; MAXIMUM HEIGHT=%8.1f; PROPORTION OF SELECTED TREES REMOVED=%6.3f\n",
                keywrd, idt, array[2], array[3], array[4])
        end
        if is != Int32(0)
            ilen = Int32(3)
            if is < Int32(0); ilen = ISPGRP(-is, Int32(92)); end
            sp_str = length(kard[5]) >= ilen ? kard[5][1:ilen] : rpad(kard[5], ilen)
            @printf(io_units[JOSTND], "           SPECIES= %s (CODE= %3d) IS TARGETED FOR THIS CUT.\n", sp_str, is)
        else
            @printf(io_units[JOSTND], "           ALL SPECIES (CODE= %3d) ARE TARGETED FOR THIS CUT.\n", is)
        end
        if (array[6] > Float32(0.0) || array[7] > Float32(0.0))
            @printf(io_units[JOSTND], "           RESIDUAL CLASS TPA =%8.1f RESIDUAL CLASS BA =%8.1f\n", array[6], array[7])
        end
    end
    @goto label_10

    # =======================================================================
    # SHARED LABEL — label_4081: TOPKILL / HTGSTOP
    # iact pre-set by caller (111=TOPKILL, 110=HTGSTOP)
    # verified against initre.f 1315-1360
    # =======================================================================
    @label label_4081
    idt = Int32(1)
    if lnotbk[1]; idt = Int32(array[1]); end
    if iprmpt > Int32(0)
        if iprmpt != Int32(2)
            KEYDMP(JOSTND, IRECNT, keywrd, array, kard)
            ERRGRO(true, Int32(25))
        else
            kode = OPNEWC(JOSTND, IREAD, idt, iact, keywrd, kard, iprmpt, IRECNT, ICYC)
            irtncd = fvsGetRtnCode()
            if irtncd != Int32(0); return; end
        end
        @goto label_10
    end
    is = SPDECD(Int32(2), NSP, JOSTND, IRECNT, keywrd, array, kard)
    if is == Int32(-999); @goto label_10; end
    if iact == Int32(110) && !lnotbk[6]; array[6] = Float32(1.0); end
    kode = OPNEW(idt, iact, Int32(6), array)
    if kode > Int32(0); @goto label_10; end
    if lkecho
        ilen = Int32(3)
        if is < Int32(0); ilen = ISPGRP(-is, Int32(92)); end
        sp_str = length(kard[2]) >= ilen ? kard[2][1:ilen] : rpad(kard[2], ilen)
        @printf(io_units[JOSTND], "\n%-8s   DATE/CYCLE=%5d; SPECIES= %s (CODE= %3d); LOWER TREE-HEIGHT LIMIT=%5.1f; UPPER LIMIT=%5.1f\n           PROBABILITY (%-8s) FOR TREES WITHIN THE HEIGHT LIMITS=%10.3f\n",
            keywrd, idt, sp_str, is, array[3], array[4], keywrd, array[5])
        if iact >= Int32(110); @printf(io_units[JOSTND], "           AVERAGE PROPORTION OF HEIGHT GROWTH LOST=%6.3f; STD DEV=%6.3f\n", array[6], array[7]); end
        if iact >= Int32(111); @printf(io_units[JOSTND], "           AVERAGE PROPORTION OF HEIGHT LOST=%6.3f; STD DEV=%6.3f\n", array[6], array[7]); end
    end
    @goto label_10

    # =======================================================================
    # SHARED LABEL — label_4090: THINBTA/ATA/BBA/ABA
    # ICFLAG pre-set by caller (223..226)
    # verified against initre.f 1364-1412
    # =======================================================================
    @label label_4090
    idt = Int32(1)
    if lnotbk[1]; idt = Int32(array[1]); end
    if iprmpt > Int32(0)
        if iprmpt != Int32(2)
            KEYDMP(JOSTND, IRECNT, keywrd, array, kard)
            ERRGRO(true, Int32(25))
        else
            kode = OPNEWC(JOSTND, IREAD, idt, ICFLAG, keywrd, kard, iprmpt, IRECNT, ICYC)
            irtncd = fvsGetRtnCode()
            if irtncd != Int32(0); return; end
        end
        @goto label_10
    end
    if !lnotbk[2]
        KEYDMP(JOSTND, IRECNT, keywrd, array, kard)
        ERRGRO(true, Int32(4))
        @goto label_10
    end
    prms[1] = array[2]
    prms[2] = EFF
    if lnotbk[3]; prms[2] = array[3]; end
    prms[3] = Float32(0.0)
    if lnotbk[4]; prms[3] = array[4]; end
    prms[4] = Float32(999.0)
    if lnotbk[5]; prms[4] = array[5]; end
    prms[5] = Float32(0.0)
    if lnotbk[6]; prms[5] = array[6]; end
    prms[6] = Float32(999.0)
    if lnotbk[7]; prms[6] = array[7]; end
    kode = OPNEW(idt, ICFLAG, Int32(6), prms)
    if kode > Int32(0); @goto label_10; end
    if lkecho
        @printf(io_units[JOSTND], "\n%-8s   DATE/CYCLE=%5d; RESIDUAL=%8.2f; PROPORTION OF SELECTED TREES REMOVED=%6.3f\n           DBH OF REMOVED TREES WILL RANGE FROM %5.1f TO %5.1f INCHES, AND\n           HEIGHT OF REMOVED TREES WILL RANGE FROM %5.1f TO %5.1f FEET.\n",
            keywrd, idt, prms[1], prms[2], prms[3], prms[4], prms[5], prms[6])
    end
    @goto label_10

    # =======================================================================
    # SHARED LABEL — label_6005: BAIMULT/REGDMULT/HTGMULT/REGHMULT
    # i_mult pre-set: 91=BAIMULT, 96=REGDMULT, 92=HTGMULT, 93=REGHMULT
    # =======================================================================
    # i_mult pre-set: 91=BAIMULT, 96=REGDMULT, 92=HTGMULT, 93=REGHMULT
    # verified against initre.f (label 6005)
    @label label_6005
    idt = Int32(1)
    if lnotbk[1]; idt = Int32(array[1]); end
    if iprmpt > Int32(0)
        if iprmpt != Int32(2)
            KEYDMP(JOSTND, IRECNT, keywrd, array, kard)
            ERRGRO(true, Int32(25))
        else
            kode = OPNEWC(JOSTND, IREAD, idt, i_mult, keywrd, kard, iprmpt, IRECNT, ICYC)
            irtncd = fvsGetRtnCode()
            if irtncd != Int32(0); return; end
        end
        @goto label_10
    end
    if !lnotbk[3]; array[3] = Float32(1.0); end
    is = SPDECD(Int32(2), NSP, JOSTND, IRECNT, keywrd, array, kard)
    if is == Int32(-999); @goto label_10; end
    kode = OPNEW(idt, i_mult, Int32(2), view(array, 2:12))
    if kode > Int32(0); @goto label_10; end
    ilen = Int32(3)
    if is < Int32(0); ilen = Int32(ISPGRP(-is, Int32(92))); end
    sp_str = kard[2][1:min(Int(ilen), length(kard[2]))]
    if lkecho
        @printf(io_units[JOSTND], "\n%-8s   DATE/CYCLE=%5d; SPECIES=%s (CODE= %3d); MULTIPLIER=%10.4f\n", keywrd, idt, sp_str, is, array[3])
    end
    @goto label_10

end  # function INITRE
