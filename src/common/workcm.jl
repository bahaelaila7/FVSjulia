# WORKCM.F77 — Work arrays (scratch space shared across routines)
# Fortran COMMON /WORKCM/ → module-level globals

const IWORK1 = zeros(Int32, MAXTRE)   # scratch integer array (sorted diameter indices, etc.)
const WORK1  = zeros(Float32, MAXTRE) # scratch real array
const WORK2  = zeros(Float32, MAXSP)  # scratch by species
const WORK3  = zeros(Float32, MAXTRE) # scratch real array
