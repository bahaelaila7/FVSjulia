# evldx.jl — EVLDX: event monitor variable loader for Prognosis model variables
# Translated from: evldx.f (1200 lines)
#
# Called from ALGEVL to load X values for event monitor expression evaluation.
# XLDREG: output array (result in XLDREG[1])
# NXLDX:  length of XLDREG
# INSTR:  instruction code (opcode) specifying which value to load
# IRC:    return code: 0=OK, 1=undefined (IPHASE/ICYC constraint), 2=unrecognized

function EVLDX(xldreg::AbstractVector{Float32}, nxldx::Integer,
               instr::Integer, irc_ref::Ref{Int32})
    ldeb = DBCHK(false, "EVLDX", Int32(5), ICYC)
    if ldeb
        @printf(io_units[Int32(JOSTND)], "\n IN EVLDX, INSTR=%6d; NXLDX=%3d\n", instr, nxldx)
    end

    itmpdx = zeros(Int32, 1)   # local scratch index array for COVOLP

    # -----------------------------------------------------------------------
    # INSTR 1001..8999: load constant from PARMS array
    # -----------------------------------------------------------------------
    if instr > 1000 && instr < 9000
        xldreg[1] = PARMS[instr - 1000]
        if ldeb
            @printf(io_units[Int32(JOSTND)], " IN EVLDX, XLDREG(1)=PARMS(%d) = %g\n",
                    instr - 1000, PARMS[instr - 1000])
        end
        @goto label_1000
    end

    # -----------------------------------------------------------------------
    # INSTR < 1000: load from saved variable arrays (TSTV1..TSTV5) or RANN
    # -----------------------------------------------------------------------
    if instr < 1000
        i_ev = mod(instr, 100)
        j_ev = div(instr, 100)
        if ldeb
            @printf(io_units[Int32(JOSTND)], " IN EVLDX, I, J = %4d %4d\n", i_ev, j_ev)
        end

        if j_ev == 1
            xldreg[1] = TSTV1[i_ev]
            @goto label_1000
        elseif j_ev == 2
            if Int(IPHASE) < 2; @goto label_1001; end
            xldreg[1] = TSTV2[i_ev]
            @goto label_1000
        elseif j_ev == 3
            if Int(ICYC) < 2; @goto label_1001; end
            xldreg[1] = TSTV3[i_ev]
            @goto label_1000
        elseif j_ev == 4
            if !LTSTV4[i_ev]; @goto label_1001; end
            xldreg[1] = TSTV4[i_ev]
            @goto label_1000
        elseif j_ev == 5   # opcode 501..599
            if !LTSTV5[i_ev]; @goto label_1001; end
            xldreg[1] = TSTV5[i_ev]
            @goto label_1000
        elseif j_ev == 6   # opcode 600..699
            if !LTSTV5[i_ev + 100]; @goto label_1001; end
            xldreg[1] = TSTV5[i_ev + 100]
            @goto label_1000
        elseif j_ev == 7   # opcode 700..799
            if !LTSTV5[i_ev + 200]; @goto label_1001; end
            xldreg[1] = TSTV5[i_ev + 200]
            @goto label_1000
        elseif j_ev == 8   # opcode 800..899
            if !LTSTV5[i_ev + 300]; @goto label_1001; end
            xldreg[1] = TSTV5[i_ev + 300]
            @goto label_1000
        elseif j_ev == 9   # opcode 900
            if i_ev == 0
                xldreg[1] = RANN()
            else
                xldreg[1] = Float32(i_ev)
            end
            @goto label_1000
        else
            @goto label_1001   # j_ev == 0 or j_ev >= 10
        end
    end

    # if INSTR 1..10000 but not handled above, unrecognized
    if instr <= 10000; @goto label_1002; end

    # -----------------------------------------------------------------------
    # INSTR > 10000: complex stand-level statistics
    # Extract argument count (JARGS) and base opcode (MYSTR)
    # -----------------------------------------------------------------------
    jargs = mod(instr, 100)
    mystr = div(instr, 100) * 100

    # -----------------------------------------------------------------------
    # SPMCDBH (10600): stand/species/size-class statistics
    # -----------------------------------------------------------------------
    if mystr == 10600
        if jargs < 3; @goto label_1002; end
        l_ev = Int(trunc(xldreg[1] + 0.5f0))
        j_ev = xldreg[2] >= 0f0 ? Int(trunc(xldreg[2] + 0.5f0)) : Int(trunc(xldreg[2] - 0.5f0))
        k_ev = Int(trunc(xldreg[3] + 0.5f0))

        if l_ev <= 0 || l_ev > 15; @goto label_1002; end
        if j_ev > Int(MAXSP); @goto label_1002; end
        if j_ev < 0 && Int(NSPGRP) < -j_ev; @goto label_1002; end
        if k_ev < 0 || k_ev > 3; @goto label_1002; end

        xsdi   = Float32(0); dumsdi = Float32(0)
        stagea = Float32(0); stageb = Float32(0)
        clsd2  = Float32(0); clstpa = Float32(0)
        xcrd   = Float32(0); crdtfac= Float32(0); crddfac= Float32(0)

        if l_ev == 11
            _, _, stagea, stageb = SDICLS(Int32(0), Float32(0), Float32(999), Int32(1), Int32(0))
        end
        if l_ev == 14
            clsd2, clstpa, xcrd, crdtfac, crddfac = RDCLS(Int32(0), Float32(0), Float32(999), Int32(1), Int32(0))
        end

        cut_f  = Float32(0); dead_f = Float32(0); res_f  = Float32(0)
        idmi   = 0
        xldbh  = Float32(0); xhdbh  = Float32(1e30)
        xlht   = Float32(0); xhht   = Float32(1e30)
        jpnum  = 0; jptgrp = 0

        if jargs >= 4; xldbh  = xldreg[4]; end
        if jargs >= 5; xhdbh  = xldreg[5]; end
        if jargs >= 6; xlht   = xldreg[6]; end
        if jargs >= 7; xhht   = xldreg[7]; end
        if jargs >= 8
            if xldreg[8] == 1f0; dead_f = xldreg[8]
            elseif xldreg[8] == 2f0; cut_f = xldreg[8]
            elseif xldreg[8] == 3f0; res_f = xldreg[8]
            elseif xldreg[8] == 4f0; idmi  = Int(trunc(xldreg[8] + 0.5f0))
            end
        end
        if jargs >= 9
            if xldreg[9] < 0f0
                jpnum  = Int(trunc(xldreg[9] - 0.5f0))
                jptgrp = -jpnum
            else
                jpnum = Int(trunc(xldreg[9] + 0.5f0))
            end
        end

        # Resolve inventory point number to sequential point number
        xldreg[1] = Float32(0)
        if jpnum > 0
            if Int(ITHNPI) <= 0 || Int(ITHNPI) > 2
                @goto label_1000
            elseif Int(ITHNPI) == 1
                found_pt = false
                for ii in 1:Int(IPTINV)
                    if jpnum == Int(IPVEC[ii])
                        jpnum = ii
                        found_pt = true
                        break
                    end
                end
                if !found_pt; @goto label_1000; end
            elseif Int(ITHNPI) == 2
                if jpnum > Int(IPTINV); @goto label_1000; end
            end
        end
        if ldeb
            @printf(io_units[Int32(JOSTND)], " AFTER POINT PROCESSING JPNUM= %d\n", jpnum)
        end

        sump_v  = Float32(0)
        ntrees_v = 0
        local_work1 = zeros(Float32, Int(MAXTRE))

        if cut_f > 0f0 && Int(IPHASE) < 2; @goto label_1001; end
        if res_f > 0f0 && Int(IPHASE) < 2; @goto label_1001; end
        ilim_v = Int(ITRN)
        if cut_f != 0f0; ilim_v = Int(MAXTRE); end

        if ilim_v > 0
            for i in 1:ilim_v
                lincl = false
                if j_ev == 0 || j_ev == Int(ISP[i])
                    lincl = true
                elseif j_ev < 0
                    igrp = -j_ev
                    iulim = Int(ISPGRP[igrp, 1]) + 1
                    for ig in 2:iulim
                        if Int(ISP[i]) == Int(ISPGRP[igrp, ig])
                            lincl = true
                            break
                        end
                    end
                end

                # Check point group membership
                if jptgrp > 0
                    if Int(ITHNPI) <= 0 || Int(ITHNPI) > 2; @goto label_1000; end
                    in_ptgrp = false
                    for jpt in 2:(Int(IPTGRP[jptgrp, 1]) + 1)
                        if Int(ITHNPI) == 1
                            if Int(IPTGRP[jptgrp, jpt]) == Int(IPVEC[Int(ITRE[i])])
                                jpnum = Int(ITRE[i])
                                in_ptgrp = true
                                break
                            end
                        elseif Int(ITHNPI) == 2
                            if Int(IPTGRP[jptgrp, jpt]) == Int(ITRE[i])
                                jpnum = Int(ITRE[i])
                                if jpnum > Int(IPTINV); @goto label_1000; end
                                in_ptgrp = true
                                break
                            end
                        end
                    end
                    if !in_ptgrp; lincl = false; end
                end

                if jpnum > 0 && jpnum != Int(ITRE[i]); lincl = false; end

                if lincl &&
                   (k_ev == 0 || k_ev == Int(IMC[i])) &&
                   DBH[i] >= xldbh && DBH[i] < xhdbh &&
                   HT[i]  >= xlht  && HT[i]  < xhht
                    tpa_v = PROB[i]
                    if dead_f != 0f0
                        tpa_v = (Int(ICYC) <= 1) ? Float32(0) : WK2[i]
                    elseif cut_f != 0f0
                        tpa_v = WK4[i]
                    elseif idmi != 0
                        idmr_r = Ref(Int32(0))
                        MISGET(i, idmr_r)
                        if idmr_r[] == Int32(0); tpa_v = Float32(0); end
                    end
                    if jpnum > 0
                        tpa_v = tpa_v * (Float32(PI) - Float32(NONSTK))
                    end
                    sump_v += tpa_v

                    if l_ev == 1
                        xldreg[1] += tpa_v
                    elseif l_ev == 2
                        xldreg[1] += tpa_v * DBH[i] * DBH[i] * 0.005454154f0
                    elseif l_ev == 3
                        xldreg[1] += tpa_v * (dead_f != 0f0 ? PTOCFV[i] : CFV[i])
                    elseif l_ev == 4
                        xldreg[1] += tpa_v * (dead_f != 0f0 ? PMRBFV[i] : BFV[i])
                    elseif l_ev == 5
                        xldreg[1] += tpa_v * DBH[i] * DBH[i]
                    elseif l_ev == 6
                        xldreg[1] += tpa_v * HT[i]
                    elseif l_ev == 7
                        ntrees_v += 1
                        local_work1[ntrees_v] = CRWDTH[i] * CRWDTH[i] * tpa_v * 0.785398f0
                    elseif l_ev == 8
                        idmr_r8 = Ref(Int32(0))
                        MISGET(i, idmr_r8)
                        xldreg[1] += Float32(idmr_r8[]) * tpa_v
                    elseif l_ev == 9
                        xldreg[1] += tpa_v * (dead_f != 0f0 ? PMRCFV[i] : MCFV[i])
                    elseif l_ev == 10
                        xldreg[1] += tpa_v * DG[i]
                    elseif l_ev == 11
                        if DBH[i] >= Float32(DBHSTAGE)
                            xldreg[1] += (stagea + stageb * DBH[i]^2f0) * tpa_v
                        end
                    elseif l_ev == 12
                        treerd_v = RDSLTR(Int(ISP[i]), i)
                        xldreg[1] += tpa_v * treerd_v / GROSPC
                    elseif l_ev == 13
                        if DBH[i] >= Float32(DBHZEIDE)
                            xldreg[1] += ((DBH[i] / 10f0)^1.605f0) * tpa_v
                        end
                    elseif l_ev == 14
                        if DBH[i] >= Float32(DBHSTAGE)
                            xldreg[1] += (crdtfac + crddfac * DBH[i]^2f0) * tpa_v
                        end
                    elseif l_ev == 15  # cubic sawlog volume
                        xldreg[1] += tpa_v * (dead_f != 0f0 ? PSCFV[i] : SCFV[i])
                    end
                end
            end # i loop

            # Normalize point group stats by number of points in group
            if (1 <= l_ev <= 4 || l_ev == 9 || (11 <= l_ev <= 14))
                if jptgrp > 0 && Int(IPTGRP[jptgrp, 1]) > 0
                    xldreg[1] /= Float32(IPTGRP[jptgrp, 1])
                end
            end

            if l_ev == 5 || l_ev == 6 || l_ev == 8 || l_ev == 10
                if sump_v > 0.0001f0
                    if l_ev == 5
                        xldreg[1] = sqrt(xldreg[1] / sump_v)
                    else
                        xldreg[1] /= sump_v
                    end
                else
                    xldreg[1] = Float32(0)
                end
            elseif l_ev == 7
                cover_r = Ref(Float32(0))
                COVOLP(ldeb, Int(JOSTND), ntrees_v, itmpdx, local_work1, cover_r, CCCOEF)
                xldreg[1] = cover_r[]
            elseif (1 <= l_ev <= 4 || l_ev == 9)
                xldreg[1] /= GROSPC
            end
        end
        @goto label_1000
    end

    # -----------------------------------------------------------------------
    # ACCFSP (11200) / BCCFSP (11300): calibration statistics by species
    # -----------------------------------------------------------------------
    if mystr == 11200 || mystr == 11300
        if jargs != 1; @goto label_1002; end
        i_ev = xldreg[1] >= 0f0 ? Int(trunc(xldreg[1] + 0.5f0)) : Int(trunc(xldreg[1] - 0.5f0))
        if i_ev > Int(MAXSP); @goto label_1002; end
        if i_ev < 0 && Int(NSPGRP) < -i_ev; @goto label_1002; end
        if mystr == 11300 && Int(IPHASE) < 2; @goto label_1001; end
        temsum = Float32(0)
        if i_ev < 0
            igrp = -i_ev
            iulim = Int(ISPGRP[igrp, 1]) + 1
            for ig in 2:iulim
                igsp = Int(ISPGRP[igrp, ig])
                temsum += mystr == 11200 ? BCCFSP[igsp] : ACCFSP[igsp]
            end
            xldreg[1] = temsum
        elseif i_ev == 0
            for ispc in 1:Int(MAXSP)
                temsum += mystr == 11200 ? BCCFSP[ispc] : ACCFSP[ispc]
            end
            xldreg[1] = temsum
        else
            xldreg[1] = mystr == 11200 ? BCCFSP[i_ev] : ACCFSP[i_ev]
        end
        @goto label_1000
    end

    # -----------------------------------------------------------------------
    # DBHDIST (10500): diameter distribution statistics
    # -----------------------------------------------------------------------
    if mystr == 10500
        if jargs < 2; @goto label_1002; end
        i_ev = Int(trunc(xldreg[1] + 0.5f0))
        j_ev = Int(trunc(xldreg[2] + 0.5f0))
        if i_ev <= 0 || i_ev > 13; @goto label_1002; end
        if i_ev >= 7 && Int(IPHASE) == 1; @goto label_1001; end
        if j_ev <= 0 || j_ev > 7; @goto label_1002; end
        if i_ev == 1; xldreg[1] = OACC[j_ev]
        elseif i_ev == 2; xldreg[1] = OMORT[j_ev]
        elseif i_ev == 3; xldreg[1] = ONTCUR[j_ev]
        elseif i_ev == 4; xldreg[1] = OCVCUR[j_ev]
        elseif i_ev == 5; xldreg[1] = OMCCUR[j_ev]
        elseif i_ev == 6; xldreg[1] = OBFCUR[j_ev]
        elseif i_ev == 7; xldreg[1] = ONTREM[j_ev]
        elseif i_ev == 8; xldreg[1] = OCVREM[j_ev]
        elseif i_ev == 9; xldreg[1] = OMCREM[j_ev]
        elseif i_ev == 10; xldreg[1] = OBFREM[j_ev]
        elseif i_ev == 11; xldreg[1] = ONTRES[j_ev]
        elseif i_ev == 12; xldreg[1] = OSCCUR[j_ev]
        elseif i_ev == 13; xldreg[1] = OSCREM[j_ev]
        end
        @goto label_1000
    end

    # -----------------------------------------------------------------------
    # SUMSTAT (10400): summary table statistics by cycle
    # -----------------------------------------------------------------------
    if mystr == 10400
        if ldeb
            for jj in 1:22
                @printf(io_units[Int32(JOSTND)], " IN EVLDX: CURRENT IOSUM(%d,%d) = %d\n",
                        jj, 1, IOSUM[jj, 1])
            end
        end
        if jargs < 2; @goto label_1002; end
        i_ev = Int(trunc(xldreg[1] + 0.5f0))
        j_ev = Int(trunc(xldreg[2] + 0.5f0))
        if i_ev <= 0 || i_ev > Int(MAXCY1); @goto label_1001; end
        if j_ev <= 0 || j_ev > 22; @goto label_1002; end
        if i_ev > Int(ICYC) + 1; @goto label_1001; end
        xldreg[1] = Float32(IOSUM[j_ev, i_ev])
        @goto label_1000
    end

    # -----------------------------------------------------------------------
    # FUELLOAD (11700): fire model fuel load
    # -----------------------------------------------------------------------
    if mystr == 11700
        lactv_r = Ref(false)
        FMATV(lactv_r)
        if !lactv_r[]; @goto label_1002; end
        if jargs < 1 || jargs > 2; @goto label_1002; end
        ilo_v = Int(trunc(xldreg[1] + 0.5f0))
        ihi_v = (jargs == 1) ? ilo_v : Int(trunc(xldreg[2] + 0.5f0))
        if ihi_v < ilo_v; @goto label_1002; end
        if ilo_v < 1 || ihi_v > 11; @goto label_1002; end
        rval_r = Ref(Float32(0)); irc_r2 = Ref(Int32(0))
        FMEVCWD(rval_r, ilo_v, ihi_v, irc_r2)
        if irc_r2[] == Int32(1); @goto label_1001; end
        xldreg[1] = rval_r[]
        @goto label_1000
    end

    # -----------------------------------------------------------------------
    # SNAGS (11800)
    # -----------------------------------------------------------------------
    if mystr == 11800
        lactv_r = Ref(false)
        FMATV(lactv_r)
        if !lactv_r[]; @goto label_1002; end
        if jargs < 3; @goto label_1002; end
        l_ev = Int(trunc(xldreg[1] + 0.5f0))
        j_ev = xldreg[2] >= 0f0 ? Int(trunc(xldreg[2] + 0.5f0)) : Int(trunc(xldreg[2] - 0.5f0))
        k_ev = Int(trunc(xldreg[3] + 0.5f0))
        if l_ev < 1 || l_ev > 3; @goto label_1002; end
        if j_ev > Int(MAXSP); @goto label_1002; end
        if j_ev < 0 && Int(NSPGRP) < -j_ev; @goto label_1002; end
        if k_ev < 0 || k_ev > 2; @goto label_1002; end
        xldbh = Float32(0); xhdbh = Float32(1e30)
        xlht  = Float32(0); xhht  = Float32(1e30)
        m_ev  = 0
        if jargs >= 4; xldbh = xldreg[4]; end
        if jargs >= 5; xhdbh = xldreg[5]; end
        if jargs >= 6; xlht  = xldreg[6]; end
        if jargs >= 7; xhht  = xldreg[7]; end
        if jargs >= 8; m_ev  = Int(xldreg[8]); end
        if m_ev == 1 && Int(IPHASE) < 2; @goto label_1001; end
        rval_r = Ref(Float32(0)); irc_r2 = Ref(Int32(0))
        FMEVSNG(rval_r, l_ev, j_ev, k_ev, xldbh, xhdbh, xlht, xhht, irc_r2)
        if irc_r2[] == Int32(1); @goto label_1001; end
        xldreg[1] = rval_r[]
        @goto label_1000
    end

    # -----------------------------------------------------------------------
    # POTFLEN (11900)
    # -----------------------------------------------------------------------
    if mystr == 11900
        lactv_r = Ref(false)
        FMATV(lactv_r)
        if !lactv_r[]; @goto label_1002; end
        if jargs < 1 || jargs > 2; @goto label_1002; end
        j_ev = Int(trunc(xldreg[1] + 0.5f0))
        if j_ev < 1 || j_ev > 4; @goto label_1002; end
        rval_r = Ref(Float32(0)); irc_r2 = Ref(Int32(0))
        FMEVFLM(rval_r, j_ev, irc_r2)
        if irc_r2[] == Int32(1); @goto label_1001; end
        xldreg[1] = rval_r[]
        @goto label_1000
    end

    # -----------------------------------------------------------------------
    # POTFMORT (12100)
    # -----------------------------------------------------------------------
    if mystr == 12100
        lactv_r = Ref(false)
        FMATV(lactv_r)
        if !lactv_r[]; @goto label_1002; end
        if jargs < 1 || jargs > 1; @goto label_1002; end
        j_ev = Int(trunc(xldreg[1] + 0.5f0))
        if j_ev < 1 || j_ev > 4; @goto label_1002; end
        rval_r = Ref(Float32(0)); irc_r2 = Ref(Int32(0))
        FMEVMRT(rval_r, j_ev, irc_r2)
        if irc_r2[] == Int32(1); @goto label_1001; end
        xldreg[1] = rval_r[]
        @goto label_1000
    end

    # -----------------------------------------------------------------------
    # FUELMODS (12200)
    # -----------------------------------------------------------------------
    if mystr == 12200
        lactv_r = Ref(false)
        FMATV(lactv_r)
        if !lactv_r[]; @goto label_1002; end
        if jargs < 1 || jargs > 2; @goto label_1002; end
        l_ev = Int(trunc(xldreg[1] + 0.5f0))
        j_ev = Int(trunc(xldreg[2] + 0.5f0))
        if l_ev < 1 || l_ev > 4; @goto label_1002; end
        if j_ev < 1 || j_ev > 2; @goto label_1002; end
        rval_r = Ref(Float32(0)); irc_r2 = Ref(Int32(0))
        FMEVFMD(rval_r, l_ev, j_ev, irc_r2)
        if irc_r2[] == Int32(1); @goto label_1001; end
        xldreg[1] = rval_r[]
        @goto label_1000
    end

    # -----------------------------------------------------------------------
    # SALVVOL (12300)
    # -----------------------------------------------------------------------
    if mystr == 12300
        lactv_r = Ref(false)
        FMATV(lactv_r)
        if !lactv_r[]; @goto label_1002; end
        if jargs < 3; @goto label_1002; end
        j_ev = xldreg[1] >= 0f0 ? Int(trunc(xldreg[1] + 0.5f0)) : Int(trunc(xldreg[1] - 0.5f0))
        if j_ev > Int(MAXSP); @goto label_1002; end
        if j_ev < 0 && Int(NSPGRP) < -j_ev; @goto label_1002; end
        xldbh = xldreg[2]; xhdbh = xldreg[3]
        rval_r = Ref(Float32(0)); irc_r2 = Ref(Int32(0))
        FMEVSAL(rval_r, j_ev, xldbh, xhdbh, irc_r2)
        if irc_r2[] == Int32(1) || Int(IPHASE) < 2; @goto label_1001; end
        xldreg[1] = rval_r[]
        @goto label_1000
    end

    # -----------------------------------------------------------------------
    # POINTID (12400)
    # -----------------------------------------------------------------------
    if mystr == 12400
        if jargs != 1; @goto label_1002; end
        i_ev = Int(trunc(xldreg[1] + 0.5f0))
        if i_ev <= 0 || i_ev > Int(IPTINV); @goto label_1001; end
        xldreg[1] = Float32(IPVEC[i_ev])
        @goto label_1000
    end

    # -----------------------------------------------------------------------
    # STRSTAT (12500): structural stage statistics
    # -----------------------------------------------------------------------
    if mystr == 12500
        if !LCALC; @goto label_1002; end
        if jargs < 1 || jargs > 2; @goto label_1002; end
        j_ev = 0
        l_ev = Int(trunc(xldreg[1] + 0.5f0))
        if jargs == 2; j_ev = Int(trunc(xldreg[2] + 0.5f0)); end
        if l_ev < 1 || l_ev > 33; @goto label_1002; end
        if j_ev < 0 || j_ev > 1; @goto label_1002; end
        if j_ev == 1 && Int(IPHASE) < 2; @goto label_1001; end
        xldreg[1] = OSTRST[l_ev, j_ev + 1]
        @goto label_1000
    end

    # -----------------------------------------------------------------------
    # POTFTYPE (12600)
    # -----------------------------------------------------------------------
    if mystr == 12600
        lactv_r = Ref(false)
        FMATV(lactv_r)
        if !lactv_r[]; @goto label_1002; end
        if jargs < 1 || jargs > 1; @goto label_1002; end
        j_ev = Int(trunc(xldreg[1] + 0.5f0))
        if j_ev < 1 || j_ev > 2; @goto label_1002; end
        rval_r = Ref(Float32(0)); irc_r2 = Ref(Int32(0))
        FMEVTYP(rval_r, j_ev, irc_r2)
        if irc_r2[] == Int32(1); @goto label_1001; end
        xldreg[1] = rval_r[]
        @goto label_1000
    end

    # -----------------------------------------------------------------------
    # POTSRATE (12700)
    # -----------------------------------------------------------------------
    if mystr == 12700
        lactv_r = Ref(false)
        FMATV(lactv_r)
        if !lactv_r[]; @goto label_1002; end
        if jargs < 1 || jargs > 1; @goto label_1002; end
        j_ev = Int(trunc(xldreg[1] + 0.5f0))
        if j_ev < 1 || j_ev > 4; @goto label_1002; end
        rval_r = Ref(Float32(0)); irc_r2 = Ref(Int32(0))
        FMEVSRT(rval_r, j_ev, irc_r2)
        if irc_r2[] == Int32(1); @goto label_1001; end
        xldreg[1] = rval_r[]
        @goto label_1000
    end

    # -----------------------------------------------------------------------
    # POTREINT (12800)
    # -----------------------------------------------------------------------
    if mystr == 12800
        lactv_r = Ref(false)
        FMATV(lactv_r)
        if !lactv_r[]; @goto label_1002; end
        if jargs < 1 || jargs > 1; @goto label_1002; end
        j_ev = Int(trunc(xldreg[1] + 0.5f0))
        if j_ev < 1 || j_ev > 2; @goto label_1002; end
        rval_r = Ref(Float32(0)); irc_r2 = Ref(Int32(0))
        FMEVRIN(rval_r, j_ev, irc_r2)
        if irc_r2[] == Int32(1); @goto label_1001; end
        xldreg[1] = rval_r[]
        @goto label_1000
    end

    # -----------------------------------------------------------------------
    # TREEBIO (12900)
    # -----------------------------------------------------------------------
    if mystr == 12900
        lactv_r = Ref(false)
        FMATV(lactv_r)
        if !lactv_r[]; @goto label_1002; end
        if jargs < 3; @goto label_1002; end
        i1_ev = xldreg[1] >= 0f0 ? Int(trunc(xldreg[1] + 0.5f0)) :
                xldreg[1] == 0f0  ? 0 : Int(trunc(xldreg[1] - 0.5f0))
        i2_ev = xldreg[2] >= 0f0 ? Int(trunc(xldreg[2] + 0.5f0)) :
                xldreg[2] == 0f0  ? 0 : Int(trunc(xldreg[2] - 0.5f0))
        i3_ev = xldreg[3] >= 0f0 ? Int(trunc(xldreg[3] + 0.5f0)) :
                xldreg[3] == 0f0  ? 0 : Int(trunc(xldreg[3] - 0.5f0))
        i4_ev = xldreg[4] >= 0f0 ? Int(trunc(xldreg[4] + 0.5f0)) : Int(trunc(xldreg[4] - 0.5f0))
        if i4_ev > Int(MAXSP); @goto label_1002; end
        if i4_ev < 0 && Int(NSPGRP) < -i4_ev; @goto label_1002; end
        xldbh = Float32(0); xhdbh = Float32(1e30)
        xlht  = Float32(0); xhht  = Float32(1e30)
        if jargs >= 5; xldbh = xldreg[5]; end
        if jargs >= 6; xhdbh = xldreg[6]; end
        if jargs >= 7; xlht  = xldreg[7]; end
        if jargs >= 8; xhht  = xldreg[8]; end
        rval_r = Ref(Float32(0)); irc_r2 = Ref(Int32(0))
        FMEVTBM(rval_r, i1_ev, i2_ev, i3_ev, i4_ev, xldbh, xhdbh, xlht, xhht, irc_r2)
        if irc_r2[] == Int32(1); @goto label_1001; end
        xldreg[1] = rval_r[]
        @goto label_1000
    end

    # -----------------------------------------------------------------------
    # CARBSTAT (13000)
    # -----------------------------------------------------------------------
    if mystr == 13000
        lactv_r = Ref(false)
        FMATV(lactv_r)
        if !lactv_r[]; @goto label_1002; end
        if jargs < 1 || jargs > 1; @goto label_1002; end
        j_ev = Int(trunc(xldreg[1] + 0.5f0))
        if j_ev < 1 || j_ev > 17; @goto label_1002; end
        rval_r = Ref(Float32(0)); irc_r2 = Ref(Int32(0))
        FMEVCARB(rval_r, j_ev, irc_r2)
        if irc_r2[] == Int32(1); @goto label_1001; end
        xldreg[1] = rval_r[]
        @goto label_1000
    end

    # -----------------------------------------------------------------------
    # HTDIST (13100): height percentile
    # -----------------------------------------------------------------------
    if mystr == 13100
        if jargs < 1 || jargs > 1; @goto label_1002; end
        j_ev = Int(trunc(xldreg[1] + 0.5f0))
        if j_ev < 1 || j_ev > 100; @goto label_1002; end
        htpct = Float32(1) - Float32(j_ev) / Float32(100)
        ht_index = collect(Int32(i) for i in 1:Int(MAXTRE))
        for i in (Int(ITRN)+1):Int(MAXTRE); ht_index[i] = Int32(0); end
        RDPSRT(Int(ITRN), HT, ht_index, false)
        sumpin = Float32(0)
        xldreg[1] = Float32(0)
        for i in 1:Int(ITRN)
            isrti = Int(ht_index[i])
            p_v = PROB[isrti]
            if HT[isrti] >= xldreg[1]; sumpin += p_v; end
            if sumpin > TPROB * htpct && xldreg[1] == 0f0
                xldreg[1] = HT[isrti]
            end
        end
        @goto label_1000
    end

    # -----------------------------------------------------------------------
    # HERBSHRB (13200)
    # -----------------------------------------------------------------------
    if mystr == 13200
        lactv_r = Ref(false)
        FMATV(lactv_r)
        if !lactv_r[]; @goto label_1002; end
        if jargs != 1; @goto label_1002; end
        ilo_v = Int(trunc(xldreg[1] + 0.5f0))
        if ilo_v < 1 || ilo_v > 3; @goto label_1002; end
        rval_r = Ref(Float32(0)); irc_r2 = Ref(Int32(0))
        FMEVLSF(rval_r, ilo_v, irc_r2)
        if irc_r2[] == Int32(1); @goto label_1001; end
        xldreg[1] = rval_r[]
        @goto label_1000
    end

    # -----------------------------------------------------------------------
    # DWDVAL (13300): down woody debris
    # -----------------------------------------------------------------------
    if mystr == 13300
        lactv_r = Ref(false)
        FMATV(lactv_r)
        if !lactv_r[]; @goto label_1002; end
        if jargs != 4; @goto label_1002; end
        l_ev = Int(trunc(xldreg[1] + 0.5f0))
        j_ev = Int(trunc(xldreg[2] + 0.5f0))
        k_ev = Int(trunc(xldreg[3] + 0.5f0))
        m_ev = Int(trunc(xldreg[4] + 0.5f0))
        if l_ev < 1 || l_ev > 2; @goto label_1002; end
        if j_ev < 0 || j_ev > 2; @goto label_1002; end
        if k_ev < 1 || k_ev > 7; @goto label_1002; end
        if m_ev < 1 || m_ev > 7; @goto label_1002; end
        if k_ev > m_ev; @goto label_1002; end
        rval_r = Ref(Float32(0)); irc_r2 = Ref(Int32(0))
        FMDWD(rval_r, l_ev, j_ev, k_ev, m_ev, irc_r2)
        if irc_r2[] == Int32(1); @goto label_1001; end
        xldreg[1] = rval_r[]
        @goto label_1000
    end

    # -----------------------------------------------------------------------
    # ACORNS (13400): acorn production
    # -----------------------------------------------------------------------
    if mystr == 13400
        if jargs != 2; @goto label_1002; end
        l_ev = Int(trunc(xldreg[1] + 0.5f0))
        j_ev = xldreg[2] >= 0f0 ? Int(trunc(xldreg[2] + 0.5f0)) : Int(trunc(xldreg[2] - 0.5f0))
        if l_ev <= 0 || l_ev > 2; @goto label_1002; end
        if j_ev > Int(MAXSP); @goto label_1002; end
        if j_ev < 0 && Int(NSPGRP) < -j_ev; @goto label_1002; end
        xldreg[1] = Float32(0)
        for i in 1:Int(ITRN)
            fcode = FIAJSP[Int(ISP[i])]
            if fcode == "802" || fcode == "806" || fcode == "832" || fcode == "833" || fcode == "837"
                lincl = false
                if j_ev == 0 || j_ev == Int(ISP[i])
                    lincl = true
                elseif j_ev < 0
                    igrp = -j_ev
                    iulim = Int(ISPGRP[igrp, 1]) + 1
                    for ig in 2:iulim
                        if Int(ISP[i]) == Int(ISPGRP[igrp, ig])
                            lincl = true
                            break
                        end
                    end
                end
                if lincl && DBH[i] >= 5.0f0
                    dcm  = DBH[i] * 2.54f0
                    tpa3 = PROB[i]
                    adiv = Float32(1)
                    if l_ev == 2
                        if fcode == "802"; adiv = Float32(140)
                        elseif fcode == "806"; adiv = Float32(180)
                        elseif fcode == "832"; adiv = Float32(115)
                        elseif fcode == "833"; adiv = Float32(100)
                        elseif fcode == "837"; adiv = Float32(160)
                        end
                    end
                    acrn = Float32(0)
                    if fcode == "802"
                        badj = 0.6f0^2f0 * (1f0 - 0.6f0^2f0) / 2f0
                        acrn = (tpa3 * (10f0^(0.71155f0 + 0.06346f0*dcm - 0.00034290f0*dcm*dcm + badj) - 1f0)) / adiv
                    elseif fcode == "806"
                        badj = 0.5f0^2f0 * (1f0 - 0.5f0^2f0) / 2f0
                        acrn = (tpa3 * (10f0^(1.16744f0 + 0.05158f0*dcm - 0.00026797f0*dcm*dcm + badj) - 1f0)) / adiv
                    elseif fcode == "832"
                        badj = 0.6f0^2f0 * (1f0 - 0.6f0^2f0) / 2f0
                        acrn = (tpa3 * (10f0^(0.20984f0 + 0.06029f0*dcm - 0.00039431f0*dcm*dcm + badj) - 1f0)) / adiv
                    elseif fcode == "833"
                        badj = 0.6f0^2f0 * (1f0 - 0.6f0^2f0) / 2f0
                        acrn = (tpa3 * (10f0^(-0.14836f0 + 0.07539f0*dcm - 0.00039950f0*dcm*dcm + badj) - 1f0)) / adiv
                    elseif fcode == "837"
                        badj = 0.4f0^2f0 * (1f0 - 0.4f0^2f0) / 2f0
                        acrn = (tpa3 * (10f0^(1.06367f0 + 0.03123f0*dcm + badj) - 1f0)) / adiv
                    end
                    xldreg[1] += acrn
                end
            end
        end
        @goto label_1000
    end

    # -----------------------------------------------------------------------
    # CLSPVIAB (13500): climate species viability
    # -----------------------------------------------------------------------
    if mystr == 13500
        lactv_r = Ref(false)
        CLACTV(lactv_r)
        if !lactv_r[]; @goto label_1002; end
        if jargs != 1; @goto label_1002; end
        rval_r = Ref(xldreg[1]); irc_r2 = Ref(Int32(0))
        CLSPVIAB(Int(trunc(xldreg[1])), rval_r, irc_r2)
        if irc_r2[] != Int32(0); @goto label_1002; end
        xldreg[1] = rval_r[]
        @goto label_1000
    end

    # Unrecognized instruction
    @goto label_1002

    @label label_1000
    irc_ref[] = Int32(0)
    if ldeb
        @printf(io_units[Int32(JOSTND)], " IN EVLDX: IRC= %2d XLDREG=%14.5E\n", 0, xldreg[1])
    end
    return nothing

    @label label_1001
    irc_ref[] = Int32(1)
    if ldeb
        @printf(io_units[Int32(JOSTND)], " IN EVLDX: IRC= %2d XLDREG=%14.5E\n", 1, xldreg[1])
    end
    return nothing

    @label label_1002
    irc_ref[] = Int32(2)
    if ldeb
        @printf(io_units[Int32(JOSTND)], " IN EVLDX: IRC= %2d XLDREG=%14.5E\n", 2, xldreg[1])
    end
    return nothing
end
