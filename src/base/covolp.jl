# covolp.jl — COVOLP: compute canopy cover accounting for crown overlap
# Translated from: covolp.f (59 lines)
#
# Uses Poisson model: COVER = (1 - exp(-CCCOEF * sum(CRAREA) / 43560)) * 100
# If PCCU > 5, returns 100% cover.

function COVOLP(debug::Bool, jostnd::Integer, ntrees::Integer,
                index::AbstractVector{<:Integer}, crarea::AbstractVector{Float32},
                cover_ref::Ref{Float32}, cccoef::Real)

    cover_ref[] = Float32(0)
    if debug
        @printf(io_units[Int32(jostnd)], " IN COVOLP, NTREES =%4d\n", ntrees)
    end
    if ntrees == 0; return nothing; end

    sumcr = Float32(0)
    if index[1] == 0
        for i in 1:ntrees; sumcr += crarea[i]; end
    else
        for i in 1:ntrees; sumcr += crarea[Int(index[i])]; end
    end

    pccu = Float32(cccoef) * (sumcr / Float32(43560))
    cover_ref[] = pccu > Float32(5) ? Float32(100) : (Float32(1) - exp(-pccu)) * Float32(100)

    if debug
        @printf(io_units[Int32(jostnd)], " SUM=%14.7E; COVER=%8.1f; CCCOEF=%8.6f\n",
                sumcr, cover_ref[], cccoef)
    end
    return nothing
end
