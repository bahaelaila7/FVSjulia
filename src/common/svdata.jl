# SVDATA.F77 — Stand Visualization (SVS) data
# Fortran COMMON /SVDATA/ → module-level globals

const MXSVOB = Int32(15000)

# Integer scalars
ICOLIDX::Int32  = Int32(0)
IDPLOTS::Int32  = Int32(0)   # 0=no plot boundaries; 1=draw
IGRID::Int32    = Int32(0)   # grid resolution for ground files (0=none)
IMETRIC::Int32  = Int32(0)   # 0=imperial; 1=metric
IMORTCNT::Int32 = Int32(0)   # count of SVMORT calls this cycle
IPLGEM::Int32   = Int32(0)   # plot geometry code (0=square acre; 1=subdivided; 2=round; 3=subdivided round)
IRPOLES::Int32  = Int32(0)   # 0=no scale poles; 1=draw
ISVINV::Int32   = Int32(0)   # max of ITRE() or IPTINV
JSVOUT::Int32   = Int32(0)   # 0=no SVS; else file unit
JSVPIC::Int32   = Int32(0)   # file unit for index file
NIMAGE::Int32   = Int32(0)   # image sequence number
NSVOBJ::Int32   = Int32(0)   # number of objects defined

# Integer arrays
const IOBJTP = zeros(Int32, MXSVOB)   # object type: 0=open; 1=FVS tree; 2=snag; 3=to-remove; 4=CWD; 5=salvaged snag
const IS2F   = zeros(Int32, MXSVOB)   # pointer to tree/snag/CWD record

# Real arrays
const SVMSAVE = zeros(Float32, MAXTRE)
const X1R1S   = zeros(Float32, MAXPLT)
const X2R2S   = zeros(Float32, MAXPLT)
const Y1A1S   = zeros(Float32, MAXPLT)
const Y2A2S   = zeros(Float32, MAXPLT)
const XSLOC   = zeros(Float32, MXSVOB)
const YSLOC   = zeros(Float32, MXSVOB)
