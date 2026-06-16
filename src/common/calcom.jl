# CALCOM.F77 — Calibration control
# Fortran COMMON /CALCOM/ → module-level globals

FNMIN::Float32  = Float32(0.0)   # min DG obs per species to calibrate large-tree DG model
HGHCH::Float32  = Float32(0.0)
POTEN::Float32  = Float32(0.0)
REGCH::Float32  = Float32(0.0)

ICRHAB::Int32  = Int32(0)
IRHHAB::Int32  = Int32(0)
ISPCCF::Int32  = Int32(0)
ISPDSQ::Int32  = Int32(0)
ISPFOR::Int32  = Int32(0)
ISPHAB::Int32  = Int32(0)
NCALHT::Int32  = Int32(0)   # min HG obs per species to calibrate small-tree HG model

const GMULT = zeros(Float32, 2)
const REIN  = zeros(Float32, 2)
