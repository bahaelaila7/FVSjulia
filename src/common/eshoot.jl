# ESHOOT.F77 — Establishment stump sprout data
# Fortran COMMON /ESHOOT/ → module-level globals

ASBAR::Float32  = Float32(0.0)   # aspen BA removed for sprouting
ASTPAR::Float32 = Float32(0.0)   # aspen TPA removed for sprouting

# Per-tree arrays
const ISHOOT = zeros(Int32, MAXTRE)    # encoded stump: diam_class*1e6 + species*1e3 + plot
const JSHAGE = zeros(Int32, MAXTRE)    # age of sprouts at end of creation cycle
const DSTUMP = zeros(Float32, MAXTRE)  # DBH of cut/killed tree
const PRBREM = zeros(Float32, MAXTRE)  # PROB removed when tree was cut
