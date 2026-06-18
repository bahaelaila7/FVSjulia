# sn/grinit.f — GRINIT: initialize model variables for sn variant
# Translated from: bin/FVSsn_buildDir/grinit.f (340 lines)
#
# Called once at stand initialization (from FVS! before the cycle loop).
# Sets all per-species arrays and scalar globals to their default values,
# then calls LNKINT and DBINIT.

function GRINIT()
    global VARACD  = "SN"
    global ECOREG  = "    "
    global CFCTYPE = "F"
    global BFCTYPE = "F"

    LNKINT()

    for i in 1:Int(MAXSP)
        IORDER[i]   = Int32(0)
        COR[i]      = Float32(0)
        XDMULT[i]   = Float32(1)
        XHMULT[i]   = Float32(1)
        XRDMLT[i]   = Float32(1)
        XRHMLT[i]   = Float32(1)
        XMMULT[i]   = Float32(1)
        XMDIA1[i]   = Float32(0)
        XMDIA2[i]   = Float32(99999)
        VEQNNB[i]   = "           "
        VEQNNC[i]   = "           "
        STMP[i]     = Float32(0.5)
        TOPD[i]     = Float32(0)
        DBHMIN[i]   = Float32(0)
        FRMCLS[i]   = Float32(80)
        METHB[i]    = Int32(6)
        METHC[i]    = Int32(6)
        BFSTMP[i]   = Float32(1)
        BFTOPD[i]   = Float32(0)
        BFMIND[i]   = Float32(0)
        SCFSTMP[i]  = Float32(1)
        SCFMIND[i]  = Float32(0)
        SCFTOPD[i]  = Float32(0)
        BFLA0[i]    = Float32(0)
        BFLA1[i]    = Float32(1)
        CFLA0[i]    = Float32(0)
        CFLA1[i]    = Float32(1)
        LDGCAL[i]   = true
        LHTCAL[i]   = true
        LHTDRG[i]   = false
        IABFLG[i]   = Int32(1)
        BARANK[i]   = Float32(0)
        MAXSDI[i]   = Int32(0)
        SDIDEF[i]   = Float32(0)
        SITEAR[i]   = Float32(0)
        LSPCWE[i]   = false
        CWDS0[i]    = Float32(0)
        CWDS1[i]    = Float32(0)
        CWDS2[i]    = Float32(0)
        CWDS3[i]    = Float32(2)
        CWDL0[i]    = Float32(0)
        CWDL1[i]    = Float32(0)
        CWDL2[i]    = Float32(0)
        CWDL3[i]    = Float32(2)
        CWTDBH[i]   = Float32(0)
        SIZCAP[i,1] = Float32(999)
        SIZCAP[i,2] = Float32(1)
        SIZCAP[i,3] = Float32(0)
        SIZCAP[i,4] = Float32(999)
        JSPIN[i]    = Int32(3)
        LEAVESP[i]  = false
    end

    global LFLAGV  = false
    global LBAMAX  = false
    global LZEIDE  = true
    global CALCSDI = " "
    global CFMIN   = Float32(0)
    global SCFMIN  = Float32(0)
    global TCFMIN  = Float32(0)
    global BFMIN   = Float32(0)
    global BAMIN   = Float32(0)
    global TCWT    = Float32(0)
    global SPCLWT  = Float32(0)
    global PBAWT   = Float32(0)
    global PCCFWT  = Float32(0)
    global PTPAWT  = Float32(0)
    global IREC1   = Int32(0)
    global RMAI    = Float32(0)
    global IREC2   = Int32(MAXTP1)
    global ITHNPI  = Int32(1)
    global ITHNPN  = Int32(-1)
    global ITHNPA  = Int32(0)

    for i in 1:Int(MAXCYC)
        IY[i] = Int32(5)
    end
    IY[1]       = Int32(0)
    IY[MAXCY1]  = Int32(-1)
    fill!(ITABLE, Int32(0))

    global MANAGD  = Int32(0)
    global ISTDORG = Int32(0)
    global ALPHA_V = Float32(0.05)
    global BJPHI   = Float32(0.74)
    global BJTHET  = Float32(0.42)
    global ASPECT  = Float32(0)
    global LAUTON  = false
    global LFIA    = false
    global LFIANVB = false
    global AUTMAX  = Float32(60)
    global AUTMIN  = Float32(45)
    global BAF     = Float32(40)
    global BAMAX   = Float32(0)
    global BRK     = Float32(5)
    global DGSD    = Float32(2)
    global EFF     = Float32(1)
    global ELEV    = Float32(0)
    global FINT    = Float32(5)
    global FINTH   = Float32(5)
    global FINTM   = Float32(5)
    global FPA     = Float32(300)
    global IAGE    = Int32(0)
    IWORK1[1]    = Int32(0)

    global ICL4    = Int32(2)
    global ICL5    = Int32(999)
    global ICL6    = Int32(0)
    global IDG     = Int32(0)
    global IFINT   = Int32(5)
    global IFINTH  = Int32(5)
    global IFOR    = Int32(1)
    global KODFOR  = Int32(0)
    global IFST    = Int32(1)
    global IGL     = Int32(2)
    global IHTG    = Int32(0)
    global IPTINV  = Int32(-9999)
    global ITYPE   = Int32(0)
    global KODTYP  = Int32(0)
    global CPVREF  = "          "
    global PCOMX   = "        "
    global KODIST  = Int32(6)
    global ISEFOR  = Int32(0)
    global LDCOR2  = false
    global LDUBDG  = false
    global LEVUSE  = true    # grinit.f:205 (so EVTSTV(0) runs every stand → MAI computed)
    global LFIXSD  = false
    global LHCOR2  = false
    global LRCOR2  = false
    global LSUMRY  = false
    global MGMID   = "NONE"
    global MORDAT  = false
    global LSTATS  = false
    global LMORT   = false
    global LBVOLS  = false
    global LCVOLS  = false
    global LFIRE   = false
    global LSITE   = false
    global JOCALB  = Int32(0)
    global GROSPC  = Float32(-1)
    global NCYC    = Int32(0)
    global NONSTK  = Int32(-9999)
    global NOTRIP  = false
    global NPLT    = repeat(' ', 26)
    global DBCN    = " "
    global SAMWT   = Float32(-1e25)
    global SLOPE   = Float32(5)
    global TLAT    = Float32(0)
    global TLONG   = Float32(0)
    global ISTATE  = Int32(0)
    global ICNTY   = Int32(0)
    global TFPA    = Float32(0)
    global TRM     = Float32(1)
    global LBKDEN  = false
    global RELDM1  = Float32(0)
    global OLDBA   = Float32(0)
    global ATAVH   = Float32(0)
    global ATBA    = Float32(0)
    global ATCCF   = Float32(0)
    global ORMSQD  = Float32(0)
    global SDIMAX  = Float32(0)
    global SDIBC   = Float32(0)
    global SDIAC   = Float32(0)
    global ISISP   = Int32(0)
    global PMSDIL  = Float32(55)
    global PMSDIU  = Float32(85)
    global SLPMRT  = Float32(0)
    global CEPMRT  = Float32(0)
    global IBASP   = Int32(0)
    global IMODTY  = Int32(0)
    global IPHREG  = Int32(0)
    global IFORTP  = Int32(0)
    global FNMIN   = Float32(5)
    global NCALHT  = Int32(5)
    global ISILFT  = Int32(0)
    global QMDMSB  = Float32(999)
    global SLPMSB  = Float32(0)
    global CEPMSB  = Float32(0)
    global EFFMSB  = Float32(0.90)
    global DLOMSB  = Float32(0)
    global DHIMSB  = Float32(0)
    global MFLMSB  = Int32(1)
    global DBHZEIDE= Float32(0)
    global DBHSTAGE= Float32(0)
    global DR016   = Float32(0)
    global ODR016  = Float32(0)
    global ATDR016 = Float32(0)
    global DBHSDI  = Float32(0)
    global JSPINDEF= Int32(0)
    global CCCOEF  = Float32(1)
    global CCCOEF2 = Float32(1)

    fill!(BFDEFT, Float32(0))
    fill!(CFDEFT, Float32(0))
    fill!(LOGDIA, Float32(0))
    fill!(LOGVOL, Float32(0))

    global LECBUG = false
    global LECON  = false

    DBINIT()

    global MAIFLG = Int32(0)
    global NEWSTD = Int32(0)
    global TOTREM = Float32(0)
    global AGELST = Float32(0)
    fill!(BCYMAI, Float32(0))

    global NPTGRP = Int32(0)
    global NSPGRP = Int32(0)
    fill!(ISPGRP, Int32(0))
    fill!(IPTGRP, Int32(0))
    for i in 1:30
        NAMGRP[i]  = "GROUP$(i)"
        PTGNAME[i] = "PTGROUP$(i)"
    end

    global NSITET = Int32(0)
    fill!(SITETR, Float32(0))

    for i in 1:Int(MAXSP)
        ISTAGF[i] = Int32(0)
    end

    return nothing
end
