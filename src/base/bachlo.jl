# bachlo.jl — BACHLO: Batchelor normal random variate generator
# Translated from: bachlo.f (90 lines)
#
# Returns a random number from N(xbar, stdev) using the Batchelor composite
# rejection technique (Tocher 1963).  The uniform-draw source is the 3rd arg
# (Fortran BACHLO(XBAR,STDEV,RNFUNC) passes RANN or ESRANN) — establishment
# height assignment uses ESRANN (the separate seed-55329 RNG), everything else RANN.

function BACHLO(xbar::Real, stdev::Real, rng=RANN)
    xbar_f = Float32(xbar)
    stdev_f = Float32(stdev)
    if stdev_f <= Float32(0)
        return xbar_f
    end
    while true
        u = Ref(Float32(0)); r1 = Ref(Float32(0)); r2 = Ref(Float32(0))
        rng(u); rng(r1); rng(r2)
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
