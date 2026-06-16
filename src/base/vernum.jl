# vernum.jl — VERNUM / VERNUM2 / VERNUM_F: volume library version number
# Translated from: vernum.f (230 lines)
# Version is an integer date YYYYMMDD.

function VERNUM(version_ref::Ref{Int32})
    version_ref[] = Int32(20260209)
    return nothing
end

function VERNUM2(version_ref::Ref{Int32})
    version_ref[] = Int32(20260209)
    return nothing
end

function VERNUM_F(version_ref::Ref{Int32})
    version_ref[] = Int32(20260209)
    @printf(stdout, "%8d\n", 20260209)
    return nothing
end

function vernum_r(version_ref::Ref{Int32})
    version_ref[] = Int32(20260209)
    return nothing
end
