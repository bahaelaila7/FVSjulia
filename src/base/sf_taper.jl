# sf_taper.f — SF_TAPER: compute taper coefficients from geometric properties (102 lines)
# Step 4 of taper application: given relative heights, compute 12 taper coefficients.
# All arithmetic in double precision per the Fortran IMPLICIT DOUBLE PRECISION declaration.

function SF_TAPER(rhfw::AbstractVector{Float32}, rflw::AbstractVector{Float32},
                  tapcoe::AbstractVector{Float32})
    # Unpack inputs (convert to Float64)
    r1  = Float64(rflw[1])
    r2  = Float64(rflw[2])
    r3  = Float64(rflw[3])
    r4  = Float64(rflw[4])
    r5  = Float64(rflw[5])
    a3  = Float64(rflw[6])

    rhi1    = Float64(rhfw[1])
    rhi2    = Float64(rhfw[2])
    rhc     = Float64(rhfw[3])
    rhlongi = Float64(rhfw[4])

    # Upper segment (Appendix A, Eqns A1–A4)
    k      = 1.0
    yc     = k * (1.0 - rhc)
    c2     = r5 * yc
    c1     = 3.0 * (yc - c2)
    slope  = -(3.0 - r5) * k / 2.0

    # Middle segment (Appendix A, Eqns A6–A15)
    s1     = slope * (rhc - rhi2)
    yi_min = yc - s1 * (1.0 + 2.0*r3) / 3.0
    yi_max = yc - s1 * (5.0 + 4.0*r3) / 9.0
    yi2    = yi_min + r4 * (yi_max - yi_min)
    s0     = r3 * s1

    b1 = (6.0*yc - 6.0*yi2 - 2.0*s0 - 4.0*s1) /
         (-3.0*yc + 3.0*yi2 + 2.0*s0 + s1)
    b2 = s1 * (1.0 - r3) / (0.5 - 1.0/(b1 + 1.0))
    b4 = s0
    b0 = yi2

    slope_rhi = r3 * s1 / (rhc - rhi2)

    # Straight segment at inflection
    yi1 = yi2 - slope_rhi * rhlongi
    if rhlongi > 0.0
        e2 = (yi2 - yi1) / rhlongi
        e1 = yi1 - e2 * rhi1
    else
        e1 = yi2
        e2 = 0.0
    end

    # Lower segment (Appendix A, Eqns A16–A26)
    s3    = -slope_rhi * rhi1
    k2    = s3 / r1
    f_a3  = 1.0/(6.0*a3*a3) + log(1.0 - 1.0/a3) + 1.0/(3.0*(a3-1.0)) + 2.0/(3.0*a3)
    g_a3  = (1.0/(a3-1.0) - 1.0/a3 - 1.0/a3^2 - 1.0/(a3-1.0)^3) / f_a3

    yb_min = yi1 + (2.0*s3 + k2)/3.0 + (s3 - k2)*f_a3 /
             (1.0/(a3-1.0) - 1.0/a3 - 1.0/a3^2 - 1.0/a3^3)
    yb_max = yi1 + (2.0*s3 + k2)/3.0 + (s3 - k2)/g_a3
    yb     = yb_min + r2*(yb_max - yb_min)

    a0 = yi1
    a2 = (yb - yi1 - (2.0*s3 + k2)/3.0) / f_a3
    a1 = (k2 - s3 + a2*(1.0/(a3-1.0) - 1.0/a3 - 1.0/a3^2)) / 3.0
    a4 = s3

    # Store results (convert back to Float32)
    tapcoe[1]  = Float32(a0)
    tapcoe[2]  = Float32(a1)
    tapcoe[3]  = Float32(a2)
    tapcoe[4]  = Float32(a4)
    tapcoe[5]  = Float32(b0)
    tapcoe[6]  = Float32(b1)
    tapcoe[7]  = Float32(b2)
    tapcoe[8]  = Float32(b4)
    tapcoe[9]  = Float32(c1)
    tapcoe[10] = Float32(c2)
    tapcoe[11] = Float32(e1)
    tapcoe[12] = Float32(e2)
    return nothing
end
