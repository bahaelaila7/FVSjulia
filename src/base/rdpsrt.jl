# base/rdpsrt.jl — RDPSRT: real descending indirect Quickersort (Scowen 1965)
# Translated from: bin/FVSsn_buildDir/rdpsrt.f (106 lines)
#
# Rearranges INDEX[1..n] so that A[INDEX[1]] >= A[INDEX[2]] >= ... >= A[INDEX[n]].
# If lseq=true, INDEX is pre-initialized to 1..n before sorting.
# The physical array A is not modified.

function RDPSRT(n::Integer, a::AbstractVector, index::AbstractVector{Int32}, lseq::Bool)
    if lseq
        for i in 1:n
            index[i] = Int32(i)
        end
    end
    n < 2 && return nothing

    ipush = zeros(Int, 33)
    itop = 0; il = 1; iu = n
    indil = 0; indiu = 0; indip = 0
    indkl = 0; indku = 0
    ip = 0; kl = 0; ku = 0; jl = 0; ju = 0
    t = zero(eltype(a))

    @label label_30
    if iu <= il; @goto label_40; end
    indil = Int(index[il]); indiu = Int(index[iu])
    if iu > il + 1; @goto label_50; end
    if a[indil] >= a[indiu]; @goto label_40; end
    index[il] = Int32(indiu); index[iu] = Int32(indil)

    @label label_40
    if itop == 0; return nothing; end
    il = ipush[itop-1]; iu = ipush[itop]; itop -= 2
    @goto label_30

    @label label_50
    ip    = (il + iu) ÷ 2
    indip = Int(index[ip]); t = a[indip]
    index[ip] = Int32(indil)
    kl = il; ku = iu

    @label label_60
    kl += 1
    if kl > ku; @goto label_90; end
    indkl = Int(index[kl])
    if a[indkl] >= t; @goto label_60; end

    @label label_70
    indku = Int(index[ku])
    if ku < kl; @goto label_100; end
    if a[indku] > t; @goto label_80; end
    ku -= 1
    @goto label_70

    @label label_80
    index[kl] = Int32(indku); index[ku] = Int32(indkl); ku -= 1
    @goto label_60

    @label label_90
    indku = Int(index[ku])

    @label label_100
    index[il] = Int32(indku); index[ku] = Int32(indip)
    if ku <= ip; @goto label_110; end
    jl = il; ju = ku - 1; il = ku + 1
    @goto label_120

    @label label_110
    jl = ku + 1; ju = iu; iu = ku - 1

    @label label_120
    itop += 2
    ipush[itop-1] = jl; ipush[itop] = ju
    @goto label_30
end
