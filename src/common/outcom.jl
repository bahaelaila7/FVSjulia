# OUTCOM.F77 — Output controls and percentile arrays
# Fortran COMMON /OUTCOM/ and /OUTCHR/ → module-level globals

# Character arrays — species composition strings
const IONSP   = Vector{String}(undef, 6)   # example tree species+class
const IOSPAC  = Vector{String}(undef, 4)
const IOSPBR  = Vector{String}(undef, 4)
const IOSPBV  = Vector{String}(undef, 4)
const IOSPCT  = Vector{String}(undef, 4)
const IOSPCV  = Vector{String}(undef, 4)
const IOSPMC  = Vector{String}(undef, 4)
const IOSPMO  = Vector{String}(undef, 4)
const IOSPMR  = Vector{String}(undef, 4)
const IOSPRT  = Vector{String}(undef, 4)
const IOSPTT  = Vector{String}(undef, 4)
const IOSPTV  = Vector{String}(undef, 4)
const IOSPSC  = Vector{String}(undef, 4)
const IOSPSR  = Vector{String}(undef, 4)

function _init_outcom_chars!()
    for v in (IONSP, IOSPAC, IOSPBR, IOSPBV, IOSPCT, IOSPCV, IOSPMC,
              IOSPMO, IOSPMR, IOSPRT, IOSPTT, IOSPTV, IOSPSC, IOSPSR)
        fill!(v, "   ")
    end
end

# Integer arrays
const IOICR  = zeros(Int32, 6)           # example tree ICR values
const IOSUM  = zeros(Int32, 22, MAXCY1)  # summary output stored by cycle(41) x attribute(22)

# Real arrays — percentile/distribution arrays (7 elements: 0,10,25,50,75,90,100)
const OACC       = zeros(Float32, 7)   # accretion/acre/year with distribution
const OBFCUR     = zeros(Float32, 7)   # current board foot volume
const OBFREM     = zeros(Float32, 7)   # board foot volume removed in thinning
const OCVCUR     = zeros(Float32, 7)   # current total cubic volume
const OCVREM     = zeros(Float32, 7)   # cubic volume removed in thinning
const OMCCUR     = zeros(Float32, 7)   # current merchantable cubic volume
const OMCREM     = zeros(Float32, 7)   # merchantable cubic volume removed
const OMORT      = zeros(Float32, 7)   # mortality/acre/year
const ONTCUR     = zeros(Float32, 7)   # current number of trees
const ONTREM     = zeros(Float32, 7)   # trees removed in thinning
const ONTRES     = zeros(Float32, 7)   # residual trees after thinning
const OSCCUR     = zeros(Float32, 7)   # current sawtimber cubic volume
const OSCREM     = zeros(Float32, 7)   # sawtimber cubic volume removed

# Biomass distribution arrays
const OAGBIOCUR   = zeros(Float32, 7)
const OAGBIOREM   = zeros(Float32, 7)
const OMERBIOCUR  = zeros(Float32, 7)
const OMERBIOREM  = zeros(Float32, 7)
const OCSAWBIOCUR = zeros(Float32, 7)
const OCSAWBIOREM = zeros(Float32, 7)
const OFOLIBIO    = zeros(Float32, 7)
const OFOLICARB   = zeros(Float32, 7)
const OFOLIBIOREM = zeros(Float32, 7)
const OFOLICARBREM= zeros(Float32, 7)
const OAGCARBCUR  = zeros(Float32, 7)
const OAGCARBREM  = zeros(Float32, 7)
const OMERCARBCUR = zeros(Float32, 7)
const OMERCARBREM = zeros(Float32, 7)
const OCSAWCARBCUR= zeros(Float32, 7)
const OCSAWCARBREM= zeros(Float32, 7)

# Species composition distribution arrays (4 elements)
const OSPAC = zeros(Float32, 4)
const OSPBR = zeros(Float32, 4)
const OSPBV = zeros(Float32, 4)
const OSPCT = zeros(Float32, 4)
const OSPCV = zeros(Float32, 4)
const OSPMC = zeros(Float32, 4)
const OSPMO = zeros(Float32, 4)
const OSPMR = zeros(Float32, 4)
const OSPRT = zeros(Float32, 4)
const OSPTT = zeros(Float32, 4)
const OSPTV = zeros(Float32, 4)
const OSPSC = zeros(Float32, 4)
const OSPSR = zeros(Float32, 4)

# Example tree arrays (6 example trees)
const DBHIO = zeros(Float32, 6)   # example tree DBH
const DGIO  = zeros(Float32, 6)   # example tree DG
const HTIO  = zeros(Float32, 6)   # example tree HT
const PCTIO = zeros(Float32, 6)   # example tree PCT
const PRBIO = zeros(Float32, 6)   # example tree PROB

# Removal totals
TRTPA::Float32   = Float32(0.0)
TRTCUFT::Float32 = Float32(0.0)
TRMCUFT::Float32 = Float32(0.0)
TRBDFT::Float32  = Float32(0.0)
TRSCUFT::Float32 = Float32(0.0)
