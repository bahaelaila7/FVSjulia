# fire/fmsout.f — Print the snag list (snag characteristics by species/DBH/age class)
# Accumulates hard/soft snag density, height, volume by species × age-year × DBH class.
# Calls DBSFMDSNAG for database output, then writes text to JSNOUT unit.
# Called from: FMMAIN

function FMSOUT(iyr::Integer)
    debug = DBCHK("FMSOUT", 6, ICYC)
    if debug
        @printf(get(io_units, Int32(JOSTND), stdout),
            " ENTERING FMSOUT CYCLE = %2d IYR=%5d\n", ICYC, iyr)
    end

    local myact = Int32[2512]
    local ntodo = Int(OPFIND(Int32(1), myact))
    for jdo in 1:ntodo
        local jyr_ref   = Ref(Int32(0))
        local iactk_ref = Ref(Int32(0))
        local nprm_ref  = Ref(Int32(0))
        local prms      = zeros(Float32, 4)
        OPGET(Int32(jdo), Int32(4), jyr_ref, iactk_ref, nprm_ref, prms)
        global ISNAGB = Int32(iyr)
        global ISNAGE = Int32(Float32(iyr) + prms[1])
        global JSNOUT = Int32(prms[3])
        global LSHEAD = (prms[4] == 0.0f0)
        OPDONE(Int32(jdo), Int32(iyr))
        break
    end

    if debug
        @printf(get(io_units, Int32(JOSTND), stdout),
            " FMSOUT: ISNAGB=%5d; ISNAGE=%5d\n", ISNAGB, ISNAGE)
    end

    # Year range check
    if !(iyr == 0 && iyr == Int(ISNAGB))
        if iyr < Int(ISNAGB) || iyr > Int(ISNAGE); return nothing; end
    end

    # Accumulation arrays: (species, age_year, DBH_class)
    local totdh  = zeros(Float32, Int(MAXSP), 100, 6)
    local totds  = zeros(Float32, Int(MAXSP), 100, 6)
    local tothth = zeros(Float32, Int(MAXSP), 100, 6)
    local tothts = zeros(Float32, Int(MAXSP), 100, 6)
    local totvlh = zeros(Float32, Int(MAXSP), 100, 6)
    local totvls = zeros(Float32, Int(MAXSP), 100, 6)
    local totdbh = zeros(Float32, Int(MAXSP), 100, 6)

    local yrlast = -1
    local tempv_ref = Ref(Float32(0))

    for ii in 1:Int(NSNAG)
        if (DENIS[ii] + DENIH[ii]) <= 0.0f0 || DBHS[ii] < SNPRCL[1]; continue; end

        # Volume of initially-soft snags
        local snvols = 0.0f0
        if DENIS[ii] > 0.0f0
            tempv_ref[] = 0.0f0
            FMSVOL(ii, HTIS[ii], tempv_ref, false, Int32(0))
            snvols = tempv_ref[] * DENIS[ii]
        end

        # Volume of initially-hard snags (may have softened)
        local snvolh = 0.0f0
        if DENIH[ii] > 0.0f0
            tempv_ref[] = 0.0f0
            FMSVOL(ii, HTIH[ii], tempv_ref, false, Int32(0))
            if HARD[ii]
                snvolh = tempv_ref[] * DENIH[ii]
            else
                snvols += tempv_ref[] * DENIH[ii]
            end
        end

        # Age-year class (capped at 100)
        local jyr = iyr - Int(YRDEAD[ii]) + 1
        if jyr > 100; jyr = 100; end
        if jyr > yrlast; yrlast = jyr; end

        # DBH class (1-5 by SNPRCL breaks, 6 = largest)
        local jcl = 6
        for jc in 1:5
            if DBHS[ii] < SNPRCL[jc+1]; jcl = jc; break; end
        end

        local idc = Int(SPS[ii])
        totds[idc, jyr, jcl]  += DENIS[ii]
        tothts[idc, jyr, jcl] += HTIS[ii] * DENIS[ii]

        if HARD[ii]
            totdh[idc, jyr, jcl]  += DENIH[ii]
            tothth[idc, jyr, jcl] += HTIH[ii] * DENIH[ii]
        else
            totds[idc, jyr, jcl]  += DENIH[ii]
            tothts[idc, jyr, jcl] += HTIH[ii] * DENIH[ii]
        end

        totvls[idc, jyr, jcl] += snvols
        totvlh[idc, jyr, jcl] += snvolh
        totdbh[idc, jyr, jcl] += DBHS[ii] * (DENIS[ii] + DENIH[ii])
    end

    # Normalize heights and DBHs
    for jyr in 1:(yrlast > 0 ? yrlast : 0)
        for idc in 1:Int(MAXSP)
            for jcl in 1:6
                local totn = totdh[idc, jyr, jcl] + totds[idc, jyr, jcl]
                if totn == 0.0f0; continue; end
                totdbh[idc, jyr, jcl] /= totn
                tothth[idc, jyr, jcl] = totdh[idc, jyr, jcl] > 0.0f0 ?
                    tothth[idc, jyr, jcl] / totdh[idc, jyr, jcl] : 0.0f0
                tothts[idc, jyr, jcl] = totds[idc, jyr, jcl] > 0.0f0 ?
                    tothts[idc, jyr, jcl] / totds[idc, jyr, jcl] : 0.0f0
            end
        end
    end

    # Database output
    local dbskode = Ref(Int32(1))
    DBSFMDSNAG(iyr, totdbh, tothth, tothts, totvlh, totvls,
               totdh, totds, yrlast, dbskode)
    if dbskode[] == Int32(0); return nothing; end

    local lok = openIfClosed(JSNOUT, "sng")
    if !lok; return nothing; end
    local io = get(io_units, Int32(JSNOUT), stdout)

    if LSHEAD
        @printf(io, " ESTIMATED SNAG CHARACTERISTICS (BASED ON STOCKABLE AREA), STAND ID=%-26s\n", NPLT)
        @printf(io, "%s\n", "-"^76)
        @printf(io, "%13s DEATH CURR HEIGHT CURR VOLUME (FT3)          DENSITY (SNAGS/ACRE)  \n", "")
        @printf(io, "%9s DBH  DBH %s(FT)%s %s  YEAR %s\n",
                "", "-"^4, "-"^3, "-"^17, "-"^23)
        @printf(io, " YEAR SP  CL  (IN)  HARD  SOFT  HARD  SOFT TOTAL  DIED   HARD    SOFT    TOTAL\n")
        @printf(io, "%s\n", "-"^76)
        global LSHEAD = false
    end

    for jyr in 1:(yrlast > 0 ? yrlast : 0)
        for idc in 1:Int(MAXSP)
            for jcl in 1:6
                local totn = totdh[idc, jyr, jcl] + totds[idc, jyr, jcl]
                if totn == 0.0f0; continue; end
                @printf(io, " %4d %2s %3d %5.1f %5.1f %5.1f %5d %5d %5d %4d %7.2f %7.2f %7.2f\n",
                    iyr, JSP[idc], jcl,
                    totdbh[idc, jyr, jcl],
                    tothth[idc, jyr, jcl], tothts[idc, jyr, jcl],
                    Int(totvlh[idc, jyr, jcl]), Int(totvls[idc, jyr, jcl]),
                    Int(totvlh[idc, jyr, jcl] + totvls[idc, jyr, jcl]),
                    iyr - jyr + 1,
                    totdh[idc, jyr, jcl], totds[idc, jyr, jcl], totn)
            end
        end
    end

    if haskey(io_units, Int32(JSNOUT))
        close(io_units[Int32(JSNOUT)])
        delete!(io_units, Int32(JSNOUT))
    end
    return nothing
end
