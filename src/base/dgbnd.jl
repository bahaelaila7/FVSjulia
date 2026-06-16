# dgbnd.jl — DGBND: diameter growth bounds check for 90 sn species
# Translated from: dgbnd.f (153 lines)
#
# Enforces a maximum DG that ramps linearly from 1.0 to 0.048 between
# species-specific DBH thresholds DLODHI[:,1] and DLODHI[:,2].
# Also enforces the SIZCAP(:,1) DBH size cap when SIZCAP(:,3) < 1.5.

const _DGBND_DLODHI = Float32[
    # columns: [lo, hi]  for species 1..15
    26.0f0,34.0f0,  998.0f0,999.0f0,  38.0f0,52.0f0,  18.9f0,24.0f0,  998.0f0,999.0f0,
    998.0f0,999.0f0, 32.6f0,48.0f0,  998.0f0,999.0f0, 18.7f0,28.0f0,  24.2f0,40.0f0,
    28.7f0,40.0f0,  998.0f0,999.0f0, 998.0f0,999.0f0, 998.0f0,999.0f0, 79.8f0,144.0f0,
    # 16..30
    998.0f0,999.0f0, 39.3f0,84.0f0,  26.1f0,34.0f0,  26.7f0,60.0f0,  998.0f0,999.0f0,
    998.0f0,999.0f0, 998.0f0,999.0f0, 998.0f0,999.0f0, 38.4f0,54.0f0,  998.0f0,999.0f0,
    17.3f0,27.0f0,  998.0f0,999.0f0, 46.5f0,144.0f0,  32.9f0,60.0f0,  11.3f0,13.4f0,
    # 31..45
    9.7f0,12.0f0,   22.4f0,27.0f0,  42.8f0,60.0f0,  30.7f0,60.0f0,  33.4f0,84.0f0,
    36.0f0,48.0f0,  37.0f0,48.0f0,  33.2f0,72.0f0,  28.1f0,33.4f0,  20.5f0,36.0f0,
    998.0f0,999.0f0, 30.0f0,36.0f0,  32.9f0,96.0f0,  39.6f0,60.0f0,  998.0f0,999.0f0,
    # 46..60
    32.5f0,43.0f0,  27.0f0,72.0f0,  36.5f0,84.0f0,  32.5f0,43.0f0,  36.5f0,84.0f0,
    21.2f0,22.0f0,  23.6f0,30.0f0,  63.8f0,89.0f0,  998.0f0,999.0f0, 33.0f0,60.0f0,
    18.6f0,24.0f0,  16.7f0,24.0f0,  19.2f0,36.0f0,  56.6f0,125.0f0,  46.5f0,144.0f0,
    # 61..75
    48.0f0,60.0f0,  26.9f0,84.0f0,  998.0f0,999.0f0, 34.5f0,48.0f0,  42.3f0,84.0f0,
    46.2f0,84.0f0,  17.2f0,26.0f0,  48.1f0,84.0f0,  48.0f0,60.0f0,  22.7f0,27.0f0,
    47.2f0,108.0f0, 37.2f0,72.0f0,  47.6f0,72.0f0,  998.0f0,999.0f0, 998.0f0,999.0f0,
    # 76..90
    40.6f0,96.0f0,  38.9f0,52.0f0,  998.0f0,999.0f0, 58.8f0,69.0f0,  30.8f0,60.0f0,
    38.8f0,60.0f0,  25.6f0,31.6f0,  998.0f0,999.0f0, 31.4f0,38.0f0,  23.9f0,27.0f0,
    46.7f0,130.0f0, 35.8f0,80.0f0,  24.1f0,29.0f0,  998.0f0,999.0f0, 20.5f0,25.0f0,
]

# Reshaped to 90×2 (row = species, col 1 = lo, col 2 = hi)
const _DGBND_DLODHI_MAT = reshape(_DGBND_DLODHI, 2, 90)

function DGBND(ispc::Integer, dbh::Real, ddg_ref::Ref{Float32})
    lo = _DGBND_DLODHI_MAT[1, ispc]
    hi = _DGBND_DLODHI_MAT[2, ispc]
    dbhf = Float32(dbh)
    ddg  = ddg_ref[]

    if dbhf <= lo
        # no adjustment
    elseif dbhf > hi
        ddg = Float32(0.048)
    else
        ddg = ddg * (Float32(1) + Float32(0.90) * ((dbhf - lo) / (lo - hi)))
        if ddg < Float32(0.048); ddg = Float32(0.048); end
    end

    # size cap check
    if (dbhf + ddg) > SIZCAP[ispc, 1] && SIZCAP[ispc, 3] < Float32(1.5)
        ddg = SIZCAP[ispc, 1] - dbhf
        if ddg < Float32(0.01); ddg = Float32(0.01); end
    end

    ddg_ref[] = ddg
    return nothing
end

# Convenience overload for scalar pass-by-value callers (matches dgdriv.jl stub signature).
# Caller must re-assign from the Ref after this form isn't useful, so prefer Ref form.
function DGBND(ispc::Integer, dbh::Real, ddg::Float32)
    r = Ref(ddg)
    DGBND(ispc, dbh, r)
    return r[]
end
