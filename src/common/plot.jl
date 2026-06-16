# PLOT.F77 — Stand/plot-level data
# Fortran COMMON /PLOT/ and /PLTCHR/ → module-level globals

# Character scalars (/PLTCHR/)
MGMID::String  = "    "              # 4-char management ID
ECOREG::String = "    "              # 4-char Bailey's ecoregion code
CPVREF::String = "          "        # 10-char PV reference code
NPLT::String   = repeat(' ', 26)     # 26-char stand identification code
DBCN::String   = repeat(' ', 40)     # 40-char database control number

# Character arrays (/PLTCHR/)
const FIAJSP = fill("    ", MAXSP)          # 4-char FIA species codes
const JSP    = fill("    ", MAXSP)          # 4-char alpha species codes
const NSP    = fill("    ", MAXSP, 3)       # 4-char species-tree class codes (3 variants)
const PLNJSP = fill("      ", MAXSP)        # 6-char PLANTS species symbols

# Integer scalars
IAGE::Int32    = Int32(0)    # stand age (original, never updated)
IASPEC::Int32  = Int32(0)    # input aspect (degrees)
ICAGE::Int32   = Int32(0)    # stand age computed from size class + height
ICNTY::Int32   = Int32(0)    # FIA county code
IFINT::Int32   = Int32(0)    # forecast interval (integer years/cycle)
IFOR::Int32    = Int32(0)    # forest identification subscript
IFORTP::Int32  = Int32(0)    # forest type
IGL::Int32     = Int32(0)    # geographic location: 1=N, 2=C, 3=S
IIFORTP::Int32 = Int32(0)    # inventory forest type
IMODTY::Int32  = Int32(0)    # model type (MODTYPE keyword field 1)
IPHREG::Int32  = Int32(0)    # physiographic region (MODTYPE field 2)
IPTINV::Int32  = Int32(0)    # points inventoried (integer version of PI)
ISISP::Int32   = Int32(0)    # site species (species of max BA)
ISLOP::Int32   = Int32(0)    # input slope (undecoded)
ISMALL::Int32  = Int32(0)    # number of tree records < 3.0" DBH
ISTATE::Int32  = Int32(0)    # FIA state code
ISTCL::Int32   = Int32(0)    # stocking class (from STKVAL)
ISZCL::Int32   = Int32(0)    # size class (from STKVAL)
ITYPE::Int32   = Int32(0)    # input habitat type code
JSPINDEF::Int32= Int32(0)    # default species code format
KODFOR::Int32  = Int32(0)    # user forest code
KODTYP::Int32  = Int32(0)    # habitat type classified in HABTYP
MANAGD::Int32  = Int32(0)    # 0=unmanaged; 1=managed
NONSTK::Int32  = Int32(0)    # non-stockable points inventoried
NSITET::Int32  = Int32(0)    # number of site trees
ISTDORG::Int32 = Int32(0)    # stand origin: 0=natural, 1=plantation

# Integer arrays
const IPVEC = zeros(Int32, MAXPLT)    # subplot identification vector
const JSPIN = zeros(Int32, MAXSP)     # species code format per species (1=alpha,2=FIA,3=PLANTS)
const JTYPE = zeros(Int32, 122)       # valid habitat type codes

# Real scalars
ASPECT::Float32 = Float32(0.0)   # stand aspect (radians)
ATAVD::Float32  = Float32(0.0)   # QMD after thinning
ATAVH::Float32  = Float32(0.0)   # avg height of dominants after thinning
ATBA::Float32   = Float32(0.0)   # basal area after thinning
ATCCF::Float32  = Float32(0.0)   # CCF after thinning
ATSDIX::Float32 = Float32(0.0)   # max SDI after treatment
ATTPA::Float32  = Float32(0.0)   # TPA after thinning
AVH::Float32    = Float32(0.0)   # current avg stand height
BA::Float32     = Float32(0.0)   # current stand basal area (ft²/acre)
BAF::Float32    = Float32(40.0)  # basal area factor for inventory
BRK::Float32    = Float32(5.0)   # min DBH measured on variable plot
BTSDIX::Float32 = Float32(0.0)   # max SDI before treatment
COVMLT::Float32 = Float32(0.0)   # sum of serial correlations (periods I and J)
COVYR::Float32  = Float32(0.0)   # COVMLT(YR,YR)
ELEV::Float32   = Float32(0.0)   # elevation (hundreds of feet)
FINT::Float32   = Float32(0.0)   # cycle length (floating point)
FPA::Float32    = Float32(300.0) # inverse of fixed plot area (acres)
GROSPC::Float32 = Float32(1.0)   # CCF inflator for non-stockable points
OLDAVH::Float32 = Float32(0.0)   # avg dominant height end of last cycle
OLDBA::Float32  = Float32(0.0)   # BA at end of last cycle
OLDTPA::Float32 = Float32(0.0)   # TPA at end of last cycle
ORMSQD::Float32 = Float32(0.0)   # QMD at end of last cycle
PI::Float32     = Float32(3.14159265)
PMSDIL::Float32 = Float32(0.0)   # % of SDIMAX where density mortality begins
PMSDIU::Float32 = Float32(0.0)   # % of SDIMAX at which stand reaches max density
RELDEN::Float32 = Float32(0.0)   # current CCF (crown competition factor)
RELDM1::Float32 = Float32(0.0)   # CCF of previous cycle
RMAI::Float32   = Float32(0.0)   # adjusted mean annual increment
RMSQD::Float32  = Float32(0.0)   # quadratic mean diameter (stand QMD)
SAMWT::Float32  = Float32(0.0)   # stand sampling weight
SDIAC::Float32  = Float32(0.0)   # SDI following cutting
SDIAC2::Float32 = Float32(0.0)   # Zeide SDI following cutting
SDIBC::Float32  = Float32(0.0)   # SDI before cutting
SDIBC2::Float32 = Float32(0.0)   # Zeide SDI before cutting
SDIMAX::Float32 = Float32(0.0)   # maximum SDI for stand
SLOPE::Float32  = Float32(0.0)   # slope (range 0-1)
STNDSI::Float32 = Float32(0.0)   # initial site index of site species
TFPA::Float32   = Float32(0.0)   # sum of fixed plot areas (acres)
TLAT::Float32   = Float32(0.0)   # latitude (degrees)
TLONG::Float32  = Float32(0.0)   # longitude (degrees, negative = west)
TPROB::Float32  = Float32(0.0)   # total trees per acre (= SUM(PROB[1:ITRN]))
VMLT::Float32   = Float32(0.0)   # sum of serial correlations within period I
VMLTYR::Float32 = Float32(0.0)   # VMLT(YR)

# Real arrays (per-species)
const BARANK = zeros(Float32, MAXSP)   # species ranking by BA
const RELDSP = zeros(Float32, MAXSP)   # CCF contribution by species
const SDIDEF = zeros(Float32, MAXSP)   # max SDI by species
const SITEAR = zeros(Float32, MAXSP)   # site index by species (large + small)

# Real arrays (per-tree-site)
const SITETR = zeros(Float32, MAXSTR, 6)  # site tree records: sp/DBH/HT/age/total-age/on-plot
