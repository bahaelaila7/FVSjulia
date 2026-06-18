# sn/crown.jl — CROWN: crown ratio dubbing and change; CRCONS: load coefficients
# Translated from: bin/FVSsn_buildDir/crown.f (628 lines)
#
# Module-level DATA arrays (Fortran SAVE'd via DATA in ENTRY CRCONS):
#   _CROWN_MCREQN(6,MAXSP) — mean crown ratio equation type+coefficients
#   _CROWN_WEIBUL(5,MAXSP) — Weibull distribution parameters (row 5 unused)
#   _CROWN_CRNMLT(MAXSP)   — crown multiplier per species (default 1.0, mutable)
#   _CROWN_ICFLG(MAXSP)    — flag: reset CRNMLT after LSTART (default 0, mutable)
#   _CROWN_DLOW(MAXSP)     — DBH lower bound for CRNMLT (default 0.0, mutable)
#   _CROWN_DHI(MAXSP)      — DBH upper bound for CRNMLT (default 99.0, mutable)
#
# CROWN: computes crown ratio for all live trees; dubs dead tree crowns via DUBSCR
# CRCONS: no-op in Julia (DATA already set at module load); resets mutable defaults

# ---------------------------------------------------------------------------
# Mean crown ratio equation coefficients — MCREQN(6, MAXSP)
# Row 1: equation type (1=Hoerl, 2=Power, 3=Linear, 4=Log, 5=Inverse)
# Row 2: a coeff; Row 3: c coeff; Row 4: b coeff; Row 5: b_log; Row 6: b_inv
# Stored column-major (6 rows × MAXSP cols) matching Fortran MCREQN(6,MAXSP).
# ---------------------------------------------------------------------------
const _CROWN_MCREQN_RAW = Float32[
    # J= 1..15
    3,  63.51,  -0.09,   0.00,    0.00,    0.00,
    3,  67.64,  -2.25,   0.00,    0.00,    0.00,
    3,  63.51,  -0.09,   0.00,    0.00,    0.00,
    4,  54.0462, 0.00,   0.00, -18.2118,   0.00,
    4,  47.7297, 0.00,   0.00, -16.352,    0.00,
    4,  42.8255, 0.00,   0.00, -15.0135,   0.00,
    2,   4.17,   0.00,  -0.23,    0.00,    0.00,
    4,  42.84,   0.00,   0.00,   -5.62,    0.00,
    4,  45.8231, 0.00,   0.00, -13.8999,   0.00,
    1,   4.3546, 0.0163,-0.5034,  0.00,    0.00,
    1,   3.8904, 0.0478,-0.3565,  0.00,    0.00,
    3,  51.8,   -0.8,    0.00,    0.00,    0.00,
    1,   3.8284, 0.0172,-0.2234,  0.00,    0.00,
    1,   4.1136, 0.007, -0.331,   0.00,    0.00,
    4,  48.2413, 0.00,   0.00, -10.1014,   0.00,
    # J= 16..30
    4,  36.0855, 0.00,   0.00,  -5.4737,   0.00,
    3,  63.51,  -0.09,   0.00,    0.00,    0.00,
    4,  53.1867, 0.00,   0.00,  -9.4122,   0.00,
    4,  61.9643, 0.00,   0.00, -22.3363,   0.00,
    4,  46.1653, 0.00,   0.00,  -6.088,    0.00,
    3,  42.98,   0.55,   0.00,    0.00,    0.00,
    3,  48.2,   -0.01,   0.00,    0.00,    0.00,
    3,  42.13,  -0.1,    0.00,    0.00,    0.00,
    1,   3.7275, 0.0282,-0.1124,  0.00,    0.00,
    1,   3.8785, 0.0171,-0.1749,  0.00,    0.00,
    1,   3.9904, 0.0171,-0.1496,  0.00,    0.00,
    1,   3.9939, 0.0238,-0.2117,  0.00,    0.00,
    4,  48.03,   0.00,   0.00, -13.21,     0.00,
    4,  50.8266, 0.00,   0.00, -14.5261,   0.00,
    4,  44.5839, 0.00,   0.00, -14.0874,   0.00,
    # J= 31..45
    4,  51.8467, 0.00,   0.00, -14.1876,   0.00,
    1,   3.8415, 0.0297,-0.2879,  0.00,    0.00,
    4,  59.09,   0.00,   0.00,  -4.99,     0.00,
    3,  38.26,  -0.77,   0.00,    0.00,    0.00,
    1,   3.7881,-0.0055,-0.0634,  0.00,    0.00,
    3,  35.49,   0.00,   0.00,    0.00,    0.00,
    3,  35.49,   0.00,   0.00,    0.00,    0.00,
    2,   3.82,   0.00,  -0.1,     0.00,    0.00,
    3,  37.83,  -0.15,   0.00,    0.00,    0.00,
    1,   4.4653, 0.107, -0.834,   0.00,    0.00,
    3,  52.05,  -0.11,   0.00,    0.00,    0.00,
    2,   3.91,   0.00,  -0.12,    0.00,    0.00,
    2,   3.91,   0.00,  -0.12,    0.00,    0.00,
    1,   3.8153, 0.0055,-0.0964,  0.00,    0.00,
    2,   3.87,   0.00,  -0.07,    0.00,    0.00,
    # J= 46..60
    3,  44.71,   0.4,    0.00,    0.00,    0.00,
    3,  42.15,  -0.11,   0.00,    0.00,    0.00,
    3,  44.71,   0.4,    0.00,    0.00,    0.00,
    3,  36.5,   -0.23,   0.00,    0.00,    0.00,
    3,  44.71,   0.4,    0.00,    0.00,    0.00,
    3,  55.48,  -2.38,   0.00,    0.00,    0.00,
    3,  42.32,  -1.08,   0.00,    0.00,    0.00,
    3,  36.02,  -0.3,    0.00,    0.00,    0.00,
    3,  41.01,  -0.21,   0.00,    0.00,    0.00,
    3,  41.379, -0.8012, 0.00,    0.00,    0.00,
    4,  52.7207, 0.00,   0.00, -11.484,    0.00,
    3,  38.71,  -0.1,    0.00,    0.00,    0.00,
    3,  38.03,  -0.09,   0.00,    0.00,    0.00,
    1,   3.9839,-0.0248,-0.0462,  0.00,    0.00,
    4,  48.03,   0.00,   0.00, -13.21,     0.00,
    # J= 61..75
    4,  48.03,   0.00,   0.00, -13.21,     0.00,
    3,  45.06,  -0.96,   0.00,    0.00,    0.00,
    2,   4.05,   0.00,  -0.12,    0.00,    0.00,
    4,  51.7,    0.00,   0.00,  -9.65,     0.00,
    2,   3.92,   0.00,  -0.09,    0.00,    0.00,
    1,   3.9112, 0.0147,-0.1697,  0.00,    0.00,
    2,   3.95,   0.00,  -0.02,    0.00,    0.00,
    4,  54.36,   0.00,   0.00, -11.3181,   0.00,
    4,  57.82,   0.00,   0.00, -18.45,     0.00,
    4,  56.42,   0.00,   0.00, -14.13,     0.00,
    1,   3.9344, 0.0043,-0.0845,  0.00,    0.00,
    1,   4.1233,-0.0142,-0.1279,  0.00,    0.00,
    1,   3.9116, 0.0509,-0.2657,  0.00,    0.00,
    4,  54.53,   0.00,   0.00, -14.7,      0.00,
    2,   3.9,    0.00,  -0.07,    0.00,    0.00,
    # J= 76..90
    3,  46.72,  -0.85,   0.00,    0.00,    0.00,
    4,  44.34,   0.00,   0.00,  -5.23,     0.00,
    2,   4.17,   0.00,  -0.18,    0.00,    0.00,
    3,  49.27,  -0.72,   0.00,    0.00,    0.00,
    4,  49.022,  0.00,   0.00, -22.5732,   0.00,
    3,  44.5295,-1.0053, 0.00,    0.00,    0.00,
    3,  38.85,  -0.99,   0.00,    0.00,    0.00,
    5,   0.0283, 0.00,   0.00,    0.00,  -0.012,
    2,   3.68,   0.00,  -0.02,    0.00,    0.00,
    4,  43.64,   0.00,   0.00, -10.03,     0.00,
    1,   3.7366, 0.0151,-0.0896,  0.00,    0.00,
    1,   3.8487, 0.0276,-0.2005,  0.00,    0.00,
    3,  67.64,  -2.25,   0.00,    0.00,    0.00,
    1,   3.78,  -0.02,  -0.02,    0.00,    0.00,
    2,   3.93,   0.00,  -0.15,    0.00,    0.00,
]

# ---------------------------------------------------------------------------
# Weibull CDF parameters — stored as (5, MAXSP); row 5 is unused
# Row 1: A; Row 2: B0; Row 3: B1 (B = B0 + B1*MCR); Row 4: C
# ---------------------------------------------------------------------------
const _CROWN_WEIBUL_RAW = Float32[
    # J= 1..15 (4 values per species, row 5 left zero)
     4.0659,  -6.8708, 1.0510, 4.1741,
     2.4435, -32.4837, 1.6503, 2.6518,
     4.0659,  -6.8708, 1.0510, 4.1741,
     4.3780,  -5.0254, 0.9620, 2.4758,
     4.6721,  -3.9456, 1.0509, 3.0228,
     3.8940,  -4.7342, 0.9786, 2.9082,
     5.0000, -10.1125, 1.0734, 3.3218,
     3.9771,  14.3941, 0.5189, 3.7531,
     3.9190,   1.2933, 0.7986, 2.9202,
     3.9190,   1.2933, 0.7986, 2.9202,
     4.3300, -34.2606, 1.7823, 3.0554,
     4.6496, -11.4277, 1.1343, 2.9405,
     4.9701, -14.6680, 1.3196, 2.8517,
     5.0000, -10.2832, 1.1019, 2.4693,
     5.0000,  -9.8322, 1.1062, 2.8512,
    # J= 16..30
     4.9986,  -9.6939, 1.0740, 2.3667,
     4.0659,  -6.8708, 1.0510, 4.1741,
     5.0000, -18.6340, 1.2622, 3.6407,
     5.0000, -18.6340, 1.2622, 3.6407,
     4.7322, -24.2740, 1.4587, 2.9951,
     5.0000, -18.6340, 1.2622, 3.6407,
     4.6903, -19.5613, 1.2928, 3.3715,
     5.0000, -18.6340, 1.2622, 3.6407,
     4.1939,   1.2500, 0.8795, 3.1500,
     4.1939,   1.2500, 0.8795, 3.1500,
     4.5640,   0.9693, 0.9093, 3.0540,
     5.0000, -29.1096, 1.5626, 3.5310,
     4.8371, -14.3180, 1.2060, 3.7345,
     4.5671, -49.1736, 2.1311, 2.9883,
     5.0000,  15.0407, 0.6546, 3.0344,
    # J= 31..45
     4.7093,  -9.6999, 1.1020, 2.7391,
     4.7093,  -9.6999, 1.1020, 2.7391,
     4.6965, -14.3809, 1.2016, 3.5571,
     4.0098, -12.7054, 1.2224, 2.7400,
     4.8776, -11.6617, 1.1668, 3.8475,
     4.0098, -12.7054, 1.2224, 2.7400,
     4.5987, -16.9647, 1.3925, 3.3601,
     4.9245, -13.3135, 1.2765, 2.8455,
     4.1992, -16.8789, 1.2949, 2.7697,
     4.7093,  -9.6999, 1.1020, 2.7391,
     4.6965, -14.3809, 1.2016, 3.5571,
     4.2967, -17.7977, 1.3186, 3.0386,
     4.2967, -17.7977, 1.3186, 3.0386,
     4.6350, -39.7348, 1.9132, 3.0574,
     4.9948, -11.1090, 1.1089, 3.8822,
    # J= 46..60
     5.0000,   9.2520, 0.7899, 3.2166,
     4.9829,  -5.2479, 0.9552, 3.8219,
     5.0000,   9.2520, 0.7899, 3.2166,
     4.2299, -32.4970, 1.7316, 2.7902,
     5.0000,   9.2520, 0.7899, 3.2166,
     4.2932,  -7.1512, 1.0504, 2.7738,
     4.8677, -22.5591, 1.4240, 2.8686,
     5.0000, -15.1643, 1.2524, 3.1645,
     4.6134, -42.6970, 1.9983, 3.0081,
     4.8257,  -7.1092, 1.0128, 2.7232,
     5.0000,  15.0407, 0.6546, 3.0344,
     4.8677, -22.5591, 1.4240, 2.8686,
     3.5122,  22.2798, 0.3081, 2.7868,
     4.5640, -30.7592, 1.6192, 3.2836,
     4.8371, -14.3180, 1.2060, 3.7345,
    # J= 61..75
     4.8371, -14.3180, 1.2060, 3.7345,
     4.2932,  -7.1512, 1.0504, 2.7738,
     5.0000, -16.0927, 1.2319, 3.5016,
     5.0000,  -4.6551, 0.9593, 3.8340,
     5.0000, -26.7842, 1.6030, 3.5160,
     5.0000,  -4.2993, 1.0761, 3.5922,
     4.1406,  13.6950, 0.6895, 3.0427,
     4.6329,  -1.2977, 0.9438, 3.2263,
     5.0000,  11.2401, 0.7081, 3.5258,
     4.1406,  13.6950, 0.6895, 3.0427,
     4.4764, -18.7445, 1.3539, 3.8384,
     5.0000,  -7.5332, 1.0257, 3.1662,
     5.0000, -50.1177, 2.1127, 3.5148,
     5.0000,  -9.7922, 1.0728, 3.6340,
     5.0000, -12.4107, 1.1363, 3.6430,
    # J= 76..90
     5.0000,   5.0414, 0.8032, 3.6764,
     4.7585, -83.4596, 3.0817, 3.4788,
     5.0000,  -6.5883, 1.0266, 3.5587,
     5.0000,  11.2401, 0.7081, 3.5258,
     3.5643, -10.5101, 1.2176, 2.2033,
     4.8547, -17.1135, 1.3108, 3.2431,
     4.9082, -11.2413, 1.1519, 2.4971,
     4.2656, -26.6773, 1.5580, 4.4024,
     5.0000,   1.1421, 0.9141, 3.0621,
     4.9367,   7.6678, 0.9105, 3.0303,
     5.0000,   1.1421, 0.9141, 3.0621,
     4.7375, -21.8810, 1.5340, 3.3558,
     2.4435, -32.4837, 1.6503, 2.6518,
     4.1374,  17.2956, 0.4987, 2.2670,
     4.9041,  -2.5097, 0.9225, 2.7628,
]

# Reshape MCREQN raw flat vector into 6×MAXSP matrix (column-major = Fortran order)
function _build_mcreqn()
    return reshape(_CROWN_MCREQN_RAW, 6, Int(MAXSP))
end
const _CROWN_MCREQN = _build_mcreqn()

# Build (5, MAXSP) matrix from raw 4-per-species data (row 5 = 0, unused)
function _build_weibul()
    w = zeros(Float32, 5, Int(MAXSP))
    for j in 1:Int(MAXSP)
        base = (j-1)*4
        w[1,j] = _CROWN_WEIBUL_RAW[base+1]
        w[2,j] = _CROWN_WEIBUL_RAW[base+2]
        w[3,j] = _CROWN_WEIBUL_RAW[base+3]
        w[4,j] = _CROWN_WEIBUL_RAW[base+4]
    end
    return w
end

const _CROWN_WEIBUL = _build_weibul()

# Mutable per-species arrays (modified by CRNMULT keyword)
_CROWN_CRNMLT = fill(Float32(1.0), Int(MAXSP))
_CROWN_ICFLG  = fill(Int32(0),     Int(MAXSP))
_CROWN_DLOW   = fill(Float32(0.0), Int(MAXSP))
_CROWN_DHI    = fill(Float32(99.0),Int(MAXSP))

const _CROWN_MYACTS = Int32[81]   # CRNMULT activity code

# ---------------------------------------------------------------------------
# CROWN: dub missing crown ratios and compute crown ratio changes
# ---------------------------------------------------------------------------
function CROWN()
    debug = DBCHK(false, "CROWN", Int32(5), ICYC)
    if debug
        @printf(io_units[Int32(JOSTND)], " ENTERING SUBROUTINE CROWN  CYCLE =%5d\n", ICYC)
    end

    # Local working arrays (no SAVE needed — initialized each call on LSTART)
    crnew = zeros(Float32, Int(MAXTRE))
    isort = zeros(Int32,   Int(MAXTRE))

    # Initialize crown variables to beginning-of-cycle values on LSTART
    if LSTART
        fill!(crnew, Float32(0))
        fill!(isort, Int32(0))
    end

    # Dub crowns on dead trees if no live trees in inventory
    if (ITRN <= 0) && (IREC2 < Int(MAXTP1))
        @goto label_74
    end

    if ITRN == 0
        return nothing
    elseif TPROB <= Float32(0)
        for i in 1:Int(ITRN)
            ICR[i] = abs(ICR[i])
        end
        return nothing
    end

    # Process CRNMULT keyword (activity 81)
    ntodo = OPFIND(Int32(1), _CROWN_MYACTS)
    if ntodo > Int32(0)
        prm = zeros(Float32, 5)
        for i in 1:Int(ntodo)
            iactk, idt, np = OPGET(i, 5, prm)
            OPDONE(i, idt)
            ispcc = Int(prm[1])
            if ispcc < 0
                igrp = -ispcc
                iulim = Int(ISPGRP[igrp, 1]) + 1
                for ig in 2:iulim
                    igsp = Int(ISPGRP[igrp, ig])
                    if prm[2] >= Float32(0); _CROWN_CRNMLT[igsp] = prm[2]; end
                    if prm[3] > Float32(0);  _CROWN_DLOW[igsp]   = prm[3]; end
                    if prm[4] > Float32(0);  _CROWN_DHI[igsp]    = prm[4]; end
                    if prm[5] > Float32(0);  _CROWN_ICFLG[igsp]  = Int32(1); end
                end
            elseif ispcc == 0
                for k in 1:Int(MAXSP)
                    if prm[2] >= Float32(0); _CROWN_CRNMLT[k] = prm[2]; end
                    if prm[3] > Float32(0);  _CROWN_DLOW[k]   = prm[3]; end
                    if prm[4] > Float32(0);  _CROWN_DHI[k]    = prm[4]; end
                    if prm[5] > Float32(0);  _CROWN_ICFLG[k]  = Int32(1); end
                end
            else
                if prm[2] >= Float32(0); _CROWN_CRNMLT[ispcc] = prm[2]; end
                if prm[3] > Float32(0);  _CROWN_DLOW[ispcc]   = prm[3]; end
                if prm[4] > Float32(0);  _CROWN_DHI[ispcc]    = prm[4]; end
                if prm[5] > Float32(0);  _CROWN_ICFLG[ispcc]  = Int32(1); end
            end
        end
    end

    if debug
        @printf(io_units[Int32(JOSTND)], "\n IN CROWN 9024 ICYC,CRNMLT= %5d\n", ICYC)
        for k in 1:11:Int(MAXSP)
            endk = min(k+10, Int(MAXSP))
            for kk in k:endk
                @printf(io_units[Int32(JOSTND)], " %6.2f", _CROWN_CRNMLT[kk])
            end
            @printf(io_units[Int32(JOSTND)], "\n")
        end
    end

    # Build ISORT: diameter rank for each tree
    # IND(JJ) holds trees sorted by diameter; J1 = ITRN-JJ+1 so
    # IND(1) → rank ITRN, IND(ITRN) → rank 1
    for jj in 1:Int(ITRN)
        j1 = Int(ITRN) - jj + 1
        isort[Int(IND[jj])] = Int32(j1)
    end

    if debug
        @printf(io_units[Int32(JOSTND)], " IN CROWN 7900 ITRN,IND =%6d\n", ITRN)
        for jj in 1:Int(ITRN); @printf(io_units[Int32(JOSTND)], "%4d", IND[jj]); end
        @printf(io_units[Int32(JOSTND)], "\n")
        for jj in 1:Int(ITRN); @printf(io_units[Int32(JOSTND)], "%4d", isort[jj]); end
        @printf(io_units[Int32(JOSTND)], "\n")
    end

    # Species loop
    for ispc in 1:Int(MAXSP)
        i1 = Int(ISCT[ispc, 1])
        if i1 == 0; continue; end
        i2 = Int(ISCT[ispc, 2])

        # Relative SDI
        relsdi = if SDIDEF[ispc] > Float32(0)
            SDIAC / SDIDEF[ispc] * Float32(10)
        else
            Float32(6)
        end
        relsdi = clamp(relsdi, Float32(1), Float32(12))

        # Select mean crown ratio equation by type
        imcreq = Int(_CROWN_MCREQN[1, ispc])
        amcr = _CROWN_MCREQN[2, ispc]
        cmcr = _CROWN_MCREQN[3, ispc]
        bmcr = _CROWN_MCREQN[4, ispc]

        acrnew = if imcreq == 1       # Hoerl
            bmcr2 = _CROWN_MCREQN[4, ispc]
            exp(amcr + bmcr2*log(relsdi) + cmcr*relsdi)
        elseif imcreq == 2            # Power
            exp(amcr + bmcr*log(relsdi))
        elseif imcreq == 3            # Linear
            amcr + cmcr*relsdi
        elseif imcreq == 4            # Logarithmic
            b_log = _CROWN_MCREQN[5, ispc]
            amcr + b_log*log10(relsdi)
        elseif imcreq == 5            # Inverse/hyperbolic
            b_inv = _CROWN_MCREQN[6, ispc]
            relsdi / (amcr*relsdi + b_inv)
        else
            Float32(0)
        end

        # Weibull parameters
        a = _CROWN_WEIBUL[1, ispc]
        b = _CROWN_WEIBUL[2, ispc] + _CROWN_WEIBUL[3, ispc]*acrnew
        c = _CROWN_WEIBUL[4, ispc]
        if b < Float32(3); b = Float32(3); end
        if c < Float32(2); c = Float32(2); end

        if debug
            @printf(io_units[Int32(JOSTND)],
                    " IN CROWN 9001 ISPC,SDIAC,ORMSQD,RELSDI,ACRNEW,A,B,C,SDIDEF,IMCREQ =\n")
            @printf(io_units[Int32(JOSTND)],
                    " %5d%8.2f%8.4f%8.2f%8.2f%10.4f%10.4f%10.4f%10.4f%10d\n",
                    ispc, SDIAC, ORMSQD, relsdi, acrnew, a, b, c, SDIDEF[ispc], imcreq)
        end

        # Tree loop for this species
        for i3 in i1:i2
            i = Int(IND1[i3])

            # Skip if LSTART and crown already assigned
            if LSTART && ICR[i] > Int32(0); continue; end

            # If pest extension computed negative ICR, flip sign and skip
            if !LSTART && ICR[i] < Int32(0)
                ICR[i] = -ICR[i]
                if debug
                    @printf(io_units[Int32(JOSTND)],
                            " ICR(%4d) WAS CALCULATED ELSEWHERE AND IS %4d\n", i, ICR[i])
                end
                continue
            end

            d = DBH[i]

            # Compute percentile rank X
            scale = Float32(1) - Float32(0.00167) * (RELDEN - Float32(100))
            scale = clamp(scale, Float32(0.30), Float32(1))

            x = if DBH[i] > Float32(0)
                Float32(isort[i]) / Float32(ITRN) * scale
            else
                RANN() * scale
            end

            if debug
                @printf(io_units[Int32(JOSTND)], " IN CROWN ACRNEW, A,B,C%10.4f%10.4f%10.4f%10.4f\n",
                        acrnew, a, b, c)
            end

            x = clamp(x, Float32(0.05), Float32(0.95))
            crnew[i] = a + b * ((-log(Float32(1) - x))^(Float32(1)/c))

            if debug
                @printf(io_units[Int32(JOSTND)],
                        " IN CROWN 9002 WRITE I,X,CRNEW,ICR =%5d%10.5f%10.5f%5d\n",
                        i, x, crnew[i], ICR[i])
            end

            # Compute crown change (non-LSTART, existing crown only)
            if !LSTART && ICR[i] != Int32(0)
                chg     = crnew[i] - Float32(ICR[i])
                pdifpy  = chg / Float32(ICR[i]) / FINT
                if pdifpy > Float32(0.01)
                    chg = Float32(ICR[i]) * Float32(0.01) * FINT
                elseif pdifpy < Float32(-0.01)
                    chg = Float32(ICR[i]) * Float32(-0.01) * FINT
                end
                if debug
                    @printf(io_units[Int32(JOSTND)],
                            "\n  IN CROWN 9020 I,CRNEW,ICR,PDIFPY,CHG =%5d%10.3f%5d%10.3f%10.3f%10.3f\n",
                            i, crnew[i], ICR[i], pdifpy, chg)
                end
                if DBH[i] >= _CROWN_DLOW[ispc] && DBH[i] <= _CROWN_DHI[ispc]
                    crnew[i] = Float32(ICR[i]) + chg * _CROWN_CRNMLT[ispc]
                else
                    crnew[i] = Float32(ICR[i]) + chg
                end
            end

            icri = trunc(Int32, crnew[i] + Float32(0.5))

            if LSTART || ICR[i] == Int32(0)
                if DBH[i] >= _CROWN_DLOW[ispc] && DBH[i] <= _CROWN_DHI[ispc]
                    icri = trunc(Int32, Float32(icri) * _CROWN_CRNMLT[ispc])
                end
            end

            # Crown length checks (non-LSTART, existing crown)
            if !LSTART && ICR[i] != Int32(0)
                crln  = HT[i] * Float32(ICR[i]) / Float32(100)
                crmax = (crln + HTG[i]) / (HT[i] + HTG[i]) * Float32(100)
                if debug
                    @printf(io_units[Int32(JOSTND)],
                            " CRMAX=%10.2f CRLN=%10.2f ICRI=%10d I=%5d CRNEW=%10.2f CHG=      0.000\n",
                            crmax, crln, icri, i, crnew[i])
                end
                if Float32(icri) > crmax
                    icri = trunc(Int32, crmax + Float32(0.5))
                end
                if icri < Int32(10) && _CROWN_CRNMLT[ispc] == Float32(1)
                    icri = trunc(Int32, crmax + Float32(0.5))
                end
            end

            # Reduce crown for top-killed trees (LSTART only)
            if LSTART && ITRUNC[i] != Int32(0)
                hn   = Float32(NORMHT[i]) / Float32(100)
                hd   = hn - Float32(ITRUNC[i]) / Float32(100)
                cl   = (Float32(icri) / Float32(100)) * hn - hd
                icri = trunc(Int32, cl * Float32(100) / hn + Float32(0.5))
                if debug
                    @printf(io_units[Int32(JOSTND)],
                            " IN CROWN 9030 I,ITRUNC,NORMHT,HN,HD,ICRI,CL =%5d%5d%5d%10.3f%10.3f%5d%10.3f\n",
                            i, ITRUNC[i], NORMHT[i], hn, hd, icri, cl)
                end
            end

            # Clamp ICR
            if icri > Int32(95); icri = trunc(Int32, 95); end
            if icri < Int32(10) && _CROWN_CRNMLT[ispc] == Float32(1); icri = trunc(Int32, 10); end
            if icri < Int32(1);  icri = trunc(Int32, 1);  end
            ICR[i] = icri
        end # tree loop

        # Reset CRNMLT if flagged (after LSTART processing)
        if LSTART && _CROWN_ICFLG[ispc] == Int32(1)
            _CROWN_CRNMLT[ispc] = Float32(1)
            _CROWN_ICFLG[ispc]  = Int32(0)
        end
    end # species loop

    @label label_74
    # Dub missing crowns on cycle-0 dead trees
    if IREC2 <= Int(MAXTRE)
        for i in Int(IREC2):Int(MAXTRE)
            if ICR[i] > Int32(0); continue; end
            d  = DBH[i]
            cr = DUBSCR(d)
            icri = trunc(Int32, cr * Float32(100) + Float32(0.5))
            if ITRUNC[i] != Int32(0)
                hn   = Float32(NORMHT[i]) / Float32(100)
                hd   = hn - Float32(ITRUNC[i]) / Float32(100)
                cl   = (Float32(icri) / Float32(100)) * hn - hd
                icri = trunc(Int32, cl * Float32(100) / hn + Float32(0.5))
            end
            if icri > Int32(95); icri = trunc(Int32, 95); end
            if icri < Int32(10); icri = trunc(Int32, 10); end
            ICR[i] = icri
        end
    end

    if debug
        @printf(io_units[Int32(JOSTND)], " LEAVING CROWN 9010 FORMAT ITRN,ICR= %10d\n", ITRN)
        for jj in 1:Int(ITRN); @printf(io_units[Int32(JOSTND)], "%4d", ICR[jj]); end
        @printf(io_units[Int32(JOSTND)], "\n")
        @printf(io_units[Int32(JOSTND)], " LEAVING SUBROUTINE CROWN  CYCLE =%5d\n", ICYC)
    end
    return nothing
end

# CRCONS: called by RCON to load crown model constants.
# In Fortran this is a DATA-only entry — a no-op at runtime since DATA is static.
# In Julia the module-level arrays above are already initialized at load time.
function CRCONS()
    return nothing
end
