# svutils.jl — SVS (Stand Visualization System) utility subroutines
# svrann.f: random number generator for SVS placement (SVRANN/SVRSED/SVRANNGET/SVRANNPUT)
# svcrol.f: circle overlap test
# svntr.f:  TPA → number of tree records
# svhabt.f: habitat modifier (always 1.0 for base)
# svgtpt.f: get random point in region (rectangular or circular plot)
# svonln.f: check if point lies on a line interval
# svdfln.f: define line Y=A+BX from two points

# SVRANN: Linear-congruential RNG for SVS (Park-Miller, modulus 2^31-1)
function SVRANN(sel_ref::Ref{Float32})
    global SVS0, SVS1
    SVS1 = mod(16807.0 * SVS0, 2147483647.0)
    sel_ref[] = Float32(SVS1 / 2147483648.0)
    SVS0 = SVS1
    return nothing
end
function SVRANN()
    global SVS0, SVS1
    SVS1 = mod(16807.0 * SVS0, 2147483647.0)
    sel = Float32(SVS1 / 2147483648.0)
    SVS0 = SVS1
    return sel
end

function SVRSED(lset::Bool, seed_ref::Ref{Float32})
    global SVS0, SVSS
    if !lset
        seed_ref[] = Float32(SVSS)
        SVS0 = Float64(SVSS)
        return nothing
    end
    s = seed_ref[]
    if mod(s, 2.0f0) == 0.0f0; s += 1.0f0; end
    seed_ref[] = s
    SVSS = s
    SVS0 = Float64(s)
    return nothing
end

function SVRANNGET(passs0_ref::Ref{Float64})
    passs0_ref[] = SVS0
    return nothing
end

function SVRANNPUT(passs0_ref::Ref{Float64})
    global SVS0 = passs0_ref[]
    return nothing
end

# SVCROL: return KODE=1 if two circles overlap, 0 if not
function SVCROL(x1::Real, y1::Real, r1::Real, x2::Real, y2::Real, r2::Real,
                kode_ref::Ref{Int32})
    d2 = (x2 - x1)^2 + (y2 - y1)^2
    rsum = Float32(r1) + Float32(r2)
    kode_ref[] = rsum * rsum > d2 ? Int32(1) : Int32(0)
    return nothing
end

# SVNTR: given trees-per-acre XP, return number of tree records NP (stochastic)
function SVNTR(xp::Real, np_ref::Ref{Int32})
    xx = Float32(xp)
    np = Int32(0)
    if xx > 1.0f0
        np = Int32(floor(xx))
        xx = xx - Float32(np)
    end
    if xx > 0.00001f0
        x = SVRANN()
        if x < xx; np += Int32(1); end
    end
    np_ref[] = np
    return nothing
end

# SVHABT: return habitat modifier XMOD=1.0 (base variant — all habitat types equal)
function SVHABT(xmod_ref::Ref{Float32})
    xmod_ref[] = 1.0f0
    return nothing
end

# SVGTPT: get a random point in rectangular or circular region
# IPGLEM<2 → rectangular (X1R1..X2R2, Y1A1..Y2A2)
# IPGLEM>=2 → circular (X1R1..X2R2 = R min/max, Y1A1..Y2A2 = angle min/max)
function SVGTPT(ipglem::Integer, x1r1::Real, x2r2::Real, y1a1::Real, y2a2::Real,
                x_ref::Ref{Float32}, y_ref::Ref{Float32}, imetric::Integer)
    if ipglem < 2
        x_ref[] = Float32(x1r1) + (Float32(x2r2) - Float32(x1r1)) * SVRANN()
        y_ref[] = Float32(y1a1) + (Float32(y2a2) - Float32(y1a1)) * SVRANN()
    else
        a = Float32(y1a1) + (Float32(y2a2) - Float32(y1a1)) * SVRANN()
        r_rand = SVRANN()
        r1f = Float32(x1r1); r2f = Float32(x2r2)
        r = sqrt(r1f * r1f + r_rand * (r2f * r2f - r1f * r1f))
        center = imetric == 0 ? 117.7522f0 : 56.42f0
        x_ref[] = cos(a) * r + center
        y_ref[] = sin(a) * r + center
    end
    return nothing
end

# SVONLN: return KODE=1 if (X,Y) lies within interval [(X1,Y1),(X2,Y2)], else KODE=0
# Assumes (X,Y) is already on the line; only checks the interval bounds.
function SVONLN(x::Real, y::Real, x1::Real, y1::Real, x2::Real, y2::Real,
                kode_ref::Ref{Int32})
    kode_ref[] = Int32(0)
    xf, yf = Float32(x), Float32(y)
    x1f, x2f = Float32(x1), Float32(x2)
    y1f, y2f = Float32(y1), Float32(y2)
    if x1f < x2f
        !(x1f <= xf <= x2f) && return nothing
    else
        !(x2f <= xf <= x1f) && return nothing
    end
    if y1f < y2f
        !(y1f <= yf <= y2f) && return nothing
    else
        !(y2f <= yf <= y1f) && return nothing
    end
    kode_ref[] = Int32(1)
    return nothing
end

# SVDFLN: compute slope (B) and intercept (A) of line Y=A+BX through (X1,Y1),(X2,Y2)
# KODE=0 normal; KODE=1 infinite slope (X1==X2)
function SVDFLN(x1::Real, y1::Real, x2::Real, y2::Real,
                a_ref::Ref{Float32}, b_ref::Ref{Float32}, kode_ref::Ref{Int32})
    a_ref[] = 0.0f0
    b_ref[] = 0.0f0
    kode_ref[] = Int32(0)
    if abs(Float32(y1) - Float32(y2)) < 1.0f-6
        a_ref[] = Float32(y1)
        return nothing
    end
    if abs(Float32(x1) - Float32(x2)) < 1.0f-6
        kode_ref[] = Int32(1)
        return nothing
    end
    b = (Float32(y2) - Float32(y1)) / (Float32(x2) - Float32(x1))
    b_ref[] = b
    a_ref[] = Float32(y1) - b * Float32(x1)
    return nothing
end

# SVLCOL: circle/line overlap test
# Returns KODE=1 if circle (center X,Y, radius R) overlaps line segment (X1,Y1)-(X2,Y2)
function SVLCOL(x::Real, y::Real, r::Real, x1::Real, y1::Real, x2::Real, y2::Real,
                kode_ref::Ref{Int32})
    a1_ref = Ref(0.0f0); b1_ref = Ref(0.0f0); k_ref = Ref(Int32(0))
    SVDFLN(x1, y1, x2, y2, a1_ref, b1_ref, k_ref)
    if k_ref[] == Int32(1)
        kode_ref[] = abs(Float32(x1) - Float32(x)) < Float32(r) ? Int32(1) : Int32(0)
    elseif abs(b1_ref[]) <= 1.0f-6
        kode_ref[] = abs(Float32(y1) - Float32(y)) < Float32(r) ? Int32(1) : Int32(0)
    else
        b = -1.0f0 / b1_ref[]
        a = Float32(y) - b * Float32(x)
        xs = (a - a1_ref[]) / (b1_ref[] - b)
        ys = a + b * xs
        kode_ref[] = ((Float32(x) - xs)^2 + (Float32(y) - ys)^2 < Float32(r)^2) ? Int32(1) : Int32(0)
    end
    return nothing
end

# SVLSOL: find overlap point of two collinear 1-D segments [XJ1,XJ2] and [XK1,XK2]
# KODE=1 if they overlap, XS = overlap point; KODE=0 if not
function SVLSOL(xj1::Real, xj2::Real, xk1::Real, xk2::Real,
                xs_ref::Ref{Float32}, kode_ref::Ref{Float32})
    kode_ref[] = 1.0f0
    j1f, j2f, k1f, k2f = Float32(xj1), Float32(xj2), Float32(xk1), Float32(xk2)
    if abs(j2f - j1f) > abs(k2f - k1f)
        if j1f < j2f
            xs_ref[] = k1f; j1f <= k1f <= j2f && return nothing
            xs_ref[] = k2f; j1f <= k2f <= j2f && return nothing
        else
            xs_ref[] = k1f; j2f <= k1f <= j1f && return nothing
            xs_ref[] = k2f; j2f <= k2f <= j1f && return nothing
        end
    else
        if k1f < k2f
            xs_ref[] = j1f; k1f <= j1f <= k2f && return nothing
            xs_ref[] = j2f; k1f <= j2f <= k2f && return nothing
        else
            xs_ref[] = j1f; k2f <= j1f <= k1f && return nothing
            xs_ref[] = j2f; k2f <= j2f <= k1f && return nothing
        end
    end
    xs_ref[] = 0.0f0
    kode_ref[] = 0.0f0
    return nothing
end

# SVLNOL: find intersection of two line segments; KODE=1 if they cross, XS,YS = crossing point
function SVLNOL(xj1::Real, yj1::Real, xj2::Real, yj2::Real,
                xk1::Real, yk1::Real, xk2::Real, yk2::Real,
                xs_ref::Ref{Float32}, ys_ref::Ref{Float32}, kode_ref::Ref{Int32})
    xs_ref[] = 0.0f0; ys_ref[] = 0.0f0; kode_ref[] = Int32(0)
    aj_ref = Ref(0.0f0); bj_ref = Ref(0.0f0); kj_ref = Ref(Int32(0))
    ak_ref = Ref(0.0f0); bk_ref = Ref(0.0f0); kk_ref = Ref(Int32(0))
    SVDFLN(xj1, yj1, xj2, yj2, aj_ref, bj_ref, kj_ref)
    SVDFLN(xk1, yk1, xk2, yk2, ak_ref, bk_ref, kk_ref)
    xs = 0.0f0; ys = 0.0f0
    if kj_ref[] == Int32(1) && kk_ref[] == Int32(1)
        abs(Float32(xj1) - Float32(xk1)) > 1.0f-6 && return nothing
        ys_dummy = Ref(0.0f0); kd = Ref(0.0f0)
        SVLSOL(yj1, yj2, yk1, yk2, ys_dummy, kd)
        xs_ref[] = Float32(xj1); ys_ref[] = ys_dummy[]; kode_ref[] = Int32(round(kd[]))
        return nothing
    elseif kj_ref[] == Int32(1)
        xs = Float32(xj1); ys = ak_ref[] + bk_ref[] * xs
    elseif kk_ref[] == Int32(1)
        xs = Float32(xk1); ys = aj_ref[] + bj_ref[] * xs
    elseif abs(bj_ref[] - bk_ref[]) < 1.0f-6
        abs(aj_ref[] - ak_ref[]) > 1.0f-6 && return nothing
        xs_dummy = Ref(0.0f0); kd = Ref(0.0f0)
        SVLSOL(xj1, xj2, xk1, xk2, xs_dummy, kd)
        xs_ref[] = xs_dummy[]; kode_ref[] = Int32(round(kd[]))
        kode_ref[] == Int32(1) && (ys_ref[] = aj_ref[] + bj_ref[] * xs_ref[])
        return nothing
    else
        xs = (aj_ref[] - ak_ref[]) / (bk_ref[] - bj_ref[])
        ys = aj_ref[] + bj_ref[] * xs
    end
    kj_tmp = Ref(Int32(0))
    SVONLN(xs, ys, xj1, yj1, xj2, yj2, kj_tmp)
    if kj_tmp[] == Int32(1)
        kk_tmp = Ref(Int32(0))
        SVONLN(xs, ys, xk1, yk1, xk2, yk2, kk_tmp)
        if kk_tmp[] == Int32(1)
            xs_ref[] = xs; ys_ref[] = ys; kode_ref[] = Int32(1)
            return nothing
        end
    end
    return nothing
end

# SVOBOL: overlap test for two objects (J,K) of type 1=circle or 2=line
function SVOBOL(j::Integer, xj1::Real, yj1::Real, xj2::Real, yj2::Real,
                k::Integer, xk1::Real, yk1::Real, xk2::Real, yk2::Real,
                xs_ref::Ref{Float32}, ys_ref::Ref{Float32}, kode_ref::Ref{Int32})
    xs_ref[] = 0.0f0; ys_ref[] = 0.0f0
    if j == 1 && k == 1
        SVCROL(xj1, yj1, xj2, xk1, yk1, xk2, kode_ref)
    elseif j == 1 && k == 2
        SVLCOL(xj1, yj1, xj2, xk1, yk1, xk2, yk2, kode_ref)
    elseif j == 2 && k == 1
        SVLCOL(xk1, yk1, xk2, xj1, yj1, xj2, yj2, kode_ref)
    elseif j == 2 && k == 2
        SVLNOL(xj1, yj1, xj2, yj2, xk1, yk1, xk2, yk2, xs_ref, ys_ref, kode_ref)
    else
        kode_ref[] = Int32(0)
    end
    return nothing
end

# FVSOLDSEC: cubic volume for second-growth trees (D>=4, H>=18 up to D<=9, H<40)
# Volume equation from sn/base volume library (fvsoldsec.f, 35 lines)
function FVSOLDSEC(ispc::Integer, vn_ref::Ref{Float32}, d::Real, h::Real)
    vn = -5.577f0 + 1.9067f0 * log(Float32(d)) + 0.9416f0 * log(Float32(h))
    vn_ref[] = vn > 0.0f0 ? exp(vn) : 0.0f0
    return nothing
end

# FVSOLDFST: cubic volume for first-growth/small trees (D<4 or H<18)
# Volume equation from sn/base volume library (fvsoldfst.f, 35 lines)
function FVSOLDFST(ispc::Integer, vn_ref::Ref{Float32}, d::Real, h::Real)
    hf = Float32(h); df = Float32(d)
    if hf <= 4.5f0
        vn_ref[] = 0.0f0
        return nothing
    end
    if hf <= 18.0f0
        t1 = ((hf - 0.9f0) * (hf - 0.9f0)) / ((hf - 4.5f0) * (hf - 4.5f0))
        t2 = t1 * (hf - 0.9f0) / (hf - 4.5f0)
        form = 0.406098f0 * t1 - 0.0762998f0 * df * t2 + 0.00262615f0 * df * hf * t2
    else
        form = 0.480961f0 + 42.46542f0 / (hf * hf) - 10.99643f0 * df / (hf * hf) -
               0.107809f0 * df / hf - 0.00409083f0 * df
    end
    vn = 0.005454154f0 * form * df * df * hf
    vn_ref[] = max(vn, 0.0f0)
    return nothing
end
