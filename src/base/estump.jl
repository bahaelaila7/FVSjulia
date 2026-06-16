# estump.f — ESTUMP: store stump sprout record when a tree is cut (115 lines)
# Part of the STRP/ESTB establishment model.
# essprt.f:ESASID entry — return FVS species index for quaking aspen in this variant.

# ESASID: return species index of quaking aspen for variant VAR.
# For SN variant (not in the select case), returns 9999 (aspen not present).
function ESASID(var_::AbstractString, indxas_ref::Ref{Int32})
    idx = if var_ == "BC";         Int32(12)
    elseif var_ == "BM";           Int32(15)
    elseif var_ == "CA";           Int32(44)
    elseif var_ == "CR";           Int32(20)
    elseif var_ == "CS";           Int32(76)
    elseif var_ == "EC";           Int32(26)
    elseif var_ == "LS" || var_ == "ON"; Int32(41)
    elseif var_ == "NE";           Int32(49)
    elseif var_ == "OC";           Int32(44)
    elseif var_ == "OP";           Int32(26)
    elseif var_ == "PN" || var_ == "WC"; Int32(26)
    elseif var_ == "SO";           Int32(24)
    elseif var_ == "TT" || var_ == "UT"; Int32(6)
    elseif var_ == "WS";           Int32(36)
    else                           Int32(9999)
    end
    indxas_ref[] = idx
    return nothing
end

# ESTUMP: record a cut tree for stump sprout modeling.
# JSSP   = FVS species code of the cut tree
# DBH    = diameter (in) of the cut tree
# PREM   = TPA weight of the cut record
# JPLOT  = plot number (1..MAXPLT)
# ISHAG  = harvest age stored for the sprout cycle
function ESTUMP(jssp::Integer, dbh::Real, prem::Real,
                jplot::Integer, ishag::Integer)
    mdbh = Int32(10_000_000)
    msp  = Int32(10_000)

    # Check if JSSP is a sprouting species (linear search over ISPSPE)
    issp = 0
    for i in 1:Int(NSPSPE)
        if jssp == Int(ISPSPE[i])
            issp = i
            break
        end
    end
    if issp == 0
        # Not a sprouting species — still check aspen accumulation below
        @goto label_900
    end

    # Find diameter class
    idbh = Int(NDBHCL)
    for i in 1:Int(NDBHCL) - 1
        dbhend = (DBHMID[i] + DBHMID[i + 1]) / 2.0f0
        if dbh <= dbhend
            idbh = i
            break
        end
    end

    iplt = min(Int32(jplot), Int32(9999))
    ishi = Int32(idbh) * mdbh + Int32(issp) * msp + iplt

    global ITRNRM = ITRNRM + Int32(1)

    if ITRNRM <= Int32(MAXTRE)
        DSTUMP[Int(ITRNRM)] = Float32(dbh)
        ISHOOT[Int(ITRNRM)] = ishi
        PRBREM[Int(ITRNRM)] = Float32(prem)
        JSHAGE[Int(ITRNRM)] = Int32(ishag)
    else
        global ITRNRM = Int32(MAXTRE)
        # List full — find best matching existing record
        mnagdf = Int32(9999)
        ibest  = 0
        for i in 1:Int(ITRNRM)
            if ishi == ISHOOT[i]
                agdiff = abs(Int(ishag) - Int(JSHAGE[i]))
                if agdiff < Int(mnagdf)
                    ibest  = i
                    mnagdf = Int32(agdiff)
                end
            end
            if mnagdf == Int32(0); break; end
        end
        if ibest > 0
            PRBREM[ibest] += Float32(prem)
        end
    end

    @label label_900

    # Accumulate aspen BA/TPA if this species is quaking aspen in this variant
    indxas_r = Ref(Int32(0))
    ESASID(VARACD, indxas_r)
    if jssp == Int(indxas_r[])
        global ASTPAR = ASTPAR + Float32(prem)
        global ASBAR  = ASBAR  + Float32(0.0054542 * prem * Float64(dbh)^2)
    end
    return nothing
end
