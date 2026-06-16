# bachlo.jl — BACHLO: Batchelor normal random variate generator
# Translated from: bachlo.f (90 lines)
#
# Returns a random number from N(xbar, stdev) using the Batchelor composite
# rejection technique (Tocher 1963).  Uses module-level RANN for uniform draws.

function BACHLO(xbar::Real, stdev::Real)
    xbar_f = Float32(xbar)
    stdev_f = Float32(stdev)
    if stdev_f <= Float32(0)
        return xbar_f
    end
    while true
        u = Ref(Float32(0)); r1 = Ref(Float32(0)); r2 = Ref(Float32(0))
        RANN(u); RANN(r1); RANN(r2)
        local x::Float32, z::Float32
        if u[] > Float32(2.0/3.0)
            z_val = Float32(3) * u[] - Float32(2)
            if z_val < Float32(0.001); continue; end
            x = Float32(1) - Float32(0.5) * log(z_val)
            z = Float32(0.5) * (x - Float32(2))^2
        else
            x = Float32(1.5) * u[]
            z = Float32(0.5) * x * x
        end
        y = -log(r1[])
        if y <= z; continue; end
        if r2[] >= Float32(0.5); x = -x; end
        return x * stdev_f + xbar_f
    end
end
