# opcycl.f — OPCYCL: map activities to cycles via IMGPTS
# Translated from: bin/FVSsn_buildDir/opcycl.f (101 lines)
#
# Fills IMGPTS(icyc, 1..2) with start/end positions in IOPSRT for each cycle.

function OPCYCL(ncyc::Int32, iy::AbstractVector{Int32})
    mxact = IMGL - Int32(1)

    if mxact <= Int32(0)
        for i in 1:ncyc
            IMGPTS[i, 1] = Int32(0)
        end
        return nothing
    end

    j    = Int32(1)
    ildt = IOPSRT[j]
    ildt = IDATE[ildt]

    for i in 1:ncyc
        iy2 = iy[i + 1]

        if ildt >= iy2 || j > mxact
            IMGPTS[i, 1] = Int32(0)
            IMGPTS[i, 2] = Int32(0)
            continue
        end

        IMGPTS[i, 1] = j

        while true
            j = j + Int32(1)
            if j > mxact
                break
            end
            ildt = IOPSRT[j]
            ildt = IDATE[ildt]
            if ildt >= iy2
                break
            end
        end

        IMGPTS[i, 2] = j - Int32(1)
    end

    return nothing
end
