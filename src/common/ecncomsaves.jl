# ECNCOMSAVES.F77 — FVS/ECON state that persists across cycles (SAVE variables)
# Fortran COMMON /ECONSAVE/ → module-level globals

# Derived dimensions
const MAX_YEARS_EC    = MAXCYC * 20        # max years = max cycles × 20 yrs/cycle
const MAX_HARVESTS_EC = (MAXCYC * MAXSP + 1) ÷ 2
const MAX_COSTS_EC    = (MAXCYC * 4 * MAX_KEYWORDS_EC + 1) ÷ 2

# Integer scalars
burnCnt_EC::Int32    = Int32(0)
hrvCstCnt::Int32     = Int32(0)
hrvRvnCnt::Int32     = Int32(0)
logTableId::Int32    = Int32(0)
mechCnt_EC::Int32    = Int32(0)
startYear_EC::Int32  = Int32(0)
specCstCnt::Int32    = Int32(0)
specRvnCnt::Int32    = Int32(0)
sumTableId::Int32    = Int32(0)

# Real scalars
costDisc::Float32   = Float32(0.0)
costUndisc::Float32 = Float32(0.0)
rate_EC::Float32    = Float32(0.0)
revDisc::Float32    = Float32(0.0)
revUndisc::Float32  = Float32(0.0)
sevAnnCst::Float32  = Float32(0.0)
sevAnnRvn::Float32  = Float32(0.0)

# Per-year arrays
const undiscCost = zeros(Float32, MAX_YEARS_EC)
const undiscRev  = zeros(Float32, MAX_YEARS_EC)

# Per-harvest cost arrays
const hrvCstAmt   = zeros(Float32, MAX_COSTS_EC)
const hrvCstKeywd = zeros(Int32,   MAX_COSTS_EC)
const hrvCstTime  = zeros(Int32,   MAX_COSTS_EC)
const hrvCstTyp   = zeros(Int32,   MAX_COSTS_EC)

# Per-harvest revenue arrays
const hrvRvnAmt   = zeros(Float32, MAX_HARVESTS_EC)
const hrvRvnKeywd = zeros(Int32,   MAX_HARVESTS_EC)
const hrvRvnSp    = zeros(Int32,   MAX_HARVESTS_EC)
const hrvRvnTime  = zeros(Int32,   MAX_HARVESTS_EC)
const hrvRvnUnits = zeros(Int32,   MAX_HARVESTS_EC)

# Pretend functionality
isPretendActive::Bool   = false
pretendStartYear::Int32 = Int32(0)
pretendEndYear::Int32   = Int32(0)
