# FMSVCM.F77 — Fire model SVS visualization scratch arrays
# Fortran COMMON /FMSVCM/ → module-level globals

const NFLPTS = Int32(20)   # number of fire line points

# Fire line position arrays (NFLPTS = 20)
const FMY1    = zeros(Float32, NFLPTS)
const FMY2    = zeros(Float32, NFLPTS)
const OFFSET  = zeros(Float32, NFLPTS)
const CATCHUP = zeros(Float32, NFLPTS)

FLPART::Float32   = Float32(0.0)   # fire line partial step
FLAMEHT::Float32  = Float32(0.0)   # flame height for SVS
IFMTYP::Int32     = Int32(0)       # fire type for SVS

# Temporary copies of SVS object arrays (MXSVOB = 15000 from svdata.jl)
const IOBJTPTMP = zeros(Int32, MXSVOB)
const IS2FTMP   = zeros(Int32, MXSVOB)
