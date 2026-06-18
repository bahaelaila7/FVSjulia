# SUBROUTINE FMCADD — annual litterfall, crown breakage, and CWD debris-in-waiting
# Translated from: fmcadd.f (181 lines)
#
# Called from FMMAIN inner year loop. Adds foliage litterfall, random woody breakage,
# and crown-lifting material to down debris pools, then processes the year-1 CWD2B
# (snag material ready to fall) and shifts all CWD2B pools forward one year.
#
# Index notes:
#   CROWNW/OLDCRW: Fortran J=0..5 → Julia j+1 (1..6); class 0=foliage, 1-5=woody
#   CWD2B:         Fortran SIZE=0..5 → Julia SIZE+1 (1..6)

function FMCADD()
    local debug::Bool = false
    debug = DBCHK(false, "FMCADD", Int32(6), ICYC)
    if debug
        @printf(io_units[Int32(JOSTND)], " ENTERING FMCADD CYCLE = %2d NYRS=%4d TFMAX=%4d\n",
                ICYC, NYRS, TFMAX)
    end

    # Per-tree litterfall and crown breakage
    for i in 1:ITRN
        if FMPROB[i] > 0.0f0
            local sp::Int32   = ISP[i]
            local dkcl::Int32 = DKRCLS[sp]

            # Foliage litterfall (crown class 0 → Julia index 1)
            local litter::Float32 = (CROWNW[i, 1] * FMPROB[i] / LEAFLF[sp]) * P2T
            CWD[1, 10, 2, dkcl] += litter
            CWDNEW[1, 10]        += litter

            for sz in 1:5
                # Random breakage of woody crown component (classes 1-5 → Julia index sz+1)
                local amt::Float32 = (LIMBRK * FMPROB[i] * CROWNW[i, sz+1]) * P2T
                CWD[1, sz, 2, dkcl] += amt
                CWDNEW[1, sz]        += amt

                # Crown-lifting material (old crown that fell due to lift this cycle).
                # Apply minimum threshold: < 0.001 oz/acre → zero (avoids float errors).
                if (FMPROB[i] * OLDCRW[i, sz+1]) < 0.0000625f0
                    amt = Float32(0.0)
                else
                    amt = (FMPROB[i] * OLDCRW[i, sz+1]) * P2T
                end
                CWD[1, sz, 2, dkcl] += amt
                CWDNEW[1, sz]        += amt
            end
        end
    end

    # Add debris-in-waiting from snags: take the entire year-1 pool of CWD2B
    local iyr::Int32   = Int32(1)
    local pdown::Float32 = 1.0f0

    for dkcl in 1:4
        # Foliage class (SIZE=0 → Julia index 1)
        local down::Float32 = pdown * CWD2B[dkcl, 1, iyr] / Float32(NYRS)
        CWD[1, 10, 2, dkcl] += down / 2000.0f0
        CWDNEW[1, 10]        += down / 2000.0f0
        CWD2B[dkcl, 1, iyr]  -= down

        # Woody classes (SIZE=1..5 → Julia index sz+1)
        for sz in 1:5
            down = pdown * CWD2B[dkcl, sz+1, iyr] / Float32(NYRS)
            CWD[1, sz, 2, dkcl] += down / 2000.0f0
            CWDNEW[1, sz]        += down / 2000.0f0
            CWD2B[dkcl, sz+1, iyr] -= down
        end
    end

    if debug
        println(io_units[Int32(JOSTND)], "BEFORE POOLS ARE MOVED FORWARD")
        for dkcl in 1:4, sz in 0:5, yr in 1:(TFMAX-1)
            @printf(io_units[Int32(JOSTND)],
                    " FMCADD: DKCL,SIZE,IYR=%3d%3d%3d CWD2B=%12.2f CWD2B2=%12.2f\n",
                    dkcl, sz, yr, CWD2B[dkcl, sz+1, yr], CWD2B2[dkcl, sz+1, yr])
        end
    end

    # Shift all debris-in-waiting pools one year forward
    for dkcl in 1:4
        for sz in 0:5
            for yr in 1:(TFMAX-1)
                CWD2B[dkcl, sz+1, yr] = CWD2B[dkcl, sz+1, yr+1]
            end
            CWD2B[dkcl, sz+1, TFMAX] = Float32(0.0)
        end
    end

    if debug
        println(io_units[Int32(JOSTND)], "AFTER POOLS ARE MOVED FORWARD")
        for dkcl in 1:4, sz in 0:5, yr in 1:(TFMAX-1)
            @printf(io_units[Int32(JOSTND)],
                    " FMCADD: DKCL,SIZE,IYR=%3d%3d%3d CWD2B=%12.2f CWD2B2=%12.2f\n",
                    dkcl, sz, yr, CWD2B[dkcl, sz+1, yr], CWD2B2[dkcl, sz+1, yr])
        end
    end

    return nothing
end
