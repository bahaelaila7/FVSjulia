# grincr.jl — Growth increment computation
# Translated from: base/grincr.f (567 lines)
#
# GRINCR:
#   1. Process SETSITE / PERMFRST keyword options
#   2. Root disease, fire, Silvah pre-thinning setup
#   3. Call CUTS (harvest/thinning)
#   4. Post-thin density update, cover model
#   5. Save volumes, compress tree list (COMCUP)
#   6. Bug models (MPB, DFB, TM, BWE)
#   7. DGDRIV (diameter growth), HTGF (height growth), REGENT
#   8. FIXDG / FIXHTG overrides
#   9. MORTS (mortality); optionally TRIPLE + REASS
#  10. FFERT (fertilizer)

"""
    GRINCR(debug, ipmodi, ltmgo, lmpbgo, ldfbgo, lbwego, lcvatv)

Compute per-tree growth increments for one simulation cycle.
`ipmodi=1` is normal; `ipmodi=2` skips bug models.
"""
function GRINCR(debug::Bool, ipmodi::Int32,
                ltmgo::Bool, lmpbgo::Bool, ldfbgo::Bool,
                lbwego::Bool, lcvatv::Bool)
    # FIXDG=98, FIXHTG=99, SETSITE=120, PERMFRST=445
    myacts = (Int32(98), Int32(99), Int32(120), Int32(445))
    kard   = "          "
    prm    = zeros(Float32, 6)
    stagea = Float32(0.0); stageb = Float32(0.0)

    # Set cycle length
    if ICYC >= Int32(2)
        global OLDFNT = IY[ICYC] - IY[ICYC-1]
    else
        global OLDFNT = FINT
    end
    global IFINT = IY[ICYC+1] - IY[ICYC]
    global FINT  = IFINT

    OPCSET(ICYC)

    global LTRIP = (ICYC <= ICL4 && ITRN <= (MAXTRE ÷ 3) && !NOTRIP)

    istopres = fvsGetRestartCode()
    if debug
        @printf(io_units[JOSTND], "\n IN GRINCR, ICYC=%3d; ISTOPRES=%3d; NPLT=%s\n",
                ICYC, istopres, NPLT)
    end

    # Computed goto: (1,16,17,71,72,1)[istopres+1]
    jump = Int32[1, 16, 17, 71, 72, 1]
    target = (istopres >= Int32(0) && istopres <= Int32(5)) ?
             jump[istopres + Int32(1)] : Int32(1)
    if target == Int32(16); @goto label_16; end
    if target == Int32(17); @goto label_17; end
    if target == Int32(71); @goto label_71; end
    if target == Int32(72); @goto label_72; end

    # -------------------------------------------------------------------------
    # 1. SETSITE option
    # -------------------------------------------------------------------------
    ntodo = OPFIND(Int32(1), Int32[myacts[3]])
    if ntodo > Int32(0)
        for itodo in Int32(1):ntodo
            idate_r = Ref(Int32(0)); iactk_r = Ref(Int32(0)); np_r = Ref(Int32(0))
            OPGET(itodo, Int32(6), idate_r, iactk_r, np_r, prm)
            if iactk_r[] < Int32(0); continue; end
            OPDONE(itodo, IY[ICYC])

            if prm[1] > Float32(0.0)
                global KODTYP = Int32(floor(prm[1]))
                kard   = "         "
                global CPVREF = "          "
                HABTYP(kard, prm[1])
                if KODTYP > Int32(0); global ICL5 = KODTYP; end
                for i in Int32(1):MAXPLT
                    IPHAB[i] = ITYPE
                end
                if debug
                    @printf(io_units[JOSTND],
                        " IN GRINCR PROCESSING SETSITE HABITAT TYPE: KODTYP,ICL5,ITYPE= %d%d%d\n",
                        KODTYP, ICL5, ITYPE)
                end
            end

            if prm[2] > Float32(0.0)
                global BAMAX  = prm[2]
                global LBAMAX = true
                if debug
                    @printf(io_units[JOSTND],
                        " IN GRINCR PROCESSING SETSITE BASAL AREA MAXIMUM = %9.4f  LBAMAX = %s\n",
                        BAMAX, LBAMAX)
                end
            end

            is = Int32(floor(prm[3]))
            if is < Int32(0)
                igrp = -is
                iulim = ISPGRP[igrp, 1] + Int32(1)
                if ISISP == Int32(0); global ISISP = ISPGRP[igrp, 2]; end
                global LSITE = true
                for ig in Int32(2):iulim
                    igsp = ISPGRP[igrp, ig]
                    if prm[5] == Float32(0.0)
                        if prm[4] > Float32(0.0); SITEAR[igsp] = prm[4]; end
                    else
                        if prm[4] != Float32(0.0)
                            SITEAR[igsp] += SITEAR[igsp] * prm[4] / Float32(100.0)
                        end
                    end
                    if SITEAR[igsp] < Float32(1.0); SITEAR[igsp] = Float32(1.0); end
                    if prm[6] > Float32(0.0)
                        SDIDEF[igsp] = prm[6]
                        MAXSDI[igsp] = Int32(1)
                    end
                end
            elseif is == Int32(0)
                for i in Int32(1):MAXSP
                    if prm[5] == Float32(0.0)
                        if prm[4] > Float32(0.0); SITEAR[i] = prm[4]; end
                    else
                        if prm[4] != Float32(0.0)
                            SITEAR[i] += SITEAR[i] * prm[4] / Float32(100.0)
                        end
                    end
                    if SITEAR[i] < Float32(1.0); SITEAR[i] = Float32(1.0); end
                    if prm[6] > Float32(0.0)
                        SDIDEF[i] = prm[6]
                        MAXSDI[i] = Int32(1)
                    end
                end
            else
                if prm[5] == Float32(0.0)
                    if prm[4] > Float32(0.0); SITEAR[is] = prm[4]; end
                else
                    if prm[4] != Float32(0.0)
                        SITEAR[is] += SITEAR[is] * prm[4] / Float32(100.0)
                    end
                end
                if SITEAR[is] < Float32(1.0); SITEAR[is] = Float32(1.0); end
                if prm[6] > Float32(0.0)
                    SDIDEF[is] = prm[6]
                    MAXSDI[is] = Int32(1)
                end
            end

            if debug && (prm[4] > Float32(0.0) || prm[6] > Float32(0.0))
                @printf(io_units[JOSTND],
                    " IN GRINCR PROCESSING SETSITE SITE INDEX AND/OR SDIMAX:\n")
                i = Int32(1)
                while i <= MAXSP
                    j  = i
                    jj = min(i + Int32(9), MAXSP)
                    @printf(io_units[JOSTND], "\n    SPECIES      ")
                    for k in j:jj; @printf(io_units[JOSTND], "%-8s", NSP[k,1][1:2]); end
                    @printf(io_units[JOSTND], "\n SITE INDEX  ")
                    for k in j:jj; @printf(io_units[JOSTND], "%8d", round(Int32, SITEAR[k])); end
                    @printf(io_units[JOSTND], "\n    SDI MAX  ")
                    for k in j:jj; @printf(io_units[JOSTND], "%8d", round(Int32, SDIDEF[k])); end
                    if jj == MAXSP; break; end
                    i = jj + Int32(1)
                end
                @printf(io_units[JOSTND], "\n")
            end
        end
        if ISISP > Int32(0) && ISISP <= MAXSP
            global STNDSI = SITEAR[ISISP]
        else
            global STNDSI = Float32(0.0)
        end
        RCON()
    end

    # -------------------------------------------------------------------------
    # 2. PERMFRST option (AK variant only — no-op for SN)
    # -------------------------------------------------------------------------
    ntodo = OPFIND(Int32(1), Int32[myacts[4]])
    if ntodo > Int32(0)
        for itodo in Int32(1):ntodo
            idate_r = Ref(Int32(0)); iactk_r = Ref(Int32(0)); np_r = Ref(Int32(0))
            OPGET(itodo, Int32(1), idate_r, iactk_r, np_r, prm)
            if iactk_r[] >= Int32(0)
                OPDONE(itodo, IY[ICYC])
                if prm[1] == Float32(0.0)
                    global LPERM = false
                elseif prm[1] == Float32(1.0)
                    global LPERM = true
                end
                if debug
                    @printf(io_units[JOSTND],
                        " IN GRINCR PROCESSED PERMFRST - LPERM: %s\n", LPERM)
                end
            end
        end
    end

    # -------------------------------------------------------------------------
    # 3. Pre-thinning setup
    # -------------------------------------------------------------------------
    RDMN2(OLDFNT)
    RDTRP(LTRIP)
    FMSDIT()
    SILFTY()

    if debug
        @printf(io_units[JOSTND],
            " BEFORE SDICAL, BTSDIX, SDIBC, SDIBC2, CYCLE=%9.1f%9.1f%9.1f%2d\n",
            BTSDIX, SDIBC, SDIBC2, ICYC)
    end

    global BTSDIX = SDICAL(Int32(0))
    (sdibc_v, sdibc2_v, stagea, stageb) = SDICLS(Int32(0), Float32(0.0), Float32(999.0), Int32(1), Int32(0))
    global SDIBC = sdibc_v; global SDIBC2 = sdibc2_v

    if debug
        @printf(io_units[JOSTND],
            " AFTER SDICAL, BTSDIX, SDIBC, SDIBC2, CYCLE=%9.1f%9.1f%9.1f%2d\n",
            BTSDIX, SDIBC, SDIBC2, ICYC)
    end

    iba = Int32(1)
    SSTAGE(iba, ICYC, false)

    istopres = fvsStopPoint(Int32(1))
    if istopres != Int32(0); return nothing; end
    irtncd = fvsGetRtnCode()
    if irtncd != Int32(0); return nothing; end

    @label label_16
    EVMON(Int32(1), Int32(1))

    istopres = fvsStopPoint(Int32(2))
    if istopres != Int32(0); return nothing; end
    irtncd = fvsGetRtnCode()
    if irtncd != Int32(0); return nothing; end

    @label label_17
    ECSTATUS(ICYC, NCYC, IY, Int32(0))

    if ICYC > Int32(1); SVOUT(IY[ICYC], Int32(1), "Beginning of cycle"); end

    # Save last-cycle density stats
    global OLDTPA = TPROB
    global OLDAVH = AVH
    global OLDBA  = BA
    global RELDM1 = RELDEN
    global ORMSQD = RMSQD
    global ODR016 = DR016

    if debug; @printf(io_units[JOSTND], " CALLING CUTS, CYCLE=%2d\n", ICYC); end
    CUTS()

    # Save removed TPA in WK4
    WK4[1:MAXTRE] .= WK3[1:MAXTRE]

    CVGO(lcvatv)

    if ONTREM[7] > Float32(0.0)
        if debug; @printf(io_units[JOSTND], " CALLING DENSE (POST THIN), CYCLE=%3d\n", ICYC); end
        DENSE()
    end

    # Post-thin density
    global ATAVD   = RMSQD
    global ATDR016 = DR016
    global ATAVH   = AVH
    global ATBA    = BA
    global ATCCF   = RELDEN
    global ATTPA   = TPROB
    global ATSDIX = SDICAL(Int32(0))
    (sdiac_v, sdiac2_v, stagea, stageb) = SDICLS(Int32(0), Float32(0.0), Float32(999.0), Int32(1), Int32(0))
    global SDIAC = sdiac_v; global SDIAC2 = sdiac2_v
    SILFTY()

    if ONTREM[7] > Float32(0.0) && lcvatv
        if debug; @printf(io_units[JOSTND], " CALLING CVBROW, CYCLE =%2d\n", ICYC); end
        CVBROW(true)
        if debug; @printf(io_units[JOSTND], " CALLING CVCNOP, CYCLE =%2d\n", ICYC); end
        CVCNOP(true)
    end

    iba = Int32(2)
    SSTAGE(iba, ICYC, false)

    istopres = fvsStopPoint(Int32(3))
    if istopres != Int32(0); return nothing; end
    irtncd = fvsGetRtnCode()
    if irtncd != Int32(0); return nothing; end

    @label label_71
    EVMON(Int32(2), Int32(1))

    istopres = fvsStopPoint(Int32(4))
    if istopres != Int32(0); return nothing; end
    irtncd = fvsGetRtnCode()
    if irtncd != Int32(0); return nothing; end

    @label label_72
    ECSTATUS(ICYC, NCYC, IY, Int32(1))

    # -------------------------------------------------------------------------
    # 4. Save per-tree volume history
    # -------------------------------------------------------------------------
    for i in Int32(1):ITRN
        PTOCFV[i]  = CFV[i]
        PMRCFV[i]  = MCFV[i]
        PSCFV[i]   = SCFV[i]
        PMRBFV[i]  = BFV[i]
        PDBH[i]    = DBH[i]
        PHT[i]     = HT[i]
        icdf       = (DEFECT[i] - ((DEFECT[i] ÷ Int32(10000)) * Int32(10000))) ÷ Int32(100)
        ibdf       = DEFECT[i] - ((DEFECT[i] ÷ Int32(100)) * Int32(100))
        NCFDEF[i]  = icdf
        NBFDEF[i]  = ibdf
    end

    if debug; @printf(io_units[JOSTND], " CALLING COMCUP, CYCLE=%3d\n", ICYC); end
    COMCUP()

    if ipmodi == Int32(2); @goto label_120; end

    # -------------------------------------------------------------------------
    # 5. Bug models
    # -------------------------------------------------------------------------
    if debug; @printf(io_units[JOSTND], " CALLING DFTMGO, CYCLE=%2d\n", ICYC); end
    DFTMGO(ltmgo)
    if debug; @printf(io_units[JOSTND], " CALLING MPBGO, CYCLE=%2d\n", ICYC); end
    MPBGO(lmpbgo)
    if debug; @printf(io_units[JOSTND], " CALLING DFBGO, CYCLE=%2d\n", ICYC); end
    DFBGO(ldfbgo)
    if debug; @printf(io_units[JOSTND], " CALLING BWEGO, CYCLE=%2d\n", ICYC); end
    BWEGO(lbwego)

    if ltmgo
        if debug; @printf(io_units[JOSTND], " CALLING TMBMAS, CYCLE=%2d\n", ICYC); end
        TMBMAS()
    end

    @label label_120

    # -------------------------------------------------------------------------
    # 6. Diameter and height growth
    # -------------------------------------------------------------------------
    if debug; @printf(io_units[JOSTND], " CALLING DGDRIV, CYCLE=%2d\n", ICYC); end
    DGDRIV()

    if debug; @printf(io_units[JOSTND], " CALLING HTGF, CYCLE=%2d\n", ICYC); end
    HTGF()

    if debug; @printf(io_units[JOSTND], " CALLING REGENT, CYCLE=%2d\n", ICYC); end
    REGENT(false, Int32(1))

    # -------------------------------------------------------------------------
    # 7. FIXDG option
    # -------------------------------------------------------------------------
    ntodo = OPFIND(Int32(1), Int32[myacts[1]])
    if ntodo > Int32(0)
        for itodo in Int32(1):ntodo
            idate_r = Ref(Int32(0)); iactk_r = Ref(Int32(0)); np_r = Ref(Int32(0))
            OPGET(itodo, Int32(4), idate_r, iactk_r, np_r, prm)
            if iactk_r[] < Int32(0); continue; end
            OPDONE(itodo, IY[ICYC])
            ispcc = Int32(floor(prm[1]))
            if prm[2] < Float32(0.0); prm[2] = Float32(0.0); end
            if prm[3] < Float32(0.0); prm[3] = Float32(0.0); end
            if prm[4] <= Float32(0.0); prm[4] = Float32(999.0); end
            if ITRN > Int32(0)
                for i in Int32(1):ITRN
                    lincl = false
                    if ispcc == Int32(0) || ispcc == ISP[i]
                        lincl = true
                    elseif ispcc < Int32(0)
                        igrp = -ispcc
                        iulim = ISPGRP[igrp, 1] + Int32(1)
                        for ig in Int32(2):iulim
                            if ISP[i] == ISPGRP[igrp, ig]; lincl = true; break; end
                        end
                    end
                    if lincl && prm[3] <= DBH[i] && DBH[i] < prm[4]
                        DG[i] *= prm[2]
                        if LTRIP
                            itfn = ITRN + Int32(2)*i - Int32(1)
                            DG[itfn]   *= prm[2]
                            DG[itfn+1] *= prm[2]
                        end
                    end
                end
            end
        end
    end

    # -------------------------------------------------------------------------
    # 8. FIXHTG option
    # -------------------------------------------------------------------------
    ntodo = OPFIND(Int32(1), Int32[myacts[2]])
    if ntodo > Int32(0)
        for itodo in Int32(1):ntodo
            idate_r = Ref(Int32(0)); iactk_r = Ref(Int32(0)); np_r = Ref(Int32(0))
            OPGET(itodo, Int32(4), idate_r, iactk_r, np_r, prm)
            if iactk_r[] < Int32(0); continue; end
            OPDONE(itodo, IY[ICYC])
            ispcc = Int32(floor(prm[1]))
            if prm[2] < Float32(0.0); prm[2] = Float32(0.0); end
            if ITRN > Int32(0)
                for i in Int32(1):ITRN
                    lincl = false
                    if ispcc == Int32(0) || ispcc == ISP[i]
                        lincl = true
                    elseif ispcc < Int32(0)
                        igrp = -ispcc
                        iulim = ISPGRP[igrp, 1] + Int32(1)
                        for ig in Int32(2):iulim
                            if ISP[i] == ISPGRP[igrp, ig]; lincl = true; break; end
                        end
                    end
                    if lincl && prm[3] <= DBH[i] && DBH[i] < prm[4]
                        HTG[i] *= prm[2]
                        if LTRIP
                            itfn = ITRN + Int32(2)*i - Int32(1)
                            HTG[itfn]   *= prm[2]
                            HTG[itfn+1] *= prm[2]
                        end
                    end
                end
            end
        end
    end

    # -------------------------------------------------------------------------
    # 9. Mortality
    # -------------------------------------------------------------------------
    if debug; @printf(io_units[JOSTND], " CALLING MORTS, CYCLE=%2d\n", ICYC); end
    MORTS()

    if LTRIP && ITRN > Int32(0)
        if debug; @printf(io_units[JOSTND], " CALLING TRIPLE, CYCLE=%2d\n", ICYC); end
        TRIPLE()
        global ITRN  = ITRN * Int32(3)
        if debug; @printf(io_units[JOSTND], " CALLING REASS, CYCLE=%2d\n", ICYC); end
        REASS()
        global IREC1 = IREC1 * Int32(3)
    end

    # -------------------------------------------------------------------------
    # 10. Fertilizer
    # -------------------------------------------------------------------------
    if debug; @printf(io_units[JOSTND], " CALLING FFERT, CYCLE=%2d\n", ICYC); end
    FFERT()

    return nothing
end

# RDMN2/RDTRP → base/extstubs.jl  TMBMAS → base/extstubs.jl
