# notre.jl — Trees-per-acre calculation
# Translated from: base/notre.f (128 lines)
#
# NOTRE computes trees/acre (PROB) for each tree record based on the
# sampling design. Live trees (1..IREC1) and dead trees (IREC2..MAXTRE)
# are processed separately. The dead-tree pass inflates PROB by FINT/FINTM.

"""
    NOTRE()

Calculate trees per acre for all tree records.

Variable-plot trees (DBH >= BRK): P = PROB*BAF*183.3465/π / DBH²  [+ fixed large-tree term]
Fixed-plot trees (DBH < BRK):     P = PROB * FPA / π

Dead trees: PROB further inflated by FINT/FINTM (growth period / mortality period).
"""
function NOTRE()
    if (ITRN <= Int32(0)) && (IREC2 >= MAXTP1)
        return nothing
    end

    fp  = FPA / PI
    fp2 = Float32(0.0)
    if TFPA > Float32(0.0)
        fp = Float32(1.0) / TFPA
    end
    vp = BAF * Float32(183.3465) / PI

    if BAF > Float32(0.0)
        @goto label_5
    end
    vp  = Float32(0.0)
    fp2 = -BAF / PI

    @label label_5
    i1 = Int32(1)
    i2 = IREC1

    @label label_10
    for i in i1:i2
        p = PROB[i]
        d = DBH[i]
        if p <= Float32(0.0); p = Float32(1.0); end

        if d < BRK
            @goto label_20
        end
        p = p * vp / (d * d) + p * fp2
        @goto label_30

        @label label_20
        p = p * fp

        @label label_30
        if p <= Float32(0.0); p = Float32(9.0e-25); end

        # Adjust for non-stockable points
        PROB[i] = p * GROSPC

        # Warn if TPA > 1000
        if p > Float32(1000.0)
            ERRGRO(true, Int32(40))
            @printf(io_units[JOSTND],
                "\n********   FVS40 WARNING:  TREE_ID=%6d TREE INDEX=%4d SPECIES=%3d DIAMETER=%5.1f TPA=%8.2f\n",
                IDTREE[i], i, ISP[i], DBH[i], PROB[i])
        end

        # Western Root Disease prob assignment
        RDPRIN(i)
    end

    # Switch to dead-tree pass if needed
    if i1 != Int32(1)
        @goto label_60
    end
    if IREC2 >= MAXTP1
        @goto label_60
    end

    # Scale expansion factors for the mortality observation period
    vp  = vp  * (FINT / FINTM)
    fp  = fp  * (FINT / FINTM)
    fp2 = fp2 * (FINT / FINTM)

    i1 = IREC2
    i2 = MAXTRE
    @goto label_10

    @label label_60
    return nothing
end

# RDPRIN stub lives in base/extstubs.jl
