# SUBROUTINE FMCWD(IYR) — annual CWD decay + hard→soft transition
# ENTRY CWD1(ISNG, DIH, DISIN)    — falling snag material → CWD pools
# ENTRY CWD2(ISNG, DIH, DISIN, OLDHTH, OLDHTS) — broken snag top material → CWD
# ENTRY CWD3(KSP, D, DIH, HTH, CRWNRTO) — harvested tree material → CWD (from FMSCUT)
# Translated from: fmcwd.f (430 lines)
#
# Index notes:
#   BP(0:9) in Fortran → bp[1..10] in Julia (shift +1)
#   BPH(0:9) → bph[1..10]
#   Inner loop J=1..9 accesses BPH(J) and BPH(J-1) → bph[j+1] and bph[j]

# Breakpoints for fuel size categories (Fortran DATA BP: 0-indexed 0:9)
const _FMCWD_BP = Float32[0.0f0, 0.25f0, 1.0f0, 3.0f0, 6.0f0, 12.0f0, 20.0f0, 35.0f0, 50.0f0, 9999.0f0]
# SCNV: soft material is 80% density of hard
const _FMCWD_SCNV = Float32[0.80f0, 1.00f0]

function FMCWD(iyr::Integer)
    local debug::Bool = false
    debug = DBCHK(false, "FMCWD", Int32(5), ICYC)
    if debug
        @printf(io_units[Int32(JOSTND)], " ENTERING FMCWD CYCLE = %2d\n", ICYC)
    end

    # Decay CWD pools and transfer some to duff; hard→soft transition
    for i in 1:2, l in 1:4
        # Duff: decay first so we can safely add material to it
        CWD[i, 11, 1, l] *= (1.0f0 - (DKR[11, l] * 1.1f0))^NYRS
        CWD[i, 11, 2, l] *= (1.0f0 - DKR[11, l])^NYRS
        if CWD[i, 11, 1, l] < 0.0f0; CWD[i, 11, 1, l] = 0.0f0; end
        if CWD[i, 11, 2, l] < 0.0f0; CWD[i, 11, 2, l] = 0.0f0; end

        for j in 1:10
            # Compute amount decayed and move a fraction to duff before reducing pool
            local amt::Float32 = CWD[i, j, 1, l] - CWD[i, j, 1, l] * (1.0f0 - (DKR[j, l] * 1.1f0))^NYRS
            if amt < 1.0f-9; amt = 0.0f0; end
            CWD[i, 11, 2, l] += amt * PRDUFF[j, l]

            amt = CWD[i, j, 2, l] - CWD[i, j, 2, l] * (1.0f0 - DKR[j, l])^NYRS
            if amt < 1.0f-9; amt = 0.0f0; end
            CWD[i, 11, 2, l] += amt * PRDUFF[j, l]

            # Apply decay to pools
            CWD[i, j, 1, l] *= (1.0f0 - (DKR[j, l] * 1.1f0))^NYRS
            CWD[i, j, 2, l] *= (1.0f0 - DKR[j, l])^NYRS
            if CWD[i, j, 1, l] < 1.0f-9; CWD[i, j, 1, l] = 0.0f0; end
            if CWD[i, j, 2, l] < 1.0f-9; CWD[i, j, 2, l] = 0.0f0; end

            # Hard→soft transition: fraction reaching 64% of original density
            if j < 10
                local tosoft::Float32 = Float32(NYRS) * log(1.0f0 - DKR[j, l]) / log(0.64f0)
                if tosoft < 0.0f0; tosoft = 0.0f0; end
                if tosoft > 1.0f0; tosoft = 1.0f0; end
                tosoft = tosoft * CWD[i, j, 2, l]
                CWD[i, j, 1, l] += tosoft
                CWD[i, j, 2, l] -= tosoft
                if CWD[i, j, 1, l] < 1.0f-9; CWD[i, j, 1, l] = 0.0f0; end
                if CWD[i, j, 2, l] < 1.0f-9; CWD[i, j, 2, l] = 0.0f0; end
            end
        end
    end

    return nothing
end

# ---------------------------------------------------------------------------
# Shared computation body for CWD1 / CWD2 / CWD3 (label 1000 in Fortran)
# Distributes snag/log volume into size-class CWD pools using conical taper model.
# ---------------------------------------------------------------------------
function _fmcwd_process!(i_snag::Int, dih::Float32, dis::Float32,
                          hiht::Vector{Float32}, loht::Vector{Float32},
                          diam::Float32, htd::Float32, sp::Int32,
                          tvoli::Float32, lcuts::Bool, debug::Bool)
    if diam <= 0.1f0; diam_eff = 0.1f0; else diam_eff = diam; end

    # Cone model: radius-to-height ratio
    local rhrat::Float32 = ((htd * 12.0f0) - 54.0f0) / (0.5f0 * diam_eff)

    local idcl::Int32 = DKRCLS[sp]

    # Heights at which size-class breakpoints fall on the snag (0-indexed → julia +1)
    local bph = Vector{Float32}(undef, 10)
    for j in 0:9
        local x_h::Float32 = (0.5f0 * _FMCWD_BP[j+1] * rhrat) / 12.0f0
        bph[j+1] = max(0.10f0, htd - x_h)
    end

    for k in 1:2
        if k == 1 && dis <= 0.0f0; continue; end
        if k == 2 && dih <= 0.0f0; continue; end

        if loht[k] < 0.10f0; loht[k] = 0.10f0; end

        local r1::Float32 = diam_eff * 0.04166667f0   # 1/24
        if htd > 4.5f0
            r1 = r1 + (loht[k] * ((r1 * htd) / (htd - 4.5f0)))
        end
        local r1sq::Float32 = r1 * r1

        for j in 1:9
            # Skip if height range of piece doesn't overlap current size class
            if hiht[k] <= bph[j+1]; continue; end    # BPH(J) in 1-based
            if loht[k] >  bph[j];   continue; end    # BPH(J-1) in 1-based

            local hicut::Float32 = hiht[k]
            if hiht[k] > bph[j]; hicut = bph[j]; end   # BPH(J-1) in 1-based

            local locut::Float32 = loht[k]
            if loht[k] <= bph[j+1]; locut = bph[j+1]; end  # BPH(J)

            if locut == hicut; continue; end

            # Conical taper volume calculation: fraction of total volume in slice
            local r2sq_hi::Float32 = r1 * (1.0f0 - (hicut / htd))
            r2sq_hi *= r2sq_hi
            local p1::Float32 = (r2sq_hi * (htd - hicut)) / (r1sq * htd)

            local r2sq_lo::Float32 = r1 * (1.0f0 - (locut / htd))
            r2sq_lo *= r2sq_lo
            local p2::Float32 = (r2sq_lo * (htd - locut)) / (r1sq * htd)

            local dif::Float32 = max(0.0f0, p2 - p1) * tvoli

            if k == 1
                dif *= dis
            else
                dif *= dih
            end

            local add::Float32 = 0.0f0
            if dif > 1.0f-6
                add = dif * V2T[sp] * _FMCWD_SCNV[k]
                CWD[1, j, k, idcl] += add
                CWDNEW[2, j] += add
            end

            if debug
                @printf(io_units[Int32(JOSTND)],
                        " I=%4d K=%2d LOCUT=%7.3f HICUT=%7.3f DIF=%8.5f ADD=%10.6f TVOLI=%10.6f\n",
                        i_snag, k, locut, hicut, dif, add, tvoli)
            end
        end
    end
end

# CWD1: entry point for fallen snag material → CWD pools
function CWD1(isng::Integer, dih::Real, disin::Real)
    local debug::Bool = false
    debug = DBCHK(false, "FMCWD", Int32(5), ICYC)
    if debug
        @printf(io_units[Int32(JOSTND)], " ENTERING FM-CWD1 CYCLE = %2d\n", ICYC)
        @printf(io_units[Int32(JOSTND)], " ISNG=%d DIH=%.4f DISIN=%.4f\n", isng, dih, disin)
    end

    if (Float32(dih) + Float32(disin)) <= 0.0f0; return; end

    local i::Int = Int(isng)
    local hiht = Float32[HTIS[i], HTIH[i]]
    local loht = Float32[1.0f0, 0.10f0]
    local diam::Float32 = DBHS[i]
    local htd::Float32  = HTDEAD[i]
    local sp::Int32     = SPS[i]

    local tvoli_ref = Ref(Float32(0))
    FMSVL2(sp, diam, htd, Float32(-1.0), tvoli_ref, Int32(0),
           "D", false, false, Int32(JOSTND))
    local tvoli::Float32 = tvoli_ref[]

    if debug
        @printf(io_units[Int32(JOSTND)], " I(CWD1)=%d HTD=%.4f TVOLI=%.4f\n", i, htd, tvoli)
    end

    _fmcwd_process!(i, Float32(dih), Float32(disin), hiht, loht, diam, htd, sp, tvoli, false, debug)
    return nothing
end

# CWD2: entry point for height-reduced snag material (top breakage)
function CWD2(isng::Integer, dih::Real, disin::Real, oldhth::Real, oldhts::Real)
    local debug::Bool = false
    debug = DBCHK(false, "FMCWD", Int32(5), ICYC)
    if debug
        @printf(io_units[Int32(JOSTND)], " ENTERING FM-CWD2 CYCLE = %2d\n", ICYC)
        @printf(io_units[Int32(JOSTND)], " ISNG=%d DIH=%.4f DISIN=%.4f\n", isng, dih, disin)
    end

    if (Float32(dih) + Float32(disin)) <= 0.0f0; return; end

    local i::Int = Int(isng)
    # Broken top piece: height range = [current snag height, old snag height]
    local hiht = Float32[Float32(oldhts), Float32(oldhth)]
    local loht = Float32[HTIS[i], HTIH[i]]
    local diam::Float32 = DBHS[i]
    local htd::Float32  = HTDEAD[i]
    local sp::Int32     = SPS[i]

    local tvoli_ref = Ref(Float32(0))
    FMSVL2(sp, diam, htd, Float32(-1.0), tvoli_ref, Int32(0),
           "D", false, false, Int32(JOSTND))
    local tvoli::Float32 = tvoli_ref[]

    _fmcwd_process!(i, Float32(dih), Float32(disin), hiht, loht, diam, htd, sp, tvoli, false, debug)
    return nothing
end

# CWD3: entry point for harvested trees → CWD (from FMSCUT)
function CWD3(ksp::Integer, d::Real, dih::Real, hth::Real, crwnrto::Integer)
    if Float32(dih) <= 0.0f0; return; end

    local sp::Int32    = Int32(ksp)
    local diam::Float32= Float32(d)
    local htd::Float32 = Float32(hth)
    local dis::Float32 = 0.0f0   # all hard for cut material

    local hiht = Float32[0.0f0, htd]
    local loht = Float32[0.0f0, 0.1f0]

    local tvoli_ref = Ref(Float32(0))
    FMSVL2(sp, diam, htd, Float32(-1.0), tvoli_ref, Int32(crwnrto),
           "D", false, false, Int32(JOSTND))
    local tvoli::Float32 = tvoli_ref[]

    _fmcwd_process!(-1, Float32(dih), dis, hiht, loht, diam, htd, sp, tvoli, true, false)
    return nothing
end
