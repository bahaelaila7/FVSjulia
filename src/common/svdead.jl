# SVDEAD.F77 — Snag and coarse woody debris (CWD) data for SVS
# Fortran COMMON /SVDEAD/ → module-level globals

const MXDEAD = Int32(1000)
const MXCWD  = Int32(5000)    # half of MXSVOB

# Integer scalars
ILYEAR::Int32 = Int32(0)   # last year all-snags routine was called
NCWD::Int32   = Int32(0)   # total number of CWD records
NDEAD::Int32  = Int32(0)   # total number of snags

# Integer arrays
const ISNSP   = zeros(Int32, MXDEAD)   # species code for snag
const ISTATUS = zeros(Int32, MXDEAD)   # snag status: 0=open; 1=green hard; 2=red hard; 3=grey hard; 4=grey soft; 5,6=burned
const IYRCOD  = zeros(Int32, MXDEAD)   # year of death
const OIDTRE  = zeros(Int32, MXDEAD)   # original IDTREE that generated snag

# Real arrays (snag attributes)
const CRNDIA  = zeros(Float32, MXDEAD)
const CRNRTO  = zeros(Float32, MXDEAD)
const FALLDIR = zeros(Float32, MXDEAD)    # 0-360=direction of fall; -1=standing
const ODIA    = zeros(Float32, MXDEAD)    # original tree diameter
const OLEN    = zeros(Float32, MXDEAD)    # original tree length
const PBFALL  = zeros(Float32, MXDEAD)    # post-burn fall rate
const SNGCNWT = zeros(Float32, MXDEAD, 4)   # snag crown weight by size class (indices 0:3 → 1:4 in Julia)
const SNGDIA  = zeros(Float32, MXDEAD)    # current snag diameter
const SNGLEN  = zeros(Float32, MXDEAD)    # current snag height
const SPROBS  = zeros(Float32, MXDEAD, 3) # trees/ac snag stockings (3 forms)

# Per-species arrays
const HRATE  = zeros(Float32, MAXSP)   # rate modifier for height loss
const YHFHTH = zeros(Float32, MAXSP)   # years to half-height for hard snags
const YHFHTS = zeros(Float32, MAXSP)   # years to half-height for soft snags

# CWD arrays
const CWDDIA = zeros(Float32, MXCWD)
const CWDDIR = zeros(Float32, MXCWD)
const CWDLEN = zeros(Float32, MXCWD)
const CWDPIL = zeros(Float32, MXCWD)   # piled (1) / unpiled (0)
const CWDWT  = zeros(Float32, MXCWD)   # weight (tons)
