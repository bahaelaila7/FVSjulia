# base/iqrsrt.jl — IQRSRT: ascending integer Quickersort (Scowen 1965)
# Translated from: bin/FVSsn_buildDir/iqrsrt.f (77 lines)
# Sorts list[1..n] in ascending order in-place.

function IQRSRT(list::AbstractVector{Int32}, n::Integer)
    n <= 1 && return
    m  = 1
    i  = 1
    j  = Int(n)
    iu = zeros(Int, 33)
    il = zeros(Int, 33)
    t  = Int32(0)
    tt = Int32(0)

    @label label_5
    if i >= j; @goto label_70; end

    @label label_10
    k  = i
    ij = (i + j) ÷ 2
    t  = list[ij]
    if list[i] <= t; @goto label_20; end
    list[ij] = list[i]; list[i] = t; t = list[ij]

    @label label_20
    l = j
    if list[j] >= t; @goto label_40; end
    list[ij] = list[j]; list[j] = t; t = list[ij]
    if list[i] <= t; @goto label_40; end
    list[ij] = list[i]; list[i] = t; t = list[ij]
    @goto label_40

    @label label_30
    list[l] = list[k]; list[k] = tt

    @label label_40
    l = l - 1
    if list[l] > t; @goto label_40; end
    tt = list[l]

    @label label_50
    k = k + 1
    if list[k] < t; @goto label_50; end
    if k <= l; @goto label_30; end
    if l - i <= j - k; @goto label_60; end
    il[m] = i; iu[m] = l; i = k; m += 1; @goto label_80

    @label label_60
    il[m] = k; iu[m] = j; j = l; m += 1; @goto label_80

    @label label_70
    m -= 1
    if m <= 0; return; end
    i = il[m]; j = iu[m]

    @label label_80
    if j - i >= 11; @goto label_10; end
    if i == 1; @goto label_5; end
    i -= 1

    @label label_90
    i += 1
    if i == j; @goto label_70; end
    t = list[i + 1]
    if list[i] <= t; @goto label_90; end
    k = i

    @label label_100
    list[k + 1] = list[k]; k -= 1
    if t < list[k]; @goto label_100; end
    list[k + 1] = t
    @goto label_90
end
