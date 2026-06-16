# Remaining FVSjulia Translation Work
# Updated: 2026-06-16
# Tracks fire SVS, volume library, and pest extension chunks

## STATUS LEGEND
- TODO: not started
- WIP: in progress (current session)
- DONE: complete

---

## FIRE SVS (1028 lines total — one chunk)

### Chunk FIRE-SVS — DONE (2026-06-16)
Files written in fire/:
- fmsvtobj.jl: FMSVTOBJ — fire SVS tree object positioning
- fmsvsync.jl: FMSVSYNC — fire SVS synchronization
- fmsvtree.jl: FMSVTREE — fire SVS per-tree crown flame objects
- fmsvfl.jl: FMSVFL + FMGETFL — fire SVS ground fire line + flame objects
- fmsvout.jl: FMSVOUT — fire SVS animation output driver (NFMSVPX frames)

All five files added to fire.jl include list.
Stubs removed from extstubs.jl (FMSVTOBJ/FMSVOUT/FMSVSYNC/FMSVFL/FMSVTREE).

Key pattern: all bail early if JSVOUT==0 (SVS disabled). Functions write @flame.eob
records to SVS file unit. FMSVOUT uses BACHLO()/SVRANN for progressive fire line.

---

## VOLUME LIBRARY (stubs sufficient — no translation needed)

### Chunk VOL-V1/V2/V3 — DONE (2026-06-16, analysis)
Key finding: vollib09.f is a Windows DLL wrapper for external NVEL library (not present).
vollibcs.f and vollibfia.f dispatch to JENKINS()/NATCRS() which ARE implemented.
For Pan's biomass use case: NATCRS→JENKINS path is fully functional.
Volume equation stubs in extstubs.jl/volstubs.jl are correct and sufficient.

No new files needed.

---

## PEST EXTENSIONS (ex*.f files are themselves stubs)

### Chunk PEST-P1/P2/P3 — DONE (2026-06-16)
Key finding: all ex*.f files ARE the FVS "not linked" stub implementations that
ship when pest models aren't compiled in. The Julia extstubs.jl already covered
all entry points. Fixes applied:

**extstubs.jl fixes (added ERRGRO(true,11) to "IN" functions):**
- BMIN  (westwide bark beetle — exbm.f, was labeled "blister rust init")
- BRIN  (blister rust — exbrus.f)
- CLIN  (climate — exclim.f)
- CVIN  (cover model — excov.f)
- DFBIN (Douglas-fir beetle — exdfb.f)
- DFTMIN (DFTM tussock moth — exdftm.f)
- MISIN (dwarf mistletoe — exmist.f)
- MPBIN (mountain pine beetle — exmpb.f)
- RDIN  (root disease — exrd.f)

**extstubs.jl fix (RDATV behavior):**
- RDATV now properly sets both lgo[]=false; ltee[]=false (matching exrd.f L=.FALSE.)

**oplist.jl fixes (KEY functions now return correct "*NO XXX" strings):**
- TMKEY → "*NO DFTM"  (exdftm.f NODFTM)
- MPKEY → "*NO MPB "  (exmpb.f NOMPB)
- CLKEY → "*NO CLIM"  (exclim.f NOCLIM)
- BRKEY → "*NO BRUS"  (exbrus.f NOBR)
- MISKEY → "*NO MIST" (exmist.f NOMIS)
- DFBKEY → "*NO DFB " (exdfb.f NODFB)
- BMKEY → "**NO BM "  (exbm.f NOBM)
- RDKEY → "*NO RROT"  (exrd.f NORR)

No new extpests_p1/p2/p3.jl files needed — extstubs.jl already had all ENTRY points.

---

## PROGRESS LOG

| Date | Chunk | Status |
|------|-------|--------|
| 2026-06-16 | Fire SVS (fmsvtobj/sync/tree/fl/out) | DONE |
| 2026-06-16 | Vol V1/V2/V3 (NVEL stubs sufficient) | DONE |
| 2026-06-16 | Pest P1/P2/P3 (extstubs.jl + oplist.jl fixes) | DONE |
