# base/evmon.jl — EVMON: event monitor dispatcher
# Translated from: bin/FVSsn_buildDir/evmon.f (348 lines)
#
# Called from GRINCR (phase 1 and 2) each cycle.
# Tasks:
#   1. Age events (EVAGE)
#   2. Maintain test variable tables (EVTSTV)
#   3. Determine which events occurred (ALGEVL)
#   4. Post event dates (EVPOST)
#   5. Schedule activities following events (OPSCHD / OPINCR)
#
# When IEVT<=1 (no events), returns immediately after EVTSTV.
# When ALGEVL is stubbed (IRC=1), no events fire and the function is a no-op.

const _EVMON_MXPASS = Int32(50)

function EVMON(iph::Integer, ippcl::Integer)
    global IPHASE = Int32(iph)

    ldeb  = DBCHK(false, "EVMON",  Int32(5), ICYC)
    ldeb2 = DBCHK(false, "ALGEVL", Int32(6), ICYC)

    if ldeb
        @printf(io_units[JOSTND], "\n IN EVMON, IEVT=%5d; IPHASE=%3d; ICYC=%3d\n",
                IEVT, IPHASE, ICYC)
    end

    # Load test variable tables if needed
    if LEVUSE; EVTSTV(Int32(0)); end

    # No events defined — exit early
    if IEVT <= Int32(1); return nothing; end

    # Age events only on first phase and after cycle 1
    if !(iph > 1 || ICYC == Int32(1))
        EVAGE(IY[ICYC])
    end

    # -------------------------------------------------------------------------
    # Main loop: evaluate each event and collect those that occurred this cycle.
    # -------------------------------------------------------------------------
    mae    = 0
    ipass  = Int32(0)

    maelnk = zeros(Int32, 2, Int(MAXEVT_OP))   # (1,.)=IEVACT pointer; (2,.)=IEVNTS pointer
    ievlst = zeros(Int32, 3, Int(MAXEVT_OP))   # (1,.)=event; (2,.)=first-group; (3,.)=n-groups

    @label label_6
    noccrd = 0
    irc_r  = Ref(Int32(0))
    ngrps_r = Ref(Int32(0)); ialnk_r = Ref(Int32(0))

    for ien in 1:(Int(IEVT)-1)
        if IEVNTS[ien, 2] > Int32(-1); continue; end

        irc_r[] = Int32(0)
        ALGEVL(LREG, Int(MXLREG_OP), XREG, Int(MXXREG_OP),
               view(IEVCOD, Int(IEVNTS[ien,1]):length(IEVCOD)),
               Int(MAXCOD_OP) - Int(IEVNTS[ien,1]) + 1,
               IY[1], IY[ICYC], ldeb2, Int(JOSTND), irc_r)

        if ldeb
            @printf(io_units[JOSTND],
                " IN EVMON: IEN=%3d IEVNTS(IEN,1)=%5d LREG(1)=%s IRC=%4d\n",
                ien, IEVNTS[ien,1], LREG[1], irc_r[])
        end

        if irc_r[] > Int32(1)
            ERRGRO(true, Int32(21))
        end

        if LREG[1] && irc_r[] == Int32(0)
            EVPOST(Int(JOSTND), ien, Int(IY[ICYC]), ngrps_r, ialnk_r)
            noccrd += 1
            ievlst[1, noccrd] = Int32(ien)
            ievlst[2, noccrd] = ialnk_r[]
            ievlst[3, noccrd] = ngrps_r[]
            if ldeb
                @printf(io_units[JOSTND],
                    " IN EVMON: NOCCRD=%5d IEN=%5d IALNK=%5d NGRPS=%5d\n",
                    noccrd, ien, ialnk_r[], ngrps_r[])
            end
        end
    end

    if ldeb
        @printf(io_units[JOSTND], "\n IN EVMON: NOCCRD=%5d\n", noccrd)
    end
    if noccrd == 0; @goto label_300; end

    # -------------------------------------------------------------------------
    # Collect multi-group events into maelnk
    # -------------------------------------------------------------------------
    mae = 0
    for i in 1:noccrd
        if ievlst[3,i] > Int32(1)
            j1 = Int(ievlst[2,i])
            j2 = Int(ievlst[3,i]) + j1 - 1
            for j in j1:j2
                mae += 1
                maelnk[1, mae] = Int32(j)
                maelnk[2, mae] = ievlst[1, i]
            end
        end
    end

    if ldeb
        @printf(io_units[JOSTND], "\n IN EVMON: NOCCRD=%5d MAE=%5d\n", noccrd, mae)
    end

    if mae > 0
        if ldeb
            for i in 1:mae
                @printf(io_units[JOSTND],
                    " IN EVMON(50): MAELNK(1&2,%3d)= %5d%5d\n",
                    i, maelnk[1,i], maelnk[2,i])
            end
        end

        if LBSETS
            if ldeb
                @printf(io_units[JOSTND],
                    " IN EVMON, BEFORE LBTRIM, LENSLS=%4d SLSET= %s\n",
                    LENSLS, length(SLSET) > 0 ? SLSET[1:min(Int(LENSLS),length(SLSET))] : "")
            end
            mae_r = Ref(Int32(mae))
            LBTRIM(mae_r, maelnk)
            mae = Int(mae_r[])
            if mae <= 0; @goto label_100; end
            if ldeb
                for i in 1:mae
                    @printf(io_units[JOSTND],
                        " IN EVMON(70): MAELNK(1:2,%2d)= %5d%5d\n",
                        i, maelnk[1,i], maelnk[2,i])
                end
            end
        end

        mae_r2 = Ref(Int32(mae))
        OPSAME(mae_r2, maelnk, Int(JOSTND), ldeb)
        mae = Int(mae_r2[])
    end

    @label label_100

    # -------------------------------------------------------------------------
    # If IPPCL == 2: trim ievlst to single-group events
    # -------------------------------------------------------------------------
    if ippcl == 2
        idel = 0
        for inocc in 1:noccrd
            if ievlst[3,inocc] == Int32(1); continue; end
            jevnt = Int(ievlst[1,inocc])
            j1 = 0
            if mae > 0
                for ii in 1:mae
                    if maelnk[2,ii] == Int32(jevnt)
                        j1 = ii; break
                    end
                end
            end
            if j1 == 0
                idel += 1
                ievlst[1,inocc] = Int32(0)
            else
                ievlst[2,inocc] = -maelnk[1,j1]
                ievlst[3,inocc] = Int32(1)
            end
        end

        if idel > 0
            if idel == noccrd
                noccrd = 0
            else
                idel = noccrd + 1
                inocc = 1
                while inocc <= noccrd
                    if ievlst[1,inocc] == Int32(0)
                        idel -= 1
                        for j1 in 1:3
                            ievlst[j1,inocc] = ievlst[j1,idel]
                        end
                    else
                        inocc += 1
                    end
                end
                noccrd = idel
            end
        end
    end

    # -------------------------------------------------------------------------
    # Schedule activity groups for events that occurred
    # -------------------------------------------------------------------------
    nschds = 0
    if noccrd == 0; @goto label_210; end

    ischds_r = Ref(Int32(0)); kode_r = Ref(Int32(0))
    for inocc in 1:noccrd
        if ldeb
            @printf(io_units[JOSTND],
                " IN EVMON: IEVLST(1:3,%3d)= %4d%4d%4d\n",
                inocc, ievlst[1,inocc], ievlst[2,inocc], ievlst[3,inocc])
        end

        ialnk = Int(ievlst[2,inocc])
        if ialnk < 0
            ialnk = -ialnk
        else
            if LBSETS && LENAGL[ialnk] > Int32(-1)
                lenwrk_r = Ref(Int32(0)); kode2_r = Ref(Int32(0))
                LBINTR(Int(LENAGL[ialnk]), AGLSET[ialnk],
                       Int(LENSLS), SLSET,
                       lenwrk_r, WKSTR1, kode2_r)
                if lenwrk_r[] == Int32(0); continue; end
            end
        end

        OPSCHD(IY[ICYC], IEVACT[ialnk,4], IEVACT[ialnk,5], ischds_r, kode_r)
        if ldeb
            @printf(io_units[JOSTND],
                "\n IN EVMON: ICYC=%3d IY(ICYC)=%5d IALNK=%5d IEVACT(IALNK,4:5)=%5d%5d ISCHDS=%4d KODE=%3d\n",
                ICYC, IY[ICYC], ialnk,
                IEVACT[ialnk,4], IEVACT[ialnk,5], ischds_r[], kode_r[])
        end

        if kode_r[] >= Int32(2)
            IEVACT[ialnk, 2] = Int32(-1)
            IEVNTS[Int(ievlst[1,inocc]), 3] = Int32(-1)
            ERRGRO(true, Int32(18))
            @goto label_210
        end

        IEVACT[ialnk, 2] = Int32(2)
        nschds += Int(ischds_r[])
    end

    @label label_210
    if ldeb
        @printf(io_units[JOSTND], "\n IN EVMON: NSCHDS=%5d\n", nschds)
    end

    if nschds > 0
        OPINCR(IY, Int(ICYC), Int(NCYC))
        EVTSTV(Int32(1))
        ipass += Int32(1)
        if ldeb
            @printf(io_units[JOSTND], " IN EVMON: IPASS=%5d\n", ipass)
        end
        if ipass <= _EVMON_MXPASS; @goto label_6; end
    end

    @label label_300
    return nothing
end
