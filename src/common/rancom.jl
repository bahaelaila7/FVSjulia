# RANCOM.F77 — Random number generator state
# Fortran COMMON /RANCOM/ → module-level globals

S0::Float64 = Float64(0.0)   # RNG state 0
S1::Float64 = Float64(0.0)   # RNG state 1
SS::Float32 = Float32(0.0)   # supplemental RNG state
