# extensions/fire/fmsvfl.jl — FMSVFL + FMGETFL: fire SVS ground flame and fire line output
# Translated from fire/fmsvfl.f (253 lines)
# FMSVFL: writes #FIRE_LINE, #PRE/POST_FIRE_LOAD, and @flame.eob ground flame records.
# FMGETFL: copies FMY2 fire line array to caller.

function FMSVFL(nout::Integer)
    io = get(io_units, Int32(nout), stdout)

    # write fire line and fuel load headers
    @printf(io, "#FIRE_LINE ")
    for i in 1:Int(NFLPTS); @printf(io, " %6.2f", FMY2[i]); end
    @printf(io, "\n")
    @printf(io, "#PRE_FIRE_LOAD")
    for v in TCWD; @printf(io, " %6.2f", v); end
    @printf(io, "\n")
    @printf(io, "#POST_FIRE_LOAD")
    for v in TCWD2; @printf(io, " %6.2f", v); end
    @printf(io, "\n")

    widthmin = 0f0

    tiltbase = if FWIND <= 1f0
        5f0
    elseif FWIND <= 10f0
        15f0
    elseif FWIND <= 35f0
        30f0
    else
        40f0
    end

    # surface or passive: 250 ground flames; crowning: 0
    nflf = FIRTYPE == 1 ? 0 : 250

    if IMETRIC == 0
        wmax  = IPLGEM <= 1 ? 208.71f0 : 235.50f0
        width = wmax
    else
        wmax  = IPLGEM <= 1 ? 100.0f0 : 112.84f0
        width = wmax
    end
    global FLPART = wmax / Float32(NFLPTS)

    nflames = nflf
    nflms   = nflames
    iflames = 0

    while iflames < nflames
        iflames += 1

        if iflames <= nflf
            # pick random X, retry if outside stand boundary
            local flmx::Float32
            local flmy::Float32
            local ii::Int
            while true
                x_r = Ref(0f0); SVRANN(x_r); flmx = x_r[] * wmax
                ii = Int(flmx / FLPART)
                ii > Int(NFLPTS) && (ii = Int(NFLPTS))
                ii < 1           && (ii = 1)
                flmy = BACHLO(FMY2[ii], 2.5f0, SVRANN)
                (flmy < 0f0 || flmy > wmax) && (iflames -= 1; iflames += 1; continue)
                if IPLGEM > 1
                    if IMETRIC == 0
                        xd = 235.50f0; xr = 117.75f0; xr2 = 13865.06f0
                    else
                        xd = 112.84f0; xr =  56.42f0; xr2 =  3183.22f0
                    end
                    if flmy > xr
                        width = 2f0 * sqrt(xr2 - (flmy - xr)^2)
                    else
                        width = 2f0 * sqrt(xr2 - (xr - flmy)^2)
                    end
                    widthmin = (xd - width) / 2f0
                    (flmx < widthmin || flmx > widthmin + width) && continue
                end
                break
            end

            local flmht::Float32
            if flmy > FMY2[ii] + 1f0
                tmpdist = flmy - FMY2[ii]
                tmppct  = 1f0 / tmpdist
                tmpvar  = 1f0 - tmppct^2
                tmpheight = FLAMEHT - FLAMEHT * tmpvar
                flmht = BACHLO(tmpheight, tmpheight * 0.05f0, SVRANN)
            elseif flmy >= FMY2[ii] - 1f0
                flmht = BACHLO(FLAMEHT, FLAMEHT * 0.1f0, SVRANN)
            else
                tmpdist = FMY2[ii] - flmy
                tmppct  = 1f0 / tmpdist
                tmpvar  = 1f0 - tmppct^3
                tmpheight = FLAMEHT - (FLAMEHT * tmpvar) / 2f0
                flmht = BACHLO(tmpheight, tmpheight * 0.05f0, SVRANN)
            end

            fw_r = Ref(0f0); SVRANN(fw_r)
            flmwdth = fw_r[] * FLAMEHT + 1f0
            flmtilt = BACHLO(tiltbase, 5f0, SVRANN)
            x2_r = Ref(0f0); SVRANN(x2_r)
            iflr0t = Int(x2_r[] * 360f0)

            if IMETRIC == 0
                @printf(io, "@flame.eob               %5d 99 0 1 0%6.0f%6.0f%5d 0%6.1f 0 0 0 0 0 0 0 1 0%8.2f%8.2f%8.2f\n",
                        iflames + NSVOBJ, flmht, flmtilt, iflr0t, flmwdth, flmx, flmy, 0f0)
            else
                @printf(io, "@flame.eob               %5d 99 0 1 0%6.0f%6.0f%5d 0%6.1f 0 0 0 0 0 0 0 1 0%8.2f%8.2f%8.2f\n",
                        iflames + NSVOBJ, flmht * FTtoM, flmtilt, iflr0t, flmwdth * FTtoM, flmx, flmy, 0f0)
            end
        end
    end
    return
end

function FMGETFL(asize::Integer, fline::AbstractVector{Float32})
    n = min(Int(asize), Int(NFLPTS))
    for i in 1:n
        fline[i] = FMY2[i]
    end
    return
end
