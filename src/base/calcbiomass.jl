# calcbiomass.jl — CalcBiomass / BiomassLibrary / BiomassLibrary2
# Translated from: calcbiomass.f (556 lines)
#
# JENKINS and WOODDEN are fully implemented using WDBKWT (wdbkwt_data.jl).
# BiomassLibrary2 / NBEL functions remain stubbed (complex equation library).

# ---------------------------------------------------------------------------
# JENKINS — Jenkins et al. (2003) above-ground biomass equations
# spn: FIA species code (>=10) OR Jenkins group code (1-10 if <10)
# dia: DBH outside bark (inches)
# jnkbms(8): output biomass components (lbs)
#   1=above-ground total, 2=stem wood, 3=stem bark, 4=foliage,
#   5=coarse roots, 6=branches, 7=crown(fol+branch), 8=stem wood+bark
# ---------------------------------------------------------------------------
function JENKINS(spn::Integer, dia::Real, jnkbms::AbstractVector{Float32})
    fill!(jnkbms, Float32(0))
    KG2LB = Float32(2.20462)
    # Coefficient table: [group_code, B0, B1] for 10 Jenkins groups
    # Group 1=Cedar/Larch, 2=Douglas-fir, 3=True fir/Hemlock, 4=Pine,
    #       5=Spruce, 6=Aspen/Alder/Cottonwood/Willow,
    #       7=Soft maple/Birch, 8=Mixed hardwood,
    #       9=Hard maple/Oak/Hickory/Beech, 10=Juniper/Oak/Mesquite
    COEF_B0 = Float32[-2.0336, -2.2304, -2.5384, -2.5356, -2.0773,
                      -2.2094, -1.9123, -2.4800, -2.0127, -0.7152]
    COEF_B1 = Float32[ 2.2592,  2.4435,  2.4814,  2.4349,  2.3323,
                       2.3867,  2.3651,  2.4835,  2.4342,  1.7029]

    spcd    = Int(spn)
    spcls   = Int32(0)   # 0=softwood, 1=hardwood
    spgrpcd = Int32(8)   # default: mixed hardwood

    if spcd < 10
        # Input is already a Jenkins group code
        spgrpcd = spcd == 0 ? Int32(10) : Int32(spcd)
        spcls   = spgrpcd >= 6 ? Int32(1) : Int32(0)
    else
        # Binary search in WDBKWT (sorted by FIA code in col 1)
        lo = 1; hi = Int(WDBKWT_TOTSPC); done = Int(WDBKWT_CNT999)
        while lo <= hi
            mid = (lo + hi) >>> 1
            code = Int(WDBKWT[mid, 1])
            if code == spcd; done = mid; break
            elseif code < spcd; lo = mid + 1
            else; hi = mid - 1
            end
        end
        spcls   = Int32(WDBKWT[done, 2])
        spgrpcd = Int32(WDBKWT[done, 3])
    end

    dbhin = Float32(dia)
    dbhcm = Float32(2.54) * dbhin

    if dbhcm <= Float32(0)
        return nothing
    end

    # Above-ground total biomass (kg)
    gi = Int(spgrpcd)
    if gi < 1 || gi > 10; gi = 8; end
    b0 = COEF_B0[gi]; b1 = COEF_B1[gi]
    abt = exp(b0 + b1 * log(dbhcm))   # kg

    # Component ratios
    if spcls == Int32(0)   # softwood
        a0f = Float32(-2.9584); a1f = Float32(4.4766)
        a0r = Float32(-1.5619); a1r = Float32(0.6614)
        a0b = Float32(-2.0980); a1b = Float32(-1.1432)
        a0w = Float32(-0.3737); a1w = Float32(-1.8055)
    else                   # hardwood
        a0f = Float32(-4.0813); a1f = Float32(5.8816)
        a0r = Float32(-1.6911); a1r = Float32(0.8160)
        a0b = Float32(-2.0129); a1b = Float32(-1.6805)
        a0w = Float32(-0.3065); a1w = Float32(-5.4240)
    end

    fol  = abt * exp(a0f + a1f / dbhcm)
    root = abt * exp(a0r + a1r / dbhcm)

    if dbhin < Float32(5)
        bark = Float32(0); wood = Float32(0); stmtot = Float32(0)
        branches = abt - fol
        crown    = abt
    else
        bark     = abt * exp(a0b + a1b / dbhcm)
        wood     = abt * exp(a0w + a1w / dbhcm)
        stmtot   = wood + bark
        branches = abt - stmtot - fol   # stump ignored (stub RAILEVOL = 0)
        crown    = abt - stmtot
    end

    jnkbms[1] = Float32(abt      * KG2LB)  # above-ground total
    jnkbms[2] = Float32(wood     * KG2LB)  # stem wood
    jnkbms[3] = Float32(bark     * KG2LB)  # stem bark
    jnkbms[4] = Float32(fol      * KG2LB)  # foliage
    jnkbms[5] = Float32(root     * KG2LB)  # coarse roots
    jnkbms[6] = Float32(branches * KG2LB)  # branches
    jnkbms[7] = Float32(crown    * KG2LB)  # crown
    jnkbms[8] = Float32(stmtot   * KG2LB)  # stem wood + bark
    return nothing
end

# WOODDEN — wood and bark dry density (lb/cf) from WDBKWT
function WOODDEN(spn::Integer, wden_ref::Ref{Float32}, bden_ref::Ref{Float32})
    wden_ref[] = Float32(30); bden_ref[] = Float32(25)   # defaults
    spcd = Int(spn)
    spcd < 10 && return nothing
    lo = 1; hi = Int(WDBKWT_TOTSPC)
    while lo <= hi
        mid = (lo + hi) >>> 1
        code = Int(WDBKWT[mid, 1])
        if code == spcd
            wden_ref[] = Float32(WDBKWT[mid, 4])
            bden_ref[] = Float32(WDBKWT[mid, 5])
            return nothing
        elseif code < spcd; lo = mid + 1
        else; hi = mid - 1
        end
    end
    return nothing
end

function SAPLINGADJ(spn::Integer, ratio_ref::Ref{Float32})
    ratio_ref[] = Float32(1)
    spcd = Int(spn)
    spcd < 10 && return nothing
    lo = 1; hi = Int(WDBKWT_TOTSPC)
    while lo <= hi
        mid = (lo + hi) >>> 1
        code = Int(WDBKWT[mid, 1])
        if code == spcd
            ratio_ref[] = Float32(WDBKWT[mid, 11])
            return nothing
        elseif code < spcd; lo = mid + 1
        else; hi = mid - 1
        end
    end
    return nothing
end
function FIABEQ2NVELBEQ(beqnum::Integer, spn::Integer, nvelbeq_ref::Ref{String},
                         geosub_ref::Ref{String}, errflg_ref::Ref{Int32})
    nvelbeq_ref[] = "            "; errflg_ref[] = Int32(0); return nothing
end
function str2int(s::AbstractString, val_ref::Ref{Int32}, stat_ref::Ref{Int32})
    v = tryparse(Int32, strip(s))
    if isnothing(v); stat_ref[] = Int32(1); return nothing; end
    val_ref[] = v; stat_ref[] = Int32(0); return nothing
end
function FIA_NW(bioeq::AbstractString, dia::Real, ht::Real, vol::AbstractVector{Float32}, bioms_ref::Ref{Float32})
    bioms_ref[] = Float32(0); return nothing
end
function FIA_RM(bioeq::AbstractString, dia::Real, ht::Real, stems::Integer, vol::AbstractVector{Float32}, bioms_ref::Ref{Float32})
    bioms_ref[] = Float32(0); return nothing
end
function FIA_NC(bioeq::AbstractString, dia::Real, ht::Real, vol::AbstractVector{Float32}, bioms_ref::Ref{Float32})
    bioms_ref[] = Float32(0); return nothing
end
function FIA_NE(bioeq::AbstractString, dia::Real, ht::Real, vol::AbstractVector{Float32}, bioms_ref::Ref{Float32})
    bioms_ref[] = Float32(0); return nothing
end
function FIA_SE(bioeq::AbstractString, dia::Real, ht::Real, vol::AbstractVector{Float32}, bioms_ref::Ref{Float32})
    bioms_ref[] = Float32(0); return nothing
end
function PI_BIOMASS(spn::Integer, bioeq::AbstractString, dia::Real, ht::Real, cv4::Real,
                    bioms_ref::Ref{Float32}, errflg_ref::Ref{Int32})
    bioms_ref[] = Float32(0); errflg_ref[] = Int32(0); return nothing
end
function BROWN(bioeq::AbstractString, dia::Real, ht::Real, cr::Real,
               bioms_ref::Ref{Float32}, errflg_ref::Ref{Int32})
    bioms_ref[] = Float32(0); errflg_ref[] = Int32(0); return nothing
end
function BioeqFormula(eqform::Integer, dia::Real, ht::Real, cr::Real, topd::Real,
                      a::Real, b::Real, c::Real, d::Real, e::Real, bioms_ref::Ref{Float32})
    # Translated from biomassformula.f (BioeqFormula subroutine, 128 lines)
    dbh = Float32(dia); tht = Float32(ht); topd_f = Float32(topd)
    cr_f = Float32(cr)
    af = Float32(a); bf = Float32(b); cf = Float32(c)
    df = Float32(d); ef = Float32(e)

    if cr_f > 1.0f0 || cr_f <= 0.0f0; cr_f = 0.5f0; end
    if topd_f <= 0.0f0; topd_f = 4.0f0; end
    cl = cr_f * tht

    bms = 0.0f0
    eq = Int(eqform)
    if eq == 1
        bms = 10.0f0^(af + bf * log10(dbh^cf))
    elseif eq == 2
        bms = exp(af + bf * dbh + cf * log(dbh^df) + ef * tht)
    elseif eq == 3
        bms = exp(af + bf * log(dbh) + cf * (df + ef * log(dbh)))
    elseif eq == 4
        bms = af + bf * dbh + cf * dbh^df + ef * dbh^2 * tht
    elseif eq == 5
        bms = af + bf * dbh + cf * dbh^2 + df * dbh^3 + ef * dbh * tht
    elseif eq == 6
        bms = af * exp(bf + cf * log(dbh) + df * dbh)
    elseif eq == 7
        bms = af + (bf * dbh^cf) / (dbh^cf + df)
    elseif eq == 8
        bms = 100.0f0^(af + bf * log10(dbh))
    elseif eq == 9
        bms = exp(log(af) + bf * log(dbh))
    elseif eq == 10
        bms = exp(af + bf * log(dbh)) * exp(cf + df / dbh)
    elseif eq == 11
        bms = af + bf * dbh^2 * tht + cf * dbh^3 + df * dbh * tht
    elseif eq == 12
        bms = exp(af + bf * log(dbh) + cf * log(tht))
    elseif eq == 13
        bms = exp(af + bf * log(dbh) + df * log(tht)) * cf
    elseif eq == 14
        bms = exp(af + bf * log(dbh)) / (cf + df * dbh^ef)
    elseif eq == 15
        bms = af + bf * tht + cf * tht^2
    elseif eq == 16
        bms = af * dbh^bf * tht^cf
    elseif eq == 17
        bms = af + bf * dbh + cf * dbh^2 + df * tht + ef * dbh^2 * tht
    elseif eq == 18
        bms = exp(af + bf * log(dbh) + cf * log(cr_f) + df * log(cr_f * tht))
    elseif eq == 19
        bms = 1.0f0 - exp(af * topd_f^bf * dbh^cf)
    elseif eq == 33
        bms = dbh < 11.0f0 ? af * (dbh^2)^bf : cf * (dbh^2)^df
    elseif eq == 34
        bms = dbh < 11.0f0 ? af * (dbh^2 * tht)^bf : cf * (dbh^2)^df * tht^ef
    elseif eq == 35
        bms = af + bf * dbh^3 + cf * dbh^2 * cr_f + df * dbh^2 * tht * cr_f
    elseif eq == 36
        bms = af + bf * dbh^2 + cf * dbh^2 * tht + df * dbh * tht * cr_f + ef * dbh^2 * tht * cr_f
    elseif eq == 37
        bms = exp(af + bf * log(dbh * tht) + cf * log(tht * cr_f))
    elseif eq == 38
        bms = af + bf * tht + cf * tht * cr_f + df * dbh * tht * cr_f
    elseif eq == 39
        bms = af * dbh^bf * tht^cf * exp(df * cr_f)
    elseif eq == 40
        bms = af + bf * dbh^cf * tht^df * cl^ef
    elseif eq == 41
        bms = 1.0f0 / (1.0f0 + af * dbh^bf)
    elseif eq == 42
        bms = af * dbh^bf * exp(cf * tht)
    elseif eq == 43
        bms = af * dbh^2 * tht * (bf + cf * topd_f / dbh + df * (topd_f / dbh)^2) / 100.0f0
    end

    bioms_ref[] = isnan(bms) || !isfinite(bms) ? Float32(0) : bms
    return nothing
end

function BIOMASSFORMULA(eqform::Integer, dia::Real, ht::Real, cr::Real,
                        a::Real, b::Real, c::Real, d::Real, e::Real,
                        bioms_ref::Ref{Float32})
    BioeqFormula(eqform, dia, ht, cr, Float32(4.0), a, b, c, d, e, bioms_ref)
    return nothing
end
function BIOEQDB(bioeq::AbstractString, dia::Real, ht::Real, ht1prd::Real, ht2prd::Real,
                 cr::Real, topd::Real, bioms_ref::Ref{Float32}, errflg_ref::Ref{Int32})
    bioms_ref[] = Float32(0); errflg_ref[] = Int32(0); return nothing
end
function MILESDATA(spcd::Integer, sg::AbstractVector{Float32})
    fill!(sg, Float32(0))
    sg[9]  = Float32(55); sg[10] = Float32(30)   # defaults
    s = Int(spcd)
    s < 10 && return nothing
    lo = 1; hi = Int(WDBKWT_TOTSPC)
    while lo <= hi
        mid = (lo + hi) >>> 1
        code = Int(WDBKWT[mid, 1])
        if code == s
            for j in 1:min(12, length(sg)); sg[j] = Float32(WDBKWT[mid, j]); end
            return nothing
        elseif code < s; lo = mid + 1
        else; hi = mid - 1
        end
    end
    return nothing
end
function CRZSPDFT(regn::Integer, forst::AbstractString, spec::Integer,
                  wf::AbstractVector{Float32}, bmseq::Any, ref::Any)
    fill!(wf, Float32(0)); return nothing
end

function CalcBiomass(beq::AbstractString, dbh::Real, tht::Real, cr::Real, bms_ref::Ref{Float32})
    bms_ref[] = Float32(0)
    ht1 = Float32(0); ht2 = Float32(0); topd = Float32(0)
    vol = zeros(Float32, 15)
    errflg = Ref(Int32(0))
    BiomassLibrary(beq, Float32(dbh), Float32(tht), Float32(cr),
        ht1, ht2, topd, Int32(1), vol, bms_ref, errflg)
    return nothing
end

function BiomassLibrary(bioeq::AbstractString, dbhob::Real, httot::Real, cr::Real,
                         ht1prd::Real, ht2prd::Real, topd::Real,
                         stems::Integer, vol::AbstractVector{Float32},
                         bioms_ref::Ref{Float32}, errflg_ref::Ref{Int32})
    spn = Int32(0); geosub = Ref("0           ")
    BiomassLibrary2(bioeq, dbhob, httot, cr, ht1prd, ht2prd, topd,
        stems, vol, bioms_ref, errflg_ref, spn, geosub)
    return nothing
end

function BiomassLibrary2(bioeq::AbstractString, dbhob::Real, httot::Real, cr::Real,
                          ht1prd::Real, ht2prd::Real, topd::Real,
                          stems::Integer, vol::AbstractVector{Float32},
                          bioms_ref::Ref{Float32}, errflg_ref::Ref{Int32},
                          spn::Integer, geosub::Union{Ref{String},AbstractString})
    # Stubbed: NBEL library not yet translated
    bioms_ref[]  = Float32(0)
    errflg_ref[] = Int32(0)
    return nothing
end
