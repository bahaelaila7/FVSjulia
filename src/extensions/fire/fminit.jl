# SUBROUTINE FMINIT — fire model initialization
# Translated from: fminit.f (1042 lines)
# Also translates ENTRY points: FMATV, FMSATV, FMLNKD
#
# CALLED FROM: INITRE (stand initialization)

function FMINIT()
    global HARVYR, NSNAG, IFTYR, ISALVC, ISALVS, ICYCRM, ITRNL, NSNAGSALV
    global SMALL, LARGE, OSMALL, OLARGE, SLCHNG, LATFUEL
    global FM89YR, LATSHRB, LPRV89, PERCOV, CCCHNG, PRV8, PRV9
    global IFMYR1, IFMYR2, BURNYR, PBURNYR
    global JSNOUT, LFMON, LFMON2, LHEAD, LSHEAD, ISNGSM, LANHED, LDHEAD, LDYNFM
    global POTPAB, POTSEAS, BURNSEAS, SOILTP
    global ICBHMT, CANMHT, ICANSP, CBHCUT, FOLMC
    global LUSRFM
    global IFLOGIC, IFMSET, ULHV
    global CWDCUT
    global NYRS
    global IFMBRB, IFMBRE, IFMFLB, IFMFLE, IFMMRB, IFMMRE
    global IFLALB, IFLALE, IPFLMB, IPFLME, ISNAGB, ISNAGE
    global ISHEATB, ISHEATE, ICFPB, ICFPE, IDWRPB, IDWRPE, IDWCVB, IDWCVE
    global IDBRN, IDSHEAT, IDFUL, IDMRT, IDFLAL, IDPFLM, IDDWRP, IDDWCV
    global IBRPAS, IFLPAS, IMRPAS, IFAPAS, IPFPAS, IDWPAS, IDCPAS
    global IDCRPT, ICRPTB, ICRPTE, ICRPAS
    global IDCHRV, ICHRVB, ICHRVE, ICHPAS
    global ICMETH, ICMETRC, ICHABT, CRDCAY
    global BIOLIVE, BIOSNAG, BIODDW, BIOFLR, BIOSHRB, BIOROOT
    global LREMT, NFMSVPX

    HARVYR    = Int32(0)
    NSNAG     = Int32(0)
    IFTYR     = Int32(0)
    ISALVC    = Int32(0)
    ISALVS    = Int32(0)
    ICYCRM    = Int32(0)
    ITRNL     = ITRN
    NSNAGSALV = Int32(0)

    fill!(ISPCC, Int32(0))

    fill!(PFLAM,   Float32(0.0))
    fill!(POTKIL,  Float32(0.0))
    fill!(POTFSR,  Float32(0.0))
    fill!(POTVOL,  Float32(0.0))
    fill!(POTTYP,  Int32(0))
    fill!(POTRINT, Float32(0.0))

    for j in 1:MXSNAG
        DENIH[j]      = Float32(0.0)
        DENIS[j]      = Float32(0.0)
        SALVSPA[j, 1] = Float32(0.0)
        SALVSPA[j, 2] = Float32(0.0)
        HTIHSALV[j]   = Float32(0.0)
        HTISSALV[j]   = Float32(0.0)
        SPSSALV[j]    = Int32(0)
        DBHSSALV[j]   = Float32(0.0)
        HARDSALV[j]   = false
        HTDEADSALV[j] = Float32(0.0)
    end

    SMALL   = Float32(0.0)
    LARGE   = Float32(0.0)
    OSMALL  = Float32(0.0)
    OLARGE  = Float32(0.0)
    SLCHNG  = Float32(0.0)
    LATFUEL = false

    # Reset user-adjustable decay rates to "not set" sentinel
    fill!(SETDECAY, Float32(-1.0))

    FM89YR  = Int32(-1)
    LATSHRB = false
    LPRV89  = false
    PERCOV  = Float32(0.0)
    CCCHNG  = Float32(0.0)
    PRV8    = Float32(0.0)
    PRV9    = Float32(0.0)

    fill!(FUAREA, Float32(0.0))

    IFMYR1  = Int32(0)
    IFMYR2  = Int32(0)
    BURNYR  = Int32(-1)
    PBURNYR = Int32(-1)

    CWDCUT   = Float32(0.0)

    JLOUT[1] = Int32(0)
    JLOUT[2] = Int32(0)
    JLOUT[3] = Int32(0)
    JSNOUT   = Int32(35)

    PRESVL[1, 1] = Float32(0.0)
    PRESVL[2, 1] = Float32(0.0)

    LFMON  = false
    LFMON2 = true
    LHEAD  = true
    LSHEAD = true
    ISNGSM = Int32(-1)
    LANHED = true
    LDHEAD = true
    LDYNFM = true

    POTPAB[1]  = Float32(100.0)
    POTPAB[2]  = Float32(100.0)
    POTSEAS[1] = Int32(1)
    POTSEAS[2] = Int32(1)
    BURNSEAS   = Int32(1)
    SOILTP     = Int32(3)

    ICBHMT = Int32(0)
    CANMHT = Float32(6.0)
    ICANSP = Int32(0)
    CBHCUT = Float32(30.0)
    FOLMC  = Float32(100.0)

    LUSRFM = false
    fill!(FMDUSR, Int32(0))
    fill!(FWTUSR, Float32(0.0))

    # -------------------------------------------------------------------
    # Default fuel model variables (can be changed by DEFULMOD keyword)
    # Initialize SAV for all models; then set per-model specific values
    # -------------------------------------------------------------------
    for i in 1:MXDFMD
        SURFVL[i, 1, 2] = Int32(109)
        SURFVL[i, 1, 3] = Int32(30)
        SURFVL[i, 2, 1] = Int32(1500)
        SURFVL[i, 2, 2] = Int32(1500)
        FMLOAD[i, 1, 1] = Float32(0.0)
        FMLOAD[i, 1, 2] = Float32(0.0)
        FMLOAD[i, 1, 3] = Float32(0.0)
        FMLOAD[i, 1, 4] = Float32(0.0)
        FMLOAD[i, 2, 1] = Float32(0.0)
        FMLOAD[i, 2, 2] = Float32(0.0)
        FMDEP[i]        = Float32(0.0)
        MOISEX[i]       = Float32(0.0)
    end

    # FMD 1 — Short Grass
    let i = 1
        SURFVL[i, 1, 1] = Int32(3500)
        FMLOAD[i, 1, 1] = Float32(0.03398)
        FMDEP[i]        = Float32(1.0)
        MOISEX[i]       = Float32(0.12)
    end
    # FMD 2 — Timber (Grass & Understory)
    let i = 2
        SURFVL[i, 1, 1] = Int32(3000)
        FMLOAD[i, 1, 1] = Float32(0.09183)
        FMLOAD[i, 1, 2] = Float32(0.04591)
        FMLOAD[i, 1, 3] = Float32(0.02296)
        FMLOAD[i, 2, 2] = Float32(0.02296)
        FMDEP[i]        = Float32(1.0)
        MOISEX[i]       = Float32(0.15)
    end
    # FMD 3 — Tall Grass (2.5 ft)
    let i = 3
        SURFVL[i, 1, 1] = Int32(1500)
        FMLOAD[i, 1, 1] = Float32(0.13820)
        FMDEP[i]        = Float32(2.5)
        MOISEX[i]       = Float32(0.25)
    end
    # FMD 4 — Chaparral (6 ft)
    let i = 4
        SURFVL[i, 1, 1] = Int32(2000)
        FMLOAD[i, 1, 1] = Float32(0.23003)
        FMLOAD[i, 1, 2] = Float32(0.18411)
        FMLOAD[i, 1, 3] = Float32(0.09183)
        FMLOAD[i, 2, 1] = Float32(0.23003)
        FMDEP[i]        = Float32(6.0)
        MOISEX[i]       = Float32(0.20)
    end
    # FMD 5 — Brush (2 ft)
    let i = 5
        SURFVL[i, 1, 1] = Int32(2000)
        FMLOAD[i, 1, 1] = Float32(0.04591)
        FMLOAD[i, 1, 2] = Float32(0.02296)
        FMLOAD[i, 2, 1] = Float32(0.09183)
        FMDEP[i]        = Float32(2.0)
        MOISEX[i]       = Float32(0.20)
    end
    # FMD 6 — Dormant Brush / Hardwood Slash
    let i = 6
        SURFVL[i, 1, 1] = Int32(1750)
        FMLOAD[i, 1, 1] = Float32(0.06887)
        FMLOAD[i, 1, 2] = Float32(0.11478)
        FMLOAD[i, 1, 3] = Float32(0.09183)
        FMDEP[i]        = Float32(2.5)
        MOISEX[i]       = Float32(0.25)
    end
    # FMD 7 — Southern Rough
    let i = 7
        SURFVL[i, 1, 1] = Int32(1750)
        SURFVL[i, 2, 1] = Int32(1550)
        FMLOAD[i, 1, 1] = Float32(0.05188)
        FMLOAD[i, 1, 2] = Float32(0.08586)
        FMLOAD[i, 1, 3] = Float32(0.06887)
        FMLOAD[i, 2, 1] = Float32(0.01699)
        FMDEP[i]        = Float32(2.5)
        MOISEX[i]       = Float32(0.40)
    end
    # FMD 8 — Closed Timber Litter
    let i = 8
        SURFVL[i, 1, 1] = Int32(2000)
        FMLOAD[i, 1, 1] = Float32(0.06887)
        FMLOAD[i, 1, 2] = Float32(0.04591)
        FMLOAD[i, 1, 3] = Float32(0.11478)
        FMDEP[i]        = Float32(0.2)
        MOISEX[i]       = Float32(0.3)
    end
    # FMD 9 — Hardwood Litter
    let i = 9
        SURFVL[i, 1, 1] = Int32(2500)
        FMLOAD[i, 1, 1] = Float32(0.13407)
        FMLOAD[i, 1, 2] = Float32(0.01882)
        FMLOAD[i, 1, 3] = Float32(0.00689)
        FMDEP[i]        = Float32(0.2)
        MOISEX[i]       = Float32(0.25)
    end
    # FMD 10 — Timber (Litter & Understory)
    let i = 10
        SURFVL[i, 1, 1] = Int32(2000)
        FMLOAD[i, 1, 1] = Float32(0.13820)
        FMLOAD[i, 1, 2] = Float32(0.09183)
        FMLOAD[i, 1, 3] = Float32(0.23003)
        FMLOAD[i, 2, 1] = Float32(0.09183)
        FMDEP[i]        = Float32(1.0)
        MOISEX[i]       = Float32(0.25)
    end
    # FMD 11 — Light Logging Slash
    let i = 11
        SURFVL[i, 1, 1] = Int32(1500)
        FMLOAD[i, 1, 1] = Float32(0.06887)
        FMLOAD[i, 1, 2] = Float32(0.20707)
        FMLOAD[i, 1, 3] = Float32(0.25298)
        FMDEP[i]        = Float32(1.0)
        MOISEX[i]       = Float32(0.15)
    end
    # FMD 12 — Medium Logging Slash
    let i = 12
        SURFVL[i, 1, 1] = Int32(1500)
        FMLOAD[i, 1, 1] = Float32(0.18411)
        FMLOAD[i, 1, 2] = Float32(0.64417)
        FMLOAD[i, 1, 3] = Float32(0.75895)
        FMDEP[i]        = Float32(2.3)
        MOISEX[i]       = Float32(0.2)
    end
    # FMD 13 — Heavy Logging Slash
    let i = 13
        SURFVL[i, 1, 1] = Int32(1500)
        FMLOAD[i, 1, 1] = Float32(0.32185)
        FMLOAD[i, 1, 2] = Float32(1.05785)
        FMLOAD[i, 1, 3] = Float32(1.28788)
        FMDEP[i]        = Float32(3.0)
        MOISEX[i]       = Float32(0.25)
    end
    # FMD 14 — Modified 11 (also called 11A or 111)
    let i = 14
        SURFVL[i, 1, 1] = Int32(1500)
        FMLOAD[i, 1, 1] = Float32(0.126)
        FMLOAD[i, 1, 2] = Float32(0.426)
        FMLOAD[i, 1, 3] = Float32(0.506)
        FMDEP[i]        = Float32(1.8)
        MOISEX[i]       = Float32(0.20)
    end
    # FMD 25 — Ray Hermit (R5): older plantation with shrub understory
    let i = 25
        SURFVL[i, 1, 1] = Int32(2000)
        FMLOAD[i, 1, 1] = Float32(0.069)
        FMLOAD[i, 1, 2] = Float32(0.069)
        FMLOAD[i, 1, 3] = Float32(0.092)
        FMLOAD[i, 2, 1] = Float32(0.207)
        FMDEP[i]        = Float32(3.5)
        MOISEX[i]       = Float32(0.25)
    end
    # FMD 26 — Modified Model 4 brush
    let i = 26
        SURFVL[i, 1, 1] = Int32(2000)
        FMLOAD[i, 1, 1] = Float32(0.1242)
        FMLOAD[i, 1, 2] = Float32(0.1242)
        FMLOAD[i, 1, 3] = Float32(0.0828)
        FMLOAD[i, 2, 1] = Float32(0.1656)
        FMDEP[i]        = Float32(3.6)
        MOISEX[i]       = Float32(0.35)
    end

    # -----------------------------------------------------------------------
    # 40 new fuel models (Scott & Burgan 2005)
    # -----------------------------------------------------------------------

    # GR1 (101) — Short sparse dry climate grass
    let i = 101
        SURFVL[i, 1, 1] = Int32(2200); SURFVL[i, 2, 2] = Int32(2000)
        FMLOAD[i, 1, 1] = Float32(0.00459); FMLOAD[i, 2, 2] = Float32(0.01377)
        FMDEP[i] = Float32(0.4); MOISEX[i] = Float32(0.15)
    end
    # GR2 (102) — Low load dry climate grass
    let i = 102
        SURFVL[i, 1, 1] = Int32(2000); SURFVL[i, 2, 2] = Int32(1800)
        FMLOAD[i, 1, 1] = Float32(0.00459); FMLOAD[i, 2, 2] = Float32(0.04591)
        FMDEP[i] = Float32(1.0); MOISEX[i] = Float32(0.15)
    end
    # GR3 (103) — Low load very coarse humid climate grass
    let i = 103
        SURFVL[i, 1, 1] = Int32(1500); SURFVL[i, 2, 2] = Int32(1300)
        FMLOAD[i, 1, 1] = Float32(0.00459); FMLOAD[i, 1, 2] = Float32(0.01837)
        FMLOAD[i, 2, 2] = Float32(0.06887)
        FMDEP[i] = Float32(2.0); MOISEX[i] = Float32(0.30)
    end
    # GR4 (104) — Moderate load dry climate grass
    let i = 104
        SURFVL[i, 1, 1] = Int32(2000); SURFVL[i, 2, 2] = Int32(1800)
        FMLOAD[i, 1, 1] = Float32(0.01148); FMLOAD[i, 2, 2] = Float32(0.08724)
        FMDEP[i] = Float32(2.0); MOISEX[i] = Float32(0.15)
    end
    # GR5 (105) — Low load humid climate grass
    let i = 105
        SURFVL[i, 1, 1] = Int32(1800); SURFVL[i, 2, 2] = Int32(1600)
        FMLOAD[i, 1, 1] = Float32(0.01837); FMLOAD[i, 2, 2] = Float32(0.11478)
        FMDEP[i] = Float32(1.5); MOISEX[i] = Float32(0.40)
    end
    # GR6 (106) — Moderate load humid climate grass
    let i = 106
        SURFVL[i, 1, 1] = Int32(2200); SURFVL[i, 2, 2] = Int32(2000)
        FMLOAD[i, 1, 1] = Float32(0.00459); FMLOAD[i, 2, 2] = Float32(0.15611)
        FMDEP[i] = Float32(1.5); MOISEX[i] = Float32(0.40)
    end
    # GR7 (107) — High load dry climate grass
    let i = 107
        SURFVL[i, 1, 1] = Int32(2000); SURFVL[i, 2, 2] = Int32(1800)
        FMLOAD[i, 1, 1] = Float32(0.04591); FMLOAD[i, 2, 2] = Float32(0.24793)
        FMDEP[i] = Float32(3.0); MOISEX[i] = Float32(0.15)
    end
    # GR8 (108) — High load very coarse humid climate grass
    let i = 108
        SURFVL[i, 1, 1] = Int32(1500); SURFVL[i, 2, 2] = Int32(1300)
        FMLOAD[i, 1, 1] = Float32(0.02296); FMLOAD[i, 1, 2] = Float32(0.04591)
        FMLOAD[i, 2, 2] = Float32(0.33517)
        FMDEP[i] = Float32(4.0); MOISEX[i] = Float32(0.30)
    end
    # GR9 (109) — Very high load humid climate grass
    let i = 109
        SURFVL[i, 1, 1] = Int32(1800); SURFVL[i, 2, 2] = Int32(1600)
        FMLOAD[i, 1, 1] = Float32(0.04591); FMLOAD[i, 1, 2] = Float32(0.04591)
        FMLOAD[i, 2, 2] = Float32(0.41322)
        FMDEP[i] = Float32(5.0); MOISEX[i] = Float32(0.40)
    end
    # GS1 (121) — Low load dry climate grass-shrub
    let i = 121
        SURFVL[i, 1, 1] = Int32(2000)
        SURFVL[i, 2, 1] = Int32(1800); SURFVL[i, 2, 2] = Int32(1800)
        FMLOAD[i, 1, 1] = Float32(0.00918); FMLOAD[i, 2, 1] = Float32(0.02984)
        FMLOAD[i, 2, 2] = Float32(0.02296)
        FMDEP[i] = Float32(0.9); MOISEX[i] = Float32(0.15)
    end
    # GS2 (122) — Moderate load dry climate grass-shrub
    let i = 122
        SURFVL[i, 1, 1] = Int32(2000)
        SURFVL[i, 2, 1] = Int32(1800); SURFVL[i, 2, 2] = Int32(1800)
        FMLOAD[i, 1, 1] = Float32(0.02296); FMLOAD[i, 1, 2] = Float32(0.02296)
        FMLOAD[i, 2, 1] = Float32(0.04591); FMLOAD[i, 2, 2] = Float32(0.02755)
        FMDEP[i] = Float32(1.5); MOISEX[i] = Float32(0.15)
    end
    # GS3 (123) — Moderate load humid climate grass-shrub
    let i = 123
        SURFVL[i, 1, 1] = Int32(1800)
        SURFVL[i, 2, 1] = Int32(1600); SURFVL[i, 2, 2] = Int32(1600)
        FMLOAD[i, 1, 1] = Float32(0.01377); FMLOAD[i, 1, 2] = Float32(0.01148)
        FMLOAD[i, 2, 1] = Float32(0.05739); FMLOAD[i, 2, 2] = Float32(0.06657)
        FMDEP[i] = Float32(1.8); MOISEX[i] = Float32(0.40)
    end
    # GS4 (124) — High load humid climate grass-shrub
    let i = 124
        SURFVL[i, 1, 1] = Int32(1800)
        SURFVL[i, 2, 1] = Int32(1600); SURFVL[i, 2, 2] = Int32(1600)
        FMLOAD[i, 1, 1] = Float32(0.08724); FMLOAD[i, 1, 2] = Float32(0.01377)
        FMLOAD[i, 1, 3] = Float32(0.00459)
        FMLOAD[i, 2, 1] = Float32(0.32599); FMLOAD[i, 2, 2] = Float32(0.15611)
        FMDEP[i] = Float32(2.1); MOISEX[i] = Float32(0.40)
    end
    # SH1 (141) — Low load dry climate shrub
    let i = 141
        SURFVL[i, 1, 1] = Int32(2000)
        SURFVL[i, 2, 1] = Int32(1600); SURFVL[i, 2, 2] = Int32(1800)
        FMLOAD[i, 1, 1] = Float32(0.01148); FMLOAD[i, 1, 2] = Float32(0.01148)
        FMLOAD[i, 2, 1] = Float32(0.05969); FMLOAD[i, 2, 2] = Float32(0.00689)
        FMDEP[i] = Float32(1.0); MOISEX[i] = Float32(0.15)
    end
    # SH2 (142) — Moderate load dry climate shrub
    let i = 142
        SURFVL[i, 1, 1] = Int32(2000); SURFVL[i, 2, 1] = Int32(1600)
        FMLOAD[i, 1, 1] = Float32(0.06189); FMLOAD[i, 1, 2] = Float32(0.11019)
        FMLOAD[i, 1, 3] = Float32(0.03444); FMLOAD[i, 2, 1] = Float32(0.17677)
        FMDEP[i] = Float32(1.0); MOISEX[i] = Float32(0.15)
    end
    # SH3 (143) — Moderate load humid climate shrub
    let i = 143
        SURFVL[i, 1, 1] = Int32(1600); SURFVL[i, 2, 1] = Int32(1400)
        FMLOAD[i, 1, 1] = Float32(0.02066); FMLOAD[i, 1, 2] = Float32(0.13774)
        FMLOAD[i, 2, 1] = Float32(0.28466)
        FMDEP[i] = Float32(2.4); MOISEX[i] = Float32(0.40)
    end
    # SH4 (144) — Low load humid climate timber-shrub
    let i = 144
        SURFVL[i, 1, 1] = Int32(2000)
        SURFVL[i, 2, 1] = Int32(1600); SURFVL[i, 2, 2] = Int32(1800)
        FMLOAD[i, 1, 1] = Float32(0.03903); FMLOAD[i, 1, 2] = Float32(0.05280)
        FMLOAD[i, 1, 3] = Float32(0.00918); FMLOAD[i, 2, 1] = Float32(0.11708)
        FMDEP[i] = Float32(3.0); MOISEX[i] = Float32(0.30)
    end
    # SH5 (145) — High load dry climate shrub
    let i = 145
        SURFVL[i, 1, 1] = Int32(750); SURFVL[i, 2, 1] = Int32(1600)
        FMLOAD[i, 1, 1] = Float32(0.16529); FMLOAD[i, 1, 2] = Float32(0.09642)
        FMLOAD[i, 2, 1] = Float32(0.13315)
        FMDEP[i] = Float32(6.0); MOISEX[i] = Float32(0.15)
    end
    # SH6 (146) — Low load humid climate shrub
    let i = 146
        SURFVL[i, 1, 1] = Int32(750); SURFVL[i, 2, 1] = Int32(1600)
        FMLOAD[i, 1, 1] = Float32(0.13315); FMLOAD[i, 1, 2] = Float32(0.06657)
        FMLOAD[i, 2, 1] = Float32(0.06428)
        FMDEP[i] = Float32(2.0); MOISEX[i] = Float32(0.30)
    end
    # SH7 (147) — Very high load dry climate shrub
    let i = 147
        SURFVL[i, 1, 1] = Int32(750); SURFVL[i, 2, 1] = Int32(1600)
        FMLOAD[i, 1, 1] = Float32(0.16070); FMLOAD[i, 1, 2] = Float32(0.24334)
        FMLOAD[i, 1, 3] = Float32(0.10101); FMLOAD[i, 2, 1] = Float32(0.15611)
        FMDEP[i] = Float32(6.0); MOISEX[i] = Float32(0.15)
    end
    # SH8 (148) — High load humid climate shrub
    let i = 148
        SURFVL[i, 1, 1] = Int32(750); SURFVL[i, 2, 1] = Int32(1600)
        FMLOAD[i, 1, 1] = Float32(0.09412); FMLOAD[i, 1, 2] = Float32(0.15611)
        FMLOAD[i, 1, 3] = Float32(0.03903); FMLOAD[i, 2, 1] = Float32(0.19972)
        FMDEP[i] = Float32(3.0); MOISEX[i] = Float32(0.40)
    end
    # SH9 (149) — Very high load humid climate shrub
    let i = 149
        SURFVL[i, 1, 1] = Int32(750)
        SURFVL[i, 2, 1] = Int32(1500); SURFVL[i, 2, 2] = Int32(1800)
        FMLOAD[i, 1, 1] = Float32(0.20661); FMLOAD[i, 1, 2] = Float32(0.11249)
        FMLOAD[i, 2, 1] = Float32(0.32140); FMLOAD[i, 2, 2] = Float32(0.07117)
        FMDEP[i] = Float32(4.4); MOISEX[i] = Float32(0.40)
    end
    # TU1 (161) — Low load dry climate timber-grass-shrub
    let i = 161
        SURFVL[i, 1, 1] = Int32(2000)
        SURFVL[i, 2, 1] = Int32(1600); SURFVL[i, 2, 2] = Int32(1800)
        FMLOAD[i, 1, 1] = Float32(0.00918); FMLOAD[i, 1, 2] = Float32(0.04132)
        FMLOAD[i, 1, 3] = Float32(0.06887)
        FMLOAD[i, 2, 1] = Float32(0.04132); FMLOAD[i, 2, 2] = Float32(0.00918)
        FMDEP[i] = Float32(0.6); MOISEX[i] = Float32(0.20)
    end
    # TU2 (162) — Moderate load humid climate timber-shrub
    let i = 162
        SURFVL[i, 1, 1] = Int32(2000); SURFVL[i, 2, 1] = Int32(1600)
        FMLOAD[i, 1, 1] = Float32(0.04362); FMLOAD[i, 1, 2] = Float32(0.08264)
        FMLOAD[i, 1, 3] = Float32(0.05739); FMLOAD[i, 2, 1] = Float32(0.00918)
        FMDEP[i] = Float32(1.0); MOISEX[i] = Float32(0.30)
    end
    # TU3 (163) — Moderate load humid climate timber-grass-shrub
    let i = 163
        SURFVL[i, 1, 1] = Int32(1800)
        SURFVL[i, 2, 1] = Int32(1400); SURFVL[i, 2, 2] = Int32(1600)
        FMLOAD[i, 1, 1] = Float32(0.05051); FMLOAD[i, 1, 2] = Float32(0.00689)
        FMLOAD[i, 1, 3] = Float32(0.01148)
        FMLOAD[i, 2, 1] = Float32(0.05051); FMLOAD[i, 2, 2] = Float32(0.02984)
        FMDEP[i] = Float32(1.3); MOISEX[i] = Float32(0.30)
    end
    # TU4 (164) — Dwarf conifer with understory
    let i = 164
        SURFVL[i, 1, 1] = Int32(2300); SURFVL[i, 2, 1] = Int32(2000)
        FMLOAD[i, 1, 1] = Float32(0.20661); FMLOAD[i, 2, 1] = Float32(0.09183)
        FMDEP[i] = Float32(0.5); MOISEX[i] = Float32(0.12)
    end
    # TU5 (165) — Very high load dry climate timber-shrub
    let i = 165
        SURFVL[i, 1, 1] = Int32(1500); SURFVL[i, 2, 1] = Int32(750)
        FMLOAD[i, 1, 1] = Float32(0.18365); FMLOAD[i, 1, 2] = Float32(0.18365)
        FMLOAD[i, 1, 3] = Float32(0.13774); FMLOAD[i, 2, 1] = Float32(0.13774)
        FMDEP[i] = Float32(1.0); MOISEX[i] = Float32(0.25)
    end
    # TL1 (181) — Low load compact conifer litter
    let i = 181
        SURFVL[i, 1, 1] = Int32(2000)
        FMLOAD[i, 1, 1] = Float32(0.04591); FMLOAD[i, 1, 2] = Float32(0.10101)
        FMLOAD[i, 1, 3] = Float32(0.16529)
        FMDEP[i] = Float32(0.2); MOISEX[i] = Float32(0.30)
    end
    # TL2 (182) — Low load broadleaf litter
    let i = 182
        SURFVL[i, 1, 1] = Int32(2000)
        FMLOAD[i, 1, 1] = Float32(0.06428); FMLOAD[i, 1, 2] = Float32(0.10560)
        FMLOAD[i, 1, 3] = Float32(0.10101)
        FMDEP[i] = Float32(0.2); MOISEX[i] = Float32(0.25)
    end
    # TL3 (183) — Moderate load conifer litter
    let i = 183
        SURFVL[i, 1, 1] = Int32(2000)
        FMLOAD[i, 1, 1] = Float32(0.02296); FMLOAD[i, 1, 2] = Float32(0.10101)
        FMLOAD[i, 1, 3] = Float32(0.12856)
        FMDEP[i] = Float32(0.3); MOISEX[i] = Float32(0.20)
    end
    # TL4 (184) — Small downed logs
    let i = 184
        SURFVL[i, 1, 1] = Int32(2000)
        FMLOAD[i, 1, 1] = Float32(0.02296); FMLOAD[i, 1, 2] = Float32(0.06887)
        FMLOAD[i, 1, 3] = Float32(0.19284)
        FMDEP[i] = Float32(0.4); MOISEX[i] = Float32(0.25)
    end
    # TL5 (185) — High load conifer litter
    let i = 185
        SURFVL[i, 1, 1] = Int32(2000); SURFVL[i, 2, 1] = Int32(1600)
        FMLOAD[i, 1, 1] = Float32(0.05280); FMLOAD[i, 1, 2] = Float32(0.11478)
        FMLOAD[i, 1, 3] = Float32(0.20202)
        FMDEP[i] = Float32(0.6); MOISEX[i] = Float32(0.25)
    end
    # TL6 (186) — Moderate load broadleaf litter
    let i = 186
        SURFVL[i, 1, 1] = Int32(2000)
        FMLOAD[i, 1, 1] = Float32(0.11019); FMLOAD[i, 1, 2] = Float32(0.05510)
        FMLOAD[i, 1, 3] = Float32(0.05510)
        FMDEP[i] = Float32(0.3); MOISEX[i] = Float32(0.25)
    end
    # TL7 (187) — Large downed logs
    let i = 187
        SURFVL[i, 1, 1] = Int32(2000)
        FMLOAD[i, 1, 1] = Float32(0.01377); FMLOAD[i, 1, 2] = Float32(0.06428)
        FMLOAD[i, 1, 3] = Float32(0.37190)
        FMDEP[i] = Float32(0.4); MOISEX[i] = Float32(0.25)
    end
    # TL8 (188) — Long-needle litter
    let i = 188
        SURFVL[i, 1, 1] = Int32(1800)
        FMLOAD[i, 1, 1] = Float32(0.26630); FMLOAD[i, 1, 2] = Float32(0.06428)
        FMLOAD[i, 1, 3] = Float32(0.05051)
        FMDEP[i] = Float32(0.3); MOISEX[i] = Float32(0.35)
    end
    # TL9 (189) — Very high load broadleaf litter
    let i = 189
        SURFVL[i, 1, 1] = Int32(1800); SURFVL[i, 2, 1] = Int32(1600)
        FMLOAD[i, 1, 1] = Float32(0.30533); FMLOAD[i, 1, 2] = Float32(0.15152)
        FMLOAD[i, 1, 3] = Float32(0.19054)
        FMDEP[i] = Float32(0.6); MOISEX[i] = Float32(0.35)
    end
    # SB1 (201) — Low load activity fuel
    let i = 201
        SURFVL[i, 1, 1] = Int32(2000)
        FMLOAD[i, 1, 1] = Float32(0.06887); FMLOAD[i, 1, 2] = Float32(0.13774)
        FMLOAD[i, 1, 3] = Float32(0.50505)
        FMDEP[i] = Float32(1.0); MOISEX[i] = Float32(0.25)
    end
    # SB2 (202) — Moderate load activity fuel or low load blowdown
    let i = 202
        SURFVL[i, 1, 1] = Int32(2000)
        FMLOAD[i, 1, 1] = Float32(0.20661); FMLOAD[i, 1, 2] = Float32(0.19513)
        FMLOAD[i, 1, 3] = Float32(0.18365)
        FMDEP[i] = Float32(1.0); MOISEX[i] = Float32(0.25)
    end
    # SB3 (203) — High load activity fuel or moderate load blowdown
    let i = 203
        SURFVL[i, 1, 1] = Int32(2000)
        FMLOAD[i, 1, 1] = Float32(0.25253); FMLOAD[i, 1, 2] = Float32(0.12626)
        FMLOAD[i, 1, 3] = Float32(0.13774)
        FMDEP[i] = Float32(1.2); MOISEX[i] = Float32(0.25)
    end
    # SB4 (204) — High load blowdown
    let i = 204
        SURFVL[i, 1, 1] = Int32(2000)
        FMLOAD[i, 1, 1] = Float32(0.24105); FMLOAD[i, 1, 2] = Float32(0.16070)
        FMLOAD[i, 1, 3] = Float32(0.24105)
        FMDEP[i] = Float32(2.7); MOISEX[i] = Float32(0.25)
    end

    # New fire calculation option defaults
    IFLOGIC  = Int32(0)
    IFMSET   = Int32(2)
    USAV[1]  = Float32(2000.0)
    USAV[2]  = Float32(1800.0)
    USAV[3]  = Float32(1500.0)
    UBD[1]   = Float32(0.10)
    UBD[2]   = Float32(0.75)
    ULHV     = Float32(8000.0)
    fill!(IFUELMON, Int32(-1))

    # Snag pool initialization (non-zero: MINHT = 1000)
    for i in 1:MAXSP
        for j in 1:19
            MAXHT[i, j]  = Float32(0.0)
            MINHT[i, j]  = Float32(1000.0)
            DSPDBH[i, j] = Float32(0.0)
        end
    end

    NYRS = Int32(1)

    # Report begin/end years (9999 = disabled)
    IFMBRB  = Int32(9999); IFMBRE  = Int32(9999)
    IFMFLB  = Int32(9999); IFMFLE  = Int32(9999)
    IFMMRB  = Int32(9999); IFMMRE  = Int32(9999)
    IFLALB  = Int32(9999); IFLALE  = Int32(9999)
    IPFLMB  = Int32(9999); IPFLME  = Int32(9999)
    ISNAGB  = Int32(9999); ISNAGE  = Int32(9999)
    ISHEATB = Int32(9999); ISHEATE = Int32(9999)
    ICFPB   = Int32(9999); ICFPE   = Int32(9999)
    IDWRPB  = Int32(9999); IDWRPE  = Int32(9999)
    IDWCVB  = Int32(9999); IDWCVE  = Int32(9999)

    IDBRN   = Int32(0); IDSHEAT = Int32(0)
    IDFUL   = Int32(0); IDMRT   = Int32(0)
    IDFLAL  = Int32(0); IDPFLM  = Int32(0)
    IDDWRP  = Int32(0); IDDWCV  = Int32(0)

    IBRPAS  = Int32(0); IFLPAS  = Int32(0)
    IMRPAS  = Int32(0); IFAPAS  = Int32(0)
    IPFPAS  = Int32(0); IDWPAS  = Int32(0)
    IDCPAS  = Int32(0)

    # Carbon report initialization
    IDCRPT  = Int32(0)
    ICRPTB  = Int32(9999); ICRPTE = Int32(9999)
    ICRPAS  = Int32(0)

    IDCHRV  = Int32(0)
    ICHRVB  = Int32(9999); ICHRVE = Int32(9999)
    ICHPAS  = Int32(0)

    fill!(CARBVAL, Float32(0.0))

    ICMETH  = Int32(0)
    ICMETRC = if VARACD ∈ ("ON", "BC"); Int32(1); else Int32(0); end
    ICHABT  = Int32(1)
    CRDCAY  = Float32(0.0425)
    CDBRK[1] = Float32(9.0)
    CDBRK[2] = Float32(11.0)
    BIOLIVE  = Float32(0.0)
    BIOREM[1] = Float32(0.0); BIOREM[2] = Float32(0.0)
    BIOSNAG  = Float32(0.0)
    BIODDW   = Float32(0.0)
    BIOFLR   = Float32(0.0)
    BIOSHRB  = Float32(0.0)
    BIOROOT  = Float32(0.0)
    BIOCON[1] = Float32(0.0); BIOCON[2] = Float32(0.0)
    fill!(FATE, Float32(0.0))

    fill!(CWDNEW, Float32(0.0))
    fill!(CWD,    Float32(0.0))
    fill!(CWDVOL, Float32(0.0))
    fill!(CWDCOV, Float32(0.0))
    fill!(CWD2B,  Float32(0.0))
    fill!(CWD2B2, Float32(0.0))

    for i in 1:MAXTRE
        FMPROB[i] = Float32(0.0)
        OLDHT[i]  = Float32(0.0)
        OLDCRL[i] = Float32(0.0)
        GROW_FM[i] = Int32(1)
        SNGNEW[i]  = Float32(0.0)
        for k in 1:6
            CROWNW[i, k]  = Float32(0.0)
            OLDCRW[i, k]  = Float32(0.0)
        end
    end

    FLIVE[1] = Float32(0.0)
    FLIVE[2] = Float32(0.0)

    LREMT    = false
    NFMSVPX  = Int32(3)

    FMVINIT()

    return nothing
end

# ENTRY FMATV(LRET) — return state of LFMON
function FMATV(lret_ref::Ref{Bool})
    lret_ref[] = LFMON
    return nothing
end

# ENTRY FMSATV(LRET) — set state of LFMON (called by GETSTD)
function FMSATV(lfm::Bool)
    global LFMON = lfm
    return nothing
end

# ENTRY FMLNKD(LRET) — returns true (fire model is linked in this build)
function FMLNKD(lret_ref::Ref{Bool})
    lret_ref[] = true
    return nothing
end
