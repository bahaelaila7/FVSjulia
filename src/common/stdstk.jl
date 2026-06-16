# STDSTK.F77 — Previous cycle tree attributes (for stand output)
# Fortran COMMON /STDSTK/ → module-level globals

const NBFDEF = zeros(Int32, MAXTRE)    # previous cycle BF defect factor
const NCFDEF = zeros(Int32, MAXTRE)    # previous cycle CF defect factor
const PDBH   = zeros(Float32, MAXTRE)  # previous cycle DBH
const PHT    = zeros(Float32, MAXTRE)  # previous cycle height
const PMRBFV = zeros(Float32, MAXTRE)  # previous cycle merch BF volume/tree
const PMRCFV = zeros(Float32, MAXTRE)  # previous cycle merch CF volume/tree
const PSCFV  = zeros(Float32, MAXTRE)  # previous cycle sawlog CF volume/tree
const PTOCFV = zeros(Float32, MAXTRE)  # previous cycle total CF volume/tree
