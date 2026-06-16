# base/disply.jl — DISPLY: write stand and tree statistics at start/end of each cycle
# Translated from: bin/FVSsn_buildDir/disply.f (431 lines)
#
# Called from TREGRO at the beginning and end of each cycle.
# Writes formatted stand tables to JOSTND, populates IOSUM[] summary array,
# and maintains running removal totals (TRTPA, TRTCUFT, etc.).
#
# Fortran WRITE(JOTREE) calls are binary scratch-file records consumed by PRTEXM.
# Since PRTEXM is a stub, those writes are omitted here.

function DISPLY()
    io = get(io_units, Int(JOSTND), stdout)

    at1 = "REMOVAL  "; at2 = "VOLUME:  "; at3 = "RESIDUAL "; at4 = "ACCRETION"

    # -----------------------------------------------------------------------
    # Write header record to JOTREE scratch file (binary — stubbed)
    # Fortran: IF (.NOT.LSTART.OR.ITABLE(2).EQ.1) GO TO 10
    #          IRT = 0; WRITE(JOTREE) IRT,NPLT,MGMID
    # -----------------------------------------------------------------------
    # (JOTREE binary writes omitted; PRTEXM is a stub)

    # -----------------------------------------------------------------------
    # 10 CONTINUE
    # IF ICL6 < 0: projection complete — branch to statement 34
    # (write only the final summary line)
    # -----------------------------------------------------------------------
    if ICL6 < Int32(0)
        @goto label_34
    end

    # -----------------------------------------------------------------------
    # Assign JYR = year at start of next cycle
    # -----------------------------------------------------------------------
    jyr = Int(IY[Int(ICYC) + 1])

    # -----------------------------------------------------------------------
    # Volume equation labels (variant-specific if user-specified)
    # -----------------------------------------------------------------------
    if LCVOLS
        std1 = "USER TOTAL"; std2 = "USER MERCH"; std3 = "USER CUBIC SAW"
    else
        std1 = "TOTAL     "; std2 = "MERCH     "; std3 = "CUBIC SAW "
    end
    if LBVOLS
        std4 = "USER MERCH"
    else
        std4 = "MERCH     "
    end

    # -----------------------------------------------------------------------
    # Skip stand composition table if ITABLE(1)==1
    # -----------------------------------------------------------------------
    if ITABLE[1] == Int32(1)
        @goto label_32
    end

    # Skip removal stats if at start or no removals
    if LSTART
        @goto label_30
    end
    if ONTREM[7] <= Float32(0)
        @goto label_20
    end

    # -----------------------------------------------------------------------
    # Write removal statistics (9003/9004/9005 formats)
    # -----------------------------------------------------------------------
    @printf(io, "\n")

    # 9004 FORMAT(6X,A9,3X,5F7.1,F8.1,F9.0,' TREES   ',3(F5.0,'%% ',A3,','),F5.0,'%% ',A3)
    @printf(io, "      %-9s   %7.1f%7.1f%7.1f%7.1f%7.1f%8.1f%9.0f TREES   %5.0f%% %-3s,%5.0f%% %-3s,%5.0f%% %-3s,%5.0f%% %-3s\n",
            at1,
            ONTREM[1],ONTREM[2],ONTREM[3],ONTREM[4],ONTREM[5],ONTREM[6],ONTREM[7],
            OSPTT[1],IOSPTT[1],OSPTT[2],IOSPTT[2],OSPTT[3],IOSPTT[3],OSPTT[4],IOSPTT[4])

    # 9005 volume block (AT2 label + 4 volume lines)
    @printf(io, "      %-9s\n", at2)
    @printf(io, "        %-10s%7.1f%7.1f%7.1f%7.1f%7.1f%8.1f%9.0f CUFT    %5.0f%% %-3s,%5.0f%% %-3s,%5.0f%% %-3s,%5.0f%% %-3s\n",
            std1,
            OCVREM[1],OCVREM[2],OCVREM[3],OCVREM[4],OCVREM[5],OCVREM[6],OCVREM[7],
            OSPTV[1],IOSPTV[1],OSPTV[2],IOSPTV[2],OSPTV[3],IOSPTV[3],OSPTV[4],IOSPTV[4])
    @printf(io, "        %-10s%7.1f%7.1f%7.1f%7.1f%7.1f%8.1f%9.0f CUFT    %5.0f%% %-3s,%5.0f%% %-3s,%5.0f%% %-3s,%5.0f%% %-3s\n",
            std2,
            OMCREM[1],OMCREM[2],OMCREM[3],OMCREM[4],OMCREM[5],OMCREM[6],OMCREM[7],
            OSPMR[1],IOSPMR[1],OSPMR[2],IOSPMR[2],OSPMR[3],IOSPMR[3],OSPMR[4],IOSPMR[4])
    @printf(io, "        %-10s%7.1f%7.1f%7.1f%7.1f%7.1f%8.1f%9.0f CUFT    %5.0f%% %-3s,%5.0f%% %-3s,%5.0f%% %-3s,%5.0f%% %-3s\n",
            std3,
            OSCREM[1],OSCREM[2],OSCREM[3],OSCREM[4],OSCREM[5],OSCREM[6],OSCREM[7],
            OSPSR[1],IOSPSR[1],OSPSR[2],IOSPSR[2],OSPSR[3],IOSPSR[3],OSPSR[4],IOSPSR[4])
    @printf(io, "        %-10s%7.1f%7.1f%7.1f%7.1f%7.1f%8.1f%9.0f BDFT    %5.0f%% %-3s,%5.0f%% %-3s,%5.0f%% %-3s,%5.0f%% %-3s\n",
            std4,
            OBFREM[1],OBFREM[2],OBFREM[3],OBFREM[4],OBFREM[5],OBFREM[6],OBFREM[7],
            OSPBR[1],IOSPBR[1],OSPBR[2],IOSPBR[2],OSPBR[3],IOSPBR[3],OSPBR[4],IOSPBR[4])

    @printf(io, "\n")
    @printf(io, "      %-9s   %7.1f%7.1f%7.1f%7.1f%7.1f%8.1f%9.0f TREES   %5.0f%% %-3s,%5.0f%% %-3s,%5.0f%% %-3s,%5.0f%% %-3s\n",
            at3,
            ONTRES[1],ONTRES[2],ONTRES[3],ONTRES[4],ONTRES[5],ONTRES[6],ONTRES[7],
            OSPRT[1],IOSPRT[1],OSPRT[2],IOSPRT[2],OSPRT[3],IOSPRT[3],OSPRT[4],IOSPRT[4])

    # -----------------------------------------------------------------------
    # 20 CONTINUE — write accretion and mortality statistics
    # -----------------------------------------------------------------------
    @label label_20
    @printf(io, "\n")

    # 9006 FORMAT(6X,A9,3X,5F7.1,F8.1,F9.0,' CUFT/YR ',3(F5.0,'%% ',A3,','),F5.0,'%% ',A3)
    @printf(io, "      %-9s   %7.1f%7.1f%7.1f%7.1f%7.1f%8.1f%9.0f CUFT/YR %5.0f%% %-3s,%5.0f%% %-3s,%5.0f%% %-3s,%5.0f%% %-3s\n",
            at4,
            OACC[1],OACC[2],OACC[3],OACC[4],OACC[5],OACC[6],OACC[7],
            OSPAC[1],IOSPAC[1],OSPAC[2],IOSPAC[2],OSPAC[3],IOSPAC[3],OSPAC[4],IOSPAC[4])

    local mortlbl = LMORT ? "USER MORT" : "MORTALITY"
    @printf(io, "      %-9s   %7.1f%7.1f%7.1f%7.1f%7.1f%8.1f%9.0f CUFT/YR %5.0f%% %-3s,%5.0f%% %-3s,%5.0f%% %-3s,%5.0f%% %-3s\n",
            mortlbl,
            OMORT[1],OMORT[2],OMORT[3],OMORT[4],OMORT[5],OMORT[6],OMORT[7],
            OSPMO[1],IOSPMO[1],OSPMO[2],IOSPMO[2],OSPMO[3],IOSPMO[3],OSPMO[4],IOSPMO[4])

    # -----------------------------------------------------------------------
    # 30 CONTINUE — write current stand statistics
    # -----------------------------------------------------------------------
    @label label_30
    @printf(io, "\n")

    # 9007 FORMAT(/I4,'  TREES',T19,5F7.1,F8.1,F9.0,' TREES   ',3(F5.0,'%% ',A3,','),F5.0,'%% ',A3)
    @printf(io, "\n%4d  TREES       %7.1f%7.1f%7.1f%7.1f%7.1f%8.1f%9.0f TREES   %5.0f%% %-3s,%5.0f%% %-3s,%5.0f%% %-3s,%5.0f%% %-3s\n",
            jyr,
            ONTCUR[1],ONTCUR[2],ONTCUR[3],ONTCUR[4],ONTCUR[5],ONTCUR[6],ONTCUR[7],
            OSPCT[1],IOSPCT[1],OSPCT[2],IOSPCT[2],OSPCT[3],IOSPCT[3],OSPCT[4],IOSPCT[4])

    @printf(io, "      %-9s\n", at2)
    @printf(io, "        %-10s%7.1f%7.1f%7.1f%7.1f%7.1f%8.1f%9.0f CUFT    %5.0f%% %-3s,%5.0f%% %-3s,%5.0f%% %-3s,%5.0f%% %-3s\n",
            std1,
            OCVCUR[1],OCVCUR[2],OCVCUR[3],OCVCUR[4],OCVCUR[5],OCVCUR[6],OCVCUR[7],
            OSPCV[1],IOSPCV[1],OSPCV[2],IOSPCV[2],OSPCV[3],IOSPCV[3],OSPCV[4],IOSPCV[4])
    @printf(io, "        %-10s%7.1f%7.1f%7.1f%7.1f%7.1f%8.1f%9.0f CUFT    %5.0f%% %-3s,%5.0f%% %-3s,%5.0f%% %-3s,%5.0f%% %-3s\n",
            std2,
            OMCCUR[1],OMCCUR[2],OMCCUR[3],OMCCUR[4],OMCCUR[5],OMCCUR[6],OMCCUR[7],
            OSPMC[1],IOSPMC[1],OSPMC[2],IOSPMC[2],OSPMC[3],IOSPMC[3],OSPMC[4],IOSPMC[4])
    @printf(io, "        %-10s%7.1f%7.1f%7.1f%7.1f%7.1f%8.1f%9.0f CUFT    %5.0f%% %-3s,%5.0f%% %-3s,%5.0f%% %-3s,%5.0f%% %-3s\n",
            std3,
            OSCCUR[1],OSCCUR[2],OSCCUR[3],OSCCUR[4],OSCCUR[5],OSCCUR[6],OSCCUR[7],
            OSPSC[1],IOSPSC[1],OSPSC[2],IOSPSC[2],OSPSC[3],IOSPSC[3],OSPSC[4],IOSPSC[4])
    @printf(io, "        %-10s%7.1f%7.1f%7.1f%7.1f%7.1f%8.1f%9.0f BDFT    %5.0f%% %-3s,%5.0f%% %-3s,%5.0f%% %-3s,%5.0f%% %-3s\n",
            std4,
            OBFCUR[1],OBFCUR[2],OBFCUR[3],OBFCUR[4],OBFCUR[5],OBFCUR[6],OBFCUR[7],
            OSPBV[1],IOSPBV[1],OSPBV[2],IOSPBV[2],OSPBV[3],IOSPBV[3],OSPBV[4],IOSPBV[4])

    @label label_32

    # -----------------------------------------------------------------------
    # Write sample tree output.  Skip if LSTART.
    # -----------------------------------------------------------------------
    if LSTART
        @goto label_39
    end

    @label label_34
    ioage = Int(IAGE) + Int(IY[Int(ICYC)]) - Int(IY[1])

    if ITABLE[2] == Int32(1)
        @goto label_41
    end

    # Compute JSDI (integer SDI before cutting)
    jsdi = LZEIDE ? Int(SDIBC2 + Float32(0.5)) : Int(SDIBC + Float32(0.5))

    if ONTREM[7] > Float32(0)
        @goto label_35
    end

    # No thinning: write pre-thin record (IRT=1)
    # WRITE(JOTREE) 1, IOAGE, ORMSQD, OLDTPA, OLDBA, OLDAVH, RELDM1, JSDI  — binary stub
    @goto label_36

    @label label_35
    # Thinning occurred: write pre-thin (IRT=2) then post-thin (IRT=3)
    # WRITE(JOTREE) 2, IOAGE, ORMSQD, OLDTPA, OLDBA, OLDAVH, RELDM1, JSDI  — binary stub
    jsdi = LZEIDE ? Int(SDIAC2 + Float32(0.5)) : Int(SDIAC + Float32(0.5))
    # WRITE(JOTREE) 3, ATAVD, ATTPA, ATBA, ATAVH, ATCCF, JSDI  — binary stub

    @label label_36
    if ICL6 < Int32(0)
        @goto label_90
    end

    # -----------------------------------------------------------------------
    # 39 CONTINUE — write year and period length
    # -----------------------------------------------------------------------
    @label label_39
    if ITABLE[2] == Int32(1)
        @goto label_41
    end

    i_yr = jyr
    if IFST != Int32(0)
        global IFST = Int32(0)
        if !LSTART
            i_yr = -i_yr
        end
    end

    # WRITE(JOTREE) 4, I_YR, IFINT  — binary stub
    # WRITE(JOTREE) 5, IONSP, DBHIO, HTIO, IOICR, DGIO, PCTIO, PRBIO  — binary stub

    @label label_41

    # -----------------------------------------------------------------------
    # Load IOSUM summary array
    # -----------------------------------------------------------------------
    iknt = Int(ICYC) + 1

    # Calculate forest type, size class, stocking class
    dum1 = Float32(0)
    ixf  = Int32(2)
    isnoft = IFORTP
    FORTYP(ixf, dum1)

    # -----------------------------------------------------------------------
    # Estimate stand age from size class + abirth if LSTART
    # -----------------------------------------------------------------------
    if LSTART
        global TRTPA   = Float32(0)
        global TRTCUFT = Float32(0)
        global TRMCUFT = Float32(0)
        global TRSCUFT = Float32(0)
        global TRBDFT  = Float32(0)

        sumage = Float32(0); ageknt = Float32(0)

        if ISZCL == Int32(0) || ISZCL > Int32(3)
            global ICAGE = Int32(0)
            @goto label_42
        elseif ISZCL == Int32(3)
            for i in 1:Int(ITRN)
                if DBH[i] < Float32(5)
                    sumage += ABIRTH[i] * PROB[i]
                    ageknt += PROB[i]
                end
            end
        elseif ISZCL == Int32(2)
            for i in 1:Int(ITRN)
                ifia = if FIAJSP[Int(ISP[i])][1:1] == "-"
                    998
                else
                    parse(Int, strip(FIAJSP[Int(ISP[i])]))
                end
                d = DBH[i]
                if (ifia < 300 && d >= Float32(5) && d < Float32(9)) ||
                   (ifia >= 300 && d >= Float32(5) && d < Float32(11))
                    sumage += ABIRTH[i] * PROB[i]
                    ageknt += PROB[i]
                end
            end
        else   # ISZCL == 1 (large trees)
            for i in 1:Int(ITRN)
                ifia = if FIAJSP[Int(ISP[i])][1:1] == "-"
                    998
                else
                    parse(Int, strip(FIAJSP[Int(ISP[i])]))
                end
                d = DBH[i]
                if (ifia < 300 && d >= Float32(9)) ||
                   (ifia >= 300 && d >= Float32(11))
                    sumage += ABIRTH[i] * PROB[i]
                    ageknt += PROB[i]
                end
            end
        end

        global ICAGE = ageknt > Float32(0) ? Int32(floor(sumage / ageknt)) : Int32(0)
    end

    @label label_42

    IOSUM[1,  iknt] = Int32(IY[iknt])
    IOSUM[3,  iknt] = Int32(ONTCUR[7] / GROSPC + Float32(0.5))
    IOSUM[4,  iknt] = Int32(OCVCUR[7] / GROSPC + Float32(0.5))
    IOSUM[5,  iknt] = Int32(OMCCUR[7] / GROSPC + Float32(0.5))
    IOSUM[6,  iknt] = Int32(OBFCUR[7] / GROSPC + Float32(0.5))
    IOSUM[21, iknt] = Int32(OSCCUR[7] / GROSPC + Float32(0.5))

    IOSUM[18, iknt] = Int32(IFORTP)
    IOSUM[19, iknt] = Int32(ISZCL)
    IOSUM[20, iknt] = Int32(ISTCL)

    if LSTART
        @goto label_100
    end

    # -----------------------------------------------------------------------
    # 90 CONTINUE — load final line of summary output
    # -----------------------------------------------------------------------
    @label label_90
    iknt = Int(ICYC)
    IOSUM[2, iknt] = Int32(ioage)

    if ONTREM[7] <= Float32(0)
        @goto label_91
    end

    IOSUM[3,  iknt] = Int32(OLDTPA / GROSPC + Float32(0.5))
    IOSUM[11, iknt] = Int32(ATBA   / GROSPC + Float32(0.5))
    IOSUM[12, iknt] = Int32(ATCCF  / GROSPC + Float32(0.5))
    IOSUM[13, iknt] = Int32(ATAVH  + Float32(0.5))
    QDBHAT[iknt] = ATAVD
    sdiactmp = LZEIDE ? SDIAC2 : SDIAC
    ISDIAT[iknt] = Int32(sdiactmp / GROSPC + Float32(0.5))
    @goto label_92

    @label label_91
    IOSUM[11, iknt] = Int32(OLDBA  / GROSPC + Float32(0.5))
    IOSUM[12, iknt] = Int32(RELDM1 / GROSPC + Float32(0.5))
    IOSUM[13, iknt] = Int32(OLDAVH + Float32(0.5))
    QDBHAT[iknt] = ORMSQD
    sdibctmp = LZEIDE ? SDIBC2 : SDIBC
    ISDIAT[iknt] = Int32(sdibctmp / GROSPC + Float32(0.5))

    @label label_92
    sdibctmp = LZEIDE ? SDIBC2 : SDIBC
    ISDI_S[iknt] = Int32(sdibctmp / GROSPC + Float32(0.5))

    IOSUM[7,  iknt] = Int32(ONTREM[7] / GROSPC + Float32(0.5))
    IOSUM[8,  iknt] = Int32(OCVREM[7] / GROSPC + Float32(0.5))
    IOSUM[9,  iknt] = Int32(OMCREM[7] / GROSPC + Float32(0.5))
    IOSUM[22, iknt] = Int32(OSCREM[7] / GROSPC + Float32(0.5))
    IOSUM[10, iknt] = Int32(OBFREM[7] / GROSPC + Float32(0.5))

    # Accumulate removal totals
    if iknt <= Int(NCYC)
        global TRTPA   = TRTPA   + ONTREM[7]
        global TRTCUFT = TRTCUFT + OCVREM[7]
        global TRMCUFT = TRMCUFT + OMCREM[7]
        global TRSCUFT = TRSCUFT + OSCREM[7]
        global TRBDFT  = TRBDFT  + OBFREM[7]
    end

    IOSUM[14, iknt] = Int32(IFINT)
    IOSUM[15, iknt] = Int32(OACC[7]  / GROSPC + Float32(0.5))
    IOSUM[16, iknt] = Int32(OMORT[7] / GROSPC + Float32(0.5))
    QSDBT[iknt]  = ORMSQD
    IOLDBA[iknt] = Int32(OLDBA  / GROSPC + Float32(0.5))
    IBTCCF[iknt] = Int32(RELDM1 / GROSPC + Float32(0.5))
    IBTAVH[iknt] = Int32(OLDAVH + Float32(0.5))

    iswt = if SAMWT >= Float32(0.99999)
        Int32(floor(SAMWT + Float32(0.0001)))
    else
        Int32(floor(SAMWT * Float32(100000) + Float32(0.5)))
    end
    IOSUM[17, iknt] = iswt

    @label label_100
    if ICL6 > Int32(0)
        @goto label_150
    end

    # -----------------------------------------------------------------------
    # Print example tree record and stand attribute table
    # -----------------------------------------------------------------------
    if ITABLE[2] != Int32(1)
        # ENDFILE JOTREE  — binary scratch file end-of-file (stub)
        PRTEXM(Int(JOTREE), Int(JOSTND), ITITLE)
        irtncd = fvsGetRtnCode()
        if irtncd != Int32(0); return; end
    end

    # -----------------------------------------------------------------------
    # Print summary output
    # -----------------------------------------------------------------------
    for i in 7:10
        IOSUM[i, iknt] = Int32(0)
    end
    for i in 14:16
        IOSUM[i, iknt] = Int32(0)
    end

    # Load final MAI value
    if MAIFLG == Int32(0) && IOSUM[2, iknt] > Int32(0)
        BCYMAI[iknt] = (Float32(IOSUM[5, iknt]) + TOTREM) / Float32(IOSUM[2, iknt])
    else
        BCYMAI[iknt] = Float32(0)
    end

    if LECON; ECEND(); end

    i_sum = Int32(0)
    if LSUMRY; i_sum = JOSUM; end

    j_out = JOSTND
    if ITABLE[3] == Int32(1); j_out = Int32(0); end

    GROHED(JOSTND)
    LBSPLW(Int(JOSTND))
    SUMOUT(IOSUM, Int32(22), Int32(0), JOSTND, j_out, i_sum, Int32(iknt), MGMID, NPLT, SAMWT, ITITLE, IPTINV)
    OPLIST(false, NPLT, MGMID, ITITLE)

    if LECON; ECLBL(); end

    @label label_150
    if LSTART && LSCRN; SUMHED(); end
    if !LSTART && LSCRN
        joscrn_io = get(io_units, Int(JOSCRN), stdout)
        # 170 FORMAT(I4,I6,3I4,F5.1,4I6,3I4,F5.1,I4,I4)
        @printf(joscrn_io, "%4d%6d%4d%4d%4d%5.1f%6d%6d%6d%6d%4d%4d%4d%5.1f%4d%4d\n",
                IOSUM[1, iknt],  IOSUM[3, iknt],
                IOLDBA[iknt],    ISDI_S[iknt],    IBTAVH[iknt],  QSDBT[iknt],
                IOSUM[4, iknt],  IOSUM[7, iknt],  IOSUM[8, iknt], IOSUM[10, iknt],
                IOSUM[11, iknt], ISDIAT[iknt],     IOSUM[13, iknt], QDBHAT[iknt],
                IOSUM[15, iknt], IOSUM[16, iknt])
    end

    if !LSTART
        DBSSUMRY2()
        DBSCARBBIOSUMRY()
    end

    return nothing
end
