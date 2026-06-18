# base/esnutr.jl — ESNUTR: per-cycle interface coupling the regen model to FVS.
# Translated from: bin/FVSsn_buildDir/esnutr.f (350 lines)
#
# Called once per cycle from GRADD. Processes SPECMULT/STOCKADJ/HTADJ options,
# decides whether the establishment model runs this cycle (TALLY / PLANT triggers),
# and calls ESTAB(KDT) to create new trees.
#
# Sprouting (LSPRUT/ITRNRM>=1) is NEVER exercised by snt01 — ESUCKR is never called
# (loblolly pine doesn't stump-sprout, so the cut routine leaves ITRNRM=0). For
# stands with no establishment keywords (1-4) ESNUTR is a clean no-op (→ label_400).
#
# Structured flat (no `let` blocks) so the @label/@goto control flow stays at
# function scope.

function ESNUTR()
    nclas  = Int32(floor(Float32(MAXTRE) * 0.4f0))
    iestb  = Int32[427, 428, 429]
    myact2 = Int32[95, 440, 442, 430, 431]
    lone   = false
    debug  = DBCHK(false, "ESNUTR", Int32(6), Int(ICYC))
    prms   = zeros(Float32, 3)
    ntodo  = Int32(0)
    kdt    = Int32(0)
    iactk  = Int32(0); idt = Int32(0); np = Int32(0)

    ESADDT(Int32(1))   # ADDTREES from external source (stub; not used by snt01)

    # ---- SPECMULT (95) / STOCKADJ (440) / HTADJ (442) ----
    ntodo = OPFIND(Int32(3), @view(myact2[1:3]))
    if ntodo > Int32(0)
        kdt = IY[Int(ICYC)]
        for i in 1:Int(ntodo)
            iactk, idt, np = OPGET(Int32(i), Int32(2), prms)
            if iactk < Int32(0); continue; end
            if iactk == Int32(95)
                j = Int(trunc(prms[1]))
                if j < 0
                    igrp = -j; iulim = Int(ISPGRP(Int32(igrp), Int32(1))) + 1
                    for ig in 2:iulim; XESMLT[Int(ISPGRP(Int32(igrp), Int32(ig)))] = prms[2]; end
                elseif j == 0
                    for jj in 1:Int(MAXSP); XESMLT[jj] = prms[2]; end
                else
                    XESMLT[j] = prms[2]
                end
            elseif iactk == Int32(440)
                global STOADJ = prms[1]
            elseif iactk == Int32(442)
                j = Int(trunc(prms[1]))
                if j < 0
                    igrp = -j; iulim = Int(ISPGRP(Int32(igrp), Int32(1))) + 1
                    for ig in 2:iulim; HTADJ[Int(ISPGRP(Int32(igrp), Int32(ig)))] = prms[2]; end
                elseif j == 0
                    for jj in 1:Int(MAXSP); HTADJ[jj] = prms[2]; end
                else
                    HTADJ[j] = prms[2]
                end
            end
            OPDONE(Int32(i), kdt)
        end
    end

    # Default date of disturbance / last removal to 20 yr before inventory.
    if IDSDAT == Int32(-9999); global IDSDAT = IY[1] - Int32(20); end
    if IYRLRM == Int32(-9999); global IYRLRM = IY[1] - Int32(20); end
    if ONTREM[7] > Float32(0.0); global IYRLRM = IY[Int(ICYC)]; end

    # ---- sprouting (never fires for snt01: ITRNRM=0) ----
    if LSPRUT
        if ITRNRM >= Int32(1)
            if Int(ITRN) + Int(ITRNRM) > Int(MAXTRE)
                itrgt = MAXTRE - ITRNRM
                if nclas > itrgt; itrgt = nclas; end
                ESCPRS(itrgt, debug)
            end
            ESUCKR()
            global IREC1 = ITRN
            SPESRT()
            if ITRN > Int32(0); RDPSRT(ITRN, DBH, IND, true); end
            global IFST = Int32(1)
        end
    else
        global ITRNRM = Int32(0)
    end

    kdt = IY[Int(ICYC)+1] - Int32(1)

    # ---- find TALLYONE (428), else TALLYTWO (429) ----
    ntodo = OPFIND(Int32(1), @view(iestb[2:2]))
    if ntodo == Int32(0)
        ntodo = OPFIND(Int32(1), @view(iestb[3:3]))
        if ntodo == Int32(0); @goto label_100; end
    end
    iactk, idt, np = OPGET(ntodo, Int32(1), prms)
    if iactk < Int32(0); @goto label_100; end
    global NTALLY = iactk - Int32(427)
    global IDSDAT = Int32(trunc(prms[1]))
    lone = true
    if IDSDAT < Int32(1000) && IDSDAT >= Int32(1); global IDSDAT = IY[Int(IDSDAT)]; end
    if kdt + Int32(1) - IDSDAT > Int32(20)
        @printf(io_units[Int(JOSTND)],
            "\nREGENERATION MODEL CANNOT PREDICT REGENERATION TALLIES BEYOND 20 YEARS FROM DATE OF DISTURBANCE\nDISTURBANCE DATE=%6d  TALLY DATE=%6d  TALLY=%3d\n",
            IDSDAT, kdt, NTALLY)
        @goto label_300
    end
    if NTALLY == Int32(2)
        isqr = Ref(Int32(0)); nt = Ref(Int32(0)); idtr = Ref(Int32(0))
        np1 = Ref(Int32(0)); ist = Ref(Int32(0)); kd = Ref(Int32(0))
        OPSTUS(Int32(428), IDSDAT, kdt, isqr, nt, idtr, np1, ist, kd)
        if kd[] > Int32(0) || ist[] <= IDSDAT
            @printf(io_units[Int(JOSTND)], "\nTALLYTWO CHANGED TO TALLYONE. YEAR=%4d\n", IY[Int(ICYC)+1]-Int32(1))
            global NTALLY = Int32(1)
        end
    end
    @goto label_200

    @label label_100
    # ---- check for TALLY (427) ----
    ntodo = OPFIND(Int32(1), @view(iestb[1:1]))
    if ntodo > Int32(0)
        global IDSDAT = Int32(-1)
        isqv = 0
        for itodo in 1:Int(ntodo)
            iactk, idt, np = OPGET(Int32(itodo), Int32(1), prms)
            if iactk < Int32(0); break; end
            ii = Int(trunc(prms[1]))
            if Int32(ii) > IDSDAT
                global IDSDAT = Int32(ii); isqv = itodo
            end
        end
        if IDSDAT < Int32(1000) && IDSDAT >= Int32(1); global IDSDAT = IY[Int(IDSDAT)]; end
        if kdt + Int32(1) - IDSDAT > Int32(20)
            @printf(io_units[Int(JOSTND)],
                "\nREGENERATION MODEL CANNOT PREDICT REGENERATION TALLIES BEYOND 20 YEARS FROM DATE OF DISTURBANCE\nDISTURBANCE DATE=%6d  TALLY DATE=%6d  TALLY=%3d\n",
                IDSDAT, kdt, NTALLY)
            @goto label_300
        end
        ntodo = Int32(isqv)
        global NTALLY = Int32(1)
        @goto label_200
    end

    # label 120: no tally — trigger ESTAB if within 20 yr or PLANT/NATURAL present
    ntodo = Int32(0)
    if kdt - IDSDAT <= Int32(19) && NTALLY > Int32(0)
        prms[1] = Float32(IDSDAT)
        global NTALLY = NTALLY + Int32(1)
        prms[2] = Float32(NTALLY)
        kdt = IY[Int(ICYC)+1] - Int32(1)
        kode_r = Ref(Int32(0))
        OPADD(kdt, iestb[1], kdt, Int32(2), prms, kode_r)
        @goto label_200
    end
    npnats = OPFIND(Int32(2), @view(myact2[4:5]))
    if npnats > Int32(0)
        global NTALLY = Int32(1)
        global IDSDAT = IY[Int(ICYC)+1] - Int32(20)
        @goto label_200
    end
    @goto label_400

    # ---- common ESTAB calling sequence ----
    @label label_200
    if IYRLRM < IDSDAT; global IYRLRM = IDSDAT; end
    if IPINFO >= Int32(4)
        @printf(io_units[Int(JOSTND)], "\nNOTE: NONE OF THE PLOTS ARE STOCKABLE.  STAND ID: %s; YEAR=%5d\n",
            strip(NPLT), IY[Int(ICYC)+1]-Int32(1))
        @goto label_300
    end
    if ntodo > Int32(0); OPDONE(ntodo, kdt); end
    if Float32(ITRN) > Float32(MAXTRE)*0.7f0 && ntodo > Int32(0); ESCPRS(nclas, debug); end

    ESTAB(kdt)

    if ITRN > Int32(0); RDPSRT(ITRN, DBH, IND, true); end
    global IFST = Int32(1)
    if lone; global NTALLY = Int32(0); end

    @label label_300
    ntodo = OPFIND(Int32(3), iestb)
    if ntodo > Int32(0)
        for i in 1:Int(ntodo); OPDEL1(Int32(i)); end
    end

    @label label_400
    return nothing
end
