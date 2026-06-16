# HTCAL.F77 — Height growth calibration
# Fortran COMMON /HTCAL/ → module-level globals

FINTH::Float32  = Float32(0.0)   # measurement period for small-tree HG
IFINTH::Int32   = Int32(0)       # integer version of FINTH
IHTG::Int32     = Int32(0)       # height growth version of IDG
LHCOR2::Bool    = false          # true if HCOR2 modifies HG models

const HCOR2  = zeros(Float32, MAXSP)   # user-supplied HG correction terms by species
const HSIG   = zeros(Float32, MAXSP)   # dummy (may be used for sigmas)
const LHTCAL = fill(false, MAXSP)      # true → calibrate HG for that species
