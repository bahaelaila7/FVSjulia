# PDEN.F77 — Plot density arrays
# Fortran COMMON /PDEN/ → module-level globals

OLDFNT::Float32 = Float32(0.0)
REGNBK::Float32 = Float32(0.0)   # break DBH between understory and overstory

const BAAA  = zeros(Float32, MAXPLT)          # point basal area > REGNBK
const OVER  = zeros(Float32, MAXSP, MAXPLT)   # basal area by species > REGNBK
const PCCF  = zeros(Float32, MAXPLT)          # point CCF
const PTPA  = zeros(Float32, MAXPLT)          # point TPA
const PRDA  = zeros(Float32, MAXPLT)          # point relative density (Zeide/SDIMAX)
const PTPAA = zeros(Float32, MAXPLT)          # point TPA > REGNBK
