# base/dbchk.f — DBCHK: check if subroutine SUBIN is in the debug stack
# Translated from: bin/FVSsn_buildDir/dbchk.f (31 lines)
#
# Julia adaptation: returns Bool instead of setting the first arg by reference.
# The existing 2-arg stub DBCHK(name, cyc) = false in intree.jl handles the
# 2-arg calling convention used in comprs.jl and opnew.jl.
# This 4-arg version handles calls from initre.jl and the Fortran-style callers.

function DBCHK(ldebg_in::Bool, subin::AbstractString, nc::Integer, icyc::Integer)::Bool
    result = false
    if ITOP > Int32(0)
        r = Ref(false)
        DBSCAN(r, ALLSUB, Int32(6), Int32(0))
        if !r[]; DBSCAN(r, ALLSUB, Int32(6), Int32(icyc)); end
        if !r[]; DBSCAN(r, subin,  Int32(nc), Int32(icyc)); end
        result = r[]
    end
    return result
end

# 2-arg convenience overload (common calling pattern in translated files)
function DBCHK(subin::AbstractString, nc::Integer)::Bool
    return DBCHK(false, subin, nc, Int(ICYC))
end
