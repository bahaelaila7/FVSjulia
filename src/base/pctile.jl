# base/pctile.jl — PCTILE: compute tree-attribute percentiles
# Translated from: bin/FVSsn_buildDir/pctile.f (75 lines)
#
# Fills PERCNT[INDEX[i]] with the cumulative percentage of CHAR from the
# smallest element up to the i-th ranked element (so the largest = 100%).
# Returns the total sum of CHAR (the Fortran TOT output argument).
#
# Called with:
#   n      = number of trees (ITRN)
#   index  = tree sort index sorted descending (IND, INDEX[1] = largest)
#   char   = per-tree attribute (WK5, PROB, WK3, ...)
#   percnt = output: percentile for each tree slot (PCT, WK3, ...)

function PCTILE(n::Integer, index::AbstractVector{Int32},
                char::AbstractVector{Float32}, percnt::AbstractVector{Float32})::Float32
    if n == 0
        percnt[1] = Float32(0)
        return Float32(0)
    end
    percnt[1] = Float32(100)
    tot = char[1]
    n <= 1 && return tot

    nm1  = n - 1
    indn = Int(index[n])
    percnt[indn] = char[indn]

    for i in 1:nm1
        j      = n - i
        indjp1 = Int(index[j+1])
        indj   = Int(index[j])
        percnt[indj] = percnt[indjp1] + char[indj]
    end

    indx1 = Int(index[1])
    tot   = percnt[indx1]
    percnt[indx1] = tot / Float32(100)

    tot <= Float32(0) && return tot

    pctin1 = percnt[indx1]
    for i in 2:n
        indi = Int(index[i])
        percnt[indi] = percnt[indi] / pctin1
    end
    percnt[indx1] = Float32(100)
    return tot
end
