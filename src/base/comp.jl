# base/comp.jl — COMP: species composition percentages
# Translated from: bin/FVSsn_buildDir/comp.f (81 lines)
#
# Finds the 4 largest species-tree-class contributions of a stand attribute
# and loads CMP[1..4] with their percentages and ICMP[1..4] with their labels.
#
# Arguments:
#   cmp    = Float32[4] output: top-4 percentages
#   icmp   = String[4] output: top-4 "SP/class" 3-char labels
#   attr   = Float32[MAXSP,3] input: attribute by species × tree class (S/M/L)

function COMP(cmp::AbstractVector{Float32}, icmp::AbstractVector{<:AbstractString},
              attr::AbstractMatrix{Float32})
    ns = "---"
    if Int(ITRN) <= 0
        for i in 1:4
            cmp[i]  = Float32(0)
            icmp[i] = ns
        end
        return nothing
    end

    mxsp3 = Int(MAXSP) * 3
    work1 = zeros(Float32, mxsp3)
    work2 = zeros(Float32, mxsp3)
    ids   = zeros(Int32, mxsp3)

    j = 0
    for i1 in 1:Int(MAXSP)
        for i2 in 1:3
            j += 1
            work1[j] = attr[i1, i2]
        end
    end

    RDPSRT(mxsp3, work1, ids, true)
    PCTILE(mxsp3, ids, work1, work2)

    for i in 1:4
        j    = Int(ids[i])
        ispc = (j + 2) ÷ 3
        jmc  = mod(j, 3)
        if jmc == 0; jmc = 3; end
        k       = Int(ids[i+1])
        cmp[i]  = work2[j] - work2[k]
        lbl     = NSP[ispc, jmc]
        icmp[i] = length(lbl) >= 3 ? lbl[1:3] : rpad(lbl, 3)[1:3]
        if cmp[i] <= Float32(0); icmp[i] = ns; end
    end
    return nothing
end
