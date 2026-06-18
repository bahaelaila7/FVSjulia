# base/esin.jl — ESIN: option processor for the regeneration establishment model
# Translated from: bin/FVSsn_buildDir/esin.f (748 lines)
#
# CHUNK B scope: the ESTAB packet reader + the PLANT/NATURAL/END options, which is
# all snt01's BARE stand needs (ESTAB 1992 / PLANT 1992 13 400 / PLANT 1992 3 400).
# The other ~24 establishment keywords (BURNPREP, TALLY, SPROUT, …) are NOT used by
# snt01 and are routed to a safe skip (logged; consumes the card, loops back).
#
# ESIN is called once with the ESTAB keyword (paskey); it then reads the following
# keyword cards itself via KEYRDR until END.

const _ESIN_TABLE = String[
    "END", "PLANT", "NATURAL", "BURNPREP", "MECHPREP", "OUTPUT",
    "SPECMULT", "BUDWORM", "EZCRUISE", "PLOTINFO", "TALLYONE",
    "TALLYTWO", "STOCKADJ", "HABGROUP", "HTADJ", "TALLY", "ESRANSD",
    "PASSALL", "RESETAGE", "MINPLOTS", "INGROW", "NOINGROW",
    "NOAUTALY", "AUTALLY", "THRSHOLD", "SPROUT", "NOSPROUT",
    "ESTAB", "ADDTREES"]

function ESIN(paskey::AbstractString, array::Vector{Float32},
              lnotbk::Vector{Bool}, kard::Vector{String}, lkecho::Bool)
    debug = DBCHK(false, "ESIN", Int32(4), Int(ICYC))
    table = [rpad(s, 8) for s in _ESIN_TABLE]

    keywrd = rpad(paskey, 8)
    ltally = false
    lmode_r = Ref(false); OPMODE(lmode_r); lmode = lmode_r[]

    # ---- process the leading ESTAB keyword: set the date of disturbance ----
    if lmode
        if lnotbk[1]
            RCDSET(Int32(10), true)
            @printf(io_units[Int(JOSTND)],
                "\n********   WARNING:  DATE OF DISTURBANCE IS IGNORED.\n")
        end
        global IDSDAT = Int32(0)
    else
        if lnotbk[1]
            global IDSDAT = Int32(trunc(array[1]))
            if lkecho
                @printf(io_units[Int(JOSTND)], "%sDATE OF DISTURBANCE=%5d\n", " "^11, IDSDAT)
            end
        else
            global IDSDAT = Int32(-1)
        end
    end

    iprmpt = Int32(0)
    kode   = Int32(0)
    number = Int32(0)
    iactk  = Int32(0)

    # =======================================================================
    @label label_10
    keywrd, lnotbk, array, irecnt_new, kode, kard, lflag_new =
        KEYRDR(IREAD, JOSTND, debug, lnotbk, array, IRECNT, kode, kard, LFLAG, lkecho)
    global IRECNT = irecnt_new
    global LFLAG  = lflag_new

    iprmpt = kode < Int32(0) ? Int32(-kode) : Int32(0)

    if kode <= Int32(0); @goto label_30; end
    if kode == Int32(2); ERRGRO(false, Int32(2)); end
    if fvsGetRtnCode() != Int32(0); return; end
    ERRGRO(true, Int32(6))
    @goto label_10

    @label label_30
    number, kode = FNDKEY(keywrd, table, JOSTND)
    if kode == Int32(1)
        ERRGRO(true, Int32(1))
        if fvsGetRtnCode() != Int32(0); return; end
        @goto label_10
    end

    # ---- dispatch (Fortran computed GOTO over 29 options) ----
    if number == Int32(1) || number == Int32(28)
        @goto label_1000   # END & ESTAB
    elseif number == Int32(2)
        iactk = Int32(430)
        @goto label_1205   # PLANT
    elseif number == Int32(3)
        iactk = Int32(431)  # NATURAL
        global STOADJ = Float32(0.0)
        global LAUTAL = false
        global LINGRW = false
        @goto label_1205
    else
        # Establishment keyword not needed by snt01 (BURNPREP/TALLY/SPROUT/…).
        if debug
            @printf(io_units[Int(JOSTND)],
                " ESIN: establishment keyword '%s' (opt %d) not implemented; skipped.\n",
                keywrd, number)
        end
        @goto label_10
    end

    # ----------------------------- END & ESTAB -----------------------------
    @label label_1000
    if !ltally
        if lmode
            if IDSDAT == Int32(0); global IDSDAT = Int32(1); end
            kode_r = Ref(Int32(0))
            OPNEW(kode_r, IDSDAT, Int32(427), Int32(0), array)
        elseif IDSDAT != Int32(-1)
            array[7] = Float32(IDSDAT)
            kode_r = Ref(Int32(0))
            OPNEW(kode_r, max(Int32(1), IDSDAT), Int32(427), Int32(1), @view(array[7:end]))
        end
    end
    if number == Int32(1)
        if lkecho
            @printf(io_units[Int(JOSTND)], "\n%-8s   END OF ESTABLISHMENT KEYWORDS\n", keywrd)
        end
        # IDSDAT=-9999 signals ESNUTR that the date was never set; -1 otherwise.
        global IDSDAT = ltally ? Int32(-1) : Int32(-9999)
        return
    end
    # A further ESTAB keyword (option 28): update date and keep reading.
    ltally = false
    if lmode
        if lnotbk[1]; RCDSET(Int32(10), true); end
        global IDSDAT = Int32(0)
    elseif lnotbk[1]
        global IDSDAT = Int32(trunc(array[1]))
    end
    @goto label_10

    # ------------------------------- PLANT/NATURAL --------------------------
    @label label_1205
    idt = lnotbk[1] ? Int32(trunc(array[1])) : Int32(1)

    if iprmpt > Int32(0)
        # PARMS feature — not used by snt01; OPNEWC path deferred.
        @goto label_10
    end

    is_ref = Ref(Int32(0))
    SPDECD(Int32(2), is_ref, view(NSP, :, 1), JOSTND, Ref(IRECNT), keywrd, array, kard)
    is = is_ref[]
    if is == Int32(-999); @goto label_10; end

    if array[3] <= Float32(0.0)
        KEYDMP(JOSTND, IRECNT, keywrd, array, kard)
        ERRGRO(true, Int32(4))
        @goto label_10
    end

    if array[4] < Float32(0.001) || array[4] > Float32(100.0)
        array[4] = Float32(100.0)
    end

    kode_r = Ref(Int32(0))
    OPNEW(kode_r, idt, iactk, Int32(6), @view(array[2:end]))
    if kode_r[] > Int32(0); @goto label_10; end

    if lkecho
        @printf(io_units[Int(JOSTND)],
            "\n%-8s   DATE/CYCLE=%5d; SPECIES CODE=%3d; TREES/ACRE=%6.0f; %% SURVIVAL=%6.2f\n%sAGE=%5.1f; AVE. HEIGHT=%5.1f; SHADE CODE=%5.1f\n",
            keywrd, idt, is, array[3], array[4], " "^11, array[5], array[6], array[7])
    end
    @goto label_10
end
