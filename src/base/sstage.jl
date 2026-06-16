# sstage.jl — Stand structural stage classification
# Translated from: base/sstage.f (942 lines)
#
# Stage classes (TMPSCL / ISTRCL):
#   0=BG bare ground, 1=SI stand initiation, 2=SE stem exclusion,
#   3=UR understory reinitiation, 4=YM young forest multistrata,
#   5=OS old forest single stratum, 6=OM old forest multistrata
#
# Three helper functions from the same source file:
#   _sstghp!   — nominal DBH/height statistics per stratum
#   _sstghtpa! — TPA per stratum
#   UPDATECCCOEF — process CCADJ keyword activities

const _SSCODES = ("0=BG","1=SI","2=SE","3=UR","4=YM","5=OS","6=OM")

function SSTAGE(inba::Integer, inicycle::Integer, lsuprt::Bool)
    tmptpa = Float32(TPAMIN)
    tmpccm = Float32(CCMIN)
    tmppct = Float32(PCTSMX)
    tmpsaw = Float32(SAWDBH)
    tmpssd = Float32(SSDBH)
    tmpgap = Float32(GAPPCT)
    fmflag = 0
    iba    = Int(inba)
    icycle = Int(inicycle)

    UPDATECCCOEF(Int(inicycle), Int(inba))
    if inicycle > 1 && inba == 2 && CCCOEF2 != Float32(1); global CCCOEF = CCCOEF2; end

    tmpprb = zeros(Float32, Int(MAXTRE))
    tmpicr = zeros(Int32,   Int(MAXTRE))
    for i in 1:Int(ITRN)
        tmpprb[i] = Float32(PROB[i])
        tmpicr[i] = Int32(ICR[i])
    end

    if icycle == 1 && !LCALC
        EVUST4(16); EVUST4(17); EVUST4(18)
        EVUST4(19); EVUST4(24); EVUST4(25)
    end
    if !LCALC; return nothing; end

    _sstage_core!(fmflag, iba, icycle, lsuprt, tmptpa, tmpccm, tmppct,
                  tmpsaw, tmpssd, tmpgap, tmpprb, tmpicr,
                  Ref(Int32(0)), Ref(Float32(0)))
    return nothing
end

function FMSSTAGE(fmtpa::Real, fmccm::Real, fmpct::Real, fmsaw::Real,
                  fmssd::Real, fmgap::Real, fmstcl::Ref{Int32},
                  fmdbh::Ref{Float32}, fprob::AbstractVector{Float32},
                  ficr::AbstractVector{Int32})
    tmptpa = Float32(fmtpa)
    tmpccm = Float32(fmccm)
    tmppct = Float32(fmpct)
    tmpsaw = Float32(fmsaw)
    tmpssd = Float32(fmssd)
    tmpgap = Float32(fmgap)
    fmflag = 1

    tmpprb = zeros(Float32, Int(MAXTRE))
    tmpicr = zeros(Int32,   Int(MAXTRE))
    for i in 1:Int(ITRN)
        tmpprb[i] = fprob[i]
        tmpicr[i] = ficr[i]
    end

    _sstage_core!(fmflag, Int(ICYC), Int(ICYC), false, tmptpa, tmpccm, tmppct,
                  tmpsaw, tmpssd, tmpgap, tmpprb, tmpicr, fmstcl, fmdbh)
    return nothing
end

# ---------------------------------------------------------------------------
# Shared implementation — called by both SSTAGE and FMSSTAGE
# ---------------------------------------------------------------------------
function _sstage_core!(fmflag::Int, iba::Int, icycle::Int, lsuprt::Bool,
                       tmptpa::Float32, tmpccm::Float32, tmppct::Float32,
                       tmpsaw::Float32, tmpssd::Float32, tmpgap::Float32,
                       tmpprb::Vector{Float32}, tmpicr::Vector{Int32},
                       fmstcl_ref::Ref{Int32}, fmdbh_ref::Ref{Float32})
    # Choose SDI baseline
    xbamax = if fmflag == 1
        Float32(ATSDIX)
    else
        xb = Float32(BTSDIX)
        (iba != 1 && Float32(ONTREM[7]) > Float32(0)) ? Float32(ATSDIX) : xb
    end

    debug = DBCHK(false, "SSTAGE", Int32(6), Int32(icycle))
    if debug
        @printf(io_units[Int(JOSTND)], " IN SSTAGE, IBA, ICYCLE= %5d %5d\n", iba, icycle)
    end

    # Initialize
    nstr   = 0; is1ok = 0; is2ok = 0; is3ok = 0
    tmpscl = Int32(0); tmpdbh = Float32(0)
    xhtls  = Float32(0); xhtss = Float32(0); xnstr = Float32(0); xsdi = Float32(0)
    dbhs1  = Float32(0); dbhs2 = Float32(0); dbhs3 = Float32(0)
    ihts1  = 0; ihts2 = 0; ihts3 = 0
    ihtls  = 0; ihtss = 0
    ihtss1 = 0; ihtss2 = 0; ihtss3 = 0
    ihtls1 = 0; ihtls2 = 0; ihtls3 = 0
    icrbs1 = 0; icrbs2 = 0; icrbs3 = 0
    icrcv1 = 0; icrcv2 = 0; icrcv3 = 0
    icovr  = 0
    isp11  = 0; isp21 = 0; isp12 = 0; isp22 = 0; isp13 = 0; isp23 = 0
    tpa1   = Float32(0); tpa2 = Float32(0); tpa3 = Float32(0)
    sp11 = "--"; sp21 = "--"; sp12 = "--"; sp22 = "--"; sp13 = "--"; sp23 = "--"

    index = zeros(Int32, Int(MAXTRE))
    sswk  = zeros(Float32, Int(MAXTRE))

    # Build index of live trees
    ntrees = 0
    for i in 1:Int(ITRN)
        if tmpprb[i] > Float32(1e-5)
            ntrees += 1
            index[ntrees] = Int32(i)
        end
        if debug
            @printf(io_units[Int(JOSTND)],
                " IN SSTAGE. I, DBH, HT, TMPICR, TMPPRB= %4d %9.3f %9.3f %4d %9.5f\n",
                i, DBH[i], HT[i], tmpicr[i], tmpprb[i])
        end
    end

    if ntrees == 0; @goto label_100; end

    if ntrees <= 1
        i = Int(index[1])
        WK6[i] = Float32(CRWDTH[i])
        WK6[i] = WK6[i] * WK6[i] * tmpprb[i] * Float32(0.785398)
        icrcv1 = round(Int, WK6[i]/Float32(43560) + Float32(0.5))
        if WK6[i] < Float32(435.60) * tmpccm
            tmpscl = Int32(0)
            if tmpprb[i] >= tmptpa; tmpscl = Int32(1); end
        elseif Float32(DBH[i]) < tmpssd
            tmpscl = Int32(1)
        elseif Float32(DBH[i]) < tmpsaw
            tmpscl = Int32(2)
            if Float32(SDIAC) < Float32(0.01) * tmppct * xbamax; tmpscl = Int32(1); end
        else
            tmpscl = Int32(5)
        end
        tmpdbh = Float32(DBH[i])
        dbhs1  = tmpdbh
        ihts1  = round(Int, Float32(HT[i]) + Float32(0.5))
        ihtss1 = ihts1; ihtls1 = ihts1
        icrbs1 = round(Int, Float32(HT[i]) * (Float32(1) - Float32(tmpicr[i]) * Float32(0.01)) + Float32(0.5))
        sp11   = length(JSP[Int(ISP[i])]) >= 2 ? JSP[Int(ISP[i])][1:2] : JSP[Int(ISP[i])]
        isp11  = Int(ISP[i])
        tpa1   = tmpprb[i]
        @goto label_80
    end

    RDPSRT(ntrees, HT, @view(index[1:ntrees]), false)

    # Compute crown cover per tree (crown area × prob)
    for ii in 1:ntrees
        i = Int(index[ii])
        WK6[i] = Float32(CRWDTH[i])
        WK6[i] = WK6[i] * WK6[i] * tmpprb[i] * Float32(0.785398)
        if debug
            @printf(io_units[Int(JOSTND)],
                " IN SSTAGE. I, II, DBH, HT, TMPICR, WK6= %4d %4d %9.3f %9.3f %4d %9.1f\n",
                i, ii, DBH[i], HT[i], tmpicr[i], WK6[i])
        end
    end

    # Find two largest height gaps
    diff1 = Float32(-1e20); diff2 = Float32(-1e20)
    id1i1 = 0; id1i2 = 0; id2i1 = 0; id2i2 = 0
    iilg  = 1; ilarge = Int(index[iilg]); sumprb = Float32(0)

    for ii in 2:ntrees
        ismall = Int(index[ii])
        x = Float32(HT[ilarge]) * tmpgap * Float32(0.01)
        if x < Float32(10); x = Float32(10); end
        if Float32(HT[ismall]) < Float32(HT[ilarge]) - x
            if tmpprb[ismall] + sumprb < Float32(2)
                sumprb += tmpprb[ismall]
            else
                diff = Float32(HT[ilarge]) - Float32(HT[ismall])
                if diff > diff1
                    diff2 = diff1; diff1 = diff
                    id2i1 = id1i1; id2i2 = id1i2
                    id1i1 = iilg;  id1i2 = ii
                elseif diff > diff2
                    diff2 = diff
                    id2i1 = iilg; id2i2 = ii
                end
                ilarge = ismall; iilg = ii; sumprb = Float32(0)
            end
        else
            if tmpprb[ismall] + sumprb < Float32(2)
                sumprb += tmpprb[ismall]
            else
                ilarge = ismall; iilg = ii; sumprb = Float32(0)
            end
        end
        if debug
            @printf(io_units[Int(JOSTND)],
                " II=%4d IILG=%4d LG=%4d SM=%4d HTL&S= %7.1f %7.1f SPB=%7.4f D11=%4d 2=%4d D21=%4d 2=%4d\n",
                ii, iilg, ilarge, ismall, HT[ilarge], HT[ismall],
                sumprb, id1i1, id1i2, id2i1, id2i2)
        end
    end

    # Ensure upper stratum is on top
    if id1i1 > id2i1 && id2i1 > 0
        ii = id1i1; id1i1 = id2i1; id2i1 = ii
        ii = id1i2; id1i2 = id2i2; id2i2 = ii
    end

    # Stratum boundaries
    nstr  = 1
    is1i1 = 1;  is1i2 = ntrees
    is2i1 = 0;  is2i2 = 0
    is3i1 = 0;  is3i2 = 0

    if id1i1 > 0
        nstr  = 2
        is1i2 = id1i1; is2i1 = id1i2; is2i2 = ntrees
    end
    if id2i1 > 0
        nstr  = 3
        is2i2 = id2i1; is3i1 = id2i2; is3i2 = ntrees
    end

    if debug
        @printf(io_units[Int(JOSTND)],
            " ID1I1=%4d ID1I2=%4d ID2I1=%4d ID2I2=%4d DIFF1&2= %14.7e %14.7e\n NSTR=%2d IS1I1=%4d IS1I2=%4d IS2I1=%4d IS2I2=%4d IS3I1=%4d IS3I2=%4d\n",
            id1i1, id1i2, id2i1, id2i2, diff1, diff2,
            nstr, is1i1, is1i2, is2i1, is2i2, is3i1, is3i2)
    end

    # Cover in each stratum
    i2 = max(is1i2, is2i1 - 1)
    crs1 = Ref(Float32(0))
    COVOLP(debug, Int(JOSTND), i2-is1i1+1, @view(index[is1i1:i2]), WK6, crs1, Float32(CCCOEF))
    if debug; @printf(io_units[Int(JOSTND)], " I2=%4d CRS1=%8.2f\n", i2, crs1[]); end
    if crs1[] > tmpccm; is1ok = 1; end

    crs2 = Float32(0)
    crs2_r = Ref(Float32(0))
    if nstr >= 2
        i2 = max(is2i2, is3i1 - 1)
        COVOLP(debug, Int(JOSTND), i2-is2i1+1, @view(index[is2i1:i2]), WK6, crs2_r, Float32(CCCOEF))
        crs2 = crs2_r[]
        if debug; @printf(io_units[Int(JOSTND)], " I2=%4d CRS2=%8.2f\n", i2, crs2); end
        if crs2 > tmpccm; is2ok = 1; end
    end

    crs3 = Float32(0)
    crs3_r = Ref(Float32(0))
    if nstr >= 3
        COVOLP(debug, Int(JOSTND), is3i2-is3i1+1, @view(index[is3i1:is3i2]), WK6, crs3_r, Float32(CCCOEF))
        crs3 = crs3_r[]
        if debug; @printf(io_units[Int(JOSTND)], " I2=%4d CRS3=%8.2f\n", i2, crs3); end
        if crs3 > tmpccm; is3ok = 1; end
    end
    crs1_val = crs1[]

    if debug
        @printf(io_units[Int(JOSTND)], "%2d CRS1,2,3= %8.2f %8.2f %8.2f IS1,2,3OK= %2d %2d %2d NSTR= %2d\n",
                1, crs1_val, crs2, crs3, is1ok, is2ok, is3ok, nstr)
    end

    nstr = is1ok + is2ok + is3ok

    if debug
        @printf(io_units[Int(JOSTND)], "%2d CRS1,2,3= %8.2f %8.2f %8.2f IS1,2,3OK= %2d %2d %2d NSTR= %2d\n",
                2, crs1_val, crs2, crs3, is1ok, is2ok, is3ok, nstr)
    end

    if nstr == 0
        if Float32(TPROB) < tmptpa; @goto label_80; end
        is1ok = 1; nstr = 1; is1i1 = 1; is1i2 = ntrees
    end

    j1 = max(is1i2, is2i1 - 1)
    j2 = max(is2i2, is3i1 - 1)
    _sstghtpa!(is1i1, j1,    index, tmpprb, tpa1)
    _sstghtpa!(is2i1, j2,    index, tmpprb, tpa2)
    _sstghtpa!(is3i1, is3i2, index, tmpprb, tpa3)

    msp1 = 0; msp2 = 0
    _sstghp!(is1i1, is1i2, index, WK6, sswk, Float32.(DBH), Float32.(HT),
             tmpicr, Int.(ISP), tmpprb, dbhs1, ihts1, ihtss1, ihtls1, icrbs1, msp1, msp2)
    if msp1 > 0; sp11 = JSP[msp1];  isp11 = msp1; end
    if msp2 > 0; sp21 = JSP[msp2];  isp21 = msp2; end

    _sstghp!(is2i1, is2i2, index, WK6, sswk, Float32.(DBH), Float32.(HT),
             tmpicr, Int.(ISP), tmpprb, dbhs2, ihts2, ihtss2, ihtls2, icrbs2, msp1, msp2)
    if msp1 > 0; sp12 = JSP[msp1];  isp12 = msp1; end
    if msp2 > 0; sp22 = JSP[msp2];  isp22 = msp2; end

    _sstghp!(is3i1, is3i2, index, WK6, sswk, Float32.(DBH), Float32.(HT),
             tmpicr, Int.(ISP), tmpprb, dbhs3, ihts3, ihtss3, ihtls3, icrbs3, msp1, msp2)
    if msp1 > 0; sp13 = JSP[msp1];  isp13 = msp1; end
    if msp2 > 0; sp23 = JSP[msp2];  isp23 = msp2; end

    # Identify dominant stratum
    dmind = Float32(0)
    if is1ok == 1
        is1ok = 2; tmpdbh = dbhs1
        dmind = Float32(DBH[Int(index[is1i2])])
        ihtls = ihtls1; ihtss = ihtss1
    elseif is2ok == 1
        is2ok = 2; tmpdbh = dbhs2
        dmind = Float32(DBH[Int(index[is2i2])])
        ihtls = ihtls2; ihtss = ihtss2
    elseif is3ok == 1
        is3ok = 2; tmpdbh = dbhs3
        dmind = Float32(DBH[Int(index[is3i2])])
        ihtls = ihtls3; ihtss = ihtss3
    else
        ihtls = 0; ihtss = 0
    end

    # Classify structural stage
    if nstr == 1
        if tmpdbh < tmpssd
            tmpscl = Int32(1)
        elseif tmpdbh < tmpsaw
            tmpscl = Int32(2)
            xsdi = iba == 1 ? Float32(SDIBC) : Float32(SDIAC)
            if xsdi < Float32(0.01) * tmppct * xbamax; tmpscl = Int32(1); end
        else
            tmpscl = Int32(5)
            if dmind < Float32(3); tmpscl = Int32(6); end
        end
    elseif nstr == 2
        if tmpdbh < tmpssd
            tmpscl = Int32(1)
        elseif tmpdbh < tmpsaw
            tmpscl = Int32(3)
        else
            tmpscl = Int32(6)
        end
    else
        if tmpdbh < tmpssd
            tmpscl = Int32(1)
        elseif tmpdbh < tmpsaw
            tmpscl = Int32(4)
        else
            tmpscl = Int32(6)
        end
    end

    if debug
        @printf(io_units[Int(JOSTND)],
            " IN SSTAGE. TMPSSD,TMPSAW,TMPPCT,XSDI,XBAMAX= %9.1f %9.1f %9.1f %9.1f %9.1f\n",
            tmpssd, tmpsaw, tmppct, xsdi, xbamax)
        @printf(io_units[Int(JOSTND)],
            " IN SSTAGE. TMPTPA,TMPCCM,TMPGAP= %9.1f %9.1f %9.1f\n",
            tmptpa, tmpccm, tmpgap)
    end

    icrcv1 = round(Int, crs1_val + Float32(0.5))
    icrcv2 = round(Int, crs2     + Float32(0.5))
    icrcv3 = round(Int, crs3     + Float32(0.5))

    @label label_80

    cover_r = Ref(Float32(0))
    COVOLP(debug, Int(JOSTND), ntrees, @view(index[1:max(1,ntrees)]), WK6, cover_r, Float32(CCCOEF))
    cover  = cover_r[]
    icovr  = round(Int, cover + Float32(0.5))
    if ntrees <= 1; icrcv1 = icovr; end

    if debug
        @printf(io_units[Int(JOSTND)], " IN SSTAGE. ISTRCL & DBHDOM= %2d %9.1f\n", tmpscl, tmpdbh)
    end

    @label label_100

    if fmflag == 1
        fmstcl_ref[] = tmpscl
        fmdbh_ref[]  = tmpdbh
        return nothing
    end

    global ISTRCL = tmpscl
    global DBHDOM = tmpdbh

    icd = iba == 1 ? 0 : 1

    if debug
        @printf(io_units[Int(JOSTND)], " IN SSTAGE. ISTRCL & DBHDOM= %2d %9.1f\n", ISTRCL, DBHDOM)
    end

    if iba == 1
        EVSET4(16, Float32(ISTRCL)); EVSET4(18, Float32(DBHDOM)); EVSET4(24, Float32(icovr))
        EVSET4(40, Float32(ihtls));  EVSET4(42, Float32(ihtss));  EVSET4(44, Float32(nstr))
        EVUST4(17); EVUST4(19); EVUST4(25); EVUST4(41); EVUST4(43); EVUST4(45)
    else
        EVSET4(17, Float32(ISTRCL)); EVSET4(19, Float32(DBHDOM)); EVSET4(25, Float32(icovr))
        EVSET4(41, Float32(ihtls));  EVSET4(43, Float32(ihtss));  EVSET4(45, Float32(nstr))
    end

    j = iba == 1 ? 1 : 2
    if iba == 1
        for jj in 1:33; for kk in 1:2; OSTRST[jj, kk] = Float32(0); end; end
    end
    OSTRST[1,j]=dbhs1; OSTRST[2,j]=Float32(ihts1);  OSTRST[3,j]=Float32(ihtls1)
    OSTRST[4,j]=Float32(ihtss1); OSTRST[5,j]=Float32(icrbs1); OSTRST[6,j]=Float32(icrcv1)
    OSTRST[7,j]=Float32(isp11);  OSTRST[8,j]=Float32(isp21);  OSTRST[9,j]=Float32(is1ok)
    OSTRST[10,j]=tpa1
    OSTRST[11,j]=dbhs2; OSTRST[12,j]=Float32(ihts2); OSTRST[13,j]=Float32(ihtls2)
    OSTRST[14,j]=Float32(ihtss2); OSTRST[15,j]=Float32(icrbs2); OSTRST[16,j]=Float32(icrcv2)
    OSTRST[17,j]=Float32(isp12);  OSTRST[18,j]=Float32(isp22);  OSTRST[19,j]=Float32(is2ok)
    OSTRST[20,j]=tpa2
    OSTRST[21,j]=dbhs3; OSTRST[22,j]=Float32(ihts3); OSTRST[23,j]=Float32(ihtls3)
    OSTRST[24,j]=Float32(ihtss3); OSTRST[25,j]=Float32(icrbs3); OSTRST[26,j]=Float32(icrcv3)
    OSTRST[27,j]=Float32(isp13);  OSTRST[28,j]=Float32(isp23);  OSTRST[29,j]=Float32(is3ok)
    OSTRST[30,j]=tpa3
    OSTRST[31,j]=Float32(nstr); OSTRST[32,j]=Float32(icovr); OSTRST[33,j]=Float32(ISTRCL)

    dbskode = Ref(Int32(1))
    DBSSTRCLASS(Int(IY[icycle]), String(NPLT), icd,
                dbhs1, ihts1, ihtls1, ihtss1, icrbs1, icrcv1, sp11, sp21, is1ok,
                dbhs2, ihts2, ihtls2, ihtss2, icrbs2, icrcv2, sp12, sp22, is2ok,
                dbhs3, ihts3, ihtls3, ihtss3, icrbs3, icrcv3, sp13, sp23, is3ok,
                nstr, icovr, _SSCODES[Int(ISTRCL)+1], dbskode, ntrees)
    if dbskode[] == 0; return nothing; end

    if icycle == 1
        if !lsuprt && LPRNT && IRREF == -1
            irref_ref = Ref(Int32(0))
            GETID(irref_ref)
            global IRREF = irref_ref[]
            iout = Ref(Int32(0)); GETLUN(iout)
            @printf(io_units[Int(iout[])],
                " %5d \$#*%%\nStructural statistics for stand: %s  MgmtID: %s\n\n",
                IRREF, NPLT, MGMID)
            @printf(io_units[Int(iout[])],
                "        ------------ Stratum 1 ------------        ------------ Stratum 2 ------------        ------------ Stratum 3 ------------\n")
            @printf(io_units[Int(iout[])],
                "     Rm  DBH  Nom  Lg  Sm Bas Cov Sp1 Sp2 C  DBH  Nom  Lg  Sm Bas Cov Sp1 Sp2 C  DBH  Nom  Lg  Sm Bas Cov Sp1 Sp2 C N Tot Struc\n")
            @printf(io_units[Int(iout[])],
                "Year Cd ----- --- --- --- --- --- --- --- - ----- --- --- --- --- --- --- --- - ----- --- --- --- --- --- --- --- - - --- -----\n\$#*%%\n")
        end
    end

    if IRREF > 0 && !lsuprt && ntrees > 0
        iout2 = Ref(Int32(0)); GETLUN(iout2)
        @printf(io_units[Int(iout2[])],
            " %5d %4d %3d %5.1f %3d %3d %3d %3d %3d %s %s %1d %5.1f %3d %3d %3d %3d %3d %s %s %1d %5.1f %3d %3d %3d %3d %3d %s %s %1d %1d %3d  %s\n",
            IRREF, IY[icycle], icd,
            dbhs1, ihts1, ihtls1, ihtss1, icrbs1, icrcv1, sp11, sp21, is1ok,
            dbhs2, ihts2, ihtls2, ihtss2, icrbs2, icrcv2, sp12, sp22, is2ok,
            dbhs3, ihts3, ihtls3, ihtss3, icrbs3, icrcv3, sp13, sp23, is3ok,
            nstr, icovr, _SSCODES[Int(ISTRCL)+1])
    end
    return nothing
end

# ---------------------------------------------------------------------------
# Private helper: nominal DBH/height stats per stratum
# ---------------------------------------------------------------------------
function _sstghp!(i1::Int, i2::Int,
                  ind::AbstractVector{Int32}, wk6::AbstractVector{Float32},
                  wk4::AbstractVector{Float32}, dbh::AbstractVector{Float32},
                  ht::AbstractVector{Float32},  tmpicr::AbstractVector{Int32},
                  isp::AbstractVector{Int},     tmpprb::AbstractVector{Float32},
                  dbhnom::Float32, iht::Int, ihts::Int, ihtl::Int, icrb::Int,
                  msp1::Int, msp2::Int)
    # Clear species accumulators in wk4 (indices 1..MAXSP)
    for i in 1:Int(MAXSP); wk4[i] = Float32(0); end
    msp1 = 0; msp2 = 0; acb = Float32(0); sp = Float32(0); sum = Float32(0)

    if i1 == 0 || i2 == 0; return; end

    ihtl = round(Int, ht[Int(ind[i1])] + Float32(0.5))
    ihts = round(Int, ht[Int(ind[i2])] + Float32(0.5))

    itop = i2; i3 = -1
    for ii in i1:itop
        i = Int(ind[ii])
        sum += wk6[i]
        sp  += tmpprb[i]
        acb += ht[i] * (Float32(1) - Float32(tmpicr[i]) * Float32(0.01)) * tmpprb[i]
        is  = isp[i]
        wk4[is] += wk6[i]
        if sum > Float32(41382) && i3 == -1; i3 = ii; end
    end
    if i3 == -1; i3 = i2; end

    # Top 2 species by cover
    x1 = Float32(0); x2 = Float32(0)
    for i in 1:Int(MAXSP)
        if wk4[i] > x1
            x2 = x1; x1 = wk4[i]; msp2 = msp1; msp1 = i
        elseif wk4[i] > x2
            x2 = wk4[i]; msp2 = i
        end
    end

    icrb = sp > Float32(0.0001) ? round(Int, acb/sp + Float32(0.5)) : 0

    # Per-tree crown area (for percentile)
    for ii in i1:i3
        i = Int(ind[ii])
        wk4[i] = wk6[i] / tmpprb[i]
    end

    RDPSRT(i3-i1+1, wk4, @view(ind[i1:i3]), false)
    T = PCTILE(i3-i1+1, @view(ind[i1:i3]), wk6, wk4)

    # Find the 70-percentile tree (30% down from top)
    i70  = 0; diff = Float32(1e30)
    for ii in i1:i3
        i = Int(ind[ii])
        if abs(wk4[i] - Float32(70)) < diff
            i70 = ii; diff = abs(wk4[i] - Float32(70))
        end
    end

    k1 = max(i1, i70 - 4)
    k2 = min(i3, i70 + 4)

    sd = Float32(0); sh = Float32(0); sp2 = Float32(0)
    for ii in k1:k2
        i = Int(ind[ii])
        sd  += dbh[i] * tmpprb[i]
        sh  += ht[i]  * tmpprb[i]
        sp2 += tmpprb[i]
    end

    dbhnom = Float32(0); iht = 0
    if sp2 > Float32(0.0001)
        dbhnom = sd / sp2
        iht    = round(Int, sh/sp2 + Float32(0.5))
    end
    return nothing
end

# ---------------------------------------------------------------------------
# Private helper: TPA per stratum
# ---------------------------------------------------------------------------
function _sstghtpa!(i1::Int, i2::Int,
                    ind::AbstractVector{Int32}, tmpprb::AbstractVector{Float32},
                    strtpa::Float32)
    strtpa = Float32(0)
    if i1 == 0 || i2 == 0; return; end
    for ii in i1:i2
        strtpa += tmpprb[Int(ind[ii])]
    end
    return nothing
end

# ---------------------------------------------------------------------------
# Private helper: process CCADJ activities to update CCCOEF
# ---------------------------------------------------------------------------
function UPDATECCCOEF(inicycle::Int, inba::Int)
    myacts = Int32[444]
    ntodo_r = Ref(Int32(0))
    OPFIND(1, myacts, ntodo_r)
    ntodo = Int(ntodo_r[])
    ntodo == 0 && return nothing

    prm   = zeros(Float32, 1)
    idate_r = Ref(Int32(0)); iactk_r = Ref(Int32(0)); np_r = Ref(Int32(0))
    for itodo in 1:ntodo
        OPGET(itodo, 1, idate_r, iactk_r, np_r, prm)
        Int(np_r[]) < 1 && continue
        if inicycle > 1 && inba == 1
            global CCCOEF2 = prm[1]
        else
            global CCCOEF  = prm[1]
        end
        OPDONE(1, Int(idate_r[]))
    end
    return nothing
end

# Stubs for external calls not yet translated
# COVOLP implemented in base/covolp.jl
# DBSSTRCLASS — implemented in extensions/dbs/dbsqlite.jl
# EVUST4/EVSET4 → base/evtstv.jl
# GETID/GETLUN → base/genrpt.jl
