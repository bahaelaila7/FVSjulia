# extensions/fire/fmsvout.jl — FMSVOUT: fire SVS animation output driver
# Translated from fire/fmsvout.f (381 lines)
# Calls SVOUT repeatedly (NFMSVPX frames) with progressive fire line, and
# FMSVTREE/FMSVFL for individual flame objects. Writes fire frames to SVS file.

function FMSVOUT(iyear::Integer, flmhtin::Real, iftyp::Integer)
    debug = DBCHK(false, "FMSVOUT", Int32(7), ICYC)
    if debug
        @printf(io_units[JOSTND],
            " IN FMSVOUT,NFMSVPX=%2d IYEAR,FLAMEHT,IFTYP=%5d%10.2f%5d\n",
            NFMSVPX, iyear, FLAMEHT, iftyp)
        @printf(io_units[JOSTND],
            " Pre-Snag-Removal Fuel Loads:  Litter   Duff    0-3    3-6    6-12     >12\n")
        @printf(io_units[JOSTND], "     Before Fire:            ")
        for v in TCWD;  @printf(io_units[JOSTND], "%6.2f  ", v); end
        @printf(io_units[JOSTND], "\n     After Fire:             ")
        for v in TCWD2; @printf(io_units[JOSTND], "%6.2f  ", v); end
        @printf(io_units[JOSTND], "\n")
    end

    global IFMTYP = Int32(iftyp)
    global FLAMEHT = Float32(flmhtin)

    (JSVOUT == Int32(0) || NFMSVPX == Int32(0)) && return

    # swap IOBJTP ↔ IOBJTPTMP, IS2F ↔ IS2FTMP
    for i in 1:Int(NSVOBJ)
        tmp = IOBJTPTMP[i]
        IOBJTPTMP[i] = IOBJTP[i]
        IOBJTP[i]    = tmp

        tmp2 = IS2FTMP[i]
        IS2FTMP[i] = IS2F[i]
        IS2F[i]    = tmp2
    end

    if debug
        @printf(io_units[JOSTND],
            " Post-Snag-Removal Fuel Loads:  Litter   Duff    0-3    3-6    6-12     >12\n")
        @printf(io_units[JOSTND], "     Before Fire:            ")
        for v in TCWD;  @printf(io_units[JOSTND], "%6.2f  ", v); end
        @printf(io_units[JOSTND], "\n     After Fire:             ")
        for v in TCWD2; @printf(io_units[JOSTND], "%6.2f  ", v); end
        @printf(io_units[JOSTND], "\n")
    end

    # stand geometry
    if IMETRIC == 0
        xsd   = 7.5f0
        xymax = IPLGEM <= 1 ? 208.71f0 : 235.50f0
    else
        xsd   = 7.5f0 * FTtoM
        xymax = IPLGEM <= 1 ? 100.0f0 : 112.84f0
    end

    xjump = (xymax / Float32(NFMSVPX - 1)) / Float32(NFLPTS)
    FMY2[1] = 0f0
    OFFSET[1] = BACHLO(0f0, xsd, SVRANN)
    for i in 2:Int(NFLPTS)
        FMY2[i]   = 0f0
        OFFSET[i] = OFFSET[i-1] + BACHLO(0f0, xsd, SVRANN)
    end

    for ifmsvpx in 1:Int(NFMSVPX)
        for i in 1:Int(NFLPTS)
            FMY1[i]    = FMY2[i]
            median_val = Float32(Int((Float32(ifmsvpx - 0) / Float32(NFMSVPX - 1)) * xymax))
            CATCHUP[i] = BACHLO(0f0, xjump, SVRANN)
            FMY2[i]    = median_val + OFFSET[i] + CATCHUP[i]
        end

        if ifmsvpx == Int(NFMSVPX)
            for i in 1:Int(NFLPTS); FMY2[i] = xymax; end
        end

        for i in 1:Int(NSVOBJ)
            ii = Int(XSLOC[i] / (xymax / Float32(NFLPTS)))
            ii < 1          && (ii = 1)
            ii > Int(NFLPTS) && (ii = Int(NFLPTS))
            if YSLOC[i] <= FMY2[ii] && YSLOC[i] > FMY1[ii]
                IOBJTP[i] = IOBJTPTMP[i]
                IS2F[i]   = IS2FTMP[i]
            end
        end

        if ifmsvpx == 1
            title = @sprintf("Beginning of fire (%02d/%02d)", ifmsvpx, NFMSVPX)
            SVOUT(iyear, 4, title)
        elseif ifmsvpx == Int(NFMSVPX)
            title = @sprintf("After the fire (%02d/%02d)", ifmsvpx, NFMSVPX)
            SVOUT(iyear, 5, title)
        else
            title = @sprintf("During the fire (%02d/%02d)", ifmsvpx, NFMSVPX)
            SVOUT(iyear, 4, title)
        end
    end
    return
end
