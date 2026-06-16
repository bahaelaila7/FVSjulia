# FVSjulia Migration Notes
# Fortran 77 → Julia 1.x: FVSsn (Forest Vegetation Simulator, Southern Variant)
# Written: 2026-06-16

288 Julia source files, ~57 000 lines translated from 512 Fortran `.f` files + ~50 `.F77` COMMON block
includes. This document captures every language-specific and structure-specific issue encountered during
the migration, plus a reference-level breakdown of the codebase and its internal workflows.

---

## 1. Codebase Breakdown

### 1.1 Source tree

```
FVSjulia/
├── src/
│   ├── FVSjulia.jl          # module root; 220 include() calls in strict dependency order
│   ├── common/              # 52 files — global state (translated from .F77 COMMON blocks)
│   ├── base/                # 145 files — core simulation engine
│   ├── sn/                  # 22 files — Southern variant overrides and additions
│   └── extensions/
│       ├── dbs/             # SQLite output (DBS keyword extension)
│       ├── fiavbc/          # FIA volume/biomass consistency
│       ├── fire/            # Fire & Fuels Extension (~63 files)
│       └── pests/           # Pest/disease stubs (dwarf mistletoe, MPB, DFB, WSBWE, etc.)
```

### 1.2 Simulation flow

```
main()                          # base/main.jl — parse CLI, loop until rtnCode ≠ 0
  └─ FVS!(rtnCode)              # base/fvs.jl — one stand per call
       ├─ INITRE()              # base/initre.jl — 147-option keyword + tree-record reader
       │    ├─ KEYOPN/KEYRDR   # open .key file, dispatch keywords by table lookup
       │    ├─ INTREE           # read .tre tree records (fixed-format 80-char lines)
       │    └─ per-keyword handlers (SITSET, GRINIT, DBSINIT, FMINIT, …)
       ├─ OPEXPN/OPCYCL         # expand and schedule per-cycle activities
       ├─ SETUP                 # sort/index tree list by species
       ├─ NOTRE                 # compute trees/acre from PROB expansion factors
       ├─ CRATET                # initial tree establishment
       ├─ VOLS                  # compute volumes (NATCRS→JENKINS for biomass)
       ├─ DISPLY                # initial stand table output
       └─ cycle loop (ICYC = 1..NCYC):
            └─ TREGRO           # main growth driver per cycle
                 ├─ GRINCR      # diameter + height growth (DGF, HTGF, HTCALC)
                 ├─ MORTS       # mortality (background + density-dependent SDI)
                 ├─ CRATET      # regeneration / seedling ingrowth
                 ├─ COMPRS      # compress dead/tripled trees
                 ├─ EVTSTV      # event monitor variable computation
                 ├─ FMMAIN      # fire extension: snags, CWD, fire behavior
                 └─ DISPLY/DBSWRITE — output text + SQLite
```

### 1.3 COMMON block → global variable mapping

Each Fortran `.F77` COMMON block file becomes a Julia file in `src/common/` that declares
module-level globals. Every subroutine that INCLUDEs a `.F77` in Fortran simply accesses the
same module-scope globals in Julia — no arguments needed.

| F77 file | Julia file | Key variables |
|----------|-----------|---------------|
| PRGPRM | prgprm.jl | MAXTRE=3000, MAXSP=43, MAXCYC=40 |
| ARRAYS | arrays.jl | DBH[], HT[], ISP[], PROB[], DG[], HTG[], ICR[] |
| CONTRL | contrl.jl | ICYC, NCYC, ITRN, JOSTND, JOLIST, TRM, LMORT |
| PLOT | plot.jl | BA, TPROB, RMSQD, AVH, IAGE, SLOPE, MGMID, NPLT |
| OUTCOM | outcom.jl | ITABLE[], INS[], DBHIO[], PRBIO[], IY[] |
| FMCOM | fmcom.jl | NSNAG, DENIS[], DENIH[], TCWD[], CWD2B[], CWDCUT |
| FMFCOM | fmfcom.jl | FIRTYPE, FLMHT, MOISTURE, FWIND, CRBURN |
| FMSVCM | fmsvcm.jl | IFMTYP, FLAMEHT, FMY1[], FMY2[], OFFSET[], CATCHUP[] |
| SVDATA | svdata.jl | NSVOBJ, XSLOC[], YSLOC[], IOBJTP[], CRNRTO[], OLEN[] |
| SVDEAD | svdead.jl | FALLDIR[], ISTATUS[], IS2F[] |
| DBSCOM | dbscom.jl | db (SQLite.DB handle), DBSFILE, LDBSOPEN |

### 1.4 Extension hook points

Extensions attach at exactly four hook points. None require modifying base files:

| Hook | Where called | What fires |
|------|-------------|-----------|
| Keyword read | INITRE option dispatch | `DBSIN`, `FMIN`, `RDIN`, `MISIN`, … |
| Before-growth | TREGRO top | `TMOPS` (tussock moth), `DFBSCH` (DFB), `MPBOPS` (MPB) |
| After-growth | TREGRO bottom | `FMMAIN` (fire), `RDPR` (root disease), `BRPR` (blister rust) |
| End-of-run | GENPRT | `FMSSUM`, `DBSWRITE` final flush, `MISPRT`, `BRPR` |

---

## 2. Language-Specific Translation Issues

### 2.1 ENTRY statements → separate top-level functions

Fortran allows multiple named entry points inside one subroutine, all sharing the subroutine's
local variables as persistent (SAVE) state between calls:

```fortran
SUBROUTINE EXMPB
  INTEGER NKILLS
  SAVE NKILLS
  DATA NKILLS /0/

  ENTRY MPBINT
    NKILLS = 0
  RETURN

  ENTRY MPBGO(L)
    L = (NKILLS > 0)
  RETURN
END
```

In Julia, each ENTRY becomes a separate top-level function. Any local state shared between
entry points becomes a module-level `Ref` or `const`:

```julia
const _MPBKILLS = Ref(Int32(0))

function MPBINT(); _MPBKILLS[] = Int32(0); return nothing; end
function MPBGO(l::Ref{Bool}); l[] = (_MPBKILLS[] > 0); return nothing; end
```

This pattern appears in ~40 files. The hardest cases are `cutstk.f` (CUTSTK/CLSSTK/AUTSTK),
`fmevmon.f` (15 FMEV* entries), and `extstubs.jl` where 100+ no-op entries live.

### 2.2 Fortran by-reference semantics for output arguments

Fortran passes all arguments by reference. Julia passes by value (scalars) or by reference
(arrays, mutable structs). Output scalar arguments require explicit `Ref{T}`:

```fortran
SUBROUTINE SDITMP(SDI, LOPEN)
  REAL SDI
  LOGICAL LOPEN
  SDI = BA / (AVH / 10.0)
  LOPEN = .TRUE.
```

```julia
function SDITMP(sdi_ref::Ref{Float32}, lopen_ref::Ref{Bool})
    sdi_ref[] = BA / (AVH / 10.0f0)
    lopen_ref[] = true
end
```

Call sites correspondingly use `Ref`:
```julia
sdi_r = Ref(0.0f0); lopen_r = Ref(false)
SDITMP(sdi_r, lopen_r)
sdi = sdi_r[]
```

Fortran arrays are passed by reference naturally — Julia `AbstractVector` covers this.
The `args...` variadic form was used for pest no-op stubs to avoid specifying signatures
for functions never reached in practice.

### 2.3 GOTO → @goto / @label

Fortran GOTO is pervasive in FVS. INITRE alone (6 476 lines) has 147 numbered CONTINUE
labels used as GOTO targets. Julia's `@goto`/`@label` macros provide a direct translation:

```fortran
IF (ITRN .LE. 0) GOTO 25
  ...
25 CONTINUE
```

```julia
if ITRN <= 0; @goto label_25; end
...
@label label_25
```

**Constraint**: `@goto` cannot jump forward past a new variable binding. This forced several
cases to be restructured as `while true; break; end` loops or early-exit function wrappers
when the original GOTO crossed a `let` or local variable declaration boundary.

**Computed GOTO** (`GO TO (11,12,13) I`) was translated as:
```julia
if     i == 1; @goto label_11
elseif i == 2; @goto label_12
elseif i == 3; @goto label_13
end
```

### 2.4 IMPLICIT typing

Fortran IMPLICIT NONE is present in modern FVS files but absent in older ones. Without it,
variables starting with I-N are `INTEGER`, all others are `REAL`. Some files (notably in
`fire/` and `base/`) mix implicit-typed temporaries with explicitly declared variables.
Every implicit variable had to be manually typed during translation.

Key pitfall: `INTEGER` → `Int32` (not Julia's default `Int64`). Using the wrong integer
width causes silent narrowing in array indices and bitmask operations.

### 2.5 FORMAT / WRITE → Printf

Fortran FORMAT strings are a mini-language. Common translations:

| Fortran | Julia Printf |
|---------|-------------|
| `I4` | `%4d` |
| `F10.2` | `%10.2f` |
| `E12.4` | `%12.4e` |
| `A8` | `%-8s` (left-padded) or `%8s` |
| `1X` | ` ` (literal space) |
| `T40` | pad with spaces to column 40 |
| `'text'` | literal in format string |
| `/` | `\n` |
| `(5F8.2)` | five `%8.2f` |

The T (tab) edit descriptor required computing the current column position to emit the right
number of spaces — no direct Printf equivalent. Most cases were handled by counting characters
in surrounding format items.

Hollerith (`1H `, `5HHELLO`) appears in a few legacy routines; these were replaced with the
equivalent string literals.

### 2.6 COMMON block deduplication

The same variable is often declared in multiple `.F77` INCLUDE files. For example, `JOSTND`
appears in both `CONTRL.F77` and `PLOT.F77`. The Fortran linker merges them because they
share the same COMMON block name. Julia has no such mechanism — duplicate declarations
would create two separate globals with the same name (a compile error in a module).

Solution: carefully audit every variable in every `.F77` file, track which COMMON block owns
it, and declare it exactly once. When two `.F77` files both claim the same variable in
different COMMON blocks, the build directory's resolved source (which collapses includes) was
used as ground truth.

### 2.7 CHARACTER arrays and string semantics

Fortran `CHARACTER*8 KEYWRD` is a fixed-width, space-padded string. Julia `String` is
variable-length UTF-8. The mismatch creates several issues:

- **Comparison**: Fortran `KEYWRD .EQ. 'SIMFIRE'` compares all 8 characters including trailing
  spaces. Julia comparisons must use `rstrip(keywrd) == "SIMFIRE"` or pad explicitly.
- **Assignment**: `KEYWRD = 'SIMFIRE '` (note trailing space). Julia needs explicit padding:
  `keywrd = "SIMFIRE "` (8 chars).
- **Substring**: `KEYWRD(1:4)` → `keywrd[1:4]`. Julia string indexing is byte-based (safe
  here since all FVS strings are ASCII).
- **CHARACTER*8 arrays**: `CHARACTER*8 NSP(MAXSP,10)` → `const NSP = fill("        ", MAXSP, 10)`.

The keyword comparison tables in `KEYCOM.F77` (128 eight-character keyword names) required
consistent trailing-space padding to match INITRE's lookup.

### 2.8 BLOCK DATA → module-level initialization

Fortran BLOCK DATA subroutines initialize COMMON block variables with DATA statements. In
Julia these become module-level constant arrays with inline literal initialization:

```fortran
BLOCK DATA FMCBLK
  COMMON /FMPROP/ BIOGRP(90)
  DATA BIOGRP / 1,2,1,1,... /
END
```

```julia
# fmcblk.jl
const BIOGRP = Int32[1,2,1,1,...]
```

The largest BLOCK DATA is `sn/blkdat.f`: 90 species × 12 coefficient arrays, ~1 800 DATA
values. Each array was transcribed verbatim from the Fortran source.

### 2.9 SAVE variables → module-level Refs

Fortran SAVE preserves local variable state between calls. SAVE is the default for
variables initialized with DATA statements. In Julia, subroutine-local state must be promoted
to module scope as `Ref` or `const`:

```fortran
SUBROUTINE RFMRUN
  INTEGER IRUN
  DATA IRUN / 0 /
  SAVE IRUN
  IRUN = IRUN + 1
```

```julia
const _RFMRUN_IRUN = Ref(Int32(0))
function RFMRUN()
    _RFMRUN_IRUN[] += Int32(1)
end
```

The underscore + subroutine-name prefix convention was used to avoid name collisions.

### 2.10 Fortran DO loops

Fortran DO loops are inclusive on both bounds and have an optional step:
```fortran
DO 100 I = 1, MAXTRE
DO 200 I = 1, N, -1
```

Julia equivalents:
```julia
for i in 1:MAXTRE
for i in N:-1:1
```

The DO-WHILE pattern (`DO WHILE (condition)`) translates to `while condition`.

Loop labels (shared by multiple loops) required careful tracking — Fortran allows CONTINUE at
the same label to serve as the end of multiple nested loops:
```fortran
DO 100 I = 1, N
  DO 100 J = 1, M
    A(I,J) = 0
100 CONTINUE
```

Translated as two separate `for` loops, each ending naturally.

### 2.11 Fortran array storage order

Fortran arrays are column-major (first index varies fastest). Julia is also column-major.
Array indexing required no changes — `A(I,J)` in Fortran maps directly to `A[i,j]` in Julia.

Multi-dimensional arrays declared as `REAL A(MAXSP, MAXTRE)` were translated as
`const A = zeros(Float32, MAXSP, MAXTRE)`.

### 2.12 EQUIVALENCE → shared backing array

Some FVS files use EQUIVALENCE to alias two arrays onto the same memory:
```fortran
REAL WK1(MAXTRE), WK3(MAXTRE)
EQUIVALENCE (WK1, WK3)
```

In Julia: since module-level arrays are separate objects, equivalenced arrays were handled
case-by-case — either sharing a single array with two names, or using `reinterpret()` when
the types differ.

### 2.13 Alternate returns

Fortran allows subroutines to return to a caller-specified label:
```fortran
CALL KEYRDR(KEY, *10, *20)
...
10 CONTINUE  ! returned here on error
20 CONTINUE  ! returned here on EOF
```

Translated using return codes:
```julia
rc = KEYRDR(key)
if rc == 10; @goto label_10
elseif rc == 20; @goto label_20
end
```

Appears in keyword readers and file I/O routines.

### 2.14 NAMELIST I/O

A few routines use Fortran NAMELIST for structured keyword reading. These were translated
as manual field parsers since Julia has no NAMELIST equivalent.

---

## 3. Structure-Specific Intricacies

### 3.1 The variant override pattern

FVSsn consists of:
- `base/` — core engine shared by all FVS variants
- `sn/` — Southern variant additions (25 files) + one true override (`formcl.f`)

Only `formcl.f` replaces a base function. All other `sn/` files are additions. Julia doesn't
have a namespace-override mechanism, so the include order in `FVSjulia.jl` governs which
definition "wins": sn files are included after base files, and since they define identically
named functions, Julia emits a method-overwrite warning for `FORMCL`.

All other base↔sn conflicts (e.g., MORTS, DGDRIV, HTGF) are additive — the sn versions
are different functions not replacing base ones (the base versions simply aren't included for
`FVSsn`).

### 3.2 Method-overwrite conflicts

Julia warns (but does not error) when a method is defined twice with the same signature.
During migration, 10+ such conflicts arose from stubs that were later replaced by real
implementations. Strategy:

- **Stubs in `extstubs.jl`** were removed as each real file was added.
- **Stubs inline in a caller file** (e.g., `TMBMAS` inline in `tregro.jl`) had to be removed
  before the real implementation file was included.
- **Comment pointers** were added in `extstubs.jl` pointing to the implementing file.

Conflicts that were actually caught and fixed:
- `EVUST4`/`EVSET4` — duplicated between `sstage.jl` and an early stub
- `GETID`/`GETLUN` — duplicated in `sstage.jl` vs `filopn.jl`
- `TMBMAS` — inline stub in `grincr.jl` vs real in `extstubs.jl`
- `FMSNAG` — inline stub vs later real implementation
- `AUTCOR`/`MULTS`/`DGF`/`REVISE`/`GRDTIM` — inline in `dgdriv.jl` vs own files
- `fvsGetRtnCode`/`fvsSetRtnCode` — in both `filopn.jl` and an early stub
- `FMTRIP` — in both `triple.jl` and `fmsalv.jl`

### 3.3 The INITRE 147-option keyword dispatcher

`initre.f` (6 476 lines) is a single subroutine with 147 GOTO-targeted CONTINUE labels, each
handling one FVS keyword. The structure is a chain of:

```fortran
IF (ICODE .EQ. 101) GOTO 9100
IF (ICODE .EQ. 102) GOTO 9200
...
9100 CONTINUE
  ! handle keyword 101
  GOTO 9999   ! fall through to next keyword read
9200 CONTINUE
  ! handle keyword 102
  ...
9999 CONTINUE
```

Translated as one giant `if/elseif` block with `@goto`/`@label` for intra-option jumps.
The Julia `@goto` constraint (no jumping past variable bindings) required wrapping several
option bodies in inner functions when they bound new local variables after a GOTO target.

`ICODE` values are assigned by the keyword table in `KEYCOM.F77` — 128 entries, each
8 characters with trailing spaces. Getting these exactly right was critical; a single
off-by-one in the table caused silent wrong-option dispatch.

### 3.4 IO unit system

Fortran uses integer unit numbers for all file I/O. Julia maps these to a `Dict{Int32, IO}`:

```julia
const io_units = Dict{Int32, IO}()
```

Standard mappings:
- `JOSTND` (default 6) → `stdout` (always open)
- `JOLIST` (7) → listing file or `stdout`
- `JOSUM` (8) → summary file
- Unit 0 → `stderr`
- Units 10+ → opened on demand by `FILOPN`, closed by `FILCLS`

`FILOPN`/`FILCLS` handle the `open`/`close` lifecycle. The `get(io_units, unit, stdout)`
pattern provides a safe fallback for any unit that wasn't explicitly opened.

### 3.5 The WK3 stop/restart buffer

FVS supports stopping mid-simulation and restarting from a serialized snapshot. The
stop/restart mechanism uses `WK3` — a large `Float32` work array treated as a flat binary
buffer. Each extension serializes its state into WK3 at a specific offset:

- `FMPPPUT` writes the fire model's 86 integers + 15 booleans + 56 floats + CWD/snag arrays.
- `FMPPGET` reads exactly the same layout.

In Julia, the `WK3` array is module-global (`src/common/workcm.jl`). Extension PPPUT/PPGET
functions write/read scalar values at consecutive `ipnt` positions:

```julia
function _wk3put(wk3, ipnt_ref, v::Float32)
    ipnt_ref[] += Int32(1)
    wk3[ipnt_ref[]] = v
end
```

Boolean values are stored as `Float32(1.0)` (true) or `Float32(0.0)` (false). Integer values
are stored as `reinterpret(Float32, value)` in the Fortran — in Julia we store as
`Float32(intval)` since all stored integers fit in Float32's mantissa (values < 2^24).

### 3.6 The fire extension SVS output pattern

All five fire SVS functions (`FMSVOUT`, `FMSVFL`, `FMSVTREE`, `FMSVSYNC`, `FMSVTOBJ`)
early-return when `JSVOUT == 0` (SVS disabled, which is the normal case for FIA/Pan runs):

```julia
(JSVOUT == Int32(0) || NFMSVPX == Int32(0)) && return
```

When SVS is enabled, they write `@flame.eob` records to the SVS file unit — a custom binary-ish
format with fixed-width columns. The fire line is stored in `FMY2[]` — a per-segment Y-position
array with `NFLPTS` entries. `FMSVOUT` drives `NFMSVPX` animation frames, advancing the fire
line each frame using `BACHLO` (normal-deviate via SVRANN) for random offsets.

### 3.7 Pest extensions: the "not linked" stub pattern

Every FVS pest model (MPB, DFB, DFTM, mistletoe, root disease, blister rust, BM, WSBWE,
climate, cover, ORGANON) ships with a corresponding `ex*.f` stub file. These stubs ARE the
implementations when the pest model isn't compiled in — they're not placeholders added during
the Julia migration.

The critical behavior: every `*IN` entry point (the keyword reader, called when INITRE
encounters a pest keyword in the .key file) calls `ERRGRO(.TRUE., 11)`:

```fortran
ENTRY MPBIN(KEYWRD, ARRAY, LNOTBK, LKECHO)
  CALL ERRGRO(.TRUE., 11)
  IF(.TRUE.) RETURN
```

Error code 11 means "keyword recognized but extension not linked." Without this call, pest
keywords in the `.key` file would be silently ignored instead of raising an error.

Every `*KEY` entry point returns a `"*NO XXX"` string that appears in the keyword listing
output (`OPLIST`). The exact 8-character strings from each Fortran DATA statement:
- `DFBKEY` → `"*NO DFB "`, `MPKEY` → `"*NO MPB "`, `TMKEY` → `"*NO DFTM"`
- `BWEKEY` → `"*NO WSBE"`, `BRKEY` → `"*NO BRUS"`, `MISKEY` → `"*NO MIST"`
- `CLKEY` → `"*NO CLIM"`, `CVKEY` → `"*NO COVR"`, `RDKEY` → `"*NO RROT"`
- `BMKEY` → `"**NO BM "` (note double asterisk, from `exbm.f`)

The WSBWE (budworm+bark beetle) is the exception: `BWEIN` does NOT call `ERRGRO`. Its
Fortran stub uses `IF(.TRUE.)RETURN` to suppress unused-variable warnings without any error.

### 3.8 MISDGF / MISHGF: inline stubs in caller

The mistletoe DGF/HGF modifiers (`MISDGF(itree, ispc)` and `MISHGF(itree, ispc)`) return
`1.0` when the mistletoe model isn't linked. Rather than being in `extstubs.jl`, they were
stubbed inline in the calling files:

```julia
# In dgdriv.jl — immediately after the real DGDRIV function:
MISDGF(i, ispc) = Float32(1.0)
```

This avoids a separate file for two one-line functions.

### 3.9 The CLMAXDEN dual-residency problem

`CLMAXDEN(SDIDEF, XMAX)` modifies the maximum stand density (`XMAX`) based on climate.
It appears in both:
- `exclim.f` — as a no-op ENTRY that returns XMAX unchanged
- `volstubs.jl` — as a stub with the proper return value

Because `sdical.jl` calls `CLMAXDEN` and uses its return value (`xmax = CLMAXDEN(...)`),
the stub in `volstubs.jl` was made to return `xmax` unchanged:

```julia
function CLMAXDEN(sdidef::AbstractVector{Float32}, xmax::Float32)::Float32
    return xmax
end
```

This is the Julia way to express "leave xmax unchanged" without the by-reference semantics
that the Fortran stub relies on.

### 3.10 RDATV: subtle behavior difference

`RDATV(L, LTEE)` in `exrd.f` sets `L=.FALSE.` and `LTEE=.FALSE.`. The stub in `extstubs.jl`
initially had `return nothing` (leaving the Refs unchanged). This was a correctness bug:
callers in `initre.jl`, `intree.jl`, and `putstd.jl` check these flags to determine whether
the root disease model is active. If the Refs happened to hold `true` before the call, root
disease processing would be incorrectly enabled.

Fixed to use a proper typed signature:
```julia
function RDATV(lgo::Ref{Bool}, ltee::Ref{Bool})
    lgo[] = false; ltee[] = false; return nothing
end
```

### 3.11 BLKDAT species table: 83 vs 90 entries

`sn/blkdat.f` declares `PLNJSP(MAXSP)` (PLANTS codes) with `MAXSP=90` entries. One
transcription error had only 83 entries in the Julia `PLNJSP` array. The mismatch caused
a bounds error at runtime (Julia arrays are bounds-checked by default). Fixed by counting
the Fortran DATA values and filling the array to exactly 90.

### 3.12 Project.toml DBInterface compat version

`DBInterface.jl` must be listed as a compat dependency in `Project.toml` with version `"2"`
(not `"1"`) to match the SQLite.jl that FVSjulia uses. Including it as a stdlib entry (which
it isn't) caused `Pkg.instantiate` to fail. The standard library entries (Dates, Printf, etc.)
must not appear in `[compat]` — only registered packages go there.

### 3.13 prevYearMortality = 0 (LANDIS interface)

When FVSjulia is called from Pan's LANDIS integration, the fire mortality interface sets
`CurrentYearMortality` but never `prevYearMortality`. The Biomass Succession model computes
AGB from `prevYearMortality`; if non-zero, this inflates the mortality signal and caused a
~20% AGB overshoot in Pan's output. The fix: always keep `prevYearMortality = 0` in the
integration bridge. This is NOT a general FVS behavior — it is specific to the Pan/LANDIS
coupling.

### 3.14 NATCRS → JENKINS biomass path

FVSsn's volume library (`vollib09.f`) is a Windows DLL wrapper for the external NVEL library
— a Fortran DLL not available in the Julia environment. For Pan's use case (biomass, not
merchantable volume), the relevant path is:

```
VOLS() → NATCRS() → JENKINS() → biomas[1..15]
```

`JENKINS()` (in `calcbiomass.jl`) performs a binary search on the 2 677-species `WDBKWT`
lookup table (`wdbkwt_data.jl`) to compute all eight Jenkins biomass components by FIA
species code. `NATCRS()` calls `JENKINS()` and fills the `biomas[]` array from which
`ABVGRD_BIO` is derived. The NVEL stubs (`VOLLIB09`, `VOLLIBCS`, `VOLLIBFIA`) all return
nothing — they are never reached on the biomass path.

### 3.15 FMIN keyword table: 54 entries vs sparse indices

The fire extension keyword processor (`fmin.f`) uses action codes in the range 2501–2553 to
index into FVS's keyword dispatch table. The 54 keywords do not have contiguous indices.
The Julia translation stores the keyword name table as a `const` array indexed 1..54 (not by
action code) and maps action codes to names via a separate lookup. The `_FMIN_TABLE` array
holds exactly the 54 keyword names in the order they appear in the Fortran DATA statement.

### 3.16 FMPHOTOCODE / FMPHOTOVAL: 32 photo-series references

The fire photo-series lookup (`fmphotocode.f`, `fmphotoval.f`) stores fuel-load tables for 32
distinct photo-series references. Each reference has variable-length tables (11×N for live
fuel, 9×N for standing dead). The Julia translation stores each as a matrix literal in the
`REF1`..`REF32` constants and dispatches by integer photo-code. The most complex reference
(`REF28`) has 11×40 entries — 440 Float32 literals transcribed from Fortran DATA statements.

### 3.17 FMCFMD fuel model selector: 89-model scheme

The SN fire extension uses a 14-class primary fuel model scheme mapped to Scott-Burgan
89-model codes. `FMCFMD()` selects from 14 fire behavior fuel models (1–14) and
`FMCFMD2()` implements departure-index-based dynamic selection across all 89 models.
`FMCFMD3()` builds a custom model from stand-measured loads when `IFLOGIC=2`. The
interaction between these three selectors required careful tracking of `IFLOGIC`, `NFMOD`,
and `FMOD[]` state across cycles.

### 3.18 const vs mutable at module scope

Julia's `const` at module scope prevents rebinding the name but does NOT prevent mutating
the value (for arrays or `Ref`s). All COMMON block arrays are declared `const` (the array
object itself won't be replaced) while their elements are freely mutated. Scalar globals that
need reassignment use `Ref`:

```julia
const ICYC = Ref(Int32(0))   # mutable integer via Ref
const DBH = zeros(Float32, MAXTRE)   # mutable array, const binding
```

Early in the migration, plain `let` bindings were tried for scalars — these don't update
across function calls. Switching to `Ref` everywhere for scalars that are written solved this.

### 3.19 global keyword requirement

Julia requires an explicit `global` declaration when assigning to a module-level variable
from inside a function:

```julia
function FMSVOUT(...)
    global IFMTYP = Int32(iftyp)   # required; IFMTYP is module-level
    global FLAMEHT = Float32(flmhtin)
```

This was missed on first pass in several fire SVS functions and caught at precompile time
(Julia's "cannot assign to variable X from a different scope" error).

For `Ref`-based scalars the `global` is not needed since mutation (indexing with `[]`) doesn't
rebind the name:
```julia
ICYC[] += 1   # no global keyword needed
```

### 3.20 Printf formatting: `@sprintf` vs `@printf`

`@printf(io, fmt, args...)` writes directly to an IO handle — used for all FVS text output.
`@sprintf(fmt, args...)` returns a String — used only where a formatted string is needed as
a value (e.g., SVS frame titles, DBSFILE path construction).

Julia's `@printf` does not support `%*d` (width from argument) — Fortran's `nX` format with
a variable count had to be computed manually using `" "^n`.

Fortran's `BN` (blank = null) vs `BZ` (blank = zero) numeric edit descriptors affect how
blank fields are read. FVS uses `BN` by default in its keyword reader. The Julia `FMKEYRDR`
translates this by treating blank subfields as zero during PARMS-mode parsing.

---

## 4. Recurring Patterns and Conventions

### 4.1 Convention: all module globals

All FVS state is in module-level globals (mirroring Fortran COMMON blocks). Functions have
no instance state. This makes the simulation inherently single-threaded for a single stand,
but multiple stands could in principle be run in separate Julia processes.

### 4.2 Convention: Ref{T} for scalar out-params

Any scalar that a function writes back to the caller uses `Ref{T}`. The caller allocates the
Ref, passes it, and reads the result:
```julia
n_ref = Ref(Int32(0))
NOTRE(n_ref)
n = n_ref[]
```

### 4.3 Convention: AbstractVector for array out-params

Array arguments that are modified in-place use `AbstractVector{T}` (or `AbstractMatrix`).
Julia passes arrays by reference so the caller sees the modifications.

### 4.4 Convention: io_units[JOSTND] pattern

All text output goes through `io_units[JOSTND]` (or `io_units[JOLIST]`, etc.). A helper at
call sites:
```julia
io = get(io_units, Int32(JOSTND), stdout)
@printf(io, "...")
```

### 4.5 Convention: Int32 for FVS integers

All FVS integers are `Int32`. Julia's default `Int` is `Int64` on 64-bit systems. Using the
wrong type causes:
- Type promotion to `Int64` in arithmetic (usually harmless)
- Mismatch in array index types when passed to Fortran-originated functions that expect `Int32`
- Silent truncation when storing back into `Int32` arrays

The convention is to cast all integer literals that interact with FVS arrays to `Int32(x)`.

### 4.6 Convention: Float32 for FVS reals

Fortran `REAL` = 32-bit. Julia's default `Float64` would lose correspondence with Fortran.
All coefficients, tree attributes, and computed values use `Float32`. The `f0` suffix is
used throughout:
```julia
x = 2.0f0 * DBH[i] + 1.5f0
```

---

## 5. Files That Needed Special Attention

| File | Issue |
|------|-------|
| `initre.jl` | 6 476 lines, 147 @goto labels, chunked into 6 translation passes |
| `blkdat.jl` | 90-species coefficient tables, PLNJSP count mismatch (83→90) |
| `fmphotoval.jl` | 32 photo-series DATA tables, ~3 000 literal values |
| `fmin.jl` | 54-keyword WHILE loop, PARMS-mode keyword reader |
| `fmppput.jl`/`fmppget.jl` | WK3 serialization: exact field order, bool-as-float |
| `fmcfmd2.jl` | Three-way fuel model selector with complex IFLOGIC dispatch |
| `extstubs.jl` | 700+ lines of stubs, careful removal as real files added |
| `comprs.jl` | MEANSD: Fortran pass-by-ref for scalar MEAN/SD outputs needed Ref{} |
| `dgdriv.jl` | Duplicate stubs removed: AUTCOR/MULTS/DGF/REVISE/GRDTIM |
| `triple.jl` | FMTRIP stub removed after fmsalv.jl added real implementation |
| `evtstv.jl` | GETORGV: must return 0.0 — not just return nothing |
| `volstubs.jl` | CLMAXDEN: must return xmax (not void) — callers use return value |
