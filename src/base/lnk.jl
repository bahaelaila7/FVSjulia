# lnk.jl — Chain-sort link management
# Translated from: lnkchn.f (46 lines) + lnkint.f (37 lines)

"""
    LNKCHN(itree)

Establish tree record `itree` as a link in the species chain sort.
Updates IBEGIN, IND2, KPTR, IUSED, IREF, KOUNT arrays.
"""
function LNKCHN(itree::Int32)
    global NUMSP
    ii = ISP[itree]
    if IBEGIN[ii] != Int32(0)
        @goto label_30
    end
    IBEGIN[ii] = itree
    NUMSP = NUMSP + Int32(1)
    IUSED[NUMSP] = NSP[ii, 1]
    IREF[ii] = NUMSP
    @goto label_40

    @label label_30
    kptrii = KPTR[ii]
    IND2[kptrii] = itree

    @label label_40
    KPTR[ii] = itree
    ir = IREF[ii]
    KOUNT[ir] = KOUNT[ir] + Int32(1)

    return nothing
end

"""
    LNKINT()

Initialize species chain-sort arrays: NUMSP=0, ISCT, IBEGIN, IREF, KOUNT all zero.
"""
function LNKINT()
    global NUMSP = Int32(0)
    for i in Int32(1):MAXSP
        ISCT[i, 1] = Int32(0)
        ISCT[i, 2] = Int32(0)
        IBEGIN[i]  = Int32(0)
        IREF[i]    = Int32(0)
        KOUNT[i]   = Int32(0)
    end
    return nothing
end
