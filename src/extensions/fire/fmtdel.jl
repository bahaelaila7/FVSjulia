# fmtdel.f — Copy fire model tree arrays when a tree record is deleted
# FMTDEL: called from TREDEL; copies record IREC → slot IVAC
# JJ=0:5 in Fortran → JJ+1 in Julia (CROWNW/OLDCRW size class index)

function FMTDEL(ivac::Integer, irec::Integer)
    if !LFMON; return nothing; end

    FMPROB[ivac] = FMPROB[irec]
    FMICR[ivac]  = FMICR[irec]
    OLDHT[ivac]  = OLDHT[irec]
    OLDCRL[ivac] = OLDCRL[irec]
    GROW_FM[ivac] = GROW_FM[irec]

    for jj in 0:5
        OLDCRW[ivac, jj+1] = OLDCRW[irec, jj+1]
        CROWNW[ivac, jj+1] = CROWNW[irec, jj+1]
    end
    return nothing
end
