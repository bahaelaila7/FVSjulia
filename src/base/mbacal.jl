# base/mbacal.jl — MBACAL: identify site species (max basal area)
# Translated from: bin/FVSsn_buildDir/mbacal.f (70 lines)
#
# Sets ISISP to the species with greatest basal area, unless LSITE or
# ISISP are already set. Called from DENSE and CRATET.

function MBACAL()
    if LSITE; return nothing; end
    if ITRN <= Int32(0) || ISISP > Int32(0); return nothing; end

    # Accumulate BA by species
    for ispc in 1:Int(MAXSP)
        i1 = Int(ISCT[ispc, 1])
        if i1 == 0; continue; end
        i2 = Int(ISCT[ispc, 2])
        for ii in i1:i2
            i_t = Int(IND1[ii])
            if i_t >= Int(IREC2); continue; end   # skip dead trees
            p = PROB[i_t]; d = DBH[i_t]
            BARANK[ispc] += Float32(0.005454154) * p * d * d
        end
    end

    # Find species with maximum BA
    mdx  = Int32(0); xmax = Float32(0)
    for i in 1:Int(MAXSP)
        if BARANK[i] <= xmax; continue; end
        mdx = Int32(i); xmax = BARANK[i]
    end
    global ISISP = mdx

    return nothing
end
