# forkod.jl — FORKOD: forest code translation for the sn variant
# Translated from: sn/forkod.f (609 lines)
#
# Converts KODFOR (region/forest/district code) to IFOR index + corrected KODFOR,
# sets ISEFOR, KODIST, and fills in default TLAT/TLONG/ELEV by forest.
# Reservation pseudo-codes are re-mapped to the nearest administered unit.

const _FORKOD_JFOR = Int32[801,802,803,804,805,806,807,808,809,810,
                             811,812,813,905,908,836,824,860,835,701]
const _FORKOD_NUMFOR = 20

function FORKOD()
    io = io_units[Int32(JOSTND)]

    forfound = false
    ifordi   = Int32(KODFOR) ÷ Int32(100)

    # Reduce special 3-digit codes that may appear without district suffix
    if ifordi ∈ (905, 908, 836, 824, 860, 835, 701)
        global KODFOR = ifordi
    end

    # Phase 1: re-map special/administrative codes
    kf = Int32(KODFOR)
    if kf ∈ (836, 824)
        global KODFOR = Int32(81203)
        ifordi = Int32(812)
        @printf(io, "\n%s%s\n", "********", "            SAVANNAH RIVER BEING MAPPED TO SUMTER NF (81203) FOR FURTHER PROCESSING.")
    elseif kf ∈ (860, 835)
        global KODFOR = Int32(80216)
        ifordi = Int32(802)
        @printf(io, "\n%s%s\n", "********", "            LAND BETWEEN THE LAKES BEING MAPPED TO DANIEL BOONE (80216) FOR FURTHER PROCESSING.")
    elseif kf == 7201
        @printf(io, "\n%s%s\n", "********", "            ALABAMA-COUSHATTA RES. (7201) BEING MAPPED TO 81304 TEXAS NF SAM HOUSTON DIST FOR FURTHER PROCESSING.")
        global KODFOR = Int32(81304); ifordi = Int32(813)
    elseif kf == 7207
        @printf(io, "\n%s%s\n", "********", "            KIOWA-COMANCHE-APACHE-FORT SILL APACHE OTSA (7207) BEING MAPPED TO 80906 OUACHITA NF KIAMICHI DIST FOR FURTHER PROCESSING.")
        global KODFOR = Int32(80906); ifordi = Int32(809)
    elseif kf == 7210
        @printf(io, "\n%s%s\n", "********", "            KAW OTSA (7210) BEING MAPPED TO 81005 OZARK NF BOSTON MOUNTAIN DIST FOR FURTHER PROCESSING.")
        global KODFOR = Int32(81005); ifordi = Int32(810)
    elseif kf == 7211
        @printf(io, "\n%s%s\n", "********", "            OTOE-MISSOURIA OTSA (7211) BEING MAPPED TO 81005 OZARK NF BOSTON MOUNTAIN DIST FOR FURTHER PROCESSING.")
        global KODFOR = Int32(81005); ifordi = Int32(810)
    elseif kf == 7212
        @printf(io, "\n%s%s\n", "********", "            PAWNEE OTSA (7212) BEING MAPPED TO 81005 OZARK NF BOSTON MOUNTAIN DIST FOR FURTHER PROCESSING.")
        global KODFOR = Int32(81005); ifordi = Int32(810)
    elseif kf == 7213
        @printf(io, "\n%s%s\n", "********", "            PONCA OTSA (7213) BEING MAPPED TO 81005 OZARK NF BOSTON MOUNTAIN DIST FOR FURTHER PROCESSING.")
        global KODFOR = Int32(81005); ifordi = Int32(810)
    elseif kf == 7215
        @printf(io, "\n%s%s\n", "********", "            CITIZEN POTAWATOMI NATION-ABSENTEE SHAWNEE OTSA (7215) BEING MAPPED TO 80901 OUACHITA NF CHOCTAW DIST FOR FURTHER PROCESSING.")
        global KODFOR = Int32(80901); ifordi = Int32(809)
    elseif kf == 7216
        @printf(io, "\n%s%s\n", "********", "            IOWA OTSA (7216) BEING MAPPED TO 80901 OUACHITA NF CHOCTAW DIST FOR FURTHER PROCESSING.")
        global KODFOR = Int32(80901); ifordi = Int32(809)
    elseif kf == 7218
        @printf(io, "\n%s%s\n", "********", "            SAC AND FOX OTSA (7218) BEING MAPPED TO 80901 OUACHITA NF CHOCTAW DIST FOR FURTHER PROCESSING.")
        global KODFOR = Int32(80901); ifordi = Int32(809)
    elseif kf == 7601
        @printf(io, "\n%s%s\n", "********", "            CHICKASAW OTSA (7601) BEING MAPPED TO 80906 OUACHITA NF KIAMICHI DIST FOR FURTHER PROCESSING.")
        global KODFOR = Int32(80906); ifordi = Int32(809)
    elseif kf == 7602
        @printf(io, "\n%s%s\n", "********", "            QUAPAW OTSA (7602) BEING MAPPED TO 81005 OZARK NF BOSTON MOUNTAIN DIST FOR FURTHER PROCESSING.")
        global KODFOR = Int32(81005); ifordi = Int32(810)
    elseif kf == 7603
        @printf(io, "\n%s%s\n", "********", "            EASTERN SHAWNEE OTSA (7603) BEING MAPPED TO 81005 OZARK NF BOSTON MOUNTAIN DIST FOR FURTHER PROCESSING.")
        global KODFOR = Int32(81005); ifordi = Int32(810)
    elseif kf == 7604
        @printf(io, "\n%s%s\n", "********", "            SENECA-CAYUGA OTSA (7604) BEING MAPPED TO 81005 OZARK NF BOSTON MOUNTAIN DIST FOR FURTHER PROCESSING.")
        global KODFOR = Int32(81005); ifordi = Int32(810)
    elseif kf == 7605
        @printf(io, "\n%s%s\n", "********", "            WYANDOTTE OTSA (7605) BEING MAPPED TO 81005 OZARK NF BOSTON MOUNTAIN DIST FOR FURTHER PROCESSING.")
        global KODFOR = Int32(81005); ifordi = Int32(810)
    elseif kf == 7606
        @printf(io, "\n%s%s\n", "********", "            MIAMI OTSA (7606) BEING MAPPED TO 81005 OZARK NF BOSTON MOUNTAIN DIST FOR FURTHER PROCESSING.")
        global KODFOR = Int32(81005); ifordi = Int32(810)
    elseif kf == 7607
        @printf(io, "\n%s%s\n", "********", "            PEORIA OTSA (7607) BEING MAPPED TO 81005 OZARK NF BOSTON MOUNTAIN DIST FOR FURTHER PROCESSING.")
        global KODFOR = Int32(81005); ifordi = Int32(810)
    elseif kf == 7608
        @printf(io, "\n%s%s\n", "********", "            MODOC OTSA (7608) BEING MAPPED TO 81005 OZARK NF BOSTON MOUNTAIN DIST FOR FURTHER PROCESSING.")
        global KODFOR = Int32(81005); ifordi = Int32(810)
    elseif kf == 7609
        @printf(io, "\n%s%s\n", "********", "            OSAGE RES. (7609) BEING MAPPED TO 81005 OZARK NF BOSTON MOUNTAIN DIST FOR FURTHER PROCESSING.")
        global KODFOR = Int32(81005); ifordi = Int32(810)
    elseif kf == 7610
        @printf(io, "\n%s%s\n", "********", "            CREEK OTSA (7610) BEING MAPPED TO 80901 OUACHITA NF CHOCTAW DIST FOR FURTHER PROCESSING.")
        global KODFOR = Int32(80901); ifordi = Int32(809)
    elseif kf == 7611
        @printf(io, "\n%s%s\n", "********", "            CHEROKEE OTSA (7611) BEING MAPPED TO 81005 OZARK NF BOSTON MOUNTAIN DIST FOR FURTHER PROCESSING.")
        global KODFOR = Int32(81005); ifordi = Int32(810)
    elseif kf == 7612
        @printf(io, "\n%s%s\n", "********", "            CHOCTAW OTSA (7612) BEING MAPPED TO 80906 OUACHITA NF KIAMICHI DIST FOR FURTHER PROCESSING.")
        global KODFOR = Int32(80906); ifordi = Int32(809)
    elseif kf == 7613
        @printf(io, "\n%s%s\n", "********", "            SEMINOLE OTSA (7613) BEING MAPPED TO 80901 OUACHITA NF CHOCTAW DIST FOR FURTHER PROCESSING.")
        global KODFOR = Int32(80901); ifordi = Int32(809)
    elseif kf == 8205
        @printf(io, "\n%s%s\n", "********", "            MICCOSUKEE RES. (8205) BEING MAPPED TO 80505 FLORIDA NF SEMINOLE DIST FOR FURTHER PROCESSING.")
        global KODFOR = Int32(80505); ifordi = Int32(805)
    elseif kf == 8207
        @printf(io, "\n%s%s\n", "********", "            POARCH CREEK RES. (8207) BEING MAPPED TO 80103 ALABAMA NF CONECUH DIST FOR FURTHER PROCESSING.")
        global KODFOR = Int32(80103); ifordi = Int32(801)
    elseif kf == 8210
        @printf(io, "\n%s%s\n", "********", "            CATAWBA RES. (8210) BEING MAPPED TO 81201 SUMTER NF ENOREE DIST FOR FURTHER PROCESSING.")
        global KODFOR = Int32(81201); ifordi = Int32(812)
    elseif kf == 8212
        @printf(io, "\n%s%s\n", "********", "            TUNICA-BILOXI RES. (8212) BEING MAPPED TO 80601 KISATCHIE NF CATAHOULA DIST FOR FURTHER PROCESSING.")
        global KODFOR = Int32(80601); ifordi = Int32(806)
    elseif kf == 8213
        @printf(io, "\n%s%s\n", "********", "            COUSHATTA RES. (8213) BEING MAPPED TO 80602 KISATCHIE NF CALCASIEU DIST FOR FURTHER PROCESSING.")
        global KODFOR = Int32(80602); ifordi = Int32(806)
    elseif kf == 8219
        @printf(io, "\n%s%s\n", "********", "            EASTERN CHEROKEE RES. (8219) BEING MAPPED TO 81111 NORTH CAROLINA NF NANTAHALA DIST FOR FURTHER PROCESSING.")
        global KODFOR = Int32(81111); ifordi = Int32(811)
    elseif kf == 8220
        @printf(io, "\n%s%s\n", "********", "            SEMINOLE (FL) TRUST LAND (8220) BEING MAPPED TO 80505 FLORIDA NF SEMINOLE DIST FOR FURTHER PROCESSING.")
        global KODFOR = Int32(80505); ifordi = Int32(805)
    elseif kf == 8221
        @printf(io, "\n%s%s\n", "********", "            MISSISSIPPI CHOCTAW RES. (8221) BEING MAPPED TO 80701 MISSISSIPPI NF BIENVILLE DIST FOR FURTHER PROCESSING.")
        global KODFOR = Int32(80701); ifordi = Int32(807)
    end

    # Phase 2: final evaluation — assign IFOR, KODIST, ISEFOR
    kf2 = Int32(KODFOR)
    if kf2 == 905
        global IFOR = Int32(14); global KODIST = Int32(1); global ISEFOR = Int32(0)
        global KODFOR = Int32(_FORKOD_JFOR[14] * 100 + KODIST)
        @printf(io, "\n%s%s%4d\n%s%s%3d\n", "********", "            FOREST CODE USED FOR THIS PROJECTION IS", _FORKOD_JFOR[14],
            "********", "            DISTRICT USED FOR THIS PROJECTION IS", KODIST)
    elseif kf2 == 908
        global IFOR = Int32(15); global KODIST = Int32(1); global ISEFOR = Int32(0)
        global KODFOR = Int32(_FORKOD_JFOR[15] * 100 + KODIST)
        @printf(io, "\n%s%s%4d\n%s%s%3d\n", "********", "            FOREST CODE USED FOR THIS PROJECTION IS", _FORKOD_JFOR[15],
            "********", "            DISTRICT USED FOR THIS PROJECTION IS", KODIST)
    elseif kf2 == 701
        @printf(io, "\n%s%s\n", "********", "            FORT BRAGG BEING MAPPED TO NFS IN NC, UWHARRIE DISTRICT (81110) FOR FURTHER PROCESSING.")
        global IFOR = Int32(20); global KODIST = Int32(10); global ISEFOR = Int32(701)
        global KODFOR = Int32(81110)
    else
        # Standard Region 8 five-digit codes
        for i in 1:_FORKOD_NUMFOR
            if ifordi == _FORKOD_JFOR[i]
                kd = Int32(KODFOR) - ifordi * Int32(100)
                # Clamp KODIST to valid range per forest
                f = _FORKOD_JFOR[i]
                if f == 801
                    if kd < 1 || kd == 2 || kd > 7; kd = Int32(3); end
                elseif f == 802
                    if kd < 11 || kd == 16 || kd > 17; kd = Int32(11); end
                elseif f == 803
                    if kd < 1 || kd == 3 || kd > 8; kd = Int32(8); end
                elseif f == 804
                    if kd < 1 || kd > 6; kd = Int32(1); end
                elseif f == 805
                    if kd < 1 || kd == 3 || kd > 6; kd = Int32(4); end
                elseif f == 806
                    if kd < 1 || kd > 5; kd = Int32(3); end
                elseif f == 807
                    if kd < 1 || kd == 5 || (kd > 7 && kd < 17) || kd > 17; kd = Int32(7); end
                elseif f == 808
                    if kd < 1 || (kd >= 7 && kd <= 10) || kd > 16; kd = Int32(16); end
                elseif f == 809
                    if kd < 1 || kd > 12; kd = Int32(7); end
                elseif f == 810
                    if kd < 1 || kd > 7; kd = Int32(5); end
                elseif f == 811
                    if kd < 2 || kd > 11; kd = Int32(5); end
                elseif f == 812
                    if kd < 1 || kd == 4 || kd > 5; kd = Int32(1); end
                else   # 813
                    if kd < 1 || kd == 2 || kd == 5 || kd == 6 || kd > 8; kd = Int32(3); end
                end
                global KODIST = kd
                global IFOR   = Int32(i)
                global ISEFOR = _FORKOD_JFOR[i]
                global KODFOR = Int32(_FORKOD_JFOR[i] * 100 + kd)
                forfound = true
                break
            end
        end

        if !forfound
            ERRGRO(true, Int32(3))
            @printf(io, "\n%s%s%4d\n%s%s%3d\n", "********", "            FOREST CODE USED FOR THIS PROJECTION IS", _FORKOD_JFOR[Int(IFOR)],
                "********", "            DISTRICT USED FOR THIS PROJECTION IS", KODIST)
            global ISEFOR = _FORKOD_JFOR[Int(IFOR)]
            global KODFOR = Int32(_FORKOD_JFOR[Int(IFOR)] * 100 + KODIST)
        end
    end

    # Phase 3: set default lat/long/elevation by forest
    forest = _FORKOD_JFOR[clamp(Int(IFOR), 1, _FORKOD_NUMFOR)]
    if forest == 801
        if TLAT  == 0; global TLAT  = Float32(32.37); end
        if TLONG == 0; global TLONG = Float32(86.30); end
        if ELEV  == 0; global ELEV  = Float32(7.);    end
    elseif forest == 802
        if TLAT  == 0; global TLAT  = Float32(37.99); end
        if TLONG == 0; global TLONG = Float32(84.18); end
        if ELEV  == 0; global ELEV  = Float32(12.);   end
    elseif forest == 803
        if TLAT  == 0; global TLAT  = Float32(34.30); end
        if TLONG == 0; global TLONG = Float32(83.82); end
        if ELEV  == 0; global ELEV  = Float32(17.);   end
    elseif forest == 804
        if TLAT  == 0; global TLAT  = Float32(35.16); end
        if TLONG == 0; global TLONG = Float32(84.88); end
        if ELEV  == 0; global ELEV  = Float32(22.);   end
    elseif forest == 805
        if TLAT  == 0; global TLAT  = Float32(30.44); end
        if TLONG == 0; global TLONG = Float32(84.28); end
        if ELEV  == 0; global ELEV  = Float32(1.);    end
    elseif forest == 806
        if TLAT  == 0; global TLAT  = Float32(31.32); end
        if TLONG == 0; global TLONG = Float32(92.43); end
        if ELEV  == 0; global ELEV  = Float32(2.);    end
    elseif forest == 807
        if TLAT  == 0; global TLAT  = Float32(33.31); end
        if TLONG == 0; global TLONG = Float32(89.17); end
        if ELEV  == 0; global ELEV  = Float32(3.);    end
    elseif forest == 808
        if TLAT  == 0; global TLAT  = Float32(37.27); end
        if TLONG == 0; global TLONG = Float32(79.94); end
        if ELEV  == 0; global ELEV  = Float32(21.);   end
    elseif forest == 809
        if TLAT  == 0; global TLAT  = Float32(34.50); end
        if TLONG == 0; global TLONG = Float32(93.06); end
        if ELEV  == 0; global ELEV  = Float32(9.);    end
    elseif forest == 810
        if TLAT  == 0; global TLAT  = Float32(35.28); end
        if TLONG == 0; global TLONG = Float32(93.13); end
        if ELEV  == 0; global ELEV  = Float32(13.);   end
    elseif forest == 811
        if TLAT  == 0; global TLAT  = Float32(35.60); end
        if TLONG == 0; global TLONG = Float32(82.55); end
        if ELEV  == 0; global ELEV  = Float32(25.);   end
    elseif forest == 812
        if TLAT  == 0; global TLAT  = Float32(34.00); end
        if TLONG == 0; global TLONG = Float32(81.04); end
        if ELEV  == 0; global ELEV  = Float32(4.);    end
    elseif forest == 813
        if TLAT  == 0; global TLAT  = Float32(31.34); end
        if TLONG == 0; global TLONG = Float32(94.73); end
        if ELEV  == 0; global ELEV  = Float32(3.);    end
    elseif forest == 905
        if TLAT  == 0; global TLAT  = Float32(37.95); end
        if TLONG == 0; global TLONG = Float32(91.77); end
        if ELEV  == 0; global ELEV  = Float32(10.);   end
    elseif forest == 908
        if TLAT  == 0; global TLAT  = Float32(37.74); end
        if TLONG == 0; global TLONG = Float32(88.54); end
        if ELEV  == 0; global ELEV  = Float32(4.);    end
    elseif forest == 701
        if TLAT  == 0; global TLAT  = Float32(35.60); end
        if TLONG == 0; global TLONG = Float32(82.55); end
        if ELEV  == 0; global ELEV  = Float32(25.);   end
    end

    return nothing
end
