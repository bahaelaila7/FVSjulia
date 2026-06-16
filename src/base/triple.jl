# triple.jl — TRIPLE + REASS: tree-record tripling for stochastic mortality
# Translated from: triple.f (154 lines) + reass.f (81 lines)
#
# TRIPLE: partitions each tree record into 3 records (weights 0.60, 0.25, 0.15)
#         copying all per-tree arrays to the new slots.
# REASS:  realigns IND1/IND/ISCT pointers after tripling.

# Extension stubs for tripling callbacks (may be overridden by loaded extensions)
function SVTRIP(i::Integer, itfn::Integer); return nothing; end
function ORGTRIP(i::Integer, itfn::Integer); return nothing; end
function RDTRIP(itfn::Integer, i::Integer, weight::Real); return nothing; end
function BRTRIP(itfn::Integer, i::Integer, weight::Real); return nothing; end
function BMTRIP(itfn::Integer, i::Integer, weight::Real); return nothing; end
# FMTRIP → extensions/fire/fmtrip.jl

function TRIPLE()
    for i in 1:Int(ITRN)
        weight = Float32(0.25)
        itfn   = Int(ITRN) + 2*i - 1

        SVTRIP(i, itfn)

        # Inner loop: run twice — once for itfn (2nd triple), once for itfn+1 (3rd triple)
        while true
            BFV[itfn]         = BFV[i]
            CFV[itfn]         = CFV[i]
            MCFV[itfn]        = MCFV[i]
            SCFV[itfn]        = SCFV[i]
            PTOCFV[itfn]      = PTOCFV[i]
            PMRBFV[itfn]      = PMRBFV[i]
            PMRCFV[itfn]      = PMRCFV[i]
            PSCFV[itfn]       = PSCFV[i]
            PDBH[itfn]        = PDBH[i]
            PHT[itfn]         = PHT[i]
            NCFDEF[itfn]      = NCFDEF[i]
            NBFDEF[itfn]      = NBFDEF[i]
            HT[itfn]          = HT[i]
            OLDPCT[itfn]      = OLDPCT[i]
            PCT[itfn]         = PCT[i]
            PROB[itfn]        = PROB[i] * weight
            WK1[itfn]         = WK1[i]
            WK2[itfn]         = WK2[i] * weight
            WK3[itfn]         = WK3[i]
            ICR[itfn]         = ICR[i]
            IMC[itfn]         = IMC[i]
            ISP[itfn]         = ISP[i]
            ITRE[itfn]        = ITRE[i]
            ITRUNC[itfn]      = ITRUNC[i]
            NORMHT[itfn]      = NORMHT[i]
            KUTKOD[itfn]      = KUTKOD[i]
            DEFECT[itfn]      = DEFECT[i]
            ISPECL[itfn]      = ISPECL[i]
            IESTAT[itfn]      = IESTAT[i]
            ABIRTH[itfn]      = ABIRTH[i]
            LBIRTH[itfn]      = LBIRTH[i]
            IDTREE[itfn]      = IDTREE[i]
            ZRAND[itfn]       = ZRAND[i]
            CRWDTH[itfn]      = CRWDTH[i]
            HT2TD[itfn, 1]    = HT2TD[i, 1]
            HT2TD[itfn, 2]    = HT2TD[i, 2]
            CULL[itfn]        = CULL[i]
            DECAYCD[itfn]     = DECAYCD[i]
            WDLDSTEM[itfn]    = WDLDSTEM[i]
            ABVGRD_BIO[itfn]  = ABVGRD_BIO[i]
            MERCH_BIO[itfn]   = MERCH_BIO[i]
            CUBSAW_BIO[itfn]  = CUBSAW_BIO[i]
            FOLI_BIO[Int(ITRN)]   = FOLI_BIO[i]
            ABVGRD_CARB[Int(ITRN)]= ABVGRD_CARB[i]
            MERCH_CARB[Int(ITRN)] = MERCH_CARB[i]
            CUBSAW_CARB[Int(ITRN)]= CUBSAW_CARB[i]
            FOLI_CARB[Int(ITRN)]  = FOLI_CARB[i]
            CARB_FRAC[Int(ITRN)]  = CARB_FRAC[i]

            ORGTRIP(i, itfn)

            idmr_ref = Ref(Int32(0))
            MISGET(i, idmr_ref)
            MISPUT(itfn, idmr_ref[])

            RDTRIP(itfn, i, weight)
            BRTRIP(itfn, i, weight)
            BMTRIP(itfn, i, weight)
            FMTRIP(itfn, i, weight)

            if weight < Float32(0.2); break; end

            # Set up for third triple
            weight = Float32(0.15)
            itfn   = itfn + 1
        end

        # Adjust original record for the tripling fractions
        WK2[i]  = WK2[i]  * Float32(0.6)
        PROB[i] = PROB[i] * Float32(0.60)

        RDTRIP(itfn, i, Float32(0.6))
        BRTRIP(itfn, i, Float32(0.6))
        BMTRIP(itfn, i, Float32(0.6))
        FMTRIP(itfn, i, Float32(0.6))
    end

    global TRM = TRM * Float32(0.6)
    return nothing
end

function REASS()
    # Copy IND1 into IND2 in species order
    j = 0
    for ispc in 1:MAXSP
        i1 = ISCT[ispc, 1]
        if i1 == 0; continue; end
        i2 = ISCT[ispc, 2]
        for i in i1:i2
            j += 1
            IND2[j] = IND1[i]
        end
    end

    # Realign pointers in IND1
    j = 1
    k = 1
    while k <= Int(ITRN)
        i    = Int(IND2[j])
        itfn = Int(IREC1) + 2*i - 1
        IND1[k]   = Int32(itfn)
        IND1[k+1] = Int32(i)
        IND1[k+2] = Int32(itfn + 1)
        j += 1
        k += 3
    end

    # Realign ISCT pointers
    last = 0
    for ispc in 1:MAXSP
        if ISCT[ispc, 1] == 0; continue; end
        iknt = ISCT[ispc, 2] - ISCT[ispc, 1] + 1
        ISCT[ispc, 1] = Int32(last + 1)
        last = last + iknt * 3
        ISCT[ispc, 2] = Int32(last)
    end

    # Copy IND into IND2
    for i in 1:Int(IREC1)
        IND2[i] = IND[i]
    end

    # Realign pointers in IND
    j = 1
    k = 1
    while k <= Int(ITRN)
        i    = Int(IND2[j])
        itfn = Int(IREC1) + 2*i - 1
        IND[k]   = Int32(itfn)
        IND[k+1] = Int32(i)
        IND[k+2] = Int32(itfn + 1)
        j += 1
        k += 3
    end
    return nothing
end
