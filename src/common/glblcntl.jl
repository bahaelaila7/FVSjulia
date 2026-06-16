# GLBLCNTL.F77 — Global control / restart / stoppoint mechanism
# Fortran COMMON /GLBLCNTL/ and /GLBLCNTLC/ → module-level globals

# Character strings
keywordfile::String = ""
restartfile::String = ""
stopptfile::String  = ""

# Integer flags
firstWrite::Int32             = Int32(1)   # 1=putstd not yet called
fvsRtnCode::Int32             = Int32(-1)  # -1=no startup; 0=ok; 1=error; 2=stop
jdstash::Int32                = Int32(-1)  # restart file unit (-1 = none)
jstash::Int32                 = Int32(-1)  # stoppoint file unit (-1 = none)
majorstopptcode::Int32        = Int32(0)
majorstopptyear::Int32        = Int32(0)
maxStoppts::Int32             = Int32(0)
minorstopptcode::Int32        = Int32(0)
minorstopptyear::Int32        = Int32(0)
originalRestartCode::Int32    = Int32(-1)
oldstopyr::Int32              = Int32(-1)
readFilePos::Int32            = Int32(0)
restartcode::Int32            = Int32(-1)
seekReadPos::Int32            = Int32(0)
stopstatcd::Int32             = Int32(0)   # 0=no stop; 1=stopWithStore; 2=simend; 3=stopWithoutStore; 4=reload
