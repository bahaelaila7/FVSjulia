# ECON.F77 — Simple economics flags
# Fortran COMMON /ECON/ → module-level globals

LECBUG::Bool = false   # economics debug flag
LECON::Bool  = false   # economics on flag
JOSUME::Int32 = Int32(0)  # economics summary output unit
