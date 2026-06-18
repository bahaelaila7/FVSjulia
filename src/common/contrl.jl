# CONTRL.F77 — Simulation control variables
# Fortran COMMON /CONTRL/ and /CONCHR/ → module-level globals

# Character variables (/CONCHR/)
CFCTYPE::String = " "              # cubic foot volume cruise type (1 char)
BFCTYPE::String = " "              # board foot volume cruise type (1 char)
VARACD::String  = "SN"             # 2-char variant designator
CALCSDI::String = "       "        # "ZEIDE" or "REINEKE" or blank
TREFMT::String  = repeat(' ', 160) # tree record format string
KWDFIL::String  = repeat(' ', 250) # keyword file name

# Character arrays (/CONCHR/)
const IUSED   = fill("    ", MAXSP)   # 4-char species used flags
const NAMGRP  = fill("          ", 30) # 10-char group names
const PTGNAME = fill("          ", 30) # 10-char PTG names

# Logical variables
LAUTON::Bool  = false   # auto thinning on
LBKDEN::Bool  = false   # background density flag
LBVOLS::Bool  = false   # board foot volumes flag
LCVOLS::Bool  = false   # cubic volumes flag
LDCOR2::Bool  = false
LDUBDG::Bool  = false   # dubbing flag
LFIA::Bool    = false   # FIA data flag
LFIRE::Bool   = false   # fire flag
LFLAG::Bool   = false   # general flag
LMORT::Bool   = false   # mortality flag
LPERM::Bool   = false   # permanent plots flag
LRCOR2::Bool  = false
LSITE::Bool   = false   # site index flag
LSTART::Bool  = false   # start of simulation flag
LSUMRY::Bool  = false   # summary flag
LTRIP::Bool   = false   # tripling flag
LZEIDE::Bool  = false   # Zeide SDI flag
MORDAT::Bool  = false
NOTRIP::Bool  = false   # no tripling flag
LFIANVB::Bool = false   # FIA NVB flag

# Logical arrays indexed by species
const LDGCAL  = fill(false, Int(MAXSP))  # diameter growth calibration by species
const LEAVESP = fill(false, Int(MAXSP))  # leave species flag
const LHTDRG  = fill(false, Int(MAXSP))  # height drag flag

# Integer scalars
ICCODE::Int32  = Int32(0)    # error/warning code
ICFLAG::Int32  = Int32(0)    # cutting algorithm index
ICL1::Int32    = Int32(0)    # cycle length 1
ICL2::Int32    = Int32(0)
ICL3::Int32    = Int32(0)
ICL4::Int32    = Int32(0)
ICL5::Int32    = Int32(0)
ICL6::Int32    = Int32(0)
ICYC::Int32    = Int32(0)    # current cycle number
IDG::Int32     = Int32(0)    # diameter growth calibration option
IFST::Int32    = Int32(0)    # first cycle flag
IREAD::Int32   = Int32(0)    # read flag
IREC1::Int32   = Int32(0)    # first active tree record
IREC2::Int32   = Int32(0)    # dead tree record cutoff
IRECNT::Int32  = Int32(0)
IRECRD::Int32  = Int32(0)
ISTDAT::Int32  = Int32(0)    # start date (year)
ITHNPA::Int32  = Int32(0)
ITHNPI::Int32  = Int32(0)
ITHNPN::Int32  = Int32(0)
ITRN::Int32    = Int32(0)    # number of active tree records
JOCALB::Int32  = Int32(0)    # calibration output unit
JOLIST::Int32  = Int32(7)    # listing unit
JOSTND::Int32  = Int32(6)    # standard output unit (stdout)
JOSUM::Int32   = Int32(8)    # summary output unit
JOTREE::Int32  = Int32(9)    # tree list output unit
LSTKNT::Int32  = Int32(0)
NCYC::Int32    = Int32(0)    # number of cycles requested
NPTGRP::Int32  = Int32(0)    # number of point groups
NSPGRP::Int32  = Int32(0)    # number of species groups
NSTKNT::Int32  = Int32(0)
NUMSP::Int32   = Int32(0)    # number of species encountered in stand

# Integer arrays indexed by species
const IBEGIN = zeros(Int32, MAXSP)     # beginning index per species
const IREF   = zeros(Int32, MAXSP)     # chain-sort reference pointer
const ISCT   = zeros(Int32, MAXSP, 2)  # species count table (2 columns)
const KOUNT  = zeros(Int32, MAXSP)     # count per species
const KPTR   = zeros(Int32, MAXSP)     # pointer per species
const METHB  = zeros(Int32, MAXSP)     # method B per species
const METHC  = zeros(Int32, MAXSP)     # method C per species

# Integer arrays (other)
const INS    = zeros(Int32, 6)         # input number fields
const IPTGRP = zeros(Int32, 30, 52)    # point group assignments
const ISPGRP = zeros(Int32, 30, 92)    # species group assignments

# Cycle array IY(MAXCY1) — year at start of each cycle
const IY = zeros(Int32, MAXCY1)

# Table flags (7 entries)
const ITABLE = zeros(Int32, 7)

# Real scalars
AUTEFF::Float32  = Float32(0.0)   # cutting efficiency for auto thinning
AUTMAX::Float32  = Float32(60.0)  # upper limit for auto thinning
AUTMIN::Float32  = Float32(45.0)  # lower limit for auto thinning
BAMAX::Float32   = Float32(0.0)   # maximum attainable BA
BAMIN::Float32   = Float32(0.0)   # minimum BA (like CFMIN but in BA)
BFMIN::Float32   = Float32(0.0)   # minimum acceptable harvest in BF/acre
CCCOEF::Float32  = Float32(0.0)   # canopy cover overlap coefficient
CCCOEF2::Float32 = Float32(0.0)   # CCF coefficient for after-thin in later cycles
CFMIN::Float32   = Float32(0.0)   # minimum acceptable harvest in merch cuft/acre
DBHSDI::Float32  = Float32(0.0)   # DBH breakpoint for SDI-based mortality
DBHSTAGE::Float32= Float32(0.0)   # min DBH for Reineke/Curtis SDI calc
DBHZEIDE::Float32= Float32(0.0)   # min DBH for Zeide SDI calc
DGSD::Float32    = Float32(0.0)   # std deviations bound on DG variance
DR016::Float32   = Float32(0.0)   # Zeide Reineke diameter (current cycle)
ATDR016::Float32 = Float32(0.0)   # after-thinning Zeide Reineke diameter
ODR016::Float32  = Float32(0.0)   # previous cycle Zeide Reineke diameter
EFF::Float32     = Float32(0.98)  # cutting effectiveness (max proportion removed)
FINTM::Float32   = Float32(5.0)   # mortality observation period (years)
PBAWT::Float32   = Float32(0.0)   # BA weight for thinning
PCCFWT::Float32  = Float32(0.0)   # CCF weight for thinning
PTPAWT::Float32  = Float32(0.0)   # TPA weight for thinning
SCFMIN::Float32  = Float32(0.0)   # minimum sawtimber cubic foot volume
SPCLWT::Float32  = Float32(0.0)   # special weight
TCFMIN::Float32  = Float32(0.0)   # minimum total cubic foot volume
TCWT::Float32    = Float32(0.0)   # total weight
TRM::Float32     = Float32(0.0)   # total removal (TPA)
YR::Float32      = Float32(0.0)   # current year (floating point)

# Real arrays indexed by species
const DBHMIN  = zeros(Float32, MAXSP)     # min DBH for merchantable cubic vol
const FRMCLS  = zeros(Float32, MAXSP)     # form class per species
const RCOR2   = zeros(Float32, MAXSP)     # residual correction 2
const SIZCAP  = zeros(Float32, MAXSP, 4)  # size cap per species (4 variants)
const STMP    = zeros(Float32, MAXSP)     # stump height per species
const TOPD    = zeros(Float32, MAXSP)     # top diameter per species
const SCFMIND = zeros(Float32, MAXSP)
const SCFTOPD = zeros(Float32, MAXSP)
const SCFSTMP = zeros(Float32, MAXSP)

# Title / label
ITITLE::String = repeat(' ', 72)
