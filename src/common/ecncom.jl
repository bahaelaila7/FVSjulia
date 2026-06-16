# ECNCOM.F77 — FVS/ECON extended economics
# Fortran COMMON /ECON1/ → module-level globals

# Parameters
const MAX_KEYWORDS_EC   = Int32(8)
const MAX_LOGS_EC       = Int32(20)
const MAX_PLANT_COSTS   = Int32(2)
const MAX_RATES_EC      = Int32(8)
const MAX_REV_UNITS     = Int32(5)

# Units-of-measure constants
const TPA_UNIT      = Int32(1)
const BF_1000       = Int32(2)
const FT3_100       = Int32(3)
const BF_1000_LOG   = Int32(4)
const FT3_100_LOG   = Int32(5)
const PER_ACRE      = Int32(6)
const TPA_1000      = Int32(7)

# Activity codes
const PRETEND_ACTIVITY   = Int32(2605)
const SEV_BEGIN_ACTIVITY = Int32(2606)
const SPEC_COST_ACTIVITY = Int32(2607)
const SPEC_REV_ACTIVITY  = Int32(2608)
const ECON_START_YEAR_ACT= Int32(2609)

# Logical scalars
doSev::Bool           = false
noLogStockTable::Bool = false
noOutputTables::Bool  = false
isEconToBe::Bool      = false
isFirstEcon::Bool     = true

# Integer scalars
annCostCnt_EC::Int32   = Int32(0)
annRevCnt_EC::Int32    = Int32(0)
econStartYear::Int32   = Int32(1)
fixHrvCnt::Int32       = Int32(0)
fixPctCnt::Int32       = Int32(0)
pctMinUnits::Int32     = Int32(0)
plntCostCnt::Int32     = Int32(0)
varHrvCnt::Int32       = Int32(0)
varPctCnt::Int32       = Int32(0)

# Real scalars
burnCostAmt::Float32  = Float32(0.0)
dbhSq::Float32        = Float32(0.0)
discountRate::Float32 = Float32(0.0)
mechCostAmt::Float32  = Float32(0.0)
pctMinDbh::Float32    = Float32(0.0)
pctMinVolume::Float32 = Float32(0.0)
sevInput::Float32     = Float32(0.0)

# Keyword-indexed arrays (MAX_KEYWORDS_EC = 8)
const varHrvUnits    = zeros(Int32, MAX_KEYWORDS_EC)
const varPctUnits    = zeros(Int32, MAX_KEYWORDS_EC)
const annCostAmt_EC  = zeros(Float32, MAX_KEYWORDS_EC)
const annRevAmt_EC   = zeros(Float32, MAX_KEYWORDS_EC)
const fixHrvAmt      = zeros(Float32, MAX_KEYWORDS_EC)
const fixPctAmt      = zeros(Float32, MAX_KEYWORDS_EC)
const hrvCostBf      = zeros(Float32, MAX_KEYWORDS_EC)
const hrvCostFt3     = zeros(Float32, MAX_KEYWORDS_EC)
const hrvCostTpa     = zeros(Float32, MAX_KEYWORDS_EC)
const pctBf          = zeros(Float32, MAX_KEYWORDS_EC)
const pctFt3         = zeros(Float32, MAX_KEYWORDS_EC)
const pctTpa         = zeros(Float32, MAX_KEYWORDS_EC)
const varHrvAmt      = zeros(Float32, MAX_KEYWORDS_EC)
const varHrvDbhLo    = zeros(Float32, MAX_KEYWORDS_EC)
const varHrvDbhHi    = zeros(Float32, MAX_KEYWORDS_EC)
const varPctAmt      = zeros(Float32, MAX_KEYWORDS_EC)
const varPctDbhLo    = zeros(Float32, MAX_KEYWORDS_EC)
const varPctDbhHi    = zeros(Float32, MAX_KEYWORDS_EC)

# Plant cost arrays (MAX_PLANT_COSTS = 2)
const plntCostUnits = zeros(Int32, MAX_PLANT_COSTS)
const plntCostAmt   = zeros(Float32, MAX_PLANT_COSTS)

# Rate/duration arrays (MAX_KEYWORDS_EC × MAX_RATES_EC)
const annCostRate = zeros(Float32, MAX_KEYWORDS_EC, MAX_RATES_EC)
const annCostDur  = zeros(Int32,   MAX_KEYWORDS_EC, MAX_RATES_EC)
const annRevRate  = zeros(Float32, MAX_KEYWORDS_EC, MAX_RATES_EC)
const annRevDur   = zeros(Int32,   MAX_KEYWORDS_EC, MAX_RATES_EC)
const fixHrvRate  = zeros(Float32, MAX_KEYWORDS_EC, MAX_RATES_EC)
const fixHrvDur   = zeros(Int32,   MAX_KEYWORDS_EC, MAX_RATES_EC)
const fixPctRate  = zeros(Float32, MAX_KEYWORDS_EC, MAX_RATES_EC)
const fixPctDur   = zeros(Int32,   MAX_KEYWORDS_EC, MAX_RATES_EC)
const varHrvRate  = zeros(Float32, MAX_KEYWORDS_EC, MAX_RATES_EC)
const varHrvDur   = zeros(Int32,   MAX_KEYWORDS_EC, MAX_RATES_EC)
const varPctRate  = zeros(Float32, MAX_KEYWORDS_EC, MAX_RATES_EC)
const varPctDur   = zeros(Int32,   MAX_KEYWORDS_EC, MAX_RATES_EC)
const burnCostRate = zeros(Float32, MAX_RATES_EC)
const burnCostDur  = zeros(Int32,   MAX_RATES_EC)
const mechCostRate = zeros(Float32, MAX_RATES_EC)
const mechCostDur  = zeros(Int32,   MAX_RATES_EC)
const plntCostRate = zeros(Float32, MAX_PLANT_COSTS, MAX_RATES_EC)
const plntCostDur  = zeros(Int32,   MAX_PLANT_COSTS, MAX_RATES_EC)

# Species×revenue-unit arrays
const hrvRevCnt     = zeros(Int32,   MAXSP, MAX_REV_UNITS)
const hasRevAmt     = fill(false,    MAXSP, MAX_REV_UNITS)
const lbsFt3Amt     = zeros(Float32, MAXSP)

# Species×revenue-unit×keyword arrays
const hrvRevPrice   = zeros(Float32, MAXSP, MAX_REV_UNITS, MAX_KEYWORDS_EC)
const hrvRevDia     = zeros(Float32, MAXSP, MAX_REV_UNITS, MAX_KEYWORDS_EC)
const hrvRevDiaIndx = zeros(Int32,   MAXSP, MAX_REV_UNITS, MAX_KEYWORDS_EC)
const revVolume     = zeros(Float32, MAXSP, MAX_REV_UNITS, MAX_KEYWORDS_EC)
const hrvRevRate    = zeros(Float32, MAXSP, MAX_REV_UNITS, MAX_KEYWORDS_EC, MAX_RATES_EC)
const hrvRevDur     = zeros(Int32,   MAXSP, MAX_REV_UNITS, MAX_KEYWORDS_EC, MAX_RATES_EC)

# Harvest accumulator
const harvest = zeros(Float32, 3)   # (TPA, BF, FT3)

# Log-level volume arrays (MAXTRE × MAX_LOGS)
const logBfVol  = zeros(Float32, MAXTRE, MAX_LOGS_EC)
const logDibBf  = zeros(Float32, MAXTRE, MAX_LOGS_EC)
const logFt3Vol = zeros(Float32, MAXTRE, MAX_LOGS_EC)
const logDibFt3 = zeros(Float32, MAXTRE, MAX_LOGS_EC)
