# base/getsed.jl — GETSED: generate odd integer seed from current time
# Translated from: bin/FVSsn_buildDir/getsed.f (28 lines)
#
# Heuristic seed: parses minute/second digits from the system clock and mixes
# them. "array" is the keyword ARRAY(); GETSED(array) sets array[1].
# SAVE variable I4 persists between calls via module-level global.

const _GETSED_i4 = Ref(Int32(100))

function GETSED(array::AbstractVector{Float32})
    dat_r = Ref(""); tim_r = Ref("")
    GRDTIM(dat_r, tim_r)
    tim = tim_r[]
    # Fortran: READ(TIM,'(T4,I2,T7,I2,T8,I1)') I1,I2,I3
    # TIM is "HH:MM:SS" (8 chars); T4=col4 → minutes chars 4-5; T7=col7 → sec chars 7-8; T8=col8
    i1 = Int(parse(Int32, tim[4:5]))   # minutes
    i2 = Int(parse(Int32, tim[7:8]))   # seconds
    i3 = Int(parse(Int32, tim[8:8]))   # units digit of seconds

    _GETSED_i4[] = _GETSED_i4[] + Int32(i3)
    if _GETSED_i4[] > Int32(300)
        _GETSED_i4[] = Int32(100) + Int32(i3)
    end
    i3m = mod(i3, 2) + 1
    i4v  = Int(_GETSED_i4[])

    val = Float32(trunc((Float32(i2 * 10000 + i1 * 100 + i2) / Float32(i1 + 1)) *
                        Float32(i2 + i4v) / Float32(10^i3m)))
    if mod(val, Float32(2)) == Float32(0); val = val + Float32(1); end
    # Fortran: round-trip through WRITE/READ of a 9-char float string → truncate to integer
    array[1] = parse(Float32, @sprintf("%9.0f", val))
    return nothing
end
