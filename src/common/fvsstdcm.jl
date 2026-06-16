# FVSSTDCM.F77 — FVSStand post-processor control
# Fortran COMMON /FVSSTDCM/ → module-level globals

FSTOPEN::Bool = false    # true once tree data file has been opened
KOLIST::Int32 = Int32(27) # unit number for FVSStand tree data output (default 27)
