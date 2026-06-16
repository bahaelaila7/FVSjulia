# fire/fmcrbout.f — Stand carbon report (11 indicators: live ABG, merch, BG, snags, DDW, etc.)
# Computes carbon pools using Jenkins (ICMETH=1) or FFE (ICMETH=0) equations.
# Decays root biomass each cycle regardless of print status.
# Called from: FMMAIN

function FMCRBOUT(iyr::Integer)
    debug = DBCHK("FMCRBOUT", 8, ICYC)
    if debug
        @printf(get(io_units, Int32(JOSTND), stdout),
            " ENTERING FMCRBOUT CYCLE = %2d\n", ICYC)
    end

    local jrout_ref = Ref(Int32(0))
    GETLUN(jrout_ref)
    local jrout = jrout_ref[]

    if debug
        @printf(get(io_units, Int32(JOSTND), stdout),
            " FMDOUT: ICRPTB=%5d ICRPTE=%d IDCRPT=%5d JROUT=%3d\n",
            ICRPTB, 0, IDCRPT, jrout)
    end

    local ldcay = CRDCAY > 0.0f0

    # 11 carbon indicators:
    # 1=ABG live total, 2=ABG live merch, 3=BG live, 4=BG dead (decaying roots)
    # 5=standing dead, 6=DDW, 7=forest floor, 8=shrub/herb
    # 9=total stand carbon, 10=carbon removed, 11=carbon released from fire
    local v = zeros(Float32, 11)

    for i in 1:Int(ITRN)
        local d = DBH[i]
        local abio_ref = Ref(Float32(0))
        local mbio_ref = Ref(Float32(0))
        local rbio_ref = Ref(Float32(0))
        FMCBIO(d, Int(ISP[i]), abio_ref, mbio_ref, rbio_ref)
        local abio = abio_ref[] * FMPROB[i]
        local mbio = mbio_ref[] * FMPROB[i]
        local rbio = rbio_ref[] * FMPROB[i]
        v[3] += rbio

        if Int(ICMETH) == 1   # Jenkins equations
            v[1] += abio
            v[2] += mbio
        else                  # FFE volume method
            local vt_ref = Ref(Float32(0))
            FMSVL2(Int(ISP[i]), d, HT[i], -1.0f0, vt_ref,
                   Int(ICR[i]), 'L', LVWEST, debug, Int32(JOSTND))
            v[2] += FMPROB[i] * vt_ref[] * V2T[Int(ISP[i])]
        end
    end

    # Replace live ABG from FFE bulk store if available
    if Int(ICMETH) == 1
        v[10] = BIOREM[1]
    else
        v[1]  = BIOLIVE
        v[10] = BIOREM[2]
    end

    v[4]  = BIOROOT
    v[5]  = BIOSNAG
    v[6]  = BIODDW
    v[7]  = BIOFLR
    v[8]  = BIOSHRB
    v[11] = BIOCON[1] * 0.37f0 + BIOCON[2] * 0.50f0

    # Convert biomass to carbon (loop 1:10; skip 9 which is recomputed below)
    for i in 1:10
        if i in (1, 2, 3, 4, 5, 6, 8, 10)
            v[i] *= 0.50f0
        elseif i == 7
            v[i] *= 0.37f0
        end
    end

    # Unit conversion
    if Int(ICMETRC) == 1
        for i in 1:11; v[i] *= TItoTM / ACRtoHA; end
    elseif Int(ICMETRC) == 2
        for i in 1:11; v[i] *= TItoTM; end
    end

    # Total stand carbon (possibly including decaying roots)
    v[9] = v[1] + v[3] + v[5] + v[6] + v[7] + v[8]
    if ldcay
        v[9] += v[4]
    else
        v[4] = -1.0f0
    end

    # Event monitor carbon array
    for i in 1:11; CARBVAL[i] = v[i]; end

    # Reset accumulating pools
    global BIOSNAG   = 0.0f0
    global BIODDW    = 0.0f0
    global BIOFLR    = 0.0f0
    global BIOSHRB   = 0.0f0
    global BIOREM[1] = 0.0f0
    global BIOREM[2] = 0.0f0
    global BIOLIVE   = 0.0f0
    global BIOCON[1] = 0.0f0
    global BIOCON[2] = 0.0f0

    # Text + DB report (only when report begin year is set)
    if Int(ICRPTB) != 0
        local dbskode = Ref(Int32(1))
        DBSFMCRPT(iyr, NPLT, v, Int32(11), dbskode)
        if dbskode[] != Int32(0)
            local io = get(io_units, jrout, stdout)
            global ICRPAS += Int32(1)
            if Int(ICRPAS) == 1
                @printf(io, "\n%6d \n\n%6d %s\n", IDCRPT, IDCRPT, "-"^110)
                @printf(io, "%6d %30s******  CARBON REPORT VERSION 1.0 ******\n", IDCRPT, "")
                @printf(io, "%6d %41sSTAND CARBON REPORT (BASED ON STOCKABLE AREA)\n", IDCRPT, "")
                if Int(ICMETRC) == 1
                    @printf(io, "%6d %25sALL VARIABLES ARE REPORTED IN METRIC TONS/HECTARE\n",
                            IDCRPT, "")
                elseif Int(ICMETRC) == 2
                    @printf(io, "%6d %27sALL VARIABLES ARE REPORTED IN METRIC TONS/ACRE\n",
                            IDCRPT, "")
                else
                    @printf(io, "%6d %30sALL VARIABLES ARE REPORTED IN TONS/ACRE\n", IDCRPT, "")
                end
                @printf(io, "\n%6d \n", IDCRPT)
                @printf(io, "%6d  STAND ID: %-26s    MGMT ID: %s\n", IDCRPT, NPLT, MGMID)
                @printf(io, "%6d %s\n", IDCRPT, "-"^110)
                @printf(io,
                    "%6d       Aboveground Live    Belowground%24sForest%13sTotal    Total     Carbon\n",
                    IDCRPT, "", "")
                @printf(io,
                    "%6d      %s %s    Stand  %s    Stand  Removed   Released\n",
                    IDCRPT, "-"^17, "-"^17, "-"^25)
                @printf(io,
                    "%6d YEAR    Total    Merch     Live     Dead     Dead      DDW    Floor  Shb/Hrb   Carbon   Carbon  from Fire\n",
                    IDCRPT)
                @printf(io, "%6d %s\n", IDCRPT, "-"^110)
            end
            local vstr = join([@sprintf("  %7.1f", v[i]) for i in 1:10], "")
            @printf(io, "%6d %4d%s    %7.1f\n", IDCRPT, iyr, vstr, v[11])
        end
    end

    # Decay dead roots (every cycle, regardless of printing)
    if ldcay
        global BIOROOT = BIOROOT * (1.0f0 - CRDCAY)^Int(NYRS)
    else
        global BIOROOT = 0.0f0
    end
    return nothing
end
