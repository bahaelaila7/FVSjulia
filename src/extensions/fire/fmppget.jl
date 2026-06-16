# fire/fmppget.f — Stop/restart GET: deserialize fire model state from WK3 buffer
# Exact mirror of FMPPPUT: reads in the same order using IFREAD/LFREAD/BFREAD.
# Called from: restart read path

function FMPPGET(wk3::AbstractVector{Float32}, ipnt_ref::Ref{Int32}, ilimit::Integer)
    local mxi = 86
    local mxl = 15
    local mxr = 56
    local ints   = zeros(Int32,  mxi)
    local logics = fill(false,   mxl)
    local reals  = zeros(Float32, mxr)

    IFREAD(wk3, ipnt_ref, Int32(ilimit), ints, Int32(mxi), Int32(2))
    global IFMTYP    = ints[  1]
    global ACTCBH    = ints[  2]
    global ATEMP     = ints[  3]
    global BURNYR    = ints[  4]
    global COVTYP    = ints[  5]
    global FIRTYPE   = ints[  6]
    global FMKOD     = ints[  7]
    global FTREAT    = ints[  8]
    global HARTYP    = ints[  9]
    global HARVYR    = ints[ 10]
    global IBRPAS    = ints[ 11]
    global IDBRN     = ints[ 12]
    global IDFLAL    = ints[ 13]
    global IDFUL     = ints[ 14]
    global IDMRT     = ints[ 15]
    global IDPFLM    = ints[ 16]
    global IDRYB     = ints[ 17]
    global IDRYE     = ints[ 18]
    global IFAPAS    = ints[ 19]
    global IFLALB    = ints[ 20]
    global IFLALE    = ints[ 21]
    global IFLPAS    = ints[ 22]
    global IFMBRB    = ints[ 23]
    global IFMBRE    = ints[ 24]
    global IFMFLB    = ints[ 25]
    global IFMFLE    = ints[ 26]
    global IFMMRB    = ints[ 27]
    global IFMMRE    = ints[ 28]
    global IFMYR1    = ints[ 29]
    global IFMYR2    = ints[ 30]
    global IFTYR     = ints[ 31]
    global IMRPAS    = ints[ 32]
    global IPFLMB    = ints[ 33]
    global IPFLME    = ints[ 34]
    global IPFPAS    = ints[ 35]
    global ISALVC    = ints[ 36]
    global ISALVS    = ints[ 37]
    global ISNAGB    = ints[ 38]
    global ISNAGE    = ints[ 39]
    global ISNGSM    = ints[ 40]
    global JCOUT     = ints[ 41]
    global JSNOUT    = ints[ 42]
    global ND        = ints[ 43]
    global NFMODS    = ints[ 44]
    global NFMSVPX   = ints[ 45]
    global NL        = ints[ 46]
    global NSNAG     = ints[ 47]
    global OLDCOVTYP = ints[ 48]
    global OLDICT    = ints[ 49]
    global OLDICT2   = ints[ 50]
    global PBURNYR   = ints[ 51]
    global FM89YR    = ints[ 52]
    global ICBHMT    = ints[ 53]
    global ICANSP    = ints[ 54]
    global BURNSEAS  = ints[ 55]
    global IDSHEAT   = ints[ 56]
    global ISHEATB   = ints[ 57]
    global ISHEATE   = ints[ 58]
    global SOILTP    = ints[ 59]
    global ICFPB     = ints[ 60]
    global ICFPE     = ints[ 61]
    global NSNAGSALV = ints[ 62]
    global NYRS      = ints[ 63]
    global ICHABT    = ints[ 64]
    global ICHPAS    = ints[ 65]
    global ICHRVB    = ints[ 66]
    global ICHRVE    = ints[ 67]
    global ICMETRC   = ints[ 68]
    global ICMETH    = ints[ 69]
    global ICRPAS    = ints[ 70]
    global ICRPTB    = ints[ 71]
    global ICRPTE    = ints[ 72]
    global IDCHRV    = ints[ 73]
    global IDCRPT    = ints[ 74]
    global IFLOGIC   = ints[ 75]
    global IFMSET    = ints[ 76]
    global ICYCRM    = ints[ 77]
    global ITRNL     = ints[ 78]
    global IDWPAS    = ints[ 79]
    global IDWRPB    = ints[ 80]
    global IDWRPE    = ints[ 81]
    global IDCPAS    = ints[ 82]
    global IDWCVB    = ints[ 83]
    global IDWCVE    = ints[ 84]
    global IDDWRP    = ints[ 85]
    global IDDWCV    = ints[ 86]

    local nsnagz = max(Int(NSNAG), 1)
    IFREAD(wk3, ipnt_ref, Int32(ilimit), DKRCLS,                      Int32(MAXSP),       Int32(2))
    IFREAD(wk3, ipnt_ref, Int32(ilimit), FLAG,                         Int32(3),           Int32(2))
    IFREAD(wk3, ipnt_ref, Int32(ilimit), FMDUSR,                      Int32(4),           Int32(2))
    IFREAD(wk3, ipnt_ref, Int32(ilimit), FMOD,                         Int32(MXFMOD),      Int32(2))
    IFREAD(wk3, ipnt_ref, Int32(ilimit), view(GROW_FM, 1:Int(ITRN)),  Int32(ITRN),        Int32(2))
    IFREAD(wk3, ipnt_ref, Int32(ilimit), view(IOBJTPTMP, 1:Int(NSVOBJ)), Int32(NSVOBJ),   Int32(2))
    IFREAD(wk3, ipnt_ref, Int32(ilimit), view(IS2FTMP,   1:Int(NSVOBJ)), Int32(NSVOBJ),   Int32(2))
    IFREAD(wk3, ipnt_ref, Int32(ilimit), JFROUT,                       Int32(3),           Int32(2))
    IFREAD(wk3, ipnt_ref, Int32(ilimit), JLOUT,                        Int32(3),           Int32(2))
    IFREAD(wk3, ipnt_ref, Int32(ilimit), MPS,                          Int32(8),           Int32(2))
    IFREAD(wk3, ipnt_ref, Int32(ilimit), PLSIZ,                        Int32(2),           Int32(2))
    IFREAD(wk3, ipnt_ref, Int32(ilimit), POTSEAS,                      Int32(2),           Int32(2))
    IFREAD(wk3, ipnt_ref, Int32(ilimit), POTTYP,                       Int32(2),           Int32(2))
    IFREAD(wk3, ipnt_ref, Int32(ilimit), view(SPS,     1:nsnagz),     Int32(nsnagz),      Int32(2))
    IFREAD(wk3, ipnt_ref, Int32(ilimit), view(SPSSALV, 1:nsnagz),     Int32(nsnagz),      Int32(2))
    IFREAD(wk3, ipnt_ref, Int32(ilimit), reshape(SURFVL, :),           Int32(MXDFMD*2*4),  Int32(2))
    IFREAD(wk3, ipnt_ref, Int32(ilimit), view(YRDEAD,  1:nsnagz),     Int32(nsnagz),      Int32(2))
    IFREAD(wk3, ipnt_ref, Int32(ilimit), FMICR,                        Int32(MAXTRE),      Int32(2))
    IFREAD(wk3, ipnt_ref, Int32(ilimit), IFUELMON,                     Int32(MXDFMD),      Int32(2))
    IFREAD(wk3, ipnt_ref, Int32(ilimit), ISPCC,                        Int32(MAXTRE),      Int32(2))

    LFREAD(wk3, ipnt_ref, Int32(ilimit), logics, Int32(mxl), Int32(2))
    global LANHED  = logics[ 1]
    global LATFUEL = logics[ 2]
    global LDHEAD  = logics[ 3]
    global LDYNFM  = logics[ 4]
    global LFLBRN  = logics[ 5]
    global LFMON   = logics[ 6]
    global LFMON2  = logics[ 7]
    global LHEAD   = logics[ 8]
    global LREMT   = logics[ 9]
    global LSHEAD  = logics[10]
    global LUSRFM  = logics[11]
    global LATSHRB = logics[12]
    global LVWEST  = logics[13]
    global LPRV89  = logics[14]
    global CFIM_ON = logics[15]

    LFREAD(wk3, ipnt_ref, Int32(ilimit), view(HARD_FM,   1:nsnagz),  Int32(nsnagz),      Int32(2))
    LFREAD(wk3, ipnt_ref, Int32(ilimit), view(HARDSALV,  1:nsnagz),  Int32(nsnagz),      Int32(2))
    LFREAD(wk3, ipnt_ref, Int32(ilimit), LFROUT,                       Int32(3),           Int32(2))
    LFREAD(wk3, ipnt_ref, Int32(ilimit), LSW,                          Int32(MAXSP),       Int32(2))

    BFREAD(wk3, ipnt_ref, Int32(ilimit), reals, Int32(mxr), Int32(2))
    global BURNCR  = reals[  1]
    global CBD     = reals[  2]
    global CRBURN  = reals[  3]
    global CWDCUT  = reals[  4]
    global DEPTH   = reals[  5]
    global DPMOD   = reals[  6]
    global EXPOSR  = reals[  7]
    global FLAMEHT = reals[  8]
    global FLPART  = reals[  9]
    global FMSLOP  = reals[ 10]
    global FWIND   = reals[ 11]
    global HTR1    = reals[ 12]
    global HTR2    = reals[ 13]
    global HTXSFT  = reals[ 14]
    global LARGE   = reals[ 15]
    global LIMBRK  = reals[ 16]
    global MINSOL  = reals[ 17]
    global NZERO   = reals[ 18]
    global OLARGE  = reals[ 19]
    global OSMALL  = reals[ 20]
    global PBRNCR  = reals[ 21]
    global PBSCOR  = reals[ 22]
    global PBSIZE  = reals[ 23]
    global PBSMAL  = reals[ 24]
    global PBSOFT  = reals[ 25]
    global PBTIME  = reals[ 26]
    global PERCOV  = reals[ 27]
    global PRSNAG  = reals[ 28]
    global RFINAL  = reals[ 29]
    global SCCF    = reals[ 30]
    global SCH     = reals[ 31]
    global SLCHNG  = reals[ 32]
    global SLCRIT  = reals[ 33]
    global SMALL   = reals[ 34]
    global TCLOAD  = reals[ 35]
    global TONRMC  = reals[ 36]
    global TONRMH  = reals[ 37]
    global TONRMS  = reals[ 38]
    global TOTACR  = reals[ 39]
    global CCCHNG  = reals[ 40]
    global CCCRIT  = reals[ 41]
    global PRV8    = reals[ 42]
    global PRV9    = reals[ 43]
    global CANMHT  = reals[ 44]
    global CBHCUT  = reals[ 45]
    global CRDCAY  = reals[ 46]
    global BIOLIVE = reals[ 47]
    global BIOSNAG = reals[ 48]
    global BIODDW  = reals[ 49]
    global BIOFLR  = reals[ 50]
    global BIOSHRB = reals[ 51]
    global BIOROOT = reals[ 52]
    global ULHV    = reals[ 53]
    global FOLMC   = reals[ 54]
    global CFIM_BD = reals[ 55]
    global CFIM_DC = reals[ 56]

    BFREAD(wk3, ipnt_ref, Int32(ilimit), ALLDWN,                       Int32(MAXSP),          Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), CANCLS,                       Int32(4),              Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), CATCHUP,                      Int32(NFLPTS),         Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), CORFAC,                       Int32(4),              Int32(2))
    for col in 0:5
        BFREAD(wk3, ipnt_ref, Int32(ilimit), view(CROWNW, 1:Int(ITRN), col+1), Int32(ITRN),  Int32(2))
        BFREAD(wk3, ipnt_ref, Int32(ilimit), view(OLDCRW, 1:Int(ITRN), col+1), Int32(ITRN),  Int32(2))
    end
    BFREAD(wk3, ipnt_ref, Int32(ilimit), view(CURKIL, 1:Int(ITRN)),    Int32(ITRN),           Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), reshape(CWD, :),              Int32(3*MXFLCL*2*5),   Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), reshape(CWD2B,  :),           Int32(4*6*TFMAX),      Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), reshape(CWD2B2, :),           Int32(4*6*TFMAX),      Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), reshape(CWDNEW, :),           Int32(2*MXFLCL),       Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), view(DBHS,      1:nsnagz),    Int32(nsnagz),         Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), view(DBHSSALV,  1:nsnagz),    Int32(nsnagz),         Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), DECAYX,                       Int32(MAXSP),          Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), view(DEND,      1:nsnagz),    Int32(nsnagz),         Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), view(DENIH,     1:nsnagz),    Int32(nsnagz),         Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), view(DENIS,     1:nsnagz),    Int32(nsnagz),         Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), reshape(DKR,    :),           Int32(MXFLCL*4),       Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), DKRDEF,                       Int32(4),              Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), reshape(DSPDBH, :),           Int32(MAXSP*19),       Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), FALLX,                        Int32(MAXSP),          Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), FIRACR,                       Int32(2),              Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), FLIVE,                        Int32(2),              Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), FMACRE,                       Int32(14),             Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), FMDEP,                        Int32(MXDFMD),         Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), reshape(FMLOAD, :),           Int32(MXDFMD*2*7),     Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), FMTBA,                        Int32(MAXSP),          Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), FMY1,                         Int32(NFLPTS),         Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), FMY2,                         Int32(NFLPTS),         Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), reshape(FUAREA, :),           Int32(5*4),            Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), reshape(FWG,    :),           Int32(2*7),            Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), FWT,                          Int32(MXFMOD),         Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), FWTUSR,                       Int32(4),              Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), view(HTDEAD,    1:nsnagz),    Int32(nsnagz),         Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), view(HTDEADSALV,1:nsnagz),    Int32(nsnagz),         Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), view(HTIH,      1:nsnagz),    Int32(nsnagz),         Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), view(HTIHSALV,  1:nsnagz),    Int32(nsnagz),         Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), view(HTIS,      1:nsnagz),    Int32(nsnagz),         Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), view(HTISSALV,  1:nsnagz),    Int32(nsnagz),         Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), reshape(HTX,    :),           Int32(MAXSP*4),        Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), LEAFLF,                       Int32(MAXSP),          Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), LOWDBH,                       Int32(7),              Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), reshape(MAXHT,  :),           Int32(MAXSP*19),       Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), MEXT,                         Int32(3),              Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), reshape(MINHT,  :),           Int32(MAXSP*19),       Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), reshape(MOIS,   :),           Int32(2*5),            Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), MOISEX,                       Int32(MXDFMD),         Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), OFFSET,                       Int32(NFLPTS),         Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), view(OLDCRL,    1:Int(ITRN)), Int32(ITRN),           Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), view(OLDHT,     1:Int(ITRN)), Int32(ITRN),           Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), view(PBFRIH,    1:nsnagz),    Int32(nsnagz),         Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), view(PBFRIS,    1:nsnagz),    Int32(nsnagz),         Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), reshape(PFLACR, :),           Int32(4*3),            Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), PFLAM,                        Int32(4),              Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), POTEMP,                       Int32(2),              Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), POTFSR,                       Int32(4),              Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), POTKIL,                       Int32(4),              Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), POTPAB,                       Int32(2),              Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), POTRINT,                      Int32(2),              Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), POTVOL,                       Int32(2),              Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), reshape(PRDUFF, :),           Int32(MXFLCL*4),       Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), reshape(PRESVL, :),           Int32(2*8),            Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), PREWND,                       Int32(2),              Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), PRPILE,                       Int32(MXFLCL),         Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), PSOFT,                        Int32(MAXSP),          Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), view(SALVSPA, 1:nsnagz, 1),  Int32(nsnagz),         Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), view(SALVSPA, 1:nsnagz, 2),  Int32(nsnagz),         Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), SCBE,                         Int32(3),              Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), SFRATE,                       Int32(3),              Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), SIRXI,                        Int32(3),              Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), SMOKE,                        Int32(2),              Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), view(SNGNEW,   1:nsnagz),    Int32(nsnagz),         Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), SNPRCL,                       Int32(6),              Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), SPHIS,                        Int32(3),              Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), SRHOBQ,                       Int32(3),              Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), SSIGMA,                       Int32(3),              Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), SXIR,                         Int32(3),              Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), TCWD,                         Int32(6),              Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), TCWD2,                        Int32(6),              Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), reshape(TFALL,  :),           Int32(MAXSP*6),        Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), reshape(TODUFF, :),           Int32(MXFLCL*4),       Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), V2T,                          Int32(MAXSP),          Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), reshape(BURNED, :),           Int32(3*MXFLCL),       Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), BURNLV,                       Int32(2),              Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), FIRKIL,                       Int32(MAXTRE),         Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), FMPROB,                       Int32(MAXTRE),         Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), OLDICTWT,                     Int32(2),              Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), CDBRK,                        Int32(2),              Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), BIOCON,                       Int32(2),              Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), BIOREM,                       Int32(2),              Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), reshape(FATE,   :),           Int32(2*2*MAXCYC),     Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), CARBVAL,                      Int32(17),             Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), USAV,                         Int32(3),              Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), UBD,                          Int32(2),              Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), reshape(CWDVOL, :),           Int32(3*10*2*5),       Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), reshape(CWDCOV, :),           Int32(3*10*2*5),       Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), PREMST,                       Int32(MAXTRE),         Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), PREMCR,                       Int32(MAXTRE),         Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), DBHC,                         Int32(MAXTRE),         Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), HTC,                          Int32(MAXTRE),         Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), reshape(CROWNWC, :),          Int32(MAXTRE*6),       Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), reshape(SETDECAY,:),          Int32(MXFLCL*4),       Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), reshape(CFIM_INPUT,:),        Int32(26),             Int32(2))
    BFREAD(wk3, ipnt_ref, Int32(ilimit), reshape(POTCONS, :),          Int32(3*3),            Int32(2))
    return nothing
end
