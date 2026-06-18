# FMFCOM.F77 — Fire burn model variables (COMMON /FMFCOM/, /CRBCOM/, /CFIMCOM/)
# Depends on: fmparm.jl (MXFLCL, MXFMOD, MXDFMD, TFMAX), prgprm.jl (MAXTRE, MAXSP, MAXCYC)
# All variables from FMFCOM.F77 — complete translation (not abbreviated)

# ---------------------------------------------------------------------------
# COMMON /FMFCOM/ — fire burn model parameters
# ---------------------------------------------------------------------------

# Integer scalars (NOTE: ACTCBH and ATEMP are declared INTEGER in Fortran)
ACTCBH::Int32   = Int32(0)    # canopy base height (integer feet)
ATEMP::Int32    = Int32(0)    # air temperature (integer °F)
BURNSEAS::Int32 = Int32(2)    # fire season: 1=early spring,2=before greenup,3=after,4=fall
FIRTYPE::Int32  = Int32(0)    # fire type: 1=active crown, 2=passive crown, 3=surface
FLAG = zeros(Int32, 3)         # error flags (3 values per fire event)
FM89YR::Int32   = Int32(0)    # year of FM8/9→FM5/26 switch (CA shrub delay)
IFLOGIC::Int32  = Int32(0)    # fire behavior method: 0=old, 1=new, 2=modelled loads
IFMSET::Int32   = Int32(0)    # fuel model set: 0=13, 1=40, 2=53 (new FM logic)
JSNOUT::Int32   = Int32(0)    # snag output table unit
JPOTFL::Int32   = Int32(0)    # potential-fire text report unit (0 = no text file)
ND::Int32       = Int32(0)    # number of dead fuel size classes in current FM
NL::Int32       = Int32(0)    # number of live fuel size classes
NFMODS::Int32   = Int32(0)    # number of active user-defined fuel models
SOILTP::Int32   = Int32(1)    # soil type: 1=Loamy Skeletal,2=Fine Silt,3=Fine,4=Coarse Silt,5=Coarse Loam
IDRYB::Int32    = Int32(0)    # beginning year of scheduled drought
IDRYE::Int32    = Int32(0)    # ending year of scheduled drought

# Report begin/end year integers (begin=-99999 means disabled)
IFMBRB::Int32   = Int32(-99999)  # burn conditions report begin
IFMBRE::Int32   = Int32(-99999)  # burn conditions report end
IFMFLB::Int32   = Int32(-99999)  # fuel consumption report begin
IFMFLE::Int32   = Int32(-99999)  # fuel consumption report end
IFMMRB::Int32   = Int32(-99999)  # mortality report begin
IFMMRE::Int32   = Int32(-99999)  # mortality report end
IFLALB::Int32   = Int32(-99999)  # all fuels report begin
IFLALE::Int32   = Int32(-99999)  # all fuels report end
IPFLMB::Int32   = Int32(-99999)  # potential flame report begin
IPFLME::Int32   = Int32(-99999)  # potential flame report end
ISNAGB::Int32   = Int32(-99999)  # snag report begin
ISNAGE::Int32   = Int32(-99999)  # snag report end
ICFPB::Int32    = Int32(-99999)  # canopy fuels profile table begin
ICFPE::Int32    = Int32(-99999)  # canopy fuels profile table end
IDWRPB::Int32   = Int32(-99999)  # down wood volume report begin
IDWRPE::Int32   = Int32(-99999)  # down wood volume report end
IDWCVB::Int32   = Int32(-99999)  # down wood cover report begin
IDWCVE::Int32   = Int32(-99999)  # down wood cover report end
ISHEATB::Int32  = Int32(-99999)  # soil heat report begin
ISHEATE::Int32  = Int32(-99999)  # soil heat report end

# Report ID numbers
IDBRN::Int32    = Int32(0)    # burn conditions report ID
IDFUL::Int32    = Int32(0)    # fuel consumption report ID
IDMRT::Int32    = Int32(0)    # mortality report ID
IDFLAL::Int32   = Int32(0)    # all fuels report ID
IDPFLM::Int32   = Int32(0)    # potential flame report ID
IDDWRP::Int32   = Int32(0)    # down wood volume report ID
IDDWCV::Int32   = Int32(0)    # down wood cover report ID
IDSHEAT::Int32  = Int32(0)    # soil heat report ID

# Report header flags (trip once to avoid duplicate headers)
IBRPAS::Int32   = Int32(0)
IFLPAS::Int32   = Int32(0)
IMRPAS::Int32   = Int32(0)
IFAPAS::Int32   = Int32(0)
IPFPAS::Int32   = Int32(0)
IDWPAS::Int32   = Int32(0)
IDCPAS::Int32   = Int32(0)

# Real scalars
BURNCR::Float32  = Float32(0.0)   # crown burned for smoke (tons/acre)
CBD::Float32     = Float32(0.0)   # canopy bulk density (lb/ft³)
CCCHNG::Float32  = Float32(0.0)   # % change in canopy cover cycle t→t+1
CCCRIT::Float32  = Float32(0.0)   # critical %CC change for shrub model delay
DEPTH::Float32   = Float32(0.0)   # fuelbed depth (ft) for current fuel model
DPMOD::Float32   = Float32(1.0)   # depth modifier from harvest/treatment
EXPOSR::Float32  = Float32(0.0)   # mineral soil exposure (%)
FIRACR = zeros(Float32, 2)         # fire area: 1=stand only, 2=crowning area
FWIND::Float32   = Float32(0.0)   # dominant wind speed (mi/hr)
WNDSPD::Float32  = Float32(0.0)   # working wind speed for potential-fire scenarios (FMPOFL)
LARGE::Float32   = Float32(0.0)   # coarse fuels loading (ton/acre, >3")
MINSOL::Float32  = Float32(0.0)   # mineral soil exposure in one year
OLARGE::Float32  = Float32(0.0)   # previous year LARGE
OSMALL::Float32  = Float32(0.0)   # previous year SMALL
PBRNCR::Float32  = Float32(0.0)   # potential crown material burned
PRV8::Float32    = Float32(0.0)   # weight of FM8 at shrub model period start
PRV9::Float32    = Float32(0.0)   # weight of FM9 at shrub model period start
RFINAL::Float32  = Float32(0.0)   # final fire spread rate (ft/min)
SCH::Float32     = Float32(0.0)   # scorch height (ft)
SLCHNG::Float32  = Float32(0.0)   # % change in total fuels cycle t→t+1
SLCRIT::Float32  = Float32(10.0)  # critical SLCHNG to trigger activity fuels
SMALL::Float32   = Float32(0.0)   # fine fuel loading (ton/acre, <3")
TCLOAD::Float32  = Float32(0.0)   # total canopy load (lb/ft²)
ULHV::Float32    = Float32(0.0)   # user-entered dead/live heat content (BTU/lb)

# Logical scalars
LFLBRN::Bool  = false   # fuel burning requested in current year
LHEAD::Bool   = true    # true until fire output file headers printed
LATFUEL::Bool = false   # true if activity fuels present >5 yrs
LATSHRB::Bool = false   # true if activity triggered FM shrub dynamics
LPRV89::Bool  = false   # true if FM8/9 and NOT 5/26 in previous year
LUSRFM::Bool  = false   # true if using user-defined fuel models

# Integer arrays (note: MPS and SURFVL are INTEGER in Fortran)
const FMDUSR    = zeros(Int32, 4)             # user-specified fuel model numbers
const FMOD      = zeros(Int32, MXFMOD)        # active fuel model indices
const IFUELMON  = fill(Int32(-1), MXDFMD)     # -1=not set, 0=on, 1=off
const MPS       = zeros(Int32, 2, 4)          # mean particle size (surf/vol): col-major
const PLSIZ     = zeros(Int32, 2)             # lower/upper size for area grouping
const POTSEAS   = fill(Int32(2), 2)           # season for potential fire: 1=wild,2=pres
const POTTYP    = zeros(Int32, 2)             # potential fire type: 1=sfc,2=pass,3=act,4=cond
const SURFVL    = zeros(Int32, MXDFMD, 2, 4)  # surface-to-vol ratio (integer) per fuel model

# Float32 arrays
const BURNED    = zeros(Float32, 3, MXFLCL)       # fuel consumed: (unpiled/piled/total, fuelclass)
const BURNLV    = zeros(Float32, 2)                # live fuel consumed: 1=herbs, 2=shrubs
const CANCLS    = Float32[5.0, 17.5, 37.5, 75.0]  # canopy closure class cutoffs (%)
const CORFAC    = Float32[0.5, 0.3, 0.2, 0.1]     # wind speed correction by canopy class
const FMACRE    = zeros(Float32, 14)               # landscape acres per fuel model
const FMDEP     = zeros(Float32, MXDFMD)           # fuel model depth (ft)
const FMLOAD    = zeros(Float32, MXDFMD, 2, 7)     # fuel model loading: (model,dead/live,class)
const FWG       = zeros(Float32, 2, 7)             # surface loading for current FM (dead/live, 7 classes)
const FWT       = zeros(Float32, MXFMOD)           # weighting for each active fuel model
const FWTUSR    = zeros(Float32, 4)                # user-defined fuel model weightings
const LOWDBH    = Float32[0.0, 5.0, 10.0, 20.0, 30.0, 40.0, 50.0]  # size class lower bounds
const LSW       = fill(false, MAXSP)               # softwood flag per species
const MEXT      = zeros(Float32, 3)                # moisture of extinction (dead fuel)
const MOIS      = zeros(Float32, 2, 5)             # moisture content: (dead/live, class)
const MOISEX    = zeros(Float32, MXDFMD)           # extinction moisture per fuel model
const PFLACR    = zeros(Float32, 4, 3)             # area by flame length-moisture category
const PFLAM     = zeros(Float32, 4)                # potential flame lengths (ft)
const POTEMP    = Float32[70.0, 60.0]              # fire temps (°F): 1=wildfire, 2=prescribed
const POTKIL    = zeros(Float32, 4)                # potential fire mortality (fraction BA)
const POTPAB    = zeros(Float32, 2)                # percent area burned for potential fire
const POTFSR    = zeros(Float32, 4)                # potential fire spread rate (ft/min)
const POTRINT   = zeros(Float32, 2)                # potential fire reaction intensity (BTU/ft²/min)
const POTVOL    = zeros(Float32, 2)                # potential fire mortality (cuft volume)
const PREWND    = Float32[20.0, 8.0]               # potential fire wind (mi/hr): 1=wild, 2=pres
const PRESVL    = zeros(Float32, 2, 8)             # potential fire moisture: (1=wild/2=pres, conditions)
const SCBE      = zeros(Float32, 3)                # holding var for C1 from FMFINT
const SFRATE    = zeros(Float32, 3)                # holding var for fire rate from FMFINT
const SIRXI     = zeros(Float32, 3)                # holding var for XIO (Ir*XI) from FMFINT
const SPHIS     = zeros(Float32, 3)                # holding var for PHIS from FMFINT
const SRHOBQ    = zeros(Float32, 3)                # holding var for RHOBQIG from FMFINT
const SSIGMA    = zeros(Float32, 3)                # holding var for SIGMA from FMFINT
const SXIR      = zeros(Float32, 3)                # holding var for XIR (Ir) from FMFINT
const SMOKE     = zeros(Float32, 2)                # smoke produced: 1=PM2.5, 2=PM10 (tons)
const UBD       = zeros(Float32, 2)                # user bulk density (lbs/ft³): 1=live, 2=dead
const USAV      = zeros(Float32, 3)                # user SAV (1/ft): 1=1hr, 2=herb, 3=live woody

# ---------------------------------------------------------------------------
# COMMON /CRBCOM/ — carbon reporting variables
# ---------------------------------------------------------------------------

IDCRPT::Int32   = Int32(0)      # carbon report ID
ICRPTB::Int32   = Int32(-99999) # carbon report begin year
ICRPTE::Int32   = Int32(-99999) # carbon report end year
ICRPAS::Int32   = Int32(0)      # header trip flag
IDCHRV::Int32   = Int32(0)      # harvested products report ID
ICHRVB::Int32   = Int32(-99999) # harvested products report begin
ICHRVE::Int32   = Int32(-99999) # harvested products report end
ICHPAS::Int32   = Int32(0)      # header trip flag
ICMETH::Int32   = Int32(0)      # carbon method: 0=FFE, 1=Jenkins
ICMETRC::Int32  = Int32(0)      # output units: 0=imperial, 1=metric
ICHABT::Int32   = Int32(1)      # region code for carbon-fate curves
CRDCAY::Float32 = Float32(-1.0) # stump root decay rate/yr (-1=not reported)
const CDBRK     = Float32[0.0, 0.0]   # DBH breakpoint pulp/sawlog: 1=HW, 2=SW
const BIOCON    = zeros(Float32, 2)   # biomass consumed: 1=litter/duff, 2=other
BIOLIVE::Float32 = Float32(0.0)  # FFE live biomass (tons/acre)
const BIOREM    = zeros(Float32, 2)   # removed biomass: 1=Jenkins, 2=FFE
BIOSNAG::Float32 = Float32(0.0)  # FFE snag biomass
BIODDW::Float32  = Float32(0.0)  # FFE down woody debris biomass
BIOFLR::Float32  = Float32(0.0)  # FFE litter+duff biomass
BIOSHRB::Float32 = Float32(0.0)  # FFE herb+shrub biomass
BIOROOT::Float32 = Float32(0.0)  # Jenkins root biomass
const FATE      = zeros(Float32, 2, 2, MAXCYC)  # carbon fate by cycle
const CARBVAL   = zeros(Float32, 17)             # event monitor carbon report values

# ---------------------------------------------------------------------------
# COMMON /CFIMCOM/ — Crown Fire Initiation Model variables
# ---------------------------------------------------------------------------

CFIM_ON::Bool     = false           # CFIM active flag
CFIM_BD::Float32  = Float32(0.0)   # bulk density
CFIM_DC::Float32  = Float32(0.0)   # drought condition code
const CFIM_INPUT  = zeros(Float32, 26)   # CFIM calculation inputs
const POTCONS     = zeros(Float32, 3, 3) # potential fuel consumption
