# ESCOMN.F77 — Establishment model common (all variants)
# Depends on: prgprm.jl (MAXSP, MAXPLT), esparm.jl (NDBHCL, NSPSPE, MXFRCDS)
# Fortran COMMON /ESCOMN/ → module-level globals

# Real scalars
BAA_ES::Float32    = Float32(0.0)
BAALN::Float32     = Float32(0.0)
BAASQ::Float32     = Float32(0.0)
BWAF::Float32      = Float32(0.0)
BWB4::Float32      = Float32(0.0)
ELEVSQ::Float32    = Float32(0.0)
REGT::Float32      = Float32(0.0)
SLO::Float32       = Float32(0.0)
SQBWAF::Float32    = Float32(0.0)
SQREGT::Float32    = Float32(0.0)
TIME_ES::Float32   = Float32(0.0)
XCOS::Float32      = Float32(0.0)
XCOSAS::Float32    = Float32(0.0)
XSIN::Float32      = Float32(0.0)
XSINAS::Float32    = Float32(0.0)

# Integer scalars
IHAB::Int32  = Int32(0)
IPHY::Int32  = Int32(0)
IPREP::Int32 = Int32(0)
NNID::Int32  = Int32(0)

# Integer arrays
const IFORCD = zeros(Int32, MXFRCDS)     # forest code array
const IFORST = zeros(Int32, MXFRCDS)     # forest type array
const ISPSPE = zeros(Int32, NSPSPE)      # sprouting species list

# Real arrays
const BNORML = zeros(Float32, 20)
const DBHMID = zeros(Float32, NDBHCL)   # midpoint DBH for each class
const HHTMAX = zeros(Float32, MAXSP)
const OCURHT = zeros(Float32, 16, MAXSP)
const OCURNF = zeros(Float32, MXFRCDS, MAXSP)
const SUMPI  = zeros(Float32, MAXSP)
const SUMPX  = zeros(Float32, MAXSP)
const XMIN   = zeros(Float32, MAXSP)
