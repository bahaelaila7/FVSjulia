# fvs.f — Main FVS simulation driver
# Translated from: base/fvs.f (468 lines)
#
# FVS(irtncd) orchestrates the full stand simulation:
#   INITRE → sort/setup → initial stats → cycle loop (TREGRO) → final output

"""
    FVS!(irtncd::Ref{Int32})

Main FVS simulation subroutine. Equivalent to Fortran SUBROUTINE FVS(IRTNCD).

Drives one stand through initialization, the per-cycle growth/harvest loop, and
final output. `irtncd` is set to a non-zero error code on failure.

Stop/restart logic:
- irstrtcd = 0   → fresh start
- irstrtcd >= 1  → restart from an interrupted mid-cycle point
- irstrtcd = 7   → restart from stop-point 7 (after CRATET but before cycle 1)
"""
function FVS!(irtncd::Ref{Int32})
    debug_mode = false
    DBCHK_FVS(debug_mode)

    # Check/initialize command line (first call only: irtncd == -1)
    irtncd[] = fvsGetRtnCode()
    if irtncd[] == Int32(-1)
        lencl = Int32(0)
        fvsSetCmdLine(" ", lencl, irtncd)
        if irtncd[] != Int32(0); return nothing; end
    end

    # Determine restart code
    irstrtcd = fvsRestart()
    irtncd[] = fvsGetRtnCode()
    if debug_mode
        @printf(io_units[JOSTND], "In FVS, IRSTRTCD=%d IRTNCD=%d\n", irstrtcd, irtncd[])
    end
    if irtncd[] != Int32(0); return nothing; end
    if irstrtcd  < Int32(0); return nothing; end
    if irstrtcd == Int32(7); @goto label_19; end
    if irstrtcd  >= Int32(1); @goto label_41; end

    # -----------------------------------------------------------------------
    # Fresh start
    # -----------------------------------------------------------------------
    global ICL1   = Int32(0)
    global LSTART = true
    global LFLAG  = true
    global ICYC   = Int32(0)

    INITRE()
    irtncd[] = fvsGetRtnCode()
    if irtncd[] != Int32(0); return nothing; end

    DBCHK_FVS(debug_mode)

    # Clamp cycle count
    if NCYC <= Int32(0);    global NCYC = Int32(1);    end
    if NCYC >  MAXCYC;     global NCYC = MAXCYC;      end

    # Accumulate IY: convert per-cycle lengths to cumulative years
    for i in Int32(2):MAXCY1
        if IY[i] == Int32(-1); IY[i] = Int32(10); end
        IY[i] = IY[i-1] + IY[i]
    end

    # Insert any user-requested extra output years (IWORK1)
    if IWORK1[1] > Int32(0)
        for ia in Int32(2):(IWORK1[1]+Int32(1))
            yr = IWORK1[ia]
            if yr <= IY[1] || yr >= IY[NCYC+1]
                continue
            end
            n_cyc = NCYC
            for i in Int32(1):n_cyc
                if yr > IY[i] && yr < IY[i+1]
                    global NCYC = NCYC + Int32(1)
                    if NCYC > MAXCYC; global NCYC = MAXCYC; end
                    for k in (NCYC+Int32(1)):-1:(i+Int32(2))
                        IY[k] = IY[k-Int32(1)]
                    end
                    IY[i+1] = yr
                    break
                end
            end
        end
    end

    # Extension hooks: bark beetle, dwarf mistletoe, Douglas-fir beetle
    MPBOPS()
    TMOPS()
    DFBSCH()

    # Set up economics cost/revenue indexes
    ECSETP(IY)

    # Process and list activity schedule
    OPEXPN(JOSTND, NCYC, IY)
    OPCYCL(NCYC, IY)
    if ITABLE[4] == Int32(0)
        OPLIST(true, NPLT, MGMID, ITITLE)
    end

    # Sort/index tree records by species
    SETUP()

    # Calculate trees/acre (load PROB)
    NOTRE()

    # Western Root Disease model initialization (pass 1)
    RDMN1(Int32(1))

    # Dead LPP/acre
    MPSDLP()

    # Dead DFB/acre
    DFBINV()

    global ICYC = Int32(1)

    # Set option pointers for cycle 1
    OPCSET(ICYC)

    # Stop-point 7
    istopres = fvsStopPoint(Int32(7))
    if istopres != Int32(0); return nothing; end
    irtncd[] = fvsGetRtnCode()
    if irtncd[] != Int32(0); return nothing; end

    # -----------------------------------------------------------------------
    # Label 19: restart from stop-point 7
    # -----------------------------------------------------------------------
    @label label_19

    # Calibrate growth functions; fill gaps; crown width for Weibull variants
    stagea = Float32(0.0); stageb = Float32(0.0)
    SDICLS(Int32(0), Float32(0.0), Float32(999.0), Int32(1),
           SDIAC, SDIAC2, stagea, stageb, Int32(0))
    CRATET()

    # Flag best tree records for estab model
    ESFLTR()

    global ICYC = Int32(0)

    # Initial crown widths
    CWIDTH()

    # Initial volume statistics
    VOLS()

    # Compute initial percentile distributions; multiply by PROB first
    if ITRN > Int32(0)
        for i in Int32(1):ITRN
            CFV[i]         *= PROB[i]
            BFV[i]         *= PROB[i]
            MCFV[i]        *= PROB[i]
            SCFV[i]        *= PROB[i]
            ABVGRD_BIO[i]  *= PROB[i]
            MERCH_BIO[i]   *= PROB[i]
            CUBSAW_BIO[i]  *= PROB[i]
            FOLI_BIO[i]    *= PROB[i]
            ABVGRD_CARB[i] *= PROB[i]
            MERCH_CARB[i]  *= PROB[i]
            CUBSAW_CARB[i] *= PROB[i]
            FOLI_CARB[i]   *= PROB[i]
        end
    end

    OCVCUR[7]      = PCTILE(Int(ITRN), IND, CFV,         WK3); DIST(Int(ITRN), OCVCUR, WK3)
    OBFCUR[7]      = PCTILE(Int(ITRN), IND, BFV,         WK3); DIST(Int(ITRN), OBFCUR, WK3)
    OMCCUR[7]      = PCTILE(Int(ITRN), IND, MCFV,        WK3); DIST(Int(ITRN), OMCCUR, WK3)
    OSCCUR[7]      = PCTILE(Int(ITRN), IND, SCFV,        WK3); DIST(Int(ITRN), OSCCUR, WK3)
    OAGBIOCUR[7]   = PCTILE(Int(ITRN), IND, ABVGRD_BIO,  WK3); DIST(Int(ITRN), OAGBIOCUR, WK3)
    OMERBIOCUR[7]  = PCTILE(Int(ITRN), IND, MERCH_BIO,   WK3); DIST(Int(ITRN), OMERBIOCUR, WK3)
    OCSAWBIOCUR[7] = PCTILE(Int(ITRN), IND, CUBSAW_BIO,  WK3); DIST(Int(ITRN), OCSAWBIOCUR, WK3)
    OFOLIBIO[7]    = PCTILE(Int(ITRN), IND, FOLI_BIO,    WK3); DIST(Int(ITRN), OFOLIBIO, WK3)
    OAGCARBCUR[7]  = PCTILE(Int(ITRN), IND, ABVGRD_CARB, WK3); DIST(Int(ITRN), OAGCARBCUR, WK3)
    OMERCARBCUR[7] = PCTILE(Int(ITRN), IND, MERCH_CARB,  WK3); DIST(Int(ITRN), OMERCARBCUR, WK3)
    OCSAWCARBCUR[7]= PCTILE(Int(ITRN), IND, CUBSAW_CARB, WK3); DIST(Int(ITRN), OCSAWCARBCUR, WK3)
    OFOLICARB[7]   = PCTILE(Int(ITRN), IND, FOLI_CARB,   WK3); DIST(Int(ITRN), OFOLICARB, WK3)

    # Divide back by PROB to restore per-tree values
    if ITRN > Int32(0)
        for i in Int32(1):ITRN
            CFV[i]         /= PROB[i]
            BFV[i]         /= PROB[i]
            MCFV[i]        /= PROB[i]
            SCFV[i]        /= PROB[i]
            ABVGRD_BIO[i]  /= PROB[i]
            MERCH_BIO[i]   /= PROB[i]
            CUBSAW_BIO[i]  /= PROB[i]
            FOLI_BIO[i]    /= PROB[i]
            ABVGRD_CARB[i] /= PROB[i]
            MERCH_CARB[i]  /= PROB[i]
            CUBSAW_CARB[i] /= PROB[i]
            FOLI_CARB[i]   /= PROB[i]
        end
    end

    # Assign example trees to output arrays
    EXTREE()

    # Cover model check
    lcvgo = false
    CVGO(lcvgo)

    if debug_mode
        @printf(io_units[JOSTND], " CALLING CVBROW, CYCLE=%2d\n", ICYC)
    end
    CVBROW(false)

    if debug_mode
        @printf(io_units[JOSTND], " CALLING CVCNOP, CYCLE =%2d\n", ICYC)
    end
    CVCNOP(false)

    if debug_mode
        @printf(io_units[JOSTND], " CALLING STATS, CYCLE = %2d\n", ICYC)
    end
    STATS()

    # Output simulation reference data (DBS)
    DBSREFERENCE()

    # Stand composition table heading
    if ITABLE[1] == Int32(0)
        GHEADS(NPLT, MGMID, JOSTND, Int32(0), ITITLE)
    end

    # Initial stand statistics
    global ICL6 = Int32(1)
    DISPLY()
    irtncd[] = fvsGetRtnCode()
    if irtncd[] != Int32(0); return nothing; end

    # Tree list output
    MISPRT()
    PRTRLS(Int32(1))
    DBS_FIAVBC_TRLS()

    # Initial stand visualization
    SVSTART()

    # Load old volume variables with cycle-0 volumes
    FVSSTD(Int32(1))

    # Purge inventory dead trees
    global IREC2 = MAXTP1

    # Western Root Disease initialization (pass 2)
    RDMN1(Int32(2))
    RDPR()

    # Blister rust initialization
    BRSETP()
    BRPR()

    global LFLAG  = false
    global LSTART = false

    # Initialize type-1 event monitor variables
    EVTSTV(Int32(-1))

    # -----------------------------------------------------------------------
    # Main cycle loop
    # -----------------------------------------------------------------------
    @label label_40
    global ICYC = ICYC + Int32(1)

    @label label_41

    if debug_mode
        @printf(io_units[JOSTND], "\n CALLING TREGRO, CYCLE = %4d\n", ICYC)
    end
    TREGRO()
    irtncd[] = fvsGetRtnCode()
    if irtncd[] != Int32(0); return nothing; end

    istopdone = getAmStopping()
    if istopdone != Int32(0); return nothing; end

    EXTREE()

    if debug_mode
        @printf(io_units[JOSTND], "\n CALLING DISPLY, CYCLE = %4d\n", ICYC)
    end
    DISPLY()
    irtncd[] = fvsGetRtnCode()
    if irtncd[] != Int32(0); return nothing; end

    RESAGE()
    MISPRT()
    RDPR()
    BRPR()
    PRTRLS(Int32(1))
    DBS_FIAVBC_TRLS()
    FVSSTD(Int32(1))

    if ICYC < NCYC
        ClearRestartCode()
        @goto label_40
    end

    # Signal that stop/restart for this stand cannot continue
    fvsStopPoint(Int32(-1))

    # -----------------------------------------------------------------------
    # End of projection: final display
    # -----------------------------------------------------------------------
    global ICYC = ICYC + Int32(1)
    global ICL6 = Int32(-99)
    ONTREM[7] = Float32(0.0)
    global OLDTPA  = TPROB
    global OLDBA   = BA
    global OLDAVH  = AVH
    global ORMSQD  = RMSQD
    global ODR016  = DR016
    global RELDM1  = RELDEN

    stagea = Float32(0.0); stageb = Float32(0.0)
    SDICLS(Int32(0), Float32(0.0), Float32(999.0), Int32(1),
           SDIBC, SDIBC2, stagea, stageb, Int32(0))
    global SDIAC  = SDIBC
    global SDIAC2 = SDIBC2

    DISPLY()
    irtncd[] = fvsGetRtnCode()
    if irtncd[] != Int32(0); return nothing; end

    iba = Int32(1)
    SSTAGE(iba, ICYC, false)

    SVOUT(IY[ICYC], Int32(3), "End of projection")
    global LFLAG = true
    ESOUT(LFLAG)
    CVOUT()
    MPBOUT()
    DFBOUT()
    TMOUT()
    BWEOUT()
    BRROUT()

    GENPRT()

    return nothing
end

# Alias: Fortran CALL FVS(IRTNCD) → Julia FVS(r) = FVS!(r)
FVS(r) = FVS!(r)

# ---------------------------------------------------------------------------
# Minimal stubs for helpers called directly from FVS! that have no other home.
# Everything with a real implementation elsewhere has been removed.
# ---------------------------------------------------------------------------
# fvsGetRtnCode/fvsSetRtnCode defined in base/filopn.jl
# fvsSetCmdLine defined in base/cmdline.jl
# fvsRestart/fvsStopPoint/getAmStopping defined in base/cmdline.jl (Ref-arg versions)
# These 0/1-arg wrappers are kept here for the FVS! call sites that use them that way:
DBCHK_FVS(d)        = nothing          # debug mode toggle (no-op; DBCHK handles via ENV)
fvsRestart()        = Int32(0)         # 0-arg wrapper used in FVS! cycle check
fvsStopPoint(n)     = Int32(0)         # 1-arg wrapper (stop code check)
getAmStopping()     = Int32(0)         # 0-arg wrapper
ClearRestartCode()  = nothing
SVSTART()           = nothing          # SVS animation start (SVS not translated)
BWEOUT()            = nothing          # budworm/bark beetle output (pest not translated)
# All other stubs live in base/extstubs.jl or their own .jl files:
# INITRE→initre.jl  OPEXPN→opexpn.jl  OPCYCL→opcycl.jl  OPLIST→oplist.jl
# SETUP→setup.jl    NOTRE→notre.jl    OPCSET→opcset.jl   SDICLS→sdical.jl
# CRATET→cratet.jl  CWIDTH→cwidth.jl  VOLS→vols.jl       PCTILE→pctile.jl
# DIST→dist.jl      EXTREE→extree.jl  STATS→stats.jl     GHEADS→gheads.jl
# DISPLY→disply.jl  EVTSTV→evtstv.jl  RESAGE→resage.jl   SSTAGE→sstage.jl
# PRTRLS→prtrls.jl  DBS_FIAVBC_TRLS→prtrls.jl  GENPRT→genrpt.jl
# TREGRO→tregro.jl
# All pest/SVS/cover/economics stubs → base/extstubs.jl
