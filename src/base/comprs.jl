# comprs.jl — Tree list compression
# Translated from: base/comprs.f (1010 lines)
# Authors: N.L. Crookston (1979-1982), A.R. Stage
#
# Goal: reduce tree list from ITRN records to NCLAS records.
# Method 1: maximum-gap breaks in a weighted score vector.
# Method 2: recursive splitting of classes with the largest range
#            on the first and second principal components.

"""
    COMPRS(nclas, pn1)

Compress the current tree list from ITRN records to `nclas` records.
`pn1` is the fraction of `nclas` classes to obtain via method 1 (gap splitting);
the remainder come from method 2 (PCA range splitting).

On return:
- ITRN == IREC1 == nclas
- IND contains class assignments with negative values marking vacated slots
"""
const _COMPRS_NRANK  = 5
const _COMPRS_NRANK1 = _COMPRS_NRANK + 1
const _COMPRS_LEN1   = _COMPRS_NRANK1 * (_COMPRS_NRANK1 + 1) ÷ 2
const _COMPRS_LEN2   = _COMPRS_NRANK * _COMPRS_NRANK1 ÷ 2
const _COMPRS_LEN3   = _COMPRS_NRANK * _COMPRS_NRANK
const _COMPRS_RNGMIN = Float32(0.00001)
const _COMPRS_ALGTOL = Float32(0.066)
const _COMPRS_IDCMP2 = Int32(20000000)

function COMPRS(nclas::Int32, pn1::Float32)
    NRANK   = _COMPRS_NRANK
    NRANK1  = _COMPRS_NRANK1
    LEN1    = _COMPRS_LEN1
    LEN2    = _COMPRS_LEN2
    LEN3    = _COMPRS_LEN3
    RNGMIN  = _COMPRS_RNGMIN
    ALGTOL  = _COMPRS_ALGTOL
    IDCMP2  = _COMPRS_IDCMP2

    ldebg = DBCHK("COMPRS", Int32(6))

    if ldebg
        @printf(io_units[JOSTND], " IN COMPRS: NCLAS,ITRN=%6d%6d\n", nclas, ITRN)
    end
    if nclas >= ITRN
        return nothing
    end

    # -----------------------------------------------------------------------
    # Step 2: initial weighted score (species + subplot)
    # -----------------------------------------------------------------------
    ttprb = Float32(0.0)
    ttwk2 = Float32(0.0)
    for i in Int32(1):ITRN
        WK3[i] = Float32(25.0) * (Float32(PI) * ISP[i] + ITRE[i])
        if ldebg
            ttprb += PROB[i]
            ttwk2 += WK2[i]
        end
    end
    if ldebg
        @printf(io_units[JOSTND],
            " SUM OF PROB (BEFORE)= %10.4f SUM OF MORT= %10.4f\n", ttprb, ttwk2)
    end

    # -----------------------------------------------------------------------
    # Step 3: PCA refinement of score
    # -----------------------------------------------------------------------
    xtx     = zeros(Float64, LEN2)
    eivect  = zeros(Float64, LEN3)
    xsum    = zeros(Float64, NRANK)
    rmeans  = zeros(Float64, NRANK)
    stddev  = zeros(Float64, NRANK)
    vars_v  = zeros(Float64, NRANK)

    # Compute means and standard deviations of 5 classification variables
    let mr=Ref(0.0), vr=Ref(0.0), sr=Ref(0.0)
        MEANSD(HT,  ITRN, mr, vr, sr)
        rmeans[1]=mr[]; vars_v[1]=vr[]; stddev[1]=sr[]
    end
    if stddev[1] < 1.0; stddev[1] = 1.0; end
    for i in 1:ITRN; WK4[i] = Float32(ICR[i]); end
    let mr=Ref(0.0), vr=Ref(0.0), sr=Ref(0.0)
        MEANSD(WK4, ITRN, mr, vr, sr)
        rmeans[2]=mr[]; vars_v[2]=vr[]; stddev[2]=sr[]
    end
    if stddev[2] < 1.0e-4; stddev[2] = 1.0e-4; end
    for i in 1:ITRN; WK4[i] = Float32(IMC[i]); end
    let mr=Ref(0.0), vr=Ref(0.0), sr=Ref(0.0)
        MEANSD(WK4, ITRN, mr, vr, sr)
        rmeans[3]=mr[]; vars_v[3]=vr[]; stddev[3]=sr[]
    end
    if stddev[3] < 1.0e-4; stddev[3] = 1.0e-4; end
    for i in 1:ITRN; WK4[i] = (DBH[i] > 0f0) ? log(DBH[i]) : Float32(0.0); end
    let mr=Ref(0.0), vr=Ref(0.0), sr=Ref(0.0)
        MEANSD(WK4, ITRN, mr, vr, sr)
        rmeans[4]=mr[]; vars_v[4]=vr[]; stddev[4]=sr[]
    end
    if stddev[4] < 5.0e-3; stddev[4] = 5.0e-3; end
    let mr=Ref(0.0), vr=Ref(0.0), sr=Ref(0.0)
        MEANSD(DG,  ITRN, mr, vr, sr)
        rmeans[5]=mr[]; vars_v[5]=vr[]; stddev[5]=sr[]
    end
    if stddev[5] < 0.02; stddev[5] = 0.02; end

    # Build X'X (lower triangle of correlation matrix)
    for i in 1:ITRN
        observ = (
            (HT[i]           - rmeans[1]) / stddev[1],
            (Float64(ICR[i]) - rmeans[2]) / stddev[2],
            (Float64(IMC[i]) - rmeans[3]) / stddev[3],
            (Float64(WK4[i]) - rmeans[4]) / stddev[4],
            (Float64(DG[i])  - rmeans[5]) / stddev[5]
        )
        ij = 0
        for iob in 1:NRANK
            for job in 1:iob
                ij += 1
                xtx[ij] += observ[iob] * observ[job]
            end
            xsum[iob] += observ[iob]
        end
    end

    if ldebg
        @printf(io_units[JOSTND], " IN COMPRS, SUMS:")
        for k in 1:NRANK; @printf(io_units[JOSTND], "%20.10e", xsum[k]); end
        @printf(io_units[JOSTND], "\n")
    end

    # Center (subtract cross-products of sums)
    dtrn = Float64(ITRN)
    ij = 0
    for i in 1:NRANK
        for j in 1:i
            ij += 1
            xtx[ij] -= xsum[i] * xsum[j] / dtrn
        end
    end

    # Normalize to correlation matrix
    dtrn = Float64(ITRN) - 1.0
    for i in 1:LEN2; xtx[i] /= dtrn; end
    ij = 0
    for i in 1:NRANK
        for j in 1:i
            ij += 1
            if i == j; xtx[ij] = 1.0; end
        end
    end

    if ldebg
        @printf(io_units[JOSTND],
            "\n IN COMPRS: CORRELATIONS (WRITTEN IN VECTOR FORMAT) RANK = %2d\n", NRANK)
        for i in 1:LEN2; @printf(io_units[JOSTND], "%20.12e", xtx[i]); end
        @printf(io_units[JOSTND], "\n")
    end

    # Compute eigenvectors via EIGEN (IBM SSP routine)
    EIGEN!(xtx, eivect, NRANK)

    # Fix sign conventions
    if eivect[4] < 0.0
        if ldebg
            @printf(io_units[JOSTND], " IN COMPRS: SIGN CHANGE ON FIRST EIGENVECTOR.\n")
        end
        for i in 1:NRANK; eivect[i] = -eivect[i]; end
    end
    if eivect[7] > 0.0
        if ldebg
            @printf(io_units[JOSTND], " IN COMPRS: SIGN CHANGE ON SECOND EIGENVECTOR.\n")
        end
        for i in (NRANK+1):(NRANK*2); eivect[i] = -eivect[i]; end
    end

    if ldebg
        @printf(io_units[JOSTND], " IN COMPRS: ALGTOL = %15.7e\n", ALGTOL)
        @printf(io_units[JOSTND], "\n IN COMPRS: EIGENVALUES:")
        for i in 1:NRANK
            @printf(io_units[JOSTND], "%20.12e", xtx[i + (i*i-i)÷2])
        end
        @printf(io_units[JOSTND], "\n IN COMPRS: EIGENVECTORS, RANK = %3d", NRANK)
        for i in 1:LEN3; @printf(io_units[JOSTND], "%20.12e", eivect[i]); end
        @printf(io_units[JOSTND], "\n")
        @printf(io_units[JOSTND], " IN COMPRS: FIRST EIGENVALUE = %20.12e\n", xtx[1])
    end

    # Scale eigenvectors by 1/σ
    jk = 0
    for j in 1:NRANK
        for k in 1:NRANK
            jk += 1
            eivect[jk] /= stddev[k]
        end
    end

    # Add PCA scores to initial score
    for i in 1:ITRN
        hti   = Float32(Float64(HT[i])           - rmeans[1])
        xicri = Float32(Float64(ICR[i])           - rmeans[2])
        x     = Float32(Float64(IMC[i])           - rmeans[3])
        dbhi  = Float32(Float64(WK4[i])           - rmeans[4])
        dgi   = Float32(Float64(DG[i])            - rmeans[5])
        term1 = Float32(
            hti   * eivect[1] +
            xicri * eivect[2] +
            x     * eivect[3] +
            dbhi  * eivect[4] +
            dgi   * eivect[5] + 4.0)
        WK3[i] += term1
        WK4[i]  = Float32(
            hti   * eivect[6] +
            xicri * eivect[7] +
            x     * eivect[8] +
            dbhi  * eivect[9] +
            dgi   * eivect[10])
    end

    # -----------------------------------------------------------------------
    # Step 4: Sort IND on WK3 (descending)
    # -----------------------------------------------------------------------
    if ITRN > Int32(0)
        RDPSRT(ITRN, WK3, IND, true)
    end

    # -----------------------------------------------------------------------
    # Step 5: Find maximum gaps (method 1)
    # -----------------------------------------------------------------------
    izers = 0
    i_idx = IND[1]
    x1 = WK3[i_idx]
    for j in 2:ITRN
        i_idx = IND[j]
        x2 = WK3[i_idx]
        WK6[j-1] = x1 - x2
        if WK6[j-1] <= ALGTOL; izers += 1; end
        x1 = x2
    end

    ncls1 = Int32(round(Float32(nclas) * pn1 + Float32(0.5)))
    isig  = ITRN - Int32(izers)
    if isig < ncls1; ncls1 = isig; end
    if ncls1 < Int32(1); ncls1 = Int32(1); end
    if ncls1 > nclas;    ncls1 = nclas;    end

    # Sort differences (descending) → pointers in IND1
    RDPSRT(ITRN - Int32(1), WK6, IND1, true)

    # Sort first ncls1-1 pointers ascending
    if ncls1 > Int32(1)
        IQRSRT(IND1, ncls1 - Int32(1))
    end
    IND1[ncls1] = ITRN

    # -----------------------------------------------------------------------
    # Step 6: Method 2 — range splitting
    # -----------------------------------------------------------------------
    ncls2 = nclas - ncls1
    if ldebg
        @printf(io_units[JOSTND],
            " IN COMPRS: NCLAS=%4d PN1=%5.2f ITRN=%4d NCLS1=%4d NCLS2=%4d RNGMIN=%14.6e\n",
            nclas, pn1, ITRN, ncls1, ncls2, RNGMIN)
    end

    if ncls2 > Int32(0)
        # Compute score ranges per class
        i1 = Int32(1)
        for i_cl in 1:ncls1
            i2  = IND1[i_cl]
            j_v = IND[i2]
            k_v = IND[i1]
            WK6[i_cl] = WK3[k_v] - WK3[j_v]
            len_cl    = i2 - i1 + 1
            IND2[i_cl] = Int32(len_cl)
            WK5[i_cl]  = CMRANG(len_cl, view(IND, i1:i2), WK4)
            i1 = i2 + Int32(1)
        end

        # Iterative splitting
        @label label_190_loop
        for k_split in 1:ncls2
            # Find largest class range
            irec_cl = Int32(0)
            xrang   = Float32(0.0)
            ltwo    = false
            for j_cl in 1:ncls1
                x_v  = WK6[j_cl]
                l2_f = WK5[j_cl] > x_v
                if l2_f; x_v = WK5[j_cl]; end
                if x_v <= xrang; continue; end
                ltwo  = l2_f
                xrang = x_v
                irec_cl = Int32(j_cl)
            end

            if xrang <= RNGMIN || irec_cl == Int32(0)
                break
            end

            len_cl = Int32(IND2[irec_cl])
            i1     = IND1[irec_cl] - len_cl + Int32(1)
            i2_cl  = IND1[irec_cl]

            # Sort on second eigenvector if LTWO
            if ltwo
                RDPSRT(len_cl, WK4, view(IND, i1:i2_cl), false)
            end

            i_last  = IND[i2_cl]
            xsmal   = ltwo ? WK4[i_last] : WK3[i_last]
            prang   = Float32(0.0)
            ln_val  = Int32(len_cl)

            if len_cl <= Int32(2)
                len_cl = Int32(1)
            else
                prang  = xrang / Float32(ln_val - Int32(1))
                len_cl = (len_cl + Int32(1)) ÷ Int32(2)
            end

            # Move split point away from tiny class boundaries
            jk_bound = Int32(IND2[irec_cl]) - len_cl - Int32(1)
            if jk_bound >= Int32(1)
                for j_b in 1:jk_bound
                    i_test = IND1[irec_cl] - len_cl
                    diff_v = ltwo ?
                        (WK4[IND[i_test]] - WK4[IND[i_test+1]]) :
                        (WK3[IND[i_test]] - WK3[IND[i_test+1]])
                    if diff_v > Float32(0.001)
                        break
                    end
                    len_cl += Int32(1)
                end
            end

            if ldebg
                @printf(io_units[JOSTND],
                    " IN COMPRS: NEW WAY: XRANG,PRANG,LN,LEN,I1,I2=%15.7e%15.7e%5d%5d%5d%5d\n",
                    xrang, prang, ln_val, len_cl, i1, i2_cl)
            end

            # Perform split
            ncls1 += Int32(1)
            IND1[ncls1] = IND1[irec_cl]
            i_split     = IND1[irec_cl] - len_cl
            IND1[irec_cl]  = i_split
            IND2[ncls1]    = len_cl
            IND2[irec_cl] -= len_cl
            jk_v = IND[i1]

            if !ltwo
                j_v          = IND[i_split + Int32(1)]
                WK6[ncls1]   = WK3[j_v] - xsmal
                j_v          = IND[i_split]
                WK6[irec_cl] = WK3[jk_v] - WK3[j_v]
                len_sub      = Int32(IND2[irec_cl])
                WK5[irec_cl] = CMRANG(len_sub, view(IND, i1:i1+len_sub-1), WK4)
                len_sub2     = Int32(IND2[ncls1])
                WK5[ncls1]   = CMRANG(len_sub2, view(IND, i_split+1:i_split+len_sub2), WK4)
            else
                j_v          = IND[i_split + Int32(1)]
                WK5[ncls1]   = WK4[j_v] - xsmal
                j_v          = IND[i_split]
                WK5[irec_cl] = WK4[jk_v] - WK4[j_v]
                len_sub      = Int32(IND2[irec_cl])
                RDPSRT(len_sub, WK3, view(IND, i1:i1+len_sub-1), false)
                len_sub2     = Int32(IND2[ncls1])
                RDPSRT(len_sub2, WK3, view(IND, i_split+1:i_split+len_sub2), false)
                jk_v         = IND[i1]
                j_v          = IND[i_split]
                WK6[irec_cl] = WK3[jk_v] - WK3[j_v]
                j_v2         = IND[i2_cl]
                jk_v2        = IND[i_split + Int32(1)]
                WK6[ncls1]   = WK3[jk_v2] - WK3[j_v2]
            end
        end

        # Sort class pointers
        IQRSRT(IND1, ncls1)
    end

    nclas = ncls1

    # -----------------------------------------------------------------------
    # Debug: class statistics
    # -----------------------------------------------------------------------
    if ldebg
        @printf(io_units[JOSTND],
            "\n\n CLASS TREE#   SCORES       PROB        MORT(WK2) IMC    ISP ICR ITRUNC NORMHT  DBH HT    PCT   DG   CFV        HT2TDBF HT2TDCF   ITRE\n")
        i1 = Int32(1)
        tsswc = Float32(0.0)
        for i_cl in 1:nclas
            sswc = Float32(0.0)
            i2   = IND1[i_cl]
            jk_v = i2 - i1 + 1
            j_v  = IND[i1]; k_v = IND[i2]
            x1   = WK3[j_v] - WK3[k_v]
            x2   = CMRANG(jk_v, view(IND, i1:i2), WK4)
            xbar = Float32(0.0)
            for icl_j in i1:i2; xbar += WK3[IND[icl_j]]; end
            xbar /= Float32(i2 - i1 + 1)
            for icl_j in i1:i2
                k_v = IND[icl_j]
                if i2 - i1 > 0; sswc += (WK3[k_v] - xbar)^2; end
                if ldebg
                    @printf(io_units[JOSTND],
                        "        %4d%15.7e%15.7e %7.3f %9.5f%3d%4d%4d%7d%7d%7.2f%7.2f%6.1f%6.2f%9.2f%9.2f%9.2f%6d\n",
                        k_v, WK3[k_v], WK4[k_v], PROB[k_v], WK2[k_v],
                        IMC[k_v], ISP[k_v], ICR[k_v], ITRUNC[k_v], NORMHT[k_v],
                        DBH[k_v], HT[k_v], PCT[k_v], DG[k_v], CFV[k_v],
                        HT2TD[k_v,2], HT2TD[k_v,1], ITRE[k_v])
                end
            end
            tsswc += sswc
            i1 = i2 + Int32(1)
        end
        @printf(io_units[JOSTND], "\n TOTAL WITHIN CLASS SUM OF SQUARES=%15.6e\n", tsswc)
    end

    # -----------------------------------------------------------------------
    # Step 7: Average tree attributes within each class
    # -----------------------------------------------------------------------
    # Ensure target record (IREC1) is always the lowest index in its class
    i1 = Int32(1)
    for icl in 1:nclas
        i2 = IND1[icl]
        if i1 < i2
            for ii in (i1+1):i2
                if IND[i1] > IND[ii]
                    tmp = IND[i1]; IND[i1] = IND[ii]; IND[ii] = tmp
                end
            end
        end
        i1 = i2 + Int32(1)
    end

    # WK5 = PROB + WK2 (total weight per tree)
    for i in 1:ITRN
        WK5[i] = PROB[i] + WK2[i]
    end

    # Extension hooks for compression
    RDCMPR(nclas, WK5, IND, IND1)
    BRCMPR(nclas, WK5, IND, IND1)
    FMCMPR(nclas)
    SVCMP1()

    ttprb = Float32(0.0)
    ttwk2 = Float32(0.0)
    i1 = Int32(1)

    for icl in 1:nclas
        i2    = IND1[icl]
        irec1 = IND[i1]

        if i1 == i2
            @goto label_480
        end

        # Cumulative PROB+WK2
        xp  = WK5[irec1]
        txp = xp
        WK3[irec1] = xp
        for i in (i1+1):i2
            irec = IND[i]
            xp   = WK5[irec]
            txp += xp
            WK3[irec] = txp
        end
        if txp == Float32(0.0)
            @goto label_480
        end

        # Random selection for discrete attributes
        RANN_rand!(x_rand)
        x_rand *= txp

        irec_sel = irec1
        for i in i1:i2
            irec_sel = IND[i]
            if x_rand <= WK3[irec_sel]
                break
            end
        end
        ltrnk = NORMHT[irec_sel] > Int32(0)

        ITRE[irec1]    = ITRE[irec_sel]
        ISP[irec1]     = ISP[irec_sel]
        KUTKOD[irec1]  = KUTKOD[irec_sel]
        ISPECL[irec1]  = ISPECL[irec_sel]
        IMC[irec1]     = IMC[irec_sel]
        IESTAT[irec1]  = IESTAT[irec_sel]
        IDTREE[irec1]  = IDCMP2 + IY[max(1, ICYC)]
        NCFDEF[irec1]  = NCFDEF[irec_sel]
        NBFDEF[irec1]  = NBFDEF[irec_sel]

        SVCMP2(irec1, irec_sel)

        idmr_v = Int32(0)
        MISGET(irec_sel, idmr_v)
        MISPUT(irec1, idmr_v)

        # Average height / truncation
        k_start = i1 + Int32(1)
        if !ltrnk
            hti_v  = Float32((NORMHT[irec1] > Int32(0)) ? NORMHT[irec1] / 100.0 : HT[irec1])
            hti_v *= WK5[irec1]
            NORMHT[irec1] = Int32(0)
            ITRUNC[irec1] = Int32(0)
            for i in k_start:i2
                irec = IND[i]
                x_h  = (NORMHT[irec] > Int32(0)) ? Float32(NORMHT[irec] / 100.0) : HT[irec]
                hti_v += x_h * WK5[irec]
            end
            HT[irec1] = hti_v / WK3[irec_sel]
        else
            # Truncated class averaging
            x_trunc = Float32(0.0)
            xp_sum  = Float32(0.0)
            for i in i1:i2
                irec = IND[i]
                if NORMHT[irec] <= Int32(0); continue; end
                x_trunc += Float32(ITRUNC[irec]) / 100.0f0 * WK5[irec]
                xp_sum  += HT[irec] * WK5[irec]
            end
            x_ratio = (xp_sum > Float32(0.0)) ? x_trunc / xp_sum : Float32(0.0)

            xit_v = Float32(0.0); xnr_v = Float32(0.0); hti_v = Float32(0.0)
            for i in i1:i2
                irec = IND[i]
                xp   = WK5[irec]
                hti_v += HT[irec] * xp
                if NORMHT[irec] > Int32(0)
                    xnr_v += Float32(NORMHT[irec]) / 100.0f0 * xp
                    xit_v += Float32(ITRUNC[irec]) / 100.0f0 * xp
                else
                    xnr_v += HT[irec] * xp
                    xit_v += HT[irec] * x_ratio * xp
                end
            end
            txp_v         = WK3[irec_sel]
            HT[irec1]     = hti_v / txp_v
            NORMHT[irec1] = Int32(floor(xnr_v / txp_v * 100.0f0))
            ITRUNC[irec1] = Int32(floor(xit_v / txp_v * 100.0f0))
        end

        # Initialize accumulators for continuous attributes
        xp_r    = WK5[irec1]
        bfvi    = BFV[irec1]          * xp_r
        cfvi    = CFV[irec1]          * xp_r
        mcfvi   = MCFV[irec1]         * xp_r
        scfvi   = SCFV[irec1]         * xp_r
        culli   = Float32(CULL[irec1])         * xp_r
        decayi  = Float32(DECAYCD[irec1])      * xp_r
        wdstemi = Float32(WDLDSTEM[irec1])     * xp_r
        agbioi  = ABVGRD_BIO[irec1]   * xp_r
        mbioi   = MERCH_BIO[irec1]    * xp_r
        csbioi  = CUBSAW_BIO[irec1]   * xp_r
        fbioi   = FOLI_BIO[irec1]     * xp_r
        agcarbi = ABVGRD_CARB[irec1]  * xp_r
        mcarbi  = MERCH_CARB[irec1]   * xp_r
        cscarbi = CUBSAW_CARB[irec1]  * xp_r
        fcarbi  = FOLI_CARB[irec1]    * xp_r
        cfracti = CARB_FRAC[irec1]    * xp_r
        ht2t1i  = HT2TD[irec1, 1]     * xp_r
        ht2t2i  = HT2TD[irec1, 2]     * xp_r
        dbhi    = DBH[irec1] * DBH[irec1] * xp_r
        dgi     = DG[irec1]            * xp_r
        htgi    = HTG[irec1]           * xp_r
        oldpti  = OLDPCT[irec1]        * xp_r
        pcti    = PCT[irec1]           * xp_r
        wk1i    = WK1[irec1]           * xp_r
        wk2i    = WK2[irec1]
        probi   = PROB[irec1]
        pcfvi   = PTOCFV[irec1]        * xp_r
        pmcvi   = PMRCFV[irec1]        * xp_r
        pscvi   = PSCFV[irec1]         * xp_r
        pmbvi   = PMRBFV[irec1]        * xp_r
        pdbhi   = PDBH[irec1]          * xp_r
        phti    = PHT[irec1]           * xp_r
        xicri   = Float32(ICR[irec1])          * xp_r
        df11    = Float32(DEFECT[irec1] ÷ 1000000) * xp_r
        df22    = Float32((DEFECT[irec1] ÷ 10000) - (DEFECT[irec1] ÷ 1000000) * 100) * xp_r
        df33    = Float32((DEFECT[irec1] ÷ 100)   - (DEFECT[irec1] ÷ 10000)   * 100) * xp_r
        df44    = Float32(DEFECT[irec1] - (DEFECT[irec1] ÷ 100) * 100) * xp_r
        crwdi   = CRWDTH[irec1]        * xp_r

        # Accumulate for remaining trees in class
        for i in k_start:i2
            irec = IND[i]
            IND[i] = -IND[i]   # mark vacant
            xp_r   = WK5[irec]

            bfvi    += BFV[irec]          * xp_r
            cfvi    += CFV[irec]          * xp_r
            mcfvi   += MCFV[irec]         * xp_r
            scfvi   += SCFV[irec]         * xp_r
            culli   += Float32(CULL[irec])         * xp_r
            decayi  += Float32(DECAYCD[irec])      * xp_r
            wdstemi += Float32(WDLDSTEM[irec])     * xp_r
            agbioi  += ABVGRD_BIO[irec]   * xp_r
            mbioi   += MERCH_BIO[irec]    * xp_r
            csbioi  += CUBSAW_BIO[irec]   * xp_r
            fbioi   += FOLI_BIO[irec]     * xp_r
            agcarbi += ABVGRD_CARB[irec]  * xp_r
            mcarbi  += MERCH_CARB[irec]   * xp_r
            cscarbi += CUBSAW_CARB[irec]  * xp_r
            fcarbi  += FOLI_CARB[irec]    * xp_r
            cfracti += CARB_FRAC[irec]    * xp_r
            ht2t1i  += HT2TD[irec, 1]     * xp_r
            ht2t2i  += HT2TD[irec, 2]     * xp_r
            x_d     = DBH[irec]
            dbhi    += x_d * x_d           * xp_r
            dgi     += DG[irec]            * xp_r
            htgi    += HTG[irec]           * xp_r
            oldpti  += OLDPCT[irec]        * xp_r
            pcti    += PCT[irec]           * xp_r
            wk1i    += WK1[irec]           * xp_r
            wk2i    += WK2[irec]
            probi   += PROB[irec]
            pcfvi   += PTOCFV[irec]        * xp_r
            pmcvi   += PMRCFV[irec]        * xp_r
            pscvi   += PSCFV[irec]         * xp_r
            pmbvi   += PMRBFV[irec]        * xp_r
            pdbhi   += PDBH[irec]          * xp_r
            phti    += PHT[irec]           * xp_r
            xicri   += Float32(ICR[irec])          * xp_r
            df11    += Float32(DEFECT[irec] ÷ 1000000) * xp_r
            df22    += Float32((DEFECT[irec] ÷ 10000) - (DEFECT[irec] ÷ 1000000) * 100) * xp_r
            df33    += Float32((DEFECT[irec] ÷ 100)   - (DEFECT[irec] ÷ 10000)   * 100) * xp_r
            df44    += Float32(DEFECT[irec] - (DEFECT[irec] ÷ 100) * 100) * xp_r
            crwdi   += CRWDTH[irec]        * xp_r

            SVCMP2(irec1, irec)
        end

        # Divide by total weight and store class average
        txp_v = WK3[irec_sel]
        BFV[irec1]         = bfvi    / txp_v
        CFV[irec1]         = cfvi    / txp_v
        MCFV[irec1]        = mcfvi   / txp_v
        SCFV[irec1]        = scfvi   / txp_v
        CULL[irec1]        = culli   / txp_v
        DECAYCD[irec1]     = Int32(round(decayi  / txp_v))
        WDLDSTEM[irec1]    = Int32(round(wdstemi / txp_v))
        ABVGRD_BIO[irec1]  = agbioi  / txp_v
        MERCH_BIO[irec1]   = mbioi   / txp_v
        CUBSAW_BIO[irec1]  = csbioi  / txp_v
        FOLI_BIO[irec1]    = fbioi   / txp_v
        ABVGRD_CARB[irec1] = agcarbi / txp_v
        MERCH_CARB[irec1]  = mcarbi  / txp_v
        CUBSAW_CARB[irec1] = cscarbi / txp_v
        FOLI_CARB[irec1]   = fcarbi  / txp_v
        CARB_FRAC[irec1]   = cfracti / txp_v
        HT2TD[irec1, 1]    = ht2t1i  / txp_v
        HT2TD[irec1, 2]    = ht2t2i  / txp_v
        DBH[irec1]         = sqrt(dbhi / txp_v)
        DG[irec1]          = dgi     / txp_v
        HTG[irec1]         = htgi    / txp_v
        OLDPCT[irec1]      = oldpti  / txp_v
        PCT[irec1]         = pcti    / txp_v
        WK1[irec1]         = wk1i    / txp_v
        WK2[irec1]         = wk2i
        ICR[irec1]         = Int32(round(xicri / txp_v))
        PROB[irec1]        = probi
        idf11              = Int32(floor(df11 / txp_v + Float32(0.5)))
        idf22              = Int32(floor(df22 / txp_v + Float32(0.5)))
        idf33              = Int32(floor(df33 / txp_v + Float32(0.5)))
        idf44              = Int32(floor(df44 / txp_v + Float32(0.5)))
        DEFECT[irec1]      = idf11*Int32(1000000) + idf22*Int32(10000) + idf33*Int32(100) + idf44
        PTOCFV[irec1]      = pcfvi   / txp_v
        PMRCFV[irec1]      = pmcvi   / txp_v
        PSCFV[irec1]       = pscvi   / txp_v
        PMRBFV[irec1]      = pmbvi   / txp_v
        PDBH[irec1]        = pdbhi   / txp_v
        PHT[irec1]         = phti    / txp_v
        CRWDTH[irec1]      = crwdi   / txp_v
        ZRAND[irec1]       = Float32(-999.0)

        @label label_480
        if ldebg
            ttprb += PROB[irec1]
            ttwk2 += WK2[irec1]
            @printf(io_units[JOSTND],
                " %6d%4d%43s%7.3f%9.5f%3d%4d%4d%7d%7d%7.2f%7.2f%6.1f%6.2f%9.2f%9.2f%9.2f%3d\n",
                icl, irec1, "",
                PROB[irec1], WK2[irec1], IMC[irec1], ISP[irec1], ICR[irec1],
                ITRUNC[irec1], NORMHT[irec1], DBH[irec1], HT[irec1],
                PCT[irec1], DG[irec1], CFV[irec1],
                HT2TD[irec1,2], HT2TD[irec1,1], ITRE[irec1])
        end

        i1 = i2 + Int32(1)
    end

    if ldebg
        @printf(io_units[JOSTND],
            " SUM OF PROB (AFTER)= %10.4f SUM OF MORT= %10.4f\n", ttprb, ttwk2)
    end

    # -----------------------------------------------------------------------
    # Step 8: Re-reference visualization and move trees to fill vacated slots
    # -----------------------------------------------------------------------
    SVCMP3()
    TREDEL(ITRN - nclas, IND)

    return nothing
end

# MEANSD: real implementation in base/meansd.jl (uses Ref-based output args)

# ---------------------------------------------------------------------------
# EIGEN! — IBM SSP symmetric eigenvector routine (translated from comprs context)
# Computes eigenvalues (written into diagonal of xtx) and eigenvectors (eivect)
# for a real symmetric matrix stored in lower-triangle vector form.
# Uses Householder tridiagonalization + QL iteration.
# ---------------------------------------------------------------------------
"""
    EIGEN!(xtx, eivect, nrank)

Compute eigenvalues and eigenvectors of a symmetric matrix.
`xtx` is the lower-triangle vector (length nrank*(nrank+1)/2).
Eigenvalues overwrite the diagonal of `xtx`; eigenvectors go to `eivect` (column-major).
"""
function EIGEN!(xtx::Vector{Float64}, eivect::Vector{Float64}, nrank::Int)
    n = nrank
    # Reconstruct full matrix from lower triangle
    A = zeros(Float64, n, n)
    ij = 0
    for i in 1:n
        for j in 1:i
            ij += 1
            A[i, j] = xtx[ij]
            A[j, i] = xtx[ij]
        end
    end

    # Use Julia's symmetric eigenvector decomposition
    F = eigen(Symmetric(A))
    # Sort eigenvalues descending (IBM SSP convention)
    perm = sortperm(F.values, rev=true)
    vals = F.values[perm]
    vecs = F.vectors[:, perm]

    # Write eigenvalues back to diagonal of xtx
    for i in 1:n
        diag_idx = i * (i + 1) ÷ 2
        xtx[diag_idx] = vals[i]
    end

    # Write eigenvectors to eivect (column-major, each column is one eigenvector)
    for j in 1:n
        for i in 1:n
            eivect[(j-1)*n + i] = vecs[i, j]
        end
    end
    return nothing
end

# All stubs for COMPRS call sites are in base/extstubs.jl or their own .jl files.
x_rand = Ref(Float32(0.0))
RANN_rand!(r) = (r[] = rand(Float32))
