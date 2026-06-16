# SSTGMC.F77 — Stand structural stage common
# Fortran COMMON /SSTGMC/ → module-level globals

# Logical
LCALC::Bool = false   # true if structural stages being computed
LPRNT::Bool = false   # true if stages being printed

# Integer
IRREF::Int32  = Int32(0)   # report reference number
ISTRCL::Int32 = Int32(0)   # structural class

# Real scalars
CCMIN::Float32  = Float32(0.0)
DBHDOM::Float32 = Float32(0.0)
GAPPCT::Float32 = Float32(0.0)
PCTSMX::Float32 = Float32(0.0)
SAWDBH::Float32 = Float32(0.0)
SSDBH::Float32  = Float32(0.0)
TPAMIN::Float32 = Float32(0.0)

# Real array: structural statistics output (33 attributes × 2: before/after thin)
const OSTRST = zeros(Float32, 33, 2)
