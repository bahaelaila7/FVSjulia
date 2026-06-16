# base/update.jl — UPDATE: add growth, deduct mortality, call VOLS
# Translated from: bin/FVSsn_buildDir/update.f (118 lines)
#
# Called from GRADD each cycle.  Adds height increments, deducts mortality
# from PROB, computes mortality distribution statistics, calls VOLS for volumes,
# then advances DBH by DG/BRATIO.

function UPDATE()
    debug = DBCHK(false, "UPDATE", Int32(6), ICYC)
    io    = get(io_units, Int(JOSTND), stdout)

    # -----------------------------------------------------------------------
    # Zero mortality accumulator arrays
    # -----------------------------------------------------------------------
    spcmo = zeros(Float32, Int(MAXSP), 3)   # [sp, tree_class] mortality volume
    for i in 1:7
        OMORT[i] = Float32(0)
    end

    # -----------------------------------------------------------------------
    # Species loop: add height increment, deduct mortality from PROB
    # -----------------------------------------------------------------------
    for is in 1:Int(MAXSP)
        i1 = Int(ISCT[is, 1])
        if i1 == 0; continue; end
        i2 = Int(ISCT[is, 2])

        for j in i1:i2
            i_t = Int(IND1[j])

            # Add height increment
            HT[i_t] += HTG[i_t]
            if NORMHT[i_t] > Int32(0)
                NORMHT[i_t] = Int32(floor(Float32(NORMHT[i_t]) + HTG[i_t] * Float32(100) + Float32(0.5)))
            end

            # Deduct mortality from PROB
            im  = Int(IMC[i_t])
            wki = WK2[i_t]
            if wki > PROB[i_t]; wki = PROB[i_t]; end
            WK6[i_t]        = wki * CFV[i_t] / FINT
            spcmo[is, im]  += WK6[i_t]
            PROB[i_t]       = max(Float32(0), PROB[i_t] - wki)
        end

        if debug
            @printf(io, " IN UPDATE,  SPECIES=%3d,  CUM. MORT. VOL. BY TREE CLASS=%8.3f,%8.3f,%8.3f,\n",
                    is, spcmo[is, 1], spcmo[is, 2], spcmo[is, 3])
        end
    end

    # -----------------------------------------------------------------------
    # Load WK3 with percentile distribution of mortality volume (WK6)
    # and compute OMORT(7) total mortality volume
    # -----------------------------------------------------------------------
    OMORT[7] = PCTILE(Int(ITRN), IND, WK6, WK3)
    DIST(ITRN, OMORT, WK3)                # distributes percentile values into OMORT
    COMP(OSPMO, IOSPMO, spcmo)            # species composition for mortality

    # -----------------------------------------------------------------------
    # Volume calculations (VOLS is a stub until volumes are translated)
    # -----------------------------------------------------------------------
    if debug
        @printf(io, " CALLING VOLS, CYCLE=%2d\n", ICYC)
    end
    VOLS()

    # -----------------------------------------------------------------------
    # Update DBH to end-of-cycle values: DBH += DG / BRATIO
    # -----------------------------------------------------------------------
    if ITRN == Int32(0); return nothing; end

    for i in 1:Int(ITRN)
        is_i = Int(ISP[i])
        DBH[i] += DG[i] / BRATIO(is_i, DBH[i], HT[i])
    end

    return nothing
end
