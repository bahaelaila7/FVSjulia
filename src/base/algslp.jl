# algslp.jl — ALGSLP: piecewise linear interpolation
# Translated from: algslp.f (43 lines)
#
# Returns value of a linear-segmented function defined by (X,Y) pairs at XX.
# If XX < X[1], returns Y[1]; if XX >= X[N], returns Y[N].

function ALGSLP(xx::Real, x::AbstractVector, y::AbstractVector, n::Integer)::Float32
    xx = Float32(xx)
    if xx < Float32(x[1])
        return Float32(y[1])
    elseif xx >= Float32(x[n])
        return Float32(y[n])
    else
        for i in 1:Int(n)-1
            if xx < Float32(x[i+1])
                return Float32(y[i]) + (Float32(y[i+1]) - Float32(y[i])) /
                       (Float32(x[i+1]) - Float32(x[i])) * (xx - Float32(x[i]))
            end
        end
        return Float32(y[n])
    end
end
