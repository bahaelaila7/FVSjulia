# fmcrowe.f — Crown component weight estimator (Jenkins et al. + Loomis equations)
# FMCROWE: returns XV[1..6] = (foliage, 0-.25", 0-1", 0-3", 3-4", 4"+) weights (tons)
# XV in Julia is 1-indexed: XV[1]=foliage (Fortran XV(0)), ..., XV[6]=4"+ (Fortran XV(5))
# Called from: FMCROW

function FMCROWE(spils::Integer, spiyv::Integer, d_in::Real, h_in::Real,
                  ic::Integer, sg::Real, xv::AbstractVector{Float32})
    local debug::Bool = false
    DBCHK(Ref(debug), "FMCROWE", Int32(7), ICYC)
    if debug
        @printf(get(io_units, Int32(JOSTND), stdout), " ENTERING FMCROWE\n")
    end

    local d::Float32 = Float32(d_in)
    local h::Float32 = Float32(h_in)
    local dx::Float32 = d
    local hx::Float32 = h
    local c::Float32  = Float32(ic)
    local mypi::Float32 = 3.14159f0

    for j in 1:6; xv[j] = 0.0f0; end
    local umbtw = zeros(Float32, 4)
    local fol::Float32 = 0.0f0; local ttopw::Float32 = 0.0f0; local lilpce::Float32 = 0.0f0

    if d == 0.0f0 || h == 0.0f0; return nothing; end

    # Jenkins et al. total aboveground biomass
    if d < 1.0f0; d = 1.0f0; end
    local totabv::Float32 = 0.0f0
    local bark::Float32 = 0.0f0; local wood::Float32 = 0.0f0; local branch::Float32 = 0.0f0
    local dcm::Float32 = d * 2.54f0

    let spi = Int(spils)
        if spi in (17, 40, 41, 42, 64, 65, 66)   # aspen/alder/cottonwood/willow
            totabv = exp(-2.2094f0 + 2.3867f0 * log(dcm))
        elseif spi in (18, 19, 24, 43) || spi in (49, 50, 51, 52)  # soft maple/birch
            totabv = exp(-1.9123f0 + 2.3651f0 * log(dcm))
        elseif spi in (15, 16, 20, 21, 22, 23, 25, 29) ||
               spi in (44, 45, 46, 47, 48) || (53 <= spi <= 63) || spi in (67, 68)  # mixed hardwood
            totabv = exp(-2.4800f0 + 2.4835f0 * log(dcm))
        elseif (26 <= spi <= 28) || (30 <= spi <= 39)  # hard maple/oak/hickory/beech
            totabv = exp(-2.0127f0 + 2.4342f0 * log(dcm))
        elseif spi in (10, 11, 13, 14)  # cedar/larch
            totabv = exp(-2.0336f0 + 2.2592f0 * log(dcm))
        elseif spi in (8, 12)   # true fir/hemlock
            totabv = exp(-2.5384f0 + 2.4814f0 * log(dcm))
        elseif spi in (1, 2, 3, 4, 5)  # pine
            totabv = exp(-2.5356f0 + 2.4349f0 * log(dcm))
        elseif spi in (6, 7, 9)  # spruce
            totabv = exp(-2.0773f0 + 2.3323f0 * log(dcm))
        end
        totabv *= 2.2046f0

        # Component proportions
        if spi >= 15   # hardwood
            fol    = exp(-4.0813f0 + 5.8816f0 / dcm)
            bark   = exp(-2.0129f0 - 1.6805f0 / dcm)
            wood   = exp(-0.3065f0 - 5.4240f0 / dcm)
        else           # softwood
            fol    = exp(-2.9584f0 + 4.4766f0 / dcm)
            bark   = exp(-2.0980f0 - 1.1432f0 / dcm)
            wood   = exp(-0.3737f0 - 1.8055f0 / dcm)
        end
        fol    *= totabv; bark *= totabv; wood *= totabv
        branch  = totabv - (fol + bark + wood)
    end

    if dx < 1.0f0
        d = dx
        fol = d * fol; bark = d * bark; wood = d * wood
        branch = d * branch; totabv = d * totabv
    end
    if branch < 0.0f0; branch = 0.0f0; end
    ttopw = branch

    # Small unmerchantable tree bole addition (SN/LS/NE/CS/ON variants)
    local temp::Float32 = 0.0f0
    local vt1::Float32 = 0.0f0; local dobf::Float32 = 0.0f0
    local lmerch::Bool = false
    let spi = Int(spiyv), dbhmin_v = DBHMIN[spiyv]
        if dx < dbhmin_v && (VARACD == "SN" || VARACD == "LS" || VARACD == "NE" ||
                              VARACD == "CS" || VARACD == "ON")
            d = dbhmin_v
            local h2_ref = Ref(h)
            HTDBH(Int32(IFOR), Int32(spiyv), d, h2_ref, Int32(0))
            local h2::Float32 = h2_ref[]
            local vt_ref = Ref(Float32(0))
            local xneg1::Float32 = -1.0f0
            FMSVL2(Int32(spiyv), d, h2, xneg1, vt_ref, Int32(0), " ", false, false, Int32(JOSTND))
            vt1 = 0.0015f0 * dx * dx * hx
            local vt2::Float32 = 0.0015f0 * d * d * h2
            if vt2 > 0.0f0; temp = Float32(sg) * (vt_ref[] / vt2) * vt1 / P2T; end
            ttopw += temp
            d = dx; h = hx
        end
    end

    # Size class proportions
    local p1::Float32 = 0.0f0; local p2::Float32 = 0.0f0; local p3::Float32 = 0.0f0
    local f1::Float32 = 0.0f0; local f2::Float32 = 0.0f0
    local f3::Float32 = 0.0f0; local f4::Float32 = 0.0f0
    let spi = Int(spils)
        if 30 <= spi <= 39   # red oak / oaks and hickories
            p1 = 6.4735f0 * (d^(-1.1313f0)) * (c^(-0.5777f0))
            p2 = 36.8351f0 * (d^(-0.9345f0)) * (c^(-0.7014f0))
            p3 = 28.2916f0 * (d^(-0.8658f0)) * (c^(-0.4084f0))
        elseif 1 <= spi <= 14  # shortleaf pine / conifers
            p1 = 3.525f0 * (d^(-0.778f0)) * (c^(-0.412f0))
            p2 = 5.989f0 * (d^(-0.565f0)) * (c^(-0.346f0))
            p3 = 8.585f0 * (d^(-0.517f0)) * (c^(-0.223f0))
            if d <= 1.5f0; p1 = 0.5f0; p2 = 1.0f0; end
            if d <= 10.5f0 || c <= 35.0f0; p3 = 1.0f0; end
        elseif spi in (18, 19, 26, 27) || (49 <= spi <= 52)  # maple
            f1 = 1.0f0 / (4.6762f0 + 0.1091f0 * d^2.0390f0)
            f2 = 1.0f0 / (3.3212f0 + 0.0777f0 * d^2.0496f0)
            f3 = 1.0f0 / (0.9341f0 + 0.0158f0 * d^2.1627f0)
            f4 = 1.0f0 / (0.8625f0 + 0.0093f0 * d^1.7070f0)
            if d < 1.9f0; f3 = 1.0f0; end
            if d < 4.8f0; f4 = 1.0f0; end
        else   # aspen default
            p1 = 1.856f0 * (d * 2.54f0)^(-0.773f0)
            p2 = 5.317f0 * (d * 2.54f0)^(-0.718f0)
            p3 = 1.793f0 * (d * 2.54f0)^(-0.185f0)
        end
    end

    # Unmerchantable bole tip weight by size class
    dobf = 4.0f0 / BRATIO(Int32(spiyv), d, h)
    if d > dobf && d > DBHMIN[spiyv]
        local htf::Float32 = 4.5f0 + (h - 4.5f0) / d * (d - dobf)
        if (h - htf) > 0.0f0
            temp = (h - htf) * 4.0f0 * 4.0f0 * mypi / 1728.0f0
        else
            temp = 0.0f0
        end
        umbtw[4] = Float32(sg) * temp / P2T
        local dbrk = Float32[0.0f0, 0.25f0, 1.0f0, 3.0f0]
        local angle::Float32 = atan((h - htf) / 2.0f0)
        for j in 1:3
            local tempht::Float32 = dbrk[j+1] / 2.0f0 * tan(angle)
            temp = tempht * dbrk[j+1]^2 * mypi / 1728.0f0
            umbtw[j] = Float32(sg) * temp / P2T
        end
        # LILPCE for SN/LS/NE/CS/ON
        if VARACD in ("SN", "LS", "NE", "CS", "ON")
            local dib::Float32 = 4.0f0 * BRATIO(Int32(spiyv), d, h)
            local htlp::Float32 = 4.5f0 + (h - 4.5f0) / d * (d - 4.0f0)
            if (htlp - htf) > 0.0f0
                lilpce = mypi * (htlp - htf) / 1728.0f0 * (16.0f0 + 4.0f0 * dib + dib^2)
            else
                lilpce = 0.0f0
            end
            lilpce *= Float32(sg) / P2T
            if lilpce < 0.0f0; lilpce = 0.0f0; end
            umbtw[4] -= lilpce
        end
    elseif h > 4.5f0
        # Small/unmerchantable tree: whole stem
        temp = (h - 4.5f0) * d^2 * mypi / 1728.0f0
        umbtw[4] = Float32(sg) * temp / P2T
        local dbrk2 = Float32[0.0f0, 0.25f0, 1.0f0, 3.0f0]
        local angle2::Float32 = atan((h - 4.5f0) / (d / 2.0f0))
        for j in 1:3
            if j == 1 || (j > 1 && d > dbrk2[j])
                local tempd::Float32 = min(dbrk2[j+1], d)
                local tempht2::Float32 = tempd / 2.0f0 * tan(angle2)
                temp = tempht2 * tempd^2 * mypi / 1728.0f0
                umbtw[j] = Float32(sg) * temp / P2T
            end
        end
        # Add stem below 4.5 ft (cylinder approximation)
        temp = mypi * d^2 / 4.0f0 / 144.0f0 * min(4.5f0, h)
        local k::Int = d <= 0.25f0 ? 1 : d <= 1.0f0 ? 2 : d <= 3.0f0 ? 3 : 4
        for j in k:4; umbtw[j] += Float32(sg) * temp / P2T; end
    end

    # Clamp all proportions
    p1 = clamp(p1, 0.0f0, 1.0f0); p2 = clamp(p2, 0.0f0, 1.0f0); p3 = clamp(p3, 0.0f0, 1.0f0)
    if p2 < p1; p2 = p1; end; if p3 < p2; p3 = p2; end
    f1 = clamp(f1, 0.0f0, 1.0f0); f2 = clamp(f2, 0.0f0, 1.0f0)
    f3 = clamp(f3, 0.0f0, 1.0f0); f4 = clamp(f4, 0.0f0, 1.0f0)
    if f2 < f1; f2 = f1; end; if f3 < f2; f3 = f2; end; if f4 < f3; f4 = f3; end
    if ttopw < 0.0f0; ttopw = 0.0f0; end
    if lilpce < 0.0f0; lilpce = 0.0f0; end
    if fol < 0.0f0; fol = 0.0f0; end
    for j in 1:4; if umbtw[j] < 0.0f0; umbtw[j] = 0.0f0; end; end
    if umbtw[2] < umbtw[1]; umbtw[2] = umbtw[1]; end
    if umbtw[3] < umbtw[2]; umbtw[3] = umbtw[2]; end
    if umbtw[4] < umbtw[3]; umbtw[4] = umbtw[3]; end

    # Assign crown components to size classes
    let spi = Int(spils)
        if spi in (18, 19, 26, 27) || (49 <= spi <= 52)  # maple
            if ttopw < umbtw[4]; ttopw = umbtw[4]; end
            ttopw += fol
            xv[1] = fol
            xv[2] = (ttopw - umbtw[4]) * (f2 - f1) + umbtw[1]
            xv[3] = (ttopw - umbtw[4]) * (f3 - f2) + (umbtw[2] - umbtw[1])
            xv[4] = (ttopw - umbtw[4]) * (f4 - f3) + (umbtw[3] - umbtw[2])
            xv[5] = (ttopw - umbtw[4]) * (1.0f0 - f4) + (umbtw[4] - umbtw[3])
            xv[6] = 0.0f0
        elseif 1 <= spi <= 14  # shortleaf pine / conifers
            if ttopw < umbtw[4]; ttopw = umbtw[4]; end
            xv[1] = fol
            xv[2] = (ttopw - umbtw[4]) * p1 + umbtw[1]
            xv[3] = (ttopw - umbtw[4]) * (p2 - p1) + (umbtw[2] - umbtw[1])
            xv[4] = (ttopw - umbtw[4]) * (p3 - p2) + (umbtw[3] - umbtw[2])
            xv[5] = (ttopw - umbtw[4]) * (1.0f0 - p3) + (umbtw[4] - umbtw[3])
            xv[6] = 0.0f0
        elseif 30 <= spi <= 39  # red oak
            if ttopw < (umbtw[4] - umbtw[2]); ttopw = umbtw[4] - umbtw[2]; end
            xv[1] = fol
            xv[2] = (ttopw - umbtw[4] + umbtw[2]) * p1
            xv[3] = (ttopw - umbtw[4] + umbtw[2]) * (p2 - p1)
            xv[4] = (ttopw - umbtw[4] + umbtw[2]) * (p3 - p2) + (umbtw[3] - umbtw[2])
            xv[5] = (ttopw - umbtw[4] + umbtw[2]) * (1.0f0 - p3) + (umbtw[4] - umbtw[3])
            xv[6] = 0.0f0
        else  # aspen default
            if ttopw < (umbtw[4] - umbtw[1]); ttopw = umbtw[4] - umbtw[1]; end
            xv[1] = fol
            xv[2] = (ttopw - umbtw[4] + umbtw[1]) * p1
            xv[3] = (ttopw - umbtw[4] + umbtw[1]) * (p2 - p1) + (umbtw[2] - umbtw[1])
            xv[4] = (ttopw - umbtw[4] + umbtw[1]) * (p3 - p2) + (umbtw[3] - umbtw[2])
            xv[5] = (ttopw - umbtw[4] + umbtw[1]) * (1.0f0 - p3) + (umbtw[4] - umbtw[3])
            xv[6] = 0.0f0
        end
    end

    # Add LILPCE back to the large-end class for merchantable trees
    if d > dobf && d > DBHMIN[spiyv]
        xv[5] += lilpce
    end

    return nothing
end
