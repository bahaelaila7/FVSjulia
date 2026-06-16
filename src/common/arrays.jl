# ARRAYS.F77 — Per-tree attribute arrays
# Fortran COMMON /ARRAYS/ → module-level globals

# Logical arrays
const LBIRTH = falses(MAXTRE)          # whether tree age was input

# Integer arrays
const DAMSEV   = zeros(Int32, 6, MAXTRE)  # damage severity (6 types x MAXTRE)
const DECAYCD  = zeros(Int32, MAXTRE)
const DEFECT   = zeros(Int32, MAXTRE)
const ICR      = zeros(Int32, MAXTRE)     # crown ratio (%)
const IDTREE   = zeros(Int32, MAXTRE)     # tree ID number
const IMC      = zeros(Int32, MAXTRE)     # mortality code
const IND      = zeros(Int32, MAXTRE)     # sorting index
const IND1     = zeros(Int32, MAXTRE)
const IND2     = zeros(Int32, MAXTRE)
const ISP      = zeros(Int32, MAXTRE)     # species code (1..MAXSP)
const ISPECL   = zeros(Int32, MAXTRE)     # special code
const ITRE     = zeros(Int32, MAXTRE)     # tree number in plot
const ITRUNC   = zeros(Int32, MAXTRE)
const KUTKOD   = zeros(Int32, MAXTRE)     # cut code
const NORMHT   = zeros(Int32, MAXTRE)
const WDLDSTEM = zeros(Int32, MAXTRE)

# Real arrays
const ABIRTH  = zeros(Float32, MAXTRE)   # age at birth (if known)
const BFV     = zeros(Float32, MAXTRE)   # board foot volume per tree
const CFV     = zeros(Float32, MAXTRE)   # cubic foot volume per tree
const CRWDTH  = zeros(Float32, MAXTRE)   # crown width
const DBH     = zeros(Float32, MAXTRE)   # diameter breast height (in)
const DG      = zeros(Float32, MAXTRE)   # diameter growth (in/cycle)
const HT      = zeros(Float32, MAXTRE)   # total height (ft)
const HT2TD   = zeros(Float32, MAXTRE, 2) # height to top: [i,1]=BF merch top, [i,2]=CF merch top
const HTG     = zeros(Float32, MAXTRE)   # height growth (ft/cycle)
const OLDPCT  = zeros(Float32, MAXTRE)
const OLDRN   = zeros(Float32, MAXTRE)
const PCT     = zeros(Float32, MAXTRE)   # crown ratio (fraction 0-1)
const PLTSIZ  = zeros(Float32, MAXTRE)   # plot size (acres)
const PROB    = zeros(Float32, MAXTRE)   # trees per acre (expansion factor)
const WK1     = zeros(Float32, MAXTRE)
const WK2     = zeros(Float32, MAXTRE)
const WK3     = zeros(Float32, MAXTRE)
const WK4     = zeros(Float32, MAXTRE)
const WK5     = zeros(Float32, MAXTRE)
const WK6     = zeros(Float32, MAXTRE)
const WK7     = zeros(Float32, MAXTRE)
const WK8     = zeros(Float32, MAXTRE)
const WK9     = zeros(Float32, MAXTRE)
const WK10    = zeros(Float32, MAXTRE)
const WK11    = zeros(Float32, MAXTRE)
const WK12    = zeros(Float32, MAXTRE)
const WK13    = zeros(Float32, MAXTRE)
const WK14    = zeros(Float32, MAXTRE)
const WK15    = zeros(Float32, MAXTRE)
const YRDLOS  = zeros(Float32, MAXTRE)   # year of last observed diameter
const ZRAND   = zeros(Float32, MAXTRE)   # random numbers per tree
const MCFV    = zeros(Float32, MAXTRE)   # merch cubic foot volume
const SCFV    = zeros(Float32, MAXTRE)   # sawtimber cubic foot volume
const CULL    = zeros(Float32, MAXTRE)

# Biomass and carbon arrays (lbs/tree)
const ABVGRD_BIO  = zeros(Float32, MAXTRE)  # above-ground biomass
const MERCH_BIO   = zeros(Float32, MAXTRE)  # merchantable biomass
const CUBSAW_BIO  = zeros(Float32, MAXTRE)  # cubic sawtimber biomass
const FOLI_BIO    = zeros(Float32, MAXTRE)  # foliage biomass
const ABVGRD_CARB = zeros(Float32, MAXTRE)  # above-ground carbon
const MERCH_CARB  = zeros(Float32, MAXTRE)
const CUBSAW_CARB = zeros(Float32, MAXTRE)
const FOLI_CARB   = zeros(Float32, MAXTRE)
const CARB_FRAC   = zeros(Float32, MAXTRE)  # carbon fraction by species

# Integer arrays for IPVARS (5 variables) — from intree.f field read
const IPVARS = zeros(Int32, 5, MAXTRE)

# History code
const IHISTY = zeros(Int32, MAXTRE)      # history code for tree
