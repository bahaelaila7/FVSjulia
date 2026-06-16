# habtyp.jl — HABTYP: habitat type / ecological unit code decoder (sn variant)
# Translated from: habtyp.f (154 lines) + hbdecd.f (89 lines)
#
# HABTYP translates the habitat type code (KARD2 keyword field) into an integer
# subscript KODTYP and sets the global PCOM string. Default when no match is
# found: ecological unit "231DD" (index 122 in SNECU).
#
# HBDECD is a base utility called only from HABTYP; inlined here.

# ---------------------------------------------------------------------------
# 320 Southern ecological unit codes (NPA=320, DATA-initialized)
# ---------------------------------------------------------------------------
const _HABTYP_SNECU = String[
    "221DB","221DD","221DE","221EB","221EG","221EJ","221EN","221HA","221HB","221HC",
    "221HD","221HE","221JA","221JB","221JC","222AB","222AG","222AH","222AL","222AM",
    "222AN","222CB","222CC","222CD","222CE","222CF","222CG","222CH","222DA","222DB",
    "222DC","222DD","222DE","222DG","222DI","222DJ","222EA","222EB","222EC","222ED",
    "222EE","222EF","222EG","222EH","222EI","222EJ","222EK","222EN","222EO","222FA",
    "222FB","222FC","222FD","222FF","223AB","223AG","223AH","223AM","223AN","223BB",
    "223BC","223BD","223DA","223DB","223DC","223DD","223DE","223DG","223DI","223DJ",
    "223EA","223EB","223EC","223ED","223EE","223EF","223EG","223EH","223FA","223FB",
    "223FC","223FD","223FF","231AA","231AB","231AC","231AD","231AE","231AF","231AG",
    "231AH","231AI","231AJ","231AK","231AL","231AM","231AN","231AO","231AP","231BA",
    "231BB","231BC","231BD","231BE","231BF","231BG","231BH","231BI","231BJ","231BK",
    "231BL","231CA","231CB","231CC","231CD","231CE","231CF","231CG","231DA","231DB",
    "231DC","231DD","231DE","231EA","231EB","231EC","231ED","231EE","231EF","231EG",
    "231EH","231EI","231EJ","231EK","231EL","231EM","231EN","231EO","231FA","231FB",
    "231GA","231GB","231GC","231HA","231HB","231HC","231HD","231HE","231HF","231HH",
    "231HI","231IA","231IB","231IC","231ID","231IE","231IF","231IG","232AD","232BA",
    "232BB","232BC","232BD","232BE","232BF","232BG","232BH","232BI","232BJ","232BK",
    "232BL","232BM","232BN","232BO","232BP","232BQ","232BR","232BS","232BT","232BU",
    "232BV","232BX","232BZ","232CA","232CB","232CC","232CD","232CE","232CF","232CG",
    "232CH","232CI","232CJ","232DA","232DB","232DC","232DD","232DE","232EA","232EB",
    "232EC","232ED","232EE","232EF","232FA","232FB","232FC","232FD","232FE","232FF",
    "232GA","232GB","232GC","232GD","232HA","232HB","232HC","232IA","232IB","232JA",
    "232JB","232JC","232JD","232JE","232JF","232JG","232KA","232KB","232LA","232LB",
    "232LC","234AA","234AB","234AC","234AD","234AE","234AF","234AG","234AH","234AI",
    "234AJ","234AK","234AL","234AM","234AN","234CA","234CB","234CC","234CD","234DA",
    "234DB","234DC","234DO","234EA","234EB","234EC","251EA","251EC","251ED","251FB",
    "251FC","255AA","255AB","255AC","255AD","255AE","255AF","255AG","255AH","255AI",
    "255AJ","255AK","255AM","255BA","255CA","255CC","255CD","255CE","255CF","255CG",
    "255CH","255DA","255DB","255DC","255DD","255EA","255EB","255EC","255ED","255EE",
    "411AA","411AB","411AC","411AD","411AE","411AF","411AG","M221AA","M221AB","M221AC",
    "M221BA","M221BD","M221BE","M221CA","M221CB","M221CC","M221CD","M221CE","M221DA","M221DB",
    "M221DC","M221DD","M222AA","M222AB","M223AA","M223AB","M231AA","M231AB","M231AC","M231AD",
]

# ---------------------------------------------------------------------------
# HBDECD — decode habitat type alpha or numeric code (inlined from hbdecd.f)
# Returns ihb (1-based index into cnhb, or 0 for "DEFAULT", or -1 for no match).
# Updates kard2_ref[] with the matched code string (up to 8 chars).
# Updates array2_ref[] with Float32(ihb).
# ---------------------------------------------------------------------------
function HBDECD(cnhb::Vector{String}, maxhb::Int,
                array2_ref::Ref{Float32}, kard2_ref::Ref{String})
    ihb = Int(floor(array2_ref[]))

    if ihb >= 0 && ihb <= maxhb
        if ihb == 0
            # try alpha decode from kard2
            kard2 = kard2_ref[]
            temp  = "UNKNOWN"
            found_start = false
            for ic in 1:min(10, length(kard2))
                ch = length(kard2) >= ic ? kard2[ic:ic] : " "
                if ch != " "
                    found_start = true
                    # collect up to 8 non-blank chars starting at ic
                    buf = IOBuffer()
                    for jc in ic:min(10, length(kard2))
                        cch = kard2[jc:jc]
                        if jc == ic && cch == "0"
                            temp = "DEFAULT"
                            kard2_ref[] = temp
                            array2_ref[] = Float32(0)
                            return 0
                        end
                        print(buf, uppercase(cch))
                        if length(take!(buf)) >= 8; break; end  # should track length properly
                    end
                    # rebuild from start
                    buf2 = IOBuffer()
                    for jc in ic:min(ic+7, length(kard2))
                        cch = kard2[jc:jc]
                        if jc == ic && cch == "0"
                            kard2_ref[] = "DEFAULT"
                            array2_ref[] = Float32(0)
                            return 0
                        end
                        print(buf2, uppercase(cch))
                    end
                    temp = String(take!(buf2))
                    break
                end
            end
            if !found_start
                kard2_ref[] = "DEFAULT"
                array2_ref[] = Float32(0)
                return 0
            end

            if temp != "UNKNOWN"
                for i in 1:maxhb
                    code = cnhb[i]
                    if temp[1:min(8,length(temp))] == code[1:min(8,length(code))]
                        kard2_ref[]   = code[1:min(8,length(code))]
                        array2_ref[]  = Float32(i)
                        return i
                    end
                end
                # no match
                kard2_ref[] = temp
                return -1
            end
            # UNKNOWN case: return 0 (handled as ihb=0 → default below in HABTYP)
            kard2_ref[] = temp
            array2_ref[] = Float32(0)
            return 0
        else
            # numeric code given: validate and set kard2
            kard2_ref[] = cnhb[ihb][1:min(8,length(cnhb[ihb]))]
            return ihb
        end
    else
        return -1
    end
end

# ---------------------------------------------------------------------------
# HABTYP — translate habitat code keyword field into KODTYP global
# ---------------------------------------------------------------------------
function HABTYP(kard2::AbstractString, array2::Real)
    debug = DBCHK(false, "HABTYP", Int32(6), ICYC)
    if debug
        @printf(io_units[Int(JOSTND)], "ENTERING HABTYP CYCLE,KODTYP,KODFOR,KARD2,ARRAY2= %d %d %d %s %g\n",
            ICYC, KODTYP, KODFOR, kard2, array2)
    end

    kard2_ref  = Ref{String}(String(kard2))
    array2_ref = Ref(Float32(array2))
    npa        = length(_HABTYP_SNECU)

    ihb = HBDECD(_HABTYP_SNECU, npa, array2_ref, kard2_ref)

    if debug
        @printf(io_units[Int(JOSTND)], "AFTER HAB DECODE,KODTYP= %d\n", ihb)
    end

    if ihb > 0
        global PCOM   = rpad(_HABTYP_SNECU[ihb], 8)[1:8]
        global KODTYP = Int32(ihb)
        global ITYPE  = Int32(ihb)
        if LSTART
            @printf(io_units[Int(JOSTND)], "\n            ECOLOGICAL UNIT CODE USED IN THIS PROJECTION IS %-8s\n", PCOM)
        end
    elseif ihb == 0
        # no match, treat array2 as index
        a2 = Int(floor(array2_ref[]))
        if a2 > 0 && a2 <= npa
            global KODTYP = Int32(a2)
            global ITYPE  = Int32(a2)
            global PCOM   = rpad(_HABTYP_SNECU[a2], 8)[1:8]
        else
            global ITYPE  = Int32(122)
            ERRGRO(true, Int32(14))
            global KODTYP = ITYPE
            global PCOM   = rpad(_HABTYP_SNECU[Int(ITYPE)], 8)[1:8]
            if LSTART
                @printf(io_units[Int(JOSTND)], "\n            ECOLOGICAL UNIT CODE USED IN THIS PROJECTION IS %-8s\n", PCOM)
            end
        end
    else
        # no match, treat array2 as index
        a2 = Int(floor(Float32(array2)))
        if a2 > 0 && a2 <= npa
            global KODTYP = Int32(a2)
            global ITYPE  = Int32(a2)
            global PCOM   = rpad(_HABTYP_SNECU[a2], 8)[1:8]
        else
            global ITYPE  = Int32(122)
            ERRGRO(true, Int32(14))
            global KODTYP = ITYPE
            global PCOM   = rpad(_HABTYP_SNECU[Int(ITYPE)], 8)[1:8]
            if LSTART
                @printf(io_units[Int(JOSTND)], "\n            ECOLOGICAL UNIT CODE USED IN THIS PROJECTION IS %-8s\n", PCOM)
            end
        end
    end

    global ICL5  = KODTYP

    if debug
        @printf(io_units[Int(JOSTND)], "LEAVING HABTYP KODTYP,ITYPE,ICL5,KARD2 PCOM =%d %d %d %s %s\n",
            KODTYP, ITYPE, ICL5, kard2_ref[], PCOM)
    end
    return nothing
end
