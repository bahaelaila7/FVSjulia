# stkval.jl — STKVAL: compute per-ITG-group stocking values for all trees
# Translated from: stkval.f (647 lines)
#
# Fills S(210) array with basal-area-equivalent stocking by initial type group (ITG).
# Also sets globals ISZCL (size class) and ISTCL (stocking class).
# Called only from FORTYP.

# ---------------------------------------------------------------------------
# TAB2(36,2): stocking equation coefficients [b0, b1] for 36 equations
# TAB2(eq,1)=b0, TAB2(eq,2)=b1; stocking = b0 * DBH^b1 * TPA
# ---------------------------------------------------------------------------
const _STKVAL_TAB2 = Float32[
    0.00869f0  1.48f0;   # eq  1
    0.00454f0  1.73f0;   # eq  2
    0.01691f0  1.05f0;   # eq  3
    0.00946f0  1.59f0;   # eq  4
    0.00422f0  1.70f0;   # eq  5
    0.00509f0  1.81f0;   # eq  6
    0.00458f0  1.91f0;   # eq  7
    0.00335f0  1.73f0;   # eq  8
    0.01367f0  1.44f0;   # eq  9
    0.00250f0  2.00f0;   # eq 10
    0.00609f0  1.67f0;   # eq 11
    0.00914f0  1.67f0;   # eq 12
    0.00900f0  1.51f0;   # eq 13
    0.00680f0  1.72f0;   # eq 14
    0.00769f0  1.54f0;   # eq 15
    0.00433f0  1.80f0;   # eq 16
    0.00313f0  2.11f0;   # eq 17
    0.00427f0  1.67f0;   # eq 18
    0.00333f0  1.68f0;   # eq 19
    0.00000f0  1.00f0;   # eq 20
    0.00000f0  1.00f0;   # eq 21
    0.00000f0  1.00f0;   # eq 22
    0.00000f0  1.00f0;   # eq 23
    0.00000f0  1.00f0;   # eq 24
    0.01105f0  1.53f0;   # eq 25
    0.01671f0  1.41f0;   # eq 26
    0.00694f0  1.86f0;   # eq 27
    0.00635f0  1.89f0;   # eq 28
    0.01119f0  1.63f0;   # eq 29
    0.01546f0  1.50f0;   # eq 30
    0.00429f0  1.87f0;   # eq 31
    0.01429f0  1.46f0;   # eq 32
    0.02197f0  1.13f0;   # eq 33
    0.00000f0  1.00f0;   # eq 34
    0.00442f0  2.02f0;   # eq 35
    0.00688f0  1.86f0;   # eq 36
]

# ---------------------------------------------------------------------------
# TAB3(1000,2): per-FIA-species-code lookup
#   col 1: ITG group number (0 = not assigned)
#   col 2: stocking equation number (0 = use default)
# Stored as vectors indexed [fia] for each column.
# ---------------------------------------------------------------------------
const _STKVAL_TAB3_COL1 = Int32[
    # indices 1..100
    0,0,0,0,0,0,0,0,0,55,
    1,55,0,2,2,55,3,4,4,5,
    5,7,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,
    8,9,59,0,0,0,0,0,0,12,
    12,12,12,12,12,0,64,161,161,161,
    161,161,161,38,161,63,64,64,161,70,
    65,40,13,0,0,0,0,0,0,0,
    10,0,0,0,0,0,0,0,0,16,
    70,40,14,16,17,15,58,18,16,42,
    # indices 101..200
    19,20,21,20,41,162,44,23,24,45,
    46,22,25,22,47,36,27,22,28,6,
    48,26,49,29,42,50,163,51,53,71,
    52,54,162,162,26,70,22,22,22,162,
    22,20,162,72,70,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,
    # indices 201..300
    30,31,0,0,0,0,0,0,0,0,
    32,33,0,0,0,0,0,0,0,0,
    61,61,61,0,0,0,0,0,0,0,
    40,40,0,0,0,0,0,0,0,60,
    60,11,0,0,0,0,0,0,0,0,
    40,40,0,0,0,0,0,0,0,66,
    66,66,34,35,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,170,160,
    # indices 301..400
    0,0,0,0,0,0,0,0,0,152,
    151,130,208,96,152,95,97,96,152,152,
    159,159,159,159,159,0,0,0,0,153,
    153,153,153,153,153,153,153,0,0,0,
    151,0,0,0,153,153,0,0,0,153,
    131,153,153,0,146,152,0,0,0,0,
    132,132,132,0,0,0,152,0,0,98,
    98,98,129,151,99,99,99,99,99,0,
    151,0,0,0,0,0,0,0,0,0,
    152,0,0,0,0,0,0,0,0,92,
    # indices 401..500
    90,92,92,91,90,92,92,92,92,92,
    0,0,0,0,0,0,0,0,0,0,
    152,152,152,0,0,0,0,0,0,133,
    133,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,152,
    152,152,0,0,0,0,0,0,0,115,
    100,115,115,0,0,0,0,0,0,0,
    152,0,0,0,156,156,156,156,156,0,
    153,0,0,0,0,0,0,0,0,153,
    153,153,0,0,0,0,0,0,0,101,
    # indices 501..600
    101,101,0,0,0,0,0,0,0,148,
    0,0,0,0,0,0,0,0,0,0,
    93,0,0,0,0,0,0,0,0,0,
    102,0,0,0,0,0,0,0,0,153,
    103,135,104,105,153,153,153,153,153,0,
    151,101,0,0,127,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,
    101,0,0,0,0,0,0,0,0,153,
    0,0,0,0,0,0,0,0,0,0,
    106,0,0,0,0,0,0,0,0,153,
    # indices 601..700
    107,108,153,153,153,153,0,0,0,0,
    109,0,0,0,0,0,0,0,0,0,
    110,0,0,0,0,0,0,0,0,0,
    136,0,0,0,0,0,0,0,0,0,
    101,0,0,0,0,0,0,0,0,152,
    152,152,111,152,152,152,152,152,0,152,
    152,152,152,152,152,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,152,
    152,152,152,152,0,0,0,0,0,113,
    112,151,113,114,0,0,0,0,0,0,
    # indices 701..800
    152,152,0,0,0,0,0,0,0,0,
    152,144,0,0,0,0,0,0,0,0,
    127,151,0,0,0,0,0,0,0,153,
    116,153,0,0,0,0,0,0,0,118,
    117,118,119,118,118,119,137,118,118,0,
    0,118,0,0,157,157,157,157,0,152,
    152,121,152,152,152,152,0,152,0,0,
    0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,158,
    # indices 801..900
    138,81,210,151,142,82,134,89,86,210,
    210,88,87,158,140,89,202,139,89,201,
    158,128,83,206,87,207,204,143,210,205,
    125,84,85,87,86,87,120,203,142,86,
    89,89,210,0,0,0,0,0,0,210,
    152,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,152,
    # indices 901..1000
    122,160,0,0,0,0,0,0,0,0,
    147,0,0,0,0,0,0,0,158,123,
    123,123,123,123,0,0,123,0,123,0,
    93,0,0,0,152,152,152,152,152,0,
    0,0,0,0,0,0,0,0,0,124,
    124,124,124,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,152,
    209,94,209,146,94,152,94,0,0,0,
    141,0,0,0,0,0,0,0,149,160,
    153,145,146,146,146,153,153,180,190,0,
]

const _STKVAL_TAB3_COL2 = Int32[
    # indices 1..100
    0,0,0,0,0,0,0,0,0,1,
    18,1,0,18,15,1,18,1,1,18,
    18,18,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,
    18,18,16,0,0,0,0,0,0,10,
    10,10,10,10,10,0,4,10,10,3,
    3,10,10,10,10,10,4,4,10,1,
    1,2,2,0,0,0,0,0,0,0,
    18,0,0,0,0,0,0,0,0,1,
    1,18,1,1,3,1,1,18,1,11,
    # indices 101..200
    10,10,8,8,4,10,4,5,10,6,
    7,10,10,10,4,10,10,10,8,10,
    9,10,4,10,11,4,10,12,13,4,
    14,4,10,10,10,11,10,10,10,10,
    10,10,10,4,4,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,
    # indices 201..300
    15,15,0,0,0,0,0,0,0,0,
    19,19,0,0,0,0,0,0,0,0,
    31,31,31,0,0,0,0,0,0,0,
    18,18,0,0,0,0,0,0,0,16,
    16,18,0,0,0,0,0,0,0,0,
    18,18,0,0,0,0,0,0,0,17,
    17,17,18,18,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,13,0,25,
    # indices 301..400
    0,0,0,0,0,0,0,0,0,25,
    25,25,36,27,27,25,25,27,25,25,
    10,10,10,10,10,0,0,0,0,27,
    27,27,27,27,27,27,27,0,0,0,
    25,0,0,0,36,36,0,0,0,26,
    26,26,26,0,26,25,0,0,0,0,
    29,29,29,0,0,0,25,0,0,27,
    27,27,28,28,28,28,28,28,28,0,
    25,0,0,0,0,0,0,0,0,0,
    25,0,0,0,0,0,0,0,0,29,
    # indices 401..500
    29,29,29,29,29,29,29,29,29,29,
    0,0,0,0,0,0,0,0,0,0,
    25,29,29,0,0,0,0,0,0,29,
    29,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,27,
    27,27,0,0,0,0,0,0,0,36,
    36,36,36,0,0,0,0,0,0,0,
    25,0,0,0,10,33,33,33,33,0,
    25,0,0,0,0,0,0,0,0,25,
    25,26,0,0,0,0,0,0,0,29,
    # indices 501..600
    29,29,0,0,0,0,0,0,0,15,
    0,0,0,0,0,0,0,0,0,0,
    29,0,0,0,0,0,0,0,0,0,
    27,0,0,0,0,0,0,0,0,33,
    33,33,33,36,33,33,33,33,33,0,
    25,27,0,0,25,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,
    25,0,0,0,0,0,0,0,0,25,
    0,0,0,0,0,0,0,0,0,0,
    25,0,0,0,0,0,0,0,0,30,
    # indices 601..700
    30,30,30,30,30,30,0,0,0,0,
    31,0,0,0,0,0,0,0,0,0,
    33,0,0,0,0,0,0,0,0,0,
    25,0,0,0,0,0,0,0,0,0,
    29,0,0,0,0,0,0,0,0,33,
    33,33,25,33,33,33,33,33,0,29,
    29,29,29,29,29,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,25,
    25,25,25,25,0,0,0,0,0,31,
    31,31,31,31,0,0,0,0,0,0,
    # indices 701..800
    25,25,0,0,0,0,0,0,0,0,
    25,27,0,0,0,0,0,0,0,0,
    33,33,0,0,0,0,0,0,0,36,
    36,36,0,0,0,0,0,0,0,36,
    32,36,32,36,36,32,36,36,36,0,
    0,36,0,0,10,10,10,10,0,25,
    25,33,25,25,25,25,0,25,0,0,
    0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,10,
    # indices 801..900
    29,29,10,29,29,29,29,29,29,10,
    10,29,29,10,29,29,29,29,29,29,
    25,29,10,29,29,10,29,29,10,29,
    29,29,29,29,29,29,29,29,29,29,
    29,29,10,0,0,0,0,0,0,10,
    25,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,29,
    # indices 901..1000
    29,10,0,0,0,0,0,0,0,0,
    29,0,0,0,0,0,0,0,25,25,
    25,25,25,25,0,0,25,0,25,0,
    29,0,0,0,25,25,25,25,25,0,
    0,0,0,0,0,0,0,0,0,35,
    35,35,35,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,36,
    36,36,36,36,36,36,36,0,0,0,
    29,0,0,0,0,0,0,0,25,10,
    25,1,33,25,25,25,25,25,25,0,
]

# Mutable copy for SELECT CASE override for western variants
const _STKVAL_TAB3_COL2_MUT = copy(_STKVAL_TAB3_COL2)

function _stkval_init_tab3!()
    # SN/CS/LS/NE/ON: no change; western variants get different defaults
    if !(VARACD ∈ ("SN","CS","LS","NE","ON"))
        _STKVAL_TAB3_COL2_MUT[299] = Int32(8)
        _STKVAL_TAB3_COL2_MUT[998] = Int32(26)
        _STKVAL_TAB3_COL2_MUT[999] = Int32(26)
    end
end

function STKVAL(s::AbstractVector{Float32})
    # Adjust TAB3 for variant on first call (cheap guard)
    _stkval_init_tab3!()

    debug = DBCHK(false, "STKVAL", Int32(6), ICYC)
    if debug
        @printf(io_units[Int(JOSTND)], " ENTERING SUBROUTINE STKVAL  CYCLE =%5d ITRN= %5d\n", ICYC, ITRN)
    end

    dmax_loc = Float32(0)
    ss = zeros(Float32, MAXSP)
    totstk = Float32(0); ttst51 = Float32(0); ttst52 = Float32(0)
    totst5 = Float32(0); totst3 = Float32(0); totst1 = Float32(0)
    szcl   = zeros(Float32, 3)
    global ISZCL = Int32(0); global ISTCL = Int32(0)

    if ITRN <= 0; return nothing; end

    # Find max DBH in stand
    dmxstd = Float32(0); dmxss = Float32(0)
    for ispc in 1:MAXSP
        i1 = ISCT[ispc,1]; if i1 == 0; continue; end
        i2 = ISCT[ispc,2]
        for i3 in i1:i2
            i = Int(IND1[i3])
            imc_v = Int(IMC[i])
            if imc_v >= 6 && imc_v <= 9; continue; end
            d = DBH[i]
            if d > dmxstd; dmxstd = d; end
            if d < Float32(5) && d > dmxss; dmxss = d; end
        end
    end

    function _get_fia_and_coeffs(ispc::Int)
        fs = strip(FIAJSP[ispc])
        ifia = isempty(fs) ? 998 : (n = tryparse(Int, fs); isnothing(n) ? 998 : n)
        if ifia == 0; ifia = 999; end
        if ifia < 1 || ifia > 1000; ifia = 999; end
        eq = Int(_STKVAL_TAB3_COL2_MUT[ifia])
        if eq < 1 || eq > 36
            eq = Int(_STKVAL_TAB3_COL2_MUT[999])
        end
        b0 = _STKVAL_TAB2[eq, 1]
        b1 = _STKVAL_TAB2[eq, 2]
        if b0 == Float32(0) || b1 == Float32(0)
            eq2 = Int(_STKVAL_TAB3_COL2_MUT[999])
            b0 = _STKVAL_TAB2[eq2, 1]; b1 = _STKVAL_TAB2[eq2, 2]
        end
        return ifia, b0, b1
    end

    # Step 1: initial stocking for trees >= 5 in (TTST51)
    stktr1 = Float32(0)
    for ispc in 1:MAXSP
        i1 = ISCT[ispc,1]; if i1 == 0; continue; end
        i2 = ISCT[ispc,2]
        _, b0, b1 = _get_fia_and_coeffs(ispc)
        for i3 in i1:i2
            i = Int(IND1[i3])
            imc_v = Int(IMC[i]); if imc_v >= 6 && imc_v <= 9; continue; end
            d = DBH[i]
            if d > Float32(0)
                stktr1 = b0 * d^b1 * PROB[i]
                if d >= Float32(5); ttst51 += stktr1; end
            end
        end
    end

    if debug
        @printf(io_units[Int(JOSTND)], " TTST51,STKTR1,PROB(1)= %g %g %g\n", ttst51, stktr1, PROB[1])
    end

    # Step 2: adjust for competitive position
    stktr2 = Float32(0)
    for ispc in 1:MAXSP
        i1 = ISCT[ispc,1]; if i1 == 0; continue; end
        i2 = ISCT[ispc,2]
        ifia, b0, b1 = _get_fia_and_coeffs(ispc)
        for i3 in i1:i2
            i = Int(IND1[i3])
            imc_v = Int(IMC[i]); if imc_v >= 6 && imc_v <= 9; continue; end
            d = DBH[i]
            if d > Float32(0)
                cf = if d >= Float32(5)
                    Float32(1)
                else
                    dmax_loc = ttst51 >= Float32(10) ? Float32(5) : dmxss
                    dmax_loc > Float32(0) ? d / dmax_loc : Float32(0)
                end
                stktr2 = b0 * d^b1 * PROB[i] * cf
                if d >= Float32(5); ttst52 += stktr2; totst5 += stktr2; end
                if d > Float32(0.1) && d < Float32(5); totst3 += stktr2; end
                if d == Float32(0.1); totst1 += stktr2; end
                totstk += stktr2
                ss[ispc] += stktr2
            end
        end
    end

    if debug
        @printf(io_units[Int(JOSTND)], " IN STKVAL_1: DMXSS,DMAX,CF,TTST51,TOTST5,TOTSTK - %g %g %g %g %g %g\n",
            dmxss, dmax_loc, Float32(0), ttst51, totst5, totstk)
    end

    # Step 3&4: "future stand" correction when < 20 stocking from large trees
    if ttst52 < Float32(20.0)
        fill!(ss, Float32(0)); totstk=Float32(0); totst5=Float32(0); totst3=Float32(0); totst1=Float32(0)
        for ispc in 1:MAXSP
            i1 = ISCT[ispc,1]; if i1 == 0; continue; end
            i2 = ISCT[ispc,2]
            ifia, b0, b1 = _get_fia_and_coeffs(ispc)
            for i3 in i1:i2
                i = Int(IND1[i3])
                imc_v = Int(IMC[i]); if imc_v >= 6 && imc_v <= 9; continue; end
                d = DBH[i]
                if d > Float32(0)
                    cf = if d >= Float32(5)
                        Float32(1)
                    else
                        dmax_loc = ttst51 >= Float32(10) ? Float32(5) : dmxss
                        dmax_loc > Float32(0) ? d / dmax_loc : Float32(0)
                    end
                    d_adj = d < Float32(5) ? Float32(5) : d
                    stktr2 = b0 * d_adj^b1 * PROB[i] * cf
                    d_orig = DBH[i]
                    if d_orig >= Float32(5); totst5 += stktr2; end
                    if d_orig > Float32(0.1) && d_orig < Float32(5); totst3 += stktr2; end
                    if d_orig == Float32(0.1); totst1 += stktr2; end
                    totstk += stktr2; ss[ispc] += stktr2
                end
            end
        end
    end

    if debug
        @printf(io_units[Int(JOSTND)], " IN STKVAL_2: DMXSS,DMAX,CF,TTST51,TOTST5,TOTSTK - %g %g %g %g %g %g\n",
            dmxss, dmax_loc, Float32(0), ttst51, totst5, totstk)
    end

    # Step 5: proportion adjustments (PRG, PRA, PRE)
    ug = Float32(120); gi = totst5; ai = totst3; ei_v = totst1
    ua = max(ug - gi, Float32(0)); ue = max(ua - ai, Float32(0))
    prg = ug > Float32(0) && gi > Float32(0) ? min(ug/gi, Float32(1)) : Float32(1)
    pra = ua > Float32(0) && ai > Float32(0) ? min(ua/ai, Float32(1)) : Float32(1)
    pre = ue > Float32(0) && ei_v > Float32(0) ? min(ue/ei_v, Float32(1)) : Float32(1)

    fill!(ss, Float32(0)); totstk=Float32(0); totst5=Float32(0); totst3=Float32(0); totst1=Float32(0)
    for ispc in 1:MAXSP
        i1 = ISCT[ispc,1]; if i1 == 0; continue; end
        i2 = ISCT[ispc,2]
        ifia, b0, b1 = _get_fia_and_coeffs(ispc)
        for i3 in i1:i2
            i = Int(IND1[i3])
            imc_v = Int(IMC[i])
            if imc_v >= 6 && imc_v <= 9; continue; end
            d = DBH[i]
            if d > Float32(0)
                cf = if d >= Float32(5)
                    Float32(1)
                else
                    dmax_loc = ttst51 >= Float32(10) ? Float32(5) : dmxss
                    dmax_loc > Float32(0) ? d / dmax_loc : Float32(0)
                end
                d_adj = (ttst52 < Float32(20) && d < Float32(5)) ? Float32(5) : d
                stktr2 = b0 * d_adj^b1 * PROB[i] * cf
                d_orig = DBH[i]
                if d_orig >= Float32(5); totst5 += stktr2; end
                if d_orig > Float32(0.1) && d_orig < Float32(5); totst3 += stktr2; end
                if d_orig == Float32(0.1); totst1 += stktr2; end
                totstk += stktr2; ss[ispc] += stktr2

                # size class accumulation
                if d_orig < Float32(5)
                    szcl[1] += stktr2
                elseif ifia < 300 && d_orig >= Float32(5) && d_orig < Float32(9)
                    szcl[2] += stktr2
                elseif ifia >= 300 && d_orig >= Float32(5) && d_orig < Float32(11)
                    szcl[2] += stktr2
                elseif ifia < 300 && d_orig >= Float32(9)
                    szcl[3] += stktr2
                elseif ifia >= 300 && d_orig >= Float32(11)
                    szcl[3] += stktr2
                end
            end
        end
    end

    if debug
        @printf(io_units[Int(JOSTND)], " IN STKVAL_3: DMXSS,DMAX,TTST51,TTST52,TOTST5,TOTSTK - %g %g %g %g %g %g\n",
            dmxss, dmax_loc, ttst51, ttst52, totst5, totstk)
    end

    # Determine size class
    global ISZCL = if totstk < Float32(10)
        Int32(5)
    elseif szcl[1] > totstk * Float32(0.50)
        Int32(3)
    elseif szcl[2] > szcl[3]
        Int32(2)
    else
        Int32(1)
    end

    # Determine stocking class
    global ISTCL = if totstk > Float32(100)
        Int32(1)
    elseif totstk >= Float32(60)
        Int32(2)
    elseif totstk >= Float32(35)
        Int32(3)
    elseif totstk >= Float32(10)
        Int32(4)
    else
        Int32(5)
    end

    # Load S array by ITG group
    fill!(s, Float32(0))
    for is in 1:210
        for ispc in 1:MAXSP
            fs = strip(FIAJSP[ispc]); if isempty(fs); continue; end
            ifia = (n = tryparse(Int, fs); isnothing(n) ? 0 : n)
            if ifia < 1 || ifia > 1000; continue; end
            if Int(_STKVAL_TAB3_COL1[ifia]) == is
                s[is] += ss[ispc]
                if debug
                    @printf(io_units[Int(JOSTND)], " IN STKVAL_LOAD, IS,S(IS)= %d %g\n", is, s[is])
                end
            end
        end
    end

    if debug
        @printf(io_units[Int(JOSTND)], " IN STKVAL, TOTST5= %g\n", totst5)
        @printf(io_units[Int(JOSTND)], " ISZCL,ISTCL= %d %d\n", ISZCL, ISTCL)
    end
    return nothing
end
