# DBSCOM.F77 — DBS/SQLite extension state
# Fortran COMMON /DBSCOM/ and /DBSCHR/ → module-level globals

# Character globals (/DBSCHR/)
DSNOUT::String   = "FVSOut.db"   # output database file name (DBSBLKD default)
DSNIN::String    = "FVS_Data.db" # input database file name (DBSBLKD default)
KEYFNAME::String = ""   # keyword file name (stored for FVS_Cases table)
CASEID::String   = ""   # unique case ID (up to 36 chars)

# Float data array for tree binding
const RTREEDATA = zeros(Float32, 25)

# String lengths
const LENSTRINGS = zeros(Int32, 3)

# Table output switches (0=off, 1=on, 2=db-only)
ISUMARY::Int32   = Int32(0)   # FVS_Summary2
ICOMPUTE::Int32  = Int32(0)   # FVS_Compute
ITREELIST::Int32 = Int32(0)   # FVS_TreeList
IPOTFIRE::Int32  = Int32(0)   # FVS_PotFire
IFUELS::Int32    = Int32(0)   # FVS_Fuels
ITREEIN::Int32   = Int32(0)   # FVS_TreeIn
ICUTLIST::Int32  = Int32(0)   # FVS_Cutlist
IATRTLIST::Int32 = Int32(0)   # FVS_ATreatment
IDM1::Int32      = Int32(0)
IDM2::Int32      = Int32(0)
IDM3::Int32      = Int32(0)
IDM5::Int32      = Int32(0)
IDM6::Int32      = Int32(0)
IFUELC::Int32    = Int32(0)   # FVS_FuelConsumption
IBURN::Int32     = Int32(0)   # FVS_BurnConditions
IMORTF::Int32    = Int32(0)   # FVS_MortFire
ISSUM::Int32     = Int32(0)   # FVS_SnagSummary
ISDET::Int32     = Int32(0)   # FVS_SnagDetail
ISTRCLAS::Int32  = Int32(0)   # FVS_StructureClass
IBMMAIN::Int32   = Int32(0)
IBMBKP::Int32    = Int32(0)
IBMTREE::Int32   = Int32(0)
IBMVOL::Int32    = Int32(0)
IDBSECON::Int32  = Int32(0)   # FVS_EconSummary
ISPOUT6::Int32   = Int32(0)
ISPOUT17::Int32  = Int32(0)
ISPOUT21::Int32  = Int32(0)
ISPOUT23::Int32  = Int32(0)
ISPOUT30::Int32  = Int32(0)
ISPOUT31::Int32  = Int32(0)
IDWDVOL::Int32   = Int32(0)   # FVS_DwdVolume
IDWDCOV::Int32   = Int32(0)   # FVS_DwdCover
IOUTDBREF::Int32 = Int32(-1)   # DBSBLKD default
IINDBREF::Int32  = Int32(-1)   # DBSBLKD default
ICALIB::Int32    = Int32(0)   # FVS_Calibration
ISTATS1::Int32   = Int32(0)
ISTATS2::Int32   = Int32(0)
IRD1::Int32      = Int32(0)
IRD2::Int32      = Int32(0)
IRD3::Int32      = Int32(0)
IREG1::Int32     = Int32(0)
IREG2::Int32     = Int32(0)
IREG3::Int32     = Int32(0)
IREG4::Int32     = Int32(0)
IREG5::Int32     = Int32(0)
IPOTFIREC::Int32 = Int32(0)
IVBCSUM::Int32   = Int32(0)   # FVS_FIAVBC_Summary
IVBCTRELST::Int32= Int32(0)
IVBCCUTLST::Int32= Int32(0)
IVBCATRLST::Int32= Int32(0)
ICANPR::Int32    = Int32(0)
ICLIM::Int32     = Int32(0)
I_CMPU::Int32    = Int32(0)
IADDCMPU::Int32  = Int32(0)
ICMRPT::Int32    = Int32(0)
ICHRPT::Int32    = Int32(0)
irgin::Int32     = Int32(0)
