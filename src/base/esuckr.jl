# esuckr.f — CREATE STUMP & ROOT SPROUTS FROM TREES CUT AT BEGINNING OF CYCLE.
# Trees removed this cycle are recorded in ISHOOT/PRBREM/JSHAGE/DSTUMP by ESTUMP
# (called from CUTS). For each, ESUCKR computes a sprout count (NSPREC), TPA per
# record (ESSPRT), height (SPRTHT) and DBH, and appends sprout tree records.
# Called from: ESNUTR (when LSPRUT and ITRNRM>=1).

function ESUCKR()
    debug = DBCHK("ESUCKR", 6, ICYC)
    # No trees removed → nothing to do
    if ITRNRM < Int32(1)
        global ITRNRM = Int32(0)
        return nothing
    end

    local MDBH = 10000000
    local MSP  = 10000
    local myacts = Int32[450]

    # Per-sprout-species accumulators (regen report)
    local countr = zeros(Float32, Int(NSPSPE))
    local tpasum = zeros(Float32, Int(NSPSPE))
    local htave  = zeros(Float32, Int(NSPSPE))
    local tpatot = 0.0f0

    # Keyword multipliers (SPROUT keyword, activity 450), default 1
    local sprmlt = ones(Float32, Int(NSPSPE), 100)
    local htmspr = ones(Float32, Int(NSPSPE), 100)
    local dmin   = zeros(Float32, Int(NSPSPE), 100)
    local dmax   = zeros(Float32, Int(NSPSPE), 100)

    # ── Process SPROUT keyword options ──
    local ntodo_ref = Ref(Int32(0))
    OPFIND(Int32(1), myacts, ntodo_ref)
    local ntodo = Int(ntodo_ref[])
    if ntodo > 0
        local prms = zeros(Float32, 6)
        for it in 1:ntodo
            local iactk, idt, np = OPGET(Int32(it), Int32(5), prms)
            local j = Int(trunc(prms[1]))
            if j < 0
                local igrp = -j
                local iulim = Int(ISPGRP[igrp, 1]) + 1
                for ig in 2:iulim
                    local igsp = Int(ISPGRP[igrp, ig])
                    for jj in 1:Int(NSPSPE)
                        if igsp == Int(ISPSPE[jj])
                            sprmlt[jj, it] = prms[2]; htmspr[jj, it] = prms[3]
                            dmin[jj, it] = prms[4];  dmax[jj, it] = prms[5]
                        end
                    end
                end
            elseif j == 0
                for jj in 1:Int(NSPSPE)
                    sprmlt[jj, it] = prms[2]; htmspr[jj, it] = prms[3]
                    dmin[jj, it] = prms[4];  dmax[jj, it] = prms[5]
                end
            else
                for jj in 1:Int(NSPSPE)
                    if j == Int(ISPSPE[jj])
                        sprmlt[jj, it] = prms[2]; htmspr[jj, it] = prms[3]
                        dmin[jj, it] = prms[4];  dmax[jj, it] = prms[5]
                    end
                end
            end
            OPDONE(Int32(it), Int32(idt))
        end
    end

    # ── Loop over each removed tree record ──
    for i in 1:Int(ITRNRM)
        local inumb = Int(ISHOOT[i])
        local icl   = inumb ÷ MDBH
        local issp  = inumb ÷ MSP - icl * 1000
        local iplot = mod(inumb, MSP)
        local prem  = PRBREM[i]
        local ishag = Int(JSHAGE[i])
        local dstmp = DSTUMP[i]

        prem < 0.001f0 && continue

        # Map the decoded sprout-species index to the actual species code
        local ispsto = issp
        if issp >= 1 && issp <= Int(NSPSPE)
            issp = Int(ISPSPE[issp])
        else
            continue   # no species match
        end

        # Ensure room in the tree list (RDESCP returns MAXTRE when RROT off)
        local mxrr_ref = Ref(Int32(0))
        RDESCP(Int32(MAXTRE), mxrr_ref)
        local mxrr = Int(mxrr_ref[])

        # Sprout keyword multipliers by stump-DBH range
        local smult = 1.0f0
        local hmult = 1.0f0
        for it in 1:ntodo
            if dstmp >= dmin[ispsto, it] && dstmp < dmax[ispsto, it]
                smult = sprmlt[ispsto, it]
                hmult = htmspr[ispsto, it]
            end
        end
        smult <= 0.0f0 && continue

        # Number of sprout records
        local nsprt_ref = Ref(Int32(0))
        NSPREC(VARACD, issp, nsprt_ref, dstmp)
        local numspr = Int(nsprt_ref[])

        # Quaking aspen (none in SN → indxas 0, branch skipped)
        local indxas_ref = Ref(Int32(0))
        ESASID(VARACD, indxas_ref)
        if issp == Int(indxas_ref[])
            local asprtr_ref = Ref(Float32(0))
            ASSPTN(Int32(ishag), ASBAR, ASTPAR, prem, asprtr_ref)
            prem = asprtr_ref[]
        end

        # Variant/species-specific TPA per sprout record
        local prem_ref = Ref(prem)
        ESSPRT(VARACD, issp, prem_ref, dstmp)
        prem = prem_ref[]

        prem < 0.001f0 && continue

        # ── Create sprout records ──
        for j in 1:numspr
            if ITRN >= mxrr
                local itrgt = Int(ITRNRM) - i
                local mxtodo = Int(round(mxrr * 0.70f0))
                mxtodo > itrgt && (itrgt = mxtodo)
                ESCPRS(Int32(itrgt), debug)
            end
            global ITRN = ITRN + Int32(1)
            local it = Int(ITRN)
            IMC[it] = Int32(2); ISP[it] = Int32(issp); ITRE[it] = Int32(iplot)
            CFV[it] = 0.0f0; MCFV[it] = 0.0f0; SCFV[it] = 0.0f0
            CULL[it] = 0.0f0; DECAYCD[it] = Int32(0); WDLDSTEM[it] = Int32(0)
            ABVGRD_BIO[it] = 0.0f0; ABVGRD_CARB[it] = 0.0f0
            MERCH_BIO[it] = 0.0f0; MERCH_CARB[it] = 0.0f0
            CUBSAW_BIO[it] = 0.0f0; CUBSAW_CARB[it] = 0.0f0
            FOLI_BIO[it] = 0.0f0; FOLI_CARB[it] = 0.0f0; CARB_FRAC[it] = 0.0f0
            ITRUNC[it] = Int32(0); NORMHT[it] = Int32(0)

            PROB[it] = prem * smult

            # Sprout height (with random deviation) and DBH
            local hti_ref = Ref(Float32(0))
            SPRTHT(VARACD, issp, SITEAR[issp], Int32(ishag), hti_ref)
            HT[it] = hti_ref[] * hmult
            local randev = 0.0f0
            while true
                randev = BACHLO(0.0f0, 0.5f0, ESRANN)
                (randev < -1.0f0 || randev > 1.0f0) || break
            end
            randev = randev * HT[it] / 5.5f0
            HT[it] = HT[it] + randev

            if HT[it] > 4.5f0
                local bx = HT2[issp]
                local ax = Int(IABFLG[issp]) == 1 ? HT1[issp] : AA[issp]
                DBH[it] = (bx / (log(HT[it] - 4.5f0) - ax)) - 1.0f0
                DBH[it] < 0.1f0 && (DBH[it] = 0.1f0)
            else
                DBH[it] = 0.1f0
            end

            ICR[it] = Int32(70)
            local cw_ref = Ref(Float32(0))
            CWCALC(Int32(issp), PROB[it], DBH[it], HT[it], 1.0f0,
                   ICR[it], cw_ref, Int32(0), JOSTND)
            CRWDTH[it] = cw_ref[]

            DG[it] = 0.0f0; HTG[it] = 0.0f0; PCT[it] = 0.0f0; OLDPCT[it] = 0.0f0
            WK1[it] = 0.0f0; WK2[it] = 0.0f0; WK4[it] = 0.0f0; BFV[it] = 0.0f0
            IESTAT[it] = Int32(0); PTBALT[it] = 0.0f0
            IDTREE[it] = Int32(10000000) + ICYC * Int32(10000) + ITRN
            MISPUTZ(it, 0)

            ABIRTH[it] = Float32(ishag); DEFECT[it] = Int32(0); ISPECL[it] = Int32(0)
            OLDRN[it] = 0.0f0; PTOCFV[it] = 0.0f0; PMRCFV[it] = 0.0f0
            PSCFV[it] = 0.0f0; PMRBFV[it] = 0.0f0
            NCFDEF[it] = Int32(0); NBFDEF[it] = Int32(0)
            PDBH[it] = 0.0f0; PHT[it] = 0.0f0; ZRAND[it] = -999.0f0

            countr[ispsto] += 1.0f0
            tpasum[ispsto] += prem * smult
            tpatot += prem * smult
            htave[ispsto] += HT[it]
        end
    end

    # ── Regeneration report ──
    if IPRINT != Int32(0)
        local io = get(io_units, Int32(JOREGT), devnull)
        @printf(io, "%s\nREGENERATION FROM STUMP & ROOT SPROUTS\n\nSTAND ID: %-26s  MANAGEMENT CODE: %-4s  YEAR: %5d\n\n             TREES  AVERAGE\n    SPECIES  /ACRE  HEIGHT\n    -------  -----  -------\n",
                repeat("-", 54), NPLT, MGMID, IY[Int(ICYC)+1] - 1)
        local wtaveht = 0.0f0
        local iyear = IY[Int(ICYC)+1] - 1
        local lastht = 0.0f0
        for ii in 1:Int(NSPSPE)
            local clabel = NSP[Int(ISPSPE[ii]), 1][1:min(2, length(NSP[Int(ISPSPE[ii]), 1]))]
            htave[ii] = htave[ii] / (countr[ii] + 0.00001f0)
            lastht = htave[ii]
            if tpasum[ii] > 0.0f0
                @printf(io, "       %2s   %6.0f  %6.1f\n", clabel, tpasum[ii], htave[ii])
                wtaveht = htave[ii] * tpasum[ii] + wtaveht
                DBSSPRT(clabel, tpasum[ii], htave[ii], tpatot, wtaveht, 1, iyear)
            end
        end
        wtaveht = tpatot == 0.0f0 ? 0.0f0 : wtaveht / tpatot
        DBSSPRT("ALL", 0.0f0, lastht, tpatot, wtaveht, 2, iyear)
        @printf(io, "             -----\n            %6.0f\n%s\n", tpatot, repeat("-", 54))
    end

    global ITRNRM = Int32(0)
    return nothing
end
