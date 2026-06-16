# comcup.jl — COMCUP: interface coupling compression routine to simulation loop
# Translated from: comcup.f (208 lines)
#
# Deletes zero-PROB trees, then checks for a COMPRESS keyword (act=250),
# compresses to the target tree count, and reestablishes sort / statistics.

function COMCUP()
    debug = DBCHK(false, "COMCUP", Int32(6), ICYC)
    io = io_units[Int32(JOSTND)]

    # Check for zero-probability trees; build IND2
    lcmprs = false
    ndel   = 0
    if ITRN > Int32(0)
        for i in 1:Int(ITRN)
            if PROB[i] <= Float32(1e-5)
                IND2[i] = Int32(-i)
                ndel += 1
            else
                IND2[i] = Int32(i)
            end
        end
    end

    # If all trees have zero PROB, zero ITRN
    if ndel == Int(ITRN)
        global ITRN  = Int32(0)
        global IREC1 = Int32(0)
    end
    if debug; @printf(io, "\n IN COMCUP (TOP): ITRN,NDEL=%6d%6d\n", ITRN, ndel); end

    # Delete zero-PROB trees
    if ndel > 0 && ITRN > Int32(0)
        TREDEL(ndel, IND2)
    end

    # Check for COMPRESS activity (act=250)
    myact = Int32[250]
    ntodo = Ref(Int32(0))
    OPFIND(Int32(1), myact, ntodo)

    itarg = Int32(0); pn1 = Float32(0)
    if ntodo[] > 0
        idt_r = Ref(Int32(0)); iact_r = Ref(Int32(0))
        nprms_r = Ref(Int32(0)); prms = zeros(Float32, 3)
        OPGET(ntodo[], Int32(3), idt_r, iact_r, nprms_r, prms)
        if ntodo[] > 1
            for i in 1:Int(ntodo[])-1
                OPDEL1(Int32(i))
            end
        end
        itarg = Int32(floor(prms[1]))
        pn1   = prms[2] / Float32(100)
        lcmprs = itarg < ITRN
        if debug; @printf(io, "\n IN COMCUP: ITARG,PN1,LCMPRS: %5d%8.3f%s\n", itarg, pn1, lcmprs ? " T" : " F"); end

        if lcmprs
            for i in 1:Int(ITRN); WK2[i] = Float32(0); end
            COMPRS(itarg, pn1)
            OPDONE(ntodo[], IY[Int(ICYC)])
            global NOTRIP = true
        else
            OPDEL1(ntodo[])
        end
    end

    # If compression or zero-PROB deletions occurred, re-sort and recompute stats
    if lcmprs || ndel > 0
        SPESRT()
        spcnt = zeros(Float32, Int(MAXSP), 3)
        if ITRN > Int32(0)
            for i in 1:Int(ITRN)
                is = Int(ISP[i]); im = Int(IMC[i])
                spcnt[is, im] += PROB[i]
            end
            RDPSRT(ITRN, DBH, IND, true)
            PCTILE(ITRN, IND, PROB, WK3, @view(ONTCUR[7:end]))
            # Estimate missing total tree ages
            for i in 1:Int(ITRN)
                if ABIRTH[i] <= Float32(0)
                    sitage_r = Ref(Float32(0)); sitht_r = Ref(Float32(0))
                    agmax_r  = Ref(Float32(0)); htmax_r = Ref(Float32(0)); htmax2_r = Ref(Float32(0))
                    d2 = Float32(0)
                    FINDAG(Int32(i), ISP[i], DBH[i], d2, HT[i], sitage_r, sitht_r, agmax_r, htmax_r, htmax2_r, debug)
                    if sitage_r[] > Float32(0); ABIRTH[i] = sitage_r[]; end
                end
            end
        end
        global IFST = Int32(1)
        DIST(ITRN, ONTCUR, WK3)
        COMP(OSPCT, IOSPCT, spcnt)
        DENSE()
    end

    if debug; @printf(io, "\n IN COMCUP (BOT): ITRN,NDEL=%6d%6d\n", ITRN, ndel); end
    return nothing
end
