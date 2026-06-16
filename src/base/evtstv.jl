# base/evtstv.jl — EVTSTV: populate event monitor test variable tables
# Translated from bin/FVSsn_buildDir/evtstv.f (660 lines)
#
# Entry points (separate Julia functions):
#   EVTSTV(iuserv) — main; fills TSTV1/TSTV2/TSTV3 and evaluates COMPUTE activities
#   EVSET4(iset, value) — set TSTV4[iset]
#   EVUST4(iset)        — unset TSTV4[iset]
#   EVGET4(ival, vset_ref, lset_ref) — retrieve TSTV4[ival]
#
# IUSERV:
#   0  = normal call (load all variable groups for current phase)
#  >0  = compute user-defined variables only (scheduled for specific year)
#  <0  = type-1 variables only (initialize SDI vars, then return)

function EVTSTV(iuserv::Integer)
    ldeb  = DBCHK(false, "EVTSTV", Int32(6), ICYC)
    ldeb2 = DBCHK(false, "ALGEVL", Int32(6), ICYC)

    if ldeb
        @printf(io_units[JOSTND], " IN EVTSTV,IUSERV=%4d ICYC=%4d GROSPC=%5.3f BA=%7.3f RMSQD=%6.3f\n",
                iuserv, ICYC, GROSPC, BA, RMSQD)
    end

    if iuserv >= 1; @goto label_20; end

    # -----------------------------------------------------------------------
    # GROUP 1 — phase 1 variables, always known
    # -----------------------------------------------------------------------
    if iuserv < 0
        global IPHASE = Int32(1)
        global BTSDIX = Float32(0.0)
        global SDIBC  = Float32(0.0)
        global SDIBC2 = Float32(0.0)
    else
        if IPHASE > Int32(1); @goto label_10; end
    end

    if ldeb
        @printf(io_units[JOSTND], " IN EVTSTV,IPHASE,ICYC=%4d%4d\n", IPHASE, ICYC)
    end

    TSTV1[1]  = Float32(IY[max(1, Int(ICYC))])
    TSTV1[2]  = Float32(IAGE) + TSTV1[1] - Float32(IY[1])
    TSTV1[3]  = TPROB / GROSPC
    TSTV1[4]  = OCVCUR[7] / GROSPC
    TSTV1[5]  = OMCCUR[7] / GROSPC
    TSTV1[6]  = OBFCUR[7] / GROSPC
    TSTV1[20] = OSCCUR[7] / GROSPC
    TSTV1[7]  = BA / GROSPC
    TSTV1[51] = (OAGBIOCUR[7]   / GROSPC) / Float32(2000)
    TSTV1[52] = (OMERBIOCUR[7]  / GROSPC) / Float32(2000)
    TSTV1[53] = (OCSAWBIOCUR[7] / GROSPC) / Float32(2000)
    TSTV1[54] = (OFOLIBIO[7]    / GROSPC) / Float32(2000)
    TSTV1[55] = (OAGCARBCUR[7]  / GROSPC) / Float32(2000)
    TSTV1[56] = (OMERCARBCUR[7] / GROSPC) / Float32(2000)
    TSTV1[57] = (OCSAWCARBCUR[7]/ GROSPC) / Float32(2000)
    TSTV1[58] = (OFOLICARB[7]   / GROSPC) / Float32(2000)
    TSTV1[8]  = RELDEN
    TSTV1[9]  = AVH
    TSTV1[10] = RMSQD
    TSTV1[11] = Float32(1.0)
    TSTV1[12] = Float32(0.0)
    TSTV1[13] = Float32(ICYC)
    TSTV1[14] = Float32(ITRN)
    TSTV1[15] = BTSDIX
    TSTV1[16] = SDIBC
    TSTV1[59] = DR016
    TSTV1[17] = RMSQD != 0.0f0 ? TSTV1[7] / sqrt(TSTV1[10]) : Float32(0.0)

    TSTV1[18] = RDCLS2(Int32(0), Float32(0.0), Float32(999.0), Int32(1), Int32(0)) / GROSPC

    for i in 1:MAXSP; BCCFSP[i] = RELDSP[i]; end

    if ICYC <= 1
        TSTV1[27] = Float32(ISLOP)
        TSTV1[28] = Float32(IASPEC)
        TSTV1[29] = Float32(ELEV) * Float32(100.0)
        TSTV1[30] = SAMWT
        TSTV1[31] = Float32(IY[1])
        TSTV1[37] = TLAT
        TSTV1[38] = TLONG
        TSTV1[39] = Float32(ISTATE)
        TSTV1[40] = Float32(ICNTY)
    end

    TSTV1[26] = Float32(ICL5)
    TSTV1[32] = Float32(IY[max(1, Int(ICYC)) + 1] - 1)
    TSTV1[33] = Float32(IPHASE)
    TSTV1[34] = Float32(0.0)
    TSTV1[41] = Float32(IFORTP)
    TSTV1[42] = Float32(ISZCL)
    TSTV1[43] = Float32(ISTCL)
    TSTV1[44] = GROSPC > Float32(0.0) ? Float32(1.0) / GROSPC : Float32(0.0)
    TSTV1[45] = Float32(0.0)
    TSTV1[46] = Float32(ICAGE)
    TSTV1[47] = Float32(0.0)
    TSTV1[19] = Float32(0.0)
    TSTV1[48] = Float32(ISILFT)

    findx_ref = Ref(Float32(0.0))
    FISHER_SN(findx_ref)
    TSTV1[49] = findx_ref[]

    TSTV1[50] = SDIBC2

    # Stand mistletoe rating
    if ITRN >= 1
        prbsum = Float32(0.0); dmrsum = Float32(0.0)
        idmr_ref = Ref(Int32(0))
        for i in 1:ITRN
            MISGET(i, idmr_ref)
            prbsum += PROB[i]
            dmrsum += Float32(idmr_ref[]) * PROB[i]
        end
        TSTV1[34] = prbsum < Float32(1e-6) ? Float32(0.0) : dmrsum / prbsum
    end

    if ISISP > Int32(0)
        TSTV1[35] = STNDSI
    else
        TSTV1[35] = Float32(0.0)
    end
    TSTV1[36] = Float32(0.0)

    if ldeb
        for i in 1:50
            @printf(io_units[JOSTND], " TSTV1[%2d]=%11.3e\n", i, TSTV1[i])
        end
    end

    if iuserv < 0; return nothing; end

    # -----------------------------------------------------------------------
    # MAI logic
    # -----------------------------------------------------------------------
    if ICYC == Int32(1)
        if TSTV1[2] > Float32(0.0)
            BCYMAI[ICYC] = Float32(IOSUM[5, ICYC]) / TSTV1[2]
        else
            BCYMAI[ICYC] = Float32(0.0)
            if TSTV1[3] == Float32(0.0)
                global NEWSTD = Int32(1)
            else
                global MAIFLG = Int32(1)
            end
        end
        TSTV1[45] = BCYMAI[ICYC]
        global AGELST = TSTV1[2]
    else
        age  = TSTV1[2]
        zero = age - Float32(IY[ICYC] - IY[ICYC - 1])
        if age < AGELST; global TOTREM = Float32(0.0); end

        if zero == Float32(0.0) || (MAIFLG == Int32(1) && NEWSTD != Int32(1))
            BCYMAI[ICYC] = Float32(0.0)
            if NEWSTD == Int32(0); global MAIFLG = Int32(1); end
            @goto label_11
        end
        curvol = Float32(IOSUM[5, ICYC])
        if age > AGELST; global TOTREM = Float32(IOSUM[9, ICYC - 1]) + TOTREM; end
        BCYMAI[ICYC] = (TOTREM + curvol) / age

        @label label_11

        # After-treatment clearcut check
        if TSTV2[5] == Float32(0.0) && TSTV2[6] == Float32(0.0) &&
           TSTV2[14] == Float32(0.0) && TSTV2[9] > Float32(0.0)
            global NEWSTD = Int32(1)
            global TOTREM = Float32(0.0)
        end

        if zero == Float32(0.0) && TSTV1[3] == Float32(0.0); global NEWSTD = Int32(1); end

        TSTV1[45] = BCYMAI[ICYC]
        global AGELST = age
    end

    # -----------------------------------------------------------------------
    # DBH^3-weighted average and height-weighted BA
    # -----------------------------------------------------------------------
    tadwba = Float32(0.0); tahwba = Float32(0.0)
    for i in 1:ITRN
        tadwba += (DBH[i]^3) * Float32(0.0054542) * PROB[i]
        tahwba += HT[i] * (DBH[i]^2) * Float32(0.0054542) * PROB[i]
    end
    TSTV1[47] = (BA > Float32(0.0) && GROSPC > Float32(0.0)) ? tadwba / BA : Float32(0.0)
    TSTV1[19] = (BA > Float32(0.0) && GROSPC > Float32(0.0)) ? tahwba / BA : Float32(0.0)

    # -----------------------------------------------------------------------
    # GROUP 3 — known after cycle 1
    # -----------------------------------------------------------------------
    if ICYC > Int32(1)
        TSTV3[1] = Float32(IOSUM[15, ICYC - 1])
        TSTV3[2] = Float32(IOSUM[16, ICYC - 1])
        TSTV3[3] = TSTV3[1] - TSTV3[2]
        TSTV3[4] = Float32(0.0)
        TSTV3[5] = TPROB / GROSPC - Float32(IOSUM[3, ICYC - 1])
        x = Float32(IOSUM[3, ICYC - 1])
        TSTV3[6] = x > Float32(0.0) ? (TPROB / GROSPC) / x * Float32(100.0) : Float32(0.0)
        TSTV3[7] = BA / GROSPC - Float32(IOLDBA[ICYC - 1])
        x = Float32(IOLDBA[ICYC - 1])
        TSTV3[8] = x > Float32(0.0) ? (BA / GROSPC) / x * Float32(100.0) : Float32(0.0)
        TSTV3[9] = RELDEN / GROSPC - Float32(IBTCCF[ICYC - 1])
        x = Float32(IBTCCF[ICYC - 1])
        TSTV3[10] = x > Float32(0.0) ? (RELDEN / GROSPC) / x * Float32(100.0) : Float32(0.0)
        # ORGANON canopy cover (stub returns 0)
        v2_ref = Ref(Float32(0.0))
        GETORGV(Int32(1), v2_ref); TSTV3[11] = v2_ref[]
        GETORGV(Int32(2), v2_ref); TSTV3[12] = v2_ref[]
    end

    @goto label_20

    # -----------------------------------------------------------------------
    # label_10: phase 2 — load GROUP 2 variables (after-treatment)
    # -----------------------------------------------------------------------
    @label label_10
    TSTV1[33] = Float32(IPHASE)
    TSTV1[48] = Float32(ISILFT)
    if ONTREM[7] > Float32(0.0)
        findx_ref2 = Ref(Float32(0.0))
        FISHER_SN(findx_ref2)
        TSTV1[49] = findx_ref2[]
    end

    TSTV1[14] = Float32(ITRN)
    if ONTREM[7] > Float32(0.0); TSTV1[36] = Float32(1.0); end

    TSTV2[1]  = TPROB / GROSPC
    TSTV2[5]  = BA / GROSPC
    TSTV2[6]  = RELDEN
    TSTV2[7]  = AVH
    TSTV2[8]  = RMSQD
    TSTV2[9]  = ONTREM[7] / GROSPC
    TSTV2[10] = OCVREM[7] / GROSPC
    TSTV2[11] = OMCREM[7] / GROSPC
    TSTV2[12] = OBFREM[7] / GROSPC
    TSTV2[21] = OSCREM[7] / GROSPC
    TSTV2[23] = (OAGBIOREM[7]   / GROSPC) / Float32(2000)
    TSTV2[29] = (OAGCARBREM[7]  / GROSPC) / Float32(2000)
    TSTV2[25] = (OMERBIOREM[7]  / GROSPC) / Float32(2000)
    TSTV2[31] = (OMERCARBREM[7] / GROSPC) / Float32(2000)
    TSTV2[27] = (OCSAWBIOREM[7] / GROSPC) / Float32(2000)
    TSTV2[33] = (OCSAWCARBREM[7]/ GROSPC) / Float32(2000)
    TSTV2[35] = (OFOLIBIOREM[7] / GROSPC) / Float32(2000)
    TSTV2[37] = (OFOLICARBREM[7]/ GROSPC) / Float32(2000)
    TSTV2[38] = DR016

    for i in 1:MAXSP; ACCFSP[i] = RELDSP[i]; end

    TSTV2[13] = ATSDIX
    TSTV2[14] = SDIAC
    TSTV2[18] = SDIAC2
    TSTV2[15] = RMSQD != Float32(0.0) ? TSTV2[5] / sqrt(TSTV2[8]) : Float32(0.0)
    TSTV2[2]  = (OCVCUR[7]  - OCVREM[7])  / GROSPC
    TSTV2[3]  = (OMCCUR[7]  - OMCREM[7])  / GROSPC
    TSTV2[4]  = (OBFCUR[7]  - OBFREM[7])  / GROSPC
    TSTV2[20] = (OSCCUR[7]  - OSCREM[7])  / GROSPC
    TSTV2[22] = ((OAGBIOCUR[7]    - OAGBIOREM[7])    / GROSPC) / Float32(2000)
    TSTV2[28] = ((OAGCARBCUR[7]   - OAGCARBREM[7])   / GROSPC) / Float32(2000)
    TSTV2[24] = ((OMERBIOCUR[7]   - OMERBIOREM[7])   / GROSPC) / Float32(2000)
    TSTV2[30] = ((OMERCARBCUR[7]  - OMERCARBREM[7])  / GROSPC) / Float32(2000)
    TSTV2[26] = ((OCSAWBIOCUR[7]  - OCSAWBIOREM[7])  / GROSPC) / Float32(2000)
    TSTV2[32] = ((OCSAWCARBCUR[7] - OCSAWCARBREM[7]) / GROSPC) / Float32(2000)
    TSTV2[34] = ((OFOLIBIO[7]     - OFOLIBIOREM[7])  / GROSPC) / Float32(2000)
    TSTV2[36] = ((OFOLICARB[7]    - OFOLICARBREM[7]) / GROSPC) / Float32(2000)

    if ldeb
        for i in 1:14
            @printf(io_units[JOSTND], " TSTV2[%2d]=%11.3e\n", i, TSTV2[i])
        end
    end

    tadwba2 = Float32(0.0); tahwba2 = Float32(0.0)
    for i in 1:ITRN
        tadwba2 += (DBH[i]^3) * Float32(0.0054542) * PROB[i]
        tahwba2 += HT[i] * (DBH[i]^2) * Float32(0.0054542) * PROB[i]
    end
    TSTV2[16] = (BA > Float32(0.0) && GROSPC > Float32(0.0)) ? tadwba2 / BA : Float32(0.0)

    TSTV2[17] = RDCLS2(Int32(0), Float32(0.0), Float32(999.0), Int32(1), Int32(0)) / GROSPC
    TSTV2[19] = (BA > Float32(0.0) && GROSPC > Float32(0.0)) ? tahwba2 / BA : Float32(0.0)

    # -----------------------------------------------------------------------
    # label_20: evaluate COMPUTE activities and user-defined variables
    # -----------------------------------------------------------------------
    @label label_20
    if iuserv > 1; global IPHASE = Int32(2); end

    myact = Int32[33, 101, 102]
    ntodo_ref = Ref(Int32(0))
    OPFIND(Int32(3), myact, ntodo_ref)
    ntodo = ntodo_ref[]

    if ldeb; @printf(io_units[JOSTND], "\n IN EVTSTV; NTODO: %4d\n", ntodo); end

    ntodo == 0 && return nothing

    idat_ref  = Ref(Int32(0)); iactk_ref = Ref(Int32(0))
    np_ref    = Ref(Int32(0)); prm       = zeros(Float32, 3)

    for itodo in 1:ntodo
        OPGET(Int32(itodo), Int32(3), idat_ref, iactk_ref, np_ref, prm)
        idat  = idat_ref[]
        iactk = iactk_ref[]

        if iuserv > 1 && iuserv != Int(idat); continue; end

        if ldeb
            @printf(io_units[JOSTND], " IN EVTSTV: ITODO=%4d IACTK=%4d\n", itodo, iactk)
        end

        iactk < Int32(0) && continue

        if iactk == Int32(33)
            its5  = Int(prm[2]); its5 > 500 && (its5 -= 500)
            locod = Int(prm[3])

            irc_ref = Ref(Int32(0))
            ALGEVL(LREG, Int(MXLREG_OP), XREG, Int(MXXREG_OP),
                   view(IEVCOD, locod:length(IEVCOD)),
                   Int(MAXCOD_OP) - locod + 1,
                   IY[1], IY[ICYC], ldeb2, Int(JOSTND), irc_ref)
            irc = irc_ref[]

            if irc == Int32(0)
                TSTV5[its5]  = XREG[1]
                LTSTV5[its5] = true
                PARMS[Int(IACT[Int(IPTODO[itodo]), 2])] = XREG[1]
                iyear_done = IY[ICYC]
                if iuserv > 1 && iuserv == Int(idat); iyear_done = iuserv; end
                OPDONE(itodo, iyear_done)
            elseif irc == Int32(1)
                LTSTV5[its5] = false
            else
                LTSTV5[its5] = false
                OPDEL1(itodo)
            end

            if ldeb
                @printf(io_units[JOSTND],
                    " IN EVTSTV: ITS5=%4d LOCOD=%4d LTSTV5=%s TSTV5=%15.7e CTSTV5=%s IRC=%2d\n",
                    its5, locod, LTSTV5[its5], TSTV5[its5], CTSTV5[its5], irc)
            end
        else
            DBSEVM(itodo, iactk, IY[ICYC], JOSTND)
        end
    end

    if iuserv == 1; return nothing; end
    return nothing
end

# FISHER_SN: real implementation in base/evmon_support.jl (overrides this stub)

# GETORGV stub: ORGANON canopy cover / average height (OC/OP variants only)
function GETORGV(i::Integer, value_ref::Ref{Float32})
    value_ref[] = Float32(0.0)
    return nothing
end

# DBSEVM: run scheduled DBS SQL commands (from dbsevm.f, 49 lines)
# IACTK=101 → SQLIN (execute on input DB); IACTK=102 → SQLOUT (execute on output DB)
function DBSEVM(itodo::Integer, iactk::Integer, idt::Integer, jostnd::Integer)
    sqlcmd = OPGETC(itodo)
    isempty(strip(sqlcmd)) && return nothing

    irc_ref  = Ref{Int32}(Int32(1))
    kode_ref = Ref{Int32}(Int32(0))

    if iactk == 101          # SQLIN
        if _dbs_in_db[] === nothing
            DBSOPEN(false, true, kode_ref)
            if kode_ref[] == Int32(1)
                io = get(io_units, Int32(jostnd), stdout)
                @printf(io, "            DBS ERROR: INPUT CONNECTION FAILED FOR DSN: %s\n", DSNIN)
                return nothing
            end
        end
        DBSEXECSQL(_dbs_in_db[], sqlcmd, true, irc_ref)
    elseif iactk == 102      # SQLOUT
        if _dbs_out_db[] === nothing
            DBSOPEN(false, true, kode_ref)
            if kode_ref[] == Int32(1)
                io = get(io_units, Int32(jostnd), stdout)
                @printf(io, "            DBS ERROR: OUTPUT CONNECTION FAILED FOR DSN: %s\n", DSNOUT)
                return nothing
            end
        end
        DBSEXECSQL(_dbs_out_db[], sqlcmd, true, irc_ref)
    end

    irc_ref[] == Int32(0) && OPDONE(Int32(itodo), Int32(idt))
    return nothing
end

# ---------------------------------------------------------------------------
# Entry-point equivalents (EVSET4, EVUST4, EVGET4)
# ---------------------------------------------------------------------------
function EVSET4(iset::Integer, value::Real)
    TSTV4[Int(iset)] = Float32(value)
    LTSTV4[Int(iset)] = true
    return nothing
end

function EVUST4(iset::Integer)
    LTSTV4[Int(iset)] = false
    return nothing
end

function EVGET4(ival::Integer, vset_ref::Ref{Float32}, lset_ref::Ref{Bool})
    vset_ref[] = TSTV4[Int(ival)]
    lset_ref[] = LTSTV4[Int(ival)]
    return nothing
end
