# base/esplt.jl — ESPLT1 / ESPLT2 (establishment plot-setup)
# Translated from: bin/FVSsn_buildDir/esplt1.f (97) + esplt2.f (290)
#
# ESPLT1: called by INTREE per plot to record plot stockability + site data.
# ESPLT2: called once by INITRE to translate plot site variables for the estab
#         model, populating NPTIDS / IPTIDS / PSLO / PASP / IPHAB / IPHYS / IPPREP.
#
# Fortran EQUIVALENCEs reuse COMMON arrays as scratch and to pass the
# nonstockable-plot list from ESPLT1 to ESPLT2:
#   (NSID,ESB1)  — integer plot-ID list overlaid on the real ESB1 array
#   (NSTK,SUMPRB)— the list count overlaid on the real SUMPRB scalar
# Here ESB1 holds IDs as Float32 (small ints, exact) and SUMPRB holds the count.
# (NEW,PROB1)/(NON,PNN) are local scratch in ESPLT2 → plain local arrays in Julia.

const _ESPLT_IEND = Int32[269,299,319,335,385,394,399,499,509,515,519,522,
    523,524,529,564,579,584,589,599,634,637,644,649,659,669,689,
    699,709,719,739,744,799]
const _ESPLT_MYGRUP = Int32[3,1,4,2,4,3,4,3,8,6,8,7,
    5,7,8,9,10,6,8,5,13,16,11,14,16,12,15,12,14,15,11,15,14]

function ESPLT1(itrei::Integer, imc1::Integer, npnvrs::Integer, ipvars::AbstractVector)
    itrei = Int32(itrei)

    if IPINFO == Int32(1)
        # PLOTINFO already read — just check stockability of this plot (label 20).
        if Int(imc1) != 8; return nothing; end
        for i in 1:Int(NPTIDS)
            if Int32(IPTIDS[i]) == itrei
                IPPREP[i] = Int32(-1)
                return nothing
            end
        end
        # Not found — append to the nonstockable list (NSID/NSTK via ESB1/SUMPRB).
        nstk = Int(round(SUMPRB)) + 1
        global SUMPRB = Float32(nstk)
        ESB1[nstk] = Float32(itrei)
        return nothing
    end

    # Save plot stockability.
    global NPTIDS = NPTIDS + Int32(1)
    if NPTIDS > MAXPLT
        ERRGRO(false, Int32(13))
        if fvsGetRtnCode() != Int32(0); return nothing; end
    end
    IPTIDS[Int(NPTIDS)] = itrei
    IPPREP[Int(NPTIDS)] = Int32(0)

    if Int(imc1) == 8
        IPPREP[Int(NPTIDS)] = Int32(-1)
        return nothing
    end
    # Stockable (label 10): store site vars only if they were passed.
    if Int(npnvrs) <= 1; return nothing; end
    global IPINFO = Int32(2)
    PSLO[Int(NPTIDS)]  = Float32(ipvars[1])
    PASP[Int(NPTIDS)]  = Float32(ipvars[2])
    IPHAB[Int(NPTIDS)] = Int32(ipvars[3])
    IPHYS[Int(NPTIDS)] = Int32(ipvars[4])
    IPPREP[Int(NPTIDS)] = Int32(ipvars[5])
    return nothing
end

# Map a habitat code through the IEND/MYGRUP table → establishment habitat group.
function _esplt_habmap(code::Integer)::Int32
    for j in 1:33
        if Int32(code) <= _ESPLT_IEND[j]; return _ESPLT_MYGRUP[j]; end
    end
    return Int32(16)
end

function ESPLT2(iptknt::Integer)
    debug = DBCHK(false, "ESPLT2", Int32(6), Int(ICYC))
    iptknt = Int(iptknt)

    global IHTYPE = _esplt_habmap(ICL5)
    xxslp = Float32(ISLOP) * 0.01f0
    xxasp = Float32(IASPEC) * 0.0174533f0

    nm = 0
    new_ = zeros(Int32, Int(MAXPLT))   # local scratch (Fortran NEW≡PROB1)
    non  = zeros(Int32, Int(MAXPLT))   # local scratch (Fortran NON≡PNN)

    if iptknt > 0; @goto label_20; end

    # ---- no tree data (e.g. BARE): build a plot-ID vector with pointers ----
    if NPTIDS <= Int32(0) || IREC1 == Int32(0)
        global NPTIDS = IPTINV - NONSTK
        if NPTIDS <= Int32(0); global NPTIDS = Int32(1); end
    end
    for i in 1:Int(NPTIDS); IPTIDS[i] = Int32(i); end
    if IPINFO != Int32(0); @goto label_110; end
    nm = 1
    @goto label_150

    @label label_20
    if IPINFO != Int32(1); @goto label_80; end
    # ---- PLOTINFO option: match plot IDs with the tree file (label 20) ----
    let n = Int(NPTIDS)
        global NPTIDS = Int32(0)
        nstk = Int(round(SUMPRB))
        for j in 1:iptknt
            me = Int32(IPVEC[j])
            matched = false
            for i in 1:n
                if me == Int32(IPTIDS[i]);
                    # label 40: a match — keep if stockable
                    if IPPREP[j] != Int32(-1)
                        global NPTIDS = NPTIDS + Int32(1)
                        new_[Int(NPTIDS)] = Int32(j)
                    end
                    matched = true
                    break
                end
            end
            matched && continue
            # no match: if stockable and not in nonstockable list, record it
            innsk = false
            for j1 in 1:nstk
                if me == Int32(round(ESB1[j1])); innsk = true; break; end
            end
            innsk && continue
            nm += 1
            non[nm] = Int32(j)
        end
    end
    if NPTIDS > Int32(0); @goto label_60; end
    if nm <= 0
        global IPINFO = Int32(4)
        @goto label_140
    end
    for j in 1:nm; IPTIDS[j] = non[j]; end
    global IPINFO = Int32(5)
    global NPTIDS = Int32(nm)
    nm = 1
    @goto label_150

    @label label_60
    for i in 1:Int(NPTIDS); IPTIDS[i] = new_[i]; end
    @goto label_110

    @label label_80
    # ---- PLOTINFO not used: drop nonstockable plots (IPPREP<0) ----
    let n = Int(NPTIDS)
        global NPTIDS = Int32(0)
        for i in 1:n
            if IPPREP[i] >= Int32(0)
                global NPTIDS = NPTIDS + Int32(1)
                IPTIDS[Int(NPTIDS)] = Int32(i)
            end
        end
        extra = Int(IPTINV) - Int(NONSTK) - n
        if extra > 0
            for _ in 1:extra
                global NPTIDS = NPTIDS + Int32(1)
                IPTIDS[Int(NPTIDS)] = NPTIDS
                PSLO[Int(NPTIDS)]  = -1.0f0
                PASP[Int(NPTIDS)]  = -1.0f0
                IPHAB[Int(NPTIDS)] = ICL5
                IPPREP[Int(NPTIDS)] = Int32(1)
                IPHYS[Int(NPTIDS)] = Int32(3)
            end
        end
    end
    if NPTIDS <= Int32(0)
        global IPINFO = Int32(4)
        @goto label_140
    end
    if IPINFO == Int32(2); @goto label_110; end
    nm = 1
    @goto label_150

    @label label_110
    # ---- decode plot-specific site variables ----
    for nn in 1:Int(NPTIDS)
        i = Int(IPTIDS[nn])
        PSLO[i] = PSLO[i] < 0.0f0 ? xxslp : PSLO[i] * 0.01f0
        if IPHYS[i] < Int32(1) || IPHYS[i] > Int32(5); IPHYS[i] = Int32(3); end
        PASP[i] = PASP[i] < 0.0f0 ? xxasp : PASP[i] * 0.0174533f0
        if IPPREP[i] < Int32(1) || IPPREP[i] > Int32(4); IPPREP[i] = Int32(1); end
        if IPHAB[i] == Int32(0); IPHAB[i] = ICL5; end
        IPHAB[i] = _esplt_habmap(IPHAB[i])
    end
    if nm == 0; @goto label_170; end
    for j in 1:nm; IPTIDS[Int(NPTIDS)+j] = non[j]; end
    global IPINFO = Int32(3)
    global NPTIDS = NPTIDS + Int32(nm)
    nm = Int(NPTIDS) - nm + 1
    @goto label_150

    @label label_140
    IPTIDS[1] = Int32(1)
    global NPTIDS = Int32(1)
    nm = 1

    @label label_150
    for nn in nm:Int(NPTIDS)
        i = Int(IPTIDS[nn])
        PSLO[i]  = xxslp
        PASP[i]  = xxasp
        IPHAB[i] = IHTYPE
        IPPREP[i] = Int32(1)
        IPHYS[i] = Int32(3)
    end

    @label label_170
    if IPINFO > Int32(0) && IPINFO != Int32(5); global LOAD = Int32(1); end
    if IPINFO == Int32(5); global IPINFO = Int32(3); end
    return nothing
end
