# METRIC.F77 — Metric conversion constants + runtime flag
# Fortran PARAMETER statements + COMMON /METRIC/ → module-level constants + global

# Runtime flag
LMTRIC::Bool = false   # true if metric output mode active

# Metric → US
const CMtoIN = Float32(0.3937)
const CMtoFT = Float32(0.0328084)
const MtoIN  = Float32(39.37)
const MtoFT  = Float32(3.28084)
const KMtoMI = Float32(0.6214)

const M2toFT2 = Float32(10.763867)
const HAtoACR = Float32(2.471)
const M3toFT3 = Float32(35.314455)
const KGtoLB  = Float32(2.2046226)
const TMtoTI  = Float32(1.102311)
const CtoF1   = Float32(1.8)
const CtoF2   = Float32(32.0)
const KJtoBTU = Float32(0.9478171)

# US → Metric
const INtoCM = Float32(2.54)
const FTtoCM = Float32(30.48)
const INtoM  = Float32(0.0254001)
const FTtoM  = Float32(0.3048)
const MItoKM = Float32(1.609)

const FT2toM2 = Float32(0.0929034)
const ACRtoHA = Float32(0.4046945)
const FT3toM3 = Float32(0.028317)
const LBtoKG  = Float32(0.4535924)
const TItoTM  = Float32(0.90718)
const FtoC1   = Float32(0.554)
const FtoC2   = Float32(-17.7)
const BTUtoKJ = Float32(1.0550559)

# Complex conversions
const M2pHAtoFT2pACR = Float32(4.3560773)
const M3pHAtoFT3pACR = Float32(14.291564)
const TpHAtoTpACR    = Float32(0.4460896)
const FT2pACRtoM2pHA = Float32(0.2295643)
const FT3pACRtoM3pHA = Float32(0.0699713)
const TpACRtoTpHA    = Float32(2.2417023)
