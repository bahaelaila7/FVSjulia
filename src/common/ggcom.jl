# GGCOM.F77 — GENGYM-derived variant variables (bark beetle / general)
# Fortran COMMON /GGCOM/ → module-level globals

# Scalar values
AGERNG::Float32 = Float32(0.0)   # age range between largest and smallest tree > 4.5ft
BAINIT::Float32 = Float32(0.0)   # initial BA of stand
DSTAG::Float32  = Float32(1.0)   # stagnation multiplier (reduces growth+mortality)
IGFOR::Int32    = Int32(0)       # number of R2 forests + 1
SEEDS::Float32  = Float32(0.0)   # trees/acre in seedlings (<4.5ft)
TPAT::Float32   = Float32(0.0)   # total trees per acre

# Per-species arrays
const BARK1  = zeros(Float32, MAXSP)
const BARK2  = zeros(Float32, MAXSP)
const BREAK  = zeros(Float32, MAXSP)   # breakpoint DBH large/small trees
const DBHMAX = zeros(Float32, MAXSP)   # maximum DBH used in GEMDG
const SITEHI = zeros(Float32, MAXSP)   # upper valid site index range
const SITELO = zeros(Float32, MAXSP)   # lower valid site index range
const TBA    = zeros(Float32, MAXSP)   # total BA by species

# BAU(41) — total BA above subject DBH class (41 = MAXCY1 = MAXCYC+1)
const BAU = zeros(Float32, 41)

# 2-D arrays indexed by (species, 41-diameter-classes)
const BCLAS = zeros(Float32, MAXSP, 41)   # BA by species by 1-inch diameter class
const TCLAS = zeros(Float32, MAXSP, 41)   # TPA by species by diameter class
