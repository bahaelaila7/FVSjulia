# FMPARM.F77 — Fire model dimension parameters
# Fortran PARAMETER → module-level constants

const MAXOPT_FM = Int32(40)      # max keywords linked to option processor
const MXSNAG    = Int32(2000)    # max snag records
const MXFLCL    = Int32(11)      # max fuel classes (1-9=woody, 10=litter, 11=duff)
const MXFMOD    = Int32(5)       # max active fuel models
const MXDFMD    = Int32(256)     # max definable fuel models
const TFMAX     = Int32(60)      # max years to track dead crown material
const P2T       = Float32(0.0005) # pounds-to-tons conversion

# Crown weight categories for CROWNW, OLDCRW, TFALL, CWD2B, CWD2B2:
#   0=foliage, 1=<0.25", 2=0.25-1", 3=1-3", 4=3-6", 5=6-12"
