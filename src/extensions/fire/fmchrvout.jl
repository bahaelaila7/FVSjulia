# fire/fmchrvout.f — Harvested products carbon report (6 indicators)
# Uses FAPROP fate-proportion curves and FATE(pulp/saw, HW/SW, cycle) arrays.
# Called from: FMMAIN

function FMCHRVOUT(iyr::Integer)
    debug = DBCHK("FMCHRVOUT", 9, ICYC)
    if debug
        @printf(get(io_units, Int32(JOSTND), stdout),
            " ENTERING FMCHRVOUT CYCLE = %2d\n", ICYC)
    end

    local jrout_ref = Ref(Int32(0))
    GETLUN(jrout_ref)
    local jrout = jrout_ref[]

    if debug
        @printf(get(io_units, Int32(JOSTND), stdout),
            " FMCHRVOUT: ICHRVB=%5d ICHRVE=%5d IDCHRV=%5d JROUT=%3d\n",
            ICHRVB, ICHRVE, IDCHRV, jrout)
    end

    # 6 carbon fate indicators:
    # 1=Products (in use), 2=Landfill, 3=Energy, 4=Emissions
    # 5=Merch C stored (1+2), 6=Merch C removed from stand (3+4+5)
    local v = zeros(Float32, 6)

    for jcyc in 1:Int(ICYC)
        local kyr = iyr - Int(IY[jcyc]) + 1
        if kyr >= 101; kyr = 101; end
        for ipl in 1:2        # pulpwood / sawlog
            for ihw in 1:2    # softwood / hardwood
                local xtmp = 0.0f0
                for ifate in 1:3  # in-use, landfill, energy
                    xtmp    += FAPROP[Int(ICHABT), kyr, ifate, ipl, ihw]
                    v[ifate] += FATE[ipl, ihw, jcyc] *
                                FAPROP[Int(ICHABT), kyr, ifate, ipl, ihw]
                end
                v[4] += FATE[ipl, ihw, jcyc] * (1.0f0 - xtmp)
            end
        end
    end

    v[5] = v[1] + v[2]
    v[6] = v[3] + v[4] + v[5]

    # Biomass → carbon (×0.5)
    for i in 1:6; v[i] *= 0.5f0; end

    # Unit conversion
    if Int(ICMETRC) == 1
        for i in 1:6; v[i] *= TItoTM / ACRtoHA; end
    elseif Int(ICMETRC) == 2
        for i in 1:6; v[i] *= TItoTM; end
    end

    # Event monitor carbon array (indices 12-17)
    for i in 1:6; CARBVAL[11 + i] = v[i]; end

    if Int(ICHRVB) == 0; return nothing; end

    # Database output
    local dbskode = Ref(Int32(1))
    DBSFMHRPT(iyr, NPLT, v, Int32(6), dbskode)
    if dbskode[] == Int32(0); return nothing; end

    # Text report
    local io = get(io_units, jrout, stdout)
    global ICHPAS += Int32(1)
    if Int(ICHPAS) == 1
        @printf(io, "\n%6d \n\n%6d %s\n", IDCHRV, IDCHRV, "-"^122)
        @printf(io, "%6d %30s******  CARBON REPORT VERSION 1.0 ******\n", IDCHRV, "")
        @printf(io, "%6d %38sHARVESTED PRODUCTS REPORT (BASED ON STOCKABLE AREA)\n", IDCHRV, "")
        if Int(ICMETRC) == 1
            @printf(io, "%6d %25sALL VARIABLES ARE REPORTED IN METRIC TONS/HECTARE\n", IDCHRV, "")
        elseif Int(ICMETRC) == 2
            @printf(io, "%6d %27sALL VARIABLES ARE REPORTED IN METRIC TONS/ACRE\n", IDCHRV, "")
        else
            @printf(io, "%6d %30sALL VARIABLES ARE REPORTED IN TONS/ACRE\n", IDCHRV, "")
        end
        @printf(io, "\n%6d \n", IDCHRV)
        @printf(io, "%6d  STAND ID: %-26s    MGMT ID: %s\n", IDCHRV, NPLT, MGMID)
        @printf(io, "%6d %s\n", IDCHRV, "-"^122)
        @printf(io, "%6d %44sMerch Carbon\n", IDCHRV, "")
        @printf(io, "%6d %43s%s\n", IDCHRV, "", "-"^15)
        @printf(io, "%6d YEAR  Prducts  Lndfill   Energy  Emissns   Stored  Removed\n", IDCHRV)
        @printf(io, "%6d %s\n", IDCHRV, "-"^122)
    end

    @printf(io, "%6d %4d  %7.1f  %7.1f  %7.1f  %7.1f  %7.1f  %7.1f\n",
            IDCHRV, iyr, v[1], v[2], v[3], v[4], v[5], v[6])
    return nothing
end
