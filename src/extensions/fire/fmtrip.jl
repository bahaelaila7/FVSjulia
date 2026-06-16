# fmtrip.f — Copy and scale fire model tree arrays when tripling tree records
# FMTRIP: called from TRIPLE; new record ITFN gets attributes of I scaled by WEIGHT

function FMTRIP(itfn::Integer, i::Integer, weight::Real)
    if !LFMON; return nothing; end

    FMPROB[itfn]  = FMPROB[i] * Float32(weight)
    FMICR[itfn]   = FMICR[i]
    OLDHT[itfn]   = OLDHT[i]
    OLDCRL[itfn]  = OLDCRL[i]
    GROW_FM[itfn] = GROW_FM[i]

    for jj in 0:5
        OLDCRW[itfn, jj+1] = OLDCRW[i, jj+1]
        CROWNW[itfn, jj+1] = CROWNW[i, jj+1]
    end
    return nothing
end
