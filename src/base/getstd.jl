# base/getstd.jl — GETSTD: deserialize FVS stand state from stash buffer
# Translated from: bin/FVSsn_buildDir/getstd.f (900 lines)
#
# Reads integer, logical, and real scalars/arrays from WK3 via
# IFREAD/LFREAD/BFREAD (defined in putgetsubs.jl).
# Called at each stop/restart restore point.
#
# EQUIVALENCE translations (see putstd.jl for encoding):
#   ROSUM(20,MAXCY1) ↔ IOSUM(22,MAXCY1): first 20 rows per col as Float32
#   RSEED(2)         ↔ S0   (Float64)
#   ESSEED(2)        ↔ ESS0 (Float64)
#   SVSED0(2)        ↔ SVS0 (Float64)
#   SVSED1(2)        ↔ SVS1 (Float64)
#   RDTREE(MAXTRE)   ↔ IDTREE(Int32)

function GETSTD()
    MXI    = Int32(120)
    MXL    = Int32(40)
    MXR    = Int32(137)
    ILIMIT = Int32(1024)

    ipnt = Ref{Int32}(0)

    # -----------------------------------------------------------------------
    # Read 120 integer scalars (ibegin=1 resets pointer)
    # -----------------------------------------------------------------------
    ints = zeros(Int32, MXI)
    IFREAD(WK3, ipnt, ILIMIT, ints, MXI, Int32(1))
    i_ref = Ref{Int32}(0)
    fvsGetRtnCode(i_ref)
    if i_ref[] != Int32(0); return nothing; end

    global IAGE     = ints[  1]
    global IASPEC   = ints[  2]
    global IBLK     = ints[  3]
    global ICACT    = ints[  4]
    global ICFLAG   = ints[  5]
    global ICL1     = ints[  6]
    global ICL2     = ints[  7]
    global ICL3     = ints[  8]
    global ICL4     = ints[  9]
    global ICL5     = ints[ 10]
    global ICL6     = ints[ 11]
    global ICOD     = ints[ 12]
    global ICRHAB   = ints[ 13]
    global ICYC     = ints[ 14]
    global IDG      = ints[ 15]
    global IDSDAT   = ints[ 16]
    global IEPT     = ints[ 17]
    global IEVA     = ints[ 18]
    global IEVT     = ints[ 19]
    global IFINT    = ints[ 20]
    global IFINTH   = ints[ 21]
    global IFO      = ints[ 22]
    global IFOR     = ints[ 23]
    global IFST     = ints[ 24]
    global IGL      = ints[ 25]
    global IHAB     = ints[ 26]
    global IHTG     = ints[ 27]
    global IHTYPE   = ints[ 28]
    global IMG1     = ints[ 29]
    global IMG2     = ints[ 30]
    global IMGL     = ints[ 31]
    global IMPL     = ints[ 32]
    global INADV    = ints[ 33]
    global IPHASE   = ints[ 34]
    global IPHY     = ints[ 35]
    global IPINFO   = ints[ 36]
    global IPREP    = ints[ 37]
    global IPRINT   = ints[ 38]
    global IPTINV   = ints[ 39]
    global IREC1    = ints[ 40]
    global IREC2    = ints[ 41]
    global IRECNT   = ints[ 42]
    global IRECRD   = ints[ 43]
    global IRHHAB   = ints[ 44]
    global ISISP    = ints[ 45]
    global ISLOP    = ints[ 46]
    global ISMALL   = ints[ 47]
    global ISPCCF   = ints[ 48]
    global ISPDSQ   = ints[ 49]
    global ISPFOR   = ints[ 50]
    global ISPHAB   = ints[ 51]
    global ISTDAT   = ints[ 52]
    global ITOP     = ints[ 53]        # DBSTK common
    global ITOPRM   = ints[ 54]
    global ITRN     = ints[ 55]
    global ITRNRM   = ints[ 56]
    global ITST5    = ints[ 57]
    global ITYPE    = ints[ 58]
    global IYRLRM   = ints[ 59]
    global KDTOLD   = ints[ 60]
    global KODFOR   = ints[ 61]
    global KODTYP   = ints[ 62]
    global LENSLS   = ints[ 63]
    global LOAD     = ints[ 64]
    global LSTKNT   = ints[ 65]
    global METH     = ints[ 66]
    global MINREP   = ints[ 67]
    global MODE     = ints[ 68]
    global MANAGD   = ints[ 69]
    global NCYC     = ints[ 70]
    global NNID     = ints[ 71]
    global NONSTK   = ints[ 72]
    global NPTIDS   = ints[ 73]
    global NSTKNT   = ints[ 74]
    global NTALLY   = ints[ 75]
    global NUMSP    = ints[ 76]
    global IMODTY   = ints[ 77]
    global IPHREG   = ints[ 78]
    global IFORTP   = ints[ 79]
    global ISTCL    = ints[ 80]
    global ISZCL    = ints[ 81]
    global ISTRCL   = ints[ 82]
    global IRREF    = ints[ 83]
    global NDEAD    = ints[ 84]
    global ICOLIDX  = ints[ 85]
    global IDPLOTS  = ints[ 86]
    global IGRID    = ints[ 87]
    global ILYEAR   = ints[ 88]
    global IRPOLES  = ints[ 89]
    global JSVOUT   = ints[ 90]
    global JSVPIC   = ints[ 91]
    global NSVOBJ   = ints[ 92]
    global IPLGEM   = ints[ 93]
    global IMORTCNT = ints[ 94]
    global ISVINV   = ints[ 95]
    global ICNTY    = ints[ 96]
    global ISTATE   = ints[ 97]
    global ICAGE    = ints[ 98]
    global MAIFLG   = ints[ 99]
    global NEWSTD   = ints[100]
    global ISEQDN   = ints[101]
    global IMETRIC  = ints[102]
    global NSPGRP   = ints[103]
    global ITHNPI   = ints[104]
    global ITHNPN   = ints[105]
    global NCALHT   = ints[106]
    global ITHNPA   = ints[107]
    global ISILFT   = ints[108]
    global NSITET   = ints[109]
    global ILGNUM   = ints[110]
    global NCWD     = ints[111]
    global MFLMSB   = ints[112]
    global JSPINDEF = ints[113]
    global KOLIST   = ints[114]
    SETNRPTS(ints[115])
    global IGFOR    = ints[116]
    global NPTGRP   = ints[117]
    global MAXTOP   = ints[118]        # DBSTK common
    global MAXLEN   = ints[119]        # DBSTK common
    global ISTDORG  = ints[120]

    # -----------------------------------------------------------------------
    # Read integer arrays (lengths now known from scalars)
    # -----------------------------------------------------------------------
    itrn_i   = Int(ITRN)
    imgl_i   = Int(IMGL)
    k        = imgl_i - 1
    IFREAD(WK3, ipnt, ILIMIT, view(DEFECT,  1:itrn_i),  Int32(ITRN),  Int32(2))
    IFREAD(WK3, ipnt, ILIMIT, view(IABFLG,  1:MAXSP),   Int32(MAXSP), Int32(2))
    for i in 1:5
        IFREAD(WK3, ipnt, ILIMIT, view(IACT, 1:k, i), Int32(k), Int32(2))
    end
    IFREAD(WK3, ipnt, ILIMIT, view(IDATE,  1:k),     Int32(k), Int32(2))
    IFREAD(WK3, ipnt, ILIMIT, view(IOPCYC, 1:k),     Int32(k), Int32(2))
    IFREAD(WK3, ipnt, ILIMIT, view(IOPSRT, 1:k),     Int32(k), Int32(2))
    IFREAD(WK3, ipnt, ILIMIT, view(ISEQ,   1:k),     Int32(k), Int32(2))
    iept_i = Int(IEPT)
    k2 = Int(MAXACT_OP) - iept_i + 1
    for i in 1:5
        IFREAD(WK3, ipnt, ILIMIT, view(IACT, iept_i:Int(MAXACT_OP), i), Int32(k2), Int32(2))
    end
    IFREAD(WK3, ipnt, ILIMIT, view(IDATE, iept_i:Int(MAXACT_OP)), Int32(k2), Int32(2))
    IFREAD(WK3, ipnt, ILIMIT, view(ISEQ,  iept_i:Int(MAXACT_OP)), Int32(k2), Int32(2))
    IFREAD(WK3, ipnt, ILIMIT, view(IALN,  1:3),      Int32(3), Int32(2))
    k3 = Int(IEVA) - 1
    if k3 > 0
        for i in 1:6
            IFREAD(WK3, ipnt, ILIMIT, view(IEVACT, 1:k3, i), Int32(k3), Int32(2))
        end
        IFREAD(WK3, ipnt, ILIMIT, view(LENAGL, 1:k3), Int32(k3), Int32(2))
    end
    icod_m1 = Int(ICOD) - 1
    IFREAD(WK3, ipnt, ILIMIT, view(IEVCOD,        1:icod_m1),       Int32(icod_m1),        Int32(2))
    ievt_m1 = Int(IEVT) - 1
    IFREAD(WK3, ipnt, ILIMIT, view(IEVNTS, 1:ievt_m1, 1),           Int32(ievt_m1),        Int32(2))
    IFREAD(WK3, ipnt, ILIMIT, view(IEVNTS, 1:ievt_m1, 2),           Int32(ievt_m1),        Int32(2))
    IFREAD(WK3, ipnt, ILIMIT, view(IEVNTS, 1:ievt_m1, 3),           Int32(ievt_m1),        Int32(2))
    IFREAD(WK3, ipnt, ILIMIT, view(IMC,    1:itrn_i),                Int32(ITRN),           Int32(2))
    ncyc_i = Int(NCYC)
    IFREAD(WK3, ipnt, ILIMIT, view(IMGPTS, 1:ncyc_i, 1),             Int32(NCYC),           Int32(2))
    IFREAD(WK3, ipnt, ILIMIT, view(IMGPTS, 1:ncyc_i, 2),             Int32(NCYC),           Int32(2))
    IFREAD(WK3, ipnt, ILIMIT, view(IBEGIN, 1:MAXSP),                 Int32(MAXSP),          Int32(2))
    icyc_p1 = Int(ICYC) + 1
    IFREAD(WK3, ipnt, ILIMIT, view(IBTAVH, 1:icyc_p1),               Int32(icyc_p1),        Int32(2))
    IFREAD(WK3, ipnt, ILIMIT, view(IBTCCF, 1:icyc_p1),               Int32(icyc_p1),        Int32(2))
    IFREAD(WK3, ipnt, ILIMIT, view(IBTRAN, 1:MAXSP),                  Int32(MAXSP),          Int32(2))
    IFREAD(WK3, ipnt, ILIMIT, view(ICTRAN, 1:MAXSP),                  Int32(MAXSP),          Int32(2))
    IFREAD(WK3, ipnt, ILIMIT, view(ICR,    1:itrn_i),                 Int32(ITRN),           Int32(2))
    IFREAD(WK3, ipnt, ILIMIT, view(IDTREE, 1:itrn_i),                 Int32(ITRN),           Int32(2))
    IFREAD(WK3, ipnt, ILIMIT, view(IESTAT, 1:itrn_i),                 Int32(ITRN),           Int32(2))
    IFREAD(WK3, ipnt, ILIMIT, view(IND,    1:itrn_i),                 Int32(ITRN),           Int32(2))
    IFREAD(WK3, ipnt, ILIMIT, view(IND1,   1:itrn_i),                 Int32(ITRN),           Int32(2))
    IFREAD(WK3, ipnt, ILIMIT, view(IND2,   1:itrn_i),                 Int32(ITRN),           Int32(2))
    IFREAD(WK3, ipnt, ILIMIT, view(INS,    1:6),                      Int32(6),              Int32(2))
    IFREAD(WK3, ipnt, ILIMIT, view(IOICR,  1:6),                      Int32(6),              Int32(2))
    IFREAD(WK3, ipnt, ILIMIT, view(IOLDBA, 1:icyc_p1),                Int32(icyc_p1),        Int32(2))
    IFREAD(WK3, ipnt, ILIMIT, view(IORDER, 1:MAXSP),                  Int32(MAXSP),          Int32(2))
    iptinv_i = Int(IPTINV)
    IFREAD(WK3, ipnt, ILIMIT, view(IPHAB,  1:iptinv_i),               Int32(IPTINV),         Int32(2))
    IFREAD(WK3, ipnt, ILIMIT, view(IPHYS,  1:iptinv_i),               Int32(IPTINV),         Int32(2))
    IFREAD(WK3, ipnt, ILIMIT, view(IPPREP, 1:MAXPLT),                 Int32(MAXPLT),         Int32(2))
    IFREAD(WK3, ipnt, ILIMIT, view(IPTIDS, 1:iptinv_i),               Int32(IPTINV),         Int32(2))
    IFREAD(WK3, ipnt, ILIMIT, view(IPVEC,  1:iptinv_i),               Int32(IPTINV),         Int32(2))
    IFREAD(WK3, ipnt, ILIMIT, view(IREF,   1:MAXSP),                  Int32(MAXSP),          Int32(2))
    IFREAD(WK3, ipnt, ILIMIT, view(ISCT,   1:MAXSP*2),                Int32(MAXSP*2),        Int32(2))
    IFREAD(WK3, ipnt, ILIMIT, view(ISDI_S, 1:icyc_p1),                Int32(icyc_p1),        Int32(2))
    IFREAD(WK3, ipnt, ILIMIT, view(ISDIAT, 1:icyc_p1),                Int32(icyc_p1),        Int32(2))
    IFREAD(WK3, ipnt, ILIMIT, view(ISP,    1:itrn_i),                 Int32(ITRN),           Int32(2))
    IFREAD(WK3, ipnt, ILIMIT, view(ISPECL, 1:itrn_i),                 Int32(ITRN),           Int32(2))
    # ISPGRP(30, 92): read element by element
    for i in 1:30
        for ii in 1:92
            tmp_i = Int32[Int32(0)]
            IFREAD(WK3, ipnt, ILIMIT, tmp_i, Int32(1), Int32(2))
            ISPGRP[i, ii] = tmp_i[1]
        end
    end
    IFREAD(WK3, ipnt, ILIMIT, view(ISTAGF, 1:MAXSP),                  Int32(MAXSP),          Int32(2))
    IFREAD(WK3, ipnt, ILIMIT, view(ITRE,   1:itrn_i),                 Int32(ITRN),           Int32(2))
    IFREAD(WK3, ipnt, ILIMIT, view(ITRUNC, 1:itrn_i),                 Int32(ITRN),           Int32(2))
    IFREAD(WK3, ipnt, ILIMIT, view(IY,     1:MAXCY1),                 Int32(MAXCY1),         Int32(2))
    IFREAD(WK3, ipnt, ILIMIT, view(KOUNT,  1:MAXSP),                  Int32(MAXSP),          Int32(2))
    IFREAD(WK3, ipnt, ILIMIT, view(KPTR,   1:MAXSP),                  Int32(MAXSP),          Int32(2))
    IFREAD(WK3, ipnt, ILIMIT, view(KUTKOD, 1:itrn_i),                 Int32(ITRN),           Int32(2))
    IFREAD(WK3, ipnt, ILIMIT, view(MAXSDI, 1:MAXSP),                  Int32(MAXSP),          Int32(2))
    IFREAD(WK3, ipnt, ILIMIT, view(METHC,  1:MAXSP),                  Int32(MAXSP),          Int32(2))
    IFREAD(WK3, ipnt, ILIMIT, view(METHB,  1:MAXSP),                  Int32(MAXSP),          Int32(2))
    IFREAD(WK3, ipnt, ILIMIT, view(NBFDEF, 1:itrn_i),                 Int32(ITRN),           Int32(2))
    IFREAD(WK3, ipnt, ILIMIT, view(NCFDEF, 1:itrn_i),                 Int32(ITRN),           Int32(2))
    IFREAD(WK3, ipnt, ILIMIT, view(NORMHT, 1:itrn_i),                 Int32(ITRN),           Int32(2))
    IFREAD(WK3, ipnt, ILIMIT, view(NSTORE, 1:MAXPLT),                 Int32(MAXPLT),         Int32(2))
    ndead_i = Int(NDEAD)
    IFREAD(WK3, ipnt, ILIMIT, view(ISNSP,   1:ndead_i),               Int32(NDEAD),          Int32(2))
    IFREAD(WK3, ipnt, ILIMIT, view(IYRCOD,  1:ndead_i),               Int32(NDEAD),          Int32(2))
    IFREAD(WK3, ipnt, ILIMIT, view(ISTATUS, 1:ndead_i),               Int32(NDEAD),          Int32(2))
    nsvobj_i = Int(NSVOBJ)
    IFREAD(WK3, ipnt, ILIMIT, view(IOBJTP,  1:nsvobj_i),              Int32(NSVOBJ),         Int32(2))
    IFREAD(WK3, ipnt, ILIMIT, view(IS2F,    1:nsvobj_i),              Int32(NSVOBJ),         Int32(2))
    IFREAD(WK3, ipnt, ILIMIT, view(OIDTRE,  1:ndead_i),               Int32(NDEAD),          Int32(2))
    IFREAD(WK3, ipnt, ILIMIT, view(JSPIN,   1:MAXSP),                 Int32(MAXSP),          Int32(2))
    IFREAD(WK3, ipnt, ILIMIT, view(ITABLE,  1:7),                     Int32(7),              Int32(2))
    # IPTGRP(30, 52): read element by element
    for i in 1:30
        for ii in 1:52
            tmp_i = Int32[Int32(0)]
            IFREAD(WK3, ipnt, ILIMIT, tmp_i, Int32(1), Int32(2))
            IPTGRP[i, ii] = tmp_i[1]
        end
    end
    IFREAD(WK3, ipnt, ILIMIT, view(DECAYCD,  1:itrn_i), Int32(ITRN), Int32(2))
    IFREAD(WK3, ipnt, ILIMIT, view(WDLDSTEM, 1:itrn_i), Int32(ITRN), Int32(2))

    # -----------------------------------------------------------------------
    # Read 40 logical scalars
    # -----------------------------------------------------------------------
    logics = zeros(Bool, MXL)
    LFREAD(WK3, ipnt, ILIMIT, logics, MXL, Int32(2))
    global LAUTAL  = logics[ 1]
    global LAUTON  = logics[ 2]
    global LBKDEN  = logics[ 3]
    global LBSETS  = logics[ 4]
    global LBVOLS  = logics[ 5]
    lcvgo_val      = logics[ 6]       # used below for CVGET
    global LCVOLS  = logics[ 7]
    global LDCOR2  = logics[ 8]
    global LDUBDG  = logics[ 9]
    global LECBUG  = logics[10]
    global LECON   = logics[11]
    global LEVUSE  = logics[12]
    global LFIANVB = logics[13]
    global LFIXSD  = logics[14]
    global LFLAG   = logics[15]
    global LHCOR2  = logics[16]
    global LINGRW  = logics[17]
    global LMORT   = logics[18]
    global LOPEVN  = logics[19]
    global LRCOR2  = logics[20]
    global LSITE   = logics[21]
    global LSTART  = logics[22]
    global LSTATS  = logics[23]
    global LSPRUT  = logics[24]
    global LSUMRY  = logics[25]
    global LTRIP   = logics[26]
    global MORDAT  = logics[27]
    global NOTRIP  = logics[28]
    global LCALC   = logics[29]
    global LFLAGV  = logics[30]
    global LBAMAX  = logics[31]
    global LPRNT   = logics[32]
    global LFIA    = logics[33]
    global LZEIDE  = logics[34]
    global LFIRE   = logics[35]
    lfm_val        = logics[36]       # used below to restore fire model state
    FMSATV(lfm_val)
    global FSTOPEN = logics[37]
    lclm_val       = logics[38]
    CLSETACTV(lclm_val)
    lwrd_val       = logics[39]       # western root disease active flag
    global LSCRN   = logics[40]

    # Read logical arrays
    let buf = Vector{Bool}(undef, MAXSP)
        LFREAD(WK3, ipnt, ILIMIT, buf, Int32(MAXSP), Int32(2))
        LDGCAL[1:MAXSP] .= buf
    end
    let buf = Vector{Bool}(undef, MAXSP)
        LFREAD(WK3, ipnt, ILIMIT, buf, Int32(MAXSP), Int32(2))
        LHTDRG[1:MAXSP] .= buf
    end
    let buf = Vector{Bool}(undef, MAXSP)
        LFREAD(WK3, ipnt, ILIMIT, buf, Int32(MAXSP), Int32(2))
        LHTCAL[1:MAXSP] .= buf
    end
    let buf = Vector{Bool}(undef, Int(MXTST4_OP))
        LFREAD(WK3, ipnt, ILIMIT, buf, Int32(MXTST4_OP), Int32(2))
        LTSTV4[1:Int(MXTST4_OP)] .= buf
    end
    let itst5_i = Int(ITST5)
        buf = Vector{Bool}(undef, itst5_i)
        LFREAD(WK3, ipnt, ILIMIT, buf, Int32(ITST5), Int32(2))
        LTSTV5[1:itst5_i] .= buf
    end
    let buf = Vector{Bool}(undef, MAXSP)
        LFREAD(WK3, ipnt, ILIMIT, buf, Int32(MAXSP), Int32(2))
        LSPCWE[1:MAXSP] .= buf
    end
    let buf = Vector{Bool}(undef, Int(MXLREG_OP))
        LFREAD(WK3, ipnt, ILIMIT, buf, Int32(MXLREG_OP), Int32(2))
        LREG[1:Int(MXLREG_OP)] .= buf
    end
    let buf = Vector{Bool}(undef, MAXSP)
        LFREAD(WK3, ipnt, ILIMIT, buf, Int32(MAXSP), Int32(2))
        LEAVESP[1:MAXSP] .= buf
    end

    # -----------------------------------------------------------------------
    # Read 137 real scalars
    # -----------------------------------------------------------------------
    reals = zeros(Float32, MXR)
    BFREAD(WK3, ipnt, ILIMIT, reals, MXR, Int32(2))
    global AHAT     = reals[  1]
    global ALPHA    = reals[  2]
    global ASPECT   = reals[  3]
    global ATAVD    = reals[  4]
    global ATAVH    = reals[  5]
    global ATBA     = reals[  6]
    global ATCCF    = reals[  7]
    global ATSDIX   = reals[  8]
    global ATTPA    = reals[  9]
    global AUTMAX   = reals[ 10]
    global AUTMIN   = reals[ 11]
    global AUTEFF   = reals[ 12]
    global AVH      = reals[ 13]
    global BA       = reals[ 14]
    global BAA      = reals[ 15]
    global BAALN    = reals[ 16]
    global BAASQ    = reals[ 17]
    global BAF      = reals[ 18]
    global BAMAX    = reals[ 19]
    global BAMIN    = reals[ 20]
    global BFMIN    = reals[ 21]
    global BHAT     = reals[ 22]
    global BJPHI    = reals[ 23]
    global BJTHET   = reals[ 24]
    global BRK      = reals[ 25]
    global BTSDIX   = reals[ 26]
    global BWAF     = reals[ 27]
    global BWB4     = reals[ 28]
    global CCMIN    = reals[ 29]
    global CEPMRT   = reals[ 30]
    global CFMIN    = reals[ 31]
    global CONFID   = reals[ 32]
    global COVMLT   = reals[ 33]
    global COVYR    = reals[ 34]
    global DBHDOM   = reals[ 35]
    global DGSD     = reals[ 36]
    global EFF      = reals[ 37]
    global ELEV     = reals[ 38]
    global ELEVSQ   = reals[ 39]
    global ESA      = reals[ 40]
    global ESB      = reals[ 41]
    global ESDRAW   = reals[ 42]
    global FINT     = reals[ 43]
    global FINTH    = reals[ 44]
    global FINTM    = reals[ 45]
    global FPA      = reals[ 46]
    global GAPPCT   = reals[ 47]
    global GROSPC   = reals[ 48]
    global H2COF    = reals[ 49]
    global HDGCOF   = reals[ 50]
    global HGHCH    = reals[ 51]
    global OLDAVH   = reals[ 52]
    global OLDBA    = reals[ 53]
    global OLDFNT   = reals[ 54]
    global OLDTIM   = reals[ 55]
    global OLDTPA   = reals[ 56]
    global ORMSQD   = reals[ 57]
    global PBURN    = reals[ 58]
    global PCTSMX   = reals[ 59]
    global PI       = reals[ 60]
    global PMECH    = reals[ 61]
    global PMSDIL   = reals[ 62]
    global PMSDIU   = reals[ 63]
    global POTEN    = reals[ 64]
    global REGCH    = reals[ 65]
    global REGNBK   = reals[ 66]
    global REGT     = reals[ 67]
    global RELDEN   = reals[ 68]
    global RELDM1   = reals[ 69]
    global RMAI     = reals[ 70]
    global RMSQD    = reals[ 71]
    global SAMWT    = reals[ 72]
    global SAWDBH   = reals[ 73]
    global SDIAC    = reals[ 74]
    global SDIBC    = reals[ 75]
    global SDIMAX   = reals[ 76]
    global SLO      = reals[ 77]
    global SLOPE    = reals[ 78]
    global SLPMRT   = reals[ 79]
    global SPCLWT   = reals[ 80]
    global SQBWAF   = reals[ 81]
    global SQREGT   = reals[ 82]
    global SSDBH    = reals[ 83]
    global STOADJ   = reals[ 84]
    global SUMPRB   = reals[ 85]
    global TCFMIN   = reals[ 86]
    global TCWT     = reals[ 87]
    global TFPA     = reals[ 88]
    global THRES1   = reals[ 89]
    global THRES2   = reals[ 90]
    global TIME     = reals[ 91]
    global TLAT     = reals[ 92]
    global TPACRE   = reals[ 93]
    global TPAMIN   = reals[ 94]
    global TPAMRT   = reals[ 95]
    global TPROB    = reals[ 96]
    global TRM      = reals[ 97]
    global VMLT     = reals[ 98]
    global VMLTYR   = reals[ 99]
    global XCOS     = reals[100]
    global XCOSAS   = reals[101]
    global XSIN     = reals[102]
    global XSINAS   = reals[103]
    global XTES     = reals[104]
    global YR       = reals[105]
    global ZBURN    = reals[106]
    global ZMECH    = reals[107]
    global SVSS     = reals[108]
    global TLONG    = reals[109]
    global TOTREM   = reals[110]
    global AGELST   = reals[111]
    global PBAWT    = reals[112]
    global PCCFWT   = reals[113]
    global FNMIN    = reals[114]
    global QMDMSB   = reals[115]
    global SLPMSB   = reals[116]
    global CEPMSB   = reals[117]
    global PTPAWT   = reals[118]
    global EFFMSB   = reals[119]
    global DLOMSB   = reals[120]
    global DHIMSB   = reals[121]
    global SDIAC2   = reals[122]
    global SDIBC2   = reals[123]
    global DBHZEIDE = reals[124]
    global DBHSTAGE = reals[125]
    global DR016    = reals[126]
    global CCCOEF   = reals[127]
    global CCCOEF2  = reals[128]
    global TRTCUFT  = reals[129]
    global TRMCUFT  = reals[130]
    global TRBDFT   = reals[131]
    global TRSCUFT  = reals[132]
    global TRTPA    = reals[133]
    global STNDSI   = reals[134]
    global SCFMIN   = reals[135]
    global ODR016   = reals[136]
    global ATDR016  = reals[137]

    # -----------------------------------------------------------------------
    # Read real arrays
    # -----------------------------------------------------------------------
    BFREAD(WK3, ipnt, ILIMIT, view(AA,          1:MAXSP),      Int32(MAXSP),      Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(ABIRTH,      1:itrn_i),     Int32(ITRN),       Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(ABVGRD_BIO,  1:itrn_i),     Int32(ITRN),       Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(ABVGRD_CARB, 1:itrn_i),     Int32(ITRN),       Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(ACCFSP,      1:MAXSP),      Int32(MAXSP),      Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(ATTEN,       1:MAXSP),      Int32(MAXSP),      Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(BAAA,        1:iptinv_i),   Int32(IPTINV),     Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(BAAINV,      1:iptinv_i),   Int32(IPTINV),     Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(BARANK,      1:MAXSP),      Int32(MAXSP),      Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(BB,          1:MAXSP),      Int32(MAXSP),      Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(B0ACCF,      1:MAXSP),      Int32(MAXSP),      Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(B1ACCF,      1:MAXSP),      Int32(MAXSP),      Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(B0BCCF,      1:MAXSP),      Int32(MAXSP),      Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(B1BCCF,      1:MAXSP),      Int32(MAXSP),      Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(B0ASTD,      1:MAXSP),      Int32(MAXSP),      Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(B1BSTD,      1:MAXSP),      Int32(MAXSP),      Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(BCCFSP,      1:MAXSP),      Int32(MAXSP),      Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(BCYMAI,      1:MAXCY1),     Int32(MAXCY1),     Int32(2))
    for i in 1:MAXSP
        BFREAD(WK3, ipnt, ILIMIT, view(BFDEFT, :, i), Int32(9), Int32(2))
        BFREAD(WK3, ipnt, ILIMIT, view(BFVEQL, :, i), Int32(7), Int32(2))
        BFREAD(WK3, ipnt, ILIMIT, view(BFVEQS, :, i), Int32(7), Int32(2))
        BFREAD(WK3, ipnt, ILIMIT, view(CFDEFT, :, i), Int32(9), Int32(2))
        BFREAD(WK3, ipnt, ILIMIT, view(CFVEQL, :, i), Int32(7), Int32(2))
        BFREAD(WK3, ipnt, ILIMIT, view(CFVEQS, :, i), Int32(7), Int32(2))
    end
    BFREAD(WK3, ipnt, ILIMIT, view(BFLA0,       1:MAXSP),      Int32(MAXSP),      Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(BFLA1,       1:MAXSP),      Int32(MAXSP),      Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(BFMIND,      1:MAXSP),      Int32(MAXSP),      Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(BFSTMP,      1:MAXSP),      Int32(MAXSP),      Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(BFTOPD,      1:MAXSP),      Int32(MAXSP),      Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(BFV,         1:itrn_i),     Int32(ITRN),       Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(BJRHO,       1:40),         Int32(40),         Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(BKRAT,       1:MAXSP),      Int32(MAXSP),      Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(BTRAN,       1:MAXSP),      Int32(MAXSP),      Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(CARB_FRAC,   1:itrn_i),     Int32(ITRN),       Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(CFLA0,       1:MAXSP),      Int32(MAXSP),      Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(CFLA1,       1:MAXSP),      Int32(MAXSP),      Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(CFV,         1:itrn_i),     Int32(ITRN),       Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(COR,         1:MAXSP),      Int32(MAXSP),      Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(COR2,        1:MAXSP),      Int32(MAXSP),      Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(CRCON,       1:MAXSP),      Int32(MAXSP),      Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(CRWDTH,      1:itrn_i),     Int32(ITRN),       Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(CTRAN,       1:MAXSP),      Int32(MAXSP),      Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(CUBSAW_BIO,  1:itrn_i),     Int32(ITRN),       Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(CUBSAW_CARB, 1:itrn_i),     Int32(ITRN),       Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(CULL,        1:itrn_i),     Int32(ITRN),       Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(DBH,         1:itrn_i),     Int32(ITRN),       Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(DBHIO,       1:6),          Int32(6),          Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(DBHMIN,      1:MAXSP),      Int32(MAXSP),      Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(DG,          1:itrn_i),     Int32(ITRN),       Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(DGCCF,       1:MAXSP),      Int32(MAXSP),      Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(DGCON,       1:MAXSP),      Int32(MAXSP),      Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(DGDSQ,       1:MAXSP),      Int32(MAXSP),      Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(DGIO,        1:6),          Int32(6),          Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(DIFH,        1:MAXSP),      Int32(MAXSP),      Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(ESB1,        1:MAXPLT),     Int32(MAXPLT),     Int32(2))
    # ESSEED(2) ↔ ESS0 (Float64): read two Float32 bits then reconstruct Float64
    let esseed_buf = zeros(Float32, 2)
        BFREAD(WK3, ipnt, ILIMIT, esseed_buf, Int32(2), Int32(2))
        global ESS0 = reinterpret(Float64, esseed_buf)[1]
    end
    BFREAD(WK3, ipnt, ILIMIT, view(FL,          1:MAXSP),      Int32(MAXSP),      Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(FM,          1:MAXSP),      Int32(MAXSP),      Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(FRMCLS,      1:MAXSP),      Int32(MAXSP),      Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(FOLI_BIO,    1:itrn_i),     Int32(ITRN),       Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(FOLI_CARB,   1:itrn_i),     Int32(ITRN),       Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(FU,          1:MAXSP),      Int32(MAXSP),      Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(GMULT,       1:2),          Int32(2),          Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(HCOR,        1:MAXSP),      Int32(MAXSP),      Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(HCOR2,       1:MAXSP),      Int32(MAXSP),      Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(HSIG,        1:MAXSP),      Int32(MAXSP),      Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(HT,          1:itrn_i),     Int32(ITRN),       Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(HT1,         1:MAXSP),      Int32(MAXSP),      Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(HT2,         1:MAXSP),      Int32(MAXSP),      Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(reshape(HTT1, :), 1:MAXSP*9), Int32(MAXSP*9),  Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(reshape(HTT2, :), 1:MAXSP*9), Int32(MAXSP*9),  Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(HTADJ,       1:MAXSP),      Int32(MAXSP),      Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(HTCON,       1:MAXSP),      Int32(MAXSP),      Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(HTG,         1:itrn_i),     Int32(ITRN),       Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(HTIO,        1:6),          Int32(6),          Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(LOGDIA, :, 1),              Int32(21),         Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(LOGDIA, :, 2),              Int32(21),         Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(LOGDIA, :, 3),              Int32(21),         Int32(2))
    for i in 1:20
        BFREAD(WK3, ipnt, ILIMIT, view(LOGVOL, :, i), Int32(7), Int32(2))
    end
    BFREAD(WK3, ipnt, ILIMIT, view(MCFV,        1:itrn_i),     Int32(ITRN),       Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(MERCH_BIO,   1:itrn_i),     Int32(ITRN),       Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(MERCH_CARB,  1:itrn_i),     Int32(ITRN),       Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(OACC,        1:7),          Int32(7),          Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(OBFCUR,      1:7),          Int32(7),          Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(OBFREM,      1:7),          Int32(7),          Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(OCVCUR,      1:7),          Int32(7),          Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(OCVREM,      1:7),          Int32(7),          Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(OLDPCT,      1:itrn_i),     Int32(ITRN),       Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(OLDRN,       1:itrn_i),     Int32(ITRN),       Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(OMCCUR,      1:7),          Int32(7),          Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(OMCREM,      1:7),          Int32(7),          Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(OMORT,       1:7),          Int32(7),          Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(ONTCUR,      1:7),          Int32(7),          Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(ONTREM,      1:7),          Int32(7),          Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(ONTRES,      1:7),          Int32(7),          Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(OSCCUR,      1:7),          Int32(7),          Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(OSCREM,      1:7),          Int32(7),          Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(OSPAC,       1:4),          Int32(4),          Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(OSPBR,       1:4),          Int32(4),          Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(OSPBV,       1:4),          Int32(4),          Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(OSPCT,       1:4),          Int32(4),          Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(OSPCV,       1:4),          Int32(4),          Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(OSPMC,       1:4),          Int32(4),          Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(OSPMO,       1:4),          Int32(4),          Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(OSPMR,       1:4),          Int32(4),          Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(OSPRT,       1:4),          Int32(4),          Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(OSPSC,       1:4),          Int32(4),          Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(OSPSR,       1:4),          Int32(4),          Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(OSPTT,       1:4),          Int32(4),          Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(OSPTV,       1:4),          Int32(4),          Int32(2))
    n_over = iptinv_i * MAXSP
    BFREAD(WK3, ipnt, ILIMIT, view(reshape(OVER, :), 1:n_over), Int32(n_over),    Int32(2))
    impl_m1 = Int(IMPL) - 1
    BFREAD(WK3, ipnt, ILIMIT, view(PARMS, 1:impl_m1),                  Int32(impl_m1),        Int32(2))
    itoprm_i = Int(ITOPRM)
    BFREAD(WK3, ipnt, ILIMIT, view(PARMS, itoprm_i:Int(MAXPRM_OP)),    Int32(MAXPRM_OP - ITOPRM + 1), Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(PASP,        1:iptinv_i),  Int32(IPTINV),     Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(PCCF,        1:iptinv_i),  Int32(IPTINV),     Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(PCT,         1:itrn_i),    Int32(ITRN),       Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(PCTIO,       1:6),         Int32(6),          Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(PNN,         1:MAXPLT),    Int32(MAXPLT),     Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(PRBIO,       1:6),         Int32(6),          Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(PADV,        1:MAXSP),     Int32(MAXSP),      Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(PSUB,        1:MAXSP),     Int32(MAXSP),      Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(PTBAA,       1:iptinv_i),  Int32(IPTINV),     Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(PTBALT,      1:itrn_i),    Int32(ITRN),       Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(PTPA,        1:iptinv_i),  Int32(IPTINV),     Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(PXCS,        1:MAXSP),     Int32(MAXSP),      Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(SUMPX,       1:MAXSP),     Int32(MAXSP),      Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(SUMPI,       1:MAXSP),     Int32(MAXSP),      Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(PLPROB,      1:iptinv_i),  Int32(IPTINV),     Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(PLTSIZ,      1:itrn_i),    Int32(ITRN),       Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(PROB,        1:itrn_i),    Int32(ITRN),       Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(PROB1,       1:MAXPLT),    Int32(MAXPLT),     Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(PSLO,        1:iptinv_i),  Int32(IPTINV),     Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(PTOCFV,      1:itrn_i),    Int32(ITRN),       Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(PMRCFV,      1:itrn_i),    Int32(ITRN),       Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(PMRBFV,      1:itrn_i),    Int32(ITRN),       Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(PSCFV,       1:itrn_i),    Int32(ITRN),       Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(PDBH,        1:itrn_i),    Int32(ITRN),       Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(QDBHAT,      1:icyc_p1),   Int32(icyc_p1),    Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(QSDBT,       1:icyc_p1),   Int32(icyc_p1),    Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(RCOR2,       1:MAXSP),     Int32(MAXSP),      Int32(2))
    # RDTREE ↔ IDTREE: read Float32 bits, reinterpret as Int32
    let rdtree_buf = zeros(Float32, itrn_i)
        BFREAD(WK3, ipnt, ILIMIT, rdtree_buf, Int32(ITRN), Int32(2))
        IDTREE[1:itrn_i] .= reinterpret(Int32, rdtree_buf)
    end
    BFREAD(WK3, ipnt, ILIMIT, view(REIN,        1:2),         Int32(2),          Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(RELDSP,      1:MAXSP),     Int32(MAXSP),      Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(RHCON,       1:MAXSP),     Int32(MAXSP),      Int32(2))
    # ROSUM/IOSUM: read 20 Float32 per cycle col, reinterpret bits back to Int32
    k_cyc = icyc_p1
    let rosum_buf = zeros(Float32, 20)
        for i in 1:k_cyc
            BFREAD(WK3, ipnt, ILIMIT, rosum_buf, Int32(20), Int32(2))
            IOSUM[1:20, i] .= reinterpret(Int32, rosum_buf)
        end
    end
    # RSEED ↔ S0: read two Float32 bits, reconstruct Float64
    let rseed_buf = zeros(Float32, 2)
        BFREAD(WK3, ipnt, ILIMIT, rseed_buf, Int32(2), Int32(2))
        global S0 = reinterpret(Float64, rseed_buf)[1]
    end
    BFREAD(WK3, ipnt, ILIMIT, view(SCFMIND,     1:MAXSP),     Int32(MAXSP),      Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(SCFSTMP,     1:MAXSP),     Int32(MAXSP),      Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(SCFTOPD,     1:MAXSP),     Int32(MAXSP),      Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(SCFV,        1:itrn_i),    Int32(ITRN),       Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(SDIDEF,      1:MAXSP),     Int32(MAXSP),      Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(SIGMA,       1:MAXSP),     Int32(MAXSP),      Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(SIGMAR,      1:MAXSP),     Int32(MAXSP),      Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(SITEAR,      1:MAXSP),     Int32(MAXSP),      Int32(2))
    # SIZCAP(MAXSP, 4): read element by element
    for i in 1:MAXSP
        for ii in 1:4
            tmp_r = Float32[Float32(0)]
            BFREAD(WK3, ipnt, ILIMIT, tmp_r, Int32(1), Int32(2))
            SIZCAP[i, ii] = tmp_r[1]
        end
    end
    BFREAD(WK3, ipnt, ILIMIT, view(SMCON,       1:MAXSP),     Int32(MAXSP),      Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(STMP,        1:MAXSP),     Int32(MAXSP),      Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(SUMPRE,      1:5),         Int32(5),          Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(TOPD,        1:MAXSP),     Int32(MAXSP),      Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(TPAAINV,     1:iptinv_i),  Int32(IPTINV),     Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(TSTV1,       1:Int(MXTST1_OP)), Int32(MXTST1_OP), Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(TSTV2,       1:Int(MXTST2_OP)), Int32(MXTST2_OP), Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(TSTV3,       1:Int(MXTST3_OP)), Int32(MXTST3_OP), Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(TSTV4,       1:Int(MXTST4_OP)), Int32(MXTST4_OP), Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(TSTV5,       1:Int(ITST5)),      Int32(ITST5),     Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(VARDG,       1:MAXSP),     Int32(MAXSP),      Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(WCI,         1:MAXSP),     Int32(MAXSP),      Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(WK1,         1:itrn_i),    Int32(ITRN),       Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(WK2,         1:itrn_i),    Int32(ITRN),       Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(XDMULT,      1:MAXSP),     Int32(MAXSP),      Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(XESMLT,      1:MAXSP),     Int32(MAXSP),      Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(XHMULT,      1:MAXSP),     Int32(MAXSP),      Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(XMDIA1,      1:MAXSP),     Int32(MAXSP),      Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(XMDIA2,      1:MAXSP),     Int32(MAXSP),      Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(XMMULT,      1:MAXSP),     Int32(MAXSP),      Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(XRDMLT,      1:MAXSP),     Int32(MAXSP),      Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(XRHMLT,      1:MAXSP),     Int32(MAXSP),      Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(ZRAND,       1:itrn_i),    Int32(ITRN),       Int32(2))

    # SVS arrays
    let svsed0_buf = zeros(Float32, 2)
        BFREAD(WK3, ipnt, ILIMIT, svsed0_buf, Int32(2), Int32(2))
        global SVS0 = reinterpret(Float64, svsed0_buf)[1]
    end
    let svsed1_buf = zeros(Float32, 2)
        BFREAD(WK3, ipnt, ILIMIT, svsed1_buf, Int32(2), Int32(2))
        global SVS1 = reinterpret(Float64, svsed1_buf)[1]
    end
    BFREAD(WK3, ipnt, ILIMIT, view(CRNDIA,  1:ndead_i),  Int32(NDEAD),   Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(CRNRTO,  1:ndead_i),  Int32(NDEAD),   Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(OLEN,    1:ndead_i),  Int32(NDEAD),   Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(ODIA,    1:ndead_i),  Int32(NDEAD),   Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(FALLDIR, 1:ndead_i),  Int32(NDEAD),   Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(YHFHTS,  1:MAXSP),    Int32(MAXSP),   Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(YHFHTH,  1:MAXSP),    Int32(MAXSP),   Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(HRATE,   1:MAXSP),    Int32(MAXSP),   Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(XSLOC,   1:nsvobj_i), Int32(NSVOBJ),  Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(YSLOC,   1:nsvobj_i), Int32(NSVOBJ),  Int32(2))
    isvinv_i = Int(ISVINV)
    BFREAD(WK3, ipnt, ILIMIT, view(X1R1S,   1:isvinv_i), Int32(ISVINV),  Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(X2R2S,   1:isvinv_i), Int32(ISVINV),  Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(Y1A1S,   1:isvinv_i), Int32(ISVINV),  Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(Y2A2S,   1:isvinv_i), Int32(ISVINV),  Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(CWDS0,   1:MAXSP),    Int32(MAXSP),   Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(CWDS1,   1:MAXSP),    Int32(MAXSP),   Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(CWDS2,   1:MAXSP),    Int32(MAXSP),   Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(CWDS3,   1:MAXSP),    Int32(MAXSP),   Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(CWDL0,   1:MAXSP),    Int32(MAXSP),   Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(CWDL1,   1:MAXSP),    Int32(MAXSP),   Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(CWDL2,   1:MAXSP),    Int32(MAXSP),   Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(CWDL3,   1:MAXSP),    Int32(MAXSP),   Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, view(CWTDBH,  1:MAXSP),    Int32(MAXSP),   Int32(2))
    ostrst_flat = view(reshape(OSTRST, :), 1:33*2)
    BFREAD(WK3, ipnt, ILIMIT, ostrst_flat, Int32(33*2),  Int32(2))

    if ndead_i > 0
        BFREAD(WK3, ipnt, ILIMIT, view(PBFALL,  1:ndead_i), Int32(NDEAD), Int32(2))
        BFREAD(WK3, ipnt, ILIMIT, view(SNGDIA,  1:ndead_i), Int32(NDEAD), Int32(2))
        BFREAD(WK3, ipnt, ILIMIT, view(SNGLEN,  1:ndead_i), Int32(NDEAD), Int32(2))
        for i in 1:3
            BFREAD(WK3, ipnt, ILIMIT, view(SPROBS, 1:ndead_i, i), Int32(NDEAD), Int32(2))
        end
        for i in 1:4
            BFREAD(WK3, ipnt, ILIMIT, view(SNGCNWT, 1:ndead_i, i), Int32(NDEAD), Int32(2))
        end
    end

    ncwd_i = Int(NCWD)
    if ncwd_i > 0
        BFREAD(WK3, ipnt, ILIMIT, view(CWDDIA, 1:ncwd_i),  Int32(NCWD),  Int32(2))
        BFREAD(WK3, ipnt, ILIMIT, view(CWDLEN, 1:ncwd_i),  Int32(NCWD),  Int32(2))
        BFREAD(WK3, ipnt, ILIMIT, view(CWDPIL, 1:ncwd_i),  Int32(NCWD),  Int32(2))
        BFREAD(WK3, ipnt, ILIMIT, view(CWDDIR, 1:ncwd_i),  Int32(NCWD),  Int32(2))
        BFREAD(WK3, ipnt, ILIMIT, view(CWDWT,  1:ncwd_i),  Int32(NCWD),  Int32(2))
    end

    sitetr_flat = view(reshape(SITETR, :), 1:MAXSTR*6)
    BFREAD(WK3, ipnt, ILIMIT, view(PHT,      1:MAXTRE),   Int32(MAXTRE),  Int32(2))
    BFREAD(WK3, ipnt, ILIMIT, sitetr_flat,               Int32(MAXSTR*6), Int32(2))

    # -----------------------------------------------------------------------
    # Extension get calls
    # -----------------------------------------------------------------------
    VARGET(WK3, ipnt, ILIMIT, reals, logics, ints)

    if lcvgo_val
        CVGET(WK3, ipnt, ILIMIT)
    end

    lmored_ref = Ref{Bool}(false)
    MISACT(lmored_ref)
    if lmored_ref[]
        MSPPGT(WK3, ipnt, ILIMIT)
    end

    if lwrd_val
        RDPPGT(WK3, ipnt, ILIMIT)
    end

    if lfm_val
        FMPPGET(WK3, ipnt, ILIMIT)
    end

    ECNGET(WK3, ipnt, ILIMIT)
    DBSPPGET(WK3, ipnt, ILIMIT)
    CLGET(WK3, ipnt, ILIMIT)

    # Last real array: ibegin=3 signals end-of-record flush
    BFREAD(WK3, ipnt, ILIMIT, view(XSTORE, 1:MAXPLT), Int32(MAXPLT), Int32(3))

    # End of numeric/logical read — restore character data
    CHGET()

    # Reopen establishment model report file if present
    let cname = rstrip(KWDFIL) * "_RegenRpt.txt"
        if isfile(cname)
            kode_ref = Ref{Int32}(0)
            MYOPEN(JOREGT, cname, Int32(3), Int32(133), Int32(0), Int32(1), Int32(1), Int32(0), kode_ref)
            if kode_ref[] > Int32(0)
                @printf(stdout, "OPEN FAILED FOR %4d\n", JOREGT)
            else
                # position at end of file (equivalent to Fortran READ loop until END= then BACKSPACE)
                io_key = get(io_units, Int(JOREGT), nothing)
                if io_key !== nothing
                    seekend(io_key)
                end
            end
        end
    end

    return nothing
end
