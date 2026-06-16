# VARCOM.F77 — Variant-specific variables
# Fortran COMMON /VARCOM/ and /VARCHR/ → module-level globals

# Character
PCOM::String  = "        "   # alphanumeric plant community / ecoclass code
PCOMX::String = "        "   # PV reference code (error reporting)

# Logical scalars
LBAMAX::Bool = false   # true when user sets BAMAX (prevents auto-reset in SN)
LFIXSD::Bool = false
LFLAGV::Bool = false   # SN: prevents reset of forest type calc each cycle (when true)

# Integer scalars
IBASP::Int32  = Int32(0)   # species with plurality of BA
ISILFT::Int32 = Int32(0)   # SILVAH forest type code
MFLMSB::Int32 = Int32(0)   # MSB mortality flag: 1=from above, 2=from below, 3=throughout

# Real scalars
CEPMRT::Float32 = Float32(0.0)
CEPMSB::Float32 = Float32(0.0)
DHIMSB::Float32 = Float32(0.0)
DLOMSB::Float32 = Float32(0.0)
EFFMSB::Float32 = Float32(0.0)
QMDMSB::Float32 = Float32(0.0)
SLPMRT::Float32 = Float32(0.0)
SLPMSB::Float32 = Float32(0.0)
TPAMRT::Float32 = Float32(0.0)

# Integer arrays (MAXSP)
const IABFLG = zeros(Int32, MAXSP)   # 1=Temesgen HT-DBH coeffs; 0=Wykoff calibrated
const ISTAGF = zeros(Int32, MAXSP)   # stagnation flag per species (0=off, 1=on)
const MAXSDI = zeros(Int32, MAXSP)   # flag to retain user-set SDIMAX by species

# Real arrays (MAXSP)
const AA    = zeros(Float32, MAXSP)
const BB    = zeros(Float32, MAXSP)
const B0ACCF = zeros(Float32, MAXSP)
const B0ASTD = zeros(Float32, MAXSP)
const B0BCCF = zeros(Float32, MAXSP)
const B1ACCF = zeros(Float32, MAXSP)
const B1BCCF = zeros(Float32, MAXSP)
const B1BSTD = zeros(Float32, MAXSP)
const HTT11  = zeros(Float32, MAXSP)
const HTT12  = zeros(Float32, MAXSP)
const HTT13  = zeros(Float32, MAXSP)

# Real 2-D arrays
const HTT1  = zeros(Float32, MAXSP, 9)
const HTT2  = zeros(Float32, MAXSP, 9)

# Per-plot and per-tree arrays
const PTBAA  = zeros(Float32, MAXPLT)   # point basal area (PTBAL output)
const PTBALT = zeros(Float32, MAXTRE)   # BA in larger trees per point
const XMAXPT = zeros(Float32, MAXPLT)  # max SDI for each plot
