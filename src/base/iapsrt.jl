# base/iapsrt.jl — IAPSRT: ascending integer indirect identification sort (Quickersort)
# Translated from: bin/FVSsn_buildDir/iapsrt.f (98 lines)
#
# Rearranges INDEX so that A[INDEX[1]] ≤ A[INDEX[2]] ≤ ... ≤ A[INDEX[N]].
# The vector A is not modified.
# If LSEQ is true, initializes INDEX = 1..N before sorting.

function IAPSRT(n::Integer, a::AbstractVector{Int32},
                index::AbstractVector{Int32}, lseq::Bool)
    if lseq
        for i in 1:n
            index[i] = Int32(i)
        end
    end

    if n < 2; return nothing; end

    ipush = zeros(Int32, 33)
    itop  = 0
    il    = 1; iu = n

    @label label_30
    if iu > il
        indil = Int(index[il]); indiu = Int(index[iu])
        if iu > il + 1
            @goto label_50
        end
        if a[indil] <= a[indiu]
            @goto label_40
        end
        index[il] = Int32(indiu)
        index[iu] = Int32(indil)
    end

    @label label_40
    if itop == 0; return nothing; end
    il   = Int(ipush[itop - 1])
    iu   = Int(ipush[itop])
    itop -= 2
    @goto label_30

    @label label_50
    ip    = (il + iu) ÷ 2
    indip = Int(index[ip])
    t     = a[indip]
    index[ip] = Int32(indil)
    kl    = il; ku = iu

    @label label_60
    kl += 1
    if kl > ku; @goto label_90; end
    indkl = Int(index[kl])
    if a[indkl] <= t; @goto label_60; end

    @label label_70
    indku = Int(index[ku])
    if ku < kl; @goto label_100; end
    if a[indku] < t
        @goto label_80
    end
    ku -= 1
    @goto label_70

    @label label_80
    index[kl] = Int32(indku)
    index[ku] = Int32(indkl)
    ku -= 1
    @goto label_60

    @label label_90
    indku = Int(index[ku])

    @label label_100
    index[il] = Int32(indku)
    index[ku] = Int32(indip)
    if ku <= ip
        jl = ku + 1; ju = iu; iu = ku - 1
    else
        jl = il; ju = ku - 1; il = ku + 1
    end

    itop += 2
    ipush[itop - 1] = Int32(jl)
    ipush[itop]     = Int32(ju)
    @goto label_30
end
