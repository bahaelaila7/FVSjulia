# ESHAP2.F77 — Establishment shape block 2 (plot-level arrays)
# Fortran COMMON /ESHAP2/ → module-level globals

SUMPRB::Float32 = Float32(0.0)

const ESB1   = zeros(Float32, MAXPLT)
const NSTORE = zeros(Int32, MAXPLT)
const PLPROB = zeros(Float32, MAXPLT)
const PNN    = zeros(Float32, MAXPLT)
const PROB1  = zeros(Float32, MAXPLT)
const XSTORE = zeros(Float32, MAXPLT)
