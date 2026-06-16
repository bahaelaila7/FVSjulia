# fmfout.f — Fire output: burn conditions, fuel consumption, tree mortality reports
# FMFOUT: writes the three optional fire report files + DBS database calls
# Called from: FMBURN

function FMFOUT(iyr::Integer, flame::Real, fmd::Integer, ifire::Integer, cftmp::AbstractString)
    debug = DBCHK("FMFOUT", 6, ICYC)
    if debug
        @printf(io_units[JOSTND],
            " ENTERING FMFOUT CYCLE=%3d IYR=%4d FLAME=%14.4f FMD=%2d IFIRE=%4d CFTMP=%s\n",
            ICYC, iyr, flame, fmd, ifire, cftmp)
    end

    local jrout_ref = Ref(Int32(0))
    GETLUN(jrout_ref)
    local jrout::Int32 = jrout_ref[]
    local jout = get(io_units, jrout, stdout)

    # -------- BURN CONDITIONS REPORT --------
    if iyr >= IFMBRB && iyr <= IFMBRE && ifire >= 0
        if ifire != 0
            local dbskodeb::Int32 = Int32(1)
            DBSFMBURN(Int32(iyr), NPLT,
                MOIS[1,1]*100.0f0, MOIS[1,2]*100.0f0, MOIS[1,3]*100.0f0,
                MOIS[1,4]*100.0f0, MOIS[1,5]*100.0f0,
                MOIS[2,1]*100.0f0, MOIS[2,2]*100.0f0,
                FWIND, Int32(floor(FMSLOP*100.0f0)), Float32(flame), SCH, cftmp,
                FMOD, FWT, Ref(dbskodeb))
            if dbskodeb == 0; @goto label_105; end
        end

        global IBRPAS = IBRPAS + Int32(1)
        if IBRPAS == 1
            @printf(jout, "\n%5d\n%5d\n", IDBRN, IDBRN)
            @printf(jout, "%5d %s\n", IDBRN, "-"^113)
            @printf(jout, "%5d%37s\n", IDBRN, "******  FIRE MODEL VERSION 1.0 ******")
            @printf(jout, "%5d%26s\n", IDBRN,
                "BURN CONDITIONS REPORT -- CONDITIONS AT THE TIME OF THE FIRE")
            @printf(jout, "%5d STAND ID: %-26s    MGMT ID: %-4s\n", IDBRN, NPLT, MGMID)
            @printf(jout, "%5d %s\n", IDBRN, "-"^113)
            @printf(jout, "%5d%43sMIDFLAME       FLAME  SCORCH%21sFUEL MODELS\n", IDBRN, "", "")
            @printf(jout, "%5d%7s------- %% MOISTURE ------------- WIND  SLOPE  LENGTH HEIGHT%12s%s\n",
                    IDBRN, "", "", "-"^31)
            @printf(jout, "%5d %s\n", IDBRN,
                "YEAR  1HR 10HR 100HR  3+ DUFF LIVE W LIVE H (MPH)  (%)    (FT)  (FT)  FIRE TYPE   " *
                "MOD %WT MOD %WT MOD %WT MOD %WT ")
        end

        if ifire != 0
            if fmd == 0
                @printf(jout, "%5d%5d%5.0f%5.0f%5.0f%5.0f%5.0f%6.0f %6.0f%6d%7.1f%7.1f  %-10s%4d%4d\n",
                    IDBRN, iyr,
                    MOIS[1,1]*100.0f0, MOIS[1,2]*100.0f0, MOIS[1,3]*100.0f0,
                    MOIS[1,4]*100.0f0, MOIS[1,5]*100.0f0,
                    MOIS[2,1]*100.0f0, MOIS[2,2]*100.0f0,
                    round(Int, FWIND), Int32(floor(FMSLOP*100.0f0)),
                    flame, SCH, cftmp, 0, 100)
            else
                local fmod_strs = join([@sprintf("%4d%4d", Int(FMOD[k]), Int(round(FWT[k]*100.0f0+0.5f0)))
                                        for k in 1:Int(NFMODS)], "")
                @printf(jout, "%5d%5d%5.0f%5.0f%5.0f%5.0f%5.0f%6.0f %6.0f%6d%6.1f%7.1f  %-10s%s\n",
                    IDBRN, iyr,
                    MOIS[1,1]*100.0f0, MOIS[1,2]*100.0f0, MOIS[1,3]*100.0f0,
                    MOIS[1,4]*100.0f0, MOIS[1,5]*100.0f0,
                    MOIS[2,1]*100.0f0, MOIS[2,2]*100.0f0,
                    round(Int, FWIND), Int32(floor(FMSLOP*100.0f0)),
                    flame, SCH, cftmp, fmod_strs)
            end
        end
    end
    @label label_105

    # -------- FUEL CONSUMPTION REPORT --------
    if iyr >= IFMFLB && iyr <= IFMFLE && ifire >= 0
        local suml3::Float32 = 0.0f0; local sumg3::Float32 = 0.0f0
        local blive::Float32 = 0.0f0; local totg3::Float32 = 0.0f0
        local pduff::Float32 = 0.0f0; local pgr3::Float32 = 0.0f0

        # Reset total columns in CWD
        for i in 1:2; for j in 1:Int(MXFLCL)
            CWD[3, j, i, 5] = 0.0f0
        end; end

        for i in 1:2; for j in 1:Int(MXFLCL); for k in 1:2; for l in 1:4
            CWD[3, j, k, 5] += CWD[i, j, k, l]
        end; end; end; end

        for ii in 1:3
            local ij = ii + 3; local ik = ii + 6
            suml3 += BURNED[3, ii]
            sumg3 += BURNED[3, ij] + BURNED[3, ik]
            totg3 += CWD[3, ij, 1, 5] + CWD[3, ij, 2, 5] + CWD[3, ik, 1, 5] + CWD[3, ik, 2, 5]
        end
        local burng12::Float32 = BURNED[3,6] + BURNED[3,7] + BURNED[3,8] + BURNED[3,9]
        local denom_d::Float32 = BURNED[3,11] + CWD[3,11,1,5] + CWD[3,11,2,5]
        if denom_d > 0.0f0
            pduff = 100.0f0 * BURNED[3,11] / denom_d
        end
        if sumg3 + totg3 > 0.0f0; pgr3 = 100.0f0 * sumg3 / (sumg3 + totg3); end
        SMOKE[1] *= P2T; SMOKE[2] *= P2T
        blive = BURNLV[1] + BURNLV[2]
        local bdtot::Float32 = suml3 + sumg3 + BURNED[3,11] + BURNED[3,10] + blive + BURNCR
        local icrb::Int32 = Int32(round(CRBURN * 100.0f0 + 0.5f0))
        if ifire == 0; icrb = Int32(0); end
        if icrb < 0;   icrb = Int32(-1); end

        local dbskodef::Int32 = Int32(1)
        DBSFMFUEL(Int32(iyr), NPLT, EXPOSR, BURNED[3,10], BURNED[3,11],
            suml3, sumg3, BURNED[3,4], BURNED[3,5], burng12, blive, BURNCR,
            bdtot, pduff, pgr3, icrb, SMOKE[1], SMOKE[2], Ref(dbskodef))
        if dbskodef == 0; @goto label_252; end

        global IFLPAS = IFLPAS + Int32(1)
        if IFLPAS == 1
            @printf(jout, "\n%5d\n%5d\n", IDFUL, IDFUL)
            @printf(jout, "%5d %s\n", IDFUL, "-"^104)
            @printf(jout, "%5d%30s\n", IDFUL, "******  FIRE MODEL VERSION 1.0 ******")
            @printf(jout, "%5d%28s\n", IDFUL, "FUEL CONSUMPTION & PHYSICAL EFFECTS REPORT (BASED ON STOCKABLE AREA)")
            @printf(jout, "%5d STAND ID: %-26s    MGMT ID: %-4s\n", IDFUL, NPLT, MGMID)
            @printf(jout, "%5d %s\n", IDFUL, "-"^104)
            @printf(jout, "%5d%6s PERCENT%11sFUEL CONSUMED (TONS/ACRE)%12s%9s%6s%%  SMOKE\n",
                    IDFUL, "", "", "", "", "")
            @printf(jout, "%5d%6s MINERAL%s\n", IDFUL, "", "-"^61 * "         TREES")
            @printf(jout, "%5d%7s SOIL%45s HERB&%7s TOTAL  %%CONSUME WITH   (TONS/ACRE)\n",
                    IDFUL, "", "", "")
            @printf(jout, "%5d YEAR EXPOSR  LITR  DUFF   0-3\"    3\"+  3-6\" 6-12\"  12\"+ SHRUB CRWNS CONS.  DUFF 3\"+  CRWNG   <2.5   < 10\n",
                    IDFUL)
        end

        @printf(jout, "%5d %4d %4d   %5.1f %5.1f %6.1f %6.1f %5.1f %5.1f %5.1f %5.1f %6.1f  %3d %3d  %4d  %6.2f %6.2f\n",
            IDFUL, iyr, Int(EXPOSR),
            BURNED[3,10], BURNED[3,11], suml3, sumg3,
            BURNED[3,4], BURNED[3,5], burng12, blive, BURNCR,
            bdtot, Int(pduff), Int(pgr3), Int(icrb),
            SMOKE[1], SMOKE[2])
    end
    @label label_252

    # -------- MORTALITY REPORT --------
    if iyr >= IFMMRB && iyr <= IFMMRE && ifire >= 0
        local maxcl::Int32 = Int32(7)
        local maxcl1::Int32 = Int32(8)
        local mxsp1::Int32 = MAXSP + Int32(1)

        local clskil = zeros(Float32, Int(mxsp1), Int(maxcl1))
        local totcls = zeros(Float32, Int(mxsp1), Int(maxcl1))
        local totbak  = zeros(Float32, Int(mxsp1))
        local totvolk = zeros(Float32, Int(mxsp1))

        for i in 1:Int(ITRN)
            local ksp::Int32 = ISP[i]
            if ksp > 0
                totbak[ksp] += CURKIL[i] * DBH[i] * DBH[i] * 0.005454154f0
                if VARACD == "CS" || VARACD == "LS" || VARACD == "NE" || VARACD == "SN"
                    totvolk[ksp] += CURKIL[i] * MCFV[i]
                else
                    totvolk[ksp] += CURKIL[i] * CFV[i]
                end
                local icls::Int32 = Int32(0)
                for ic in 1:7
                    if DBH[i] < LOWDBH[ic]
                        icls = Int32(ic - 1)
                        break
                    end
                    if ic == 7; icls = Int32(7); end
                end
                if icls == 0; continue; end
                clskil[ksp, icls]     += CURKIL[i]
                clskil[ksp, maxcl1]   += CURKIL[i]
                clskil[mxsp1, icls]   += CURKIL[i]
                totcls[ksp, icls]     += CURKIL[i] + FMPROB[i]
                totcls[ksp, maxcl1]   += CURKIL[i] + FMPROB[i]
                totcls[mxsp1, icls]   += CURKIL[i] + FMPROB[i]
                totcls[mxsp1, maxcl1] += CURKIL[i] + FMPROB[i]
            end
        end
        for ksp in 1:Int(MAXSP)
            totbak[mxsp1]  += totbak[ksp]
            totvolk[mxsp1] += totvolk[ksp]
        end

        local dbskodem::Int32 = Int32(1)
        DBSFMMORT(Int32(iyr), clskil, totcls, totbak, totvolk, Ref(dbskodem))
        if dbskodem == 0; return; end

        global IMRPAS = IMRPAS + Int32(1)
        if IMRPAS == 1
            @printf(jout, "\n%5d\n%5d\n", IDMRT, IDMRT)
            @printf(jout, "%5d %s\n", IDMRT, "-"^117)
            @printf(jout, "%5d%33s\n", IDMRT, "******  FIRE MODEL VERSION 1.0 ******")
            @printf(jout, "%5d%43s\n", IDMRT, "MORTALITY REPORT (BASED ON STOCKABLE AREA)")
            @printf(jout, "%5d STAND ID: %-26s    MGMT ID: %-4s\n", IDMRT, NPLT, MGMID)
            @printf(jout, "%5d %s\n", IDMRT, "-"^117)
            if VARACD == "SN" || VARACD == "LS" || VARACD == "NE" || VARACD == "CS"
                @printf(jout, "%5d%21sNUMBER KILLED / NUMBER BEFORE (BY DIAMETER CLASS IN INCHES)%*sBASAL    MERCH\n",
                        IDMRT, "", 11, "")
            else
                @printf(jout, "%5d%21sNUMBER KILLED / NUMBER BEFORE (BY DIAMETER CLASS IN INCHES)%*sBASAL    TOTAL\n",
                        IDMRT, "", 11, "")
            end
            local cl_hdr = join(["  $(LOWDBH[i])-$(LOWDBH[i+1])  " for i in 1:6], "") *
                           "  >=$(LOWDBH[7])  "
            @printf(jout, "%5d YEAR  SP  %s  AREA     CU FT\n", IDMRT, cl_hdr)
        end

        local lfirst::Bool = true
        for ksp in 1:Int(mxsp1)
            if totcls[ksp, maxcl1] <= 0.0f0; continue; end
            local alline = " " ^ 90
            local wpos::Int = 2
            for icls in 1:Int(maxcl)
                if totcls[ksp, icls] > 0.0f0
                    local knum = Int(clskil[ksp, icls])
                    local tnum = Int(totcls[ksp, icls])
                    local seg  = @sprintf("%5d/%5d", knum, tnum)
                    local n = min(length(seg), 91 - wpos)
                    alline = alline[1:wpos-1] * seg[1:n] * alline[wpos+n:end]
                    wpos += 13
                else
                    clskil[ksp, icls] = -1.0f0
                    wpos += 13
                end
            end
            local sp_label = ksp < Int(mxsp1) ? rstrip(JSP[ksp]) : "ALL"
            if lfirst
                @printf(jout, "%5d %4d  %-3s %s%8.2f%9d\n",
                        IDMRT, iyr, sp_label, alline, totbak[ksp], Int(totvolk[ksp]))
                lfirst = false
            else
                @printf(jout, "%5d       %-3s %s%8.2f%9d\n",
                        IDMRT, sp_label, alline, totbak[ksp], Int(totvolk[ksp]))
            end
        end
    end
    return nothing
end
