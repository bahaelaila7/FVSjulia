# SUBROUTINE FMKILL(ICALL) — convert fire mortality estimates into FVS rates
# Translated from: fmkill.f (159 lines)
#
# ICALL=1: update WK2 from FIRKIL, activate sprouting, adjust crown ratios
# ICALL=2: pass excess background mortality (WK2 > FIRKIL) to snag model,
#          group new snags, then zero FIRKIL; mark end of first master cycle.

function FMKILL(icall::Integer)
    local debug::Bool = false
    DBCHK(Ref(debug), "FMKILL", Int32(6), ICYC)
    if debug
        @printf(io_units[Int32(JOSTND)], " ENTERING FMKILL CYCLE = %2d LFMON=%s\n",
                ICYC, LFMON)
    end

    if !LFMON; return; end

    if icall == 1

        # Sprout age: prefer simulated fire; fall back to pile burn
        local ishag::Int32
        if (IY[ICYC+1] - BURNYR) <= IFINT
            ishag = IY[ICYC+1] - BURNYR
        else
            ishag = IY[ICYC+1] - PBURNYR
        end

        for i in 1:ITRN
            if debug
                @printf(io_units[Int32(JOSTND)],
                        " IN FMKILL(1), I=%4d PROB=%10.4f FIRKIL=%10.4f WK2=%10.4f FMICR=%3d ICR=%3d\n",
                        i, PROB[i], FIRKIL[i], WK2[i], FMICR[i], ICR[i])
            end

            # Clamp fire kill to available trees
            if FIRKIL[i] > PROB[i]
                FIRKIL[i] = PROB[i]
            end

            # Add killed trees to regeneration sprout list
            if FIRKIL[i] > 0.00001f0
                ESTUMP(ISP[i], DBH[i], FIRKIL[i], ITRE[i], ishag)
            end

            # Fire model mortality wins if it exceeds FVS background rate
            if FIRKIL[i] > WK2[i]
                WK2[i] = FIRKIL[i]
            end

            # If fire model changed crown ratios, pass new values to FVS
            # (negative ICR signals FVS not to recalculate next cycle)
            if FMICR[i] < 1
                FMICR[i] = Int32(1)
            end
            if FMICR[i] < abs(ICR[i])
                ICR[i] = -FMICR[i]
                if debug
                    @printf(io_units[Int32(JOSTND)],
                            " IN FMKILL CROWN CHANGED, I=%4d FMICR=%3d ICR=%3d\n",
                            i, FMICR[i], ICR[i])
                end
            end
        end

    elseif icall == 2

        for i in 1:ITRN
            if debug
                @printf(io_units[Int32(JOSTND)],
                        " IN FMKILL(2), I=%4d PROB=%10.4f FIRKIL=%10.4f WK2=%10.4f FMICR=%3d ICR=%3d\n",
                        i, PROB[i], FIRKIL[i], WK2[i], FMICR[i], ICR[i])
            end

            # Background mortality exceeds fire mortality: pass the extra to snag model
            # (fire-killed trees are added via FMEFFS/FMTRET; subtract to avoid double-count)
            if FIRKIL[i] < WK2[i]
                FMSSEE(i, ISP[i], DBH[i], HT[i], WK2[i] - FIRKIL[i],
                       Int32(1), debug, Int32(JOSTND))
            end
        end

        # Group new snags by species/DBH/HT and collect canopy material
        local year::Int32 = IY[ICYC+1] - Int32(1)
        FMSADD(year, Int32(4))

        # Zero fire model mortality array now that it has been processed
        for i in 1:ITRN
            FIRKIL[i] = Float32(0.0)
        end

        # Mark completion of first master cycle
        if LFMON2
            global LFMON2 = false
        end

    end

    return nothing
end
