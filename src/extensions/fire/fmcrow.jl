# SUBROUTINE FMCROW
# Translated from: fmcrow.f (205 lines), FIRE-SN
#
# Computes CROWNW(i, 1..6) — weight of foliage (j=0) and 5 woody size classes (j=1..5)
# for each tree, by mapping SN species numbers to LS-FFE crown equation indices and
# calling FMCROWE. Also increments GROW(i) for post-fire crown regrowth tracking.
# Called from: FMSDIT, FMPRUN

# ISPMAP: SN species 1..90 → LS-FFE crown equation species number (0-based Fortran → 1-based Julia stored same)
const _FMCROW_ISPMAP = Int32[
     8, 14,  9,  3,  3,  3,  3,  3,  3,  3,
     3,  5,  3,  3, 14, 14, 12, 26, 50, 19,
    18, 26, 44, 24, 24, 53, 39, 44, 55, 44,
    56, 44, 28, 16, 29, 15, 16, 44, 44, 44,
    44, 45, 46, 44, 44, 44, 44, 44, 44, 44,
    58, 58, 59, 59, 59, 47, 44, 44, 60, 17,
    40, 20, 30, 34, 34, 34, 34, 34, 30, 34,
    30, 33, 34, 30, 34, 34, 30, 35, 30, 48,
    64, 67, 25, 22, 22, 21, 22, 14, 44, 44
]

function FMCROW()
    local debug::Bool = false
    DBCHK(Ref(debug), "FMCROW", Int32(6), ICYC)
    if debug
        @printf(get(io_units, Int32(JOSTND), stdout),
                " ENTERING FMCROW CYCLE = %2d ITRN=%5d\n", ICYC, ITRN)
    end
    if ITRN == 0; return nothing; end

    local xv = zeros(Float32, 6)   # XV(0:5) — temp crown component weights

    for i in 1:ITRN
        # Increment post-fire crown regrowth counter; skip tree if crown not yet free
        if GROW[i] < Float32(1.0)
            GROW[i] = GROW[i] + Float32(1.0)
        end
        if GROW[i] < Float32(1.0); continue; end

        local spi::Int32 = _FMCROW_ISPMAP[ISP[i]]
        local d::Float32  = DBH[i]
        local h::Float32  = HT[i]
        local ic::Int32   = ICR[i]
        local sg::Float32 = V2T[ISP[i]]

        fill!(xv, 0.0f0)
        FMCROWE(spi, ISP[i], d, h, ic, sg, xv)

        for j in 1:6
            CROWNW[i, j] = xv[j]
            if debug
                @printf(get(io_units, Int32(JOSTND), stdout),
                        " I=%4d size=%d CROWNW=%10.4f\n", i, j-1, CROWNW[i, j])
            end
        end
    end
    return nothing
end
