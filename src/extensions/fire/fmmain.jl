# SUBROUTINE FMMAIN — main fire driver, called once per cycle from GRADD
# Translated from: fmmain.f (272 lines)
#
# Loops over years in cycle, running fuel/snag/burn sub-models.
# All sub-routines (FMCBA, FMBURN, FMSNAG, FMCWD, etc.) are stubbed
# in extstubs.jl until their files are translated.

function FMMAIN()
    local debug::Bool = false
    DBCHK(Ref(debug), "FMMAIN", Int32(6), ICYC)
    if debug
        @printf(io_units[Int32(JOSTND)], " ENTERING FMMAIN CYCLE = %2d LFMON=%s\n",
                ICYC, LFMON)
    end

    if !LFMON; return; end

    # Event monitor fire variable — 420, index 20: 0=no fire, 1=fire occurred
    EVSET4(Int32(20), Float32(0.0))
    global LFIRE = false

    global NYRS = IY[ICYC+1] - IY[ICYC]

    global IFMYR1 = IY[ICYC]
    global IFMYR2 = IY[ICYC+1] - 1
    if debug
        @printf(io_units[Int32(JOSTND)], " IN FMMAIN IFMYR1 IFMYR2 BURNYR ITRN= %5d%5d%5d%5d\n",
                IFMYR1, IFMYR2, BURNYR, ITRN)
    end

    # Process FMORTMLT keyword (activity 2554) — per-species/DBH mortality multiplier
    fill!(FMORTMLT, Float32(1.0))
    myacts = Int32[2554]
    ntodo_ref = Ref(Int32(0))
    OPFIND(Int32(1), myacts, ntodo_ref)
    ntodo = ntodo_ref[]
    if ntodo > 0
        idsp_ref = Ref(Int32(0))
        iact_ref = Ref(Int32(0))
        nprm_ref = Ref(Int32(0))
        prms     = zeros(Float32, 4)
        for itodo in 1:ntodo
            OPGET(Int32(itodo), Int32(4), idsp_ref, iact_ref, nprm_ref, prms)
            OPDONE(Int32(itodo), IY[ICYC])
            idsp = Int32(floor(prms[2]))
            for i in 1:ITRN
                if idsp != 0 && ISP[i] != idsp; continue; end
                if DBH[i] >= prms[3] && DBH[i] < prms[4]
                    FMORTMLT[i] = prms[1]
                end
            end
            if debug
                @printf(io_units[Int32(JOSTND)],
                        " FMORTMLT SET TO%10.4f FOR SPECIES I=%3d MIND=%6.2f MAXD=%7.1f\n",
                        prms[1], idsp, prms[3], prms[4])
            end
        end
    end

    iyr = IFMYR1

    if debug
        @printf(io_units[Int32(JOSTND)], " IN FMMAIN IYR BURNYR= %5d%5d\n", iyr, BURNYR)
    end

    # Initialize crown/mortality arrays for this cycle
    for i in 1:ITRN
        FMPROB[i] = PROB[i]
        FMICR[i]  = ICR[i]
        FIRKIL[i] = Float32(0.0)
    end

    # Initialize smoke / burn pools
    SMOKE[1]  = Float32(0.0)
    SMOKE[2]  = Float32(0.0)
    global CRBURN  = Float32(0.0)
    global BURNCR  = Float32(0.0)
    global PBRNCR  = Float32(0.0)
    for il in 1:MXFLCL
        BURNED[1, il] = Float32(0.0)
        BURNED[2, il] = Float32(0.0)
        BURNED[3, il] = Float32(0.0)
    end
    BURNLV[1] = Float32(0.0)
    BURNLV[2] = Float32(0.0)

    # Compute dominant cover type by basal area
    FMCBA(Int32(iyr), Int32(0))

    # Fuel treatments (jackpot burns, pile burns)
    FMTRET(Int32(iyr))

    # FuelMove keyword
    FMFMOV(Int32(iyr))

    # User-specified fuel model definitions
    local fmd_ref = Ref(Int32(0))
    FMUSRFM(Int32(iyr), fmd_ref)
    local fmd = fmd_ref[]

    # Simulate actual fires
    FMBURN(Int32(iyr), Int32(fmd), true)

    # Output: snag list, potential fire, fuel table, carbon reports
    FMSOUT(Int32(iyr))
    FMSSUM(Int32(iyr))
    FMPOCR(Int32(iyr), Int32(2))
    if BURNYR == iyr
        FMCFMD3(Int32(iyr), Int32(fmd))
    end
    FMPOFL(Int32(iyr), Int32(fmd), true)
    irtncd_ref = Ref(Int32(0))
    fvsGetRtnCode(irtncd_ref)
    if irtncd_ref[] != 0; return; end
    FMDOUT(Int32(iyr))
    FMCRBOUT(Int32(iyr))
    FMCHRVOUT(Int32(iyr))
    EVTSTV(Int32(iyr))

    # Update snag and CWD pools for each year in the cycle
    global NYRS = Int32(1)
    for iyr2 in IFMYR1:IFMYR2
        FMSNAG(Int32(iyr2), IY[1])
        FMCWD(Int32(iyr2))
        FMCADD()

        # Merge CWD2B2 (new debris from snags killed last year) into CWD2B
        for isz in 1:6          # Fortran 0:5 → Julia 1:6
            for idc in 1:4
                for itm in 1:TFMAX
                    CWD2B[idc, isz, itm]  += CWD2B2[idc, isz, itm]
                    CWD2B2[idc, isz, itm]  = Float32(0.0)
                end
            end
        end
    end

    global NYRS = IY[ICYC+1] - IY[ICYC]

    # Record crown size for next cycle's litterfall calculation
    FMOLDC()

    FMSVSYNC()

    return nothing
end
