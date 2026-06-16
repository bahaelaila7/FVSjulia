# fmr6htls.f — Region 6 snag height loss (FIRE-VBASE)
# FMR6HTLS: proportion of current height lost for one snag record
# Based on Kim Mellen (R6 wildlife ecologist) species-group tables.
# SN variant falls into DEFAULT case (uses WSSPEC table).
# Called from: FMSNGHT (only for PN/WC/BM/EC/OP/SO-Oregon variants)

function FMR6HTLS(ksp::Integer, x2_ref::Ref{Float32})
    debug = DBCHK("FMR6HTLS", 8, ICYC)
    if debug
        @printf(get(io_units, Int32(JOSTND), stdout),
            " FMR6HTLS CYCLE=%2d KSP=%5d VARACD=%s\n", ICYC, ksp, VARACD)
    end

    # Species group (1-15) tables per variant
    WSSPEC = Int32[
        11,12,12,13,12, 8,14, 1, 1, 8,
         7, 5, 2, 2, 5, 4, 1, 1, 9,10,
        15,15,15, 6, 6, 6, 6, 6, 1, 3,
         2, 7, 1, 6, 6, 6, 6, 6, 6]
    BMSPEC = Int32[
         2, 3, 4,12,10, 1, 7, 8,13, 5,
         2, 2, 1, 1, 6, 6, 5, 6]
    ECSPEC = Int32[
         2, 3, 4,11, 1,12, 7, 8,13, 5,
         9,10, 1, 2,14,12, 3, 1, 1,15,
        15,15, 6, 6, 6, 6, 6, 6, 6, 6,
        10, 6]
    SOSPEC = Int32[
         2, 2, 4,12,10, 1, 7, 8,12, 5,
         1,12,13,11,14, 2, 3, 1, 9, 1,
        15,15,15, 6, 6, 6, 6, 6, 6, 6,
         6, 4, 6]

    # Proportion of height lost when a snag loses height
    SNHTLS = Float32[
        0.141, 0.202, 0.092, 0.219, 0.172, 0.232, 0.139, 0.199, 0.225, 0.262,
        0.199, 0.277, 0.119, 0.193, 0.287]
    # Proportion of snags that actually lose height in a given year
    PRHTLS = Float32[
        0.059, 0.122, 0.063, 0.075, 0.053, 0.083, 0.057, 0.054, 0.122, 0.106,
        0.133, 0.072, 0.042, 0.055, 0.150]

    local spg::Int
    if VARACD == "EC"
        spg = Int(ECSPEC[ksp])
    elseif VARACD == "BM"
        spg = Int(BMSPEC[ksp])
    elseif VARACD == "SO"
        spg = Int(SOSPEC[ksp])
    else  # PN, WC, WS, SN, and all others → WSSPEC
        spg = Int(WSSPEC[ksp])
    end

    local y_ref = Ref(Float32(0))
    RANN(y_ref)
    local y::Float32 = y_ref[]

    local x::Float32 = 0.0f0
    if y <= PRHTLS[spg]
        x = SNHTLS[spg]
    end

    if debug
        @printf(get(io_units, Int32(JOSTND), stdout),
            " FMR6HTLS X=%6.2f Y=%6.2f SPG=%3d\n", x, y, spg)
    end

    x2_ref[] = x
    return nothing
end
