# base/volstubs.jl — stubs for NVEL volume library calls and header output routines
# The real implementations require the NVEL Fortran volume library (external dependency).
# These stubs allow the rest of FVSjulia to compile and run without NVEL.
#
# VOLEQDEF: look up default volume equation number for given species/region/product.
# Returns (ifiasp_status, errflag). ifiasp_status==8888 means found; otherwise not found.
function VOLEQDEF(var::AbstractString, iregn::Integer, forst::AbstractString,
                  dist::AbstractString, ifiasp::Integer, prod::AbstractString,
                  voleq::AbstractString)
    return (Int32(8888), Int32(0))
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
