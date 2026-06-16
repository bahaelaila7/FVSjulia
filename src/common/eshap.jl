# ESHAP.F77 — Establishment happenin' (shape) control
# Fortran COMMON /ESHAP/ → module-level globals

# Logical scalars
LAUTAL::Bool = false   # true if auto-tallies included
LINGRW::Bool = false   # true if auto-ingrowth being simulated
LSPRUT::Bool = false   # true if sprouting logic on

# Integer scalars
IBLK::Int32   = Int32(0)
IDSDAT::Int32 = Int32(0)   # date of disturbance
IFO::Int32    = Int32(0)
IHTYPE::Int32 = Int32(0)
INADV::Int32  = Int32(0)   # 0=advance regen inventoried; 1=model will add advance component
IPINFO::Int32 = Int32(0)
IPRINT::Int32 = Int32(0)   # 0=nothing printed; 1=stand summary
ITRNRM::Int32 = Int32(0)   # number of tree records to sprout in ESUCKR
IYRLRM::Int32 = Int32(0)   # year of last removal
JOREGT::Int32 = Int32(17)  # output unit for regen summary (ESBLKD default)
KDTOLD::Int32 = Int32(0)
LOAD::Int32   = Int32(0)   # 0/1 flag: use site prep from IPPREP
METH::Int32   = Int32(0)
MINREP::Int32 = Int32(0)   # number of regen inventory plots to project
MODE::Int32   = Int32(0)
NPTIDS::Int32 = Int32(0)   # total number of point IDs in base model
NTALLY::Int32 = Int32(0)   # current tally number

# Real scalars
CONFID::Float32 = Float32(0.0)
ESA::Float32    = Float32(0.0)
ESB::Float32    = Float32(0.0)
ESDRAW::Float32 = Float32(0.0)
OLDTIM::Float32 = Float32(0.0)
PBURN::Float32  = Float32(0.0)
PMECH::Float32  = Float32(0.0)
STOADJ::Float32 = Float32(1.0)
THRES1::Float32 = Float32(0.0)
THRES2::Float32 = Float32(0.0)
XTES::Float32   = Float32(0.0)
ZBURN::Float32  = Float32(0.0)
ZMECH::Float32  = Float32(0.0)

# Integer arrays
const IALN   = zeros(Int32, 3)
const IHABT  = zeros(Int32, 16)
const IPHAB  = zeros(Int32, MAXPLT)
const IPHYS  = zeros(Int32, MAXPLT)
const IPPREP = zeros(Int32, MAXPLT)
const IPTIDS = zeros(Int32, MAXPLT)

# Real arrays
const HTADJ  = zeros(Float32, MAXSP)
const PASP   = zeros(Float32, MAXPLT)
const PSLO   = zeros(Float32, MAXPLT)
const SUMPRE = zeros(Float32, 5)
const XESMLT = zeros(Float32, MAXSP)
