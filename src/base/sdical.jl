# base/sdical.f — SDICAL + 6 ENTRY points: SDI and density calculations
# Translated from: bin/FVSsn_buildDir/sdical.f (772 lines)
#
# SDICAL(iwho) → xmax     : BA-weighted max SDI for the stand
# SDICLS(jspec,dlo,dhi,iwho,jpnum) → (sdic,sdic2,a,b)
# CCCLS(jspec,dlo,dhi,iwho,jpnum)  → cra
# RDCLS(jspec,dlo,dhi,iwho,jpnum)  → (clsd2,clstpa,crd,tpafac,diamfac)
# RDCLS2(jspec,dlo,dhi,iwho,jpnum) → crd
# RDSLTR(jspec,it)                 → treerd
# SILFTY()                         → (modifies global ISILFT)
#
# Each Fortran ENTRY becomes a separate Julia function.
# DATA arrays MAPNE(108) and ISLFTM(108) are module-level constants.

const _SDICAL_MAPNE = Int32[
    2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
    2, 2, 2, 2, 2, 2, 3, 3, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3,
    2, 1, 2, 2, 2, 1, 2, 2, 2, 2, 2, 2, 2, 1, 3, 3, 3, 3, 3, 3,
    3, 3, 3, 3, 3, 3, 2, 2, 3, 3, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
    2, 2, 2, 2, 2, 2, 2, 2, 3, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3,
    2, 2, 2, 2, 2, 2, 2, 2]

const _SDICAL_ISLFTM = Int32[
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 1, 1, 0, 0, 1, 1, 0, 0, 0, 2, 2, 2, 2, 2, 1,
    0, 1, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1, 2, 2, 2, 2, 2, 2,
    2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0]

# ─── SDICAL: BA-weighted maximum SDI for the stand ───────────────────────────
function SDICAL(iwho::Integer)::Float32
    debug = DBCHK(false, "SDICAL", Int32(6), ICYC)
    if debug
        @printf(io_units[Int(JOSTND)],
            " ENTERING SUBROUTINE SDICAL CYCLE =%4d ITRN=%4d IREC1=%4d IREC2=%4d\n",
            ICYC, ITRN, IREC1, IREC2)
    end

    xmax  = Float32(0)
    totba = Float32(0)
    baxsp = zeros(Float32, MAXSP)

    # BA by species and by point
    npnt = Int(PI)
    baxpsp = zeros(Float32, MAXSP, min(npnt + 10, MAXPLT))

    if Int(ITRN) > 0
        for ii in 1:Int(ITRN)
            i    = Int(IND1[ii])
            ispc = Int(ISP[i])
            i >= Int(IREC2) && continue
            treeba = Float32(0.0054542) * DBH[i] * DBH[i] * PROB[i]
            baxsp[ispc] += treeba
            totba += treeba
            itre_i = Int(ITRE[i])
            if itre_i >= 1 && itre_i <= size(baxpsp, 2)
                baxpsp[ispc, itre_i] += treeba
            end
            if debug
                @printf(io_units[Int(JOSTND)],
                    " SDICAL II,I,ISPC,DBH,PROB,TREEBA, BAXSP,TOTBA=  %d %d %d %f %f %f %f %f\n",
                    ii, i, ispc, DBH[i], PROB[i], treeba, baxsp[ispc], totba)
            end
        end
        # calibration pass: include recent dead trees (IMC=7) when IWHO==1 and LSTART
        if Int(iwho) == 1 && LSTART
            for ii in Int(IREC2):MAXTRE
                ispc  = Int(ISP[ii])
                dprob = PROB[ii] / (FINT / FINTM)
                if Int(IMC[ii]) == 7
                    treeba = Float32(0.0054542) * DBH[ii] * DBH[ii] * dprob
                    baxsp[ispc] += treeba
                    totba += treeba
                end
            end
        end
    end

    if totba <= Float32(0)
        xmax = Float32(1)
    else
        for i in 1:MAXSP
            xmax += SDIDEF[i] * baxsp[i]
        end
        xmax /= totba
    end

    # per-point max SDI
    n2 = min(npnt + 10, MAXPLT)
    for ii in 1:n2
        XMAXPT[ii] = Float32(0)
        pntba = Float32(0)
        for i in 1:MAXSP
            ii2 = min(ii, size(baxpsp, 2))
            XMAXPT[ii] += SDIDEF[i] * baxpsp[i, ii2]
            pntba += baxpsp[i, ii2]
        end
        if pntba == Float32(0)
            XMAXPT[ii] = xmax
        else
            XMAXPT[ii] /= pntba
        end
    end

    if !LBAMAX
        global BAMAX = xmax * Float32(0.5454154) * PMSDIU
    else
        tem = PMSDIU
        if tem > Float32(1); tem /= Float32(100); end
        xmax = BAMAX / (Float32(0.5454154) * tem)
    end

    xmax = CLMAXDEN(SDIDEF, xmax)
    return xmax
end

# ─── SDICLS: SDI for a class of trees ────────────────────────────────────────
function SDICLS(jspec::Integer, dlo::Float32, dhi::Float32,
                iwho::Integer, jpnum::Integer)::NTuple{4,Float32}
    debug = DBCHK(false, "SDICLS", Int32(6), ICYC)

    sdsq  = Float32(0); sprob = Float32(0)
    sdic  = Float32(0); sdic2 = Float32(0)
    a     = Float32(0); b     = Float32(0)

    if Int(ITRN) <= 0; return (sdic, sdic2, a, b); end

    # pass 1: Stages method parameters over all trees
    for ii in 1:Int(ITRN)
        i = Int(IND1[ii])
        i >= Int(IREC2) && continue
        DBH[i] < DBHSTAGE && continue
        tpacre = Int(iwho) == 1 ? PROB[i] : WK4[i]
        sdsq  += DBH[i]^2 * tpacre
        sprob += tpacre
    end
    if sprob != Float32(0)
        a = (Float32(10)^Float32(-1.605)) * (Float32(1) - Float32(1.605)/Float32(2)) *
            ((sdsq/sprob)^(Float32(1.605)/Float32(2)))
        b = (Float32(10)^Float32(-1.605)) * (Float32(1.605)/Float32(2)) *
            ((sdsq/sprob)^(Float32(1.605)/Float32(2) - Float32(1)))
        sdic = sprob * a + b * sdsq
    end

    # pass 2: SDI for the specified class
    sdic  = Float32(0); sdic2 = Float32(0)
    igrp  = 0; iulim = 0

    for ii in 1:Int(ITRN)
        i = Int(IND1[ii])
        i >= Int(IREC2) && continue
        Int(jpnum) > 0 && Int(ITRE[i]) != Int(jpnum) && continue
        tpacre = Int(iwho) == 1 ? PROB[i] : WK4[i]
        if Int(jpnum) > 0; tpacre *= (PI - Float32(NONSTK)); end

        lincl = false
        jspec_i = Int(jspec)
        if jspec_i == 0
            lincl = true
        elseif jspec_i == Int(ISP[i]) && !LEAVESP[Int(ISP[i])]
            lincl = true
        elseif jspec_i < 0
            igrp  = -jspec_i
            iulim = Int(ISPGRP[igrp, 1]) + 1
            for ig in 2:iulim
                if Int(ISP[i]) == Int(ISPGRP[igrp, ig]) && !LEAVESP[Int(ISP[i])]
                    lincl = true; break
                end
            end
        end

        if lincl && DBH[i] >= dlo && DBH[i] < dhi
            if DBH[i] >= DBHZEIDE
                sdic2 += tpacre * (DBH[i]/Float32(10))^Float32(1.605)
            end
            if DBH[i] >= DBHSTAGE
                sdic += (a + b * DBH[i]^2) * tpacre
            end
        end
    end

    return (sdic, sdic2, a, b)
end

# ─── CCCLS: canopy cover area for a class of trees ───────────────────────────
function CCCLS(jspec::Integer, dlo::Float32, dhi::Float32,
               iwho::Integer, jpnum::Integer)::Float32
    debug = DBCHK(false, "CCCLS", Int32(5), ICYC)
    cra = Float32(0)
    if Int(ITRN) <= 0; return cra; end

    for ii in 1:Int(ITRN)
        i = Int(IND1[ii])
        i >= Int(IREC2) && continue
        Int(jpnum) > 0 && Int(ITRE[i]) != Int(jpnum) && continue

        lincl = false
        jspec_i = Int(jspec)
        if (jspec_i == 0 || jspec_i == Int(ISP[i])) && !LEAVESP[Int(ISP[i])]
            lincl = true
        elseif jspec_i < 0
            igrp  = -jspec_i
            iulim = Int(ISPGRP[igrp, 1]) + 1
            for ig in 2:iulim
                if Int(ISP[i]) == Int(ISPGRP[igrp, ig]) && !LEAVESP[Int(ISP[i])]
                    lincl = true; break
                end
            end
        end

        if lincl && DBH[i] >= dlo && DBH[i] < dhi
            tpacre = Int(iwho) == 1 ? PROB[i] : WK4[i]
            if Int(jpnum) > 0; tpacre *= (PI - Float32(NONSTK)); end
            cwdi = CRWDTH[i]
            cra += cwdi * cwdi * tpacre
        end
    end
    return cra
end

# ─── RDCLS: Curtis relative density for a class of trees ─────────────────────
function RDCLS(jspec::Integer, dlo::Float32, dhi::Float32,
               iwho::Integer, jpnum::Integer)::NTuple{5,Float32}
    debug = DBCHK(false, "RDCLS", Int32(5), ICYC)
    tpafac = Float32(0); diamfac = Float32(0)
    clsd2  = Float32(0); clstpa  = Float32(0); crd = Float32(0)

    if Int(ITRN) <= 0; return (clsd2, clstpa, crd, tpafac, diamfac); end

    cmpnt1 = Float32(0.25) * Float32(3.14159)
    cmpnt2 = Float32(24)^Float32(2)
    cmpnt4 = Float32(1.5) / Float32(2)
    cmpnt5 = cmpnt1 / cmpnt2
    cmpnt6 = Float32(0.75) * Float32(3.14159)

    # pass 1: parameters over all trees in stand
    for ii in 1:Int(ITRN)
        i = Int(IND1[ii])
        i >= Int(IREC2) && continue
        DBH[i] < DBHSTAGE && continue
        tpacre = Int(iwho) == 1 ? PROB[i] : WK4[i]
        clsd2  += DBH[i]^2 * tpacre
        clstpa += tpacre
    end
    if clstpa > Float32(0)
        cmpnt3 = clsd2 / clstpa
        tpafac  = cmpnt5 * (cmpnt3^cmpnt4)
        diamfac = (cmpnt6 / cmpnt2) * (cmpnt3^(cmpnt4 - Float32(1)))
        crd = clstpa * tpafac + clsd2 * diamfac
    end

    # pass 2: relative density for the specified class
    crd = Float32(0)

    for ii in 1:Int(ITRN)
        i = Int(IND1[ii])
        i >= Int(IREC2) && continue
        Int(jpnum) > 0 && Int(ITRE[i]) != Int(jpnum) && continue
        tpacre = Int(iwho) == 1 ? PROB[i] : WK4[i]
        if Int(jpnum) > 0; tpacre *= (PI - Float32(NONSTK)); end

        lincl = false
        jspec_i = Int(jspec)
        if jspec_i == 0
            lincl = true
        elseif jspec_i == Int(ISP[i]) && !LEAVESP[Int(ISP[i])]
            lincl = true
        elseif jspec_i < 0
            igrp  = -jspec_i
            iulim = Int(ISPGRP[igrp, 1]) + 1
            for ig in 2:iulim
                if Int(ISP[i]) == Int(ISPGRP[igrp, ig]) && !LEAVESP[Int(ISP[i])]
                    lincl = true; break
                end
            end
        end

        if lincl && DBH[i] >= dlo && DBH[i] < dhi && DBH[i] >= DBHSTAGE
            crd += (tpafac + diamfac * DBH[i]^2) * tpacre
        end
    end

    return (clsd2, clstpa, crd, tpafac, diamfac)
end

# ─── RDCLS2: SILVAH-style relative density (NE variant only) ─────────────────
function RDCLS2(jspec::Integer, dlo::Float32, dhi::Float32,
                iwho::Integer, jpnum::Integer)::Float32
    debug = DBCHK(false, "RDCLS2", Int32(6), ICYC)
    crd = Float32(0)
    VARACD != "NE" && return crd
    if Int(ITRN) <= 0; return crd; end

    for ii in 1:Int(ITRN)
        i = Int(IND1[ii])
        i >= Int(IREC2) && continue
        Int(jpnum) > 0 && Int(ITRE[i]) != Int(jpnum) && continue

        lincl = false
        jspec_i = Int(jspec)
        if (jspec_i == 0 || jspec_i == Int(ISP[i])) && !LEAVESP[Int(ISP[i])]
            lincl = true
        elseif jspec_i < 0
            igrp  = -jspec_i
            iulim = Int(ISPGRP[igrp, 1]) + 1
            for ig in 2:iulim
                if Int(ISP[i]) == Int(ISPGRP[igrp, ig]) && !LEAVESP[Int(ISP[i])]
                    lincl = true; break
                end
            end
        end

        if lincl && DBH[i] >= dlo && DBH[i] < dhi && DBH[i] >= Float32(1)
            tpacre = Int(iwho) == 1 ? PROB[i] : WK4[i]
            if Int(jpnum) > 0; tpacre *= (PI - Float32(NONSTK)); end
            ieqn = Int(_SDICAL_MAPNE[min(Int(ISP[i]), 108)])
            d2   = DBH[i] * DBH[i]
            if ieqn == 1
                crd += max(Float32(0), tpacre * (Float32(0.0033033) + Float32(0.020426)*DBH[i] + Float32(0.0006776)*d2))
            elseif ieqn == 2
                crd += max(Float32(0), tpacre * (Float32(-0.027142) + Float32(0.024257)*DBH[i] + Float32(0.0015225)*d2))
            elseif ieqn == 3
                crd += max(Float32(0), tpacre * (Float32(-0.0027935) + Float32(0.0058959)*DBH[i] + Float32(0.0047289)*d2))
            end
        end
    end
    return crd
end

# ─── RDSLTR: relative density of a single tree (NE variant only) ─────────────
function RDSLTR(jspec::Integer, it::Integer)::Float32
    debug = DBCHK(false, "RDSLTR", Int32(6), ICYC)
    treerd = Float32(0)
    it >= Int(IREC2) && return treerd
    VARACD != "NE" && return treerd
    DBH[it] < Float32(1) && return treerd
    ieqn = Int(_SDICAL_MAPNE[min(Int(jspec), 108)])
    d2   = DBH[it] * DBH[it]
    if ieqn == 1
        treerd = max(Float32(0), Float32(0.0033033) + Float32(0.020426)*DBH[it] + Float32(0.0006776)*d2)
    elseif ieqn == 2
        treerd = max(Float32(0), Float32(-0.027142) + Float32(0.024257)*DBH[it] + Float32(0.0015225)*d2)
    elseif ieqn == 3
        treerd = max(Float32(0), Float32(-0.0027935) + Float32(0.0058959)*DBH[it] + Float32(0.0047289)*d2)
    end
    return treerd
end

# ─── SILFTY: SILVAH forest type classification (NE variant only) ──────────────
function SILFTY()
    debug = DBCHK(false, "SILFTY", Int32(6), ICYC)
    global ISILFT = Int32(0)
    if VARACD != "NE"; return nothing; end

    ba1 = Float32(0); ba2 = Float32(0); ba3 = Float32(0)
    ba4 = Float32(0); ba5 = Float32(0); batot = Float32(0)

    for ii in 1:Int(ITRN)
        i    = Int(IND1[ii])
        i >= Int(IREC2) && continue
        ispc = Int(ISP[i])
        contrib = DBH[i] * DBH[i] * Float32(0.0054542) * PROB[i]
        batot  += contrib
        m = _SDICAL_ISLFTM[min(ispc, 108)]
        if m == 1
            ba1 += contrib
            if ispc == 16; ba2 += contrib; end
            if ispc ∈ (54, 42, 46); ba3 += contrib; end
        elseif m == 2
            ba4 += contrib
        end
    end
    ba5 = ba1 + ba4

    ratio1 = Float32(0); ratio2 = Float32(0)
    ratio3 = Float32(0); ratio5 = Float32(0)
    if batot > Float32(0)
        ratio1 = ba1 / batot
        ratio2 = ba2 / batot
        ratio3 = ba3 / batot
        ratio5 = ba5 / batot
    end

    if ratio1 >= Float32(0.65)
        global ISILFT = Int32(1)
        if ratio2 >= Float32(0.50)
            global ISILFT = Int32(2)
        elseif ratio3 >= Float32(0.25) && ratio2 < Float32(0.50)
            global ISILFT = Int32(3)
        end
    end
    if ba4 > Float32(0); global ISILFT = Int32(4); end
    if Int(ISILFT) == 0 && ratio5 >= Float32(0.65); global ISILFT = Int32(5); end
    return nothing
end
