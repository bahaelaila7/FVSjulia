# ESCOM2.F77 — Establishment model common block 2 (full regen variants)
# Fortran COMMON /ESCOM2/ → module-level globals

const CHAB  = zeros(Float32, 16, 10)
const CPRE  = zeros(Float32, 4, 10)
const DHAB  = zeros(Float32, 16, 10)
const DPRE  = zeros(Float32, 4, 10)
const FHAB  = zeros(Float32, 16, 10)
const FPRE  = zeros(Float32, 4, 10)
const PADV  = zeros(Float32, MAXSP)
const PSUB  = zeros(Float32, MAXSP)
const PXCS  = zeros(Float32, MAXSP)
const SPEHAB = zeros(Float32, 5, 4)
const XPREP  = zeros(Float32, 4, 5)
