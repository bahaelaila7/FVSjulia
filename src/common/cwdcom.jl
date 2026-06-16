# CWDCOM.F77 — Crown width model user coefficients
# Fortran COMMON /CWDCOM/ → module-level globals

# User-defined crown width equation: CW = CWD0 + CWD1 + CWD2*DBH^CWD3
# Large tree (DBH >= CWTDBH) coefficients
const CWDL0 = zeros(Float32, MAXSP)
const CWDL1 = zeros(Float32, MAXSP)
const CWDL2 = zeros(Float32, MAXSP)
const CWDL3 = zeros(Float32, MAXSP)

# Small tree (DBH < CWTDBH) coefficients
const CWDS0 = zeros(Float32, MAXSP)
const CWDS1 = zeros(Float32, MAXSP)
const CWDS2 = zeros(Float32, MAXSP)
const CWDS3 = zeros(Float32, MAXSP)

# Transition DBH
const CWTDBH = zeros(Float32, MAXSP)   # DBH breakpoint between small/large equations

# Flag: true if user provided their own equations for this species
const LSPCWE = fill(false, MAXSP)
