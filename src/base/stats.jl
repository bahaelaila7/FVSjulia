# stats.jl — STATS: compute and print cruise statistics among sample plots
# Translated from: stats.f (463 lines)
#
# Called from FVS cycle-0. Computes mean/SD/CI for TPA/BA/CF/BF/biomass/carbon.
# Calls TVALUE for Student's t and DBSSTATS for database output.

function TVALUE(ndf::Integer, alpha::Real, t_ref::Ref{Float32}, ierr_ref::Ref{Int32})
    # Hill (1970) ACM Algorithm 396: Student's t quantiles.
    halfpi = Float32(1.5707963268)
    t_ref[]    = Float32(0)
    ierr_ref[] = Int32(0)
    n = Int(ndf); p = Float32(alpha)
    if n < 1 || p <= Float32(0) || p >= Float32(1)
        ierr_ref[] = Int32(1)
        return nothing
    end
    if n == 1
        t_ref[] = cos(p * halfpi) / sin(p * halfpi)
        return nothing
    end
    if n == 2
        t_ref[] = sqrt(Float32(2) / (p * (Float32(2) - p)) - Float32(2))
        return nothing
    end
    xn = Float32(n)
    a  = Float32(1) / (xn - Float32(0.5))
    b  = Float32(48) / (a * a)
    c  = ((Float32(20700) * a / b - Float32(98)) * a - Float32(16)) * a + Float32(96.36)
    d  = ((Float32(94.5) / (b + c) - Float32(3)) / b + Float32(1)) *
         sqrt(a * halfpi) * xn
    x  = d * p
    y  = x^(Float32(2) / xn)
    if y > a + Float32(0.05)
        q  = p * Float32(0.5)
        qt = sqrt(log(Float32(1) / (q * q)))
        x  = -qt + (((Float32(0.802853) + qt * Float32(0.010328)) * qt +
              Float32(2.515517)) /
             (((Float32(0.189269) + qt * Float32(0.001308)) * qt +
              Float32(1.432788)) * qt + Float32(1)))
        y  = x * x
        if n < 5; c = c + Float32(0.3) * (xn - Float32(4.5)) * (x + Float32(0.6)); end
        c  = (((Float32(0.05) * d * x - Float32(5)) * x - Float32(7)) * x -
              Float32(2)) * x + b + c
        y  = (((((Float32(0.4) * y + Float32(6.3)) * y + Float32(36)) * y +
              Float32(94.5)) / c - y - Float32(3)) / b + Float32(1)) * x
        y  = a * y * y
        if y <= Float32(0.002)
            y = Float32(0.5) * y * y + y
        else
            y = exp(y) - Float32(1)
        end
    else
        y = ((Float32(1) / (((xn + Float32(6)) / (xn * y) - Float32(0.089) * d -
            Float32(0.822)) * (xn + Float32(2)) * Float32(3)) +
            Float32(0.5) / (xn + Float32(4))) * y - Float32(1)) *
            (xn + Float32(1)) / (xn + Float32(2)) + Float32(1) / y
    end
    t_ref[] = sqrt(xn * y)
    return nothing
end

# DBSSTATS — implemented in extensions/dbs/dbsqlite.jl (writes FVS_Stats_Species / FVS_Stats_Stand)

function STATS()
    if !LSTATS || ITRN == 0; return nothing; end

    io = io_units[Int32(JOSTND)]

    # Local accumulation arrays
    tottr   = zeros(Float32, MAXSP);  totba  = zeros(Float32, MAXSP)
    totbf   = zeros(Float32, MAXSP);  totcf  = zeros(Float32, MAXSP)
    totbio  = zeros(Float32, MAXSP);  totcarb= zeros(Float32, MAXSP)
    iflg    = zeros(Int32,   MAXSP)
    itpa    = zeros(Float32, MAXSP);  iba   = zeros(Float32, MAXSP)
    ibf     = zeros(Float32, MAXSP);  icf   = zeros(Float32, MAXSP)
    ibio    = zeros(Float32, MAXSP);  icarb = zeros(Float32, MAXSP)
    sp_arr  = fill("    ", MAXSP);    speccd = fill("    ", MAXSP)
    tpa_a   = zeros(Float32, MAXSP);  barea  = zeros(Float32, MAXSP)
    bfvol   = zeros(Float32, MAXSP);  cfvol  = zeros(Float32, MAXSP)
    agbio   = zeros(Float32, MAXSP);  agcarb = zeros(Float32, MAXSP)

    npts = Int(IPTINV)
    sumt   = zeros(Float32, MAXPLT);  sumba  = zeros(Float32, MAXPLT)
    sumbf  = zeros(Float32, MAXPLT);  sumcf  = zeros(Float32, MAXPLT)
    sumbio = zeros(Float32, MAXPLT);  sumcarb= zeros(Float32, MAXPLT)
    idist  = zeros(Float32, 8, 6)
    siglevel = Float32(0)
    rows   = 0
    iyear  = 0

    # Accumulate per-tree sums
    for i in 1:Int(ITRN)
        ispc = Int(ISP[i]); j = Int(ITRE[i])
        p    = PROB[i]
        tba  = DBH[i]^2 * p * Float32(0.005454154)
        tbf  = BFV[i] * p
        tcf  = CFV[i] * p
        tbiomass = (ABVGRD_BIO[i] * p) / Float32(2000)
        tcarb_v  = (ABVGRD_CARB[i] * p) / Float32(2000)
        tottr[ispc]  += p;   totba[ispc]  += tba
        totcf[ispc]  += tcf; totbf[ispc]  += tbf
        totbio[ispc] += tbiomass; totcarb[ispc] += tcarb_v
        iflg[ispc] = Int32(1)
        if npts <= 1; continue; end
        sumt[j]   += npts * p;   sumba[j]  += npts * tba
        sumbf[j]  += npts * tbf; sumcf[j]  += npts * tcf
        sumbio[j] += npts * tbiomass; sumcarb[j] += npts * tcarb_v
    end

    # Normalize by gross area
    gs = GROSPC
    for ispc in 1:MAXSP
        tottr[ispc]  /= gs; totba[ispc]  /= gs
        totcf[ispc]  /= gs; totbf[ispc]  /= gs
        totbio[ispc] /= gs; totcarb[ispc] /= gs
    end

    # Write general species summary
    @printf(io, "\n")
    @printf(io, "%9sGENERAL SPECIES SUMMARY FOR THE CRUISE (PER ACRE)\n", "")
    @printf(io, "\n%2sSTAND%18sTREES%12sARSAL AREA%17sCUBIC FEET%17sBOARD FEET%17sABOVE GROUND BIOMASS%27sABOVE GROUND CARBON\n",
        "","","","","","","")
    @printf(io, "%s\n", repeat("-", 131))

    for i in 1:MAXSP
        if iflg[i] == 0; continue; end
        rows += 1
        sp_arr[rows] = JSP[i]
        itpa[rows]   = tottr[i];  iba[rows]  = totba[i]
        ibf[rows]    = totbf[i];  icf[rows]  = totcf[i]
        ibio[rows]   = totbio[i]; icarb[rows]= totcarb[i]
        nm = length(NSP[i,1]) >= 2 ? NSP[i,1][1:2] : NSP[i,1]
        @printf(io, " %-4s=%-4s%14.1f%17.1f%17.1f%14.1f%28.1f%26.1f\n",
            JSP[i], nm, tottr[i], totba[i], totcf[i], totbf[i], totbio[i], totcarb[i])
    end

    if npts <= 1
        @printf(io, " DISTRIBUTION OF ATTRIBUTES AMONG SAMPLE POINTS CANNOT BE COMPUTED WITH ONE SAMPLE POINT.\n\n")
        @goto label_150
    end

    @printf(io, "\n\n%19sDISTRIBUTION OF STAND ATTRIBUTES AMONG SAMPLE POINTS\n\n", "")
    ialp = Int(round(100.0 - 100.0 * ALPHA + 0.5))
    @printf(io, "%31sSTANDARD  COEFF OF SAMPLE%41s%4d%%%17sSAMPLING ERROR IN\n", "", "", ialp, "")
    @printf(io, "CHARACTERISTIC%11sMEAN DEVIATION VARIATION   SIZE     CONFIDENCE  LIMITS    PERCENT     UNITS\n%s\n",
        "", repeat("-", 76))

    t_ref    = Ref(Float32(0))
    ierr_ref = Ref(Int32(0))
    ndf      = npts - 1
    TVALUE(Int32(ndf), ALPHA, t_ref, ierr_ref)
    t = Float32(t_ref[])

    labels = ("TREES/ACRE         ", "BASAL AREA/ACRE    ", "CUBIC FEET/ACRE    ",
              "BOARD FEET/ACRE    ", "ABVGRD BIOMASS/ACRE", "ABVGRD CARB/ACRE   ")
    sums_arr = (sumt, sumba, sumcf, sumbf, sumbio, sumcarb)

    for col in 1:6
        sv = sums_arr[col]
        sum_v = Float32(0); sumsq_v = Float32(0)
        for i in 1:npts
            sv_i = sv[i] / gs
            sum_v  += sv_i
            sumsq_v += sv_i * sv_i
        end
        if sum_v <= 0
            @printf(io, "%-19s%19s%9.2f%10.2f\n", labels[col], "", sum_v, sum_v)
            if col == 2; return nothing; end
            continue
        end
        pi_f  = Float32(npts)
        xbar  = sum_v / pi_f
        ss_v  = sumsq_v - sum_v * sum_v / pi_f
        s     = ss_v > 0 ? sqrt(ss_v / (pi_f - 1)) : Float32(0)
        se    = s / sqrt(pi_f)
        ul    = max(Float32(0), xbar - t * se)
        uu    = xbar + t * se
        cv    = s / xbar
        seu   = t * se
        sep_v = seu * 100f0 / xbar
        @printf(io, "%-19s%10.2f%10.2f%10.2f%7d%10.2f%14.2f%10.1f%12.1f\n",
            labels[col], xbar, s, cv, npts, ul, uu, sep_v, seu)

        idist[1,col]=xbar; idist[2,col]=s;     idist[3,col]=cv
        idist[4,col]=npts; idist[5,col]=ul;    idist[6,col]=uu
        idist[7,col]=sep_v;idist[8,col]=seu

        if col == 2; siglevel = (1f0 - ALPHA) * 100f0; end
    end

    # Database output for stand (multi-point)
    if npts > 1
        for i in 1:6
            DBSSTATS(sp_arr[i], itpa[i], iba[i], icf[i], ibf[i],
                ibio[i], icarb[i],
                idist[1,i], idist[2,i], idist[3,i], idist[4,i], siglevel,
                idist[5,i], idist[6,i], idist[7,i], idist[8,i], labels[i], 2, iyear)
        end
    end

    @label label_150
    iyear = Int(IY[1])
    for i in 1:rows
        speccd[i] = sp_arr[i]; tpa_a[i] = itpa[i]; barea[i] = iba[i]
        bfvol[i]  = ibf[i];   cfvol[i] = icf[i]
        agbio[i]  = ibio[i];  agcarb[i]= icarb[i]
        DBSSTATS(sp_arr[i], itpa[i], iba[i], icf[i], ibf[i],
            ibio[i], icarb[i],
            idist[1,i], idist[2,i], idist[3,i], idist[4,i], siglevel,
            idist[5,i], idist[6,i], idist[7,i], idist[8,i], labels[i], 1, iyear)
    end

    return nothing
end
