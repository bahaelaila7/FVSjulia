# FMCOM.F77 — Fire model main variables
# Depends on: fmparm.jl (MXSNAG, MXFLCL, TFMAX), prgprm.jl (MAXTRE, MAXSP)
# Fortran COMMON /FMCOM/ → module-level globals

# Logical scalars
LFMON::Bool  = false   # true if fire extension is running
LFMON2::Bool = false   # true if in first year of fire model
LANHED::Bool = true    # true if landscape output headers still to print
LDHEAD::Bool = true    # true if fuels output headers still to print
LSHEAD::Bool = true    # true if snag output file header still to print
LDYNFM::Bool = false   # true if dynamic fuel model to be used
LVWEST::Bool = false   # true if western variant
LREMT::Bool  = false   # true if removals being tracked for EM function

const LFROUT = fill(false, 3)   # which fire report files will be printed

# Integer scalars
BURNYR::Int32  = Int32(0)   # year of most recent burn
COVTYP::Int32  = Int32(0)   # species code for predominant cover type
FMKOD::Int32   = Int32(0)
FTREAT::Int32  = Int32(0)   # fuel treatment: 0=none; 1=lopping; 2=trampling
HARTYP::Int32  = Int32(0)   # harvest type: 1=ground; 2=high-lead; 3=helicopter
HARVYR::Int32  = Int32(0)   # year of most recent harvest
ICANSP::Int32  = Int32(0)   # 0=conifers only; 1=all species for canopy calc
ICBHMT::Int32  = Int32(0)   # canopy base height method
ICYCRM::Int32  = Int32(0)   # thinning cycle for TREEBIO
IFMYR1::Int32  = Int32(0)   # first year of cycle
IFMYR2::Int32  = Int32(0)   # last year of cycle
IFTYR::Int32   = Int32(0)   # year corresponding to FuelTreat keyword
ISALVC::Int32  = Int32(0)   # 0=cut species in salvage; 1=leave
ISALVS::Int32  = Int32(0)   # species being cut in salvage
ISNGSM::Int32  = Int32(-1)  # snag summary: -1=not requested; ≥0=report ref
ITRNL::Int32   = Int32(0)   # tree list length at FMTREM call from CUTS
JCOUT::Int32   = Int32(0)   # hidden output file unit
NFMSVPX::Int32 = Int32(0)   # number of SVS pictures to render for fire
NSNAG::Int32   = Int32(0)   # highest snag record in use
NSNAGSALV::Int32= Int32(0)
NYRS::Int32    = Int32(0)   # years in a cycle (= IFINT from PLOT)
OLDCOVTYP::Int32= Int32(0)
OLDICT::Int32  = Int32(0)
OLDICT2::Int32 = Int32(0)
PBURNYR::Int32 = Int32(0)   # year of most recent pile burn

# Integer arrays
const DKRCLS = zeros(Int32, MAXSP)     # decay rate class 1-4 per species
const FMICR  = zeros(Int32, MAXTRE)    # crown proportion (ICR) for fire model
const GROW_FM= ones(Int32, MAXTRE)     # ≥1=crowns grow normally; reduced after fire
const ISPCC  = zeros(Int32, MAXTRE)    # species removed (FMTREM→FMEVTBM)
const JFROUT = zeros(Int32, 3)         # fire report file unit numbers
const JLOUT  = zeros(Int32, 3)         # landscape output file unit numbers
const SPS    = zeros(Int32, MXSNAG)    # species of snags
const SPSSALV= zeros(Int32, MXSNAG)
const YRDEAD = zeros(Int32, MXSNAG)   # year of death for each snag record

# Real scalars
CANMHT::Float32 = Float32(0.0)   # min HT for canopy base height calc
CBHCUT::Float32 = Float32(0.0)   # cutoff for canopy base height
CRBURN::Float32 = Float32(0.0)   # proportion with crown fire
CWDCUT::Float32 = Float32(0.0)   # proportion of CWD2B cut by salvage
FOLMC::Float32  = Float32(0.0)   # foliar moisture content (%)
FMSLOP::Float32 = Float32(0.0)
HTR1::Float32   = Float32(0.0)   # base height-loss rate first 50%
HTR2::Float32   = Float32(0.0)   # base height-loss rate second 50%
HTXSFT::Float32 = Float32(0.0)
LIMBRK::Float32 = Float32(0.0)   # fraction of non-foliage crown falling per year
NZERO::Float32  = Float32(0.0)   # snags per stand considered = 0
PBSCOR::Float32 = Float32(0.0)   # scorch height threshold for post-burn rules
PBSIZE::Float32 = Float32(0.0)   # DBH between small and large snags
PBSMAL::Float32 = Float32(0.0)   # proportion of small snags to fall
PBSOFT::Float32 = Float32(0.0)   # proportion of soft snags to fall
PBTIME::Float32 = Float32(0.0)   # post-burn time period (years)
PERCOV::Float32 = Float32(0.0)   # percent cover of stand
PRSNAG::Float32 = Float32(0.0)   # proportion of cut becoming snags
SCCF::Float32   = Float32(0.0)   # stand-level CCF (%)
TONRMC::Float32 = Float32(0.0)   # tons removed via CWD transfers
TONRMH::Float32 = Float32(0.0)   # tons removed via harvest
TONRMS::Float32 = Float32(0.0)   # tons removed via salvage
TOTACR::Float32 = Float32(0.0)   # total landscape acres

# Real arrays (per-species)
const ALLDWN = zeros(Float32, MAXSP)   # time until last 5% of lg. snags fallen
const DECAYX = zeros(Float32, MAXSP)   # decay rate correction factor
const DKRDEF = zeros(Float32, 4)       # default mineralization rates
const FALLX  = zeros(Float32, MAXSP)   # fall rate correction per species
const FLIVE  = zeros(Float32, 2)       # live fuels: 1=herbs, 2=shrubs
const FMTBA  = zeros(Float32, MAXSP)   # fire model total BA per species
const LEAFLF = zeros(Float32, MAXSP)   # leaf lifespan (years)
const PSOFT  = zeros(Float32, MAXSP)   # proportion of snags initially soft
const V2T    = zeros(Float32, MAXSP)   # volume (cuft) to tons conversion
const HTX    = zeros(Float32, MAXSP, 4)
const MAXHT  = zeros(Float32, MAXSP, 19)
const MINHT  = zeros(Float32, MAXSP, 19)
const DSPDBH = zeros(Float32, MAXSP, 19)
const TFALL  = zeros(Float32, MAXSP, 6)   # time until crown falls (0:5 → 1:6 in Julia)

# Real arrays (per-tree)
const CROWNW   = zeros(Float32, MAXTRE, 6)   # crown weight by size class (0:5 → 1:6)
const CURKIL   = zeros(Float32, MAXTRE)   # fire-killed trees this year
const FIRKIL   = zeros(Float32, MAXTRE)   # fire-killed trees this cycle
const FMPROB   = zeros(Float32, MAXTRE)   # PROB for fire model
const FMORTMLT = zeros(Float32, MAXTRE)   # tree mortality multiplier
const OLDCRL   = zeros(Float32, MAXTRE)   # crown length at end of previous cycle
const OLDCRW   = zeros(Float32, MAXTRE, 6) # crown weights from prev cycle
const OLDHT    = zeros(Float32, MAXTRE)   # height at end of previous cycle
const SNGNEW   = zeros(Float32, MAXTRE)   # new snags to add
const PREMST   = zeros(Float32, MAXTRE)
const PREMCR   = zeros(Float32, MAXTRE)
const DBHC     = zeros(Float32, MAXTRE)
const HTC      = zeros(Float32, MAXTRE)
const CROWNWC  = zeros(Float32, MAXTRE, 6)

# Real arrays (per-snag)
const DBHS       = zeros(Float32, MXSNAG)
const DBHSSALV   = zeros(Float32, MXSNAG)
const DENIH      = zeros(Float32, MXSNAG)
const DENIS      = zeros(Float32, MXSNAG)
const DEND       = zeros(Float32, MXSNAG)
const HTDEAD     = zeros(Float32, MXSNAG)
const HTDEADSALV = zeros(Float32, MXSNAG)
const HTIH       = zeros(Float32, MXSNAG)
const HTIHSALV   = zeros(Float32, MXSNAG)
const HTIS       = zeros(Float32, MXSNAG)
const HTISSALV   = zeros(Float32, MXSNAG)
const PBFRIH     = zeros(Float32, MXSNAG)
const PBFRIS     = zeros(Float32, MXSNAG)
const SALVSPA    = zeros(Float32, MXSNAG, 2)
const HARD_FM    = fill(false, MXSNAG)   # true if initially-hard snag still hard
const HARDSALV   = fill(false, MXSNAG)

# CWD arrays
const CWD    = zeros(Float32, 3, MXFLCL, 2, 5)    # (piled/unpiled/total, fuel_class, soft/hard, decay_rate)
const CWD2B  = zeros(Float32, 4, 6, TFMAX)         # debris in waiting (0:5 → 1:6 crown classes)
const CWD2B2 = zeros(Float32, 4, 6, TFMAX)
const CWDVOL = zeros(Float32, 3, 10, 2, 5)
const CWDCOV = zeros(Float32, 3, 10, 2, 5)
const CWDNEW = zeros(Float32, 2, MXFLCL)
const DKR    = zeros(Float32, MXFLCL, 4)
const PRDUFF = zeros(Float32, MXFLCL, 4)
const PRPILE = zeros(Float32, MXFLCL)
const SETDECAY = fill(Float32(-1.0), MXFLCL, 4)
const TODUFF = zeros(Float32, MXFLCL, 4)

# Landscape arrays
const FUAREA  = zeros(Float32, 5, 4)
const SNPRCL  = zeros(Float32, 6)
const TCWD    = zeros(Float32, 6)
const TCWD2   = zeros(Float32, 6)
const OLDICTWT= zeros(Float32, 2)
