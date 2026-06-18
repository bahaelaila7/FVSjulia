"""
FVSjulia — Julia reimplementation of the Forest Vegetation Simulator (FVS),
Southern variant (FVSsn). Faithful 1-to-1 translation of the Fortran 77
codebase in /workspace/ForestVegetationSimulator/bin/FVSsn_buildDir/.

Source of truth: 512 resolved .f files + 51 .F77 COMMON block includes.
"""
module FVSjulia

using Printf
using Dates
using SQLite
using DBInterface

# ---------------------------------------------------------------------------
# 1. Program parameters — MUST come first (all other files depend on MAXTRE, etc.)
# ---------------------------------------------------------------------------
include("common/prgprm.jl")       # MAXTRE=3000, MAXSP=90, MAXCYC=40, MAXPLT=500

# ---------------------------------------------------------------------------
# 2. Fire model parameters — needed before fmcom.jl (MXSNAG, MXFLCL, TFMAX)
# ---------------------------------------------------------------------------
include("common/fmparm.jl")       # MXSNAG=2000, MXFLCL=11, TFMAX=60

# ---------------------------------------------------------------------------
# 3. Operations scheduling parameters — needed before opcom.jl
# ---------------------------------------------------------------------------
# (OPCOM dimensions defined inline in opcom.jl)

# ---------------------------------------------------------------------------
# 4. Establishment model parameters — needed before escomn.jl
# ---------------------------------------------------------------------------
include("common/esparm.jl")       # NDBHCL=10, NSPSPE=72

# ---------------------------------------------------------------------------
# 5. Core tree and simulation COMMON blocks
# ---------------------------------------------------------------------------
include("common/arrays.jl")       # ARRAYS.F77 — per-tree: DBH, HT, ISP, PROB, ...
include("common/contrl.jl")       # CONTRL.F77 — control flags, IO units, ICYC, BA, TPROB, ...
include("common/plot.jl")         # PLOT.F77 — stand/plot data (deduped vs contrl.jl)
include("common/outcom.jl")       # OUTCOM.F77 — output percentile arrays
include("common/econ.jl")         # ECON.F77 — economics flags (LECON, LECBUG)
include("common/workcm.jl")       # WORKCM.F77 — scratch work arrays
include("common/pden.jl")         # PDEN.F77 — plot density arrays
include("common/coeffs.jl")       # COEFFS.F77 — species growth coefficients
include("common/calcom.jl")       # CALCOM.F77 — calibration control
include("common/calden.jl")       # CALDEN.F77 — calibration density
include("common/varcom.jl")       # VARCOM.F77 — variant-specific variables
include("common/htcal.jl")        # HTCAL.F77 — height growth calibration
include("common/multcm.jl")       # MULTCM.F77 — species growth multipliers
include("common/rancom.jl")       # RANCOM.F77 — RNG state
include("common/cwdcom.jl")       # CWDCOM.F77 — crown width user coefficients
include("common/glblcntl.jl")     # GLBLCNTL.F77 — global control/restart mechanism
include("common/metric.jl")       # METRIC.F77 — unit conversion constants
include("common/screen.jl")       # SCREEN.F77 — screen output control
include("common/sncom.jl")        # SNCOM.F77 — sn variant: ISEFOR, KODIST

# ---------------------------------------------------------------------------
# 6. Operations / Event Monitor COMMON blocks
# ---------------------------------------------------------------------------
include("common/keycom.jl")       # KEYCOM.F77 — keyword name table
include("common/opcom.jl")        # OPCOM.F77 — activities / event monitor

# ---------------------------------------------------------------------------
# 7. Output / summary COMMON blocks
# ---------------------------------------------------------------------------
include("common/sumtab.jl")       # SUMTAB.F77 — summary table
include("common/stdstk.jl")       # STDSTK.F77 — previous-cycle tree attrs
include("common/sstgmc.jl")       # SSTGMC.F77 — structural stage
include("common/ggcom.jl")        # GGCOM.F77 — GENGYM variables / bark beetle
include("common/fvsstdcm.jl")     # FVSSTDCM.F77 — FVSStand post-processor
include("common/volstd.jl")       # VOLSTD.F77 — volume standard config

# ---------------------------------------------------------------------------
# 8. Stand visualization (SVS) COMMON blocks
# ---------------------------------------------------------------------------
include("common/svdata.jl")       # SVDATA.F77 — SVS tree/object arrays
include("common/svdead.jl")       # SVDEAD.F77 — SVS snag/CWD arrays
include("common/svrcom.jl")       # SVRCOM.F77 — SVS RNG state

# ---------------------------------------------------------------------------
# 9. DBS/SQLite extension COMMON blocks
# ---------------------------------------------------------------------------
include("common/dbscom.jl")       # DBSCOM.F77 — DBS output switches / file names
include("common/dbstk.jl")        # DBSTK.F77 — DBS subroutine stack

# ---------------------------------------------------------------------------
# 10. Establishment model COMMON blocks
# ---------------------------------------------------------------------------
include("common/escomn.jl")       # ESCOMN.F77 — estab model main common
include("common/escom2.jl")       # ESCOM2.F77 — estab model block 2
include("common/eshap.jl")        # ESHAP.F77 — estab control variables
include("common/eshap2.jl")       # ESHAP2.F77 — estab per-plot arrays
include("common/eshoot.jl")       # ESHOOT.F77 — stump sprout data
include("common/esrncm.jl")       # ESRNCM.F77 — estab RNG state
include("common/estcor.jl")       # ESTCOR.F77 — estab height correction
include("common/estree.jl")       # ESTREE.F77 — estab tree mortality years
include("common/eswsbw.jl")       # ESWSBW.F77 — spruce budworm interaction

# ---------------------------------------------------------------------------
# 11. Fire/FFE extension COMMON blocks
# ---------------------------------------------------------------------------
include("common/fmcom.jl")        # FMCOM.F77 — fire model main variables
include("common/fmfcom.jl")       # FMFCOM.F77 — fire burn model variables
include("common/fmprop.jl")       # FMPROP.F77 — carbon fate of products
include("common/fmsvcm.jl")       # FMSVCM.F77 — fire SVS scratch arrays

# ---------------------------------------------------------------------------
# 12. Economics extension COMMON blocks
# ---------------------------------------------------------------------------
include("common/ecncom.jl")       # ECNCOM.F77 — extended economics
include("common/ecncomsaves.jl")  # ECNCOMSAVES.F77 — economics state across cycles

# ---------------------------------------------------------------------------
# 13. SVN / version stamp
# ---------------------------------------------------------------------------
include("common/includesvn.jl")   # INCLUDESVN.F77 — version string
include("common/volinput_mod.jl") # VOLINPUT_MOD — merch rule user overrides (MRULEMOD, NEWxxx globals)

# ---------------------------------------------------------------------------
# 14. IO unit registry
#     In FVS, IO units are integers (6=stdout, 7=listing, 8=summary, 9=tree list, etc.)
#     We map them to Julia IO objects here.
# ---------------------------------------------------------------------------
const io_units = Dict{Int32, IO}()

function _init_io_units!()
    io_units[Int32(0)]  = stderr
    io_units[Int32(6)]  = stdout   # JOSTND
    io_units[Int32(7)]  = stdout   # JOLIST (may be redirected to file)
    io_units[Int32(8)]  = stdout   # JOSUM
    io_units[Int32(9)]  = stdout   # JOTREE
end

# ---------------------------------------------------------------------------
# 15. Base subroutines (Phase 2 — translated from bin/FVSsn_buildDir/*.f)
# ---------------------------------------------------------------------------
include("base/algslp.jl")      # ALGSLP: piecewise linear interpolation (must come before utils.jl)
include("base/basdam.jl")      # BASDAM: apply defect/special-status damage codes (called by DAMCDS in utils.jl)
include("base/utils.jl")       # upcase, ch2num, upkey, unblnk, tresor, behre, DAMCDS, NUMLOG, ...
include("base/ch4sort.jl")    # CH4BSR, CH4SRT: char*4 binary search and index sort
include("base/sf_taper.jl")  # SF_TAPER: compute taper coefficients from geometric properties
include("base/filopn.jl")    # FILOPN, FILClose, openIfClosed, MYOPEN
include("base/spctrn.jl")    # SPCTRN: species code translation table (562 entries)
include("base/intree.jl")    # INTREE: .tre file reader → per-tree arrays
include("base/keywd.jl")    # KEYRDR, KEYFN, FNDKEY, KEYOPN, KEYDMP
include("base/lnk.jl")     # LNKCHN, LNKINT (chain sort)
include("base/notre.jl")   # NOTRE: trees/acre calculation
include("base/fvs.jl")     # FVS!: main simulation driver
include("base/comprs.jl")  # COMPRS: tree list compression (PCA + gap/range split)
include("base/grincr.jl")  # GRINCR: compute growth increments + harvest
include("base/gradd.jl")   # GRADD: apply increments, update records, establishment
include("base/tregro.jl")  # TREGRO: per-cycle growth driver (calls GRINCR + GRADD)
include("base/errgro.jl")  # ERRGRO + GRSTOP + fvsGetICCode: error dispatcher (54 codes)
include("base/sgdecd.jl")  # SGDECD: species group name decoder
include("base/spdecd.jl")  # SPDECD: species code decoder (alpha + numeric + groups)
include("base/ptgdecd.jl") # PTGDECD: point group name decoder
include("base/opinit.jl")  # OPINIT: initialize activity schedule pointers
include("base/opnew.jl")   # OPNEW + OPMODE: activity list insertion
include("base/opcycl.jl")  # OPCYCL: map activities to simulation cycles
include("base/setup.jl")   # SETUP: build IND1 from IND2 linked chains
include("base/revise.jl")  # REVISE: return latest revision date for variant
include("base/grdtim.jl")  # GRDTIM: formatted date/time strings
include("base/dbinit.jl")  # DBINIT: initialize debug subroutine stack
include("base/dbadd.jl")   # DBADD: add subroutine name+cycle to debug stack
include("base/dbscan.jl")  # DBSCAN: search debug stack for name+cycle match
include("base/dball.jl")   # DBALL: add all-subroutines debug entry
include("base/dbchk.jl")   # DBCHK (4-arg): check if subroutine is being debugged
include("base/dbprse.jl")  # DBPRSE: parse DEBUG keyword continuation record
include("base/opsort.jl")  # OPSORT: Quickersort for activity list (two-key)
include("base/opexpn.jl")  # OPEXPN: expand all-cycle activities to per-cycle copies
include("base/opadd.jl")   # OPADD/OPREDT/OPCOPY/OPSCHD/OPINCR: dynamic activity scheduling
include("base/opcact.jl")  # OPCACT: store character string for most recently added activity
include("base/opdon2.jl")  # OPDON2: set activity status done (date-range search)
include("base/opget2.jl")  # OPGET2: retrieve pending activity by date range
include("base/opget3.jl")  # OPGET3: retrieve accomplished activity by date range
include("base/opnewc.jl")  # OPNEWC: add activity with expression (PARMS) parameters
include("base/oprdat.jl")  # OPRDAT: read activities from external file and add to schedule
include("base/opsame.jl")  # OPSAME: delete duplicate activity groups in event monitor
include("base/volstubs.jl") # VOLEQDEF/NVBEQDEF/FIAHEAD/VOLEQHEAD/NVB_REGION_CHECK/CLMAXDEN stubs
include("base/sdical.jl")  # SDICAL/SDICLS/CCCLS/RDCLS/RDCLS2/RDSLTR/SILFTY
include("base/rann.jl")    # RANN/RANSED/RANNGET/RANNPUT: Park-Miller LCG RNG
include("base/opmerg.jl")  # OPMERG: merge caller activity list with current cycle
include("base/opfind.jl")  # OPFIND/OPGET/OPGETC/OPCHPR/OPDONE/OPDEL1/OPDEL2/OPDEL3
include("base/opstus.jl")  # OPSTUS/OPEVAC: check activity status without modifying it
include("base/iqrsrt.jl")  # IQRSRT: ascending integer Quickersort
include("base/iapsrt.jl")  # IAPSRT: integer ascending indirect identification sort
include("base/rdpsrt.jl")  # RDPSRT: real descending indirect Quickersort
include("base/isstag.jl")        # ISSTAG/RQSSTG/KSSTAG: stand structural stage classification
include("base/sdefet.jl")       # SDEFET: process BFDEFECT/MCDEFECT keywords (species defect table)
include("base/setcubicdflts.jl") # SETCUBICDFLTS: variant/forest cubic volume merchandising defaults
include("base/bachlo.jl")  # BACHLO: Batchelor normal random variate (needed by algmon.jl/ALGEVL NORMAL)
include("base/extstubs.jl") # No-op stubs for extension/untranslated functions
include("base/svutils.jl") # SVS geometry utilities: SVRANN/SVRSED/SVCROL/SVNTR/SVHABT/SVGTPT/SVONLN/SVDFLN + FVSOLDSEC/FVSOLDFST
include("base/svkey.jl")   # SVKEY: process SVS visualization keyword
include("base/svcuts.jl")  # SVCUTS: update SVS after harvest, compress object list
include("base/estump.jl")  # ESTUMP: store stump sprout records + ESASID
include("base/algmon.jl")  # ALGPTG/ALGSPP/ALGKEY/ALGEXP/ALGCMP/ALGEVL: event monitor algebra
include("base/lbops.jl")        # LB1MEM/LBMEMR/LBUNIN/LBINTR/LBTRIM/LBDSET/LBSPLR/LBAGLR/LBSTRD/RCDSET
include("base/evtstv.jl")       # EVTSTV/EVSET4/EVUST4/EVGET4: test variable tables + FISHER_SN stub
include("base/evmon_support.jl") # EVAGE/EVALNK/EVCOMP/EVIF/EVPOST/EVUSRV + FISHER_SN real impl
include("base/evldx.jl")         # EVLDX: event monitor variable loader (stand stats, fire, climate)
include("base/evtact.jl")  # EVTHEN/EVALSO/EVEND: IF-THEN/ALSOTRY/ENDIF event monitor keyword handlers
include("base/evmon.jl")   # EVMON: event monitor dispatcher (calls ALGEVL/EVTSTV/EVPOST stubs)
include("base/sdefln.jl")    # SDEFLN: set species log-linear defect correction coefficients
include("base/ffin.jl")      # FFIN: schedule FERTILIZER keyword (activity 260)
include("base/stash.jl")     # STASH/DSTASH/CHSTSH/CHDSTH: binary checkpoint I/O
include("base/putgetsubs.jl")# BFREAD/BFWRIT/CHREAD/CHWRIT/LFREAD/LFWRIT/IFREAD/IFWRIT
include("base/chputget.jl")  # CHPUT/CHGET: character variable serialization
include("base/putstd.jl")    # PUTSTD: serialize all FVS stand state to stash buffer
include("base/getstd.jl")    # GETSTD: deserialize FVS stand state from stash buffer
include("base/getsed.jl")    # GETSED: generate RNG seed from time
include("base/uuidgen.jl")   # UUIDGEN: UUID v4 string generation
include("base/meansd.jl")    # MEANSD: mean and standard deviation
include("base/initre.jl")    # INITRE: stand initialization + keyword dispatch

# ---------------------------------------------------------------------------
# 16. sn-specific additions / overrides (Phase 2)
# ---------------------------------------------------------------------------
include("sn/blkdat.jl")       # BLKDAT!(): 90-species data + IO unit defaults

include("sn/dgf.jl")       # DGF: diameter growth equation; DGCONS: site constants
include("base/dgscor.jl")  # DGSCOR: auto-correlated DG prediction error for next cycle
include("base/mults.jl")   # MULTS: apply species multiplier keywords (BAIMULT, HTGMULT, etc.)
include("sn/dgdriv.jl")   # DGDRIV: diameter growth driver (calibration + normal mode)
include("sn/htcalc.jl")   # HTCALC: NC128 height-age curve + increment (mode 0/1/9)
include("sn/htgf.jl")     # HTGF: height growth driver; HTCONS: initialize HTCON[]
include("sn/morts.jl")    # MORTS: SDI + background + FIXMORT mortality; MORCON: init
include("sn/formcl.jl")   # FORMCL: form class (sn override — identical to base vanilla)
include("base/formclas.jl")  # FORMCL_BM/CA/EC/NI/PN/SO/WC: region-specific form class lookup (for r6vol)
include("base/mrules.jl")    # MRULES: set regional merchandizing rule defaults by REGN (uses VOLINPUT_MOD)
include("base/volkey.jl")   # VOLKEY: process VOLUME/BFVOLUME/MCDEFECT/BFDEFECT keywords (activity 215-218)
include("sn/findag.jl")   # FINDAG: find tree age from height via HTCALC mode 0
include("sn/varget.jl")   # VARGET + VARCHGET: read variant scalars from parallel buffer
include("sn/varput.jl")   # VARPUT + VARCHPUT: write variant scalars to parallel buffer
include("sn/varmrt.jl")   # VARMRT: distribute density mortality by shade tolerance
include("sn/grohed.jl")   # GROHED: write FVS output header (sn variant)
include("sn/grinit.jl")  # GRINIT: initialize model variables (sn variant)
include("sn/sitset.jl")  # SITSET: site index + volume spec defaults (sn variant)
include("sn/bratio.jl") # BRATIO: bark ratio DIB/DBH (sn 90-species Clark 1991 equations)
include("base/cutstk.jl") # AUTSTK/CLSSTK: stocking calculation helpers
include("base/tremov.jl") # TREMOV: swap two tree records
include("base/tredel.jl") # TREDEL: delete cut/dead trees from tree list
include("sn/dubscr.jl")  # DUBSCR: crown ratio for cycle-0 dead trees
include("sn/crown.jl")   # CROWN/CRCONS: crown ratio model (Weibull + Hoerl/Power/Linear/Log/Inverse)
include("base/pctile.jl") # PCTILE: compute tree-attribute percentiles (returns total)
include("base/dist.jl")   # DIST: find DBH at 5 percentile points of the distribution
include("base/comp.jl")   # COMP: species composition percentages (top 4 classes)
include("base/opcset.jl") # OPCSET: set up per-cycle activity sort (calls IAPSRT)
include("base/mbacal.jl") # MBACAL: identify site species (max basal area)
include("base/cwcalc.jl") # CWCALC: crown width equations library (166 species, 5 equation types)
include("base/ccfcal.jl") # CCFCAL: per-tree crown competition factor (CCF)
include("base/cuts.jl")   # CUTS: thinning/harvest/pruning for one cycle (17 thin types)
include("base/ptbal.jl")  # PTBAL: point basal area in larger trees (called from DENSE)
include("base/dense.jl")  # DENSE: stand density statistics (CCF, BA, AVH, RMSQD)
include("base/cwidth.jl") # CWIDTH: crown width computation + FIXCW keyword
include("base/update.jl") # UPDATE: add growth, deduct mortality, call VOLS, advance DBH
include("base/damcds.jl")  # DAMCDS: dispatch damage codes to base model + store in DAMSEV
include("base/dampro.jl")  # DAMPRO: dispatch damage codes to extension handlers for all trees
include("base/wdbkwt_data.jl") # WDBKWT: 2677-species wood/bark weight table for Jenkins biomass
include("base/fia_se_vol.jl") # SRS_VOL: FIA Southern Research Station volume equations (fia_se_vol.for)
include("base/r8clark_vol.jl") # _R8CLARK_VOL: R8 New Clark volume equations (r8prep.f + r9clark.f)
include("base/fvsvol.jl")   # NATCRS/OCFVOL/OBFVOL/GETEQN: variant-specific volume entry points
include("base/behprm.jl")  # BEHPRM: compute Behre hyperbola taper params AHAT/BHAT
include("base/cfvol.jl")   # CFVOL: cubic foot volume by user-defined equation (CFVOLEQ keyword)
include("base/bfvol.jl")   # BFVOL: board foot volume by user-defined equation (BFVOLEQU keyword)
include("base/cftopk.jl")  # CFTOPK: correct cubic foot volumes for broken/damaged top
include("base/bftopk.jl")  # BFTOPK: correct board foot volume for dead/damaged top
include("base/disply.jl") # DISPLY: stand statistics output + IOSUM population
include("base/vols.jl")   # VOLS: tree volume + defect + distribution (PCTILE/DIST/COMP)
include("base/covolp.jl")  # COVOLP: canopy cover computation with Poisson crown overlap model
include("base/sstage.jl") # SSTAGE/FMSSTAGE/UPDATECCCOEF: structural stage classification (7 classes)
include("base/miscal.jl") # MAICAL/AVHT40/SDICHK: mean annual increment + height + SDI check
include("base/htdbh.jl")  # HTDBH: Curtis-Arney height-diameter relationship (90 sn species)
include("base/rcon.jl")   # RCON: load site-dependent coefficients (calls DGCONS/HTCONS/REGCON/MORCON/CRCONS)
include("sn/dgbnd.jl")   # DGBND: diameter growth bounds check (90-species DLODHI array)
include("base/regent.jl") # REGENT/REGCON: small-tree height/diameter growth + calibration
include("base/cratet.jl") # CRATET: calibration, height dubbing, crown dubbing, age estimation
include("base/esinit.jl") # ESINIT/ESEZCR: regeneration establishment model init (estb extension)
include("base/esin.jl")   # ESIN: establishment keyword processor (PLANT/NATURAL/ESTAB/END)
include("base/esplt.jl")  # ESPLT1/ESPLT2: establishment plot setup (NPTIDS/IPTIDS/site vars)
include("base/esnutr.jl") # ESNUTR: per-cycle establishment driver (calls ESTAB)
include("base/essprt.jl") # ESSPRT/NSPREC/SPRTHT/ASSPTN: stump-sprout helpers
include("base/esuckr.jl") # ESUCKR: create stump & root sprouts from cut trees
include("base/estab_helpers.jl") # ESSUBH/ESPREP/ESTIME/ESETPR/ESGENT (ESTAB helpers)
include("base/estab.jl")  # ESTAB: regeneration establishment tree creation (PLANT path)
# (ESUCKR is never called for snt01 — loblolly doesn't sprout, ITRNRM stays 0 — so
#  its stub is fine. ESTAB is still stubbed: BARE reaches it but creates no trees
#  yet; non-establishment stands take the no-op path through ESNUTR.)
include("sn/habtyp.jl")   # HABTYP/HBDECD: habitat type decoder (320 sn ecological unit codes)
include("sn/forkod.jl")   # FORKOD: forest/district code translation (sn variant, 20 national forests + R9)
include("sn/nbolt.jl")    # NBOLT: number of 8-ft bolts to sawtimber/pulpwood top (Ek et al. 1984)
# cubrds.f — BLOCK DATA init: all VOLSTD arrays already zero-initialized in common/volstd.jl
include("base/stkval.jl") # STKVAL: per-ITG-group stocking computation (TAB2/TAB3 data)
include("base/fortyp.jl") # FORTYP: forest type classification decision tree (calls STKVAL)
include("base/triple.jl") # TRIPLE/REASS: tree-record tripling for stochastic mortality + pointer realignment
include("base/htgstp.jl") # HTGSTP: height growth stop / top-kill (keywords 110/111)
include("base/ffert.jl")  # FFERT: fertilization diameter+height growth adjustment (keyword 260)
include("base/lbsplw.jl") # LBSPLW: write SLSET string in 100-char chunks to output unit
include("base/spesrt.jl") # SPESRT: species sort (reset pointers, re-link, call SETUP)
include("base/comcup.jl")  # COMCUP: interface for tree-list compression (act=250, COMPRESS keyword)
include("base/sumhed.jl") # SUMHED: write summary statistics header to screen output
include("base/sumout.jl") # SUMOUT: write per-period summary rows (formatted + machine-readable)
include("base/opbisr.jl") # OPBISR: binary search in sorted ascending Int32 array
include("base/oplist.jl") # OPLIST: write activity schedule / disposition summary
include("base/prtexm.jl") # PRTEXM: print example-tree/stand-attribute table from binary file
include("base/sdichk.jl") # SDICHK: check/reset initial SDI maximum (called from SITSET)
include("base/stats.jl")  # STATS: cruise statistics (TPA/BA/CF/BF/biomass/carbon) + TVALUE/DBSSTATS stubs
include("base/gheads.jl")    # GHEADS/FIAHEAD/VOLEQHEAD: stand composition + example tree headings
include("base/vernum.jl")    # VERNUM/VERNUM2/VERNUM_F: volume library version number (20260209)
include("base/calcbiomass.jl") # CalcBiomass/BiomassLibrary stubs (NBEL pending)
include("base/cutqfa.jl")    # CUTQFA/CYCQFA: Q-factor diameter-class thinning (THINQFA keyword)
include("base/resage.jl")    # RESAGE: reset stand age from RESETAGE keyword
include("base/genrpt.jl")   # GENRPT/GETID/GETLUN/GENPRT/GETNRPTS/SETNRPTS: multi-report scratch output
include("base/extree.jl")   # EXTREE: assign example trees to output arrays
include("base/autcor.jl")   # AUTCOR: ARMA(1,1) variance/covariance for DG random component
include("sn/avht40.jl")     # AVHT40: average height of 40 TPA largest-diameter trees
include("base/cmdline.jl")   # fvsSetCmdLine / fvsGetRtnCode / fvsStopPoint / fvsRestart (API)
include("base/main.jl")      # main(): entry point (wraps fvsSetCmdLine + FVS loop)

# ---------------------------------------------------------------------------
# 17. Extensions (Phase 3 — stub placeholders; all functions are no-ops in extstubs.jl)
# ---------------------------------------------------------------------------
include("extensions/dbs/dbsqlite.jl")    # SQLite output tables (DBS extension)
include("extensions/fiavbc/fiavbc.jl")   # FIAVBC biomass (stub)
include("extensions/fire/fire.jl")       # Fire simulation (stub)
include("extensions/pests/pests.jl")     # Pest models (stub)
include("extensions/econ/ecin.jl")       # Economics keyword reader (ECIN)
include("extensions/econ/eccalc.jl")     # Economics ECSETP/ECSTATUS/ECCALC

# ---------------------------------------------------------------------------
# 17b. Tree list output — must load after extensions so _dbs_out_db etc. are defined
# ---------------------------------------------------------------------------
include("base/prtrls.jl")    # PRTRLS/DBSTRLS/DBSATRTLS/DBSCUTS: tree list output to SQLite

# ---------------------------------------------------------------------------
# 18. Module initialization — mirrors Fortran BLOCK DATA (runs at module load)
# ---------------------------------------------------------------------------
BLKDAT!()
FMCBLK!()  # initialize fire carbon product tables (FAPROP, BIOGRP)

# ---------------------------------------------------------------------------
# 19. Public entry point
# ---------------------------------------------------------------------------
# main() is provided by base/main.jl (included above).
# The module-level initializers are called by the FVS! driver via _init_io_units!() etc.

end # module FVSjulia
