# base/estab.jl — ESTAB: regeneration establishment tree creation.
# Translated from: bin/FVSsn_buildDir/estab.f (817 lines).
#
# Scope: the PLANT/plot-replication path that snt01's BARE stand exercises
# (NTALLY=1..4, NPTIDS=1, two PLANT keywords → 50 replicated plots → 100 tree
# records → 800 TPA). Natural-regen-only machinery (habitat density curves,
# best-tree picking, stocking) that isn't reached for PLANT-only is omitted.
#
# ESCOMN renames: Fortran TIME→TIME_ES, BAA→BAA_ES.
# Per-tree stubs that don't matter here: RDESTB, MISPUTZ, BRESTB, RDESCP(→MAXTRE).

function ESTAB(kdt::Integer)
    kdt = Int32(kdt)
    debug = DBCHK(false, "ESTAB", Int32(5), Int(ICYC))
    mdbh_id = Int32(10_000_000)
    myacts  = Int32[430, 431, 491, 493]
    nofspe  = Int(MAXSP)

    itrnin = ITRN + Int32(1)
    zharv  = Float32(IDSDAT)
    flokdt = Float32(kdt)
    global TIME_ES = flokdt - zharv + 1.0f0
    flonpt = Float32(NPTIDS)
    global ELEVSQ = Float32(ELEV) * Float32(ELEV)
    itmp = Int(ICYC) * 10000
    global MODE = Int32(0)
    if Int(kdt) + 1 - Int(IY[1]) > 20
        global INADV = Int32(1); global LOAD = Int32(0)
    end

    agepl  = zeros(Float32, 99)
    icode  = zeros(Int32, 99)
    iasep  = zeros(Int32, 99)
    height = zeros(Float32, 99)
    esprob = zeros(Float32, 99)
    htimlt = zeros(Float32, 99)
    first  = fill(0.1f0, 2, nofspe)
    tottpa = zeros(Float32, nofspe)
    bestpa = zeros(Float32, nofspe)
    pastpa = zeros(Float32, nofspe)
    iplant = zeros(Int32, nofspe)
    tcrop1 = 0.0f0; tcrop2 = 0.0f0; ttottp = 0.0f0
    for i in 1:nofspe
        SUMPX[i] = 0.0f0; SUMPI[i] = 0.0f0
    end

    # ---- plot replication: DUP from the MINREP loop ----
    dup = 0.0f0
    for i in 1:Int(MINREP)
        dup += 1.0f0
        n = Int(NPTIDS) * i
        if Int(NPTIDS) * (i + 1) > Int(MAXPLT); break; end
        if n >= Int(MINREP); break; end
    end
    idup   = Int(floor(dup + 0.5f0))
    dupnpt = flonpt * dup

    # ---- forest code lookup ----
    ifo = 4
    for i in 1:20
        if Int(KODFOR) == Int(IFORCD[i]); ifo = Int(IFORST[i]); break; end
    end
    global IFO = Int32(ifo)

    # ---- site preps (first tally only) ----
    meth_r = Ref(Int32(0)); zmech_r = Ref(0.0f0); zburn_r = Ref(0.0f0)
    pnone_r = Ref(0.0f0); pmech_r = Ref(0.0f0); pburn_r = Ref(0.0f0)
    ialn = zeros(Int32, 3); ip_r = Ref(Int32(0))
    if NTALLY != Int32(1)
        @goto label_276
    end
    ESETPR(meth_r, zmech_r, zburn_r, pnone_r, pmech_r, pburn_r, ialn, IDSDAT, kdt, ip_r)
    if zmech_r[] < zharv; zmech_r[] = zharv; end
    if zburn_r[] < zharv; zburn_r[] = zharv; end
    global KDTOLD = Int32(floor(zharv - 0.5f0))

    @label label_276
    esdraw = ESDRAW
    if NTALLY == Int32(1)
        draw_r = Ref(0.0f0); ESRANN(draw_r)
        esdraw = Float32(Int(floor(draw_r[] * 100000.0f0 + 0.5f0)))
    end
    ESRNSD(true, Ref(esdraw))
    global ESDRAW = esdraw

    # ---- load regen vectors from current inventory ----
    if ITRN > Int32(0)
        for i in 1:Int(ITRN)
            if DBH[i] >= REGNBK; continue; end
            nn = Int(ISP[i])
            if nn < 1 || nn > nofspe; continue; end
            pastpa[nn] += PROB[i]
            tcrop2 += PROB[i]
        end
    end

    # ---- site-prep draws ----
    nrep = idup * Int(NPTIDS)
    for i in 1:nrep
        dr = Ref(0.0f0); ESRANN(dr); WK6[i] = dr[]
    end

    sumup = zeros(Float32, 3)
    if NTALLY != Int32(1); @goto label_242; end
    if LOAD == Int32(1)
        # replicate plot preps
        nn = 0
        for i in 1:Int(NPTIDS); nn += 1; IPPREP[nn] = IPPREP[Int(IPTIDS[i])]; end
        if idup >= 2
            for i in 1:idup, n in 1:Int(NPTIDS)
                j = i * Int(NPTIDS) + n
                IPPREP[j] = IPPREP[n]
            end
        end
        @goto label_49
    end
    if ialn[2] != Int32(0) || ialn[3] != Int32(0)
        s = pmech_r[] + pburn_r[]
        if s > 1.0f0; pmech_r[] /= s; pburn_r[] /= s; end
        pnone_r[] = 1.0f0 - pmech_r[] - pburn_r[]
    else
        ESPREP(Int32(1), pnone_r, pmech_r, pburn_r)
    end

    # ---- choose site preps, sample without replacement ----
    s = pnone_r[] + pmech_r[] + pburn_r[]
    sumup[1] = pnone_r[] / s; sumup[2] = pmech_r[] / s; sumup[3] = pburn_r[] / s
    n = 0
    for ii in 1:idup, nnp in 1:Int(NPTIDS)
        n += 1
        draw = WK6[n] * ((dupnpt + 1.0f0 - Float32(n)) / dupnpt)
        ssum = 0.0f0; ipick = 0
        for i in 1:2
            ssum += sumup[i]
            if draw <= ssum; ipick = i; break; end
        end
        if ipick == 0
            ipick = sumup[3] < 0.0f0 ? 1 : 3
        end
        IPPREP[n] = Int32(ipick)
        sumup[ipick] -= 1.0f0 / dupnpt
        if sumup[ipick] < 0.0f0; sumup[ipick] = 0.0f0; end
    end

    @label label_49
    @label label_242
    # ---- get PLANT & NATURAL keywords; set MODE ----
    prms = zeros(Float32, 6)
    ntodo = OPFIND(Int32(2), @view(myacts[1:2]))
    if ntodo > Int32(0); global MODE = Int32(1); end
    mydo = Int(ntodo)
    for izero in 1:Int(ntodo)
        iactk, ipy, np = OPGET(Int32(izero), Int32(6), prms)
        if prms[2] <= 0.001f0 || prms[3] <= 0.001f0
            OPDEL1(Int32(izero)); mydo -= 1
        end
    end
    if mydo == 0; global MODE = Int32(0); end

    # ---- shade-adjustment sums ----
    sum1 = 0.0f0; sum2 = 0.0f0
    for nn in 1:Int(NPTIDS)
        tbaaa = BAAA[Int(IPTIDS[nn])]; if tbaaa < 1.0f0; tbaaa = 1.0f0; end
        sum1 += tbaaa
    end
    for nn in 1:Int(NPTIDS)
        tbaaa = BAAA[Int(IPTIDS[nn])]; if tbaaa < 1.0f0; tbaaa = 1.0f0; end
        sum2 += sum1 / tbaaa
    end

    # ---- plot processing ----
    ncount = 0
    gentim = TIME_ES - 5.0f0
    if gentim < 0.0f0; gentim = 0.0f0; end

    for nn in 1:Int(NPTIDS)
        nnprep = zeros(Int32, 4)
        istart = nn * idup - idup + 1
        iend   = nn * idup
        for i in istart:iend
            np = Int(IPPREP[i]); if np < 1 || np > 4; np = 1; end
            nnprep[np] += Int32(1)
        end

        for itypep in 1:4
            ipold = 0
            if nnprep[itypep] < Int32(1); continue; end
            ntimes = Int(nnprep[itypep])
            for irep in 1:ntimes
                ncount += 1
                iprep = itypep
                if iprep != ipold
                    ipold = iprep
                    global NNID = IPTIDS[nn]
                    radian = PASP[Int(NNID)]
                    global SLO   = PSLO[Int(NNID)]
                    global IPHY  = IPHYS[Int(NNID)]
                    global XCOSAS = cos(radian); global XSINAS = sin(radian)
                    global XCOS = XCOSAS * SLO;  global XSIN = XSINAS * SLO
                    baa = BAAA[Int(NNID)]
                    if baa < 1.0f0; baa = 1.0f0; end
                    if baa > 400.0f0; baa = 400.0f0; end
                    global BAA_ES = baa; global BAASQ = baa * baa; global BAALN = log(baa)
                    global IHAB = IPHAB[Int(NNID)]
                end

                # reset TIME to years since disturbance / site prep
                if iprep == 2
                    ievtyr = Int(floor(zmech_r[])); global TIME_ES = flokdt + 1.0f0 - zmech_r[]
                elseif iprep == 3
                    ievtyr = Int(floor(zburn_r[])); global TIME_ES = flokdt + 1.0f0 - zburn_r[]
                else
                    ievtyr = Int(IDSDAT); global TIME_ES = flokdt + 1.0f0 - zharv
                end
                ESTIME(ievtyr, kdt)
                dr = Ref(0.0f0); ESRANN(dr); emsqr = dr[] < 0.5f0 ? -1.0f0 : 1.0f0
                ESRANN(dr); emsqr *= dr[]

                itpp = 0
                ESRANN(dr)
                esdraw = Float32(Int(floor(dr[] * 100000.0f0 + 0.5f0)))

                # ---- create trees from PLANT & NATURAL (MODE 1) ----
                if MODE == Int32(1)
                    itodo = 0
                    ntodo2 = OPFIND(Int32(2), @view(myacts[1:2]))
                    itoomp = 0
                    for ido in 1:Int(ntodo2)
                        iactk, ipyear, np = OPGET(Int32(ido), Int32(6), prms)
                        if iactk <= Int32(0); continue; end
                        itodo += 1
                        if itpp + itodo > 99
                            itoomp += 1; OPDEL1(Int32(ido)); itodo -= 1; continue
                        end
                        ipnspe = Int(floor(prms[1]))
                        ptree  = (prms[2] * (prms[3] / 100.0f0)) / dupnpt
                        trage  = prms[4]
                        if trage < 0.5f0; trage = 2.0f0; end
                        if trage > 10.0f0; trage = 10.0f0; end
                        agepl[itodo] = trage
                        delay = Float32(ipyear) - (Float32(kdt) + 1.0f0 - FINT)
                        treeht = prms[5]
                        ishade = Int(floor(prms[6]))
                        ftemp = BAA_ES; if ftemp < 1.0f0; ftemp = 1.0f0; end
                        if ishade == 1
                            ptree = ptree * Float32(NPTIDS) * ftemp / sum1
                        elseif ishade == 2
                            ptree = ptree * Float32(NPTIDS) * (sum1 / ftemp) / sum2
                        end
                        dilate = first[2, ipnspe]
                        tmtime = TIME_ES; global TIME_ES = FINT
                        hht_r = Ref(1.0f0); delay_r = Ref(delay); trage_r = Ref(trage)
                        ESSUBH(ipnspe, hht_r, 0.0f0, dilate, delay_r, Float32(ELEV),
                               1, gentim, trage_r)
                        global TIME_ES = tmtime
                        hht = hht_r[]; delay = delay_r[]
                        if treeht >= 0.1f0
                            hht = treeht
                            xh = log(hht)
                            while true
                                xxh = exp(BACHLO(xh, 0.5f0, ESRANN))   # estab.f 479: ESRANN, not main RANN
                                if xxh >= 0.5f0*hht && xxh <= 2.0f0*hht; hht = xxh; break; end
                            end
                            hht += HTADJ[ipnspe]
                            if hht < 0.05f0; hht = 0.05f0; end
                        else
                            while true
                                ran = BACHLO(0.5f0, 0.25f0, ESRANN)   # estab.f 485: ESRANN, not main RANN
                                if ran >= 0.0f0 && ran <= 1.5f0; hht += ran; break; end
                            end
                            hht += HTADJ[ipnspe]
                            if hht < XMIN[ipnspe]; hht = XMIN[ipnspe]; end
                        end
                        first[2, ipnspe] = sqrt(dilate)
                        if hht > HHTMAX[ipnspe]; hht = HHTMAX[ipnspe]; end

                        icode[itpp+itodo]  = Int32(ipnspe)
                        iasep[itpp+itodo]  = iactk == Int32(430) ? Int32(3) : Int32(4)
                        height[itpp+itodo] = hht
                        esprob[itpp+itodo] = ptree
                        gentim2 = (FINT - delay) < 5.0f0 ? 0.0f0 : (FINT - delay - 5.0f0)
                        ft = trage; if ft > gentim2; ft = gentim2; end
                        htimlt[itpp+itodo] = ft / (gentim2 + 0.0001f0)
                        agepl[itpp+itodo]  = FINT - delay + agepl[itodo]
                    end
                    itp = itpp + itodo

                    # ---- pass trees from PLANT/NATURAL into the tree list (DO 35/24) ----
                    ESRNSD(true, Ref(esdraw))
                    jcount = itp - itpp
                    for jj in 1:jcount
                        ii = Int(icode[itpp+jj])
                        ftemp = esprob[itpp+jj]
                        if ftemp < 0.00011f0 && jj < jcount
                            esprob[itpp+jj+1] += ftemp; esprob[itpp+jj] = 0.0f0; continue
                        end
                        ibrkup = Int(floor(ftemp / 10.0f0 + 1.0f0)); brkup = Float32(ibrkup)
                        tottpa[ii] += ftemp; pastpa[ii] += ftemp; bestpa[ii] += ftemp
                        tcrop1 += ftemp; tcrop2 += ftemp; ttottp += ftemp
                        for _ in 1:ibrkup
                            global ITRN = ITRN + Int32(1)
                            it = Int(ITRN)
                            hht = height[itpp+jj]
                            IMC[it] = Int32(1); ISP[it] = Int32(ii)
                            CFV[it] = 0.0f0; MCFV[it] = 0.0f0; SCFV[it] = 0.0f0
                            CULL[it] = 0.0f0; DECAYCD[it] = Int32(0); WDLDSTEM[it] = Int32(0)
                            ABVGRD_BIO[it] = 0.0f0; ABVGRD_CARB[it] = 0.0f0
                            MERCH_BIO[it] = 0.0f0; MERCH_CARB[it] = 0.0f0
                            CUBSAW_BIO[it] = 0.0f0; CUBSAW_CARB[it] = 0.0f0
                            FOLI_BIO[it] = 0.0f0; FOLI_CARB[it] = 0.0f0; CARB_FRAC[it] = 0.0f0
                            ITRUNC[it] = Int32(0); NORMHT[it] = Int32(0)
                            HT2TD[it,1] = 0.0f0; HT2TD[it,2] = 0.0f0
                            ITRE[it] = NNID
                            ftemp2 = ftemp / brkup
                            PROB[it] = ftemp2; DBH[it] = 0.1f0; HT[it] = hht
                            ABIRTH[it] = agepl[jj]; DEFECT[it] = Int32(0); ISPECL[it] = Int32(0)
                            PTOCFV[it] = 0.0f0; PMRCFV[it] = 0.0f0; PSCFV[it] = 0.0f0; PMRBFV[it] = 0.0f0
                            NCFDEF[it] = Int32(0); NBFDEF[it] = Int32(0)
                            PDBH[it] = 0.0f0; PHT[it] = 0.0f0; ZRAND[it] = -999.0f0
                            ICR[it] = Int32(0); DG[it] = 0.0f0; HTG[it] = 0.0f0
                            PCT[it] = 0.0f0; OLDPCT[it] = 0.0f0; OLDRN[it] = 0.0f0
                            WK1[it] = 0.0f0; WK2[it] = 0.0f0; WK4[it] = htimlt[itpp+jj]
                            BFV[it] = 0.0f0; IESTAT[it] = Int32(0)
                            PTBALT[it] = PTBAA[Int(NNID)]
                            IDTREE[it] = Int32(10_000_000) + Int32(itmp) + Int32(it)
                        end
                    end
                end  # MODE==1
            end  # IREP
        end  # ITYPEP
    end  # NN (plot loop)

    # ---- mark PLANT/NATURAL keywords done ----
    ntodo3 = OPFIND(Int32(2), @view(myacts[1:2]))
    if ntodo3 > Int32(0)
        for itodo in 1:Int(ntodo3)
            iactk, ipyear, np = OPGET(Int32(itodo), Int32(6), prms)
            if iactk <= Int32(0); continue; end
            iplant[Int(floor(prms[1]))] = Int32(1)
            OPDONE(Int32(itodo), ipyear)
        end
    end

    # ---- grow the new trees to end of cycle ----
    if ITRN >= itrnin; ESGENT(itrnin); end
    for i in Int(itrnin):Int(ITRN)
        cw_r = Ref(0.0f0)
        CWCALC(ISP[i], PROB[i], DBH[i], HT[i], 1.0f0, ICR[i], cw_r, Int32(0), JOSTND)
        CRWDTH[i] = cw_r[]
        ABIRTH[i] = ABIRTH[i] + gentim
    end
    return nothing
end
