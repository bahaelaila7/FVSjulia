# VOLSTD.F77 — Volume standard configuration
# Fortran COMMON /VOLSTD/ and /VOLCHR/ → module-level globals

# Logical
LSTATS::Bool = false

# Real scalar
ALPHA::Float32 = Float32(0.05)

# Per-species arrays
const IBTRAN  = zeros(Int32, MAXSP)
const ICTRAN  = zeros(Int32, MAXSP)
const BFMIND  = zeros(Float32, MAXSP)    # min DBH for BF merchantability
const BFSTMP  = zeros(Float32, MAXSP)    # stump heights for merch BF volume
const BFTOPD  = zeros(Float32, MAXSP)    # top diameters for merch BF volume
const BTRAN   = zeros(Float32, MAXSP)
const CTRAN   = zeros(Float32, MAXSP)

# Volume equation number strings (11-char per species)
const VEQNNB = fill("           ", MAXSP)   # board foot equation number
const VEQNNC = fill("           ", MAXSP)   # cubic foot equation number

# Volume equation coefficient tables (7 × MAXSP)
const BFVEQL = zeros(Float32, 7, MAXSP)
const BFVEQS = zeros(Float32, 7, MAXSP)
const CFVEQL = zeros(Float32, 7, MAXSP)
const CFVEQS = zeros(Float32, 7, MAXSP)

# Log data (21 DIBs × 3 types; 7 volume attrs × 20 logs)
const LOGDIA = zeros(Float32, 21, 3)
const LOGVOL = zeros(Float32, 7, 20)
