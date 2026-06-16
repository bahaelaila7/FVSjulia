# fmsadd.f — Add new snags to the snag list
# FMSADD: averages new snags by species+DBH+height class; handles record allocation
# Called from: FMEFF, FMKILL, FMSDIT, FMSCUT, FMSNAG

function FMSADD(year::Integer, ityp::Integer)
    debug = DBCHK("FMSADD", 6, ICYC)
    if debug
        @printf(get(io_units, Int32(JOSTND), stdout),
            " FMSADD CYCLE=%2d YEAR=%5d LFMON=%s ITYP=%5d ITRN=%5d\n",
            ICYC, year, LFMON, ityp, ITRN)
    end

    if !LFMON; return nothing; end

    local losses::Int = 0
    local gaps::Bool  = NSNAG > 3
    local igap::Int   = 1
    local mxs::Int    = Int(MXSNAG)
    local mxsp::Int   = Int(MAXSP)

    local taken  = zeros(Int, mxs)
    local midht  = zeros(Float32, mxsp, 19)
    local record = zeros(Int, mxsp, 19, 2)

    for spcl in 1:mxsp; for dbhcl in 1:19
        if DSPDBH[spcl, dbhcl] <= 0.0f0 || MAXHT[spcl, dbhcl] <= 0.0f0; continue; end
        local nhtcl::Int = 1
        if (MAXHT[spcl, dbhcl] - MINHT[spcl, dbhcl]) > 20.0f0
            midht[spcl, dbhcl] = (MAXHT[spcl, dbhcl] + MINHT[spcl, dbhcl]) / 2.0f0
            nhtcl = 2
        end

        for i in 1:nhtcl
            # Try to find an empty gap record
            if gaps
                found_gap = false
                for j in igap:Int(NSNAG)
                    if (DENIH[j] + DENIS[j]) <= 0.0f0 && taken[j] <= 0
                        record[spcl, dbhcl, i] = j
                        taken[j] = 1; igap = j
                        found_gap = true
                        @goto label_29
                    end
                end
                if !found_gap; gaps = false; end
            end

            # Try to use next unused record
            if Int(NSNAG) < mxs
                global NSNAG = NSNAG + Int32(1)
                record[spcl, dbhcl, i] = Int(NSNAG)
                taken[Int(NSNAG)] = 1
                @goto label_29
            end

            # Find record with fewest snags to overwrite
            local minden::Float32 = 99999.9f0
            local best_j::Int = 0
            for j in 1:mxs
                local denj::Float32 = DENIH[j] + DENIS[j]
                if denj < minden && taken[j] <= 0
                    minden = denj; best_j = j
                end
            end
            record[spcl, dbhcl, i] = best_j

            if DSPDBH[spcl, dbhcl] >= minden
                if best_j > 0; taken[best_j] = 1; end
                @goto label_27
            end

            # Look among already-assigned new-snag records
            minden = 99999.9f0
            local spcut::Int = 0; local dbhcut::Int = 0; local htcut::Int = 0
            for sp2 in 1:spcl; for dbh2 in 1:19; for ht2 in 1:2
                if record[sp2, dbh2, ht2] > 0 && DSPDBH[sp2, dbh2] < minden
                    minden = DSPDBH[sp2, dbh2]
                    spcut = sp2; dbhcut = dbh2; htcut = ht2
                end
            end; end; end

            if DSPDBH[spcl, dbhcl] > minden
                record[spcl, dbhcl, i] = record[spcut, dbhcut, htcut]
                record[spcut, dbhcut, htcut] = 0
            else
                record[spcl, dbhcl, i] = 0
            end

            @label label_27
            if losses == 0
                println("OLD SNAGS OVERWRITTEN OR NEW SNAGS DISCARDED.")
            end
            losses += 1

            @label label_29
            local x::Int = record[spcl, dbhcl, i]
            if x > 0
                DEND[x]   = 0.0f0
                DBHS[x]   = 0.0f0
                HTDEAD[x] = 0.0f0
                SPS[x]    = Int32(spcl)
                HARD[x]   = true
                YRDEAD[x] = Int32(year)
            end
        end
    end; end  # DBHCL, SPCL loops

    # Expand ITRN for initialization mode
    local olditn::Int32 = ITRN
    if ityp == 3; global ITRN = Int32(MAXTRE); end

    if ityp >= 0
        for i in 1:Int(ITRN)
            if SNGNEW[i] <= 0.0f0; continue; end

            local spcl::Int = Int(ISP[i])
            local dbhcl::Int = DBH[i] >= 36.0f0 ? 19 : Int(floor(DBH[i] / 2.0f0 + 1.0f0))
            dbhcl = clamp(dbhcl, 1, 19)

            local htcl::Int = midht[spcl, dbhcl] <= 0.0f0 ? 1 :
                              (HT[i] < midht[spcl, dbhcl] ? 1 : 2)

            # Collect crown components of non-fire-killed snags into CWD2B
            local unfire::Float32 = max(0.0f0, SNGNEW[i] - FIRKIL[i])
            FMSCRO(Int32(i), Int32(spcl), Int32(year), unfire, Int32(ityp))

            # Root biomass accounting
            local abio_ref = Ref(Float32(0)); local mbio_ref = Ref(Float32(0)); local rbio_ref = Ref(Float32(0))
            FMCBIO(DBH[i], Int32(ISP[i]), abio_ref, mbio_ref, rbio_ref)
            local xdcay::Float32 = 1.0f0
            if ityp == 3 && CRDCAY > 0.0f0
                xdcay = (1.0f0 - CRDCAY)^10
            end
            global BIOROOT = BIOROOT + rbio_ref[] * SNGNEW[i] * xdcay

            if debug
                @printf(get(io_units, Int32(JOSTND), stdout),
                    " IN FMSADD, I=%4d SNGNEW=%7.3f FIRKIL=%7.3f HTCL=%2d SPCL=%2d DBHCL=%2d RECORD=%6d\n",
                    i, SNGNEW[i], FIRKIL[i], htcl, spcl, dbhcl, record[spcl, dbhcl, htcl])
            end

            local x::Int = record[spcl, dbhcl, htcl]
            if x <= 0
                SNGNEW[i] = 0.0f0
                continue
            end

            # Average new snags into their record
            local totden::Float32 = DEND[x] + SNGNEW[i]
            if ityp == 3
                HTDEAD[x] = (HTDEAD[x] * DEND[x] +
                              max(HT[i], NORMHT[i] * 0.01f0) * SNGNEW[i]) / totden
            else
                HTDEAD[x] = (HTDEAD[x] * DEND[x] + HT[i] * SNGNEW[i]) / totden
            end
            DBHS[x]  = (DBHS[x] * DEND[x] + DBH[i] * SNGNEW[i]) / totden
            DEND[x]  = totden

            if ityp == 3
                if ITRUNC[i] > 0
                    HTIH[x] = Float32(ITRUNC[i]) * 0.01f0
                    HTIS[x] = Float32(ITRUNC[i]) * 0.01f0
                else
                    HTIH[x] = HTDEAD[x]
                    HTIS[x] = HTDEAD[x]
                end
            end

            SNGNEW[i] = 0.0f0
        end
    end

    if ityp == 3; global ITRN = olditn; end

    # Keyword-entered snag
    if ityp < 0
        local jact::Int = -ityp
        local jyr_ref = Ref(Int32(0)); local iactk_ref = Ref(Int32(0))
        local nprm_ref = Ref(Int32(0)); local prms = zeros(Float32, 6)
        OPGET(Int32(jact), Int32(6), jyr_ref, iactk_ref, nprm_ref, prms)
        local spcl::Int = Int(prms[1])
        for dbhcl in 1:19; for htcl in 1:2
            local x::Int = record[spcl, dbhcl, htcl]
            if x <= 0; continue; end
            DBHS[x] = prms[2]; HTDEAD[x] = prms[3]; DEND[x] = prms[6]
            local abio_ref = Ref(Float32(0)); local mbio_ref = Ref(Float32(0)); local rbio_ref = Ref(Float32(0))
            FMCBIO(prms[2], Int32(spcl), abio_ref, mbio_ref, rbio_ref)
            local xdcay::Float32 = 1.0f0
            if CRDCAY > 0.0f0 && prms[5] > 0.0f0
                xdcay = (1.0f0 - CRDCAY)^prms[5]
            end
            global BIOROOT = BIOROOT + rbio_ref[] * prms[6] * xdcay
            @goto label_162
        end; end
        @label label_162
    end

    # Finalize snag records: set initial heights and hard/soft split
    for spcl in 1:mxsp; for dbhcl in 1:19
        MAXHT[spcl, dbhcl]  = 0.0f0
        MINHT[spcl, dbhcl]  = 1000.0f0
        DSPDBH[spcl, dbhcl] = 0.0f0
        for htcl in 1:2
            local x::Int = record[spcl, dbhcl, htcl]
            if x > 0 && DEND[x] > 0.0f0
                if ityp != 3
                    HTIH[x] = HTDEAD[x]
                    HTIS[x] = HTDEAD[x]
                end
                DENIH[x] = (1.0f0 - PSOFT[spcl]) * DEND[x]
                DENIS[x] = PSOFT[spcl] * DEND[x]
                if ityp < 0
                    local prms2 = zeros(Float32, 6)
                    local jyr2 = Ref(Int32(0)); local iactk2 = Ref(Int32(0)); local nprm2 = Ref(Int32(0))
                    OPGET(Int32(-ityp), Int32(6), jyr2, iactk2, nprm2, prms2)
                    HTIH[x] = prms2[4]; HTIS[x] = prms2[4]
                end
                if debug
                    @printf(get(io_units, Int32(JOSTND), stdout),
                        " IN FMSADD, X=%5d DEND=%10.3f DENIH=%10.3f DENIS=%10.3f\n",
                        x, DEND[x], DENIH[x], DENIS[x])
                end
            end
        end
    end; end

    if losses > 0
        @printf(stderr, " THIS HAPPENED %4d TIMES.\n", losses)
    end
    return nothing
end
