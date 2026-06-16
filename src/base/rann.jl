# base/rann.jl — RANN: Park-Miller LCG random number generator
# Translated from: bin/FVSsn_buildDir/rann.f (69 lines)
#
# Uses module-level globals S0, S1 (Float64) and SS (Float32) from rancom.jl.
# ENTRY RANSED  — reseed the generator
# ENTRY RANNGET — export current S0 as Float64
# ENTRY RANNPUT — import S0 from Float64

function RANN(sel_dummy=nothing)::Float32
    global S1 = mod(Float64(16807) * S0, Float64(2147483647))
    sel = Float32(S1 / Float64(2147483648))
    global S0 = S1
    return sel
end

function RANSED(lset::Bool, seed::Float32)::Float32
    global S0, SS
    if !lset
        # LSET=false: reset to SS (start over)
        S0 = Float64(SS)
        return Float32(SS)
    end
    # LSET=true: use supplied seed (force odd)
    s = seed
    if mod(s, Float32(2)) == Float32(0)
        s = s + Float32(1)
    end
    SS = s
    S0 = Float64(s)
    return s
end

function RANNGET()::Float64
    return S0
end

function RANNPUT(passs0::Float64)
    global S0 = passs0
    return nothing
end
