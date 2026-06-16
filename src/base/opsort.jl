# base/opsort.f — OPSORT: integer ascending identification sort over two keys
# Translated from: bin/FVSsn_buildDir/opsort.f (97 lines)
#
# Quickersort (Scowen 1965) on arrays A (primary key) and A2 (secondary key).
# Sorts the INDEX array so that (A[INDEX[i]], A2[INDEX[i]]) is non-decreasing.
# If LSEQ is true, INDEX is initialized to 1..N before sorting.
# Uses 'stk_top'/'ipush' locals to avoid shadowing the global ITOP (dbstk.jl).

function OPSORT(n::Int32, a::AbstractVector{Int32}, a2::AbstractVector{Int32},
                idx::Vector{Int32}, lseq::Bool)
    if lseq
        for i in 1:Int(n)
            idx[i] = Int32(i)
        end
    end
    Int(n) < 2 && return nothing

    ipush   = zeros(Int32, 33)
    stk_top = 0          # local stack pointer (shadows nothing; global is ITOP)
    il = 1; iu = Int(n)

    local indil::Int, indiu::Int, ip::Int, indip::Int, t::Int32, t2::Int32
    local kl::Int, ku::Int, indkl::Int, indku::Int, jl::Int, ju::Int

    @label label_30
    if iu <= il; @goto label_40; end
    indil = Int(idx[il]); indiu = Int(idx[iu])
    if iu > il + 1; @goto label_50; end
    if a[indil] < a[indiu]; @goto label_40; end
    if a[indil] == a[indiu] && a2[indil] <= a2[indiu]; @goto label_40; end
    idx[il] = Int32(indiu); idx[iu] = Int32(indil)

    @label label_40
    stk_top == 0 && return nothing
    il = Int(ipush[stk_top-1]); iu = Int(ipush[stk_top]); stk_top -= 2
    @goto label_30

    @label label_50
    ip    = div(il + iu, 2)
    indip = Int(idx[ip]); t = a[indip]; t2 = a2[indip]
    idx[ip] = Int32(indil); kl = il; ku = iu

    @label label_60
    kl += 1
    if kl > ku; @goto label_90; end
    indkl = Int(idx[kl])
    if a[indkl] < t; @goto label_60; end
    if a[indkl] == t && a2[indkl] <= t2; @goto label_60; end

    @label label_70
    indku = Int(idx[ku])
    if ku < kl; @goto label_100; end
    if a[indku] < t; @goto label_80; end
    if a[indku] == t && a2[indku] < t2; @goto label_80; end
    ku -= 1; @goto label_70

    @label label_80
    idx[kl] = Int32(indku); idx[ku] = Int32(indkl); ku -= 1; @goto label_60

    @label label_90
    indku = Int(idx[ku])

    @label label_100
    idx[il] = Int32(indku); idx[ku] = Int32(indip)
    if ku <= ip; @goto label_110; end
    jl = il; ju = ku - 1; il = ku + 1; @goto label_120

    @label label_110
    jl = ku + 1; ju = iu; iu = ku - 1

    @label label_120
    stk_top += 2; ipush[stk_top-1] = Int32(jl); ipush[stk_top] = Int32(ju)
    @goto label_30
end
