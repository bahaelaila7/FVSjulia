# SUBROUTINE FMOLDC — record crown size info for next-cycle litterfall calculation
# Translated from: fmoldc.f (59 lines)
#
# Called from FMMAIN at end of each cycle. Saves current HT, crown length, and
# crown weights so that FMSDIT (next cycle) can compute the crown-lifting litterfall.

function FMOLDC()
    for i in 1:ITRN
        OLDHT[i]  = HT[i]
        OLDCRL[i] = HT[i] * (Float32(FMICR[i]) / 100.0f0)
        for j in 0:5
            OLDCRW[i, j+1] = CROWNW[i, j+1]
        end
    end
    return nothing
end
