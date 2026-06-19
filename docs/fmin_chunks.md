# fmin.jl Migration Plan

Source: `/workspace/ForestVegetationSimulator/bin/FVSsn_buildDir/fmin.f` (2732 lines)
Target: `/workspace/FVSjulia/src/extensions/fire/fmin.jl`

## Overview

FMIN: fire extension keyword processor (KWCNT=54 keywords).
Also contains: FMKEY entry, FMKEYDMP, FMKEYRDR subroutines.

## Keyword table (54 entries, in order)
1=SALVSP, 2=END, 3=SVIMAGES, 4=BURNREPT, 5=MOISTURE,
6=SIMFIRE, 7=FLAMEADJ, 8=POTFIRE, 9=SNAGFALL, 10=SNAGBRK,
11=SNAGDCAY, 12=SNAGOUT, 13=SNAGCLAS, 14=LANDOUT, 15=FUELOUT,
16=FUELDCAY, 17=DUFFPROD, 18=MOREOUT, 19=FUELPOOL, 20=SALVAGE,
21=FUELINIT, 22=SNAGINIT, 23=PILEBURN, 24=SNAGPBN, 25=FUELTRET,
26=STATFUEL, 27=FUELREPT, 28=MORTREPT, 29=FUELMULT, 30=POTFMOIS,
31=SNAGSUM, 32=MORTCLAS, 33=DROUGHT, 34=FUELMOVE, 35=POTFWIND,
36=POTFTEMP, 37=SNAGPSFT, 38=FUELMODL, 39=DEFULMOD, 40=CANCALC,
41=POTFSEAS, 42=POTFPAB, 43=SOILHEAT, 44=CARBREPT, 45=CARBCUT,
46=CARBCALC, 47=CANFPROF, 48=FUELFOTO, 49=FIRECALC, 50=FMODLIST,
51=DWDVLOUT, 52=DWDCVOUT, 53=FUELSOFT, 54=FMORTMLT

## Key rules
- Computed GOTO `GO TO (100,200,...,5400), NUMBER` → Julia if/elseif chain with @goto
- GOTO 10 (top of keyword read loop) → @goto label_10
- GOTO 90 → @goto label_90
- OPNEW/OPCNEW schedule fire activities
- All COMMON vars from fmcom.jl, fmfcom.jl, contrl.jl, prgprm.jl, fmparm.jl
- FMKEY entry → separate function FMKEY(key,paskey)
- FMKEYDMP/FMKEYRDR → separate functions
- LKECHO keyword echo flag
- APRMS(13)/PRMS(13) used for FUELFOTO (48) and FUELFOTO sub-params

## Chunks

### Chunk A — COMPLETE
Fortran lines: 1-290
Produces: function header + keyword table + PHOTOREF table + read loop +
          option 1 SALVSP (lines 148-209)
          option 2 END (lines 210-215)
          option 3 SVIMAGES (lines 216-221)
          option 4 BURNREPT (lines 222-234)
          option 5 MOISTURE (lines 235-290)

### Chunk B — COMPLETE
Fortran lines: 291-700
Produces:
          option 6 SIMFIRE (lines 291-363)
          option 7 FLAMEADJ (lines 364-439)
          option 8 POTFIRE (lines 440-462)
          option 9 SNAGFALL (lines 463-630)
          option 10 SNAGBRK (lines 631-660)
          option 11 SNAGDCAY (lines 661-700)

### Chunk C — COMPLETE
Fortran lines: 700-1065
Produces:
          option 12 SNAGOUT (lines 700-729)
          option 13 SNAGCLAS (lines 730-786)
          option 14 LANDOUT (lines 787-805)
          option 15 FUELOUT (lines 806-886)
          option 16 FUELDCAY (lines 887-955)
          option 17 DUFFPROD (lines 956-966)
          option 18 MOREOUT (lines 967-992)
          option 19 FUELPOOL (lines 993-1065)

### Chunk D — COMPLETE
Fortran lines: 1066-1400
Produces:
          option 20 SALVAGE (lines 1066-1118)
          option 21 FUELINIT (lines 1119-1160)
          option 22 SNAGINIT (lines 1161-1232)
          option 23 PILEBURN (lines 1233-1263)
          option 24 SNAGPBN (lines 1264-1322)
          option 25 FUELTRET (lines 1323-1333)
          option 26 STATFUEL (lines 1334-1351)
          option 27 FUELREPT (lines 1352-1367)
          option 28 MORTREPT (lines 1368-1390)
          option 29 FUELMULT (lines 1391-1442)
          option 30 POTFMOIS (lines 1443-1457)

### Chunk E — COMPLETE
Fortran lines: 1400-1800
Produces:
          option 31 SNAGSUM (lines 1458-1474)
          option 32 MORTCLAS (lines 1475-1514)
          option 33 DROUGHT (lines 1515-1657)
          option 34 FUELMOVE (lines 1658-1670)
          option 35 POTFWIND (lines 1671-1682)
          option 36 POTFTEMP (lines 1683-1716)
          option 37 SNAGPSFT (lines 1717-1794)
          option 38 FUELMODL (lines 1795-1971; large)

### Chunk F — COMPLETE
Fortran lines: 1972-2295
Produces:
          option 39 DEFULMOD (lines 1972-1999; complex)
          option 40 CANCALC (lines 2000-2011)
          option 41 POTFSEAS (lines 2012-2023)
          option 42 POTFPAB (lines 2024-2041)
          option 43 SOILHEAT (lines 2042-2061)
          option 44 CARBREPT (lines 2062-2081)
          option 45 CARBCUT (lines 2082-2117)
          option 46 CARBCALC (lines 2118-2136)
          option 47 CANFPROF (lines 2137-2136)
          option 48 FUELFOTO (lines 2137-2292; complex: photo series lookup)

### Chunk G — COMPLETE
Fortran lines: 2293-2560
Produces:
          option 49 FIRECALC (lines 2293-2374)
          option 50 FMODLIST (lines 2375-2419)
          option 51 DWDVLOUT (lines 2420-2438)
          option 52 DWDCVOUT (lines 2439-2458)
          option 53 FUELSOFT (lines 2459-2505)
          option 54 FMORTMLT (lines 2506-2550)
          FMKEY entry (lines 2551-2556)
          end of FMIN function + closing

### Chunk H — COMPLETE
Fortran lines: 2557-2732
Produces: function FMKEYDMP + function FMKEYRDR
