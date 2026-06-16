# MULTCM.F77 — Species-specific growth multipliers
# Fortran COMMON /MULTCM/ → module-level globals

const XDMULT = ones(Float32, MAXSP)   # diameter growth multiplier (default 1.0)
const XHMULT = ones(Float32, MAXSP)   # height growth multiplier
const XMDIA1 = zeros(Float32, MAXSP)  # lower DBH limit for mortality multiplier
const XMDIA2 = fill(Float32(999.0), MAXSP) # upper DBH limit for mortality multiplier
const XMMULT = ones(Float32, MAXSP)   # mortality multiplier
const XRDMLT = ones(Float32, MAXSP)   # small tree DG multiplier
const XRHMLT = ones(Float32, MAXSP)   # small tree HG multiplier
