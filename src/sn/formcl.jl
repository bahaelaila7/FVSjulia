# sn/formcl.f — FORMCL: return form class for species (sn override)
# Translated from: bin/FVSsn_buildDir/formcl.f (41 lines)
#
# The sn variant is identical to the base "vanilla" version:
# just loads FC from FRMCLS[ISPC]; D and IFOR are unused.

function FORMCL(ispc::Int32, ifor::Int32, d::Float32, fc::Ref{Float32})
    fc[] = FRMCLS[ispc]
    return nothing
end
