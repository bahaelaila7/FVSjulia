# extensions/fire/fmsvtree.jl — FMSVTREE: draw flame objects for a single SVS tree
# Translated from fire/fmsvtree.f (178 lines)
# Called from FMSVOUT for each SVS object in the fire zone.
# Writes @flame.eob records to NOUT (SVS file unit).

function FMSVTREE(nout::Integer, isvobj::Integer)
    ii = Int(XSLOC[isvobj] / FLPART) + 1

    YSLOC[isvobj] >= FMY2[ii] && return

    f = IS2F[isvobj]
    basecrwn = ((100f0 - CRNRTO[f]) / 100f0) * OLEN[f]
    halfcrwn = ((CRNRTO[f] / 100f0) * OLEN[f]) / 2f0
    midcrwn  = basecrwn + halfcrwn
    flmcrawl = 0f0
    calc     = 0f0

    if IFMTYP == 1
        # crowning fire
        if YSLOC[isvobj] > FMY2[ii] - 150f0
            if     YSLOC[isvobj] > FMY2[ii] - 15f0;  calc = 0.75f0
            elseif YSLOC[isvobj] > FMY2[ii] - 30f0;  calc = 0.8f0
            elseif YSLOC[isvobj] > FMY2[ii] - 45f0;  calc = 0.9f0
            elseif YSLOC[isvobj] > FMY2[ii] - 60f0;  calc = 1.0f0
            elseif YSLOC[isvobj] > FMY2[ii] - 75f0;  calc = 0.9f0
            elseif YSLOC[isvobj] > FMY2[ii] - 90f0;  calc = 0.8f0
            elseif YSLOC[isvobj] > FMY2[ii] - 105f0; calc = 0.75f0
            elseif YSLOC[isvobj] > FMY2[ii] - 120f0; calc = 0.1f0
            else;                                       calc = 0f0
            end
            flmcrawl = 3f0 * (halfcrwn * 2f0 / OLEN[f]) + 1.5f0
        end
    elseif IFMTYP == 2
        # torching fire
        if     YSLOC[isvobj] > FMY2[ii] - 15f0;  calc = 0.25f0
        elseif YSLOC[isvobj] > FMY2[ii] - 30f0;  calc = 0.50f0
        elseif YSLOC[isvobj] > FMY2[ii] - 45f0;  calc = 0.75f0
        elseif YSLOC[isvobj] > FMY2[ii] - 60f0;  calc = 1.0f0
        elseif YSLOC[isvobj] > FMY2[ii] - 75f0;  calc = 0.75f0
        elseif YSLOC[isvobj] > FMY2[ii] - 90f0;  calc = 0.50f0
        elseif YSLOC[isvobj] > FMY2[ii] - 105f0; calc = 0.25f0
        elseif YSLOC[isvobj] > FMY2[ii] - 120f0; calc = 0.1f0
        else;                                       calc = 0f0
        end
        flmcrawl = 4f0 * (halfcrwn * 2f0 / OLEN[f]) + 2f0
        # 80% of trees: skip if ground fire can't reach crown
        if basecrwn > FLAMEHT * 1.2f0
            x_r = Ref(0f0); SVRANN(x_r)
            x_r[] < 0.8f0 && (calc = 0f0)
        end
    end

    z_r = Ref(0f0); SVRANN(z_r)
    flmz = z_r[] * halfcrwn + basecrwn
    flmx = XSLOC[isvobj]
    flmy = YSLOC[isvobj]

    nflms = 0
    while true
        nflms += 1
        flmz += flmcrawl
        tiltbase = max(min(FWIND * 0.5f0, 40f0), 5f0)
        flmtilt  = max(BACHLO(tiltbase, 5f0, SVRANN), 0f0)
        flmcalc  = (OLEN[f] - flmz) * 0.65f0
        if IMETRIC == 0
            flmht = BACHLO(flmcalc, 0.5f0, SVRANN)
        else
            flmht = BACHLO(flmcalc, 0.5f0 * FTtoM, SVRANN)
        end
        fw_r = Ref(0f0); SVRANN(fw_r)
        flmwdth = CRNDIA[f] * (1f0 - (flmz - basecrwn) / (halfcrwn * 2f0)) * calc
        x2_r = Ref(0f0); SVRANN(x2_r)
        iflr0t = Int(x2_r[] * 90f0 + 270f0)

        if flmht > 0f0 && flmwdth > 0f0
            io = get(io_units, Int32(nout), stdout)
            if IMETRIC == 0
                @printf(io, "@flame.eob               %5d 99 0 1 0%6.0f%6.0f%5d 0%6.1f 0 0 0 0 0 0 0 1 0%8.2f%8.2f%8.2f\n",
                        nflms + NSVOBJ, flmht, flmtilt, iflr0t, flmwdth, flmx, flmy, flmz)
            else
                @printf(io, "@flame.eob               %5d 99 0 1 0%6.0f%6.0f%5d 0%6.1f 0 0 0 0 0 0 0 1 0%8.2f%8.2f%8.2f\n",
                        nflms + NSVOBJ, flmht * FTtoM, flmtilt, iflr0t, flmwdth * FTtoM, flmx, flmy, flmz * FTtoM)
            end
        end

        (flmht + flmz) >= OLEN[f] * calc && break
    end
    return
end
