# extensions/fire/fmin.jl — Fire keyword processor + helper subroutines
# Translated from fire/fmin.f (2732 lines)
# FMIN: fire extension keyword processor, KWCNT=54 keywords
# Also contains: FMKEYDMP, FMKEYRDR, FMKEY

const _FMIN_TABLE = ["SALVSP  ","END     ","SVIMAGES","BURNREPT","MOISTURE",
                     "SIMFIRE ","FLAMEADJ","POTFIRE ","SNAGFALL","SNAGBRK ",
                     "SNAGDCAY","SNAGOUT ","SNAGCLAS","LANDOUT ","FUELOUT ",
                     "FUELDCAY","DUFFPROD","MOREOUT ","FUELPOOL","SALVAGE ",
                     "FUELINIT","SNAGINIT","PILEBURN","SNAGPBN ","FUELTRET",
                     "STATFUEL","FUELREPT","MORTREPT","FUELMULT","POTFMOIS",
                     "SNAGSUM ","MORTCLAS","DROUGHT ","FUELMOVE","POTFWIND",
                     "POTFTEMP","SNAGPSFT","FUELMODL","DEFULMOD","CANCALC ",
                     "POTFSEAS","POTFPAB ","SOILHEAT","CARBREPT","CARBCUT ",
                     "CARBCALC","CANFPROF","FUELFOTO","FIRECALC","FMODLIST",
                     "DWDVLOUT","DWDCVOUT","FUELSOFT","FMORTMLT"]

const _FMIN_PHOTOREF = ["Fischer INT-96                      ",
                        "Fischer INT-97                      ",
                        "Fischer INT-98                      ",
                        "                                    ",
                        "Koski and Fischer INT-46            ",
                        "Maxwell and Ward PNW-52             ",
                        "Blonski and Schramel PSW-56         ",
                        "Maxwell and Ward PNW-105            ",
                        "Ottmar and Hardy PNW-GTR-231        ",
                        "                                    ",
                        "Maxwell A-89-6-82                   ",
                        "Southwestern region compilation     ",
                        "Maxwell and Ward PNW-51             ",
                        "Ottmar and others Volume I          ",
                        "Ottmar and others Volume I          ",
                        "Ottmar and Vihnanek Volume II / IIa ",
                        "Ottmar and others Volume III        ",
                        "Ottmar and others Volume V / Va     ",
                        "Ottmar and others Volume VI / VIa   ",
                        "Maxwell A-89-1-90                   ",
                        "Ottmar and others Volume IV         ",
                        "Wright and others PNW-GTR-545       ",
                        "Ottmar and others PNW-GTR-258       ",
                        "Lynch and Horton NA-FR-25           ",
                        "Wilcox and others NA-FR-22          ",
                        "Scholl and Waldrop GTR-SRS-26       ",
                        "Ottmar and others Volume VII        ",
                        "Maxwell and Ward PNW-95             ",
                        "Sanders and Van Lear GTR-SE-49      ",
                        "Wade and others GTR-SE-82           ",
                        "Blank GTR-NC-77                     ",
                        "Popp and Lundquist RMRS-GTR-172     "]

function FMKEYDMP(iout::Int32, irecnt::Int32, keywrd::String,
                  array::Vector{Float32}, kard::Vector{String}, nvals::Int32)
    nv = Int(nvals)
    @printf(io_units[iout], "\nCARD NUM =%8d; KEYWORD FIELD = '%8s'\n     NUMBERS=",
            irecnt, keywrd)
    for i in 1:nv
        @printf(io_units[iout], "%13.7f", array[i])
    end
    @printf(io_units[iout], "\n     CHARS  =")
    for i in 1:nv
        @printf(io_units[iout], "'%10s'%s", kard[i], i < nv ? "," : "")
    end
    @printf(io_units[iout], "\n")
    return
end

function FMKEYRDR(inunit::Int32, iout::Int32, ldebug::Bool,
                  keywrd::Ref{String}, lnotbk::Vector{Bool},
                  array::Vector{Float32}, irecnt::Ref{Int32},
                  kode::Ref{Int32}, kard::Vector{String},
                  lflag::Ref{Bool}, nvals::Int32)
    lcom = false
    nv = Int(nvals)
    while true
        local record::String
        try
            record = readline(io_units[inunit])
        catch
            kode[] = Int32(2)
            return
        end
        irecnt[] += Int32(1)
        # Pad to at least 130 chars
        length(record) < 130 && (record = rpad(record, 130))

        # Skip '!' comment lines
        record[1] == '!' && continue

        # Skip blank lines when lflag is set
        lflag[] && all(==(' '), record) && continue

        # Print heading on first real keyword line
        tmp8 = uppercase(record[1:min(8,length(record))])
        if lflag[]
            GROHED(iout)
            @printf(io_units[iout], "\n%s\n\n%49s\n\n%s\n KEYWORD    PARAMETERS:\n%s\n",
                    "-"^130, "OPTIONS SELECTED BY INPUT", "-"^130,
                    "--------   " * "-"^119)
            lflag[] = false
        end

        # Handle pure comment lines (start with '*') and blank lines
        if record[1] == '*' || all(==(' '), record)
            if !lcom
                @printf(io_units[iout], "\n\n")
                lcom = true
            end
            nlb = something(findlast(!isspace, record), 1)
            @printf(io_units[iout], "%12s%s\n", "", record[1:nlb])
            continue
        else
            lcom = false
        end

        # Handle COMMENT keyword block
        if uppercase(record[1:7]) == "COMMENT"
            @printf(io_units[iout], "\n%s\n", record[1:7])
            while true
                local crec::String
                try
                    crec = readline(io_units[inunit])
                    irecnt[] += Int32(1)
                    length(crec) < 10 && (crec = rpad(crec, 10))
                catch
                    kode[] = Int32(2)
                    return
                end
                if uppercase(crec[1:min(4,length(crec))]) == "END "
                    @printf(io_units[iout], "\n%s\n", crec[1:4])
                    break
                else
                    nlb2 = something(findlast(!isspace, crec), 1)
                    @printf(io_units[iout], "%12s%s\n", "", crec[1:nlb2])
                end
            end
            continue
        end

        # Detect PARMS statement
        nf = nv
        ip = findfirst('P', record[11:end])
        if ip !== nothing
            kw5 = uppercase(record[ip+10:min(ip+14, length(record))])
            if length(kw5) >= 5 && kw5[1:5] == "PARMS"
                nf = (ip % 10 == 0) ? ip ÷ 10 - 1 : ip ÷ 10
            end
        end

        # Decode keyword (columns 1-8)
        keywrd[] = rpad(record[1:min(8,length(record))], 8)

        # Decode numeric fields (columns 11-20, 21-30, ...)
        j = 1
        for i in 1:nf
            j += 10
            fld_end = min(j+9, length(record))
            fld = fld_end >= j ? record[j:fld_end] : ""
            kard[i] = rpad(fld, 10)
            array[i] = 0f0
            # parse if all chars are valid number characters
            valid = true
            for k in 1:length(kard[i])
                c = kard[i][k]
                findfirst(==(c), " .+-eE0123456789") === nothing && (valid = false; break)
            end
            if valid
                s = strip(kard[i])
                s != "" && try array[i] = parse(Float32, s) catch; end
            end
        end

        keywrd[] = UPKEY(keywrd[])
        kode[] = Int32(0)
        for i in 1:nf
            lnotbk[i] = strip(kard[i]) != ""
        end
        if nf < nv
            kode[] = Int32(-(nf+1))
            j2 = nf*10 + 1
            for i in nf+1:nv
                lnotbk[i] = false
                array[i] = 0f0
                fld_end2 = min(j2+9, length(record))
                kard[i] = fld_end2 >= j2 ? rpad(record[j2:fld_end2], 10) : " "^10
                j2 += 10
            end
        end

        ldebug && FMKEYDMP(iout, irecnt[], keywrd[], array, kard, Int32(nv))
        return
    end
end

function FMKEY(key::Int32, paskey::Ref{String})
    if 1 <= Int(key) <= 54
        paskey[] = _FMIN_TABLE[key]
    end
    return
end

function FMIN(icall::Int32, nsp::AbstractMatrix, lkecho::Bool)
    const_kwcnt = Int32(54)

    # local working arrays
    keywrd = Ref{String}("        ")
    kard   = [" "^10 for _ in 1:12]
    array  = zeros(Float32, 12)
    prms   = zeros(Float32, 13)
    aprms  = ["          " for _ in 1:13]
    lnotbk = falses(12)

    kode_r   = Ref{Int32}(0)
    number_r = Ref{Int32}(0)
    irtncd   = Ref{Int32}(0)

    # local scalars
    nvals  = Int32(12)
    iprmpt = Int32(0)
    myact  = Int32(0)
    idt    = Int32(1)
    nparms = Int32(0)
    ii     = Int32(0)
    jsp    = Int32(0)
    ihead  = Int32(0)
    ichng  = Int32(0)
    icls   = Int32(0)
    idec   = Int32(0)
    id     = Int32(0)
    ifire  = Int32(0)
    iarry  = Int32(0)
    key    = Int32(0)
    ifmd   = Int32(0)
    icanpr = Int32(0)
    dkmult = 0f0
    x      = 0f0
    xsum   = 0f0
    lok    = true
    yrs50  = zeros(Float32, 2)
    yrs30  = zeros(Float32, 2)
    mois_  = zeros(Float32, 2, 6)   # local buffer for FMMOIS output

    while true   # label_10 read loop

        nvals = Int32(12)
        FMKEYRDR(IREAD, JOSTND, false, keywrd, lnotbk, array, Ref{Int32}(IRECNT),
                 kode_r, kard, Ref{Bool}(LFLAG), nvals)
        fvsGetRtnCode(irtncd)
        irtncd[] != 0 && return

        kode = kode_r[]
        if kode < 0
            iprmpt = -kode
        else
            iprmpt = Int32(0)
        end

        if kode <= 0
            # label_30
            FNDKEY(number_r, keywrd[], _FMIN_TABLE, const_kwcnt, kode_r, false, JOSTND)
            kode = kode_r[]
            if kode == 0 || kode == 2
                # label_90 — keyword found (or close match), proceed to dispatch
            elseif kode == 1
                ERRGRO(true, Int32(1))
                continue  # GOTO 10
            end
        else
            if kode == 2
                ERRGRO(false, Int32(2))
            end
            fvsGetRtnCode(irtncd)
            irtncd[] != 0 && return
            ERRGRO(true, Int32(6))
            continue  # GOTO 10
        end

        # label_90 — signal fire model active and dispatch
        LFMON = true
        number = Int(number_r[])

        # ── OPTION 1: SALVSP ──────────────────────────────────────────────────
        if number == 1
            if icall == 2
                @printf(io_units[JOSTND], "\n%8s   ***KEYWORD IS A STAND-LEVEL KEYWORD ONLY AND CANNOT BE INCLUDED WITH THE LANDSCAPE-LEVEL KEYWORDS\n", keywrd[])
                continue
            end
            myact = Int32(2501)
            idt   = Int32(1)
            lnotbk[1] && (idt = Int32(trunc(array[1])))
            if iprmpt > 0
                if iprmpt != 2
                    FMKEYDMP(JOSTND, IRECNT, keywrd[], array, kard, nvals)
                    ERRGRO(true, Int32(25))
                else
                    OPNEWC(kode_r, JOSTND, IREAD, idt, myact, keywrd[], kard, iprmpt, Ref(IRECNT), ICYC)
                    fvsGetRtnCode(irtncd); irtncd[] != 0 && return
                end
                continue
            end
            nparms = Int32(2); prms[1] = 0f0; prms[2] = 0f0
            jsp = Int32(0)
            SPDECD(Int32(2), Ref(jsp), view(nsp,:,1), JOSTND, Ref(IRECNT), keywrd[], array, kard)
            jsp == -999 && continue
            prms[1] = Float32(jsp)
            lnotbk[3] && (prms[2] = array[3])
            prms[2] < 1f0 && (prms[2] = 0f0)
            prms[2] >= 1f0 && (prms[2] = 1f0)
            ilen = 3
            jsp < 0 && (ilen = ISPGRP(-jsp, Int32(92)))
            if prms[2] < 1f0
                lkecho && @printf(io_units[JOSTND], "\n%-8s   DATE/CYCLE %4d SPECIES=%s (CODE=%3d) IS MARKED FOR CUTTING IN SUBSEQUENT SALVAGE OPERATIONS. \n", keywrd[], idt, kard[2][1:ilen], jsp)
            else
                lkecho && @printf(io_units[JOSTND], "\n%-8s   DATE/CYCLE %4d SPECIES=%s (CODE=%3d) IS MARKED TO BE LEFT IN SUBSEQUENT SALVAGE OPERATIONS. \n", keywrd[], idt, kard[2][1:ilen], jsp)
            end
            OPNEW(kode_r, idt, myact, nparms, prms)
            continue

        # ── OPTION 2: END ─────────────────────────────────────────────────────
        elseif number == 2
            lkecho && @printf(io_units[JOSTND], "\n%-8s   END OF FIRE MODEL OPTIONS.\n", keywrd[])
            return

        # ── OPTION 3: SVIMAGES ────────────────────────────────────────────────
        elseif number == 3
            lnotbk[1] && (NFMSVPX = Int32(trunc(array[1])))
            lkecho && @printf(io_units[JOSTND], "\n%-8s   VISUALIZATION IMAGES PER FIRE= %4d\n", keywrd[], NFMSVPX)
            continue

        # ── OPTION 4: BURNREPT ───────────────────────────────────────────────
        elseif number == 4
            IDBRN == 0 && GETID(Ref(IDBRN))
            IFMBRB = IY[1]
            IFMBRE = IY[1] + Int32(999)
            lkecho && @printf(io_units[JOSTND], "\n%-8s   THE BURN CONDITIONS REPORT WILL BE WRITTEN WHEN A FIRE OCCURS.\n", keywrd[])
            continue

        # ── OPTION 5: MOISTURE ────────────────────────────────────────────────
        elseif number == 5
            if icall == 2
                @printf(io_units[JOSTND], "\n%-8s   ***KEYWORD IS A STAND-LEVEL KEYWORD ONLY AND CANNOT BE INCLUDED WITH THE LANDSCAPE-LEVEL KEYWORDS\n", keywrd[])
                continue
            end
            myact = Int32(2505)
            idt = Int32(1); lnotbk[1] && (idt = Int32(trunc(array[1])))
            if iprmpt > 0
                if iprmpt != 2
                    FMKEYDMP(JOSTND, IRECNT, keywrd[], array, kard, nvals)
                    ERRGRO(true, Int32(25))
                else
                    OPNEWC(kode_r, JOSTND, IREAD, idt, myact, keywrd[], kard, iprmpt, Ref(IRECNT), ICYC)
                    fvsGetRtnCode(irtncd); irtncd[] != 0 && return
                end
                continue
            end
            nparms = Int32(7)
            for ii_i in 1:7
                prms[ii_i] = 0f0
                lnotbk[ii_i+1] && (prms[ii_i] = array[ii_i+1])
                if ii_i == 7 && !lnotbk[ii_i+1]
                    prms[7] = prms[6]
                end
            end
            lkecho && @printf(io_units[JOSTND], "\n%-8s   IN DATE/CYCLE %4d FUEL MOISTURE VALUES (%%) WILL BE:\n            1HR: %5.1f 10HR: %5.1f 100HR: %5.1f 3+: %5.1f DUFF: %5.1f LIVE WOODY: %5.0f LIVE HERB: %5.0f\n",
                keywrd[], idt, prms[1], prms[2], prms[3], prms[4], prms[5], prms[6], prms[7])
            OPNEW(kode_r, idt, myact, nparms, prms)
            continue

        # ── OPTION 6: SIMFIRE ────────────────────────────────────────────────
        elseif number == 6
            if icall == 2
                @printf(io_units[JOSTND], "\n%-8s   ***KEYWORD IS A STAND-LEVEL KEYWORD ONLY AND CANNOT BE INCLUDED WITH THE LANDSCAPE-LEVEL KEYWORDS\n", keywrd[])
                continue
            end
            myact = Int32(2506)
            idt = Int32(1); lnotbk[1] && (idt = Int32(trunc(array[1])))
            if iprmpt > 0
                if iprmpt != 2
                    FMKEYDMP(JOSTND, IRECNT, keywrd[], array, kard, nvals)
                    ERRGRO(true, Int32(25))
                else
                    OPNEWC(kode_r, JOSTND, IREAD, idt, myact, keywrd[], kard, iprmpt, Ref(IRECNT), ICYC)
                    fvsGetRtnCode(irtncd); irtncd[] != 0 && return
                end
                continue
            end
            nparms = Int32(6)
            prms[1]=20f0; prms[2]=1f0; prms[3]=70f0; prms[4]=1f0; prms[5]=100f0; prms[6]=1f0
            lnotbk[2] && (prms[1]=array[2]); lnotbk[3] && (prms[2]=array[3])
            lnotbk[4] && (prms[3]=array[4]); lnotbk[5] && (prms[4]=array[5])
            lnotbk[6] && (prms[5]=array[6]); lnotbk[7] && (prms[6]=array[7])
            prms[4] < 0 && (prms[4]=0f0); prms[4] > 1 && (prms[4]=1f0)
            prms[5] < 0 && (prms[5]=0f0); prms[5] > 100 && (prms[5]=100f0)
            prms[6] < 1 && (prms[6]=1f0); prms[6] > 4 && (prms[6]=4f0)
            lkecho && @printf(io_units[JOSTND], "\n%-8s    FIRE CONDITIONS IN DATE/CYCLE %4d WILL BE: WIND: %5.1f MPH.\n            FUEL MOISTURE VALUES WILL USE THE PRESET MOISTURE CONDITION %3.0f\n            TEMPERATURE: %5.0f DEGREES F.\n            MORTALITY CODE: %2.0f (0 = TURN OFF FFE MORTALITY, 1 = FFE ESTIMATES MORTALITY)\n            PERCENTAGE OF THE STAND BURNED: %6.1f\n            SEASON OF THE BURN: %2.0f (1 = EARLY SPRING (COMPACT LEAVES), 2 = BEFORE GREENUP, 3 = AFTER GREENUP, 4 = FALL)\n",
                keywrd[], idt, prms[1], prms[2], prms[3], prms[4], prms[5], prms[6])
            OPNEW(kode_r, idt, myact, nparms, prms)
            continue

        # ── OPTION 7: FLAMEADJ ───────────────────────────────────────────────
        elseif number == 7
            if icall == 2
                @printf(io_units[JOSTND], "\n%-8s   ***KEYWORD IS A STAND-LEVEL KEYWORD ONLY AND CANNOT BE INCLUDED WITH THE LANDSCAPE-LEVEL KEYWORDS\n", keywrd[])
                continue
            end
            myact = Int32(2507)
            idt = Int32(1); lnotbk[1] && (idt = Int32(trunc(array[1])))
            if iprmpt > 0
                if iprmpt != 2
                    FMKEYDMP(JOSTND, IRECNT, keywrd[], array, kard, nvals)
                    ERRGRO(true, Int32(25))
                else
                    OPNEWC(kode_r, JOSTND, IREAD, idt, myact, keywrd[], kard, iprmpt, Ref(IRECNT), ICYC)
                    fvsGetRtnCode(irtncd); irtncd[] != 0 && return
                end
                continue
            end
            nparms = Int32(3)
            prms[1]=1f0; prms[2]=-1f0; prms[3]=-1f0; prms[4]=-1f0
            lnotbk[2] && (prms[1]=array[2]); lnotbk[3] && (prms[2]=array[3])
            lnotbk[4] && (prms[3]=array[4])
            if lnotbk[5]; prms[4]=array[5]; nparms=Int32(4); end
            prms[1] < 0f0 && (prms[1]=1f0)
            prms[2] < 0f0 && (prms[2]=-1f0)
            prms[3] < 0f0 && (prms[3]=-1f0)
            prms[3] > 100f0 && (prms[3]=100f0)
            if prms[2] > 0f0
                lkecho && @printf(io_units[JOSTND], "\n%-8s    IN DATE/CYCLE %4d FLAME LENGTH WILL BE: %6.1f FT.\n", keywrd[], idt, prms[2])
            else
                lkecho && @printf(io_units[JOSTND], "\n%-8s    IN DATE/CYCLE %4d FLAME LENGTH WILL BE CALCULATED BASED ON APPLICABLE CONDITIONS,\n            AND THEN MULTIPLIED BY %7.3f\n", keywrd[], idt, prms[1])
            end
            if prms[3] == -1f0
                lkecho && @printf(io_units[JOSTND], "            THE MODEL PREDICTS THE %% CROWNING.\n")
            else
                lkecho && @printf(io_units[JOSTND], "            %5.1f %% OF THE CROWN WILL UNDERGO CROWNING.\n", prms[3])
            end
            nparms >= 4 && lkecho && @printf(io_units[JOSTND], "            SCORCH HEIGHT =%10.2f\n", prms[4])
            OPNEW(kode_r, idt, myact, nparms, prms)
            continue

        # ── OPTION 8: POTFIRE ────────────────────────────────────────────────
        elseif number == 8
            IDPFLM == 0 && GETID(Ref(IDPFLM))
            if icall == 2
                @printf(io_units[JOSTND], "\n%-8s   ***KEYWORD IS A STAND-LEVEL KEYWORD ONLY AND CANNOT BE INCLUDED WITH THE LANDSCAPE-LEVEL KEYWORDS\n", keywrd[])
                continue
            end
            IPFLMB = IY[1]
            IPFLME = IY[1] + Int32(999)
            lkecho && @printf(io_units[JOSTND], "\n%-8s   THE POTENTIAL FIRE REPORT WILL BE PRINTED.\n", keywrd[])
            continue

        # ── OPTION 9: SNAGFALL ───────────────────────────────────────────────
        elseif number == 9
            jsp = Int32(0)
            SPDECD(Int32(1), Ref(jsp), view(nsp,:,1), JOSTND, Ref(IRECNT), keywrd[], array, kard)
            jsp == -999 && continue
            if jsp != 0
                lnotbk[2] && (FALLX[jsp] = array[2])
                FALLX[jsp] < 0.001f0 && (FALLX[jsp] = 0.001f0)
                lnotbk[3] && (ALLDWN[jsp] = array[3])
                ALLDWN[jsp] < 0f0 && (ALLDWN[jsp] = 0f0)
            else
                for jj in 1:MAXSP
                    lnotbk[2] && (FALLX[jj] = array[2])
                    FALLX[jj] < 0.001f0 && (FALLX[jj] = 0.001f0)
                    lnotbk[3] && (ALLDWN[jj] = array[3])
                    ALLDWN[jj] < 0f0 && (ALLDWN[jj] = 0f0)
                end
                jsp = Int32(1)
            end
            lkecho && @printf(io_units[JOSTND], "\n%-8s   FOR SPECIES %s, THE RATE-OF-FALL CORRECTION MULTIPLIER IS: %6.3f\n            THE SNAG AGE BY WHICH THE LAST 5%% FALL: %6.1f\n",
                keywrd[], kard[1][1:3], FALLX[jsp], ALLDWN[jsp])
            continue

        # ── OPTION 10: SNAGBRK ───────────────────────────────────────────────
        elseif number == 10
            jsp = Int32(0)
            SPDECD(Int32(1), Ref(jsp), view(nsp,:,1), JOSTND, Ref(IRECNT), keywrd[], array, kard)
            jsp == -999 && continue
            yrs50[1] = Float32(trunc(array[2])); yrs50[1] < 1f0 && (yrs50[1]=1f0)
            yrs50[2] = Float32(trunc(array[3])); yrs50[2] < 1f0 && (yrs50[2]=1f0)
            yrs30[1] = Float32(trunc(array[4])); yrs30[1] < 1f0 && (yrs30[1]=1f0)
            yrs30[2] = Float32(trunc(array[5])); yrs30[2] < 1f0 && (yrs30[2]=1f0)
            function _brk_calc!(j, h1, h2, h3, h4, y50, y30, htxsft, htr1, htr2)
                if lnotbk[2]
                    HTX[j,1] = (1f0 - 0.5f0^(1f0/y50[1])) / htr1
                elseif HTX[j,1] != 0f0
                    y50[1] = log(0.5f0) / log(1f0 - min(0.9f0, HTX[j,1]*htr1))
                else
                    y50[1] = 999f0
                end
                if lnotbk[4]
                    y30[1] <= y50[1] && (y30[1] = y50[1] + 0.001f0)
                    HTX[j,2] = (1f0 - (0.3f0/0.5f0)^(1f0/(y30[1]-y50[1]))) / htr2
                elseif HTX[j,2] != 0f0
                    y30[1] = y50[1] + log(0.3f0/0.5f0) / log(1f0 - min(0.9f0, HTX[j,2]*htr2))
                else
                    y30[1] = 999f0
                end
                if lnotbk[3]
                    HTX[j,3] = (1f0 - 0.5f0^(1f0/y50[2])) / (htr1*htxsft)
                elseif HTX[j,3] != 0f0 && htxsft != 0f0
                    y50[2] = log(0.5f0) / log(1f0 - min(0.9f0, HTX[j,3]*htr1*htxsft))
                else
                    y50[2] = 999f0
                end
                if lnotbk[5]
                    y30[2] <= y50[2] && (y30[2] = y50[2] + 0.001f0)
                    HTX[j,4] = (1f0 - (0.3f0/0.5f0)^(1f0/(y30[2]-y50[2]))) / (htr2*htxsft)
                elseif HTX[j,4] != 0f0 && htxsft != 0f0
                    y30[2] = y50[2] + log(0.3f0/0.5f0) / log(1f0 - min(0.9f0, HTX[j,4]*htr2*htxsft))
                else
                    y30[2] = 999f0
                end
            end
            if jsp != 0
                _brk_calc!(jsp, HTX, HTX, HTX, HTX, yrs50, yrs30, HTXSFT, HTR1, HTR2)
            else
                for jj in 1:MAXSP
                    _brk_calc!(jj, HTX, HTX, HTX, HTX, yrs50, yrs30, HTXSFT, HTR1, HTR2)
                end
                jsp = Int32(1)
            end
            lkecho && @printf(io_units[JOSTND], "\n%-8s   FOR SPECIES %s, THE YEARS TO 50%% HT LOSS FOR INITIALLY HARD SNAGS IS: %4d\n            AND FOR INITIALLY SOFT SNAGS IS: %4d\n            YEARS TO THE NEXT 30%% HT LOSS FOR INITIALLY HARD SNAGS: %4d\n            AND FOR INITIALLY SOFT SNAGS IS: %4d\n",
                keywrd[], kard[1][1:3], Int(yrs50[1]), Int(yrs50[2]), Int(yrs30[1]), Int(yrs30[2]))
            continue

        # ── OPTION 11: SNAGDCAY ──────────────────────────────────────────────
        elseif number == 11
            jsp = Int32(0)
            SPDECD(Int32(1), Ref(jsp), view(nsp,:,1), JOSTND, Ref(IRECNT), keywrd[], array, kard)
            jsp == -999 && continue
            if jsp != 0
                lnotbk[2] && (DECAYX[jsp] = array[2])
                DECAYX[jsp] < 0f0 && (DECAYX[jsp] = 0f0)
            else
                for jj in 1:MAXSP
                    lnotbk[2] && (DECAYX[jj] = array[2])
                    DECAYX[jj] < 0f0 && (DECAYX[jj] = 0f0)
                end
                jsp = Int32(1)
            end
            lkecho && @printf(io_units[JOSTND], "\n%-8s   FOR SPECIES %s, THE RATE-OF-DECAY CORRECTION MULTIPLIER IS:%5.3f\n", keywrd[], kard[1][1:3], DECAYX[jsp])
            continue

        # ── OPTION 12: SNAGOUT ───────────────────────────────────────────────
        elseif number == 12
            if icall == 2
                @printf(io_units[JOSTND], "\n%-8s   ***KEYWORD IS A STAND-LEVEL KEYWORD ONLY AND CANNOT BE INCLUDED WITH THE LANDSCAPE-LEVEL KEYWORDS\n", keywrd[])
                continue
            end
            idt = Int32(1); prms[1]=200f0; prms[2]=-1f0; prms[3]=Float32(JSNOUT); prms[4]=0f0
            lnotbk[1] && (idt = Int32(trunc(array[1])))
            lnotbk[2] && (prms[1] = Float32(Int(array[2])))
            lnotbk[4] && (prms[3] = Float32(Int(array[4])))
            lnotbk[5] && (prms[4] = Float32(Int(array[5])))
            lkecho && @printf(io_units[JOSTND], "\n%-8s   THE SNAG LIST WILL BE OUTPUT STARTING IN DATE/CYCLE %4d,\n            FOR %4d YEARS.\n            OUTPUT WILL BE PRINTED TO UNIT %3d\n",
                keywrd[], idt, Int(prms[1]), Int(prms[3]))
            if prms[4] > 0f0
                lkecho && @printf(io_units[JOSTND], "            HEADINGS WILL NOT BE PRINTED.\n")
            else
                lkecho && @printf(io_units[JOSTND], "            HEADINGS WILL BE PRINTED.\n")
            end
            myact = Int32(2512); nparms = Int32(4)
            OPNEW(kode_r, idt, myact, nparms, prms)
            continue

        # ── OPTION 13: SNAGCLAS ──────────────────────────────────────────────
        elseif number == 13
            ichng = Int32(0)
            for icls_i in 1:6
                if lnotbk[icls_i]
                    SNPRCL[icls_i] = array[icls_i]
                    ichng = Int32(icls_i)
                    SNPRCL[icls_i] > 36f0 && SNPRCL[icls_i] != 999f0 && (SNPRCL[icls_i] = 36f0)
                end
            end
            ichng > 0 && for icls_i in (ichng+1):6; SNPRCL[icls_i] = 999f0; end
            lkecho && @printf(io_units[JOSTND], "\n%-8s   THE LOWER BOUNDARY FOR EACH DBH CLASS FOR PRINTING THE SNAG OUTPUT (IN INCHES): \n            %s\n",
                keywrd[], join(["CLASS$i=$(SNPRCL[i])" for i in 1:6], "; "))
            continue

        # ── OPTION 14: LANDOUT ───────────────────────────────────────────────
        elseif number == 14
            if icall == 1
                @printf(io_units[JOSTND], "\n%-8s   ***KEYWORD IS A LANDSCAPE-LEVEL KEYWORD ONLY\n", keywrd[])
                continue
            end
            JLOUT[1]=Int32(36); JLOUT[2]=Int32(37); JLOUT[3]=Int32(38)
            PLSIZ[1]=Int32(4);  PLSIZ[2]=Int32(8)
            ihead = Int32(0)
            lnotbk[1] && (JLOUT[1] = Int32(trunc(array[1])))
            lnotbk[2] && (JLOUT[2] = Int32(trunc(array[2])))
            lnotbk[3] && (JLOUT[3] = Int32(trunc(array[3])))
            lnotbk[4] && (PLSIZ[1] = Int32(trunc(array[4])))
            lnotbk[5] && (PLSIZ[2] = Int32(trunc(array[5])))
            lnotbk[6] && (ihead = Int32(trunc(array[6])))
            ihead != 0 && (LANHED = false)
            if JLOUT[1] > 0 || JLOUT[2] > 0 || JLOUT[3] > 0
                lkecho && @printf(io_units[JOSTND], "\n%-8s   THE FOLLOWING LANDSCAPE-LEVEL REPORTS WILL BE PRINTED EACH YEAR: \n", keywrd[])
                JLOUT[1]>0 && lkecho && @printf(io_units[JOSTND], "                 LOADING CATEGORIES FOR FUEL AND SNAGS, UNIT: %3d\n", JLOUT[1])
                JLOUT[2]>0 && lkecho && @printf(io_units[JOSTND], "                 PERCENT OF LANDSCAPE USING EACH FUEL MODEL, UNIT: %3d\n", JLOUT[2])
                JLOUT[3]>0 && lkecho && @printf(io_units[JOSTND], "                 FIRE EFFECTS & POTENTIAL FLAME LENGTH INFO, UNIT: %3d\n                 THE AREA WILL BE GROUPED INTO FLAME LENGTHS THAT ARE ABOVE OR BELOW %3d FEET AND ABOVE %3d FEET.\n", JLOUT[3], PLSIZ[1], PLSIZ[2])
                !LANHED && lkecho && @printf(io_units[JOSTND], "            TABLE HEADINGS WILL NOT BE PRINTED.\n")
            else
                lkecho && @printf(io_units[JOSTND], "\n%-8s     NO LANDSCAPE-LEVEL REPORTS WILL BE PRINTED\n", keywrd[])
            end
            continue

        # ── OPTION 15: FUELOUT ───────────────────────────────────────────────
        elseif number == 15
            if icall == 2
                @printf(io_units[JOSTND], "\n%-8s   ***KEYWORD IS A STAND-LEVEL KEYWORD ONLY AND CANNOT BE INCLUDED WITH THE LANDSCAPE-LEVEL KEYWORDS\n", keywrd[])
                continue
            end
            IDFLAL == 0 && GETID(Ref(IDFLAL))
            IFLALB = IY[1]
            IFLALE = IY[1] + Int32(999)
            lkecho && @printf(io_units[JOSTND], "\n%-8s   THE ALL FUELS REPORT WILL BE PRINTED.\n", keywrd[])
            continue

        # ── OPTION 16: FUELDCAY ──────────────────────────────────────────────
        elseif number == 16
            idec = Int32(0)
            if lnotbk[1]
                id = Int32(trunc(array[1])); idec = id
                idec > 4 && (idec = Int32(4)); idec <= 0 && (idec = Int32(1))
                lnotbk[2] && (DKR[10,idec] = array[2])
                lnotbk[3] && (DKR[11,idec] = array[3])
                lnotbk[4] && (DKR[1,idec]  = array[4])
                lnotbk[5] && (DKR[2,idec]  = array[5])
                lnotbk[6] && (DKR[3,idec]  = array[6])
                if lnotbk[7]
                    for ki in 4:9; DKR[ki,idec] = array[7]; end
                end
                lnotbk[2] && (SETDECAY[10,idec] = array[2])
                lnotbk[3] && (SETDECAY[11,idec] = array[3])
                lnotbk[4] && (SETDECAY[1,idec]  = array[4])
                lnotbk[5] && (SETDECAY[2,idec]  = array[5])
                lnotbk[6] && (SETDECAY[3,idec]  = array[6])
                if lnotbk[7]
                    for ki in 4:9; SETDECAY[ki,idec] = array[7]; end
                end
                if id < 5
                    for ki in 1:10
                        DKR[ki,idec] > 1f0 && (DKR[ki,idec] = 1f0)
                        TODUFF[ki,idec] = DKR[ki,idec] * PRDUFF[ki,idec]
                    end
                    lkecho && @printf(io_units[JOSTND], "\n%-8s   THE TOTAL DECAY RATES FOR DECAY CLASS%2d WILL BE\n            LITTER: %5.3f DUFF: %5.3f 0-.25: %5.3f .25-1: %5.3f 1-3: %5.3f >3: %5.3f\n",
                        keywrd[], idec, DKR[10,idec], DKR[11,idec], DKR[1,idec], DKR[2,idec], DKR[3,idec], DKR[4,idec])
                else
                    for idec2 in 1:4
                        for kj in 1:11
                            DKR[kj,idec2] = DKR[kj,4]
                            SETDECAY[kj,idec2] = min(SETDECAY[kj,4], 1f0)
                        end
                        for ki in 1:10
                            DKR[ki,idec2] > 1f0 && (DKR[ki,idec2] = 1f0)
                            TODUFF[ki,idec2] = DKR[ki,idec2] * PRDUFF[ki,idec2]
                        end
                    end
                    lkecho && @printf(io_units[JOSTND], "\n%-8s   THE TOTAL DECAY RATES FOR ALL DECAY CLASSES WILL BE\n            LITTER: %5.3f DUFF: %5.3f 0-.25: %5.3f .25-1: %5.3f 1-3: %5.3f >3: %5.3f\n",
                        keywrd[], DKR[10,4], DKR[11,4], DKR[1,4], DKR[2,4], DKR[3,4], DKR[4,4])
                end
            else
                @printf(io_units[JOSTND], "\n%-8s    **** NO DECAY CLASS WAS SPECIFIED. KEYWORD WILL BE IGNORED!\n", keywrd[])
                ERRGRO(true, Int32(1))
            end
            continue

        # ── OPTION 17: DUFFPROD ──────────────────────────────────────────────
        elseif number == 17
            idec = Int32(0)
            if lnotbk[1]
                id = Int32(trunc(array[1])); idec = id
                idec > 4 && (idec = Int32(4)); idec <= 0 && (idec = Int32(1))
                if lnotbk[7]
                    for ki in 1:10; PRDUFF[ki,idec] = array[7]; end
                end
                lnotbk[2] && (PRDUFF[10,idec] = array[2])
                lnotbk[3] && (PRDUFF[1,idec]  = array[3])
                lnotbk[4] && (PRDUFF[2,idec]  = array[4])
                lnotbk[5] && (PRDUFF[3,idec]  = array[5])
                if lnotbk[6]
                    for ki in 4:9; PRDUFF[ki,idec] = array[6]; end
                end
                if id <= 4
                    for ki in 1:10
                        PRDUFF[ki,idec] > 1f0 && (PRDUFF[ki,idec] = 1f0)
                        PRDUFF[ki,idec] < 0f0 && (PRDUFF[ki,idec] = 0f0)
                        TODUFF[ki,idec] = PRDUFF[ki,idec] * DKR[ki,idec]
                    end
                    lkecho && @printf(io_units[JOSTND], "\n%-8s   THE PROPORTION OF THE DECOMPOSING  MATERIAL WHICH GOES TO DUFF IN DECAY POOL %2d IS:\n            LITTER: %4.2f 0-.25: %4.2f .25-1: %4.2f 1-3: %4.2f >3: %4.2f\n",
                        keywrd[], idec, PRDUFF[10,idec], PRDUFF[1,idec], PRDUFF[2,idec], PRDUFF[3,idec], PRDUFF[4,idec])
                else
                    for ki in 1:10, idec2 in 1:4
                        PRDUFF[ki,idec2] = PRDUFF[ki,4]
                        PRDUFF[ki,idec2] > 1f0 && (PRDUFF[ki,idec2] = 1f0)
                        PRDUFF[ki,idec2] < 0f0 && (PRDUFF[ki,idec2] = 0f0)
                        TODUFF[ki,idec2] = PRDUFF[ki,idec2] * DKR[ki,idec2]
                    end
                    lkecho && @printf(io_units[JOSTND], "\n%-8s   THE PROPORTION OF THE DECOMPOSING  MATERIAL WHICH GOES TO DUFF IS\n            LITTER: %4.2f 0-.25: %4.2f .25-1: %4.2f 1-3: %4.2f >3: %4.2f\n",
                        keywrd[], PRDUFF[10,4], PRDUFF[1,4], PRDUFF[2,4], PRDUFF[3,4], PRDUFF[4,4])
                end
            else
                @printf(io_units[JOSTND], "\n%-8s    ****NO DECAY POOL WAS SPECIFIED. KEYWORD WILL BE IGNORED!\n", keywrd[])
            end
            continue

        # ── OPTION 18: MOREOUT ───────────────────────────────────────────────
        elseif number == 18
            JCOUT = Int32(30)
            lkecho && @printf(io_units[JOSTND], "\n%-8s\n", keywrd[])
            continue

        # ── OPTION 19: FUELPOOL ──────────────────────────────────────────────
        elseif number == 19
            jsp = Int32(0)
            SPDECD(Int32(1), Ref(jsp), view(nsp,:,1), JOSTND, Ref(IRECNT), keywrd[], array, kard)
            (jsp == -999 || !lnotbk[2]) && continue
            idec = Int32(trunc(array[2]))
            (idec < 1 || idec > 4) && continue
            if jsp != 0
                DKRCLS[jsp] = idec
            else
                for jj in 1:MAXSP; DKRCLS[jj] = idec; end
                jsp = Int32(1)
            end
            lkecho && @printf(io_units[JOSTND], "\n%-8s   FOR SPECIES %s, THE FUEL DECAY CLASS  HAS BEEN CHANGED TO:%1d\n", keywrd[], kard[1][1:3], DKRCLS[jsp])
            continue

        # ── OPTION 20: SALVAGE ───────────────────────────────────────────────
        elseif number == 20
            if icall == 2
                @printf(io_units[JOSTND], "\n%-8s   KEYWORD IS A STAND-LEVEL KEYWORD ONLY AND CANNOT BE INCLUDED WITH THE LANDSCAPE-LEVEL KEYWORDS\n", keywrd[])
                continue
            end
            myact = Int32(2520)
            idt = Int32(1); lnotbk[1] && (idt = Int32(trunc(array[1])))
            if iprmpt > 0
                if iprmpt != 2
                    FMKEYDMP(JOSTND, IRECNT, keywrd[], array, kard, nvals)
                    ERRGRO(true, Int32(25))
                else
                    OPNEWC(kode_r, JOSTND, IREAD, idt, myact, keywrd[], kard, iprmpt, Ref(IRECNT), ICYC)
                    fvsGetRtnCode(irtncd); irtncd[] != 0 && return
                end
                continue
            end
            nparms = Int32(6)
            prms[1]=0f0; prms[2]=999f0; prms[3]=5f0; prms[4]=1f0; prms[5]=0.9f0; prms[6]=0f0
            lnotbk[2] && (prms[1]=array[2]); lnotbk[3] && (prms[2]=array[3])
            lnotbk[4] && (prms[3]=array[4]); lnotbk[5] && (prms[4]=array[5])
            lnotbk[6] && (prms[5]=array[6]); lnotbk[7] && (prms[6]=array[7])
            prms[4] = Float32(Int(prms[4]))
            (prms[4] > 2f0 || prms[4] < 0f0) && (prms[4] = 0f0)
            prms[5] = min(1f0, max(0f0, prms[5]))
            prms[6] = min(1f0, max(0f0, prms[6]))
            lkecho && @printf(io_units[JOSTND], "\n%-8s   IN DATE/CYCLE %4d THE PROPORTION OF SNAGS THAT ARE BETWEEN %4.0f AND %4.0f\n            INCHES DBH AND HAVE BEEN DEAD LESS THAN %4.0f YEARS AND ARE \n", keywrd[], idt, prms[1], prms[2], prms[3])
            if prms[4] == 1f0
                lkecho && @printf(io_units[JOSTND], "            STILL HARD THAT WILL BE REMOVED AS A SALVAGE CUT IS %5.3f\n", prms[5])
            elseif prms[4] == 2f0
                lkecho && @printf(io_units[JOSTND], "            SOFT THAT WILL BE REMOVED AS A SALVAGE CUT IS %5.3f\n", prms[5])
            else
                lkecho && @printf(io_units[JOSTND], "            EITHER HARD OR SOFT THAT WILL BE REMOVED AS A SALVAGE CUT IS %5.3f\n", prms[5])
            end
            lkecho && @printf(io_units[JOSTND], "            THE PROPORTION OF TREATED SNAGS THAT WILL REMAIN IN THE STAND IS %5.3f\n", prms[6])
            OPNEW(kode_r, idt, myact, nparms, prms)
            continue

        # ── OPTION 21: FUELINIT ──────────────────────────────────────────────
        elseif number == 21
            if icall == 2
                @printf(io_units[JOSTND], "\n%-8s   KEYWORD IS A STAND-LEVEL KEYWORD ONLY AND CANNOT BE INCLUDED WITH THE LANDSCAPE-LEVEL KEYWORDS\n", keywrd[])
                continue
            end
            nparms = Int32(12)
            for pi in 1:12; prms[pi] = -1f0; end
            idt = Int32(1)
            for pi in 1:12; lnotbk[pi] && (prms[pi] = array[pi]); end
            lkecho && @printf(io_units[JOSTND], "\n%-8s   INITIAL HARD FUEL VALUES (TONS/ACRE) ARE (-1.0=NO VALUE SPECIFIED): FUELS <1\"=%5.1f; FUELS 1-3\"=%5.1f\n            FUELS 3-6\"=%5.1f; FUELS 6-12\"=%5.1f; FUELS 12-20\"=%5.1f; LITTER=%5.1f; DUFF=%5.1f\n            FUELS <.25\"=%5.1f; FUELS .25-1\"=%5.1f\n            FUELS 20-35\"=%5.1f; FUELS 35-50\"=%5.1f; FUELS >50\"=%5.1f\n",
                keywrd[], prms[1], prms[2], prms[3], prms[4], prms[5], prms[6], prms[7],
                prms[8], prms[9], prms[10], prms[11], prms[12])
            myact = Int32(2521)
            OPNEW(kode_r, idt, myact, nparms, prms)
            continue

        # ── OPTION 22: SNAGINIT ──────────────────────────────────────────────
        elseif number == 22
            if icall == 2
                @printf(io_units[JOSTND], "\n%-8s   ***KEYWORD IS A STAND-LEVEL KEYWORD ONLY AND CANNOT BE INCLUDED WITH THE LANDSCAPE-LEVEL KEYWORDS\n", keywrd[])
                continue
            end
            idt = Int32(1); nparms = Int32(6)
            for pi in 1:6; prms[pi] = -1f0; end
            jsp = Int32(0)
            SPDECD(Int32(1), Ref(jsp), view(nsp,:,1), JOSTND, Ref(IRECNT), keywrd[], array, kard)
            (jsp == 0 || jsp == -999) && continue
            prms[1] = Float32(jsp)
            lnotbk[2] && (prms[2]=array[2]); lnotbk[3] && (prms[3]=array[3])
            lnotbk[4] && (prms[4]=array[4]); lnotbk[5] && (prms[5]=array[5])
            lnotbk[6] && (prms[6]=array[6])
            lkecho && @printf(io_units[JOSTND], "\n%-8s   INITIAL SNAG CHARACTERISTICS (-1.0=NO VALUE SPECIFIED): SPECIES: %s; DBH AT DEATH (IN): %5.1f\n            HEIGHT AT DEATH (FT): %5.1f; CURRENT HEIGHT: %5.1f; AGE: %4.0f; DENSITY (STEMS/ACRE): %6.1f\n",
                keywrd[], kard[1][1:3], prms[2], prms[3], prms[4], prms[5], prms[6])
            myact = Int32(2522)
            OPNEW(kode_r, idt, myact, nparms, prms)
            continue

        # ── OPTION 23: PILEBURN ──────────────────────────────────────────────
        elseif number == 23
            if icall == 2
                @printf(io_units[JOSTND], "\n%-8s   ***KEYWORD IS A STAND-LEVEL KEYWORD ONLY AND CANNOT BE INCLUDED WITH THE LANDSCAPE-LEVEL KEYWORDS\n", keywrd[])
                continue
            end
            myact = Int32(2523)
            idt = Int32(1); lnotbk[1] && (idt = Int32(trunc(array[1])))
            if iprmpt > 0
                if iprmpt != 2
                    FMKEYDMP(JOSTND, IRECNT, keywrd[], array, kard, nvals)
                    ERRGRO(true, Int32(25))
                else
                    OPNEWC(kode_r, JOSTND, IREAD, idt, myact, keywrd[], kard, iprmpt, Ref(IRECNT), ICYC)
                    fvsGetRtnCode(irtncd); irtncd[] != 0 && return
                end
                continue
            end
            nparms = Int32(5); prms[1] = 1f0
            lnotbk[2] && (prms[1] = array[2])
            if prms[1] == 1f0
                prms[2]=70f0; prms[3]=10f0; prms[4]=80f0; prms[5]=0f0
            else
                prms[2]=100f0; prms[3]=30f0; prms[4]=60f0; prms[5]=0f0
            end
            lnotbk[3] && (prms[2]=array[3]); lnotbk[4] && (prms[3]=array[4])
            lnotbk[5] && (prms[4]=array[5]); lnotbk[6] && (prms[5]=array[6])
            burntype = prms[1] == 1f0 ? "PILE" : "JACKPOT"
            lkecho && @printf(io_units[JOSTND], "\n%-8s   IN DATE/CYCLE %4d A %s BURN WILL OCCUR.\n", keywrd[], idt, burntype)
            lkecho && @printf(io_units[JOSTND], "            PERCENT OF THE STAND AREA FROM WHICH FUEL IS COLLECTED (AFFECTED AREA):%85.0f\n            PERCENT OF THE AFFECTED AREA WHERE THE FUEL IS CONCENTRATED:%85.0f\n            PERCENT OF THE FUEL FROM THE AFFECTED AREA THAT IS COLLECTED:%85.0f\n            PERCENT OF THE TREES IN THE STAND WILL DIE AS A RESULT OF THE FIRE:%85.0f\n",
                prms[2], prms[3], prms[4], prms[5])
            OPNEW(kode_r, idt, myact, nparms, prms)
            continue

        # ── OPTION 24: SNAGPBN ───────────────────────────────────────────────
        elseif number == 24
            lnotbk[1] && (PBSOFT = array[1]); lnotbk[2] && (PBSMAL = array[2])
            lnotbk[3] && (PBTIME = array[3]); lnotbk[4] && (PBSIZE = array[4])
            lnotbk[5] && (PBSCOR = array[5])
            PBSOFT < 0f0 && (PBSOFT = 0f0); PBSOFT > 1f0 && (PBSOFT = 1f0)
            PBSMAL < 0f0 && (PBSMAL = 0f0); PBSMAL > 1f0 && (PBSMAL = 1f0)
            PBTIME < 1f0 && (PBTIME = 1f0)
            PBSIZE < 0f0 && (PBSIZE = 0f0); PBSCOR < 0f0 && (PBSCOR = 0f0)
            lkecho && @printf(io_units[JOSTND], "\n%-8s   THE PROPORTIONS OF SOFT OR SMALL SNAGS TO FALL AFTER A BURN ARE (RESPECTIVELY): %4.2f%5.2f\n            THE NUMBER OF YEARS IN WHICH THEY FALL IS: %4.0f SMALL SNAGS ARE THOSE LESS THAN: %4.0f INCHES DBH.\n            THE THRESHOLD SCORCH HEIGHT FOR THE POST-BURN FALLING IS: %5.1f\n",
                keywrd[], PBSOFT, PBSMAL, PBTIME, PBSIZE, PBSCOR)
            continue

        # ── OPTION 25: FUELTRET ──────────────────────────────────────────────
        elseif number == 25
            if icall == 2
                @printf(io_units[JOSTND], "\n%-8s   ***KEYWORD IS A STAND-LEVEL KEYWORD ONLY AND CANNOT BE INCLUDED WITH THE LANDSCAPE-LEVEL KEYWORDS\n", keywrd[])
                continue
            end
            myact = Int32(2525)
            idt = Int32(1); lnotbk[1] && (idt = Int32(trunc(array[1])))
            if iprmpt > 0
                if iprmpt != 2
                    FMKEYDMP(JOSTND, IRECNT, keywrd[], array, kard, nvals)
                    ERRGRO(true, Int32(25))
                else
                    OPNEWC(kode_r, JOSTND, IREAD, idt, myact, keywrd[], kard, iprmpt, Ref(IRECNT), ICYC)
                    fvsGetRtnCode(irtncd); irtncd[] != 0 && return
                end
                continue
            end
            nparms = Int32(3); prms[1]=0f0; prms[2]=1f0; prms[3]=-1f0
            lnotbk[2] && (prms[1]=array[2]); lnotbk[3] && (prms[2]=array[3])
            lnotbk[4] && (prms[3]=array[4])
            prms[1] < 0f0 && (prms[1]=0f0); prms[1] > 2f0 && (prms[1]=2f0)
            prms[2] < 1f0 && (prms[2]=1f0); prms[2] > 3f0 && (prms[2]=3f0)
            lkecho && @printf(io_units[JOSTND], "\n%-8s   IN DATE/CYCLE %4d FUEL TREATMENT TYPE IS %2d AND HARVEST TYPE %2d WAS USED FOR THE STAND ENTRY.\n",
                keywrd[], idt, Int(prms[1]), Int(prms[2]))
            prms[3] >= 0f0 && lkecho && @printf(io_units[JOSTND], "            MULTIPLIER FOR FUEL DEPTH WILL BE %5.1f\n", prms[3])
            OPNEW(kode_r, idt, myact, nparms, prms)
            continue

        # ── OPTION 26: STATFUEL ──────────────────────────────────────────────
        elseif number == 26
            LDYNFM = false
            lkecho && @printf(io_units[JOSTND], "\n%-8s   THE DYNAMIC FUEL MODEL IS DISABLED. \n", keywrd[])
            continue

        # ── OPTION 27: FUELREPT ──────────────────────────────────────────────
        elseif number == 27
            IDFUL == 0 && GETID(Ref(IDFUL))
            IFMFLB = IY[1]
            IFMFLE = IY[1] + Int32(999)
            lkecho && @printf(io_units[JOSTND], "\n%-8s   THE FUEL CONSUMPTION AND PHYSICAL EFFECTS REPORT WILL BE WRITTEN WHEN A FIRE OCCURS.\n", keywrd[])
            continue

        # ── OPTION 28: MORTREPT ──────────────────────────────────────────────
        elseif number == 28
            IDMRT == 0 && GETID(Ref(IDMRT))
            IFMMRB = IY[1]
            IFMMRE = IY[1] + Int32(999)
            lkecho && @printf(io_units[JOSTND], "\n%-8s   THE TREE MORTALITY REPORT WILL BE WRITTEN WHEN A FIRE OCCURS.\n", keywrd[])
            continue

        # ── OPTION 29: FUELMULT ──────────────────────────────────────────────
        elseif number == 29
            for idec_i in 1:4
                if lnotbk[idec_i]
                    dkmult = array[idec_i]
                    for ki in 1:11
                        DKR[ki,idec_i] = DKR[ki,idec_i] * dkmult
                        DKR[ki,idec_i] > 1f0 && (DKR[ki,idec_i] = 1f0)
                        ki <= 10 && (TODUFF[ki,idec_i] = DKR[ki,idec_i] * PRDUFF[ki,idec_i])
                    end
                else
                    array[idec_i] = 1f0
                end
            end
            lkecho && @printf(io_units[JOSTND], "\n%-8s   THE MULTIPLIERS APPLIED TO THE TOTAL DECAY RATES FOR DECAY RATE CLASS 1-4 ARE %5.3f, %5.3f, %5.3f, %5.3f\n",
                keywrd[], array[1], array[2], array[3], array[4])
            continue

        # ── OPTION 30: POTFMOIS ──────────────────────────────────────────────
        elseif number == 30
            ifire = Int32(0)
            lnotbk[1] && (ifire = Int32(trunc(array[1])))
            ifire > 2 && (ifire = Int32(2)); ifire < 1 && (ifire = Int32(1))
            PRESVL[ifire,1] = 1f0
            mois_start = ifire == 2 ? Int32(3) : Int32(1)
            FMMOIS(mois_start, mois_)
            for iarry_i in 2:8
                if lnotbk[iarry_i]
                    PRESVL[ifire,iarry_i] = array[iarry_i] * 0.01f0
                else
                    if iarry_i < 7
                        PRESVL[ifire,iarry_i] = mois_[1, iarry_i-1]
                    elseif iarry_i == 7
                        PRESVL[ifire,iarry_i] = mois_[2, 1]
                    elseif iarry_i == 8
                        PRESVL[ifire,iarry_i] = PRESVL[ifire,7]
                    end
                end
            end
            fire_label = ifire == 1 ? "SEVERE" : "MODERATE"
            lkecho && @printf(io_units[JOSTND], "\n%-8s   FIRE MOISTURE CONDITIONS FOR CALCULATING %s POTENTIAL FLAME LENGTHS ARE: \n            %% MOISTURE FOR 0-.25\"= %4.0f; 0.25-1\"= %4.0f; 1-3\"= %4.0f; 3+\"= %4.0f; DUFF=%4.0f; LIVE WOODY =%4.0f; LIVE HERB =%4.0f\n",
                keywrd[], fire_label,
                PRESVL[ifire,2]*100f0, PRESVL[ifire,3]*100f0, PRESVL[ifire,4]*100f0,
                PRESVL[ifire,5]*100f0, PRESVL[ifire,6]*100f0, PRESVL[ifire,7]*100f0, PRESVL[ifire,8]*100f0)
            continue

        # ── OPTION 31: SNAGSUM ───────────────────────────────────────────────
        elseif number == 31
            ISNGSM = Int32(-1)
            array[1] >= 0f0 && (ISNGSM = Int32(0))
            if ISNGSM >= 0
                lkecho && @printf(io_units[JOSTND], "\n%-8s   SNAG SUMMARY REPORT REQUESTED\n", keywrd[])
            else
                lkecho && @printf(io_units[JOSTND], "\n%-8s   SNAG SUMMARY REPORT TURNED OFF\n", keywrd[])
            end
            continue

        # ── OPTION 32: MORTCLAS ──────────────────────────────────────────────
        elseif number == 32
            for iarry_i in 1:7
                lnotbk[iarry_i] && (LOWDBH[iarry_i] = array[iarry_i])
            end
            lkecho && @printf(io_units[JOSTND], "\n%-8s   THE LOWER BOUND OF EACH SIZE CLASS USED IN THE MORTALITY REPORT IS:\n            %s\n",
                keywrd[], join(["CLASS$i=$(LOWDBH[i])" for i in 1:7], "; "))
            continue

        # ── OPTION 33: DROUGHT ───────────────────────────────────────────────
        elseif number == 33
            if icall == 2
                @printf(io_units[JOSTND], "\n%-8s   ***KEYWORD IS A STAND-LEVEL KEYWORD ONLY AND CANNOT BE INCLUDED WITH THE LANDSCAPE-LEVEL KEYWORDS\n", keywrd[])
                continue
            end
            myact = Int32(2529)
            idt = Int32(1); lnotbk[1] && (idt = Int32(trunc(array[1])))
            if iprmpt > 0
                if iprmpt != 2
                    FMKEYDMP(JOSTND, IRECNT, keywrd[], array, kard, nvals)
                    ERRGRO(true, Int32(25))
                else
                    OPNEWC(kode_r, JOSTND, IREAD, idt, myact, keywrd[], kard, iprmpt, Ref(IRECNT), ICYC)
                    fvsGetRtnCode(irtncd); irtncd[] != 0 && return
                end
                continue
            end
            nparms = Int32(1); prms[1] = 1f0
            lnotbk[2] && array[2] > 0f0 && (prms[1] = array[2])
            lkecho && @printf(io_units[JOSTND], "\n%-8s   IN DATE/CYCLE %4d DROUGHT/DORMANCY IS SIMULATED FOR %3d YEARS.\n", keywrd[], idt, Int(prms[1]))
            OPNEW(kode_r, idt, myact, nparms, prms)
            continue

        # ── OPTION 34: FUELMOVE ──────────────────────────────────────────────
        elseif number == 34
            if icall == 2
                @printf(io_units[JOSTND], "\n%-8s   ***KEYWORD IS A STAND-LEVEL KEYWORD ONLY AND CANNOT BE INCLUDED WITH THE LANDSCAPE-LEVEL KEYWORDS\n", keywrd[])
                continue
            end
            myact = Int32(2530)
            idt = Int32(1); lnotbk[1] && (idt = Int32(trunc(array[1])))
            if iprmpt > 0
                if iprmpt != 2
                    FMKEYDMP(JOSTND, IRECNT, keywrd[], array, kard, nvals)
                    ERRGRO(true, Int32(25))
                else
                    OPNEWC(kode_r, JOSTND, IREAD, idt, myact, keywrd[], kard, iprmpt, Ref(IRECNT), ICYC)
                    fvsGetRtnCode(irtncd); irtncd[] != 0 && return
                end
                continue
            end
            nparms = Int32(6); ii = Int32(0)
            prms[1] = 6f0
            if lnotbk[2]
                (array[2] < 0f0 || array[2] > 11f0) ? (ii += 1) : (prms[1] = array[2])
            end
            prms[2] = 11f0
            if lnotbk[3]
                (array[3] < 0f0 || array[3] > 11f0) ? (ii += 1) : (prms[2] = array[3])
            end
            Int(prms[1]) == Int(prms[2]) && (ii += 1)
            prms[3] = 0f0
            if lnotbk[4]
                array[4] >= 0f0 ? (prms[3] = array[4]) : (ii += 1)
            end
            prms[4] = 0f0
            if lnotbk[5]
                (array[5] >= 0f0 && array[5] <= 1f0) ? (prms[4] = array[5]) : (ii += 1)
            end
            prms[5] = 9999f0
            if lnotbk[6]
                array[6] >= 0f0 ? (prms[5] = array[6]) : (ii += 1)
            end
            prms[6] = 0f0
            if lnotbk[7]
                array[7] >= 0f0 ? (prms[6] = array[7]) : (ii += 1)
            end
            if ii == 0
                lkecho && @printf(io_units[JOSTND], "\n%-8s   IN DATE/CYCLE %4d FUEL IN SIZE CATEGORY%3d WILL BE MOVED TO\n            SIZE CATEGORY %2d. WHICHEVER OF THE FOLLOWING 4 CRITERIA\n            MOVES THE MOST FUEL, WILL BE USED:\n",
                    keywrd[], idt, Int(prms[1]), Int(prms[2]))
                lkecho && @printf(io_units[JOSTND], "            TONS/ACRE MOVED FROM SOURCE CATEGORY:    %12.3f\n", prms[3])
                lkecho && @printf(io_units[JOSTND], "            PROPORTION MOVED FROM SOURCE CATEGORY:   %12.3f\n", prms[4])
                lkecho && @printf(io_units[JOSTND], "            TONS/ACRE REMAINING IN SOURCE CATEGORY:  %12.3f\n", prms[5])
                lkecho && @printf(io_units[JOSTND], "            FINAL TONS/ACRE IN TARGET CATEGORY:      %12.3f\n", prms[6])
                OPNEW(kode_r, idt, myact, nparms, prms)
            else
                FMKEYDMP(JOSTND, IRECNT, keywrd[], array, kard, nvals)
                ERRGRO(true, Int32(4))
            end
            continue

        # ── OPTION 35: POTFWIND ──────────────────────────────────────────────
        elseif number == 35
            lnotbk[1] && (PREWND[1] = array[1])
            lnotbk[2] && (PREWND[2] = array[2])
            lkecho && @printf(io_units[JOSTND], "\n%-8s   FIRE WIND SPEEDS USED FOR CALCULATING POTENTIAL FLAME LENGTHS ARE\n             FOR SEVERE FIRE: %5.0f AND FOR MODERATE FIRE: %5.0f MPH\n", keywrd[], PREWND[1], PREWND[2])
            continue

        # ── OPTION 36: POTFTEMP ──────────────────────────────────────────────
        elseif number == 36
            lnotbk[1] && (POTEMP[1] = array[1])
            lnotbk[2] && (POTEMP[2] = array[2])
            lkecho && @printf(io_units[JOSTND], "\n%-8s   FIRE TEMPERATURES USED FOR CALCULATING POTENTIAL FLAME LENGTHS ARE\n             FOR SEVERE FIRE: %5.0f AND FOR MODERATE FIRE: %5.0f DEGREES F\n", keywrd[], POTEMP[1], POTEMP[2])
            continue

        # ── OPTION 37: SNAGPSFT ──────────────────────────────────────────────
        elseif number == 37
            jsp = Int32(0)
            SPDECD(Int32(1), Ref(jsp), view(nsp,:,1), JOSTND, Ref(IRECNT), keywrd[], array, kard)
            jsp == -999 && continue
            if jsp != 0
                if lnotbk[2]
                    PSOFT[jsp] = array[2]
                    PSOFT[jsp] < 0f0 && (PSOFT[jsp] = 0f0)
                    PSOFT[jsp] > 1f0 && (PSOFT[jsp] = 1f0)
                end
            else
                for jj in 1:MAXSP
                    lnotbk[2] && (PSOFT[jj] = array[2])
                    PSOFT[jj] < 0f0 && (PSOFT[jj] = 0f0)
                    PSOFT[jj] > 1f0 && (PSOFT[jj] = 1f0)
                end
                jsp = Int32(1)
            end
            lkecho && @printf(io_units[JOSTND], "\n%-8s   FOR SPECIES %s, THE PROPORTION OF SNAGS THAT ARE SOFT AT THE TIME THEY ARE CREATED:%4.2f\n", keywrd[], kard[1][1:3], PSOFT[jsp])
            continue

        # ── OPTION 38: FUELMODL ──────────────────────────────────────────────
        elseif number == 38
            myact = Int32(2538); nparms = Int32(8); idt = Int32(1)
            lnotbk[1] && (idt = Int32(trunc(array[1])))
            if iprmpt > 0
                if iprmpt != 2
                    FMKEYDMP(JOSTND, IRECNT, keywrd[], array, kard, nvals)
                    ERRGRO(true, Int32(25))
                else
                    OPNEWC(kode_r, JOSTND, IREAD, idt, myact, keywrd[], kard, iprmpt, Ref(IRECNT), ICYC)
                    fvsGetRtnCode(irtncd); irtncd[] != 0 && return
                end
                continue
            end
            nparms = Int32(0)
            for pi in 1:6; prms[pi] = array[pi+1]; end
            # Read supplemental record for PRMS(7..8)
            try
                IRECNT += Int32(1)
                supline = readline(io_units[IREAD])
                length(supline) < 20 && (supline = rpad(supline, 20))
                s7 = strip(supline[1:10]);  prms[7] = s7 != "" ? parse(Float32, s7) : 0f0
                s8 = strip(supline[11:20]); prms[8] = s8 != "" ? parse(Float32, s8) : 0f0
            catch
                FMKEYDMP(JOSTND, IRECNT, keywrd[], array, kard, nvals)
                ERRGRO(true, Int32(4))
                continue
            end
            # Count valid fuel models (pairs: model_num, weight; model_num must be 1..MXDFMD)
            pind = 1
            while pind <= 7
                if prms[pind] > 0f0 && prms[pind] <= Float32(MXDFMD)
                    nparms = Int32(nparms + 2)
                    prms[pind+1] <= 0f0 && (prms[pind+1] = 1f0)
                else
                    break
                end
                pind += 2
            end
            if nparms == 0
                lkecho && @printf(io_units[JOSTND], "\n%-8s   IN DATE/CYCLE %4d AUTOMATIC FUEL MODEL SELECTION WILL BE USED.\n \n", keywrd[], idt)
            else
                # Scale weights to sum to 1
                x = sum(prms[i] for i in 2:2:nparms)
                x = 1f0 / x
                for pi in 2:2:nparms; prms[pi] *= x; end
                lkecho && @printf(io_units[JOSTND], "\n%-8s   IN DATE/CYCLE %4d THE FUEL MODELS AND WEIGHTS THAT WILL BE USED ARE:\n", keywrd[], idt)
                for pi in 1:2:nparms
                    lkecho && @printf(io_units[JOSTND], "            MODEL %3d: %6.1f%%\n", Int(prms[pi]), 100f0*prms[pi+1])
                end
            end
            OPNEW(kode_r, idt, myact, nparms, prms)
            continue

        # ── OPTION 39: DEFULMOD ──────────────────────────────────────────────
        elseif number == 39
            myact = Int32(2539); idt = Int32(1)
            if lnotbk[1]
                i_val = Int32(trunc(array[1]))
                i_val >= 0 && (idt = i_val)
            end
            if iprmpt > 0
                if iprmpt != 2
                    FMKEYDMP(JOSTND, IRECNT, keywrd[], array, kard, nvals)
                    ERRGRO(true, Int32(25))
                else
                    OPNEWC(kode_r, JOSTND, IREAD, idt, myact, keywrd[], kard, iprmpt, Ref(IRECNT), ICYC)
                    fvsGetRtncd(irtncd); irtncd[] != 0 && return
                end
                continue
            end
            nparms = Int32(13)
            for pi in 1:13; prms[pi] = -1f0; end
            # Read supplemental record (7A10) for fields 7-13
            try
                IRECNT += Int32(1)
                supline = rpad(readline(io_units[IREAD]), 70)
                for pi in 7:13
                    off = (pi-7)*10+1
                    aprms[pi] = rpad(supline[off:min(off+9,70)], 10)
                    strip(aprms[pi]) != "" && (prms[pi] = parse(Float32, strip(aprms[pi])))
                end
            catch
                FMKEYDMP(JOSTND, IRECNT, keywrd[], array, kard, nvals)
                ERRGRO(true, Int32(4))
                continue
            end
            lok = true
            ifmd = Int32(0)
            if lnotbk[2]
                ifmd2 = Int32(trunc(array[2]))
                if ifmd2 >= 1 && ifmd2 <= MXDFMD
                    prms[1] = Float32(ifmd2); ifmd = ifmd2
                else
                    lok = false
                end
            end
            if lok
                for pi in 2:4
                    if lnotbk[pi+1]; prms[pi] = array[pi+1]
                    else; prms[pi] = SURFVL[ifmd,1,pi-1]; end
                end
                if lnotbk[6]; prms[5] = array[6]; else; prms[5] = SURFVL[ifmd,2,1]; end
                if lnotbk[7]; prms[6] = array[7]; else; prms[6] = FMLOAD[ifmd,1,1]; end
                for pi in 7:8
                    prms[pi] < 0f0 && (prms[pi] = FMLOAD[ifmd,1,pi-5])
                end
                prms[9]  < 0f0 && (prms[9]  = FMLOAD[ifmd,2,1])
                prms[10] < 0f0 && (prms[10] = FMDEP[ifmd])
                prms[11] < 0f0 && (prms[11] = MOISEX[ifmd])
                prms[12] < 0f0 && (prms[12] = SURFVL[ifmd,2,2])
                prms[13] < 0f0 && (prms[13] = FMLOAD[ifmd,2,2])
            end
            for pi in 2:5
                prms[pi] < 0f0 && (lok = false; break)
            end
            if lok
                xsum = sum(prms[pi] for pi in 6:9) + prms[13]
                xsum < 0.0001f0 && (lok = false)
            end
            lok && prms[10] <= 0f0 && (lok = false)
            lok && (prms[11] < 0f0 || prms[11] > 1f0) && (lok = false)
            if lok
                lkecho && @printf(io_units[JOSTND], "\n%-8s   IN DATE/CYCLE %4d THE VALUES FOR FUEL MODEL%3d WILL BE: \n            SURFACE TO VOL RATIO:\n                (<0.25\") = %6.0f\n               (0.25-1\") = %6.0f\n                  (1-3\") = %6.0f\n            (LIVE WOODY) = %6.0f\n             (LIVE HERB) = %6.0f\n            FUEL LOADING:\n                (<0.25\") = %7.4f\n               (0.25-1\") = %7.4f\n                  (1-3\") = %7.4f\n            (LIVE WOODY) = %7.4f\n             (LIVE HERB) = %7.4f\n            DEPTH = %6.3f\n            MOISTURE OF EXTINCTION =%7.4f\n",
                    keywrd[], idt, Int(prms[1]), prms[2], prms[3], prms[4], prms[5], prms[12],
                    prms[6], prms[7], prms[8], prms[9], prms[13], prms[10], prms[11])
                OPNEW(kode_r, idt, myact, nparms, prms)
            else
                @printf(io_units[JOSTND], "\n%-8s   ERROR AT CARD %4d OR CARD %4d MAKES IT INVALID. \n", keywrd[], IRECNT-1, IRECNT)
                FMKEYDMP(JOSTND, IRECNT, keywrd[], array, kard, nvals)
                ERRGRO(true, Int32(4))
            end
            continue

        # ── OPTION 40: CANCALC ───────────────────────────────────────────────
        elseif number == 40
            if icall == 2
                @printf(io_units[JOSTND], "\n%-8s   ***KEYWORD IS A STAND-LEVEL KEYWORD ONLY AND CANNOT BE INCLUDED WITH THE LANDSCAPE-LEVEL KEYWORDS\n", keywrd[])
                continue
            end
            lnotbk[1] && (ICBHMT = Int32(trunc(array[1])))
            lnotbk[2] && (CANMHT = array[2])
            lnotbk[3] && (ICANSP = Int32(trunc(array[3])))
            lnotbk[4] && (CBHCUT = array[4])
            lnotbk[5] && (FOLMC  = array[5])
            lkecho && @printf(io_units[JOSTND], "\n%-8s    CALCULATION OF CANOPY BASE HEIGHT AND CANOPY BULK DENSITY WILL USE METHOD %1d,\n            TREES ATLEAST %5.1f FT TALL, SPECIES CATEGORY %1d, A CUTOFF VALUE OF %5.1f,\n            AND A FMC OF %5.1f\n",
                keywrd[], ICBHMT, CANMHT, ICANSP, CBHCUT, FOLMC)
            continue

        # ── OPTION 41: POTFSEAS ──────────────────────────────────────────────
        elseif number == 41
            lnotbk[1] && (POTSEAS[1] = Int32(trunc(array[1])))
            lnotbk[2] && (POTSEAS[2] = Int32(trunc(array[2])))
            lkecho && @printf(io_units[JOSTND], "\n%-8s   SEASONS USED FOR CALCULATING POTENTIAL FIRE BEHAVIOR ARE \n             FOR SEVERE FIRE: %2d AND FOR MODERATE FIRE: %2d\n", keywrd[], POTSEAS[1], POTSEAS[2])
            continue

        # ── OPTION 42: POTFPAB ───────────────────────────────────────────────
        elseif number == 42
            lnotbk[1] && (POTPAB[1] = array[1])
            lnotbk[2] && (POTPAB[2] = array[2])
            lkecho && @printf(io_units[JOSTND], "\n%-8s   %% AREA BURNED VALUES USED FOR CALCULATING POTENTIAL FIRE EFFECTS ARE\n             FOR SEVERE FIRE: %5.1f AND FOR MODERATE FIRE: %5.1f\n", keywrd[], POTPAB[1], POTPAB[2])
            continue

        # ── OPTION 43: SOILHEAT ──────────────────────────────────────────────
        elseif number == 43
            IDSHEAT == 0 && GETID(Ref(IDSHEAT))
            ISHEATB = -IY[1]
            ISHEATE = IY[1] + Int32(999)
            SOILTP = Int32(3)
            lnotbk[3] && (SOILTP = Int32(trunc(array[3])))
            SOILTP < 1 && (SOILTP = Int32(1)); SOILTP > 5 && (SOILTP = Int32(5))
            lkecho && @printf(io_units[JOSTND], "\n%-8s   SOIL HEATING WILL BE ESTIMATED AND REPORTED WHEN A FIRE OCCURS.\n            SOIL TYPE IS SET TO %4d\n", keywrd[], SOILTP)
            continue

        # ── OPTION 44: CARBREPT ──────────────────────────────────────────────
        elseif number == 44
            if icall == 2
                @printf(io_units[JOSTND], "\n%-8s   ***KEYWORD IS A STAND-LEVEL KEYWORD ONLY AND CANNOT BE INCLUDED WITH THE LANDSCAPE-LEVEL KEYWORDS\n", keywrd[])
                continue
            end
            IDCRPT == 0 && GETID(Ref(IDCRPT))
            ICRPTB = IY[1]
            ICRPTE = IY[1] + Int32(999)
            lkecho && @printf(io_units[JOSTND], "\n%-8s   THE MAIN CARBON REPORT WILL BE PRINTED.\n", keywrd[])
            continue

        # ── OPTION 45: CARBCUT ───────────────────────────────────────────────
        elseif number == 45
            if icall == 2
                @printf(io_units[JOSTND], "\n%-8s   ***KEYWORD IS A STAND-LEVEL KEYWORD ONLY AND CANNOT BE INCLUDED WITH THE LANDSCAPE-LEVEL KEYWORDS\n", keywrd[])
                continue
            end
            IDCHRV == 0 && GETID(Ref(IDCHRV))
            ICHRVB = IY[1]
            ICHRVE = IY[1] + Int32(999)
            lkecho && @printf(io_units[JOSTND], "\n%-8s    THE HARVESTED PRODUCTS REPORT WILL BE PRINTED.\n", keywrd[])
            continue

        # ── OPTION 46: CARBCALC ──────────────────────────────────────────────
        elseif number == 46
            if icall == 2
                @printf(io_units[JOSTND], "\n%-8s   ***KEYWORD IS A STAND-LEVEL KEYWORD ONLY AND CANNOT BE INCLUDED WITH THE LANDSCAPE-LEVEL KEYWORDS\n", keywrd[])
                continue
            end
            lnotbk[1] && (ICMETH  = Int32(max(0, min(1, Int(trunc(array[1]))))))
            lnotbk[2] && (ICMETRC = Int32(max(0, min(2, Int(trunc(array[2]))))))
            lnotbk[3] && (CRDCAY  = max(0f0, min(1f0, array[3])))
            lnotbk[4] && (CDBRK[1] = max(0f0, min(999f0, array[4])))
            lnotbk[5] && (CDBRK[2] = max(0f0, min(999f0, array[5])))
            lkecho && @printf(io_units[JOSTND], "\n%-8s    CARBON REPORTS WILL BE BASED ON METHOD%2d (0=FFE, 1=JENKINS)\n            REPORT UNITS WILL BE%2d (0=US(TONS/ACRE), 1=METRIC(METRIC TONS/HA) 2=COMBINED(METRIC TONS/ACRE))\n            PROPORTION OF DEAD ROOTS DECAYING ANNUALLY WILL BE: %7.4f (<0 = NO DEAD ROOTS)\n            SOFTWOOD DIAMETER BREAKPOINT: %5.1f\n            HARDWOOD DIAMETER BREAKPOINT: %5.1f\n",
                keywrd[], ICMETH, ICMETRC, CRDCAY, CDBRK[1], CDBRK[2])
            continue

        # ── OPTION 47: CANFPROF ──────────────────────────────────────────────
        elseif number == 47
            if icall == 2
                @printf(io_units[JOSTND], "\n%-8s   ***KEYWORD IS A STAND-LEVEL KEYWORD ONLY AND CANNOT BE INCLUDED WITH THE LANDSCAPE-LEVEL KEYWORDS\n", keywrd[])
                continue
            end
            icanpr = Int32(1)
            DBSFMLINK(icanpr)
            ICFPB = IY[1]
            ICFPE = IY[1] + Int32(999)
            lkecho && @printf(io_units[JOSTND], "\n%-8s   CANOPY FUELS PROFILE TABLE SENT TO SPECIFIED DATABASE.\n", keywrd[])
            continue

        # ── OPTION 48: FUELFOTO ──────────────────────────────────────────────
        elseif number == 48
            if icall == 2
                @printf(io_units[JOSTND], "\n%-8s   KEYWORD IS A STAND-LEVEL KEYWORD ONLY AND CANNOT BE INCLUDED WITH THE LANDSCAPE-LEVEL KEYWORDS\n", keywrd[])
                continue
            end
            nparms = Int32(2); prms[1] = -1f0; prms[2] = -1f0
            idt = Int32(1)
            lnotbk[1] && (prms[1] = Float32(round(Int, array[1])))
            lnotbk[2] && (prms[2] = Float32(round(Int, array[2])))
            # Validate photo reference
            pr = Int(round(prms[1]))
            if pr == 4 || pr == 10 || pr < 1 || pr > 32
                prms[1] = -1f0
            end
            round(Int, prms[2]) < 1 && (prms[2] = -1f0)
            # Validate photo code per reference bounds
            pr2 = Int(round(prms[1]))
            pc2 = Int(round(prms[2]))
            _foto_maxcode = (1=>22, 2=>59, 3=>66, 5=>17, 6=>27, 7=>56, 8=>86,
                             9=>26, 11=>26, 12=>90, 13=>42, 14=>29, 15=>29, 16=>41,
                             17=>35, 18=>43, 19=>34, 20=>26, 21=>25, 22=>36, 23=>26,
                             24=>27, 25=>14, 26=>16, 27=>30, 28=>30, 29=>16, 30=>16,
                             31=>10, 32=>39)
            if haskey(_foto_maxcode, pr2) && pc2 > _foto_maxcode[pr2]
                prms[2] = -1f0
            end
            refname = pr2 == -1 ? "UNKNOWN" :
                      (1 <= pr2 <= 32 ? _FMIN_PHOTOREF[pr2] : "UNKNOWN")
            charcode_ref = Ref{String}("UNKNOWN      ")
            pr3 = Int32(round(prms[1])); pc3 = Int32(round(prms[2]))
            if pr3 != -1 && pc3 != -1
                FMPHOTOCODE(pr3, charcode_ref, pc3, Int32(0))
            end
            lkecho && @printf(io_units[JOSTND], "\n%-8s   PHOTO SERIES REFERENCE IS %4d = %s\n            PHOTO CODE IS %4d = %s\n",
                keywrd[], Int(round(prms[1])), refname, Int(round(prms[2])), charcode_ref[])
            myact = Int32(2548)
            if pr3 != -1 && pc3 != -1
                OPNEW(kode_r, idt, myact, nparms, prms)
            else
                @printf(io_units[JOSTND], "\n*** FFE MODEL WARNING: INCORRECT PHOTO REFERENCE OR PHOTO CODE ENTERED.  BOTH FIELDS ARE REQUIRED.  KEYWORD IGNORED.\n \n")
                RCDSET(Int32(2), true)
            end
            continue

        # ── OPTION 49: FIRECALC ──────────────────────────────────────────────
        elseif number == 49
            if icall == 2
                @printf(io_units[JOSTND], "\n%-8s   ***KEYWORD IS A STAND-LEVEL KEYWORD ONLY AND CANNOT BE INCLUDED WITH THE LANDSCAPE-LEVEL KEYWORDS\n", keywrd[])
                continue
            end
            myact = Int32(2549)
            idt = Int32(1); lnotbk[1] && (idt = Int32(trunc(array[1])))
            if iprmpt > 0
                if iprmpt != 2
                    FMKEYDMP(JOSTND, IRECNT, keywrd[], array, kard, nvals)
                    ERRGRO(true, Int32(25))
                else
                    OPNEWC(kode_r, JOSTND, IREAD, idt, myact, keywrd[], kard, iprmpt, Ref(IRECNT), ICYC)
                    fvsGetRtnCode(irtncd); irtncd[] != 0 && return
                end
                continue
            end
            nparms = Int32(8)
            prms[1]=Float32(IFLOGIC); prms[2]=Float32(IFMSET)
            prms[3]=USAV[1]; prms[4]=USAV[2]; prms[5]=USAV[3]
            prms[6]=UBD[1]; prms[7]=UBD[2]; prms[8]=ULHV
            lnotbk[2] && (prms[1] = Float32(max(0, min(2, Int(trunc(array[2]))))))
            lnotbk[3] && (prms[2] = Float32(max(0, min(2, Int(trunc(array[3]))))))
            lnotbk[4] && (prms[3] = max(0f0, array[4]))
            lnotbk[5] && (prms[4] = max(0f0, array[5]))
            lnotbk[6] && (prms[5] = max(0f0, array[6]))
            lnotbk[7] && (prms[6] = max(0f0, array[7]))
            lnotbk[8] && (prms[7] = max(0f0, array[8]))
            lnotbk[9] && (prms[8] = max(0f0, array[9]))
            lkecho && @printf(io_units[JOSTND], "\n%-8s    FIRE CALCULATIONS IN DATE/CYCLE %4d WILL BE:\n            BASED ON METHOD%2d (0=OLD FM LOGIC, 1=NEW FM LOGIC, 2=USE MODELLED LOADS DIRECTLY)\n            FUEL MODEL SET (IF USING NEW FM LOGIC) WILL BE%2d (0=13, 1=40, 2=53)\n            ONE-HOUR SAV (1/FT) WILL BE: %6.0f\n            HERB SAV (1/FT) WILL BE: %6.0f\n            LIVE WOODY SAV (1/FT) WILL BE: %6.0f\n            LIVE FUEL BULK DENSITY (LBS/FT3) WILL BE: %4.2f\n            DEAD FUEL BULK DENSITY (LBS/FT3) WILL BE: %4.2f\n            HEAT CONTENT (BTU/LB) WILL BE: %6.0f\n",
                keywrd[], idt, Int(prms[1]), Int(prms[2]), prms[3], prms[4], prms[5], prms[6], prms[7], prms[8])
            OPNEW(kode_r, idt, myact, nparms, prms)
            continue

        # ── OPTION 50: FMODLIST ──────────────────────────────────────────────
        elseif number == 50
            if icall == 2
                @printf(io_units[JOSTND], "\n%-8s   ***KEYWORD IS A STAND-LEVEL KEYWORD ONLY AND CANNOT BE INCLUDED WITH THE LANDSCAPE-LEVEL KEYWORDS\n", keywrd[])
                continue
            end
            myact = Int32(2550); idt = Int32(1)
            lnotbk[1] && (idt = Int32(trunc(array[1])))
            if iprmpt > 0
                if iprmpt != 2
                    FMKEYDMP(JOSTND, IRECNT, keywrd[], array, kard, nvals)
                    ERRGRO(true, Int32(25))
                else
                    OPNEWC(kode_r, JOSTND, IREAD, idt, myact, keywrd[], kard, iprmpt, Ref(IRECNT), ICYC)
                    fvsGetRtnCode(irtncd); irtncd[] != 0 && return
                end
                continue
            end
            prms[1]=1f0; prms[2]=-1f0; nparms=Int32(2)
            lnotbk[2] && (prms[1] = Float32(max(0, Int(trunc(array[2])))))
            lnotbk[3] && (prms[2] = Float32(max(-1, min(1, Int(trunc(array[3]))))))
            lkecho && @printf(io_units[JOSTND], "\n%-8s    IN DATE/CYCLE %4d FUEL MODEL %3d WILL BE:%2d (-1=DEFAULT, 0=ON, 1=OFF)\n", keywrd[], idt, Int(prms[1]), Int(prms[2]))
            OPNEW(kode_r, idt, myact, nparms, prms)
            continue

        # ── OPTION 51: DWDVLOUT ──────────────────────────────────────────────
        elseif number == 51
            if icall == 2
                @printf(io_units[JOSTND], "\n%-8s   ***KEYWORD IS A STAND-LEVEL KEYWORD ONLY AND CANNOT BE INCLUDED WITH THE LANDSCAPE-LEVEL KEYWORDS\n", keywrd[])
                continue
            end
            IDDWRP == 0 && GETID(Ref(IDDWRP))
            IDWRPB = IY[1]
            IDWRPE = IY[1] + Int32(999)
            lkecho && @printf(io_units[JOSTND], "\n%-8s   THE DOWN WOOD VOLUME REPORT WILL BE PRINTED.\n", keywrd[])
            continue

        # ── OPTION 52: DWDCVOUT ──────────────────────────────────────────────
        elseif number == 52
            if icall == 2
                @printf(io_units[JOSTND], "\n%-8s   ***KEYWORD IS A STAND-LEVEL KEYWORD ONLY AND CANNOT BE INCLUDED WITH THE LANDSCAPE-LEVEL KEYWORDS\n", keywrd[])
                continue
            end
            IDDWCV == 0 && GETID(Ref(IDDWCV))
            IDWCVB = IY[1]
            IDWCVE = IY[1] + Int32(999)
            lkecho && @printf(io_units[JOSTND], "\n%-8s   THE DOWN WOOD COVER REPORT WILL BE PRINTED.\n", keywrd[])
            continue

        # ── OPTION 53: FUELSOFT ──────────────────────────────────────────────
        elseif number == 53
            if icall == 2
                @printf(io_units[JOSTND], "\n%-8s   KEYWORD IS A STAND-LEVEL KEYWORD ONLY AND CANNOT BE INCLUDED WITH THE LANDSCAPE-LEVEL KEYWORDS\n", keywrd[])
                continue
            end
            nparms = Int32(9)
            for pi in 1:9; prms[pi] = -1f0; end
            idt = Int32(1)
            for pi in 1:9; lnotbk[pi] && (prms[pi] = array[pi]); end
            lkecho && @printf(io_units[JOSTND], "\n%-8s   INITIAL SOFT FUEL VALUES (TONS/ACRE) ARE (-1.0=NO VALUE SPECIFIED): FUELS <.25\"=%5.1f\n            FUELS .25-1\"=%5.1f; FUELS 1-3\"=%5.1f; FUELS 3-6\"=%5.1f; FUELS 6-12\"=%5.1f; FUELS 12-20\"=%5.1f\n            FUELS 20-35\"=%5.1f; FUELS 35-50\"=%5.1f; FUELS >50\"=%5.1f\n",
                keywrd[], prms[1], prms[2], prms[3], prms[4], prms[5], prms[6], prms[7], prms[8], prms[9])
            myact = Int32(2553)
            OPNEW(kode_r, idt, myact, nparms, prms)
            continue

        # ── OPTION 54: FMORTMLT ──────────────────────────────────────────────
        elseif number == 54
            myact = Int32(2554); idt = Int32(1)
            lnotbk[1] && (idt = Int32(trunc(array[1])))
            if iprmpt > 0
                if iprmpt != 2
                    FMKEYDMP(JOSTND, IRECNT, keywrd[], array, kard, nvals)
                    ERRGRO(true, Int32(25))
                else
                    OPNEWC(kode_r, JOSTND, IREAD, idt, myact, keywrd[], kard, iprmpt, Ref(IRECNT), ICYC)
                    fvsGetRtnCode(irtncd); irtncd[] != 0 && return
                end
                continue
            end
            jsp = Int32(0)
            SPDECD(Int32(3), Ref(jsp), view(nsp,:,1), JOSTND, Ref(IRECNT), keywrd[], array, kard)
            jsp == -999 && continue
            array[3] = Float32(jsp)
            !lnotbk[4] && (array[4] = 0f0)
            !lnotbk[5] && (array[5] = 999f0)
            if array[4] >= array[5]
                ERRGRO(true, Int32(4))
                KEYDMP(JOSTND, IRECNT, keywrd[], array, kard)
            else
                OPNEW(kode_r, idt, myact, Int32(4), view(array, 2:5))
                kode_r[] > 0 && continue
                lkecho && @printf(io_units[JOSTND], "\n%-8s   DATE/CYCLE=%5d; FIRE-CAUSED MORTALITY MULTIPLIER=%10.2f; SPECIES= %s (CODE= %3d)\n            ONLY TREES GREATER THAN OR EQUAL TO%7.2f AND LESS THAN %7.2f DBH ARE AFFECTED.\n",
                    keywrd[], idt, array[2], kard[3][1:3], jsp, array[4], array[5])
            end
            continue

        else
            # unrecognized NUMBER — should not happen
            continue
        end

    end  # while true
end
