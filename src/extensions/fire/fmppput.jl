# fire/fmppput.f — Stop/restart PUT: serialize fire model state to WK3 buffer
# 86 Int scalars → INTS → IFWRIT; 15 Bool scalars → LOGICS → LFWRIT;
# 56 Real scalars → REALS → BFWRIT; then per-tree and snag arrays.
# GROW renamed GROW_FM; CROWNW/OLDCRW col loop 0:5 → Julia col i+1;
# SALVSPA (MXSNAG,2) → two BFWRIT calls (one per column).
# Called from: restart write path

function FMPPPUT(wk3::AbstractVector{Float32}, ipnt_ref::Ref{Int32}, ilimit::Integer)
    local mxi = 86
    local mxl = 15
    local mxr = 56
    local ints   = zeros(Int32,  mxi)
    local logics = zeros(Bool,   mxl)
    local reals  = zeros(Float32, mxr)

    ints[  1] = IFMTYP
    ints[  2] = ACTCBH
    ints[  3] = ATEMP
    ints[  4] = BURNYR
    ints[  5] = COVTYP
    ints[  6] = FIRTYPE
    ints[  7] = FMKOD
    ints[  8] = FTREAT
    ints[  9] = HARTYP
    ints[ 10] = HARVYR
    ints[ 11] = IBRPAS
    ints[ 12] = IDBRN
    ints[ 13] = IDFLAL
    ints[ 14] = IDFUL
    ints[ 15] = IDMRT
    ints[ 16] = IDPFLM
    ints[ 17] = IDRYB
    ints[ 18] = IDRYE
    ints[ 19] = IFAPAS
    ints[ 20] = IFLALB
    ints[ 21] = IFLALE
    ints[ 22] = IFLPAS
    ints[ 23] = IFMBRB
    ints[ 24] = IFMBRE
    ints[ 25] = IFMFLB
    ints[ 26] = IFMFLE
    ints[ 27] = IFMMRB
    ints[ 28] = IFMMRE
    ints[ 29] = IFMYR1
    ints[ 30] = IFMYR2
    ints[ 31] = IFTYR
    ints[ 32] = IMRPAS
    ints[ 33] = IPFLMB
    ints[ 34] = IPFLME
    ints[ 35] = IPFPAS
    ints[ 36] = ISALVC
    ints[ 37] = ISALVS
    ints[ 38] = ISNAGB
    ints[ 39] = ISNAGE
    ints[ 40] = ISNGSM
    ints[ 41] = JCOUT
    ints[ 42] = JSNOUT
    ints[ 43] = ND
    ints[ 44] = NFMODS
    ints[ 45] = NFMSVPX
    ints[ 46] = NL
    ints[ 47] = NSNAG
    ints[ 48] = OLDCOVTYP
    ints[ 49] = OLDICT
    ints[ 50] = OLDICT2
    ints[ 51] = PBURNYR
    ints[ 52] = FM89YR
    ints[ 53] = ICBHMT
    ints[ 54] = ICANSP
    ints[ 55] = BURNSEAS
    ints[ 56] = IDSHEAT
    ints[ 57] = ISHEATB
    ints[ 58] = ISHEATE
    ints[ 59] = SOILTP
    ints[ 60] = ICFPB
    ints[ 61] = ICFPE
    ints[ 62] = NSNAGSALV
    ints[ 63] = NYRS
    ints[ 64] = ICHABT
    ints[ 65] = ICHPAS
    ints[ 66] = ICHRVB
    ints[ 67] = ICHRVE
    ints[ 68] = ICMETRC
    ints[ 69] = ICMETH
    ints[ 70] = ICRPAS
    ints[ 71] = ICRPTB
    ints[ 72] = ICRPTE
    ints[ 73] = IDCHRV
    ints[ 74] = IDCRPT
    ints[ 75] = IFLOGIC
    ints[ 76] = IFMSET
    ints[ 77] = ICYCRM
    ints[ 78] = ITRNL
    ints[ 79] = IDWPAS
    ints[ 80] = IDWRPB
    ints[ 81] = IDWRPE
    ints[ 82] = IDCPAS
    ints[ 83] = IDWCVB
    ints[ 84] = IDWCVE
    ints[ 85] = IDDWRP
    ints[ 86] = IDDWCV

    IFWRIT(wk3, ipnt_ref, Int32(ilimit), ints, Int32(mxi), Int32(2))

    local nsnagz = max(Int(NSNAG), 1)
    IFWRIT(wk3, ipnt_ref, Int32(ilimit), DKRCLS,                     Int32(MAXSP),       Int32(2))
    IFWRIT(wk3, ipnt_ref, Int32(ilimit), FLAG,                        Int32(3),           Int32(2))
    IFWRIT(wk3, ipnt_ref, Int32(ilimit), FMDUSR,                     Int32(4),           Int32(2))
    IFWRIT(wk3, ipnt_ref, Int32(ilimit), FMOD,                        Int32(MXFMOD),      Int32(2))
    IFWRIT(wk3, ipnt_ref, Int32(ilimit), view(GROW_FM, 1:Int(ITRN)), Int32(ITRN),        Int32(2))
    IFWRIT(wk3, ipnt_ref, Int32(ilimit), view(IOBJTPTMP, 1:Int(NSVOBJ)), Int32(NSVOBJ),  Int32(2))
    IFWRIT(wk3, ipnt_ref, Int32(ilimit), view(IS2FTMP,   1:Int(NSVOBJ)), Int32(NSVOBJ),  Int32(2))
    IFWRIT(wk3, ipnt_ref, Int32(ilimit), JFROUT,                     Int32(3),           Int32(2))
    IFWRIT(wk3, ipnt_ref, Int32(ilimit), JLOUT,                      Int32(3),           Int32(2))
    IFWRIT(wk3, ipnt_ref, Int32(ilimit), MPS,                         Int32(8),           Int32(2))
    IFWRIT(wk3, ipnt_ref, Int32(ilimit), PLSIZ,                       Int32(2),           Int32(2))
    IFWRIT(wk3, ipnt_ref, Int32(ilimit), POTSEAS,                     Int32(2),           Int32(2))
    IFWRIT(wk3, ipnt_ref, Int32(ilimit), POTTYP,                      Int32(2),           Int32(2))
    IFWRIT(wk3, ipnt_ref, Int32(ilimit), view(SPS,     1:nsnagz),    Int32(nsnagz),      Int32(2))
    IFWRIT(wk3, ipnt_ref, Int32(ilimit), view(SPSSALV, 1:nsnagz),    Int32(nsnagz),      Int32(2))
    IFWRIT(wk3, ipnt_ref, Int32(ilimit), reshape(SURFVL, :),          Int32(MXDFMD*2*4),  Int32(2))
    IFWRIT(wk3, ipnt_ref, Int32(ilimit), view(YRDEAD,  1:nsnagz),    Int32(nsnagz),      Int32(2))
    IFWRIT(wk3, ipnt_ref, Int32(ilimit), FMICR,                       Int32(MAXTRE),      Int32(2))
    IFWRIT(wk3, ipnt_ref, Int32(ilimit), IFUELMON,                    Int32(MXDFMD),      Int32(2))
    IFWRIT(wk3, ipnt_ref, Int32(ilimit), ISPCC,                       Int32(MAXTRE),      Int32(2))

    logics[ 1] = LANHED
    logics[ 2] = LATFUEL
    logics[ 3] = LDHEAD
    logics[ 4] = LDYNFM
    logics[ 5] = LFLBRN
    logics[ 6] = LFMON
    logics[ 7] = LFMON2
    logics[ 8] = LHEAD
    logics[ 9] = LREMT
    logics[10] = LSHEAD
    logics[11] = LUSRFM
    logics[12] = LATSHRB
    logics[13] = LVWEST
    logics[14] = LPRV89
    logics[15] = CFIM_ON
    LFWRIT(wk3, ipnt_ref, Int32(ilimit), logics,                      Int32(mxl),         Int32(2))

    LFWRIT(wk3, ipnt_ref, Int32(ilimit), view(HARD_FM,   1:nsnagz),  Int32(nsnagz),      Int32(2))
    LFWRIT(wk3, ipnt_ref, Int32(ilimit), view(HARDSALV,  1:nsnagz),  Int32(nsnagz),      Int32(2))
    LFWRIT(wk3, ipnt_ref, Int32(ilimit), LFROUT,                      Int32(3),           Int32(2))
    LFWRIT(wk3, ipnt_ref, Int32(ilimit), LSW,                         Int32(MAXSP),       Int32(2))

    reals[  1] = BURNCR
    reals[  2] = CBD
    reals[  3] = CRBURN
    reals[  4] = CWDCUT
    reals[  5] = DEPTH
    reals[  6] = DPMOD
    reals[  7] = EXPOSR
    reals[  8] = FLAMEHT
    reals[  9] = FLPART
    reals[ 10] = FMSLOP
    reals[ 11] = FWIND
    reals[ 12] = HTR1
    reals[ 13] = HTR2
    reals[ 14] = HTXSFT
    reals[ 15] = LARGE
    reals[ 16] = LIMBRK
    reals[ 17] = MINSOL
    reals[ 18] = NZERO
    reals[ 19] = OLARGE
    reals[ 20] = OSMALL
    reals[ 21] = PBRNCR
    reals[ 22] = PBSCOR
    reals[ 23] = PBSIZE
    reals[ 24] = PBSMAL
    reals[ 25] = PBSOFT
    reals[ 26] = PBTIME
    reals[ 27] = PERCOV
    reals[ 28] = PRSNAG
    reals[ 29] = RFINAL
    reals[ 30] = SCCF
    reals[ 31] = SCH
    reals[ 32] = SLCHNG
    reals[ 33] = SLCRIT
    reals[ 34] = SMALL
    reals[ 35] = TCLOAD
    reals[ 36] = TONRMC
    reals[ 37] = TONRMH
    reals[ 38] = TONRMS
    reals[ 39] = TOTACR
    reals[ 40] = CCCHNG
    reals[ 41] = CCCRIT
    reals[ 42] = PRV8
    reals[ 43] = PRV9
    reals[ 44] = CANMHT
    reals[ 45] = CBHCUT
    reals[ 46] = CRDCAY
    reals[ 47] = BIOLIVE
    reals[ 48] = BIOSNAG
    reals[ 49] = BIODDW
    reals[ 50] = BIOFLR
    reals[ 51] = BIOSHRB
    reals[ 52] = BIOROOT
    reals[ 53] = ULHV
    reals[ 54] = FOLMC
    reals[ 55] = CFIM_BD
    reals[ 56] = CFIM_DC
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), reals, Int32(mxr), Int32(2))

    BFWRIT(wk3, ipnt_ref, Int32(ilimit), ALLDWN,                      Int32(MAXSP),          Int32(2))
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), CANCLS,                      Int32(4),              Int32(2))
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), CATCHUP,                     Int32(NFLPTS),         Int32(2))
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), CORFAC,                      Int32(4),              Int32(2))
    # CROWNW/OLDCRW: Fortran CROWNW(MAXTRE,0:5) → Julia CROWNW[i, col+1]; loop col=0:5
    for col in 0:5
        BFWRIT(wk3, ipnt_ref, Int32(ilimit), view(CROWNW, 1:Int(ITRN), col+1), Int32(ITRN), Int32(2))
        BFWRIT(wk3, ipnt_ref, Int32(ilimit), view(OLDCRW, 1:Int(ITRN), col+1), Int32(ITRN), Int32(2))
    end
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), view(CURKIL, 1:Int(ITRN)),   Int32(ITRN),           Int32(2))
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), reshape(CWD, :),             Int32(3*MXFLCL*2*5),   Int32(2))
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), reshape(CWD2B,  :),          Int32(4*6*TFMAX),      Int32(2))
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), reshape(CWD2B2, :),          Int32(4*6*TFMAX),      Int32(2))
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), reshape(CWDNEW, :),          Int32(2*MXFLCL),       Int32(2))
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), view(DBHS,      1:nsnagz),   Int32(nsnagz),         Int32(2))
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), view(DBHSSALV,  1:nsnagz),   Int32(nsnagz),         Int32(2))
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), DECAYX,                      Int32(MAXSP),          Int32(2))
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), view(DEND,      1:nsnagz),   Int32(nsnagz),         Int32(2))
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), view(DENIH,     1:nsnagz),   Int32(nsnagz),         Int32(2))
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), view(DENIS,     1:nsnagz),   Int32(nsnagz),         Int32(2))
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), reshape(DKR,    :),          Int32(MXFLCL*4),       Int32(2))
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), DKRDEF,                      Int32(4),              Int32(2))
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), reshape(DSPDBH, :),          Int32(MAXSP*19),       Int32(2))
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), FALLX,                       Int32(MAXSP),          Int32(2))
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), FIRACR,                      Int32(2),              Int32(2))
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), FLIVE,                       Int32(2),              Int32(2))
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), FMACRE,                      Int32(14),             Int32(2))
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), FMDEP,                       Int32(MXDFMD),         Int32(2))
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), reshape(FMLOAD, :),          Int32(MXDFMD*2*7),     Int32(2))
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), FMTBA,                       Int32(MAXSP),          Int32(2))
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), FMY1,                        Int32(NFLPTS),         Int32(2))
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), FMY2,                        Int32(NFLPTS),         Int32(2))
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), reshape(FUAREA, :),          Int32(5*4),            Int32(2))
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), reshape(FWG,    :),          Int32(2*7),            Int32(2))
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), FWT,                         Int32(MXFMOD),         Int32(2))
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), FWTUSR,                      Int32(4),              Int32(2))
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), view(HTDEAD,    1:nsnagz),   Int32(nsnagz),         Int32(2))
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), view(HTDEADSALV,1:nsnagz),   Int32(nsnagz),         Int32(2))
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), view(HTIH,      1:nsnagz),   Int32(nsnagz),         Int32(2))
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), view(HTIHSALV,  1:nsnagz),   Int32(nsnagz),         Int32(2))
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), view(HTIS,      1:nsnagz),   Int32(nsnagz),         Int32(2))
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), view(HTISSALV,  1:nsnagz),   Int32(nsnagz),         Int32(2))
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), reshape(HTX,    :),          Int32(MAXSP*4),        Int32(2))
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), LEAFLF,                      Int32(MAXSP),          Int32(2))
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), LOWDBH,                      Int32(7),              Int32(2))
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), reshape(MAXHT,  :),          Int32(MAXSP*19),       Int32(2))
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), MEXT,                        Int32(3),              Int32(2))
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), reshape(MINHT,  :),          Int32(MAXSP*19),       Int32(2))
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), reshape(MOIS,   :),          Int32(2*5),            Int32(2))
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), MOISEX,                      Int32(MXDFMD),         Int32(2))
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), OFFSET,                      Int32(NFLPTS),         Int32(2))
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), view(OLDCRL,    1:Int(ITRN)),Int32(ITRN),           Int32(2))
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), view(OLDHT,     1:Int(ITRN)),Int32(ITRN),           Int32(2))
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), view(PBFRIH,    1:nsnagz),   Int32(nsnagz),         Int32(2))
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), view(PBFRIS,    1:nsnagz),   Int32(nsnagz),         Int32(2))
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), reshape(PFLACR, :),          Int32(4*3),            Int32(2))
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), PFLAM,                       Int32(4),              Int32(2))
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), POTEMP,                      Int32(2),              Int32(2))
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), POTFSR,                      Int32(4),              Int32(2))
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), POTKIL,                      Int32(4),              Int32(2))
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), POTPAB,                      Int32(2),              Int32(2))
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), POTRINT,                     Int32(2),              Int32(2))
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), POTVOL,                      Int32(2),              Int32(2))
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), reshape(PRDUFF, :),          Int32(MXFLCL*4),       Int32(2))
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), reshape(PRESVL, :),          Int32(2*8),            Int32(2))
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), PREWND,                      Int32(2),              Int32(2))
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), PRPILE,                      Int32(MXFLCL),         Int32(2))
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), PSOFT,                       Int32(MAXSP),          Int32(2))
    # SALVSPA is (MXSNAG,2); write nsnagz rows from each column separately
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), view(SALVSPA, 1:nsnagz, 1), Int32(nsnagz),         Int32(2))
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), view(SALVSPA, 1:nsnagz, 2), Int32(nsnagz),         Int32(2))
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), SCBE,                        Int32(3),              Int32(2))
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), SFRATE,                      Int32(3),              Int32(2))
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), SIRXI,                       Int32(3),              Int32(2))
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), SMOKE,                       Int32(2),              Int32(2))
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), view(SNGNEW,   1:nsnagz),   Int32(nsnagz),         Int32(2))
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), SNPRCL,                      Int32(6),              Int32(2))
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), SPHIS,                       Int32(3),              Int32(2))
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), SRHOBQ,                      Int32(3),              Int32(2))
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), SSIGMA,                      Int32(3),              Int32(2))
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), SXIR,                        Int32(3),              Int32(2))
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), TCWD,                        Int32(6),              Int32(2))
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), TCWD2,                       Int32(6),              Int32(2))
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), reshape(TFALL,  :),          Int32(MAXSP*6),        Int32(2))
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), reshape(TODUFF, :),          Int32(MXFLCL*4),       Int32(2))
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), V2T,                         Int32(MAXSP),          Int32(2))
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), reshape(BURNED, :),          Int32(3*MXFLCL),       Int32(2))
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), BURNLV,                      Int32(2),              Int32(2))
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), FIRKIL,                      Int32(MAXTRE),         Int32(2))
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), FMPROB,                      Int32(MAXTRE),         Int32(2))
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), OLDICTWT,                    Int32(2),              Int32(2))
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), CDBRK,                       Int32(2),              Int32(2))
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), BIOCON,                      Int32(2),              Int32(2))
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), BIOREM,                      Int32(2),              Int32(2))
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), reshape(FATE,   :),          Int32(2*2*MAXCYC),     Int32(2))
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), CARBVAL,                     Int32(17),             Int32(2))
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), USAV,                        Int32(3),              Int32(2))
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), UBD,                         Int32(2),              Int32(2))
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), reshape(CWDVOL, :),          Int32(3*10*2*5),       Int32(2))
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), reshape(CWDCOV, :),          Int32(3*10*2*5),       Int32(2))
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), PREMST,                      Int32(MAXTRE),         Int32(2))
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), PREMCR,                      Int32(MAXTRE),         Int32(2))
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), DBHC,                        Int32(MAXTRE),         Int32(2))
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), HTC,                         Int32(MAXTRE),         Int32(2))
    # CROWNWC is (MAXTRE,6); reshape gives MAXTRE*6 in column-major order
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), reshape(CROWNWC, :),         Int32(MAXTRE*6),       Int32(2))
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), reshape(SETDECAY,:),         Int32(MXFLCL*4),       Int32(2))
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), reshape(CFIM_INPUT,:),       Int32(26),             Int32(2))
    BFWRIT(wk3, ipnt_ref, Int32(ilimit), reshape(POTCONS, :),         Int32(3*3),            Int32(2))
    return nothing
end
