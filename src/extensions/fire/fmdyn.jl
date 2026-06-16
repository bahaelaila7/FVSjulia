# fmdyn.f + fmchkfwt.f — Dynamic fuel model weight interpolation
# FMCHKFWT: guard against exceeding MXFMOD fuel models
# FMDYN: finds weighted combination of fuel models closest to SM/LG point
# Called from: FMCFMD

function FMCHKFWT(i2::Integer)::Bool
    if i2 <= Int(MXFMOD)
        return true
    else
        @printf(get(io_units, Int32(JOSTND), stdout),
            "\n *** FFE MODEL WARNING: TOO MANY FIRE MODELS SPECIFIED; MAXIMUM= %2d CYCLE= %4d\n",
            MXFMOD, ICYC)
        RCDSET(Int32(2), true)
        return false
    end
end

function FMDYN(sm::Real, lg::Real,
               ityp_arr::AbstractVector{<:Integer},
               xpts::AbstractMatrix{<:Real},
               eqwt_arr::AbstractVector{<:Real},
               iptr_arr::AbstractVector{<:Integer},
               iclss::Integer,
               ldyn::Bool,
               fmd_ref::Ref{Int32})
    debug = DBCHK("FMDYN", 5, ICYC)

    local mxf::Int = Int(MXFMOD)
    local nc::Int  = Int(iclss)

    local fmod2 = zeros(Int32, mxf)
    local fwt2  = zeros(Float32, mxf)
    local eqmod = zeros(Int32, nc)
    local lok   = zeros(Bool, nc)
    local xd    = zeros(Float32, nc)
    local yd    = zeros(Float32, nc)
    local nbr   = zeros(Int32, 4)
    local wt    = zeros(Float32, 4)

    for i in 1:mxf
        FMOD[i] = Int32(0)
        FWT[i]  = 0.0f0
        fmod2[i] = Int32(0)
        fwt2[i]  = 0.0f0
    end
    for i in 1:nc; eqmod[i] = 0; lok[i] = false; end

    local pt1::Float32 = Float32(sm)
    local pt2::Float32 = Float32(lg)

    if pt1 < 0.0f0 || pt2 < 0.0f0; @goto label_999; end

    # Set LOK vector
    for i in 1:nc
        if eqwt_arr[i] > 0.0f0; lok[i] = true; end
    end

    # Unset lines with invalid coefficients
    for i in 1:nc
        if lok[i]
            j = ityp_arr[i]
            if (j == 0 && (xpts[i,1] == 0.0 || xpts[i,2] == 0.0)) ||
               (j == -1 && xpts[i,2] == 0.0) ||
               (j ==  1 && xpts[i,1] == 0.0)
                lok[i] = false
                eqwt_arr[i] = 0.0f0
            end
        end
    end

    # Build EQMOD (collinearity grouping)
    for i in 1:nc
        if lok[i]
            for j in i:nc
                if eqmod[j] == 0 && lok[j] &&
                   xpts[i,1] == xpts[j,1] && xpts[i,2] == xpts[j,2]
                    eqmod[j] = i
                end
            end
        end
    end

    # Rescale colinear EQWT to sum to 1.0
    for i in 1:nc
        if lok[i]
            local xwt::Float32 = 0.0f0
            for j in i:nc
                if lok[j] && eqmod[j] == i; xwt += eqwt_arr[j]; end
            end
            if xwt > 1.0f-6
                for j in i:nc
                    if lok[j] && eqmod[j] == i; eqwt_arr[j] /= xwt; end
                end
            end
        end
    end

    # Compute signed distances XD/YD
    for i in 1:nc
        if !lok[i]; continue; end
        j = ityp_arr[i]
        xd[i] = 0.0f0; yd[i] = 0.0f0
        if j == 0
            local m1::Float32 = Float32(xpts[i,2]) / (-Float32(xpts[i,1]))
            local b1::Float32 = Float32(xpts[i,2])
            local xp::Float32 = (pt2 - b1) / m1
            local yp::Float32 = m1 * pt1 + b1
            xd[i] = xp - pt1
            yd[i] = yp - pt2
        elseif j == 1
            xd[i] = Float32(xpts[i,1]) - pt1
        elseif j == -1
            yd[i] = Float32(xpts[i,2]) - pt2
        end
    end

    # Find closest neighbors
    local prv = Float32[-9.99e30, 9.99e30, -9.99e30, 9.99e30]
    for i in 1:nc
        if !lok[i]; continue; end
        j = ityp_arr[i]
        if j == 0 || j == 1
            if xd[i] < 0.0f0 && xd[i] > prv[1]; prv[1] = xd[i]; nbr[1] = i; end
            if xd[i] >= 0.0f0 && xd[i] < prv[2]; prv[2] = xd[i]; nbr[2] = i; end
        end
        if j == 0 || j == -1
            if yd[i] < 0.0f0 && yd[i] > prv[3]; prv[3] = yd[i]; nbr[3] = i; end
            if yd[i] >= 0.0f0 && yd[i] < prv[4]; prv[4] = yd[i]; nbr[4] = i; end
        end
    end

    # Compute distances to each neighbor line
    for k in 1:4
        local ii = Int(nbr[k])
        if ii == 0 || !lok[ii]; continue; end
        j = ityp_arr[ii]
        if j == 0
            local m1b::Float32 = Float32(xpts[ii,2]) / (-Float32(xpts[ii,1]))
            local b1b::Float32 = Float32(xpts[ii,2])
            local m2::Float32  = -(1.0f0 / m1b)
            local b2::Float32  = pt2 - m2 * pt1
            local npt1::Float32 = (b2 - b1b) / (m1b - m2)
            local npt2::Float32 = m2 * npt1 + b2
            wt[k] = sqrt((pt2 - npt2)^2 + (pt1 - npt1)^2)
        elseif j == 1
            wt[k] = abs(Float32(xpts[ii,1]) - pt1)
        elseif j == -1
            wt[k] = abs(Float32(xpts[ii,2]) - pt2)
        end
    end

    # Merge duplicate NBR indices into FMOD/FWT
    local k2::Int = 0
    for i in 1:4
        if nbr[i] == 0; continue; end
        k2 += 1
        local k::Int = k2
        for j in 1:i
            if FMOD[j] == nbr[i]; k = j; @goto label_42; end
        end
        if FMCHKFWT(k); FMOD[k] = nbr[i]; end
        @label label_42
        if FMCHKFWT(k); FWT[k] += wt[i]; end
    end

    # Reweight by inverse distance
    local xwt2::Float32 = 0.0f0
    for i in 1:mxf
        if FMOD[i] == 0; continue; end
        FWT[i] = 1.0f0 / (FWT[i] + 1.0f-6)
        xwt2 += FWT[i]
    end
    for i in 1:mxf
        if FMOD[i] == 0; continue; end
        FWT[i] /= xwt2
    end

    # Compact non-zero entries to front
    local kk::Int = 0
    for i in 1:mxf
        if FMOD[i] == 0; continue; end
        kk += 1
        if i != kk && FMCHKFWT(kk)
            FMOD[kk] = FMOD[i]; FWT[kk] = FWT[i]
            FMOD[i] = Int32(0);  FWT[i]  = 0.0f0
        end
    end

    # Distribute weight among colinear models
    for i in 1:mxf; fmod2[i] = 0; fwt2[i] = 0.0f0; end
    kk = 1
    for i in 1:mxf
        if FMOD[i] == 0; continue; end
        local ii2::Int = Int(FMOD[i])
        local xwt3::Float32 = FWT[i]
        if eqmod[ii2] == 0 && FMCHKFWT(kk)
            fwt2[kk] = FWT[i]; fmod2[kk] = FMOD[i]; kk += 1
        else
            for jj in 1:nc
                if eqmod[jj] == eqmod[ii2] && eqwt_arr[jj] > 0.0f0
                    if FMCHKFWT(kk)
                        fwt2[kk] += eqwt_arr[jj] * xwt3
                        fmod2[kk] = jj
                        kk += 1
                    end
                end
            end
        end
    end

    @label label_999
    # Final merge of fmod2/fwt2 into FMOD/FWT, resolving duplicates
    for i in 1:mxf; FMOD[i] = Int32(0); FWT[i] = 0.0f0; end
    k2 = 0
    for i in 1:mxf
        if fmod2[i] == 0; continue; end
        k2 += 1
        local kfin::Int = k2
        for j in 1:i
            if FMOD[j] == fmod2[i]; kfin = j; @goto label_72; end
        end
        if FMCHKFWT(kfin); FMOD[kfin] = fmod2[i]; end
        @label label_72
        if FMCHKFWT(kfin); FWT[kfin] += fwt2[i]; end
    end

    # Remap FMOD indices through IPTR
    for i in 1:mxf
        if FMOD[i] != 0; FMOD[i] = Int32(iptr_arr[Int(FMOD[i])]); end
    end

    # Sort by descending weight (RDPSRT descending)
    local indx_s = sortperm(collect(FWT[1:mxf]), rev=true)
    for i in 1:mxf; fmod2[i] = FMOD[indx_s[i]]; fwt2[i] = FWT[indx_s[i]]; end
    for i in 1:mxf; FMOD[i] = fmod2[i]; FWT[i] = fwt2[i]; end

    # Truncate to 4 models and reweight
    local xwt4::Float32 = 0.0f0
    for i in 1:4; xwt4 += FWT[i]; end
    if xwt4 > 1.0f-6
        for i in 1:4; FWT[i] /= xwt4; end
        for i in 5:mxf; FMOD[i] = Int32(0); FWT[i] = 0.0f0; end
    end

    # Select non-dynamic dominant model
    fmd_ref[] = Int32(-1)
    if FWT[1] > 1.0f-6; fmd_ref[] = FMOD[1]; end
    if fmd_ref[] < 0
        FMOD[1] = Int32(8); FWT[1] = 1.0f0
        global NFMODS = Int32(1)
        for i in 2:mxf; FMOD[i] = Int32(0); FWT[i] = 0.0f0; end
        RCDSET(Int32(2), true)
    end

    # Count active models
    global NFMODS = Int32(mxf)
    for i in 1:mxf
        if FWT[i] <= 1.0f-6
            global NFMODS = Int32(i - 1)
            break
        end
    end
    global NFMODS = Int32(min(Int(NFMODS), 4))

    # If static requested, collapse to single dominant model
    if !ldyn
        FMOD[1] = fmd_ref[]
        FWT[1]  = 1.0f0
        global NFMODS = Int32(1)
        for i in 2:mxf; FMOD[i] = Int32(0); FWT[i] = 0.0f0; end
    end

    if debug
        @printf(get(io_units, Int32(JOSTND), stdout),
            " FMDYN, FMD=%4d FMOD=%4d%4d%4d%4d%4d FWT=%7.2f%7.2f%7.2f%7.2f%7.2f\n",
            fmd_ref[], FMOD[1], FMOD[2], FMOD[3], FMOD[4], FMOD[5],
            FWT[1], FWT[2], FWT[3], FWT[4], FWT[5])
    end
    return nothing
end
