# DBSTK.F77 — DBS subroutine stack (debugging/tracing)
# Fortran COMMON /DBSTK/ and /DBCHR/ → module-level globals

ALLSUB::String = "      "   # 6-char: all-subroutine flag (set to '$**SUB' by DBINIT)
const SUBNAM = fill(UInt8(' '), 255)  # mutable 255-byte packed debug-name buffer

ITOP::Int32   = Int32(0)
MAXLEN::Int32 = Int32(0)
MAXTOP::Int32 = Int32(0)
