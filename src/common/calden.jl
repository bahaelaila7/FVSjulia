# CALDEN.F77 — Calibration density arrays (for establishment filter)
# Fortran COMMON /CALDEN/ → module-level globals

TPACRE::Float32 = Float32(0.0)   # inventory trees/acre in stand

const BAAINV  = zeros(Float32, MAXPLT)   # inventory BA/acre/plot >= REGNBK
const TPAAINV = zeros(Float32, MAXPLT)   # inventory TPA/plot >= REGNBK
