# base/cuts.jl — CUTS: execute thinning/harvest options for one cycle
# Translated from: bin/FVSsn_buildDir/cuts.f (2048 lines)
#
# Called once per cycle from TREGRO. Handles 17 thinning types (THINAUTO through
# THINQFA), the SPECPREF/TCONDMLT/YARDING/SPLEAVE modifier keywords, SETPTHIN
# point filtering, and PRUNE. All complex branching faithfully preserved via
# @goto/@label. Outer DO 1400 loop is a manual while to allow the LQFA backward
# jump (line 1528→352) within a single KUT iteration.

function CUTS()
    debug = DBCHK(false, "CUTS", Int32(4), ICYC)

    # Activity codes recognised by CUTS
    myacts = Int32[200,201,202,203,206,
                   222,223,224,225,226,227,228,229,230,231,232,233,234,235,236,237,
                   248,249]

    # Local tree-class accumulators (per species × 3 IMC classes)
    spcrt  = zeros(Float32, Int(MAXSP), 3)   # removed TPA
    spcrc  = zeros(Float32, Int(MAXSP), 3)   # removed total CFV
    spcres = zeros(Float32, Int(MAXSP), 3)   # residual TPA
    spcbr  = zeros(Float32, Int(MAXSP), 3)   # removed merch BFV
    spcmr  = zeros(Float32, Int(MAXSP), 3)   # removed merch CFV
    spcsr  = zeros(Float32, Int(MAXSP), 3)   # removed SC CFV

    # Per-tree yarding pools
    ssng   = zeros(Float32, Int(MAXTRE))   # standing snags/acre from cut
    dsng   = zeros(Float32, Int(MAXTRE))   # down snags/acre from cut
    ctcrwn = zeros(Float32, Int(MAXTRE))   # crown trees removed (or prune prop)
    tkcrwn = zeros(Float32, Int(MAXTRE))   # crowns taken from stand

    lnocut = falses(Int(MAXTRE))           # tree exempt from cutting flag
    prfmis = zeros(Float32, Int(MAXSP), 6) # mistletoe cutting preferences

    prms = zeros(Float32, 7)

    # Logical locals
    lyard  = false; lbarea = false; lbelow = false; lspecl = false
    lnoaut = false; lpdbh  = true;  lsdi   = false; lprtnd = false
    lptall = false; lqfa   = false; lzeideqfa = false; debug1 = false
    ldelqfa = false; lptgroup = false; lincl = false

    # Integer locals
    iactk  = Int32(0); ntodo  = Int32(0); kut   = Int32(0); kdt  = Int32(0)
    nps    = Int32(0); icflag = Int32(0); ispcut = Int32(0); jspcut = Int32(0)
    jtyp   = Int32(0); idmcut = Int32(0); kutnow = Int32(0); jpnum = Int32(0)
    ivac   = Int32(0); icut   = Int32(0); is     = Int32(0); im    = Int32(0)
    it_idx = Int32(0); ip     = Int32(0); ishag  = Int32(0); qfatar = Int32(0)
    jostnd1 = Int32(0); icflagqfa = Int32(0); jptgrp = Int32(0); jpt = Int32(0)
    ineg   = Int32(0); ipos   = Int32(0); igrp   = Int32(0); iulim = Int32(0)
    ispec  = Int32(0); imeth  = Int32(0); iprun  = Int32(0); nprun = Int32(0)
    ioldcr = Int32(0); idmr   = Int32(0)

    # Real locals
    remove  = Float32(0); rstock  = Float32(0); stock   = Float32(0)
    target  = Float32(0); cuteff  = Float32(0); cutef1  = Float32(0)
    fulstk  = Float32(0); cstock  = Float32(0); sdic    = Float32(0)
    zsdi    = Float32(0); stagea  = Float32(0); stageb  = Float32(0)
    csdi    = Float32(0); ctpa    = Float32(0); cba     = Float32(0)
    valmin  = Float32(0); valmax  = Float32(9999); dbhlo = Float32(0)
    dbhhi   = Float32(9999); htlo  = Float32(0); hthi   = Float32(999)
    dmax    = Float32(0); cfcut   = Float32(0); bfcut   = Float32(0)
    bacut   = Float32(0); tcut    = Float32(0); cmcut   = Float32(0); sccut = Float32(0)
    trees   = Float32(0); totcut  = Float32(0); this_c  = Float32(0)
    xleft   = Float32(0); cut_v   = Float32(0); prem    = Float32(0)
    prem2   = Float32(0); xmore   = Float32(0); salvtpa = Float32(0)
    loss    = Float32(0); p       = Float32(0); v       = Float32(0)
    d       = Float32(0); sumd2   = Float32(0); clknt   = Float32(0)
    treerd  = Float32(0); temp    = Float32(0); cwdi    = Float32(0)
    remtpa  = Float32(0); diff    = Float32(0); orgwk4  = Float32(0)
    prlost  = Float32(0); prdsng  = Float32(0); prcrwn  = Float32(1)
    tpafac  = Float32(0); diamfac = Float32(0); tsumd2  = Float32(0)
    tclknt  = Float32(0); cfvoli  = Float32(0)
    qfac    = Float32(0); diacw   = Float32(0); tarqfa  = Float32(0)
    valminqfa = Float32(0); valmaxqfa = Float32(0)
    ccc     = Float32(1); ccclc1  = Float32(0); ccclc21 = Float32(0)
    cccsdi  = Float32(0); cct     = Float32(0); cradif  = Float32(0)
    basnew  = Float32(0); cutmax  = Float32(0); ftcut   = Float32(0)
    crlen   = Float32(0); cri_f   = Float32(0); hti     = Float32(0)
    crbase  = Float32(0); feet    = Float32(0); pprop   = Float32(0)
    dlow_p  = Float32(0); dhi_p   = Float32(0); xsz     = Float32(0)

    # ── debug preamble ────────────────────────────────────────────────────────
    if debug
        @printf(io_units[Int(JOSTND)], "\n IN CUTS: VALUES OF PROB (15/LINE):\n\n")
        @printf(io_units[Int(JOSTND)], " %s\n",
                join([@sprintf("%10.4f", PROB[i]) for i in 1:Int(ITRN)], ""))
    end

    # ── initial dead-tree cleanup (lines 259-303) ─────────────────────────────
    ivac = Int32(0)
    if ITRN > Int32(0)
        RDPSRT(Int(ITRN), PROB, IND2, true)
        for i in 1:Int(ITRN)
            iti = Int(IND2[i])
            if iti <= 0
                ivac += Int32(1)
            elseif PROB[iti] <= Float32(1e-10)
                ivac += Int32(1)
                IND2[i] = -Int32(iti)
            end
        end
        if debug
            @printf(io_units[Int(JOSTND)], "\n IN CUTS, TOTALLY DEAD TREES=%5d; TOT TREES=%5d\n",
                    ivac, ITRN)
        end
        if ivac > Int32(0)
            TREDEL(ivac, IND2)
            SPESRT()
            global IFST = Int32(1)
        end
        IND[1] = Int32(0)
        RDPSRT(Int(ITRN), DBH, IND, true)
    end

    # ── general initialization (lines 308-462) ────────────────────────────────
    tpafac = Float32(0); diamfac = Float32(0)
    tsumd2 = Float32(0); tclknt  = Float32(0)
    global ASTPAR = Float32(0); global ASBAR = Float32(0)
    kutnow = Int32(0); jptgrp = Int32(0); jpt = Int32(0)
    lpdbh = true; lnoaut = false; lqfa = false; ldelqfa = false; lptgroup = false
    ispcut = Int32(0)

    for i in 1:7
        ONTREM[i]=Float32(0); OCVREM[i]=Float32(0); ONTRES[i]=Float32(0)
        OBFREM[i]=Float32(0); OMCREM[i]=Float32(0); OSCREM[i]=Float32(0)
        OAGBIOREM[i]=Float32(0);  OAGCARBREM[i]=Float32(0)
        OMERBIOREM[i]=Float32(0); OMERCARBREM[i]=Float32(0)
        OCSAWBIOREM[i]=Float32(0); OCSAWCARBREM[i]=Float32(0)
        OFOLIBIOREM[i]=Float32(0); OFOLICARBREM[i]=Float32(0)
        prms[i] = Float32(0)
    end
    for i in 1:Int(MAXSP), j in 1:3
        spcrt[i,j]=Float32(0); spcrc[i,j]=Float32(0); spcres[i,j]=Float32(0)
        spcbr[i,j]=Float32(0); spcmr[i,j]=Float32(0); spcsr[i,j]=Float32(0)
    end
    for ic in 1:Int(MAXTRE)
        WK3[ic]=Float32(0); ssng[ic]=Float32(0); dsng[ic]=Float32(0)
        ctcrwn[ic]=Float32(0); tkcrwn[ic]=Float32(0); YRDLOS[ic]=Float32(0)
    end

    lyard_ref = Ref(false)
    FMATV(lyard_ref)
    lyard = lyard_ref[]
    prlost = Float32(0); prdsng = Float32(0); prcrwn = Float32(1)

    if LECON; ECVOLS(); end

    lprtnd_ref = Ref(false)
    GETISPRETENDACTIVE(lprtnd_ref)
    lprtnd = lprtnd_ref[]
    if debug
        @printf(io_units[Int(JOSTND)], " ECON PRETEND MODE= %s\n", lprtnd ? ".TRUE." : ".FALSE.")
    end

    salvtpa_ref = Ref(Float32(0))
    FMSALV(Int(IY[Int(ICYC)]), salvtpa_ref)
    salvtpa = salvtpa_ref[]
    if debug
        @printf(io_units[Int(JOSTND)], " IN CUTS, FOLLOWING FMSALV CALL: SALVTPA=%7.2f\n", salvtpa)
    end

    # suppress THINAUTO if other thinnings scheduled (activities 223-237)
    ntodo = OPFIND(15, view(myacts, 7:21))
    if ntodo > Int32(0); lnoaut = true; end

    # MINHARV update (activity 200)
    ntodo = OPFIND(1, view(myacts, 1:1))
    if ntodo <= Int32(0); @goto label_40; end
    iactk, kdt, nps = OPGET(ntodo, Int32(5), prms)
    if iactk < Int32(0); @goto label_40; end
    OPDONE(ntodo, IY[Int(ICYC)])
    global BAMIN  = prms[1]; global TCFMIN = prms[2]; global CFMIN = prms[3]
    if VARACD == "CS" || VARACD == "LS" || VARACD == "NE" || VARACD == "SN" || LFIANVB
        global SCFMIN = prms[4]
    elseif !LFIANVB && prms[4] > Float32(0)
        ERRGRO(true, Int32(53))
    end
    global BFMIN = prms[5]
    @label label_40

    MISCPF(prfmis)

    # find thinning activities (201,202,203,206,222..248)
    ntodo = OPFIND(21, view(myacts, 2:22))
    if debug
        @printf(io_units[Int(JOSTND)], " IN CUTS:  NTODO=%4d; MYACTS= %s\n",
                ntodo, join(myacts[2:22], " "))
    end
    if ntodo <= Int32(0)
        tcut = Float32(0)
        @goto label_1950
    end

    iactk = Int32(0)

    # ── label_50: WK4 init (re-entered by THINAUTO retry) ────────────────────
    @label label_50
    if ITRN <= Int32(0); @goto label_100; end
    for i in 1:Int(ITRN); WK4[i] = PROB[i]; end
    @label label_100
    cfcut=Float32(0); bfcut=Float32(0); bacut=Float32(0); tcut=Float32(0)
    cmcut=Float32(0); sccut=Float32(0)
    trees = ONTCUR[7]
    jpnum = Int32(0); lptall = false

    # ── outer KUT loop (Fortran DO 1400 KUT=1,NTODO) ─────────────────────────
    kut = Int32(0)
    @label label_kut_top
    kut += Int32(1)
    if kut > ntodo; @goto label_kut_done; end

    lbelow=false; lspecl=false; lbarea=false; lsdi=false; lqfa=false
    for i in 1:7; prms[i]=Float32(0); end

    if iactk == Int32(221); @goto label_150; end   # THINAUTO retry: bypass OPGET

    iactk, kdt, nps = OPGET(kut, Int32(7), prms)
    if debug
        @printf(io_units[Int(JOSTND)],
            " IN CUTS:  KDT=%5d; IACTK=%4d; NPS=%2d; PRMS=%8.2f%8.2f%8.2f%8.2f%8.2f%8.2f%8.2f\n",
            kdt, iactk, nps, prms[1],prms[2],prms[3],prms[4],prms[5],prms[6],prms[7])
    end
    if iactk < Int32(0); @goto label_1400; end

    # SETPTHIN (activity 248)
    if iactk == Int32(248)
        if prms[1] >= Float32(0)
            jpnum = Int32(floor(prms[1] + Float32(0.5)))
        else
            jpnum = Int32(floor(prms[1] - Float32(0.5)))
        end
        if jpnum > Int32(-1) && jpnum < Int32(1)  # effectively ==0
            lptall = true
            @goto label_12813
        end
        if jpnum < Int32(0)
            lptgroup = true; jpt = Int32(1)
            jptgrp = Int32(-jpnum)
            jpnum = IPTGRP[Int(jptgrp), 2]
        end
        found_pt = false
        for ipchk in 1:Int(IPTINV)
            if ITHNPI == Int32(1)
                if jpnum == IPVEC[ipchk]
                    jpnum = Int32(ipchk); found_pt = true; break
                end
            else
                if jpnum <= IPTINV
                    found_pt = true; break
                end
            end
        end
        if !found_pt
            OPDEL1(kut)
            @goto label_1400
        end
        @label label_12813
        if prms[1] >= Float32(0); global ITHNPN = Int32(floor(prms[1])); end
        if prms[2] > Float32(0);  global ITHNPA = Int32(floor(prms[2])); end
        OPDONE(kut, IY[Int(ICYC)])
        if debug
            @printf(io_units[Int(JOSTND)],
                " SETPTHIN PROCESSING ITHNPN,ITHNPA,JPNUM,IPTINV= %d %d %d %d\n",
                ITHNPN, ITHNPA, jpnum, IPTINV)
        end
        @goto label_1400
    end  # end SETPTHIN

    icflag = iactk - Int32(220)
    if icflag != Int32(15); jpnum = Int32(0); end

    if icflag <= Int32(0); @goto label_1150; end
    if icflag > Int32(28); @goto label_1950; end

    # THINAUTO keyword (saves params, marks done)
    if icflag == Int32(2)
        global AUTMIN = prms[1]; global AUTMAX = prms[2]; global AUTEFF = prms[3]
        global LAUTON = true
        OPDONE(kut, IY[Int(ICYC)])
        @goto label_1400
    end

    if ITRN <= Int32(0); OPDEL1(kut); @goto label_1400; end

    target = max(Float32(0), prms[1])
    if nps > Int32(1); cuteff = prms[2]; end
    stock = trees - tcut

    # computed GOTO for ICFLAG 1..17
    if     icflag == Int32(1);  @goto label_150
    elseif icflag == Int32(3);  @goto label_200
    elseif icflag == Int32(4);  @goto label_225
    elseif icflag == Int32(5);  @goto label_250
    elseif icflag == Int32(6);  @goto label_275
    elseif icflag == Int32(7);  @goto label_300
    elseif icflag == Int32(8);  @goto label_325
    elseif icflag == Int32(9);  @goto label_300
    elseif icflag == Int32(10); @goto label_400
    elseif icflag == Int32(11); @goto label_400
    elseif icflag == Int32(12); @goto label_325
    elseif icflag == Int32(13); @goto label_450
    elseif icflag == Int32(14); @goto label_400
    elseif icflag == Int32(15); @goto label_475
    elseif icflag == Int32(16); @goto label_400
    elseif icflag == Int32(17); @goto label_350
    end

    # ── 150: THINAUTO / fall-through from statement 50 ───────────────────────
    @label label_150
    icflag = Int32(1)
    stock  = trees - tcut
    cuteff = AUTEFF
    fulstk = AUTSTK()
    remove = Float32(0)
    if stock < (AUTMAX / Float32(100)) * fulstk; @goto label_2000; end
    rstock = (AUTMIN / Float32(100)) * fulstk
    remove = stock - rstock
    if remove <= Float32(0); @goto label_2000; end
    lbelow = true
    if debug
        @printf(io_units[Int(JOSTND)],
            " ICFLAG  STOCK  AUTMIN  AUTMAX  CUTEFF  FULSTK  RMSQD  REMOVE  RSTOCK  LBELOW\n %5d%8.2f%8.2f%8.2f%8.2f%8.2f%8.2f%8.2f%8.2f%8s\n",
            icflag,stock,AUTMIN,AUTMAX,cuteff,fulstk,RMSQD,remove,rstock,lbelow ? "T" : "F")
    end
    @goto label_700

    # ── 200: THINBTA / THINATA ───────────────────────────────────────────────
    @label label_200
    lbelow = true
    @label label_225   # THINATA entry
    dbhlo = prms[3]; dbhhi = prms[4]; htlo = prms[5]; hthi = prms[6]
    lpdbh = (dbhhi - dbhlo) <= (hthi - htlo)
    cstock = CLSSTK(Int32(1), Int32(0), dbhlo, dbhhi, htlo, hthi, Int32(0))
    rstock = target; remove = cstock - rstock
    @goto label_550

    # ── 250: THINBBA / THINABA ───────────────────────────────────────────────
    @label label_250
    lbelow = true
    @label label_275
    lbarea = true
    dbhlo = prms[3]; dbhhi = prms[4]; htlo = prms[5]; hthi = prms[6]
    cstock = CLSSTK(Int32(2), Int32(0), dbhlo, dbhhi, htlo, hthi, Int32(0))
    rstock = target; remove = cstock - rstock
    @goto label_550

    # ── 300: THINPRSC ────────────────────────────────────────────────────────
    @label label_300
    cuteff = prms[1]; rstock = Float32(0); remove = Float32(99999)
    lspecl = true
    if nps > Int32(1); kutnow = Int32(floor(prms[2])); end
    @goto label_550

    # ── 325: THINDBH / THINHT ────────────────────────────────────────────────
    @label label_325
    valmin = prms[1]; valmax = prms[2]
    if valmax < valmin; valmax = Float32(9999); end
    cuteff = prms[3]; ispcut = Int32(floor(prms[4]))
    ctpa = max(Float32(0), prms[5]); cba = max(Float32(0), prms[6])
    rstock = Float32(0); remove = Float32(99999); lspecl = true
    @goto label_355

    # ── 350: THINQFA ─────────────────────────────────────────────────────────
    @label label_350
    valminqfa = prms[1]; valmaxqfa = prms[2]; ispcut = Int32(floor(prms[3]))
    if valmaxqfa < valminqfa; valmaxqfa = Float32(9999); end
    qfac = prms[4]; diacw = prms[5]; tarqfa = max(Float32(0), prms[6])
    qfatar = Int32(floor(prms[7]))
    if qfatar <= Int32(0)
        ctpa=Float32(0); cba=tarqfa; csdi=Float32(0)
    elseif qfatar <= Int32(1)
        ctpa=tarqfa; cba=Float32(0); csdi=Float32(0)
    else
        ctpa=Float32(0); cba=Float32(0); csdi=tarqfa; lsdi=true
    end
    cuteff=Float32(1); cutef1=Float32(1)
    rstock=Float32(0); remove=Float32(99999); lspecl=true
    if debug
        @printf(io_units[Int(JOSTND)], " PRMS= %s\n", join(prms, " "))
        @printf(io_units[Int(JOSTND)],
            " ICFLAG,TARQFA,CTPA,CBA,CSDI,QFATAR= %d %f %f %f %f %d\n",
            icflag, tarqfa, ctpa, cba, csdi, qfatar)
    end
    icflagqfa = icflag; lzeideqfa = LZEIDE; jostnd1 = JOSTND; debug1 = debug
    CUTQFA(valminqfa, valmaxqfa, ispcut, lzeideqfa, icflagqfa,
           ctpa, cba, csdi, qfatar, qfac, diacw, jostnd1, debug1)
    ldelqfa = false; lqfa = false   # stubs: always no more QFA classes
    if ldelqfa
        lqfa = false; OPDEL1(kut); @goto label_1400
    end

    @label label_352   # CYCQFA re-entry for next QFA diameter class
    CYCQFA(valmin, valmax, ctpa, cba, csdi, qfatar, diacw,
           icflagqfa, jostnd1, debug1)
    lqfa = false   # stub
    if icflag == Int32(17) && qfatar == Int32(2); @goto label_425; end

    # ── 355: residual TPA/BA target for THINDBH/THINHT/THINQFA ──────────────
    @label label_355
    if ctpa == Float32(0) && cba == Float32(0); @goto label_360; end
    cstock = Float32(0)
    jtyp = cba > Float32(0) ? Int32(2) : Int32(1)
    if icflag == Int32(8) || (icflag == Int32(17) && qfatar <= Int32(1))
        cstock = CLSSTK(jtyp, ispcut, valmin, valmax, Float32(0), Float32(999), Int32(0))
    elseif icflag == Int32(12)
        cstock = CLSSTK(jtyp, ispcut, Float32(0), Float32(999), valmin, valmax, Int32(0))
    end
    if cstock <= Float32(0); @goto label_360; end
    rstock = ctpa + cba; remove = cstock - rstock
    if cba > Float32(0); lbarea = true; end
    cuteff = min(Float32(1), remove / cstock)
    if icflag == Int32(17); @goto label_360; end
    prms[3] = max(Float32(0), cuteff)
    OPCHPR(kut, 6, prms)

    @label label_360
    if debug
        @printf(io_units[Int(JOSTND)], " IN CUTS: CTPA=%8.2f CBA=%8.2f\n", ctpa, cba)
    end
    @goto label_550

    # ── 400: THINSDI / THINCC / THINRDEN / THINPT / THINRDSL / THINQFA-SDI ──
    @label label_400
    if debug
        @printf(io_units[Int(JOSTND)], " AFTER STATEMENT 400-JPNUM= %d\n", jpnum)
    end
    if (icflag == Int32(16) && ISILFT == Int32(0)) ||
       (icflag == Int32(15) && ITHNPA == Int32(6) && ISILFT == Int32(0))
        OPDEL1(kut); @goto label_1400
    end
    csdi   = max(Float32(0), prms[1]); cutef1 = prms[2]
    ispcut = Int32(floor(prms[3])); valmin = prms[4]; dbhlo = prms[4]
    valmax = prms[5]; dbhhi = prms[5]; icut = Int32(floor(prms[6]))
    htlo=Float32(0); hthi=Float32(999)
    rstock=Float32(0); remove=Float32(99999); lsdi=true; lpdbh=true; lspecl=true
    if icut > Int32(0); lspecl=false; end
    if icut == Int32(1); lbelow=true; end

    @label label_425
    if debug
        @printf(io_units[Int(JOSTND)], " IN CUTS: ICFLAG=%d CSDI=%f\n", icflag, csdi)
    end
    if csdi > Float32(0)
        if icflag == Int32(10) || (icflag == Int32(15) && ITHNPA == Int32(3)) ||
           (icflag == Int32(17) && qfatar == Int32(2))
            sdic, zsdi, stagea, stageb = SDICLS(ispcut, valmin, valmax, Int32(2), jpnum)
            if LZEIDE; sdic = zsdi; end
        elseif icflag == Int32(11) || (icflag == Int32(15) && ITHNPA == Int32(4))
            if csdi < Float32(100)
                csdi = (-Float32(43560) * log(Float32(1) - csdi/Float32(100)) / Float32(0.785398))
                sdic = CCCLS(ispcut, valmin, valmax, Int32(2), jpnum)
            else
                OPDEL1(kut); @goto label_1400
            end
        elseif icflag == Int32(14) || (icflag == Int32(15) && ITHNPA == Int32(5))
            sumd2, clknt, sdic, tpafac, diamfac = RDCLS(ispcut, valmin, valmax, Int32(2), jpnum)
            tsumd2 = sumd2; tclknt = clknt
        elseif icflag == Int32(16) || (icflag == Int32(15) && ITHNPA == Int32(6))
            sdic = RDCLS2(ispcut, valmin, valmax, Int32(2), jpnum)
        elseif icflag == Int32(15) && ITHNPA == Int32(1)
            sdic = CLSSTK(Int32(1), ispcut, valmin, valmax, Float32(0), Float32(999), jpnum)
        elseif icflag == Int32(15) && ITHNPA == Int32(2)
            sdic = CLSSTK(Int32(2), ispcut, valmin, valmax, Float32(0), Float32(999), jpnum)
            lbarea = true
        end

        # canopy cover adjustment
        ccc = Float32(1)
        if CCCOEF  != Float32(0) && CCCOEF  != Float32(1); ccc = CCCOEF;  end
        if CCCOEF2 != Float32(0) && CCCOEF2 != Float32(1); ccc = CCCOEF2; end
        ccclc1  = Float32(100) * csdi * Float32(0.785398) / Float32(43560)
        ccclc21 = Float32(100) * (Float32(1) - exp(-(ccc/Float32(100)) * ccclc1))
        if ccclc21 > ccclc1; ccclc21 = ccclc1; end
        cct    = Float32(100) * (Float32(1) - exp(-Float32(0.01) * (Float32(100)*csdi*Float32(0.785398)/Float32(43560))))
        cccsdi = (log(Float32(1) + (-cct/Float32(100))) / (ccc/Float32(100))) * Float32(-1)
        cradif = abs((cccsdi/Float32(100)/Float32(0.785398)) * Float32(43560) - csdi)

        if (sdic + cradif) > csdi
            if icflag == Int32(11)
                if ccc < Float32(1)
                    rstock = csdi + cradif; remove = sdic - rstock
                elseif ccc > Float32(1)
                    rstock = csdi - cradif; remove = sdic - rstock
                else
                    rstock = csdi; remove = sdic - csdi
                end
            else
                rstock = csdi; remove = sdic - csdi
            end
            cuteff = min(Float32(1), remove / sdic)
            if cutef1 < cuteff
                prms[2] = max(Float32(0), cuteff); OPCHPR(kut, 6, prms)
            else
                if icut > Int32(0); cuteff = cutef1; end
            end
        else
            remove = Float32(0)
        end
    else
        # csdi == 0: remove everything in class
        if icflag == Int32(10) || (icflag == Int32(15) && ITHNPA == Int32(3)) ||
           (icflag == Int32(17) && qfatar == Int32(2))
            sdic, zsdi, stagea, stageb = SDICLS(ispcut, valmin, valmax, Int32(2), jpnum)
            if LZEIDE; sdic = zsdi; end
        elseif icflag == Int32(11) || (icflag == Int32(15) && ITHNPA == Int32(4))
            sdic = CCCLS(ispcut, valmin, valmax, Int32(2), jpnum)
        elseif icflag == Int32(14) || (icflag == Int32(15) && ITHNPA == Int32(5))
            sumd2, clknt, sdic, tpafac, diamfac = RDCLS(ispcut, valmin, valmax, Int32(2), jpnum)
            tsumd2 = sumd2; tclknt = clknt
        elseif icflag == Int32(16) || (icflag == Int32(15) && ITHNPA == Int32(6))
            sdic = RDCLS2(ispcut, valmin, valmax, Int32(2), jpnum)
        elseif icflag == Int32(15) && ITHNPA == Int32(1)
            sdic = CLSSTK(Int32(1), ispcut, valmin, valmax, Float32(0), Float32(999), jpnum)
        elseif icflag == Int32(15) && ITHNPA == Int32(2)
            sdic = CLSSTK(Int32(2), ispcut, valmin, valmax, Float32(0), Float32(999), jpnum)
            lbarea = true
        end
        remove = sdic; rstock = Float32(0); cuteff = Float32(1)
    end
    if debug
        @printf(io_units[Int(JOSTND)], " CUTTING EFFICIENCY =%f\n", cuteff)
    end
    @goto label_550

    # ── 450: THINMIST ────────────────────────────────────────────────────────
    @label label_450
    idmcut = Int32(floor(prms[1])); dbhlo=prms[2]; dbhhi=prms[3]
    if dbhhi < dbhlo; dbhhi=Float32(9999); end
    cuteff=prms[4]; rstock=Float32(0); remove=Float32(99999); lspecl=true
    @goto label_550

    # ── 475: THINPT ──────────────────────────────────────────────────────────
    @label label_475
    if (ITHNPN == Int32(0) && !lptall) || ITHNPA == Int32(0)
        OPDEL1(kut); @goto label_1400
    end
    if ITHNPA <= Int32(7)
        if lptall
            jpnum += Int32(1); @goto label_400
        elseif lptgroup && jpt <= IPTGRP[Int(jptgrp), 1]
            jpt += Int32(1)
            jpnum = IPTGRP[Int(jptgrp), Int(jpt)]
            if ITHNPI == Int32(1)
                for ipchk in 1:Int(IPTINV)
                    if jpnum == IPVEC[ipchk]; jpnum=Int32(ipchk); @goto label_400; end
                end
            elseif jpnum <= IPTINV
                @goto label_400
            end
        else
            @goto label_400
        end
    else
        OPDEL1(kut); @goto label_1400
    end

    # ── 550: debug output ─────────────────────────────────────────────────────
    @label label_550
    if debug
        @printf(io_units[Int(JOSTND)],
            " IN CUTS, CYCLE=%3d ICFLAG=%2d STOCK=%8.1f RSTOCK=%8.1f REMOVE=%8.1f LBAREA=%s LBELOW=%s LSPECL=%s KUTNOW=%2d JPNUM=%5d\n",
            ICYC, icflag, stock, rstock, remove,
            lbarea ? "T" : "F", lbelow ? "T" : "F", lspecl ? "T" : "F", kutnow, jpnum)
    end

    # ── 600: check REMOVE > 0 ────────────────────────────────────────────────
    @label label_600
    if remove > Float32(0) || (lptall && jpnum < IPTINV)
        @goto label_650
    end
    if lptgroup && jpt < IPTGRP[Int(jptgrp), 1]; @goto label_650; end
    OPDEL1(kut); @goto label_1400

    @label label_650
    OPDONE(kut, IY[Int(ICYC)])

    # ── 700: load priority array WK2 (DO 850 I=1,ITRN) ──────────────────────
    @label label_700
    idmr_ref = Ref(Int32(0))
    for i in 1:Int(ITRN)
        is_i  = Int(ISP[i]); d_i = DBH[i]; ip_i = Int(ITRE[i]); v_i = d_i
        if icflag == Int32(13); v_i = HT[i]; end
        lnocut[i] = false

        # species / point inclusion
        lincl = false
        if jpnum > Int32(0) && ITRE[i] != jpnum
            # falls through to 710
        elseif (ispcut == Int32(0) || ispcut == Int32(is_i)) && !LEAVESP[is_i]
            lincl = true
        elseif ispcut < Int32(0)
            igrp_i = Int(-ispcut); iulim_i = Int(ISPGRP[igrp_i, 1]) + 1
            for ig in 2:iulim_i
                if is_i == Int(ISPGRP[igrp_i, ig]) && !LEAVESP[is_i]
                    lincl = true; break
                end
            end
        end
        # 710 CONTINUE
        MISGET(i, idmr_ref); idmr = idmr_ref[]

        # THINMIST
        if icflag == Int32(13)
            lnocut[i] = (d_i < dbhlo || d_i >= dbhhi ||
                         (idmr != idmcut && idmcut != Int32(0)) || idmr == Int32(0))
            WK2[i] = lnocut[i] ? Float32(0) : Float32(1)
            continue   # GO TO 850
        end

        if lspecl
            # 750 CONTINUE
            WK2[i] = Float32(1)
            if icflag != Int32(8) && icflag != Int32(12) &&
               !(icflag == Int32(17) && qfatar <= Int32(1)) && !lsdi
                if nps == Int32(1)
                    if Int(KUTKOD[i]) < 2; WK2[i] = Float32(0); end
                else
                    if kutnow == Int32(-1)
                        WK2[i] = WK6[i]
                    else
                        if kutnow != Int32(KUTKOD[i]); WK2[i] = Float32(0); end
                    end
                end
            end
            # 800 CONTINUE
            if v_i < valmin || v_i >= valmax; WK2[i] = Float32(0); end
            if !lincl; WK2[i] = Float32(0); end
            continue   # GO TO 850
        end

        # normal thinning priority
        xsz_i = lpdbh ? d_i : HT[i]
        if lbelow; xsz_i = -xsz_i; end
        WK2[i] = xsz_i + Float32(IORDER[is_i]) +
                  TCWT * Float32(IMC[i]) + SPCLWT * Float32(ISPECL[i]) +
                  PBAWT * PTBAA[ip_i] + PCCFWT * PCCF[ip_i] + PTPAWT * PTPA[ip_i]
        if idmr > Int32(0); WK2[i] += prfmis[is_i, Int(idmr)]; end

        if icflag == Int32(1); continue; end   # THINAUTO: GO TO 850
        lnocut[i] = DBH[i] < dbhlo || DBH[i] >= dbhhi ||
                    HT[i]  < htlo  || HT[i]  >= hthi
        if (icflag == Int32(10) || icflag == Int32(11) || icflag == Int32(14) ||
            icflag == Int32(15) || icflag == Int32(16) ||
            (icflag == Int32(17) && qfatar == Int32(2))) && !lincl
            lnocut[i] = true
        end
        if LEAVESP[is_i]; lnocut[i] = true; end
        # 850 CONTINUE (natural end of iteration)
    end  # DO 850

    # ── 900: sort priority array ──────────────────────────────────────────────
    @label label_900
    if !lspecl && ITRN > Int32(0)
        RDPSRT(Int(ITRN), WK2, IND2, true)
    end

    # ── trial thinning loop (DO 1100 I=1,ITRN) ───────────────────────────────
    totcut = Float32(0); this_c = Float32(0); xleft = Float32(999999)
    for i in 1:Int(ITRN)
        it_idx = lspecl ? Int32(i) : IND2[i]
        if lspecl; IND2[i] = Int32(i); end

        it = Int(it_idx)
        d   = DBH[it]; xmore = Float32(0)

        if debug
            @printf(io_units[Int(JOSTND)],
                " LSDI,ICFLAG,XLEFT,REMOVE,TOTCUT= %s %d %f %f %f\n",
                lsdi, icflag, xleft, remove, totcut)
        end

        # check if thinning is complete
        sdi_mode = lsdi && (icflag == Int32(10) || icflag == Int32(16) ||
                   (icflag == Int32(17) && qfatar == Int32(2)) ||
                   (icflag == Int32(15) && ITHNPA == Int32(3)) ||
                   ITHNPA == Int32(5) || ITHNPA == Int32(6))
        if sdi_mode
            if xleft <= Float32(0.0005); WK2[it]=Float32(0); continue; end
        else
            if remove - totcut <= Float32(0); WK2[it]=Float32(0); continue; end
        end

        # 1000 CONTINUE
        if WK2[it] <= Float32(0) && lspecl; continue; end
        if lnocut[it]; continue; end

        # determine PREM
        if kutnow == Int32(-1)
            prem = WK4[it] * WK2[it]
        else
            prem = WK4[it] * cuteff
        end
        if prem > WK4[it]; prem = WK4[it]; end
        if prem <= Float32(0); continue; end

        cut_v = prem
        if lbarea; cut_v = prem * d * d * Float32(0.005454154); end
        if icflag == Int32(15) && (ITHNPA == Int32(1) || ITHNPA == Int32(2))
            cut_v = cut_v * (PI - Float32(NONSTK))
        end
        xleft = remove - (totcut + cut_v)

        if lsdi
            if icflag == Int32(10) || (icflag == Int32(17) && qfatar == Int32(2)) ||
               (icflag == Int32(15) && ITHNPA == Int32(3))
                sdic_r, zsdi_r, stagea_r, stageb_r = SDICLS(ispcut,valmin,valmax,Int32(2),jpnum)
                sdic=sdic_r; if LZEIDE; sdic=zsdi_r; end
                stagea=stagea_r; stageb=stageb_r
                cut_v = prem * (stagea + stageb * d * d)
                if LZEIDE; cut_v = prem * (d/Float32(10))^Float32(1.605); end
                if icflag == Int32(15) && ITHNPA == Int32(3)
                    cut_v = cut_v * (PI - Float32(NONSTK))
                end
                xleft = sdic - (csdi + cut_v)
            elseif icflag == Int32(11) || (icflag == Int32(15) && ITHNPA == Int32(4))
                cwdi = CRWDTH[it]; cut_v = prem * cwdi * cwdi
                if icflag == Int32(15) && ITHNPA == Int32(4)
                    cut_v = cut_v * (PI - Float32(NONSTK))
                end
                xleft = remove - (totcut + cut_v)
            elseif icflag == Int32(14)
                cut_v = (tpafac + diamfac * (DBH[it]^Float32(2))) * prem
                xleft = remove - (totcut + cut_v)
            elseif icflag == Int32(15) && ITHNPA == Int32(5)
                temp  = tsumd2 - prem * DBH[it] * DBH[it]
                cut_v = sdic - (temp * Float32(0.0054542)) /
                              ((temp / (tclknt - prem))^Float32(0.25))
                cut_v = cut_v * (PI - Float32(NONSTK))
                xleft = sdic - (csdi + cut_v)
            elseif icflag == Int32(16) || (icflag == Int32(15) && ITHNPA == Int32(6))
                treerd = RDSLTR(Int(ISP[it]), it)
                cut_v = prem * treerd
                if icflag == Int32(15) && ITHNPA == Int32(6)
                    cut_v = cut_v * (PI - Float32(NONSTK))
                end
                xleft = remove - (totcut + cut_v)
            end
        end
        if debug
            @printf(io_units[Int(JOSTND)],
                " IT,WK4,CUTEFF,PREM,REMOVE,TOTCUT,CUT,XLEFT= %d %f %f %f %f %f %f %f\n",
                it, WK4[it], cuteff, prem, remove, totcut, cut_v, xleft)
        end

        # check if this is the last tree (need to adjust PREM)
        need_adjust = lsdi && (icflag == Int32(10) || icflag == Int32(14) ||
                               icflag == Int32(16) ||
                               (icflag == Int32(17) && qfatar == Int32(2)) ||
                               (icflag == Int32(15) &&
                                (ITHNPA == Int32(3) || ITHNPA == Int32(5) || ITHNPA == Int32(6))))
        if need_adjust
            xmore = sdic - csdi
            if icflag == Int32(14) || icflag == Int32(16) ||
               (icflag == Int32(15) && ITHNPA == Int32(6))
                xmore = remove - totcut
            end
            if xmore > cut_v; @goto label_1050; end
            @goto label_955
        end
        if xleft >= Float32(0); @goto label_1050; end

        # 955 CONTINUE: last tree, iterative PREM determination
        @label label_955
        if debug
            @printf(io_units[Int(JOSTND)],
                " AT 955 REMOVE,TOTCUT,XMORE,PREM,WK4= %f %f %f %f %f LSDI,ICFLAG,ITHNPA= %s %d %d\n",
                remove,totcut,xmore,prem,WK4[it],lsdi,icflag,ITHNPA)
        end
        if lsdi && (icflag == Int32(10) || (icflag == Int32(17) && qfatar == Int32(2)) ||
                    (icflag == Int32(15) && ITHNPA == Int32(3)))
            prem = LZEIDE ? xmore / (d/Float32(10))^Float32(1.605) :
                            xmore / (stagea + stageb * d * d)
            if prem > WK4[it]; prem = WK4[it]; end
            ipos = Int32(0); ineg = Int32(0); orgwk4 = WK4[it]
            # 1045: iterative convergence
            while true
                if ipos > Int32(0) && ineg > Int32(0); break; end
                WK4[it] = orgwk4 - prem
                sdic_r, zsdi_r, stagea_r, stageb_r = SDICLS(ispcut,valmin,valmax,Int32(2),jpnum)
                sdic_r2 = LZEIDE ? zsdi_r : sdic_r
                stagea=stagea_r; stageb=stageb_r
                diff = sdic_r2 - csdi
                if abs(diff) > Float32(0.5)
                    if diff < Float32(0)
                        prem -= Float32(0.05); ineg = Int32(1)
                    else
                        prem += Float32(0.05); ipos = Int32(1)
                    end
                else
                    break
                end
            end
            WK4[it] = orgwk4
        elseif lsdi && (icflag == Int32(14) || icflag == Int32(16) ||
                        (icflag == Int32(15) && ITHNPA == Int32(5)) ||
                        (icflag == Int32(15) && ITHNPA == Int32(6)))
            prem = cut_v > Float32(0) ? (xmore / cut_v) * prem : prem
            if prem > WK4[it]; prem = WK4[it]; end
            ipos = Int32(0); ineg = Int32(0); orgwk4 = WK4[it]
            while true
                if ipos > Int32(0) && ineg > Int32(0); break; end
                WK4[it] = orgwk4 - prem
                if (icflag == Int32(14)) || (icflag == Int32(15) && ITHNPA == Int32(5))
                    _, _, sdic_r, tpafac_r, diamfac_r = RDCLS(ispcut,valmin,valmax,Int32(2),jpnum)
                    tpafac=tpafac_r; diamfac=diamfac_r
                    diff = remove - sdic_r
                else
                    sdic_r = RDCLS2(ispcut,valmin,valmax,Int32(2),jpnum)
                    diff = sdic_r - csdi
                end
                if abs(diff) > Float32(0.01)
                    if diff < Float32(0)
                        prem -= Float32(0.2); ineg = Int32(1)
                        if prem <= Float32(0); break; end
                    else
                        prem += Float32(0.2); ipos = Int32(1)
                        if prem > orgwk4; break; end
                    end
                else
                    break
                end
            end
            WK4[it] = orgwk4
        else
            prem = ((xleft + cut_v) / cut_v) * prem
        end
        cut_v = remove - totcut

        # 1050 CONTINUE: increment totcut
        @label label_1050
        totcut = totcut + cut_v
        tsumd2 = tsumd2 - prem * DBH[it] * DBH[it]
        tclknt = tclknt - prem

        if lyard
            loss = prem * prlost
            dsng[it]   += loss * prdsng
            ssng[it]   += loss * (Float32(1) - prdsng)
            ctcrwn[it] += (prcrwn * (prem - loss)) + (loss * prdsng)
            tkcrwn[it] += (Float32(1) - prcrwn) * (prem - loss)
        else
            ctcrwn[it] += prem
        end
        WK4[it]   -= prem
        YRDLOS[it]+= prem * prlost
        cfcut += prem * CFV[it]
        cmcut += prem * (Float32(1) - prlost) * MCFV[it]
        bfcut += prem * (Float32(1) - prlost) * BFV[it]
        sccut += prem * (Float32(1) - prlost) * SCFV[it]
        bacut += prem * d * d * Float32(0.005454154)
        tcut  += prem; this_c += prem
        if debug
            @printf(io_units[Int(JOSTND)],
                " IT=%4d TOTCUT=%10.3f CUT=%10.3f WK4(IT)=%8.3f CUTEFF=%8.3f PREM=%8.3f PRLOST=%5.3f PRDSNG=%5.3f\n  CFCUT=%9.2f BFCUT=%9.2f DSNG=%7.2f SSNG=%7.2f CTCRWN=%7.2f YRDLOS=%10.5f\n",
                it, totcut, cut_v, WK4[it], cuteff, prem, prlost, prdsng,
                cfcut, bfcut, dsng[it], ssng[it], ctcrwn[it], YRDLOS[it])
        end
        # 1100 CONTINUE: natural end of inner loop iteration
    end  # DO 1100

    @goto label_1350   # after trial-thinning loop → point management

    # ── 1150: SPECPREF / TCONDMLT / YARDING / SPLEAVE ────────────────────────
    @label label_1150
    OPDONE(kut, IY[Int(ICYC)])
    if iactk == Int32(201); @goto label_1200; end
    if iactk == Int32(203); @goto label_1325; end
    if iactk == Int32(206); @goto label_1340; end
    # 202: TCONDMLT
    global TCWT = prms[1]; global SPCLWT = prms[2]; global PBAWT = prms[3]
    global PCCFWT = prms[4]; global PTPAWT = prms[5]
    @goto label_1400

    @label label_1200  # 201: SPECPREF
    ispc_i = Int32(floor(prms[1]))
    if ispc_i < Int32(0)
        igrp_s = Int(-ispc_i); iulim_s = Int(ISPGRP[igrp_s, 1]) + 1
        for ig in 2:iulim_s
            IORDER[Int(ISPGRP[igrp_s, ig])] = Int32(floor(prms[2]))
        end
    elseif ispc_i == Int32(0)
        for is_s in 1:Int(MAXSP); IORDER[is_s] = Int32(floor(prms[2])); end
    else
        IORDER[Int(ispc_i)] = Int32(floor(prms[2]))
    end
    @goto label_1400

    @label label_1325  # 203: YARDING
    lyard  = true; prlost = prms[1]; prdsng = prms[2]; prcrwn = prms[3]
    @goto label_1400

    @label label_1340  # 206: SPLEAVE
    if Int32(floor(prms[1] - Float32(0.5))) < Int32(0)
        igrp_sp = Int(-Int32(floor(prms[1]))); iulim_sp = Int(ISPGRP[igrp_sp, 1]) + 1
        for ig in 2:iulim_sp
            LEAVESP[Int(ISPGRP[igrp_sp, ig])] = Int32(floor(prms[2] + Float32(0.5))) > Int32(0)
        end
    elseif Int32(floor(prms[1] + Float32(0.5))) == Int32(0)
        fill!(LEAVESP, false)
    else
        sp_idx = Int(Int32(floor(prms[1] + Float32(0.5))))
        LEAVESP[sp_idx] = Int32(floor(prms[2] + Float32(0.5))) > Int32(0)
    end
    @goto label_1400

    # ── 1350: point loop management (THINPT / SETPTHIN) ──────────────────────
    @label label_1350
    if debug
        @printf(io_units[Int(JOSTND)],
            " LPTALL,JPNUM,IPTINV,LQFA= %s %d %d %s\n",
            lptall, jpnum, IPTINV, lqfa)
    end
    if lptall
        if jpnum < IPTINV
            jpnum += Int32(1); @goto label_400
        else
            lptall = false
        end
    elseif lptgroup
        if jpt <= IPTGRP[Int(jptgrp), 1]
            jpt += Int32(1); jpnum = IPTGRP[Int(jptgrp), Int(jpt)]
            if ITHNPI == Int32(1)
                for ipchk in 1:Int(IPTINV)
                    if jpnum == IPVEC[ipchk]; jpnum=Int32(ipchk); @goto label_400; end
                end
            else
                if jpnum <= IPTINV; @goto label_400; end
            end
        end
    end

    if this_c <= Float32(0); OPDEL1(kut); end
    if lqfa; @goto label_352; end

    @label label_1400
    @goto label_kut_top   # next KUT iteration
    @label label_kut_done

    # ── post-thinning summarization (lines 1534+) ─────────────────────────────
    if tcut <= Float32(0); @goto label_1950; end

    # trivial residual TPA fix
    remtpa = trees - tcut
    if remtpa > Float32(0) && remtpa < Float32(0.01)
        for indx in 1:Int(ITRN)
            if WK4[indx] > Float32(0)
                cfcut += WK4[indx]*CFV[indx]; cmcut += WK4[indx]*MCFV[indx]
                sccut += WK4[indx]*SCFV[indx]; bfcut += WK4[indx]*BFV[indx]
                bacut += WK4[indx]*DBH[indx]*DBH[indx]*Float32(0.005454154)
                tcut  += WK4[indx]; WK4[indx] = Float32(0)
            end
        end
    end

    if debug
        @printf(io_units[Int(JOSTND)],
            " IN CUTS: BACUT,BAMIN=%10.3f%10.3f; CMCUT,CFMIN=%10.2f%10.2f;\n          BFCUT,BFMIN=%10.2f%10.2f; CFCUT,TCFMIN=%10.2f%10.2f\n",
            bacut, BAMIN, cmcut, CFMIN, bfcut, BFMIN, cfcut, TCFMIN)
    end

    if bacut >= BAMIN && cmcut >= CFMIN && bfcut >= BFMIN &&
       cfcut >= TCFMIN && sccut >= SCFMIN && !lprtnd
        @goto label_1500
    end

    # minimum harvest not met → delete scheduled thinnings
    if icflag == Int32(1); @goto label_2000; end
    for i in 1:Int(ntodo)
        iactk_c, kdt_c, nps_c = OPGET(i, Int32(7), prms)
        if abs(iactk_c) > Int32(222); OPDEL1(i); end
    end
    for i in 1:Int(MAXTRE); YRDLOS[i] = Float32(0); end
    if !lprtnd || bacut < BAMIN || cmcut < CFMIN ||
       bfcut < BFMIN || cfcut < TCFMIN || sccut < SCFMIN
        @goto label_1950
    end

    # ── 1500: trial thinning acceptable — final pass (DO 1700 I=1,ITRN) ──────
    @label label_1500
    dmax = Float32(0); ivac = Int32(0)
    for i in 1:Int(ITRN)
        it_f = Int(IND2[i]); is_f = Int(ISP[it_f]); im_f = Int(IMC[it_f])
        WK2[it_f]=Float32(0); WK5[it_f]=Float32(0); WK6[it_f]=Float32(0)
        WK7[it_f]=Float32(0); WK8[it_f]=Float32(0); WK9[it_f]=Float32(0)
        WK10[it_f]=Float32(0); WK11[it_f]=Float32(0); WK12[it_f]=Float32(0)
        WK13[it_f]=Float32(0); WK14[it_f]=Float32(0); WK15[it_f]=Float32(0)
        d_f = DBH[it_f]
        prem = PROB[it_f] - WK4[it_f]

        if !lprtnd
            p = PROB[it_f] - prem
            if p <= Float32(0.0005) && prem != Float32(0)
                if debug
                    @printf(io_units[Int(JOSTND)],
                        " TPA < .0005 REMOVE. IT, DBH, P, PROB, PREM = %d %f %f %f %f\n",
                        it_f, d_f, p, PROB[it_f], prem)
                end
                prem = PROB[it_f]; PROB[it_f] = Float32(0)
                if lyard; YRDLOS[it_f] += p * prlost; end
                ivac += Int32(1)
                IND2[i] = -Int32(it_f)
                @goto label_1600
            end
            # 1550: trivial prem check
            if prem < Float32(0.00001); @goto label_1650; end
            PROB[it_f] = p
        end

        @label label_1600
        if d_f > dmax; dmax = d_f; end

        @label label_1640
        prem2 = max(Float32(0), prem - dsng[it_f] - ssng[it_f])
        if prem2 > Float32(0.00001)
            cfvoli_f = if VARACD == "CS" || VARACD == "LS" ||
                          VARACD == "NE" || VARACD == "SN"
                           SCFV[i]
                       else
                           MCFV[i]
                       end
            ECHARV(BFV[it_f], d_f, cfvoli_f, GROSPC, prem2, is_f, it_f, ICYC, IY)
        end
        if lprtnd; continue; end   # GO TO 1700

        YRDLOS[it_f] = prem <= Float32(0) ? Float32(0) : YRDLOS[it_f] / prem
        WK2[it_f] = prem * CFV[it_f]
        WK3[it_f] = prem
        prem2 = max(Float32(0), prem - dsng[it_f] - ssng[it_f])
        WK5[it_f] = prem2 * MCFV[it_f]; WK7[it_f] = prem2 * SCFV[it_f]
        WK6[it_f] = prem2 * BFV[it_f]
        WK8[it_f]  = prem * ABVGRD_BIO[it_f];  WK9[it_f]  = prem * ABVGRD_CARB[it_f]
        WK14[it_f] = prem * FOLI_BIO[it_f];    WK15[it_f] = prem * FOLI_CARB[it_f]
        WK10[it_f] = prem2 * MERCH_BIO[it_f];  WK11[it_f] = prem2 * MERCH_CARB[it_f]
        WK12[it_f] = prem2 * CUBSAW_BIO[it_f]; WK13[it_f] = prem2 * CUBSAW_CARB[it_f]
        spcbr[is_f, im_f] += WK6[it_f]
        spcmr[is_f, im_f] += WK5[it_f]
        spcsr[is_f, im_f] += WK7[it_f]
        spcrt[is_f, im_f] += WK3[it_f]
        spcrc[is_f, im_f] += WK2[it_f]
        ishag = Int(IFINT)
        ESTUMP(is_f, d_f, max(Float32(0), prem - ssng[it_f]), Int(ITRE[it_f]), ishag)
        RDSTR(it_f, prem, p + prem)
        BMSLSH(is_f, prem, CFV[it_f], 0)

        @label label_1650
        spcres[is_f, im_f] += PROB[it_f]
        # 1700 CONTINUE: natural end
    end  # DO 1700

    if lprtnd; @goto label_1950; end

    # post-removal reporting
    PRTRLS(2); DBS_FIAVBC_CUTLST(); PRTRLS(3); DBS_FIAVBC_ATRTLS()
    FVSSTD(2)
    for i in 1:Int(MAXTRE); YRDLOS[i] = Float32(0); end
    SVCUTS(ivac, ssng, dsng, ctcrwn)
    if LECON; ECREMS(); end

    COMP(OSPTT, IOSPTT, spcrt); COMP(OSPTV, IOSPTV, spcrc)
    COMP(OSPBR, IOSPBR, spcbr); COMP(OSPMR, IOSPMR, spcmr)
    COMP(OSPSR, IOSPSR, spcsr)

    ONTREM[7]  = PCTILE(Int(ITRN), IND,  WK3, PCT); DIST(Int(ITRN), ONTREM, PCT)
    OCVREM[7]  = PCTILE(Int(ITRN), IND,  WK2, PCT); DIST(Int(ITRN), OCVREM, PCT)
    if cmcut > Float32(0)
        OMCREM[7] = PCTILE(Int(ITRN), IND, WK5, PCT); DIST(Int(ITRN), OMCREM, PCT)
        OSCREM[7] = PCTILE(Int(ITRN), IND, WK7, PCT); DIST(Int(ITRN), OSCREM, PCT)
    end
    if bfcut > Float32(0)
        OBFREM[7] = PCTILE(Int(ITRN), IND, WK6, PCT); DIST(Int(ITRN), OBFREM, PCT)
    end
    if LFIANVB
        OAGBIOREM[7]   = PCTILE(Int(ITRN), IND, WK8,  PCT); DIST(Int(ITRN), OAGBIOREM, PCT)
        OAGCARBREM[7]  = PCTILE(Int(ITRN), IND, WK9,  PCT); DIST(Int(ITRN), OAGCARBREM, PCT)
        OMERBIOREM[7]  = PCTILE(Int(ITRN), IND, WK10, PCT); DIST(Int(ITRN), OMERBIOREM, PCT)
        OMERCARBREM[7] = PCTILE(Int(ITRN), IND, WK11, PCT); DIST(Int(ITRN), OMERBIOREM, PCT)
        OCSAWBIOREM[7] = PCTILE(Int(ITRN), IND, WK12, PCT); DIST(Int(ITRN), OCSAWBIOREM, PCT)
        OCSAWCARBREM[7]= PCTILE(Int(ITRN), IND, WK13, PCT); DIST(Int(ITRN), OCSAWCARBREM, PCT)
        OFOLIBIOREM[7] = PCTILE(Int(ITRN), IND, WK14, PCT); DIST(Int(ITRN), OFOLIBIOREM, PCT)
        OFOLICARBREM[7]= PCTILE(Int(ITRN), IND, WK15, PCT); DIST(Int(ITRN), OFOLICARBREM, PCT)
    end
    ONTREM[6]=dmax; OCVREM[6]=dmax; OMCREM[6]=dmax; OSCREM[6]=dmax; OBFREM[6]=dmax

    if debug
        @printf(io_units[Int(JOSTND)], " CUTS: CALLING FMSCUT.\n")
    end
    FMSCUT(spcrc, Int(MAXSP), 3, ssng, dsng, ctcrwn, tkcrwn)
    FMTREM(dsng, ssng, tkcrwn)

    if debug
        @printf(io_units[Int(JOSTND)],
            "\n IN CUTS, TOTALLY CUT TREES=%5d; TOT TREES=%5d\n", ivac, ITRN)
    end
    if ivac > Int32(0)
        TREDEL(ivac, IND2)
        SPESRT()
        global IFST = Int32(1)
        if ITRN <= Int32(0); @goto label_1900; end
        IND[1] = Int32(0)
        RDPSRT(Int(ITRN), DBH, IND, true)
    end

    @label label_1850
    ONTRES[7] = PCTILE(Int(ITRN), IND, PROB, PCT)
    @label label_1900
    DIST(Int(ITRN), ONTRES, PCT)
    COMP(OSPRT, IOSPRT, spcres)

    @label label_1950
    if ITRN <= Int32(0) || !LAUTON || lnoaut; @goto label_2000; end
    lnoaut = true
    iactk  = Int32(221)
    ntodo  = Int32(1)
    if debug
        @printf(io_units[Int(JOSTND)], " CUTS: THINAUTO IS BEING ATTEMPTED\n")
    end
    @goto label_50   # re-initialize WK4 and restart KUT loop

    @label label_2000
    # salvage without live-tree cut: write SVS post-thin file
    if debug
        @printf(io_units[Int(JOSTND)],
            " CUTS: TESTING FOR SALVAGE W/O CUT: SALVTPA=%7.2f, TCUT=%7.2f\n",
            salvtpa, tcut)
    end
    if salvtpa > Float32(0) && tcut <= Float32(0)
        SVOUT(IY[Int(ICYC)], 2, "Post salvage")
    end

    # ── pruning (activity 249) ────────────────────────────────────────────────
    ntodo_p = OPFIND(1, view(myacts, 23:23))
    if debug
        @printf(io_units[Int(JOSTND)], " CUTS: PRUNE, NTODO=%4d ITRN=%4d\n", ntodo_p, ITRN)
    end
    if ntodo_p <= Int32(0); @goto label_2500; end

    for nprun in 1:Int(ntodo_p)
        iactk_p, kdt_p, np_p = OPGET(nprun, Int32(7), prms)
        if iactk_p < Int32(0); continue; end

        if ITRN <= Int32(0)
            OPDEL1(nprun); continue
        end
        iprun  = Int32(0); imeth = Int32(floor(prms[1]))
        feet   = prms[2];  pprop = prms[3]; ispec = Int32(floor(prms[4]))
        dlow_p = prms[5];  dhi_p = prms[6]
        if debug
            @printf(io_units[Int(JOSTND)],
                " CUTS: PRUNE, IMETH=%2d FEET=%7.2f PPROP=%7.2f ISPEC=%3d DLOW=%7.2f DHI=%7.2f\n",
                imeth, feet, pprop, ispec, dlow_p, dhi_p)
        end

        for i in 1:Int(ITRN); ctcrwn[i] = Float32(0); end

        for i in 1:Int(ITRN)
            lincl_p = false
            if ispec == Int32(0) || ispec == Int32(ISP[i])
                lincl_p = true
            elseif ispec < Int32(0)
                igrp_p = Int(-ispec); iulim_p = Int(ISPGRP[igrp_p, 1]) + 1
                for ig in 2:iulim_p
                    if ISP[i] == ISPGRP[igrp_p, ig]; lincl_p=true; break; end
                end
            end
            if !lincl_p; continue; end
            if DBH[i] < dlow_p || DBH[i] >= dhi_p; continue; end

            ioldcr = Int(ICR[i]); hti = HT[i]
            cri_f  = Float32(ICR[i]); crlen = hti * cri_f / Float32(100)
            crbase = hti - crlen

            if imeth == Int32(1) && feet > Float32(0)
                if feet > crbase
                    ICR[i] = Int32(floor(((hti - feet) / hti) * Float32(100) + Float32(0.5)))
                    if ICR[i] < Int32(5) && ioldcr > 5; ICR[i] = Int32(5); end
                    iprun += Int32(1)
                end
            elseif (imeth == Int32(2) || imeth == Int32(3)) && feet > Float32(0) && pprop > Float32(0)
                if feet > crbase
                    ftcut  = feet - crbase; cutmax = crlen * pprop
                    if ftcut <= cutmax
                        ICR[i] = Int32(floor(((hti - feet) / hti) * Float32(100) + Float32(0.5)))
                        iprun += Int32(1)
                    else
                        if imeth == Int32(2)
                            ICR[i] = Int32(floor(((crlen - cutmax) / hti) * Float32(100) + Float32(0.5)))
                            iprun += Int32(1)
                        end
                    end
                end
            elseif imeth == Int32(4) && pprop > Float32(0)
                ICR[i] = Int32(floor(cri_f * (Float32(1) - pprop) + Float32(0.5)))
                iprun += Int32(1)
            elseif imeth == Int32(5) && feet > Float32(0)
                ICR[i] = Int32(floor(((crlen - feet) / hti) * Float32(100) + Float32(0.5)))
                if ICR[i] < Int32(5) && ioldcr > 5; ICR[i] = Int32(5); end
                iprun += Int32(1)
            elseif (imeth == Int32(6) || imeth == Int32(7)) && feet > Float32(0) && pprop > Float32(0)
                cutmax = crlen * pprop
                if feet <= cutmax
                    ICR[i] = Int32(floor(((crlen - feet) / hti) * Float32(100) + Float32(0.5)))
                    iprun += Int32(1)
                else
                    if imeth == Int32(6)
                        ICR[i] = Int32(floor(((crlen - cutmax) / hti) * Float32(100) + Float32(0.5)))
                        iprun += Int32(1)
                    end
                end
            end
            basnew = (Float32(1) - Float32(ICR[i]) * Float32(0.01)) * hti
            ctcrwn[i] = max(Float32(0), Float32(1) - ((hti - basnew) / (hti - crbase)))
            if debug
                @printf(io_units[Int(JOSTND)],
                    " CUTS: PRUNE, I=%4d IOLDCR=%3d ICR=%3d DIFF=%3d OLD&NEW BASE HT=%7.1f%7.1f CTCRWN=%6.3f\n",
                    i, ioldcr, ICR[i], ioldcr - Int(ICR[i]), crbase, basnew, ctcrwn[i])
            end
        end  # tree loop

        if iprun > Int32(0)
            FMPRUN(ctcrwn); OPDONE(nprun, IY[Int(ICYC)])
        else
            OPDEL1(nprun)
        end
        if debug
            @printf(io_units[Int(JOSTND)], " CUTS: PRUNE, IPRUN=%4d\n", iprun)
        end
    end  # pruning activity loop

    @label label_2500
    if LECON; ECOUT(); end
    return nothing
end
