# base/tremov.jl — TREMOV: swap two tree records (ivac ↔ irec)
# Translated from: bin/FVSsn_buildDir/tremov.f (198 lines)
#
# Moves the tree at position irec2 to position irec1, and the tree
# that was at irec1 goes to irec2. Used by TREDEL to fill vacancies.

function TREMOV(irec1::Integer, irec2::Integer)
    r1 = Int(irec1)
    r2 = Int(irec2)

    # --- save irec1 to temporaries ---
    rtem = (BFV[r1], CFV[r1], MCFV[r1], SCFV[r1],
            DBH[r1], DG[r1], HT[r1], HTG[r1],
            OLDPCT[r1], OLDRN[r1], PCT[r1],
            WK1[r1], WK2[r1], WK3[r1],
            PROB[r1], ABIRTH[r1], ZRAND[r1],
            PTOCFV[r1], PMRCFV[r1], PSCFV[r1], PMRBFV[r1],
            PDBH[r1], PHT[r1], CRWDTH[r1],
            HT2TD[r1,1], HT2TD[r1,2], CULL[r1],
            ABVGRD_BIO[r1], MERCH_BIO[r1], CUBSAW_BIO[r1], FOLI_BIO[r1],
            ABVGRD_CARB[r1], MERCH_CARB[r1], CUBSAW_CARB[r1], FOLI_CARB[r1],
            CARB_FRAC[r1])

    item = (ICR[r1], IMC[r1], ISP[r1], DEFECT[r1], ISPECL[r1],
            KUTKOD[r1], ITRUNC[r1], NORMHT[r1], ITRE[r1], IESTAT[r1],
            IDTREE[r1], NCFDEF[r1], NBFDEF[r1], DECAYCD[r1], WDLDSTEM[r1])

    # --- copy irec2 → irec1 ---
    BFV[r1]     = BFV[r2];    CFV[r1]    = CFV[r2]
    MCFV[r1]    = MCFV[r2];   SCFV[r1]   = SCFV[r2]
    DBH[r1]     = DBH[r2];    DG[r1]     = DG[r2]
    HT[r1]      = HT[r2];     HTG[r1]    = HTG[r2]
    OLDPCT[r1]  = OLDPCT[r2]; OLDRN[r1]  = OLDRN[r2]
    PCT[r1]     = PCT[r2];    WK1[r1]    = WK1[r2]
    WK2[r1]     = WK2[r2];    WK3[r1]    = WK3[r2]
    ICR[r1]     = ICR[r2];    IMC[r1]    = IMC[r2]
    ISP[r1]     = ISP[r2];    DEFECT[r1] = DEFECT[r2]
    ISPECL[r1]  = ISPECL[r2]; KUTKOD[r1] = KUTKOD[r2]
    ITRUNC[r1]  = ITRUNC[r2]; NORMHT[r1] = NORMHT[r2]
    ITRE[r1]    = ITRE[r2];   PROB[r1]   = PROB[r2]
    IESTAT[r1]  = IESTAT[r2]; ABIRTH[r1] = ABIRTH[r2]
    IDTREE[r1]  = IDTREE[r2]; ZRAND[r1]  = ZRAND[r2]
    PTOCFV[r1]  = PTOCFV[r2]; PMRCFV[r1] = PMRCFV[r2]
    PSCFV[r1]   = PSCFV[r2];  PMRBFV[r1] = PMRBFV[r2]
    NCFDEF[r1]  = NCFDEF[r2]; NBFDEF[r1] = NBFDEF[r2]
    PDBH[r1]    = PDBH[r2];   PHT[r1]    = PHT[r2]
    CRWDTH[r1]  = CRWDTH[r2]
    HT2TD[r1,1] = HT2TD[r2,1]; HT2TD[r1,2] = HT2TD[r2,2]
    CULL[r1]    = CULL[r2];    DECAYCD[r1] = DECAYCD[r2]
    WDLDSTEM[r1]= WDLDSTEM[r2]
    ABVGRD_BIO[r1]  = ABVGRD_BIO[r2];  MERCH_BIO[r1]  = MERCH_BIO[r2]
    CUBSAW_BIO[r1]  = CUBSAW_BIO[r2];  FOLI_BIO[r1]   = FOLI_BIO[r2]
    ABVGRD_CARB[r1] = ABVGRD_CARB[r2]; MERCH_CARB[r1] = MERCH_CARB[r2]
    CUBSAW_CARB[r1] = CUBSAW_CARB[r2]; FOLI_CARB[r1]  = FOLI_CARB[r2]
    CARB_FRAC[r1]   = CARB_FRAC[r2]

    # --- copy saved irec1 → irec2 ---
    BFV[r2]     = rtem[1];   CFV[r2]    = rtem[2]
    MCFV[r2]    = rtem[3];   SCFV[r2]   = rtem[4]
    DBH[r2]     = rtem[5];   DG[r2]     = rtem[6]
    HT[r2]      = rtem[7];   HTG[r2]    = rtem[8]
    OLDPCT[r2]  = rtem[9];   OLDRN[r2]  = rtem[10]
    PCT[r2]     = rtem[11];  WK1[r2]    = rtem[12]
    WK2[r2]     = rtem[13];  WK3[r2]    = rtem[14]
    PROB[r2]    = rtem[15];  ABIRTH[r2] = rtem[16]
    ZRAND[r2]   = rtem[17];  PTOCFV[r2] = rtem[18]
    PMRCFV[r2]  = rtem[19];  PSCFV[r2]  = rtem[20]
    PMRBFV[r2]  = rtem[21];  PDBH[r2]   = rtem[22]
    PHT[r2]     = rtem[23];  CRWDTH[r2] = rtem[24]
    HT2TD[r2,1] = rtem[25];  HT2TD[r2,2]= rtem[26]
    CULL[r2]    = rtem[27]
    ABVGRD_BIO[r2]  = rtem[28]; MERCH_BIO[r2]  = rtem[29]
    CUBSAW_BIO[r2]  = rtem[30]; FOLI_BIO[r2]   = rtem[31]
    ABVGRD_CARB[r2] = rtem[32]; MERCH_CARB[r2] = rtem[33]
    CUBSAW_CARB[r2] = rtem[34]; FOLI_CARB[r2]  = rtem[35]
    CARB_FRAC[r2]   = rtem[36]

    ICR[r2]      = item[1];  IMC[r2]      = item[2]
    ISP[r2]      = item[3];  DEFECT[r2]   = item[4]
    ISPECL[r2]   = item[5];  KUTKOD[r2]   = item[6]
    ITRUNC[r2]   = item[7];  NORMHT[r2]   = item[8]
    ITRE[r2]     = item[9];  IESTAT[r2]   = item[10]
    IDTREE[r2]   = item[11]; NCFDEF[r2]   = item[12]
    NBFDEF[r2]   = item[13]; DECAYCD[r2]  = item[14]
    WDLDSTEM[r2] = item[15]

    # Swap mistletoe ratings (stubs if mistletoe extension absent)
    idmr_ref = Ref(Int32(0)); jdmr_ref = Ref(Int32(0))
    MISGET(r2, idmr_ref); MISGET(r1, jdmr_ref)
    MISPUT(r2, jdmr_ref[]); MISPUT(r1, idmr_ref[])
    return nothing
end
