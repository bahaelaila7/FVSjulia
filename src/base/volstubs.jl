# base/volstubs.jl — stubs for NVEL volume library calls and header output routines
# The real implementations require the NVEL Fortran volume library (external dependency).
# These stubs allow the rest of FVSjulia to compile and run without NVEL.

# R8_CEQN species arrays (voleqdef.f lines 1929-1952)
const _SNFIA = Int32[
   10, 57, 90,100,107,110,111,115,121,123,
  126,128,129,130,131,132,197,221,222,260,
  261,299,300,311,313,314,316,317,318,330,
  370,372,391,400,404,450,460,471,491,500,
  521,531,540,541,543,544,545,546,550,552,
  555,580,591,601,602,611,621,650,651,652,
  653,654,660,680,691,693,694,701,711,721,
  731,740,742,743,762,800,802,804,806,812,
  813,817,819,820,822,823,824,825,826,827,
  828,830,831,832,833,834,835,837,838,901,
  920,930,931,950,970,971,972,975,998,999]

const _SNSP = String[
  "261","100","115","100","107","110","111","115","121","123",
  "126","128","129","132","131","132","197","221","222","261",
  "261","132","300","500","313","314","316","317","318","330",
  "370","370","370","400","404","300","460","300","300","500",
  "521","531","541","541","300","544","545","546","550","500",
  "300","580","300","601","602","611","621","650","651","652",
  "653","300","300","300","691","693","694","500","711","300",
  "731","300","742","300","762","800","802","804","806","812",
  "813","817","800","820","822","823","800","825","826","827",
  "828","830","831","832","833","834","835","837","835","901",
  "920","930","300","950","970","970","970","970","300","300"]

function _r8_ceqn(forst::AbstractString, dist::AbstractString,
                  spec::Integer, prod::AbstractString)::String
    fornum  = tryparse(Int, strip(forst))
    distnum = tryparse(Int, strip(dist))
    (fornum  === nothing) && (fornum  = 0)
    (distnum === nothing) && (distnum = 0)

    geoa = if fornum == 1
        distnum == 3 ? '1' : '4'
    elseif fornum ∈ (2,4,8,60)
        '3'
    elseif fornum == 3
        distnum == 8 ? '2' : '3'
    elseif fornum ∈ (5,36)
        '1'
    elseif fornum ∈ (6,13)
        '5'
    elseif fornum == 7
        distnum == 6 ? '7' : (distnum ∈ (7,17) ? '4' : '5')
    elseif fornum == 9
        '6'
    elseif fornum == 10
        distnum == 7 ? '7' : '6'
    elseif fornum == 11
        distnum == 3 ? '1' : (distnum == 10 ? '2' : '3')
    elseif fornum == 12
        distnum == 2 ? '3' : (distnum == 5 ? '1' : '2')
    else
        '9'
    end

    # Binary search SNFIA for spec
    first_, last_ = 1, 110
    done = 0
    while true
        half = (last_ - first_ + 1) ÷ 2 + first_
        if _SNFIA[half] == spec
            done = half; break
        elseif first_ == last_
            done = spec < 300 ? 22 : 110; break
        elseif _SNFIA[half] < spec
            first_ = half
        else
            last_ = max(half - 1, first_)
        end
    end

    return "8" * string(geoa) * "1CLKE" * _SNSP[done]
end

# VOLEQDEF: look up default volume equation number for given species/region/product.
# Returns the equation string (INTENT(OUT) in Fortran → function return in Julia).
function VOLEQDEF(var::AbstractString, iregn::Integer, forst::AbstractString,
                  dist::AbstractString, ifiasp::Integer, prod::AbstractString,
                  voleq::AbstractString)::String
    if iregn == 8 && ifiasp > 0
        return _r8_ceqn(forst, dist, ifiasp, prod)
    end
    return "           "
end

# NVBEQDEF: look up NVB volume equation for given FIA species code.
# Translated from bin/FVSsn_buildDir/nvbeqdef.f (72 lines).
# Woodland species get region-specific equations; others get "NVBDDDDsss[P]".
const _NVBEQDEF_WOODLAND_SPP = Int32[62, 63, 65, 66, 69, 106, 133, 134,
                                      143, 321, 322, 475, 803, 810, 814, 843]
const _NVBEQDEF_WOODLAND_EQS = ["R03CHO0065", "R03CHO0066", "R03CHO0065", "R03CHO0066",
                                  "R03CHO0065", "R03CHO0106", "400DVEW133", "R03CHO0106",
                                  "R03CHO0106", "200DVEW475", "200DVEW814", "200DVEW475",
                                  "300DVEW800", "300DVEW800", "200DVEW814", "300DVEW800"]

function NVBEQDEF(spcd::Integer, voleq::AbstractString)::String
    WOODLAND_SPP = _NVBEQDEF_WOODLAND_SPP
    WOODLAND_EQS = _NVBEQDEF_WOODLAND_EQS

    if spcd in WOODLAND_SPP
        ISTATE == 0 && ERRGRO(true, Int32(44))
        idx = findfirst(==(Int32(spcd)), WOODLAND_SPP)
        eq = idx !== nothing ? WOODLAND_EQS[idx] : voleq
        if ISTATE in (6, 41, 53)
            spcd == 62 || spcd == 65 ? eq = "400DVEW065" :
            spcd == 66               ? eq = "200DVEW066" :
            spcd == 322              ? eq = "200DVEW475" : nothing
        elseif ISTATE in (4, 35)
            (spcd == 332 || spcd == 814) && (eq = "300DVEW800")
        end
        return eq
    end

    # Non-woodland species: "NVB" + 4-char division + 3-char species code
    division = lstrip(rstrip(ECOREG))
    length(division) < 4 && (division = "0" * division)
    divsplit = length(division) >= 4 ? division[1:4] : division
    sppid = lpad(string(spcd), 3, '0')   # zero-pad to at least 3 digits
    eq = "NVB" * divsplit * sppid

    # Managed plantation suffix for loblolly/slash pine in certain divisions
    if (divsplit == "0000" || divsplit == "0230") &&
       (spcd == 111 || spcd == 131) && ISTDORG == 1
        eq = eq[1:10] * "P"
    end
    return eq
end

# NVB_REGION_CHECK: validate and normalize the ECOREG division code.
# Translated from bin/FVSsn_buildDir/nvb_region_check.f (33 lines).
function NVB_REGION_CHECK()
    valid_divs = ("130 ", "210 ", "220 ", "230 ", "240 ",
                  "250 ", "260 ", "310 ", "330 ", "340 ",
                  "M130", "M210", "M220", "M230", "M240",
                  "M260", "M310", "M330", "M340")

    # Find last digit character, replace following char with '0'
    ecor = rpad(ECOREG, 4)
    i = findlast(c -> isdigit(c), ecor)
    if i !== nothing && i < 4
        ecor = ecor[1:i] * "0" * ecor[i+2:end]
    end
    ecor = rpad(ecor, 4)[1:4]
    global ECOREG = ecor

    valid = any(==(ecor), valid_divs)
    if !valid
        global ECOREG = "0000"
        ERRGRO(true, Int32(43))
    end
    return nothing
end

# FIAHEAD: real implementation in base/gheads.jl (loaded later)

# CLMAXDEN: climate-extension density modifier (exclim.f ENTRY). No-op stub.
function CLMAXDEN(sdidef::AbstractVector{Float32}, xmax::Float32)::Float32
    return xmax
end

# OPEVAL: evaluate computed expression parameters for an activity (opeval.f, 97 lines).
# Uses ALGEVL to evaluate the expression; loads results into PARMS for the activity.
# ALGEVL is stubbed → IRC=1 → activity is deleted (expression activities unsupported).
function OPEVAL(irefn::Integer, irc_ref::Ref{Int32})
    irc_ref[] = Int32(0)
    ldeb = DBCHK(false, "OPEVAL", Int32(6), ICYC)
    ldeb2 = DBCHK(false, "ALGEVL", Int32(6), ICYC)

    if ldeb
        @printf(io_units[JOSTND], " OPEVAL ICYC, IREFN, IRC= %3d %5d %3d\n",
                ICYC, irefn, irc_ref[])
    end

    if ICYC == Int32(0)
        irc_ref[] = Int32(-1)
        return nothing
    end

    j1 = -Int(IACT[irefn, 2])
    ALGEVL(LREG, Int(MXLREG_OP), XREG, Int(MXXREG_OP),
           view(IEVCOD, j1:length(IEVCOD)),
           Int(MAXCOD_OP) - j1 + 1,
           IY[1], IY[ICYC], ldeb2, Int(JOSTND), irc_ref)

    if ldeb
        @printf(io_units[JOSTND],
            "\n IN OPEVAL: IRC=%3d XREG(1)=%9.2f LREG(1)=%s\n",
            irc_ref[], XREG[1], LREG[1])
    end

    if irc_ref[] == Int32(0)
        np = Int(trunc(XREG[1]))
        if Int(IMPL) + np - 1 <= Int(ITOPRM)
            IACT[irefn, 2] = IMPL
            for i in 2:(np+1)
                PARMS[Int(IMPL)] = XREG[i]
                global IMPL = IMPL + Int32(1)
            end
            IACT[irefn, 3] = IMPL - Int32(1)
        else
            irc_ref[] = Int32(1)
            IACT[irefn, 2] = Int32(0)
            IACT[irefn, 3] = Int32(0)
            IACT[irefn, 4] = Int32(-1)
            ERRGRO(true, Int32(10))
        end
    else
        IACT[irefn, 2] = Int32(0)
        IACT[irefn, 3] = Int32(0)
        IACT[irefn, 4] = Int32(-1)
        ERRGRO(true, Int32(21))
    end
    return nothing
end

# VOLEQHEAD: real implementation in base/gheads.jl (loaded later)
