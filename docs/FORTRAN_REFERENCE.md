# FVS Fortran Codebase Reference

This document describes the structure of the original Fortran FVSsn (Southern variant) codebase
that is being translated to Julia in this package. Use it as a guide when translating `.f` files.

---

## Overview

FVS is an **individual-tree, distance-independent forest growth model**. Each simulation cycle
(default 10 years) does:

1. Reads/initializes tree records from `.tre` file and keywords from `.key` file
2. Runs optional harvest/thinning (`CUTS`)
3. Projects diameter growth (`DGF`), height growth (`HTGF`), crown width (`CWIDTH`)
4. Computes mortality (`MORTS`)
5. Adds new trees via establishment/recruitment (`CRATET`)
6. Compresses the tree list (`COMPRS`)
7. Writes output (`DISPLY`, SQLite tables)

---

## Source Directory Map

| Directory | Role | File count |
|-----------|------|-----------|
| `base/` | Core simulation engine shared by all variants | 155 .f files |
| `common/` | COMMON block include files (global data structures) | 52 .F77 files |
| `sn/` | Southern variant: species coefficients + growth model overrides | 26 .f files + 2 .F77 |
| `dbsqlite/` | SQLite database extension | 47 .f files |
| `fire/` | Fire and Fuels Extension (BEHAVE fire behavior + mortality) | ~60 .f files |
| `fiavbc/` | FIA Volume & Biomass Consistency extension | 2 .f files |
| `mistoe/` | Dwarf mistletoe pathogen model | ~37 .f files |
| `wpbr/` | White pine blister rust | multiple .f |
| `dfb/` | Douglas-fir beetle | multiple .f |
| `lpmpb/wwpb/` | Lodgepole/Western pine mountain beetle | ~97 .f |
| `wsbwe/` | Western spruce budworm + bark beetle | 57 .f |
| `econ/` | Economic calculations | 7 .f |
| `estb/` | Establishment model extension | multiple .f |
| `volume/` | Volume library extensions | multiple .f |
| `bin/FVSsn_buildDir/` | **Resolved build** — all 512 .f + ~51 .F77 files | **translate from here** |

The build directory contains the final merged files with sn variant overrides already applied.
**Translate files from `bin/FVSsn_buildDir/`**, not from `base/` or `sn/` directly.

---

## COMMON Blocks → Julia Module Globals

Fortran `INCLUDE 'FILENAME.F77'` in each subroutine → Julia: all globals are defined at
module level in `src/common/*.jl` and are accessible everywhere in the module.

| Fortran File | Julia File | Contents |
|---|---|---|
| `PRGPRM.F77` | `src/common/prgprm.jl` | All size constants (MAXTRE, MAXSP, etc.) |
| `ARRAYS.F77` | `src/common/arrays.jl` | Per-tree arrays: DBH, HT, ISP, PROB, etc. |
| `CONTRL.F77` | `src/common/contrl.jl` | Simulation control: ICYC, NCYC, JOSTND, etc. |
| `PLOT.F77` | `src/common/plot.jl` | Stand/plot data: BA, TPROB, IAGE, MGMID, etc. |
| `OUTCOM.F77` | `src/common/outcom.jl` | Output arrays, percentiles, title |
| `COEFFS.F77` | `src/common/coeffs.jl` | Species-indexed growth coefficients |
| `ECON.F77` | `src/common/econ.jl` | Simple econ flags |
| `WORKCM.F77` | `src/common/workcm.jl` | Scratch work arrays |
| `PDEN.F77` | `src/common/pden.jl` | Plot density arrays |
| `GLBLCNTL.F77` | `src/common/glblcntl.jl` | Stop/restart codes, keyword file path |
| `CALCOM.F77` | `src/common/calcom.jl` | Calibration control variables |
| `VARCOM.F77` | `src/common/varcom.jl` | Variant-specific variables (SN variant) |
| `HTCAL.F77` | `src/common/htcal.jl` | Height growth calibration |
| `OPCOM.F77` | `src/common/opcom.jl` | Activity schedule / event monitor |
| `CALDEN.F77` | `src/common/calden.jl` | Calibration density arrays |
| `CWDCOM.F77` | `src/common/cwdcom.jl` | Crown width equation coefficients |
| `DBSCOM.F77` | `src/common/dbscom.jl` | DBS/SQLite extension switches |
| `DBSTK.F77` | `src/common/dbstk.jl` | DBS keyword stack |
| `ESCOM2.F77` | `src/common/escom2.jl` | Establishment model (variant full) |
| `ESCOMN.F77` | `src/common/escomn.jl` | Establishment model (base common) |
| `ESHAP.F77` | `src/common/eshap.jl` | Establishment model shape arrays |
| `ESHAP2.F77` | `src/common/eshap2.jl` | Establishment model shape2 |
| `ESHOOT.F77` | `src/common/eshoot.jl` | Stump sprouting arrays |
| `ESPARM.F77` | `src/common/esparm.jl` | Establishment model parameters (sn) |
| `ESRNCM.F77` | `src/common/esrncm.jl` | Random number state for estab |
| `ESTCOR.F77` | `src/common/estcor.jl` | Establishment correction |
| `ESTREE.F77` | `src/common/estree.jl` | Establishment tree array |
| `ESWSBW.F77` | `src/common/eswsbw.jl` | WSB/budworm history for estab |
| `FMCOM.F77` | `src/common/fmcom.jl` | Fire model main variables |
| `FMFCOM.F77` | `src/common/fmfcom.jl` | Fire model burn behavior variables |
| `FMPARM.F77` | `src/common/fmparm.jl` | Fire model parameters |
| `FMPROP.F77` | `src/common/fmprop.jl` | Fire model carbon fate proportions |
| `FMSVCM.F77` | `src/common/fmsvcm.jl` | Fire model SVS visualization |
| `FVSSTDCM.F77` | `src/common/fvsstdcm.jl` | FVSStand output flags |
| `GGCOM.F77` | `src/common/ggcom.jl` | GGenYM (growth model) variables |
| `INCLUDESVN.F77` | `src/common/includesvn.jl` | SVN version string |
| `KEYCOM.F77` | `src/common/keycom.jl` | Keyword table |
| `METRIC.F77` | `src/common/metric.jl` | Metric conversion constants |
| `MULTCM.F77` | `src/common/multcm.jl` | Species growth multipliers |
| `RANCOM.F77` | `src/common/rancom.jl` | Random number state (base) |
| `SCREEN.F77` | `src/common/screen.jl` | Screen output flags |
| `SNCOM.F77` | `src/common/sncom.jl` | SN variant-specific variables |
| `SSTGMC.F77` | `src/common/sstgmc.jl` | Stand structural stage common |
| `STDSTK.F77` | `src/common/stdstk.jl` | Previous-cycle tree data |
| `SUMTAB.F77` | `src/common/sumtab.jl` | Summary table arrays |
| `SVDATA.F77` | `src/common/svdata.jl` | Stand visualization data |
| `SVDEAD.F77` | `src/common/svdead.jl` | Snag/CWD data for SVS |
| `SVRCOM.F77` | `src/common/svrcom.jl` | SVS random state |
| `VOLSTD.F77` | `src/common/volstd.jl` | Volume standard arrays |
| `ECNCOM.F77` | `src/common/ecncom.jl` | Economics (extended) |
| `ECNCOMSAVES.F77` | `src/common/ecncomsaves.jl` | Economics save-state for restart |

---

## Key Subroutines (Call Flow)

```
PROGRAM MAIN  (base/main.f → src/base/main.jl)
  └─ fvsSetCmdLine()            parse --keywordfile= etc.
  └─ loop: FVS(rtnCode)         until rtnCode ≠ 0

SUBROUTINE FVS  (base/fvs.f → src/base/fvs.jl)
  ├─ fvsRestart()               stop/restart mechanism
  ├─ INITRE                     read .key + .tre, init arrays
  │    ├─ KEYINP                parse keyword file
  │    ├─ INTREE                read tree records from .tre
  │    ├─ SITSET (sn)           set site variables
  │    └─ GRINIT (sn)           initialize growth calibration
  ├─ OPEXPN / OPCYCL            expand & schedule activities
  ├─ SETUP                      sort/index tree records by species
  ├─ NOTRE                      compute trees/acre
  ├─ SDICLS                     stand density index by class
  ├─ CRATET (sn)                initial tree establishment
  ├─ CWIDTH                     compute initial crown widths
  ├─ VOLS                       compute initial volumes
  ├─ DISPLY                     write initial stand table
  │
  └─ cycle loop (ICYC = 1..NCYC):
       └─ TREGRO                main growth driver
            ├─ CUTS             harvest/thinning
            │    ├─ CUTQFA      cut by species/size
            │    ├─ CUTSTK      cut by stocking
            │    └─ TREDEL      delete cut trees
            ├─ GROWS            growth calculations
            │    ├─ GRINCR      increments (calls DGF, HTGF)
            │    │    ├─ DGDRIV (sn) → DGF (sn)   diameter growth
            │    │    ├─ HTGF (sn)                 height growth
            │    │    └─ HTCALC (sn)               height from DBH
            │    ├─ MORTS (sn)                     mortality
            │    ├─ CRATET (sn)                    new tree establishment
            │    └─ COMPRS                         compress dead trees
            ├─ EVMON            event monitor variables
            └─ DISPLY           write cycle statistics
                 └─ DBSWRITE    write to SQLite tables
```

---

## Variant Override Points (base → sn)

The Southern (sn) variant overrides or adds these functions:

| Function | Source file | What it does |
|----------|-------------|-------------|
| `BLKDAT` | `sn/blkdat.f` | Species DATA block: names, FIA codes, coefficients for 90 species |
| `DGF` | `sn/dgf.f` | Diameter growth equation (Chapman-Richards for Southern) |
| `DGDRIV` | `sn/dgdriv.f` | Diameter growth driver (calls DGF, applies calibration) |
| `HTGF` | `sn/htgf.f` | Height growth function (sn species-specific) |
| `HTCALC` | `sn/htcalc.f` | Height–DBH relationship |
| `HTDBH` | `sn/htdbh.f` | Height from DBH (interpolation) |
| `MORTS` | `sn/morts.f` | Mortality model (SDI-based for Southern) |
| `CROWN` | `sn/crown.f` | Crown ratio model |
| `CRATET` | `sn/cratet.f` | Regeneration/establishment |
| `CUBRDS` | `sn/cubrds.f` | Cubic volume by product class |
| `GROHED` | `sn/grohed.f` | Growth output header |
| `GRINIT` | `sn/grinit.f` | Growth calibration initialization |
| `SITSET` | `sn/sitset.f` | Site index setting |
| `HABTYP` | `sn/habtyp.f` | Habitat type classification |
| `FORMCL` | `sn/formcl.f` | Form class (**only true override of a base .f file**) |
| `FINDAG` | `sn/findag.f` | Find age of species at site index |
| `FORKOD` | `sn/forkod.f` | Forest type code assignment |
| `DGBND` | `sn/dgbnd.f` | Diameter growth bounds/limits |
| `BRATIO` | `sn/bratio.f` | Bark ratio (DBH outside/inside bark) |
| `VARGET/VARPUT/VARMRT` | `sn/*.f` | Variant get/set/mortality |
| `REGENT` | `sn/regent.f` | Regeneration input |
| `ESSUBH` | `sn/essubh.f` | Establishment subhabitat |
| `NBOLT` | `sn/nbolt.f` | Number of bolts (product class) |
| `DUBSCR` | `sn/dubscr.f` | Species screening |

---

## File I/O Mechanics

### Input

- **`.key` file**: keyword records; columns 1-8 = keyword, 9-72 = values
- **`.tre` file**: one tree record per line
  - Format: `(I4,I4,F9.3,I1,A3,5F7.2,I3,6I3,I3,I3,5I3,F7.1)`
  - Fields: plot, tree, TPA, history, species, DBH, DG, HT, THT, HTG, ICR, damage(6×I3), IMC, KUTKOD, IPVARS(5), ABIRTH

### Output

- Text: `.out`/`.sum`/`.tls` via Fortran IO units
- SQLite: `FVSOut.db` via DBS extension (FVS_TreeList, FVS_Summary2, FVS_Carbon, FVS_FIAVBC_Summary)

### Fortran IO Units → Julia

| Fortran unit | Purpose | Julia mapping |
|---|---|---|
| `JOSTND` (6) | Standard output / stand summary | `io_units[JOSTND]` → stdout |
| `JOLIST` (7) | Keyword listing | file or stdout |
| `JOSUM` (8) | Summary table | file |
| `JOTREE` (9) | Tree list output | file |
| 10 | `.key` keyword file | `open(keyfile, "r")` |
| 0 | stderr | stderr |

---

## Fortran Feature → Julia Translation Table

| Fortran feature | Julia translation |
|---|---|
| `PARAMETER (X=val)` | `const X = val` |
| `REAL X(N)` in COMMON | `const X = zeros(Float32, N)` (module-level) |
| `INTEGER X(N)` in COMMON | `const X = zeros(Int32, N)` |
| `LOGICAL X` in COMMON | `X::Bool = false` (module global) |
| `CHARACTER*n X` | `X::String = ""` or `X = repeat(' ', n)` |
| `GOTO 25` / `25 CONTINUE` | `@goto label_25` / `@label label_25` |
| `ENTRY SUBNAME(args)` | Split into separate `function SUBNAME(args)` |
| `SAVE X` | Promote `X` to module-level global |
| `DATA X / vals /` | Inline array literal or `fill!(X, val)` in `__init__()` |
| `WRITE(unit, fmt) vars` | `@printf(io_units[unit], fmt, vars...)` |
| `OPEN(UNIT=u, FILE=f, ...)` | `io_units[u] = open(f, "r")` etc. |
| `CLOSE(u)` | `close(io_units[u]); delete!(io_units, u)` |
| `READ(u, fmt) vars` | `line = readline(io_units[u])`, then parse |
| `DO 10 I=1,N` / `10 CONTINUE` | `for I in 1:N; ...; end` |
| `IF (X.LT.Y)` | `if X < Y` |
| `X.AND.Y` | `X && Y` |
| `.TRUE.` / `.FALSE.` | `true` / `false` |
| `GO TO (11,12,13) I` | `(()->(@goto label_11), ()->(@goto label_12), ()->(@goto label_13))[I]()` or `if/elseif` |
| `INTEGER*4 X` | `X::Int32` |
| `DOUBLE PRECISION X` | `X::Float64` |
| `REAL X` | `X::Float32` |
| `X**2` | `X^2` |
| `SQRT(X)` | `sqrt(X)` |
| `ABS(X)` | `abs(X)` |
| `MAX(X,Y)` | `max(X,Y)` |
| `MIN(X,Y)` | `min(X,Y)` |
| `MOD(X,Y)` | `X % Y` (for integers) or `mod(X,Y)` |
| `NINT(X)` | `round(Int32, X)` |
| `INT(X)` | `trunc(Int32, X)` |
| `FLOAT(I)` | `Float32(I)` |
| `IFIX(X)` | `Int32(trunc(X))` |
| `EXP(X)` | `exp(X)` |
| `LOG(X)` | `log(X)` |
| `LOG10(X)` | `log10(X)` |
| `ALOG(X)` | `log(X)` (older Fortran alias) |
| `SIN(X)` / `COS(X)` | `sin(X)` / `cos(X)` |
| `ATAN(X)` | `atan(X)` |
| `ATAN2(Y,X)` | `atan(Y, X)` |
| `CHAR(N)` | `Char(N)` |
| `ICHAR(C)` | `Int32(C)` |
| `LEN(str)` | `length(str)` |
| `INDEX(str,sub)` | `findfirst(sub, str)` |
| `ADJUSTL(str)` | `lstrip(str)` |
| `TRIM(str)` | `rstrip(str)` |
| `str//str2` | `str * str2` |
| `EQUIVALENCE(A,B)` | `reinterpret()` or shared backing array |
| `INQUIRE(FILE=f,EXIST=ex)` | `ex = isfile(f)` |
| `BACKSPACE(u)` / `REWIND(u)` | `seek(io_units[u], 0)` |
| `STOP 10` | `exit(10)` |
| `RETURN` | `return` |
| Alternate return `CALL SUB(*10)` | Return an error code Int, branch on it |
| `NAMELIST /name/ vars` | Manual field parsing |

---

## Fortran Implicit Typing

Files without `IMPLICIT NONE` use F77 implicit typing:
- Variables starting with **I, J, K, L, M, N** → `INTEGER` (Int32)
- All other variables → `REAL` (Float32)

When translating a file without `IMPLICIT NONE`, derive types from these rules.

---

## Data Types

| Fortran | Julia |
|---|---|
| `INTEGER` | `Int32` |
| `INTEGER*4` | `Int32` |
| `INTEGER*2` | `Int16` |
| `REAL` | `Float32` |
| `REAL*4` | `Float32` |
| `DOUBLE PRECISION` | `Float64` |
| `REAL*8` | `Float64` |
| `LOGICAL` | `Bool` |
| `CHARACTER*n` | `String` (or `NTuple{n,Char}` if width-matters) |

---

## Array Indexing

Both Fortran and Julia are **1-based**. No index offset changes needed.

Multi-dimensional arrays: both use **column-major** order. A Fortran `A(3,MAXTRE)` maps to
Julia `A = zeros(Float32, 3, MAXTRE)`, and `A(i,j)` → `A[i,j]`. ✓

---

## Key Numerical Algorithms

| Algorithm | Fortran file | Description |
|---|---|---|
| Diameter growth | `sn/dgf.f` | Chapman-Richards equation with site modifier |
| Height growth | `sn/htgf.f` | Sigmoid function of site index, DBH, age |
| Mortality | `sn/morts.f` | Background + SDI density-dependent mortality |
| Crown ratio | `sn/crown.f` | Crown ratio from relative density + species |
| Stand density index | `base/sdicls.f` | Reineke SDI by size class |
| Volume | `base/vols.f` + `vollib09.f` | NVEL volume equations |
| Biomass/Carbon | `base/calcbiomass.f` | Jenkins/CRM equations |
| FIAVBC biomass | `fiavbc/nvbeqdef.f` | FIA-consistent AbvGrdBio |
| Establishment | `sn/cratet.f` | Stochastic seedling/sapling ingrowth |
| Crown width | `base/cwcalc.f` | Species-specific crown width from DBH |
| Site index | `sn/sitset.f` | Site index from site variables |
| Fire behavior | `fire/bia_behres.f` | BEHAVE fire spread/intensity |
| SDI thinning | `base/dense.f` | Max SDI density management |

---

## Extension Architecture

Extensions hook into the base via three mechanisms:

1. **Keyword dispatch**: `KEYINP` dispatches to extension keyword handlers:
   - `EXDBS` → SQLite extension keywords
   - `EXFIRE` → Fire extension keywords
   - `EXMIST` → Mistletoe extension keywords

2. **Cycle hooks** — called from `TREGRO`:
   - Before growth: `MPBOPS`, `DFBSCH`, `TMOPS`
   - During: fire/pest mortality via `MORTS`
   - After: `DBSWRITE` (SQLite), `RDPR`, `BRPR`, `MISPRT`

3. **End-of-run** — `GENPRT` dispatches to all extension output routines.

---

## Species Data (sn variant)

`sn/blkdat.f` defines 90 tree species for the Southern variant:
- `JSP(MAXSP)` — 2-char alpha codes ("LP", "SP", "WO", etc.)
- `FIAJSP(MAXSP)` — FIA SPCD as character strings ("121", "131", etc.)
- `PLNJSP(MAXSP)` — PLANTS codes

FIA SPCDs can be input directly in the `.tre` species field. `intree.f:384-393` matches
against all three tables (JSP, FIAJSP, PLNJSP).

---

## SQLite Output Schema (from DBS extension)

Tables written to `FVSOut.db`:

| Table | Key columns | Notes |
|---|---|---|
| `FVS_TreeList` | StandID, Year, SpeciesFIA, DBH, TPA, Ht, PctCr, TreeAge | Enabled by `TREELIST 0` + `TreeLiDB 2` |
| `FVS_Summary2` | StandID, Year, ... | Summary statistics per cycle |
| `FVS_Carbon` | StandID, Year, Aboveground_Total_Live | Carbon tons/acre |
| `FVS_FIAVBC_Summary` | StandID, Year, AbvGrdBio | FIA-consistent biomass tons/acre |

---

## Gotchas

- **`STOP 10`** is the normal FVS end code → Julia `exit(10)`
- **Fortran unit 6** = stdout; unit 0 = stderr
- **`sn/PRGPRM.F77`** has `MAXSP=43` (not base's 23)
- **COMMON block order**: `prgprm.jl` must be included first (other files use MAXTRE, MAXSP)
- **`ENTRY` statements**: split each `ENTRY` into a separate Julia function; shared state
  between the main subroutine and ENTRY points must become module globals or be passed as args
- **`EQUIVALENCE`**: some files use this to alias array sections; translate with `reinterpret`
  or by using the same array variable
- **`CHARACTER*8 NAMGRP(30)`**: a fixed-length character array → `Vector{String}` in Julia,
  padding/trimming as needed to maintain compatibility with formatted I/O
- **`DSNOUT` can't be set per-stand** in multi-stand run (FVS16 error) → don't emit DSNOUT;
  FVS writes to `FVSOut.db` by default
- **`FVS_Summary2`** (not FVS_Summary) is the correct table name for summary data
- **`TreeAge` column in FVS_TreeList is always 0** in FVS — FVS doesn't track per-tree age
