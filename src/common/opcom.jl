# OPCOM.F77 — Operations/activities scheduling (Event Monitor)
# Fortran COMMON /OPCOM/ and /OPCHR/ → module-level globals

# OPCOM dimension parameters
const MAXACT_OP = Int32(4000)
const MAXCOD_OP = Int32(6000)
const MAXEVA_OP = Int32(160)
const MAXEVT_OP = Int32(150)
const MAXPRM_OP = Int32(7999)
const MXCACT_OP = Int32(10000)
const MXEXPR_OP = Int32(2000)
const MXLREG_OP = Int32(400)
const MXPTDO_OP = Int32(500)
const MXTST1_OP = Int32(80)
const MXTST2_OP = Int32(50)
const MXTST3_OP = Int32(50)
const MXTST4_OP = Int32(50)
const MXTST5_OP = Int32(399)
const MXXREG_OP = Int32(400)

# Character globals (/OPCHR/)
SLSET::String  = ""
WKSTR1::String = ""
WKSTR2::String = ""
WKSTR3::String = ""
const CACT   = fill(' ', MXCACT_OP)       # char vector for activity strings
const CTSTV5 = fill("        ", MXTST5_OP) # user-defined variable names (8-char)
const AGLSET = fill("", MAXEVA_OP)          # activity group label sets (250-char)
const CEXPRS = zeros(UInt8, MXEXPR_OP)      # expression string buffer (UInt8 for ALGCMP/ALGEXP)

# Logical scalars
LBSETS::Bool = false   # true if label processing activated
LEVUSE::Bool = false   # true if variables need saving
LOPEVN::Bool = false   # true if in IF-THEN / ALSOTRY block

# Logical arrays
const LREG   = fill(false, MXLREG_OP)
const LTSTV4 = fill(false, MXTST4_OP)
const LTSTV5 = fill(false, MXTST5_OP)

# Integer scalars
ICACT::Int32  = Int32(0)
ICOD::Int32   = Int32(0)
IEPT::Int32   = Int32(0)
IEVA::Int32   = Int32(0)
IEVT::Int32   = Int32(0)
ILGNUM::Int32 = Int32(0)
IMG1::Int32   = Int32(0)
IMG2::Int32   = Int32(0)
IMGL::Int32   = Int32(0)
IMPL::Int32   = Int32(0)
IPHASE::Int32 = Int32(0)
ISEQDN::Int32 = Int32(0)
ITOPRM::Int32 = Int32(0)
ITST5::Int32  = Int32(0)
KTODO::Int32  = Int32(0)
LBSETS_INT::Int32 = Int32(0)   # duplicate: use LBSETS (Bool) above
LENAGL_LEN::Int32 = Int32(0)
LENSLS::Int32 = Int32(-1)      # -1 = no stand label

# Integer arrays
const IACT   = zeros(Int32, MAXACT_OP, 5)
const IDATE  = zeros(Int32, MAXACT_OP)
const IEVACT = zeros(Int32, MAXEVA_OP, 6)
const IEVCOD = zeros(Int32, MAXCOD_OP)
const IEVNTS = zeros(Int32, MAXEVT_OP, 3)
const IMGPTS = zeros(Int32, MAXCYC, 2)
const IOPCYC = zeros(Int32, MAXACT_OP)
const IOPSRT = zeros(Int32, MAXACT_OP)
const IPTODO = zeros(Int32, MXPTDO_OP)
const ISEQ   = zeros(Int32, MAXACT_OP)
const LENAGL = zeros(Int32, MAXEVA_OP)

# Real arrays
const ACCFSP = zeros(Float32, MAXSP)
const BCCFSP = zeros(Float32, MAXSP)
const PARMS  = zeros(Float32, MAXPRM_OP)
const TSTV1  = zeros(Float32, MXTST1_OP)
const TSTV2  = zeros(Float32, MXTST2_OP)
const TSTV3  = zeros(Float32, MXTST3_OP)
const TSTV4  = zeros(Float32, MXTST4_OP)
const TSTV5  = zeros(Float32, MXTST5_OP)
const XREG   = zeros(Float32, MXXREG_OP)

# Aliases without _OP suffix (for compatibility with translated code that uses Fortran names)
const MAXACT  = MAXACT_OP
const MAXCOD  = MAXCOD_OP
const MAXEVA  = MAXEVA_OP
const MAXEVT  = MAXEVT_OP
const MAXPRM  = MAXPRM_OP
const MXCACT  = MXCACT_OP
const MXEXPR  = MXEXPR_OP
const MXLREG  = MXLREG_OP
const MXPTDO  = MXPTDO_OP
const MXTST1  = MXTST1_OP
const MXTST2  = MXTST2_OP
const MXTST3  = MXTST3_OP
const MXTST4  = MXTST4_OP
const MXTST5  = MXTST5_OP
const MXXREG  = MXXREG_OP
