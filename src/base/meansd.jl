# base/meansd.jl — MEANSD: mean and standard deviation of a Float32 vector
# Translated from: bin/FVSsn_buildDir/meansd.f (39 lines)

function MEANSD(a::AbstractVector{Float32}, n::Integer,
                abar_ref::Ref{Float64}, var_ref::Ref{Float64}, std_ref::Ref{Float64})
    dn   = Float64(n)
    apx  = Float64(0)
    for i in 1:n
        apx += Float64(a[i])
    end
    apx /= dn

    sum_v  = Float64(0)
    sumsq  = Float64(0)
    for i in 1:n
        z      = Float64(a[i]) - apx
        sum_v += z
        sumsq += z * z
    end

    abar       = sum_v / dn
    var_v      = (sumsq - (sum_v * abar)) / (dn - 1)
    std_v      = sqrt(var_v)
    abar      += apx

    abar_ref[] = abar
    var_ref[]  = var_v
    std_ref[]  = std_v
    return nothing
end
