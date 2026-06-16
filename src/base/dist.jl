# base/dist.jl — DIST: find DBH at 5 percentile points of the distribution
# Translated from: bin/FVSsn_buildDir/dist.f (85 lines)
#
# Fills ATTR[1..5] with DBH at the 10,30,50,70,90 percentile points,
# ATTR[6] with the largest tree DBH.  Uses binary search in the PCT
# (descending-sorted percentile) array.  If IFST==1, fills INS[] with
# the tree indices and resets IFST=99, TRM=1.
#
# Arguments:
#   n      = ITRN (number of trees)
#   attr   = Float32[7] output (6 DBH percentile values + unused slot 7)
#   pctwk  = PCT array (descending percentile per tree slot)

function DIST(n::Integer, attr::AbstractVector{Float32}, pctwk::AbstractVector{Float32})
    if Int(ITRN) == 0
        for i in 1:6
            attr[i] = Float32(0)
            INS[i]  = Int32(0)
        end
        return nothing
    end

    n1     = n + 1
    itop_d = 1
    pctage = Float32(90)

    for i in 1:5
        j = 6 - i
        if itop_d != n
            ibot = n1
            while true
                iptr   = (ibot + itop_d) ÷ 2
                midptr = Int(IND[iptr])
                if pctwk[midptr] < pctage
                    ibot = iptr
                else
                    itop_d = iptr
                end
                itop_d + 1 >= ibot && break
            end
        end
        indtop  = Int(IND[itop_d])
        attr[j] = DBH[indtop]
        if IFST == Int32(1); INS[j] = Int32(indtop); end
        pctage -= Float32(20)
    end

    j = Int(IND[1])
    attr[6] = DBH[j]
    if IFST != Int32(1); return nothing; end
    INS[6]      = Int32(j)
    global IFST = Int32(99)
    global TRM  = Float32(1)
    return nothing
end
