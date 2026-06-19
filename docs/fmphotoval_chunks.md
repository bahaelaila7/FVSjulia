# fmphotoval.jl Migration Plan

Source: `/workspace/ForestVegetationSimulator/bin/FVSsn_buildDir/fmphotoval.f` (2369 lines)
Target: `/workspace/FVSjulia/src/extensions/fire/fmphotoval.jl`

## Strategy
Write the file chunk by chunk. Each session: read the plan → read only the Fortran lines for the
current chunk → write/append to fmphotoval.jl → mark done here.

## Key rules
- MXFLCL=11 rows per column; VLT/VLH are 11×N; VLS is 9×N
- PROPROT refs: computed via `_mk_proprot(vlt, pr)` helper
- Direct refs: VLH and VLS given directly as DATA statements  
- Rows 1-3: VLH=VLT, VLS=0; Rows 4-9: VLS=VLT*PR[j], VLH=max(VLT-VLS,0); Rows 10-11: VLH=VLT
- Column-major: `reshape(Float32[...], 11, N)` matches Fortran DATA fill order
- REF15 = REF14 (identical DATA statements)
- REF22VLS, REF26VLS, REF29VLS, REF31VLS = all zeros → `zeros(Float32, 9, N)`
- No CASE 4 or CASE 10 in dispatch

## Chunks

### Chunk 1 — COMPLETE
Fortran lines: 1-267
Produces: file header + `_mk_proprot` helper + `const _REF1`
REF1: PROPROT type, 11×22 VLT (lines 225-246) + PROPROT1 (lines 248-252)

### Chunk 2 — COMPLETE
Fortran lines: 268-470
Produces: `const _REF2` (direct, 11×59 VLH + 9×59 VLS, lines 269-388)
          `const _REF3` (PROPROT, 11×66 VLT lines 391-456 + PROPROT3 lines 457-471)

### Chunk 3 — COMPLETE
Fortran lines: 471-815
Produces: `const _REF5` (PROPROT, 11×17, lines 488-510)
          `const _REF6` (PROPROT, 11×27, lines 527-560)
          `const _REF7` (PROPROT, 11×56, lines 577-645)
          `const _REF8` (PROPROT, 11×86, lines 662-766) — careful, 86 cols
          `const _REF9` (PROPROT, 11×26, lines 783-815)

### Chunk 4 — COMPLETE
Fortran lines: 815-990
Produces: `const _REF11` (PROPROT, 11×26, lines 833-865)
          `const _REF12` (PROPROT, 11×90, lines 882-990) — careful, 90 cols

### Chunk 5 — COMPLETE
Fortran lines: 990-1305
Produces: `const _REF13` (direct, 11×42 VLH + 9×42 VLS, lines 1007-1092)
          `const _REF14` (direct, 11×29 VLH + 9×29 VLS, lines 1095-1154)
          `const _REF15 = _REF14`
          `const _REF16` (direct, 11×41 VLH + 9×41 VLS, lines 1219-1303)

### Chunk 6 — COMPLETE
Fortran lines: 1305-1650
Produces: `const _REF17` (direct, 11×35 VLH + 9×35 VLS, lines 1306-1377)
          `const _REF18` (direct, 11×43 VLH + 9×43 VLS, lines 1380-1467)
          `const _REF19` (direct, 11×34 VLH + 9×34 VLS, lines 1470-1539)
          `const _REF20` (direct, 11×26 VLH + 9×26 VLS, lines 1542-1595)
          `const _REF21` (direct, 11×25 VLH + 9×25 VLS, lines 1598-1649)

### Chunk 7 — COMPLETE
Fortran lines: 1650-1960
Produces: `const _REF22` (direct, 11×36 VLH lines 1652-1692 + zeros VLS 9×36)
          `const _REF23` (PROPROT, 11×26, lines 1692-1725)
          `const _REF24` (direct, 11×27 VLH + 9×27 VLS, lines 1742-1797)
          `const _REF25` (PROPROT, 11×14, lines 1800-1817)
          `const _REF26` (direct, 11×16 VLH lines 1820-1840 + zeros VLS 9×16)
          `const _REF27` (direct, 11×30 VLH + 9×30 VLS, lines 1854-1915)
          `const _REF28` (PROPROT, 11×30, lines 1918-1955)

### Chunk 8 — COMPLETE
Fortran lines: 1960-2125
Produces: `const _REF29` (direct, 11×16 VLH lines 1958-1990 + zeros VLS 9×16)
          `const _REF30` (direct, 11×16 VLH + 9×16 VLS, lines 1992-2025)
          `const _REF31` (direct, 11×10 VLH lines 2028-2038 + zeros VLS 9×10)
          `const _REF32` (direct, 11×39 VLH + 9×39 VLS, lines 2042-2121)

### Chunk 9 — COMPLETE
Fortran lines: 2126-2370
Produces: `function FMPHOTOVAL(...)` dispatch with elseif chain + @goto label_50 + warning block
Also: update fire.jl includes, remove stub from extstubs.jl, mark plan.md done
