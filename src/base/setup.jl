# setup.f — SETUP: build IND1 flat index from IND2 linked chains
# Translated from: bin/FVSsn_buildDir/setup.f (60 lines)
#
# Walks each species' linked chain (IBEGIN + IND2) and populates
# IND1 in contiguous species blocks; also sets ITRN = total active records.

function SETUP()
    if IREC1 <= Int32(0)
        global ITRN = Int32(0)
        return nothing
    end

    ix   = 1
    last = Int32(0)

    for i in 1:MAXSP
        ir = IREF[i]
        ir == Int32(0) && continue
        knt = KOUNT[ir]
        ISCT[i, 1] = last + Int32(1)
        last       = last + knt
        ISCT[i, 2] = last
        istart     = IBEGIN[i]
        IND1[ix]   = istart
        ix += 1
        knt == Int32(1) && continue
        nxt = IND2[istart]
        for j in 2:knt
            IND1[ix] = nxt
            ix += 1
            j == knt && break
            nxt = IND2[nxt]
        end
    end

    global ITRN = last
    return nothing
end
