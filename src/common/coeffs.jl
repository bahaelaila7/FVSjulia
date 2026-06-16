# COEFFS.F77 — Species growth model coefficients
# Fortran COMMON /COEFFS/ → module-level globals

# Integer arrays indexed by species
const IORDER = zeros(Int32, MAXSP)   # thinning selection priorities

# Real scalars
AHAT::Float32   = Float32(0.0)   # Behre taper curve parameter A
BHAT::Float32   = Float32(0.0)   # Behre taper curve parameter B
BJPHI::Float32  = Float32(0.0)   # Box-Jenkins moving-average parameter
BJTHET::Float32 = Float32(0.0)   # Box-Jenkins auto-regressive parameter
H2COF::Float32  = Float32(0.0)   # height-squared coefficient in HG model
HDGCOF::Float32 = Float32(0.0)   # DG coefficient in height increment model

# Real arrays indexed by species (MAXSP)
const ATTEN  = zeros(Float32, MAXSP)     # calibration weight (observations)
const BKRAT  = zeros(Float32, MAXSP)     # bark ratio (DIB/DOB)
const COR    = zeros(Float32, MAXSP)     # diameter growth correction terms (additive)
const COR2   = zeros(Float32, MAXSP)     # correction terms (multiplicative, from input)
const CRCON  = zeros(Float32, MAXSP)     # crown ratio model constant terms
const DGCCF  = zeros(Float32, MAXSP)
const DGCON  = zeros(Float32, MAXSP)     # DG model constant terms
const DGDSQ  = zeros(Float32, MAXSP)
const DIFH   = zeros(Float32, MAXSP)     # attenuation vector for regent HG model
const FL     = zeros(Float32, MAXSP)     # DG multiplier (decelerated, for tripling)
const FM     = zeros(Float32, MAXSP)     # DG multiplier (middle, for tripling)
const FU     = zeros(Float32, MAXSP)     # DG multiplier (accelerated, for tripling)
const HT1    = zeros(Float32, MAXSP)     # ht-DBH default coefficients
const HT2    = zeros(Float32, MAXSP)
const HTCON  = zeros(Float32, MAXSP)     # HG model constant terms
const RHCON  = zeros(Float32, MAXSP)     # small tree HG constant terms
const SIGMA  = zeros(Float32, MAXSP)     # DG pooled variance
const SIGMAR = zeros(Float32, MAXSP)     # DG regression std errors
const SMCON  = zeros(Float32, MAXSP)     # small tree DG constant terms
const VARDG  = zeros(Float32, MAXSP)
const WCI    = zeros(Float32, MAXSP)     # Bayesian weights / asymptote for correction

# Real arrays with second dimension
const BFDEFT = zeros(Float32, 9, MAXSP)  # board foot defect by diameter class
const BFLA0  = zeros(Float32, MAXSP)     # BF form-defect correction constant
const BFLA1  = zeros(Float32, MAXSP)     # BF form-defect correction linear
const CFDEFT = zeros(Float32, 9, MAXSP)  # cubic volume defect by diameter class
const CFLA0  = zeros(Float32, MAXSP)     # CF form-defect correction constant
const CFLA1  = zeros(Float32, MAXSP)     # CF form-defect correction quadratic

# BJRHO(40) — serial correlation at lag=J of ARMA model
const BJRHO = zeros(Float32, 40)
