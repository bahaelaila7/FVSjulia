# base/putstd.jl — PUTSTD: serialize all FVS stand state to stash buffer
# Translated from: bin/FVSsn_buildDir/putstd.f (896 lines)
#
# Packs integer, logical, and real scalars/arrays into WK3 via
# IFWRIT/LFWRIT/BFWRIT (defined in putgetsubs.jl).
# Called at each stop/restart save point.
#
# EQUIVALENCE translations:
#   ROSUM(20,MAXCY1) ↔ IOSUM(22,MAXCY1): reinterpret first 20 rows per col as Float32
#   RSEED(2)         ↔ S0   (Float64):    reinterpret(Float32, [S0])
#   ESSEED(2)        ↔ ESS0 (Float64):    reinterpret(Float32, [ESS0])
#   SVSED0(2)        ↔ SVS0 (Float64):    reinterpret(Float32, [SVS0])
#   SVSED1(2)        ↔ SVS1 (Float64):    reinterpret(Float32, [SVS1])
#   RDTREE(MAXTRE)   ↔ IDTREE(Int32):     reinterpret(Float32, IDTREE)

function PUTSTD()
    MXI    = Int32(120)
    MXL    = Int32(40)
    MXR    = Int32(137)
    ILIMIT = Int32(1024)

    ipnt = Ref{Int32}(0)

    if ITABLE[2] == Int32(0)
        global ITABLE
        ITABLE[2] = Int32(1)
        println("FVS turned off the example tree table output.")
    end

    # -----------------------------------------------------------------------
    # Pack 120 integer scalars
    # -----------------------------------------------------------------------
    ints = zeros(Int32, MXI)
    ints[  1] = IAGE
    ints[  2] = IASPEC
    ints[  3] = IBLK
    ints[  4] = ICACT
    ints[  5] = ICFLAG
    ints[  6] = ICL1
    ints[  7] = ICL2
    ints[  8] = ICL3
    ints[  9] = ICL4
    ints[ 10] = ICL5
    ints[ 11] = ICL6
    ints[ 12] = ICOD
    ints[ 13] = ICRHAB
    ints[ 14] = ICYC
    ints[ 15] = IDG
    ints[ 16] = IDSDAT
    ints[ 17] = IEPT
    ints[ 18] = IEVA
    ints[ 19] = IEVT
    ints[ 20] = IFINT
    ints[ 21] = IFINTH
    ints[ 22] = IFO
    ints[ 23] = IFOR
    ints[ 24] = IFST
    ints[ 25] = IGL
    ints[ 26] = IHAB
    ints[ 27] = IHTG
    ints[ 28] = IHTYPE
    ints[ 29] = IMG1
    ints[ 30] = IMG2
    ints[ 31] = IMGL
    ints[ 32] = IMPL
    ints[ 33] = INADV
    ints[ 34] = IPHASE
    ints[ 35] = IPHY
    ints[ 36] = IPINFO
    ints[ 37] = IPREP
    ints[ 38] = IPRINT
    ints[ 39] = IPTINV
    ints[ 40] = IREC1
    ints[ 41] = IREC2
    ints[ 42] = IRECNT
    ints[ 43] = IRECRD
    ints[ 44] = IRHHAB
    ints[ 45] = ISISP
    ints[ 46] = ISLOP
    ints[ 47] = ISMALL
    ints[ 48] = ISPCCF
    ints[ 49] = ISPDSQ
    ints[ 50] = ISPFOR
    ints[ 51] = ISPHAB
    ints[ 52] = ISTDAT
    ints[ 53] = ITOP        # DBSTK common
    ints[ 54] = ITOPRM
    ints[ 55] = ITRN
    ints[ 56] = ITRNRM
    ints[ 57] = ITST5
    ints[ 58] = ITYPE
    ints[ 59] = IYRLRM
    ints[ 60] = KDTOLD
    ints[ 61] = KODFOR
    ints[ 62] = KODTYP
    ints[ 63] = LENSLS
    ints[ 64] = LOAD
    ints[ 65] = LSTKNT
    ints[ 66] = METH
    ints[ 67] = MINREP
    ints[ 68] = MODE
    ints[ 69] = MANAGD
    ints[ 70] = NCYC
    ints[ 71] = NNID
    ints[ 72] = NONSTK
    ints[ 73] = NPTIDS
    ints[ 74] = NSTKNT
    ints[ 75] = NTALLY
    ints[ 76] = NUMSP
    ints[ 77] = IMODTY
    ints[ 78] = IPHREG
    ints[ 79] = IFORTP
    ints[ 80] = ISTCL
    ints[ 81] = ISZCL
    ints[ 82] = ISTRCL
    ints[ 83] = IRREF
    ints[ 84] = NDEAD
    ints[ 85] = ICOLIDX
    ints[ 86] = IDPLOTS
    ints[ 87] = IGRID
    ints[ 88] = ILYEAR
    ints[ 89] = IRPOLES
    ints[ 90] = JSVOUT
    ints[ 91] = JSVPIC
    ints[ 92] = NSVOBJ
    ints[ 93] = IPLGEM
    ints[ 94] = IMORTCNT
    ints[ 95] = ISVINV
    ints[ 96] = ICNTY
    ints[ 97] = ISTATE
    ints[ 98] = ICAGE
    ints[ 99] = MAIFLG
    ints[100] = NEWSTD
    ints[101] = ISEQDN
    ints[102] = IMETRIC
    ints[103] = NSPGRP
    ints[104] = ITHNPI
    ints[105] = ITHNPN
    ints[106] = NCALHT
    ints[107] = ITHNPA
    ints[108] = ISILFT
    ints[109] = NSITET
    ints[110] = ILGNUM
    ints[111] = NCWD
    ints[112] = MFLMSB
    ints[113] = JSPINDEF
    ints[114] = KOLIST
    nrpts_ref = Ref{Int32}(0)
    GETNRPTS(nrpts_ref)
    ints[115] = nrpts_ref[]
    ints[116] = IGFOR
    ints[117] = NPTGRP
    ints[118] = MAXTOP      # DBSTK common
    ints[119] = MAXLEN      # DBSTK common
    ints[120] = ISTDORG

    # Write integer scalars first (ibegin=1 resets ipnt)
    IFWRIT(WK3, ipnt, ILIMIT, ints, MXI, Int32(1))

    # -----------------------------------------------------------------------
    # Write integer arrays
    # -----------------------------------------------------------------------
    itrn_i = Int(ITRN)
    imgl_i = Int(IMGL)
    k = imgl_i - 1
    IFWRIT(WK3, ipnt, ILIMIT, view(DEFECT,  1:itrn_i),  Int32(ITRN),  Int32(2))
    IFWRIT(WK3, ipnt, ILIMIT, view(IABFLG,  1:MAXSP),   Int32(MAXSP), Int32(2))
    for i in 1:5
        IFWRIT(WK3, ipnt, ILIMIT, view(IACT,   1:k, i), Int32(k), Int32(2))
    end
    IFWRIT(WK3, ipnt, ILIMIT, view(IDATE,   1:k),    Int32(k), Int32(2))
    IFWRIT(WK3, ipnt, ILIMIT, view(IOPCYC,  1:k),    Int32(k), Int32(2))
    IFWRIT(WK3, ipnt, ILIMIT, view(IOPSRT,  1:k),    Int32(k), Int32(2))
    IFWRIT(WK3, ipnt, ILIMIT, view(ISEQ,    1:k),    Int32(k), Int32(2))
    iept_i = Int(IEPT)
    k2 = Int(MAXACT_OP) - iept_i + 1
    for i in 1:5
        IFWRIT(WK3, ipnt, ILIMIT, view(IACT, iept_i:Int(MAXACT_OP), i), Int32(k2), Int32(2))
    end
    IFWRIT(WK3, ipnt, ILIMIT, view(IDATE,  iept_i:Int(MAXACT_OP)), Int32(k2), Int32(2))
    IFWRIT(WK3, ipnt, ILIMIT, view(ISEQ,   iept_i:Int(MAXACT_OP)), Int32(k2), Int32(2))
    IFWRIT(WK3, ipnt, ILIMIT, view(IALN,   1:3),     Int32(3), Int32(2))
    k3 = Int(IEVA) - 1
    if k3 > 0
        for i in 1:6
            IFWRIT(WK3, ipnt, ILIMIT, view(IEVACT, 1:k3, i), Int32(k3), Int32(2))
        end
        IFWRIT(WK3, ipnt, ILIMIT, view(LENAGL, 1:k3), Int32(k3), Int32(2))
    end
    icod_m1 = Int(ICOD) - 1
    IFWRIT(WK3, ipnt, ILIMIT, view(IEVCOD,         1:icod_m1),        Int32(icod_m1),        Int32(2))
    ievt_m1 = Int(IEVT) - 1
    IFWRIT(WK3, ipnt, ILIMIT, view(IEVNTS,  1:ievt_m1, 1),            Int32(ievt_m1),        Int32(2))
    IFWRIT(WK3, ipnt, ILIMIT, view(IEVNTS,  1:ievt_m1, 2),            Int32(ievt_m1),        Int32(2))
    IFWRIT(WK3, ipnt, ILIMIT, view(IEVNTS,  1:ievt_m1, 3),            Int32(ievt_m1),        Int32(2))
    IFWRIT(WK3, ipnt, ILIMIT, view(IMC,     1:itrn_i),                 Int32(ITRN),           Int32(2))
    ncyc_i = Int(NCYC)
    IFWRIT(WK3, ipnt, ILIMIT, view(IMGPTS,  1:ncyc_i, 1),              Int32(NCYC),           Int32(2))
    IFWRIT(WK3, ipnt, ILIMIT, view(IMGPTS,  1:ncyc_i, 2),              Int32(NCYC),           Int32(2))
    IFWRIT(WK3, ipnt, ILIMIT, view(IBEGIN,  1:MAXSP),                  Int32(MAXSP),          Int32(2))
    icyc_p1 = Int(ICYC) + 1
    IFWRIT(WK3, ipnt, ILIMIT, view(IBTAVH,  1:icyc_p1),                Int32(icyc_p1),        Int32(2))
    IFWRIT(WK3, ipnt, ILIMIT, view(IBTCCF,  1:icyc_p1),                Int32(icyc_p1),        Int32(2))
    IFWRIT(WK3, ipnt, ILIMIT, view(IBTRAN,  1:MAXSP),                  Int32(MAXSP),          Int32(2))
    IFWRIT(WK3, ipnt, ILIMIT, view(ICTRAN,  1:MAXSP),                  Int32(MAXSP),          Int32(2))
    IFWRIT(WK3, ipnt, ILIMIT, view(ICR,     1:itrn_i),                 Int32(ITRN),           Int32(2))
    IFWRIT(WK3, ipnt, ILIMIT, view(IDTREE,  1:itrn_i),                 Int32(ITRN),           Int32(2))
    IFWRIT(WK3, ipnt, ILIMIT, view(IESTAT,  1:itrn_i),                 Int32(ITRN),           Int32(2))
    IFWRIT(WK3, ipnt, ILIMIT, view(IND,     1:itrn_i),                 Int32(ITRN),           Int32(2))
    IFWRIT(WK3, ipnt, ILIMIT, view(IND1,    1:itrn_i),                 Int32(ITRN),           Int32(2))
    IFWRIT(WK3, ipnt, ILIMIT, view(IND2,    1:itrn_i),                 Int32(ITRN),           Int32(2))
    IFWRIT(WK3, ipnt, ILIMIT, view(INS,     1:6),                      Int32(6),              Int32(2))
    IFWRIT(WK3, ipnt, ILIMIT, view(IOICR,   1:6),                      Int32(6),              Int32(2))
    IFWRIT(WK3, ipnt, ILIMIT, view(IOLDBA,  1:icyc_p1),                Int32(icyc_p1),        Int32(2))
    IFWRIT(WK3, ipnt, ILIMIT, view(IORDER,  1:MAXSP),                  Int32(MAXSP),          Int32(2))
    iptinv_i = Int(IPTINV)
    IFWRIT(WK3, ipnt, ILIMIT, view(IPHAB,   1:iptinv_i),               Int32(IPTINV),         Int32(2))
    IFWRIT(WK3, ipnt, ILIMIT, view(IPHYS,   1:iptinv_i),               Int32(IPTINV),         Int32(2))
    IFWRIT(WK3, ipnt, ILIMIT, view(IPPREP,  1:MAXPLT),                 Int32(MAXPLT),         Int32(2))
    IFWRIT(WK3, ipnt, ILIMIT, view(IPTIDS,  1:iptinv_i),               Int32(IPTINV),         Int32(2))
    IFWRIT(WK3, ipnt, ILIMIT, view(IPVEC,   1:iptinv_i),               Int32(IPTINV),         Int32(2))
    IFWRIT(WK3, ipnt, ILIMIT, view(IREF,    1:MAXSP),                  Int32(MAXSP),          Int32(2))
    IFWRIT(WK3, ipnt, ILIMIT, view(ISCT,    1:MAXSP*2),                Int32(MAXSP*2),        Int32(2))
    IFWRIT(WK3, ipnt, ILIMIT, view(ISDI_S,  1:icyc_p1),                Int32(icyc_p1),        Int32(2))
    IFWRIT(WK3, ipnt, ILIMIT, view(ISDIAT,  1:icyc_p1),                Int32(icyc_p1),        Int32(2))
    IFWRIT(WK3, ipnt, ILIMIT, view(ISP,     1:itrn_i),                 Int32(ITRN),           Int32(2))
    IFWRIT(WK3, ipnt, ILIMIT, view(ISPECL,  1:itrn_i),                 Int32(ITRN),           Int32(2))
    # ISPGRP(30, 92): write element by element as Fortran does ISPGRP(I,II) with count=1
    for i in 1:30
        for ii in 1:92
            tmp_i = Int32[ISPGRP[i, ii]]
            IFWRIT(WK3, ipnt, ILIMIT, tmp_i, Int32(1), Int32(2))
        end
    end
    IFWRIT(WK3, ipnt, ILIMIT, view(ISTAGF,  1:MAXSP),                  Int32(MAXSP),          Int32(2))
    IFWRIT(WK3, ipnt, ILIMIT, view(ITRE,    1:itrn_i),                 Int32(ITRN),           Int32(2))
    IFWRIT(WK3, ipnt, ILIMIT, view(ITRUNC,  1:itrn_i),                 Int32(ITRN),           Int32(2))
    IFWRIT(WK3, ipnt, ILIMIT, view(IY,      1:MAXCY1),                 Int32(MAXCY1),         Int32(2))
    IFWRIT(WK3, ipnt, ILIMIT, view(KOUNT,   1:MAXSP),                  Int32(MAXSP),          Int32(2))
    IFWRIT(WK3, ipnt, ILIMIT, view(KPTR,    1:MAXSP),                  Int32(MAXSP),          Int32(2))
    IFWRIT(WK3, ipnt, ILIMIT, view(KUTKOD,  1:itrn_i),                 Int32(ITRN),           Int32(2))
    IFWRIT(WK3, ipnt, ILIMIT, view(MAXSDI,  1:MAXSP),                  Int32(MAXSP),          Int32(2))
    IFWRIT(WK3, ipnt, ILIMIT, view(METHC,   1:MAXSP),                  Int32(MAXSP),          Int32(2))
    IFWRIT(WK3, ipnt, ILIMIT, view(METHB,   1:MAXSP),                  Int32(MAXSP),          Int32(2))
    IFWRIT(WK3, ipnt, ILIMIT, view(NBFDEF,  1:itrn_i),                 Int32(ITRN),           Int32(2))
    IFWRIT(WK3, ipnt, ILIMIT, view(NCFDEF,  1:itrn_i),                 Int32(ITRN),           Int32(2))
    IFWRIT(WK3, ipnt, ILIMIT, view(NORMHT,  1:itrn_i),                 Int32(ITRN),           Int32(2))
    IFWRIT(WK3, ipnt, ILIMIT, view(NSTORE,  1:MAXPLT),                 Int32(MAXPLT),         Int32(2))
    ndead_i = Int(NDEAD)
    IFWRIT(WK3, ipnt, ILIMIT, view(ISNSP,   1:ndead_i),                Int32(NDEAD),          Int32(2))
    IFWRIT(WK3, ipnt, ILIMIT, view(IYRCOD,  1:ndead_i),                Int32(NDEAD),          Int32(2))
    IFWRIT(WK3, ipnt, ILIMIT, view(ISTATUS, 1:ndead_i),                Int32(NDEAD),          Int32(2))
    nsvobj_i = Int(NSVOBJ)
    IFWRIT(WK3, ipnt, ILIMIT, view(IOBJTP,  1:nsvobj_i),               Int32(NSVOBJ),         Int32(2))
    IFWRIT(WK3, ipnt, ILIMIT, view(IS2F,    1:nsvobj_i),               Int32(NSVOBJ),         Int32(2))
    IFWRIT(WK3, ipnt, ILIMIT, view(OIDTRE,  1:ndead_i),                Int32(NDEAD),          Int32(2))
    IFWRIT(WK3, ipnt, ILIMIT, view(JSPIN,   1:MAXSP),                  Int32(MAXSP),          Int32(2))
    IFWRIT(WK3, ipnt, ILIMIT, view(ITABLE,  1:7),                      Int32(7),              Int32(2))
    # IPTGRP(30, 52): write element by element
    for i in 1:30
        for ii in 1:52
            tmp_i = Int32[IPTGRP[i, ii]]
            IFWRIT(WK3, ipnt, ILIMIT, tmp_i, Int32(1), Int32(2))
        end
    end
    IFWRIT(WK3, ipnt, ILIMIT, view(DECAYCD,  1:itrn_i), Int32(ITRN), Int32(2))
    IFWRIT(WK3, ipnt, ILIMIT, view(WDLDSTEM, 1:itrn_i), Int32(ITRN), Int32(2))

    # -----------------------------------------------------------------------
    # Pack 40 logical scalars and query extension flags
    # -----------------------------------------------------------------------
    logics = zeros(Bool, MXL)
    logics[ 1] = LAUTAL
    logics[ 2] = LAUTON
    logics[ 3] = LBKDEN
    logics[ 4] = LBSETS
    logics[ 5] = LBVOLS
    lcvgo_ref = Ref{Bool}(false)
    CVGO(lcvgo_ref)
    logics[ 6] = lcvgo_ref[]
    logics[ 7] = LCVOLS
    logics[ 8] = LDCOR2
    logics[ 9] = LDUBDG
    logics[10] = LECBUG
    logics[11] = LECON
    logics[12] = LEVUSE
    logics[13] = LFIANVB
    logics[14] = LFIXSD
    logics[15] = LFLAG
    logics[16] = LHCOR2
    logics[17] = LINGRW
    logics[18] = LMORT
    logics[19] = LOPEVN
    logics[20] = LRCOR2
    logics[21] = LSITE
    logics[22] = LSTART
    logics[23] = LSTATS
    logics[24] = LSPRUT
    logics[25] = LSUMRY
    logics[26] = LTRIP
    logics[27] = MORDAT
    logics[28] = NOTRIP
    logics[29] = LCALC
    logics[30] = LFLAGV
    logics[31] = LBAMAX
    logics[32] = LPRNT
    logics[33] = LFIA
    logics[34] = LZEIDE
    logics[35] = LFIRE
    lfm_ref = Ref{Bool}(false)
    FMATV(lfm_ref)
    logics[36] = lfm_ref[]
    logics[37] = FSTOPEN
    lclm_ref = Ref{Bool}(false)
    CLACTV(lclm_ref)
    logics[38] = lclm_ref[]
    lwrd_ref = Ref{Bool}(false)
    lz_ref   = Ref{Bool}(false)
    RDATV(lwrd_ref, lz_ref)
    logics[39] = lwrd_ref[]
    logics[40] = LSCRN

    LFWRIT(WK3, ipnt, ILIMIT, logics, MXL, Int32(2))

    # Write logical arrays
    LFWRIT(WK3, ipnt, ILIMIT, Vector{Bool}(LDGCAL[1:MAXSP]),  Int32(MAXSP),         Int32(2))
    LFWRIT(WK3, ipnt, ILIMIT, Vector{Bool}(LHTDRG[1:MAXSP]),  Int32(MAXSP),         Int32(2))
    LFWRIT(WK3, ipnt, ILIMIT, Vector{Bool}(LHTCAL[1:MAXSP]),  Int32(MAXSP),         Int32(2))
    LFWRIT(WK3, ipnt, ILIMIT, Vector{Bool}(LTSTV4[1:Int(MXTST4_OP)]), Int32(MXTST4_OP), Int32(2))
    LFWRIT(WK3, ipnt, ILIMIT, Vector{Bool}(LTSTV5[1:Int(ITST5)]),     Int32(ITST5),     Int32(2))
    LFWRIT(WK3, ipnt, ILIMIT, Vector{Bool}(LSPCWE[1:MAXSP]),  Int32(MAXSP),         Int32(2))
    LFWRIT(WK3, ipnt, ILIMIT, Vector{Bool}(LREG[1:Int(MXLREG_OP)]),   Int32(MXLREG_OP), Int32(2))
    LFWRIT(WK3, ipnt, ILIMIT, Vector{Bool}(LEAVESP[1:MAXSP]), Int32(MAXSP),         Int32(2))

    # -----------------------------------------------------------------------
    # Pack 137 real scalars
    # -----------------------------------------------------------------------
    reals = zeros(Float32, MXR)
    reals[  1] = AHAT
    reals[  2] = ALPHA
    reals[  3] = ASPECT
    reals[  4] = ATAVD
    reals[  5] = ATAVH
    reals[  6] = ATBA
    reals[  7] = ATCCF
    reals[  8] = ATSDIX
    reals[  9] = ATTPA
    reals[ 10] = AUTMAX
    reals[ 11] = AUTMIN
    reals[ 12] = AUTEFF
    reals[ 13] = AVH
    reals[ 14] = BA
    reals[ 15] = BAA_ES
    reals[ 16] = BAALN
    reals[ 17] = BAASQ
    reals[ 18] = BAF
    reals[ 19] = BAMAX
    reals[ 20] = BAMIN
    reals[ 21] = BFMIN
    reals[ 22] = BHAT
    reals[ 23] = BJPHI
    reals[ 24] = BJTHET
    reals[ 25] = BRK
    reals[ 26] = BTSDIX
    reals[ 27] = BWAF
    reals[ 28] = BWB4
    reals[ 29] = CCMIN
    reals[ 30] = CEPMRT
    reals[ 31] = CFMIN
    reals[ 32] = CONFID
    reals[ 33] = COVMLT
    reals[ 34] = COVYR
    reals[ 35] = DBHDOM
    reals[ 36] = DGSD
    reals[ 37] = EFF
    reals[ 38] = ELEV
    reals[ 39] = ELEVSQ
    reals[ 40] = ESA
    reals[ 41] = ESB
    reals[ 42] = ESDRAW
    reals[ 43] = FINT
    reals[ 44] = FINTH
    reals[ 45] = FINTM
    reals[ 46] = FPA
    reals[ 47] = GAPPCT
    reals[ 48] = GROSPC
    reals[ 49] = H2COF
    reals[ 50] = HDGCOF
    reals[ 51] = HGHCH
    reals[ 52] = OLDAVH
    reals[ 53] = OLDBA
    reals[ 54] = OLDFNT
    reals[ 55] = OLDTIM
    reals[ 56] = OLDTPA
    reals[ 57] = ORMSQD
    reals[ 58] = PBURN
    reals[ 59] = PCTSMX
    reals[ 60] = PI
    reals[ 61] = PMECH
    reals[ 62] = PMSDIL
    reals[ 63] = PMSDIU
    reals[ 64] = POTEN
    reals[ 65] = REGCH
    reals[ 66] = REGNBK
    reals[ 67] = REGT
    reals[ 68] = RELDEN
    reals[ 69] = RELDM1
    reals[ 70] = RMAI
    reals[ 71] = RMSQD
    reals[ 72] = SAMWT
    reals[ 73] = SAWDBH
    reals[ 74] = SDIAC
    reals[ 75] = SDIBC
    reals[ 76] = SDIMAX
    reals[ 77] = SLO
    reals[ 78] = SLOPE
    reals[ 79] = SLPMRT
    reals[ 80] = SPCLWT
    reals[ 81] = SQBWAF
    reals[ 82] = SQREGT
    reals[ 83] = SSDBH
    reals[ 84] = STOADJ
    reals[ 85] = SUMPRB
    reals[ 86] = TCFMIN
    reals[ 87] = TCWT
    reals[ 88] = TFPA
    reals[ 89] = THRES1
    reals[ 90] = THRES2
    reals[ 91] = TIME_ES
    reals[ 92] = TLAT
    reals[ 93] = TPACRE
    reals[ 94] = TPAMIN
    reals[ 95] = TPAMRT
    reals[ 96] = TPROB
    reals[ 97] = TRM
    reals[ 98] = VMLT
    reals[ 99] = VMLTYR
    reals[100] = XCOS
    reals[101] = XCOSAS
    reals[102] = XSIN
    reals[103] = XSINAS
    reals[104] = XTES
    reals[105] = YR
    reals[106] = ZBURN
    reals[107] = ZMECH
    reals[108] = SVSS
    reals[109] = TLONG
    reals[110] = TOTREM
    reals[111] = AGELST
    reals[112] = PBAWT
    reals[113] = PCCFWT
    reals[114] = FNMIN
    reals[115] = QMDMSB
    reals[116] = SLPMSB
    reals[117] = CEPMSB
    reals[118] = PTPAWT
    reals[119] = EFFMSB
    reals[120] = DLOMSB
    reals[121] = DHIMSB
    reals[122] = SDIAC2
    reals[123] = SDIBC2
    reals[124] = DBHZEIDE
    reals[125] = DBHSTAGE
    reals[126] = DR016
    reals[127] = CCCOEF
    reals[128] = CCCOEF2
    reals[129] = TRTCUFT
    reals[130] = TRMCUFT
    reals[131] = TRBDFT
    reals[132] = TRSCUFT
    reals[133] = TRTPA
    reals[134] = STNDSI
    reals[135] = SCFMIN
    reals[136] = ODR016
    reals[137] = ATDR016

    BFWRIT(WK3, ipnt, ILIMIT, reals, MXR, Int32(2))

    # -----------------------------------------------------------------------
    # Write real arrays
    # -----------------------------------------------------------------------
    BFWRIT(WK3, ipnt, ILIMIT, view(AA,          1:MAXSP),      Int32(MAXSP),      Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(ABIRTH,      1:itrn_i),     Int32(ITRN),       Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(ABVGRD_BIO,  1:itrn_i),     Int32(ITRN),       Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(ABVGRD_CARB, 1:itrn_i),     Int32(ITRN),       Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(ACCFSP,      1:MAXSP),      Int32(MAXSP),      Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(ATTEN,       1:MAXSP),      Int32(MAXSP),      Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(BAAA,        1:iptinv_i),   Int32(IPTINV),     Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(BAAINV,      1:iptinv_i),   Int32(IPTINV),     Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(BARANK,      1:MAXSP),      Int32(MAXSP),      Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(BB,          1:MAXSP),      Int32(MAXSP),      Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(B0ACCF,      1:MAXSP),      Int32(MAXSP),      Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(B1ACCF,      1:MAXSP),      Int32(MAXSP),      Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(B0BCCF,      1:MAXSP),      Int32(MAXSP),      Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(B1BCCF,      1:MAXSP),      Int32(MAXSP),      Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(B0ASTD,      1:MAXSP),      Int32(MAXSP),      Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(B1BSTD,      1:MAXSP),      Int32(MAXSP),      Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(BCCFSP,      1:MAXSP),      Int32(MAXSP),      Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(BCYMAI,      1:MAXCY1),     Int32(MAXCY1),     Int32(2))
    for i in 1:MAXSP
        BFWRIT(WK3, ipnt, ILIMIT, view(BFDEFT, :, i), Int32(9), Int32(2))
        BFWRIT(WK3, ipnt, ILIMIT, view(BFVEQL, :, i), Int32(7), Int32(2))
        BFWRIT(WK3, ipnt, ILIMIT, view(BFVEQS, :, i), Int32(7), Int32(2))
        BFWRIT(WK3, ipnt, ILIMIT, view(CFDEFT, :, i), Int32(9), Int32(2))
        BFWRIT(WK3, ipnt, ILIMIT, view(CFVEQL, :, i), Int32(7), Int32(2))
        BFWRIT(WK3, ipnt, ILIMIT, view(CFVEQS, :, i), Int32(7), Int32(2))
    end
    BFWRIT(WK3, ipnt, ILIMIT, view(BFLA0,       1:MAXSP),      Int32(MAXSP),      Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(BFLA1,       1:MAXSP),      Int32(MAXSP),      Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(BFMIND,      1:MAXSP),      Int32(MAXSP),      Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(BFSTMP,      1:MAXSP),      Int32(MAXSP),      Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(BFTOPD,      1:MAXSP),      Int32(MAXSP),      Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(BFV,         1:itrn_i),     Int32(ITRN),       Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(BJRHO,       1:40),         Int32(40),         Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(BKRAT,       1:MAXSP),      Int32(MAXSP),      Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(BTRAN,       1:MAXSP),      Int32(MAXSP),      Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(CARB_FRAC,   1:itrn_i),     Int32(ITRN),       Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(CFLA0,       1:MAXSP),      Int32(MAXSP),      Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(CFLA1,       1:MAXSP),      Int32(MAXSP),      Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(CFV,         1:itrn_i),     Int32(ITRN),       Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(COR,         1:MAXSP),      Int32(MAXSP),      Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(COR2,        1:MAXSP),      Int32(MAXSP),      Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(CRCON,       1:MAXSP),      Int32(MAXSP),      Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(CRWDTH,      1:itrn_i),     Int32(ITRN),       Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(CTRAN,       1:MAXSP),      Int32(MAXSP),      Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(CUBSAW_BIO,  1:itrn_i),     Int32(ITRN),       Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(CUBSAW_CARB, 1:itrn_i),     Int32(ITRN),       Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(CULL,        1:itrn_i),     Int32(ITRN),       Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(DBH,         1:itrn_i),     Int32(ITRN),       Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(DBHIO,       1:6),          Int32(6),          Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(DBHMIN,      1:MAXSP),      Int32(MAXSP),      Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(DG,          1:itrn_i),     Int32(ITRN),       Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(DGCCF,       1:MAXSP),      Int32(MAXSP),      Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(DGCON,       1:MAXSP),      Int32(MAXSP),      Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(DGDSQ,       1:MAXSP),      Int32(MAXSP),      Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(DGIO,        1:6),          Int32(6),          Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(DIFH,        1:MAXSP),      Int32(MAXSP),      Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(ESB1,        1:MAXPLT),     Int32(MAXPLT),     Int32(2))
    # ESSEED(2) ↔ ESS0 (Float64): reinterpret 8 bytes of ESS0 as two Float32s
    esseed = reinterpret(Float32, [ESS0])
    BFWRIT(WK3, ipnt, ILIMIT, esseed, Int32(2), Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(FL,          1:MAXSP),      Int32(MAXSP),      Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(FM,          1:MAXSP),      Int32(MAXSP),      Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(FRMCLS,      1:MAXSP),      Int32(MAXSP),      Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(FOLI_BIO,    1:itrn_i),     Int32(ITRN),       Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(FOLI_CARB,   1:itrn_i),     Int32(ITRN),       Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(FU,          1:MAXSP),      Int32(MAXSP),      Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(GMULT,       1:2),          Int32(2),          Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(HCOR,        1:MAXSP),      Int32(MAXSP),      Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(HCOR2,       1:MAXSP),      Int32(MAXSP),      Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(HSIG,        1:MAXSP),      Int32(MAXSP),      Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(HT,          1:itrn_i),     Int32(ITRN),       Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(HT1,         1:MAXSP),      Int32(MAXSP),      Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(HT2,         1:MAXSP),      Int32(MAXSP),      Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(reshape(HTT1, :), 1:MAXSP*9), Int32(MAXSP*9),  Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(reshape(HTT2, :), 1:MAXSP*9), Int32(MAXSP*9),  Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(HTADJ,       1:MAXSP),      Int32(MAXSP),      Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(HTCON,       1:MAXSP),      Int32(MAXSP),      Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(HTG,         1:itrn_i),     Int32(ITRN),       Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(HTIO,        1:6),          Int32(6),          Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(LOGDIA, :, 1),              Int32(21),         Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(LOGDIA, :, 2),              Int32(21),         Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(LOGDIA, :, 3),              Int32(21),         Int32(2))
    for i in 1:20
        BFWRIT(WK3, ipnt, ILIMIT, view(LOGVOL, :, i), Int32(7), Int32(2))
    end
    BFWRIT(WK3, ipnt, ILIMIT, view(MCFV,        1:itrn_i),     Int32(ITRN),       Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(MERCH_BIO,   1:itrn_i),     Int32(ITRN),       Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(MERCH_CARB,  1:itrn_i),     Int32(ITRN),       Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(OACC,        1:7),          Int32(7),          Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(OBFCUR,      1:7),          Int32(7),          Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(OBFREM,      1:7),          Int32(7),          Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(OCVCUR,      1:7),          Int32(7),          Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(OCVREM,      1:7),          Int32(7),          Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(OLDPCT,      1:itrn_i),     Int32(ITRN),       Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(OLDRN,       1:itrn_i),     Int32(ITRN),       Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(OMCCUR,      1:7),          Int32(7),          Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(OMCREM,      1:7),          Int32(7),          Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(OMORT,       1:7),          Int32(7),          Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(ONTCUR,      1:7),          Int32(7),          Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(ONTREM,      1:7),          Int32(7),          Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(ONTRES,      1:7),          Int32(7),          Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(OSCCUR,      1:7),          Int32(7),          Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(OSCREM,      1:7),          Int32(7),          Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(OSPAC,       1:4),          Int32(4),          Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(OSPBR,       1:4),          Int32(4),          Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(OSPBV,       1:4),          Int32(4),          Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(OSPCT,       1:4),          Int32(4),          Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(OSPCV,       1:4),          Int32(4),          Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(OSPMC,       1:4),          Int32(4),          Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(OSPMO,       1:4),          Int32(4),          Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(OSPMR,       1:4),          Int32(4),          Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(OSPRT,       1:4),          Int32(4),          Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(OSPSC,       1:4),          Int32(4),          Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(OSPSR,       1:4),          Int32(4),          Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(OSPTT,       1:4),          Int32(4),          Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(OSPTV,       1:4),          Int32(4),          Int32(2))
    n_over = iptinv_i * MAXSP
    BFWRIT(WK3, ipnt, ILIMIT, view(reshape(OVER, :), 1:n_over), Int32(n_over),    Int32(2))
    impl_m1 = Int(IMPL) - 1
    BFWRIT(WK3, ipnt, ILIMIT, view(PARMS, 1:impl_m1),                  Int32(impl_m1),        Int32(2))
    itoprm_i = Int(ITOPRM)
    BFWRIT(WK3, ipnt, ILIMIT, view(PARMS, itoprm_i:Int(MAXPRM_OP)),    Int32(MAXPRM_OP - ITOPRM + 1), Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(PASP,        1:iptinv_i),  Int32(IPTINV),     Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(PCCF,        1:iptinv_i),  Int32(IPTINV),     Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(PCT,         1:itrn_i),    Int32(ITRN),       Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(PCTIO,       1:6),         Int32(6),          Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(PNN,         1:MAXPLT),    Int32(MAXPLT),     Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(PRBIO,       1:6),         Int32(6),          Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(PADV,        1:MAXSP),     Int32(MAXSP),      Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(PSUB,        1:MAXSP),     Int32(MAXSP),      Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(PTBAA,       1:iptinv_i),  Int32(IPTINV),     Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(PTBALT,      1:itrn_i),    Int32(ITRN),       Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(PTPA,        1:iptinv_i),  Int32(IPTINV),     Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(PXCS,        1:MAXSP),     Int32(MAXSP),      Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(SUMPX,       1:MAXSP),     Int32(MAXSP),      Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(SUMPI,       1:MAXSP),     Int32(MAXSP),      Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(PLPROB,      1:iptinv_i),  Int32(IPTINV),     Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(PLTSIZ,      1:itrn_i),    Int32(ITRN),       Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(PROB,        1:itrn_i),    Int32(ITRN),       Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(PROB1,       1:MAXPLT),    Int32(MAXPLT),     Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(PSLO,        1:iptinv_i),  Int32(IPTINV),     Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(PTOCFV,      1:itrn_i),    Int32(ITRN),       Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(PMRCFV,      1:itrn_i),    Int32(ITRN),       Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(PMRBFV,      1:itrn_i),    Int32(ITRN),       Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(PSCFV,       1:itrn_i),    Int32(ITRN),       Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(PDBH,        1:itrn_i),    Int32(ITRN),       Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(QDBHAT,      1:icyc_p1),   Int32(icyc_p1),    Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(QSDBT,       1:icyc_p1),   Int32(icyc_p1),    Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(RCOR2,       1:MAXSP),     Int32(MAXSP),      Int32(2))
    # RDTREE ↔ IDTREE: write IDTREE bits as Float32
    rdtree = reinterpret(Float32, view(IDTREE, 1:itrn_i))
    BFWRIT(WK3, ipnt, ILIMIT, rdtree, Int32(ITRN), Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(REIN,        1:2),         Int32(2),          Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(RELDSP,      1:MAXSP),     Int32(MAXSP),      Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(RHCON,       1:MAXSP),     Int32(MAXSP),      Int32(2))
    # IOSUM(22,MAXCY1): write all 22 rows per col as Float32. (The Fortran wrote
    # ROSUM(20,...) equivalenced to IOSUM, a flat-memory window that happened to
    # cover rows 21-22/SCuFt for early cycles; serialize the full 22 rows so the
    # NVB SCuFt summary columns round-trip exactly.)
    k_cyc = icyc_p1
    for i in 1:k_cyc
        rosum_col = reinterpret(Float32, view(IOSUM, 1:22, i))
        BFWRIT(WK3, ipnt, ILIMIT, rosum_col, Int32(22), Int32(2))
    end
    # RSEED(2) ↔ S0 (Float64): reinterpret 8-byte Float64 as two Float32s
    rseed = reinterpret(Float32, [S0])
    BFWRIT(WK3, ipnt, ILIMIT, rseed, Int32(2), Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(SCFMIND,     1:MAXSP),     Int32(MAXSP),      Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(SCFSTMP,     1:MAXSP),     Int32(MAXSP),      Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(SCFTOPD,     1:MAXSP),     Int32(MAXSP),      Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(SCFV,        1:itrn_i),    Int32(ITRN),       Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(SDIDEF,      1:MAXSP),     Int32(MAXSP),      Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(SIGMA,       1:MAXSP),     Int32(MAXSP),      Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(SIGMAR,      1:MAXSP),     Int32(MAXSP),      Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(SITEAR,      1:MAXSP),     Int32(MAXSP),      Int32(2))
    # SIZCAP(MAXSP, 4): written element by element (Fortran loop I=1..MAXSP, II=1..4)
    for i in 1:MAXSP
        for ii in 1:4
            tmp_r = Float32[SIZCAP[i, ii]]
            BFWRIT(WK3, ipnt, ILIMIT, tmp_r, Int32(1), Int32(2))
        end
    end
    BFWRIT(WK3, ipnt, ILIMIT, view(SMCON,       1:MAXSP),     Int32(MAXSP),      Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(STMP,        1:MAXSP),     Int32(MAXSP),      Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(SUMPRE,      1:5),         Int32(5),          Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(TOPD,        1:MAXSP),     Int32(MAXSP),      Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(TPAAINV,     1:iptinv_i),  Int32(IPTINV),     Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(TSTV1,       1:Int(MXTST1_OP)), Int32(MXTST1_OP), Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(TSTV2,       1:Int(MXTST2_OP)), Int32(MXTST2_OP), Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(TSTV3,       1:Int(MXTST3_OP)), Int32(MXTST3_OP), Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(TSTV4,       1:Int(MXTST4_OP)), Int32(MXTST4_OP), Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(TSTV5,       1:Int(ITST5)),      Int32(ITST5),     Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(VARDG,       1:MAXSP),     Int32(MAXSP),      Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(WCI,         1:MAXSP),     Int32(MAXSP),      Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(WK1,         1:itrn_i),    Int32(ITRN),       Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(WK2,         1:itrn_i),    Int32(ITRN),       Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(XDMULT,      1:MAXSP),     Int32(MAXSP),      Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(XESMLT,      1:MAXSP),     Int32(MAXSP),      Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(XHMULT,      1:MAXSP),     Int32(MAXSP),      Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(XMDIA1,      1:MAXSP),     Int32(MAXSP),      Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(XMDIA2,      1:MAXSP),     Int32(MAXSP),      Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(XMMULT,      1:MAXSP),     Int32(MAXSP),      Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(XRDMLT,      1:MAXSP),     Int32(MAXSP),      Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(XRHMLT,      1:MAXSP),     Int32(MAXSP),      Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(ZRAND,       1:itrn_i),    Int32(ITRN),       Int32(2))

    # SVS arrays
    # SVSED0(2) ↔ SVS0 (Float64); SVSED1(2) ↔ SVS1 (Float64)
    svsed0 = reinterpret(Float32, [SVS0])
    svsed1 = reinterpret(Float32, [SVS1])
    BFWRIT(WK3, ipnt, ILIMIT, svsed0, Int32(2), Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, svsed1, Int32(2), Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(CRNDIA,  1:ndead_i),  Int32(NDEAD),   Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(CRNRTO,  1:ndead_i),  Int32(NDEAD),   Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(OLEN,    1:ndead_i),  Int32(NDEAD),   Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(ODIA,    1:ndead_i),  Int32(NDEAD),   Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(FALLDIR, 1:ndead_i),  Int32(NDEAD),   Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(YHFHTS,  1:MAXSP),    Int32(MAXSP),   Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(YHFHTH,  1:MAXSP),    Int32(MAXSP),   Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(HRATE,   1:MAXSP),    Int32(MAXSP),   Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(XSLOC,   1:nsvobj_i), Int32(NSVOBJ),  Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(YSLOC,   1:nsvobj_i), Int32(NSVOBJ),  Int32(2))
    isvinv_i = Int(ISVINV)
    BFWRIT(WK3, ipnt, ILIMIT, view(X1R1S,   1:isvinv_i), Int32(ISVINV),  Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(X2R2S,   1:isvinv_i), Int32(ISVINV),  Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(Y1A1S,   1:isvinv_i), Int32(ISVINV),  Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(Y2A2S,   1:isvinv_i), Int32(ISVINV),  Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(CWDS0,   1:MAXSP),    Int32(MAXSP),   Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(CWDS1,   1:MAXSP),    Int32(MAXSP),   Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(CWDS2,   1:MAXSP),    Int32(MAXSP),   Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(CWDS3,   1:MAXSP),    Int32(MAXSP),   Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(CWDL0,   1:MAXSP),    Int32(MAXSP),   Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(CWDL1,   1:MAXSP),    Int32(MAXSP),   Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(CWDL2,   1:MAXSP),    Int32(MAXSP),   Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(CWDL3,   1:MAXSP),    Int32(MAXSP),   Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, view(CWTDBH,  1:MAXSP),    Int32(MAXSP),   Int32(2))
    ostrst_flat = view(reshape(OSTRST, :), 1:33*2)
    BFWRIT(WK3, ipnt, ILIMIT, ostrst_flat, Int32(33*2),  Int32(2))

    if ndead_i > 0
        BFWRIT(WK3, ipnt, ILIMIT, view(PBFALL,  1:ndead_i), Int32(NDEAD), Int32(2))
        BFWRIT(WK3, ipnt, ILIMIT, view(SNGDIA,  1:ndead_i), Int32(NDEAD), Int32(2))
        BFWRIT(WK3, ipnt, ILIMIT, view(SNGLEN,  1:ndead_i), Int32(NDEAD), Int32(2))
        for i in 1:3
            BFWRIT(WK3, ipnt, ILIMIT, view(SPROBS, 1:ndead_i, i), Int32(NDEAD), Int32(2))
        end
        # SNGCNWT(MXDEAD, 0:3) → Julia SNGCNWT[1:NDEAD, 1:4] (Fortran col 0 = Julia col 1)
        for i in 1:4
            BFWRIT(WK3, ipnt, ILIMIT, view(SNGCNWT, 1:ndead_i, i), Int32(NDEAD), Int32(2))
        end
    end

    ncwd_i = Int(NCWD)
    if ncwd_i > 0
        BFWRIT(WK3, ipnt, ILIMIT, view(CWDDIA,  1:ncwd_i),  Int32(NCWD),  Int32(2))
        BFWRIT(WK3, ipnt, ILIMIT, view(CWDLEN,  1:ncwd_i),  Int32(NCWD),  Int32(2))
        BFWRIT(WK3, ipnt, ILIMIT, view(CWDPIL,  1:ncwd_i),  Int32(NCWD),  Int32(2))
        BFWRIT(WK3, ipnt, ILIMIT, view(CWDDIR,  1:ncwd_i),  Int32(NCWD),  Int32(2))
        BFWRIT(WK3, ipnt, ILIMIT, view(CWDWT,   1:ncwd_i),  Int32(NCWD),  Int32(2))
    end

    sitetr_flat = view(reshape(SITETR, :), 1:MAXSTR*6)
    BFWRIT(WK3, ipnt, ILIMIT, view(PHT,      1:MAXTRE),   Int32(MAXTRE),  Int32(2))
    BFWRIT(WK3, ipnt, ILIMIT, sitetr_flat,                Int32(MAXSTR*6), Int32(2))

    # -----------------------------------------------------------------------
    # Extension put calls
    # -----------------------------------------------------------------------
    VARPUT(WK3, ipnt, ILIMIT, reals, logics, ints)

    lcvgo_val = logics[6]
    if lcvgo_val
        CVPUT(WK3, ipnt, ILIMIT, ICYC, ITRN)
    end

    lmored_ref = Ref{Bool}(false)
    MISACT(lmored_ref)
    if lmored_ref[]
        MSPPPT(WK3, ipnt, ILIMIT)
    end

    lwrd_val = logics[39]
    if lwrd_val
        RDPPPUT(WK3, ipnt, ILIMIT)
    end

    lfm_val = logics[36]
    if lfm_val
        FMPPPUT(WK3, ipnt, ILIMIT)
    end

    ECNPUT(WK3, ipnt, ILIMIT)
    DBSPPPUT(WK3, ipnt, ILIMIT)
    CLPUT(WK3, ipnt, ILIMIT)

    # Last real array: ibegin=3 signals flush
    BFWRIT(WK3, ipnt, ILIMIT, view(XSTORE, 1:MAXPLT), Int32(MAXPLT), Int32(3))

    CHPUT()
    return nothing
end
