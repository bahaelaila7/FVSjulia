# SUMTAB.F77 — Summary table accumulation
# Fortran COMMON /SUMTAB/ → module-level globals

AGELST::Float32 = Float32(0.0)
TOTREM::Float32 = Float32(0.0)
MAIFLG::Int32   = Int32(0)
NEWSTD::Int32   = Int32(0)

const IBTAVH = zeros(Int32, MAXCY1)
const IBTCCF = zeros(Int32, MAXCY1)
const IOLDBA = zeros(Int32, MAXCY1)
const ISDI_S = zeros(Int32, MAXCY1)    # renamed to avoid clash with ISDI in contrl.jl
const ISDIAT = zeros(Int32, MAXCY1)
const BCYMAI = zeros(Float32, MAXCY1)
const QDBHAT = zeros(Float32, MAXCY1)
const QSDBT  = zeros(Float32, MAXCY1)
