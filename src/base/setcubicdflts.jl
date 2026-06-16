# setcubicdflts.jl — SETCUBICDFLTS: set variant/forest cubic volume merchandising defaults
# Translated from: setcubicdflts.f (511 lines)
#
# Sets per-species DBHMIN, TOPD, SCFMIND, SCFTOPD, STMP, SCFSTMP based on
# VARACD (variant code), ISEFOR/KODFOR (region/forest/district identifiers),
# IFOR (forest number), KODIST (district number), and IMODTY (model type for CR).

function SETCUBICDFLTS()

    # CR variant default model type table (23 forest codes)
    crdefmt = Int32[5, 3, 4, 5, 3, 4, 5, 5, 4, 4, 5, 4,
                    2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2]

    # AK variant location→merch category table (2 × 17)
    akmerchcds = Int32[713,  1,
                       720,  2,
                       7400, 2,
                       7401, 2,
                       7402, 2,
                       7403, 2,
                       7404, 2,
                       7405, 2,
                       7406, 2,
                       7407, 2,
                       7408, 2,
                       703,  3,
                       1005, 3,
                       8134, 3,
                       8135, 3,
                       8112, 3,
                       1004, 4]

    if VARACD == "AK"
        akmerchcat = Int32(3)   # default to Tongass
        for i in 1:17
            if KODFOR == akmerchcds[(i-1)*2 + 1]
                akmerchcat = akmerchcds[(i-1)*2 + 2]
                break
            end
        end
        for ispc in 1:Int(MAXSP)
            STMP[ispc]    = Float32(1)
            SCFSTMP[ispc] = Float32(1)
            if akmerchcat == Int32(1)
                DBHMIN[ispc]  = Float32(6); TOPD[ispc]    = Float32(4)
                SCFMIND[ispc] = Float32(9); SCFTOPD[ispc] = Float32(6)
            elseif akmerchcat == Int32(2)
                DBHMIN[ispc]  = Float32(5); TOPD[ispc]    = Float32(4)
                SCFMIND[ispc] = Float32(9); SCFTOPD[ispc] = Float32(6)
            elseif akmerchcat == Int32(3)
                DBHMIN[ispc]  = Float32(9); TOPD[ispc]    = Float32(7)
                SCFMIND[ispc] = Float32(9); SCFTOPD[ispc] = Float32(7)
            elseif akmerchcat == Int32(4)
                DBHMIN[ispc]  = Float32(9); TOPD[ispc]    = Float32(6)
                SCFMIND[ispc] = Float32(9); SCFTOPD[ispc] = Float32(6)
            else
                DBHMIN[ispc]  = Float32(9); TOPD[ispc]    = Float32(7)
                SCFMIND[ispc] = Float32(9); SCFTOPD[ispc] = Float32(7)
            end
        end

    elseif VARACD == "BM"
        for ispc in 1:Int(MAXSP)
            STMP[ispc] = Float32(1); SCFSTMP[ispc] = Float32(1)
            DBHMIN[ispc] = Float32(7); TOPD[ispc] = Float32(4.5)
            SCFMIND[ispc] = Float32(7); SCFTOPD[ispc] = Float32(4.5)
        end
        DBHMIN[7] = Float32(6); SCFMIND[7] = Float32(6)

    elseif VARACD == "CA"
        for ispc in 1:Int(MAXSP)
            STMP[ispc] = Float32(1); SCFSTMP[ispc] = Float32(1)
            DBHMIN[ispc] = Float32(7); SCFMIND[ispc] = Float32(7)
            if 6 <= IFOR <= 10
                TOPD[ispc] = Float32(4.5); SCFTOPD[ispc] = Float32(4.5)
            else
                TOPD[ispc] = Float32(6);   SCFTOPD[ispc] = Float32(6)
            end
        end
        DBHMIN[11] = Float32(6); SCFMIND[11] = Float32(6)

    elseif VARACD == "CI"
        for ispc in 1:Int(MAXSP)
            STMP[ispc] = Float32(1); SCFSTMP[ispc] = Float32(1)
            DBHMIN[ispc] = Float32(8); TOPD[ispc] = Float32(6)
            SCFMIND[ispc] = Float32(8); SCFTOPD[ispc] = Float32(6)
        end
        DBHMIN[7] = Float32(7); SCFMIND[7] = Float32(7)

    elseif VARACD == "CR"
        imodty_local = Int(IMODTY)
        if imodty_local <= 0 || imodty_local > 5
            imodty_local = Int(crdefmt[Int(IFOR)])
        end
        for ispc in 1:Int(MAXSP)
            STMP[ispc] = Float32(1); SCFSTMP[ispc] = Float32(1)
            if imodty_local == 1 || imodty_local == 2 || imodty_local == 4 || imodty_local == 5
                DBHMIN[ispc]  = Float32(5); TOPD[ispc]    = Float32(4)
                SCFTOPD[ispc] = Float32(6); SCFMIND[ispc] = Float32(7)
                if IFOR >= IGFOR; SCFMIND[ispc] = Float32(9); end
            elseif imodty_local == 3
                DBHMIN[ispc]  = Float32(9); TOPD[ispc]    = Float32(6)
                SCFMIND[ispc] = Float32(9); SCFTOPD[ispc] = Float32(6)
            end
        end

    elseif VARACD == "CS"
        for ispc in 1:Int(MAXSP)
            STMP[ispc] = Float32(0.5); SCFSTMP[ispc] = Float32(1)
            DBHMIN[ispc] = (ispc <= 7 || IFOR == 1) ? Float32(5) : Float32(6)
            TOPD[ispc]   = (ispc > 7 && IFOR == 2) ? Float32(5) : Float32(4)
            SCFMIND[ispc] = Float32(9)
            if ispc == 1 && IFOR == 1; SCFMIND[ispc] = Float32(6)
            elseif ispc > 7 && IFOR != 1; SCFMIND[ispc] = Float32(11)
            end
            SCFTOPD[ispc] = Float32(7.6)
            if ispc == 1 && IFOR == 1; SCFTOPD[ispc] = Float32(5)
            elseif ispc > 7 && IFOR != 1; SCFTOPD[ispc] = Float32(9.6)
            end
        end

    elseif VARACD == "EC"
        for ispc in 1:Int(MAXSP)
            STMP[ispc] = Float32(1); SCFSTMP[ispc] = Float32(1)
            DBHMIN[ispc] = Float32(7); TOPD[ispc] = Float32(4.5)
            SCFMIND[ispc] = Float32(7); SCFTOPD[ispc] = Float32(4.5)
        end
        DBHMIN[7] = Float32(6); SCFMIND[7] = Float32(6)

    elseif VARACD == "EM"
        for ispc in 1:Int(MAXSP)
            STMP[ispc] = Float32(1); SCFSTMP[ispc] = Float32(1)
            DBHMIN[ispc] = Float32(7); TOPD[ispc] = Float32(4.5)
            SCFMIND[ispc] = Float32(7); SCFTOPD[ispc] = Float32(4.5)
        end
        DBHMIN[7] = Float32(6); SCFMIND[7] = Float32(6)

    elseif VARACD == "IE"
        for ispc in 1:Int(MAXSP)
            STMP[ispc] = Float32(1); SCFSTMP[ispc] = Float32(1)
            DBHMIN[ispc] = Float32(7); TOPD[ispc] = Float32(4.5)
            SCFMIND[ispc] = Float32(7); SCFTOPD[ispc] = Float32(4.5)
        end
        DBHMIN[7] = Float32(6); SCFMIND[7] = Float32(6)

    elseif VARACD == "KT"
        for ispc in 1:Int(MAXSP)
            STMP[ispc] = Float32(1); SCFSTMP[ispc] = Float32(1)
            DBHMIN[ispc] = Float32(7); TOPD[ispc] = Float32(4.5)
            SCFMIND[ispc] = Float32(7); SCFTOPD[ispc] = Float32(4.5)
        end
        DBHMIN[7] = Float32(6); SCFMIND[7] = Float32(6)

    elseif VARACD == "LS"
        for ispc in 1:Int(MAXSP)
            STMP[ispc] = Float32(0.5); SCFSTMP[ispc] = Float32(1)
            DBHMIN[ispc] = ((40 <= ispc <= 42 && IFOR == 2) || IFOR == 6) ? Float32(6) : Float32(5)
            TOPD[ispc] = Float32(4)
            if ispc <= 14
                SCFMIND[ispc] = Float32(9); SCFTOPD[ispc] = Float32(7.6)
            elseif IFOR == 2
                SCFMIND[ispc] = Float32(9); SCFTOPD[ispc] = Float32(7.6)
                if 40 <= ispc <= 42
                    SCFMIND[ispc] = Float32(11); SCFTOPD[ispc] = Float32(9.6)
                end
            elseif IFOR == 5
                SCFMIND[ispc] = Float32(11); SCFTOPD[ispc] = Float32(7.6)
                if 40 <= ispc <= 42; SCFMIND[ispc] = Float32(9); end
            else
                SCFMIND[ispc] = Float32(11); SCFTOPD[ispc] = Float32(9.6)
            end
        end

    elseif VARACD == "NC"
        for ispc in 1:Int(MAXSP)
            STMP[ispc] = Float32(1); SCFSTMP[ispc] = Float32(1)
            DBHMIN[ispc] = Float32(9); SCFMIND[ispc] = Float32(9)
            if IFOR == 4
                TOPD[ispc] = Float32(4.5); SCFTOPD[ispc] = Float32(4.5)
            elseif IFOR == 5 || IFOR == 7
                TOPD[ispc] = Float32(5); SCFTOPD[ispc] = Float32(5)
            else
                TOPD[ispc] = Float32(6); SCFTOPD[ispc] = Float32(6)
            end
        end

    elseif VARACD == "NE"
        for ispc in 1:Int(MAXSP)
            STMP[ispc] = Float32(1); SCFSTMP[ispc] = Float32(1)
            DBHMIN[ispc] = Float32(5)
            if (IFOR == 1 || IFOR == 3) && ispc > 25; DBHMIN[ispc] = Float32(6); end
            if IFOR == 4 && ispc > 25; DBHMIN[ispc] = Float32(8); end
            TOPD[ispc] = Float32(4)
            if IFOR == 3 && ispc > 25; TOPD[ispc] = Float32(5); end
            SCFMIND[ispc] = ispc > 25 ? Float32(11) : Float32(9)
            SCFTOPD[ispc] = ispc > 25 ? Float32(9.6) : Float32(7.6)
        end

    elseif VARACD == "OC"
        for ispc in 1:Int(MAXSP)
            STMP[ispc] = Float32(1); SCFSTMP[ispc] = Float32(1)
            DBHMIN[ispc] = Float32(7); SCFMIND[ispc] = Float32(7)
            if 6 <= IFOR <= 10
                TOPD[ispc] = Float32(4.5); SCFTOPD[ispc] = Float32(4.5)
            else
                TOPD[ispc] = Float32(6); SCFTOPD[ispc] = Float32(6)
            end
        end
        DBHMIN[11] = Float32(6); SCFMIND[11] = Float32(6)

    elseif VARACD == "OP"
        for ispc in 1:Int(MAXSP)
            STMP[ispc] = Float32(1); SCFSTMP[ispc] = Float32(1)
            DBHMIN[ispc] = Float32(7); SCFMIND[ispc] = Float32(7)
            if IFOR == 4 || IFOR == 5 || IFOR == 6
                TOPD[ispc] = Float32(5); SCFTOPD[ispc] = Float32(5)
            else
                if ispc == 11; DBHMIN[ispc] = Float32(6); SCFMIND[ispc] = Float32(6); end
                TOPD[ispc] = Float32(4.5); SCFTOPD[ispc] = Float32(4.5)
            end
        end

    elseif VARACD == "PN"
        for ispc in 1:Int(MAXSP)
            STMP[ispc] = Float32(1); SCFSTMP[ispc] = Float32(1)
            DBHMIN[ispc] = Float32(7); SCFMIND[ispc] = Float32(7)
            if IFOR == 4 || IFOR == 5 || IFOR == 6
                TOPD[ispc] = Float32(5); SCFTOPD[ispc] = Float32(5)
            else
                if ispc == 11; DBHMIN[ispc] = Float32(6); SCFMIND[ispc] = Float32(6); end
                TOPD[ispc] = Float32(4.5); SCFTOPD[ispc] = Float32(4.5)
            end
        end

    elseif VARACD == "SN"
        iregn = ISEFOR != 0 ? Int(KODFOR ÷ 10000) : 9
        if iregn == 8
            for ispc in 1:Int(MAXSP)
                STMP[ispc] = Float32(0.5); SCFSTMP[ispc] = Float32(1)
                TOPD[ispc] = Float32(4)
                DBHMIN[ispc] = (ispc in (7,13,39,43,44,52,53,55,63)) ? Float32(6) : Float32(4)
                # North Carolina (Nantahala/Pisgah, NF 11) overrides
                if IFOR == 11
                    TOPD[ispc] = Float32(3.5)
                    if KODIST == 3 || KODIST == 10
                        DBHMIN[ispc] = (ispc <= 17 || ispc == 88) ? Float32(5.6) : Float32(6)
                    else
                        DBHMIN[ispc] = Float32(8)
                    end
                end
                # Softwood vs hardwood specs
                if ispc <= 17 || ispc == 88   # softwoods
                    SCFMIND[ispc] = Float32(10); SCFTOPD[ispc] = Float32(7)
                    if IFOR == 10 && ispc == 2
                        SCFMIND[ispc] = Float32(9); SCFTOPD[ispc] = Float32(7)
                    end
                    if IFOR == 11
                        if KODIST == 3 || KODIST == 10
                            SCFMIND[ispc] = Float32(11); SCFTOPD[ispc] = Float32(6.3)
                        elseif ispc in (2,12,15,16,17)
                            SCFMIND[ispc] = Float32(12); SCFTOPD[ispc] = Float32(9)
                        else
                            SCFMIND[ispc] = Float32(10); SCFTOPD[ispc] = Float32(6.3)
                        end
                    end
                else   # hardwoods
                    SCFMIND[ispc] = Float32(12); SCFTOPD[ispc] = Float32(9)
                    if IFOR == 11
                        SCFMIND[ispc] = Float32(15); SCFTOPD[ispc] = Float32(11)
                        if KODIST == 3 || KODIST == 10
                            SCFMIND[ispc] = Float32(13); SCFTOPD[ispc] = Float32(8)
                        end
                    end
                end
            end
        else  # non-Region 8
            for ispc in 1:Int(MAXSP)
                STMP[ispc] = Float32(0.5); SCFSTMP[ispc] = Float32(1)
                if IFOR == 15 && ispc > 17 && ispc != 88
                    DBHMIN[ispc] = Float32(6); TOPD[ispc] = Float32(5)
                else
                    DBHMIN[ispc] = Float32(5); TOPD[ispc] = Float32(4)
                end
                SCFMIND[ispc] = Float32(9); SCFTOPD[ispc] = Float32(7.6)
                if IFOR == 15 && ispc > 17 && ispc != 88
                    SCFMIND[ispc] = Float32(11); SCFTOPD[ispc] = Float32(9.6)
                end
            end
        end

    elseif VARACD == "SO"
        for ispc in 1:Int(MAXSP)
            STMP[ispc] = Float32(1); SCFSTMP[ispc] = Float32(1)
            DBHMIN[ispc] = Float32(9); SCFMIND[ispc] = Float32(9)
            if IFOR == 1 || IFOR == 2 || IFOR == 3 || IFOR == 10
                TOPD[ispc] = Float32(4.5); SCFTOPD[ispc] = Float32(4.5)
            else
                TOPD[ispc] = Float32(6); SCFTOPD[ispc] = Float32(6)
            end
        end

    elseif VARACD == "TT"
        for ispc in 1:Int(MAXSP)
            STMP[ispc] = Float32(1); SCFSTMP[ispc] = Float32(1)
            DBHMIN[ispc] = Float32(8); TOPD[ispc] = Float32(6)
            SCFMIND[ispc] = Float32(8); SCFTOPD[ispc] = Float32(6)
        end
        DBHMIN[7] = Float32(7); SCFMIND[7] = Float32(7)

    elseif VARACD == "UT"
        for ispc in 1:Int(MAXSP)
            STMP[ispc] = Float32(1); SCFSTMP[ispc] = Float32(1)
            DBHMIN[ispc] = Float32(8); TOPD[ispc] = Float32(6)
            SCFMIND[ispc] = Float32(8); SCFTOPD[ispc] = Float32(6)
        end
        DBHMIN[7] = Float32(7); SCFMIND[7] = Float32(7)

    elseif VARACD == "WC"
        for ispc in 1:Int(MAXSP)
            STMP[ispc] = Float32(1); SCFSTMP[ispc] = Float32(1)
            if 7 <= IFOR <= 10
                DBHMIN[ispc] = Float32(7); TOPD[ispc] = Float32(5)
                SCFMIND[ispc] = Float32(7); SCFTOPD[ispc] = Float32(5)
            else
                DBHMIN[ispc] = Float32(7)
                if ispc == 11; DBHMIN[ispc] = Float32(6); end
                TOPD[ispc] = Float32(4.5); SCFMIND[ispc] = Float32(7)
                if ispc == 11; SCFMIND[ispc] = Float32(6); end
                SCFTOPD[ispc] = Float32(4.5)
            end
        end

    elseif VARACD == "WS"
        for ispc in 1:Int(MAXSP)
            STMP[ispc] = Float32(1); SCFSTMP[ispc] = Float32(1)
            DBHMIN[ispc] = Float32(7); TOPD[ispc] = Float32(4.5)
            SCFMIND[ispc] = Float32(10); SCFTOPD[ispc] = Float32(6)
        end
    end

    return nothing
end
