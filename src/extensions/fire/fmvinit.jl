# extensions/fire/fmvinit.jl — FMVINIT: variant-specific fire model initialization (SN)
# Translated from: fmvinit.f (1121 lines, FIRE-SN $Id$)
# Called from: FMINIT
# Initializes per-species snag, fuels, and decay parameters for the Southern variant.

function FMVINIT()
    global LVWEST, PBSCOR, PBSOFT, PBSMAL, PBSIZE, PBTIME, OLDICT, IDRYB, IDRYE, SLCRIT
    global NZERO, LIMBRK, HTXSFT, HTR1, HTR2

    LVWEST = false  # SN is an eastern variant

    # Canopy closure class cutoffs (%) and wind speed correction factors
    CANCLS[1] =  5.0f0
    CANCLS[2] = 17.5f0
    CANCLS[3] = 37.5f0
    CANCLS[4] = 75.0f0

    CORFAC[1] = 0.5f0
    CORFAC[2] = 0.3f0
    CORFAC[3] = 0.2f0
    CORFAC[4] = 0.1f0

    # Snag diameter class breakpoints (inches) for reporting
    SNPRCL[1] =  0.0f0
    SNPRCL[2] = 12.0f0
    SNPRCL[3] = 18.0f0
    SNPRCL[4] = 24.0f0
    SNPRCL[5] = 30.0f0
    SNPRCL[6] = 36.0f0

    # Lower bounds of 7 mortality reporting size classes (DBH, inches)
    LOWDBH[1] =  0.0f0
    LOWDBH[2] =  5.0f0
    LOWDBH[3] = 10.0f0
    LOWDBH[4] = 20.0f0
    LOWDBH[5] = 30.0f0
    LOWDBH[6] = 40.0f0
    LOWDBH[7] = 50.0f0

    # Potential fire temperatures (°F) and windspeeds (mi/hr)
    PREWND[1] = 20.0f0   # wildfire
    PREWND[2] =  8.0f0   # prescribed
    POTEMP[1] = 70.0f0   # wildfire
    POTEMP[2] = 60.0f0   # prescribed

    # CWD decay rates: class 1 (pines) — from Radtke analysis
    for j in 1:9
        DKR[j, 1] = 0.11f0
    end

    # Decay rates classes 2-4 (from Abbott & Crossley / Barber & VanLear)
    DKR[1,2] = 0.11f0; DKR[1,3] = DKR[1,2]; DKR[1,4] = DKR[1,2]
    DKR[2,2] = 0.11f0; DKR[2,3] = DKR[2,2]; DKR[2,4] = DKR[2,2]
    DKR[3,2] = 0.09f0; DKR[3,3] = DKR[3,2]; DKR[3,4] = DKR[3,2]
    DKR[4,2] = 0.07f0; DKR[4,3] = DKR[4,2]; DKR[4,4] = DKR[4,2]
    DKR[5,2] = 0.07f0; DKR[5,3] = DKR[5,2]; DKR[5,4] = DKR[5,2]
    DKR[6,2] = 0.07f0; DKR[6,3] = DKR[6,2]; DKR[6,4] = DKR[6,2]
    DKR[7,2] = 0.07f0; DKR[7,3] = DKR[7,2]; DKR[7,4] = DKR[7,2]
    DKR[8,2] = 0.07f0; DKR[8,3] = DKR[8,2]; DKR[8,4] = DKR[8,2]
    DKR[9,2] = 0.07f0; DKR[9,3] = DKR[9,2]; DKR[9,4] = DKR[9,2]

    # Litter (class 10) and duff (class 11) decay rates
    for j in 1:4
        DKR[10,j] = 0.65f0
        DKR[11,j] = 0.002f0
    end

    # Duff production rates (proportion of overall decay rate)
    for i in 1:Int(MXFLCL)
        for j in 1:4
            PRDUFF[i,j] = 0.02f0
            TODUFF[i,j] = DKR[i,j] * PRDUFF[i,j]
        end
    end

    # Snag parameters
    NZERO  = 0.01f0  # snags/stand considered negligible
    LIMBRK = 0.01f0  # fraction non-foliage crown falling per year
    HTXSFT = 2.0f0
    HTR1   = 0.01f0  # height-loss rate first 50%
    HTR2   = 0.01f0  # height-loss rate second 50%
    for i in 1:Int(MAXSP)
        PSOFT[i] = 0.0f0
    end

    # Per-species parameters
    # TFALLCLS: crown component fall-time group (1-6)
    # SNAGCLS: snag persistence class (1=fast, 2=avg, 3=slow)
    # V2T: volume-to-tons (lb/ft³ / 2000); LEAFLF: leaf lifespan (yrs)
    # DKRCLS: decay rate class (1=very slow ... 4=fast)
    tfallcls = zeros(Int32, Int(MAXSP))
    snagcls  = zeros(Int32, Int(MAXSP))

    for i in 1:Int(MAXSP)
        if i == 1        # Fir sp.
            V2T[i] = 20.6f0;  tfallcls[i] = 5;  LEAFLF[i] = 8.0f0;  DKRCLS[i] = 4;  snagcls[i] = 2
        elseif i == 2    # Redcedar
            V2T[i] = 27.4f0;  tfallcls[i] = 1;  LEAFLF[i] = 5.0f0;  DKRCLS[i] = 2;  snagcls[i] = 3
        elseif i == 3    # Spruce
            V2T[i] = 23.1f0;  tfallcls[i] = 5;  LEAFLF[i] = 8.0f0;  DKRCLS[i] = 4;  snagcls[i] = 2
        elseif i == 4    # Sand pine
            V2T[i] = 28.7f0;  tfallcls[i] = 6;  LEAFLF[i] = 2.0f0;  DKRCLS[i] = 1;  snagcls[i] = 1
        elseif i == 5    # Shortleaf pine
            V2T[i] = 29.3f0;  tfallcls[i] = 6;  LEAFLF[i] = 4.0f0;  DKRCLS[i] = 1;  snagcls[i] = 1
        elseif i == 6    # Slash pine
            V2T[i] = 33.7f0;  tfallcls[i] = 6;  LEAFLF[i] = 2.0f0;  DKRCLS[i] = 1;  snagcls[i] = 1
        elseif i == 7    # Spruce pine
            V2T[i] = 25.6f0;  tfallcls[i] = 6;  LEAFLF[i] = 2.0f0;  DKRCLS[i] = 1;  snagcls[i] = 1
        elseif i == 8    # Longleaf pine
            V2T[i] = 33.7f0;  tfallcls[i] = 6;  LEAFLF[i] = 2.0f0;  DKRCLS[i] = 1;  snagcls[i] = 1
        elseif i == 9    # Table Mountain pine
            V2T[i] = 28.1f0;  tfallcls[i] = 6;  LEAFLF[i] = 3.0f0;  DKRCLS[i] = 1;  snagcls[i] = 1
        elseif i == 10   # Pitch pine
            V2T[i] = 29.3f0;  tfallcls[i] = 6;  LEAFLF[i] = 2.0f0;  DKRCLS[i] = 1;  snagcls[i] = 1
        elseif i == 11   # Pond pine
            V2T[i] = 31.8f0;  tfallcls[i] = 6;  LEAFLF[i] = 2.0f0;  DKRCLS[i] = 1;  snagcls[i] = 1
        elseif i == 12   # Eastern white pine
            V2T[i] = 21.2f0;  tfallcls[i] = 6;  LEAFLF[i] = 2.0f0;  DKRCLS[i] = 1;  snagcls[i] = 1
        elseif i == 13   # Loblolly pine
            V2T[i] = 29.3f0;  tfallcls[i] = 6;  LEAFLF[i] = 3.0f0;  DKRCLS[i] = 1;  snagcls[i] = 1
        elseif i == 14   # Virginia pine
            V2T[i] = 28.1f0;  tfallcls[i] = 6;  LEAFLF[i] = 3.0f0;  DKRCLS[i] = 1;  snagcls[i] = 1
        elseif i == 15   # Baldcypress
            V2T[i] = 26.2f0;  tfallcls[i] = 1;  LEAFLF[i] = 1.0f0;  DKRCLS[i] = 3;  snagcls[i] = 3
        elseif i == 16   # Pondcypress
            V2T[i] = 26.2f0;  tfallcls[i] = 1;  LEAFLF[i] = 1.0f0;  DKRCLS[i] = 3;  snagcls[i] = 3
        elseif i == 17   # Hemlock
            V2T[i] = 23.7f0;  tfallcls[i] = 5;  LEAFLF[i] = 4.0f0;  DKRCLS[i] = 4;  snagcls[i] = 2
        elseif i == 18   # Florida maple
            V2T[i] = 34.9f0;  tfallcls[i] = 5;  LEAFLF[i] = 1.0f0;  DKRCLS[i] = 4;  snagcls[i] = 2
        elseif i == 19   # Boxelder
            V2T[i] = 30.6f0;  tfallcls[i] = 5;  LEAFLF[i] = 1.0f0;  DKRCLS[i] = 4;  snagcls[i] = 2
        elseif i == 20   # Red maple
            V2T[i] = 30.6f0;  tfallcls[i] = 5;  LEAFLF[i] = 1.0f0;  DKRCLS[i] = 4;  snagcls[i] = 2
        elseif i == 21   # Silver maple
            V2T[i] = 27.4f0;  tfallcls[i] = 5;  LEAFLF[i] = 1.0f0;  DKRCLS[i] = 4;  snagcls[i] = 2
        elseif i == 22   # Sugar maple
            V2T[i] = 34.9f0;  tfallcls[i] = 5;  LEAFLF[i] = 1.0f0;  DKRCLS[i] = 4;  snagcls[i] = 2
        elseif i == 23   # Buckeye/horsechestnut
            V2T[i] = 34.9f0;  tfallcls[i] = 5;  LEAFLF[i] = 1.0f0;  DKRCLS[i] = 4;  snagcls[i] = 2
        elseif i == 24   # Birch sp.
            V2T[i] = 34.3f0;  tfallcls[i] = 5;  LEAFLF[i] = 1.0f0;  DKRCLS[i] = 4;  snagcls[i] = 1
        elseif i == 25   # Sweet birch
            V2T[i] = 37.4f0;  tfallcls[i] = 5;  LEAFLF[i] = 1.0f0;  DKRCLS[i] = 4;  snagcls[i] = 1
        elseif i == 26   # American hornbeam/musclewood
            V2T[i] = 34.9f0;  tfallcls[i] = 4;  LEAFLF[i] = 1.0f0;  DKRCLS[i] = 3;  snagcls[i] = 2
        elseif i == 27   # Hickory sp.
            V2T[i] = 39.9f0;  tfallcls[i] = 2;  LEAFLF[i] = 1.0f0;  DKRCLS[i] = 4;  snagcls[i] = 3
        elseif i == 28   # Catalpa
            V2T[i] = 34.9f0;  tfallcls[i] = 4;  LEAFLF[i] = 1.0f0;  DKRCLS[i] = 2;  snagcls[i] = 2
        elseif i == 29   # Hackberry
            V2T[i] = 30.6f0;  tfallcls[i] = 4;  LEAFLF[i] = 1.0f0;  DKRCLS[i] = 4;  snagcls[i] = 2
        elseif i == 30   # Eastern redbud
            V2T[i] = 34.9f0;  tfallcls[i] = 5;  LEAFLF[i] = 1.0f0;  DKRCLS[i] = 3;  snagcls[i] = 2
        elseif i == 31   # Flowering dogwood
            V2T[i] = 34.9f0;  tfallcls[i] = 5;  LEAFLF[i] = 1.0f0;  DKRCLS[i] = 3;  snagcls[i] = 2
        elseif i == 32   # Persimmon
            V2T[i] = 34.9f0;  tfallcls[i] = 4;  LEAFLF[i] = 1.0f0;  DKRCLS[i] = 2;  snagcls[i] = 3
        elseif i == 33   # American beech
            V2T[i] = 34.9f0;  tfallcls[i] = 4;  LEAFLF[i] = 1.0f0;  DKRCLS[i] = 4;  snagcls[i] = 2
        elseif i == 34   # Ash
            V2T[i] = 33.1f0;  tfallcls[i] = 5;  LEAFLF[i] = 1.0f0;  DKRCLS[i] = 4;  snagcls[i] = 2
        elseif i == 35   # White ash
            V2T[i] = 34.3f0;  tfallcls[i] = 5;  LEAFLF[i] = 1.0f0;  DKRCLS[i] = 4;  snagcls[i] = 2
        elseif i == 36   # Black ash
            V2T[i] = 28.1f0;  tfallcls[i] = 5;  LEAFLF[i] = 1.0f0;  DKRCLS[i] = 4;  snagcls[i] = 2
        elseif i == 37   # Green ash
            V2T[i] = 33.1f0;  tfallcls[i] = 5;  LEAFLF[i] = 1.0f0;  DKRCLS[i] = 4;  snagcls[i] = 2
        elseif i == 38   # Honeylocust
            V2T[i] = 37.4f0;  tfallcls[i] = 2;  LEAFLF[i] = 1.0f0;  DKRCLS[i] = 2;  snagcls[i] = 3
        elseif i == 39   # Loblolly bay
            V2T[i] = 34.9f0;  tfallcls[i] = 5;  LEAFLF[i] = 1.0f0;  DKRCLS[i] = 4;  snagcls[i] = 2
        elseif i == 40   # Silverbell
            V2T[i] = 34.9f0;  tfallcls[i] = 5;  LEAFLF[i] = 1.0f0;  DKRCLS[i] = 4;  snagcls[i] = 2
        elseif i == 41   # American holly
            V2T[i] = 34.9f0;  tfallcls[i] = 4;  LEAFLF[i] = 3.0f0;  DKRCLS[i] = 3;  snagcls[i] = 2
        elseif i == 42   # Butternut
            V2T[i] = 22.5f0;  tfallcls[i] = 4;  LEAFLF[i] = 1.0f0;  DKRCLS[i] = 4;  snagcls[i] = 2
        elseif i == 43   # Black walnut
            V2T[i] = 31.8f0;  tfallcls[i] = 4;  LEAFLF[i] = 1.0f0;  DKRCLS[i] = 2;  snagcls[i] = 2
        elseif i == 44   # Sweet gum
            V2T[i] = 28.7f0;  tfallcls[i] = 5;  LEAFLF[i] = 1.0f0;  DKRCLS[i] = 4;  snagcls[i] = 2
        elseif i == 45   # Yellow-poplar
            V2T[i] = 24.9f0;  tfallcls[i] = 4;  LEAFLF[i] = 1.0f0;  DKRCLS[i] = 4;  snagcls[i] = 2
        elseif i == 46   # Magnolia sp.
            V2T[i] = 27.4f0;  tfallcls[i] = 4;  LEAFLF[i] = 1.0f0;  DKRCLS[i] = 4;  snagcls[i] = 2
        elseif i == 47   # Cucumbertree
            V2T[i] = 27.4f0;  tfallcls[i] = 4;  LEAFLF[i] = 1.0f0;  DKRCLS[i] = 4;  snagcls[i] = 2
        elseif i == 48   # Southern magnolia
            V2T[i] = 28.7f0;  tfallcls[i] = 4;  LEAFLF[i] = 2.0f0;  DKRCLS[i] = 4;  snagcls[i] = 2
        elseif i == 49   # Sweetbay
            V2T[i] = 27.4f0;  tfallcls[i] = 4;  LEAFLF[i] = 1.0f0;  DKRCLS[i] = 4;  snagcls[i] = 2
        elseif i == 50   # Bigleaf magnolia
            V2T[i] = 27.4f0;  tfallcls[i] = 4;  LEAFLF[i] = 1.0f0;  DKRCLS[i] = 4;  snagcls[i] = 2
        elseif i == 51   # Apple sp.
            V2T[i] = 34.9f0;  tfallcls[i] = 4;  LEAFLF[i] = 1.0f0;  DKRCLS[i] = 3;  snagcls[i] = 2
        elseif i == 52   # Mulberry sp.
            V2T[i] = 34.9f0;  tfallcls[i] = 5;  LEAFLF[i] = 1.0f0;  DKRCLS[i] = 2;  snagcls[i] = 2
        elseif i == 53   # Water tupelo
            V2T[i] = 28.7f0;  tfallcls[i] = 3;  LEAFLF[i] = 1.0f0;  DKRCLS[i] = 2;  snagcls[i] = 3
        elseif i == 54   # Blackgum
            V2T[i] = 28.7f0;  tfallcls[i] = 3;  LEAFLF[i] = 1.0f0;  DKRCLS[i] = 2;  snagcls[i] = 3
        elseif i == 55   # Swamp tupelo
            V2T[i] = 28.7f0;  tfallcls[i] = 3;  LEAFLF[i] = 1.0f0;  DKRCLS[i] = 2;  snagcls[i] = 3
        elseif i == 56   # Eastern hophornbeam/ironwood
            V2T[i] = 34.9f0;  tfallcls[i] = 4;  LEAFLF[i] = 1.0f0;  DKRCLS[i] = 3;  snagcls[i] = 2
        elseif i == 57   # Sourwood
            V2T[i] = 34.9f0;  tfallcls[i] = 5;  LEAFLF[i] = 1.0f0;  DKRCLS[i] = 4;  snagcls[i] = 2
        elseif i == 58   # Redbay
            V2T[i] = 34.9f0;  tfallcls[i] = 5;  LEAFLF[i] = 1.0f0;  DKRCLS[i] = 4;  snagcls[i] = 2
        elseif i == 59   # Sycamore
            V2T[i] = 28.7f0;  tfallcls[i] = 5;  LEAFLF[i] = 1.0f0;  DKRCLS[i] = 4;  snagcls[i] = 2
        elseif i == 60   # Cottonwood
            V2T[i] = 23.1f0;  tfallcls[i] = 5;  LEAFLF[i] = 1.0f0;  DKRCLS[i] = 4;  snagcls[i] = 1
        elseif i == 61   # Bigtooth aspen
            V2T[i] = 22.5f0;  tfallcls[i] = 5;  LEAFLF[i] = 1.0f0;  DKRCLS[i] = 4;  snagcls[i] = 1
        elseif i == 62   # Black cherry
            V2T[i] = 29.3f0;  tfallcls[i] = 4;  LEAFLF[i] = 1.0f0;  DKRCLS[i] = 2;  snagcls[i] = 2
        elseif i == 63   # White oak
            V2T[i] = 37.4f0;  tfallcls[i] = 3;  LEAFLF[i] = 1.0f0;  DKRCLS[i] = 2;  snagcls[i] = 3
        elseif i == 64   # Scarlet oak
            V2T[i] = 37.4f0;  tfallcls[i] = 4;  LEAFLF[i] = 1.0f0;  DKRCLS[i] = 3;  snagcls[i] = 2
        elseif i == 65   # Southern red oak
            V2T[i] = 32.4f0;  tfallcls[i] = 4;  LEAFLF[i] = 1.0f0;  DKRCLS[i] = 3;  snagcls[i] = 2
        elseif i == 66   # Cherrybark oak / swamp red oak
            V2T[i] = 38.0f0;  tfallcls[i] = 4;  LEAFLF[i] = 1.0f0;  DKRCLS[i] = 3;  snagcls[i] = 2
        elseif i == 67   # Turkey oak
            V2T[i] = 34.9f0;  tfallcls[i] = 4;  LEAFLF[i] = 1.0f0;  DKRCLS[i] = 3;  snagcls[i] = 2
        elseif i == 68   # Laurel oak
            V2T[i] = 34.9f0;  tfallcls[i] = 4;  LEAFLF[i] = 1.0f0;  DKRCLS[i] = 3;  snagcls[i] = 2
        elseif i == 69   # Overcup oak
            V2T[i] = 35.6f0;  tfallcls[i] = 3;  LEAFLF[i] = 1.0f0;  DKRCLS[i] = 3;  snagcls[i] = 2
        elseif i == 70   # Blackjack oak
            V2T[i] = 34.9f0;  tfallcls[i] = 2;  LEAFLF[i] = 1.0f0;  DKRCLS[i] = 2;  snagcls[i] = 3
        elseif i == 71   # Swamp chestnut oak
            V2T[i] = 37.4f0;  tfallcls[i] = 3;  LEAFLF[i] = 1.0f0;  DKRCLS[i] = 3;  snagcls[i] = 2
        elseif i == 72   # Chinkapin oak
            V2T[i] = 37.4f0;  tfallcls[i] = 3;  LEAFLF[i] = 1.0f0;  DKRCLS[i] = 2;  snagcls[i] = 3
        elseif i == 73   # Water oak
            V2T[i] = 34.9f0;  tfallcls[i] = 3;  LEAFLF[i] = 1.0f0;  DKRCLS[i] = 2;  snagcls[i] = 3
        elseif i == 74   # Chestnut oak
            V2T[i] = 35.6f0;  tfallcls[i] = 3;  LEAFLF[i] = 1.0f0;  DKRCLS[i] = 3;  snagcls[i] = 2
        elseif i == 75   # Northern red oak
            V2T[i] = 34.9f0;  tfallcls[i] = 4;  LEAFLF[i] = 1.0f0;  DKRCLS[i] = 3;  snagcls[i] = 2
        elseif i == 76   # Shumard oak
            V2T[i] = 34.9f0;  tfallcls[i] = 4;  LEAFLF[i] = 1.0f0;  DKRCLS[i] = 3;  snagcls[i] = 2
        elseif i == 77   # Post oak
            V2T[i] = 37.4f0;  tfallcls[i] = 3;  LEAFLF[i] = 1.0f0;  DKRCLS[i] = 2;  snagcls[i] = 3
        elseif i == 78   # Black oak
            V2T[i] = 34.9f0;  tfallcls[i] = 4;  LEAFLF[i] = 1.0f0;  DKRCLS[i] = 3;  snagcls[i] = 2
        elseif i == 79   # Live oak
            V2T[i] = 49.9f0;  tfallcls[i] = 5;  LEAFLF[i] = 1.0f0;  DKRCLS[i] = 2;  snagcls[i] = 2
        elseif i == 80   # Black locust
            V2T[i] = 41.2f0;  tfallcls[i] = 2;  LEAFLF[i] = 1.0f0;  DKRCLS[i] = 2;  snagcls[i] = 3
        elseif i == 81   # Willow
            V2T[i] = 22.5f0;  tfallcls[i] = 6;  LEAFLF[i] = 1.0f0;  DKRCLS[i] = 4;  snagcls[i] = 1
        elseif i == 82   # Sassafras
            V2T[i] = 26.2f0;  tfallcls[i] = 4;  LEAFLF[i] = 1.0f0;  DKRCLS[i] = 2;  snagcls[i] = 2
        elseif i == 83   # Basswood
            V2T[i] = 20.0f0;  tfallcls[i] = 5;  LEAFLF[i] = 1.0f0;  DKRCLS[i] = 4;  snagcls[i] = 1
        elseif i == 84   # Elm
            V2T[i] = 28.7f0;  tfallcls[i] = 5;  LEAFLF[i] = 1.0f0;  DKRCLS[i] = 4;  snagcls[i] = 1
        elseif i == 85   # Winged elm
            V2T[i] = 28.7f0;  tfallcls[i] = 5;  LEAFLF[i] = 1.0f0;  DKRCLS[i] = 4;  snagcls[i] = 1
        elseif i == 86   # American elm
            V2T[i] = 28.7f0;  tfallcls[i] = 5;  LEAFLF[i] = 1.0f0;  DKRCLS[i] = 4;  snagcls[i] = 1
        elseif i == 87   # Slippery elm
            V2T[i] = 29.9f0;  tfallcls[i] = 5;  LEAFLF[i] = 1.0f0;  DKRCLS[i] = 4;  snagcls[i] = 1
        elseif i == 88   # Softwoods, misc.
            V2T[i] = 27.4f0;  tfallcls[i] = 5;  LEAFLF[i] = 2.0f0;  DKRCLS[i] = 1;  snagcls[i] = 1
        elseif i == 89   # Hardwoods, misc.
            V2T[i] = 34.9f0;  tfallcls[i] = 5;  LEAFLF[i] = 1.0f0;  DKRCLS[i] = 4;  snagcls[i] = 2
        else             # Unknown / not listed (i == 90)
            V2T[i] = 34.9f0;  tfallcls[i] = 5;  LEAFLF[i] = 1.0f0;  DKRCLS[i] = 4;  snagcls[i] = 2
        end

        # Softwood flag (species 1-17 and 88 are conifers)
        LSW[i] = (i >= 1 && i <= 17) || i == 88

        # Foliage fall time (TFALL col 1 = index 1 in 1-based Julia)
        TFALL[i,1] = (i == 2) ? 3.0f0 : 1.0f0   # redcedar foliage lasts 3 yrs

        # Branch component fall times by TFALLCLS group
        if tfallcls[i] == 1        # baldcypress / redcedar
            TFALL[i,2] = 5.0f0; TFALL[i,4] = 10.0f0; TFALL[i,5] = 25.0f0
        elseif tfallcls[i] == 2    # hickory / blackjack oak
            TFALL[i,2] = 3.0f0; TFALL[i,4] =  6.0f0; TFALL[i,5] = 12.0f0
        elseif tfallcls[i] == 3    # white oak
            TFALL[i,2] = 2.0f0; TFALL[i,4] =  5.0f0; TFALL[i,5] = 10.0f0
        elseif tfallcls[i] == 4    # red oak
            TFALL[i,2] = 1.0f0; TFALL[i,4] =  4.0f0; TFALL[i,5] =  8.0f0
        elseif tfallcls[i] == 5    # ash / elm / cottonwood
            TFALL[i,2] = 1.0f0; TFALL[i,4] =  3.0f0; TFALL[i,5] =  6.0f0
        else                        # pines (tfallcls == 6)
            TFALL[i,2] = 1.0f0; TFALL[i,4] =  2.0f0; TFALL[i,5] =  4.0f0
        end
        TFALL[i,3] = TFALL[i,2]   # 0.25–1" same as <0.25"
        TFALL[i,6] = TFALL[i,5]   # 6–12" same as 3–6"

        # Snag class determines decay/fall rate
        if snagcls[i] == 1         # pines and fast-decaying species
            DECAYX[i] = 0.07f0; FALLX[i] = 7.17f0
            ALLDWN[i] = (i >= 4 && i <= 14) ? 50.0f0 : 6.0f0  # pines outlast others
        elseif snagcls[i] == 2     # black oak and average-rate species
            DECAYX[i] = 0.21f0; FALLX[i] = 3.07f0; ALLDWN[i] = 15.0f0
        else                        # snagcls == 3: white oak, redcedar, slow
            DECAYX[i] = 0.35f0; FALLX[i] = 1.96f0
            ALLDWN[i] = (i == 2) ? 100.0f0 : 25.0f0  # redcedar lasts 100 yrs
        end

        # Height-loss multipliers: no height loss in SN variant
        for j in 1:4
            HTX[i,j] = 0.0f0
        end

        # Convert V2T from lb/ft³ to tons/ft³
        V2T[i] = V2T[i] / 2000.0f0
    end

    # Post-burn snag fall rate parameters
    PBSCOR =  0.0f0   # scorch height threshold for post-burn rules
    PBSOFT =  1.0f0   # proportion of soft snags to fall
    PBSMAL =  0.9f0   # proportion of small snags to fall
    PBSIZE = 12.0f0   # DBH dividing small/large snags (inches)
    PBTIME =  7.0f0   # post-burn time period (years)

    # Cover type for fuel model selection (not used in SN/OZ-FFE)
    OLDICT = Int32(0)

    # Drought begin/end years (not used in SN, but set for completeness)
    IDRYB = Int32(0)
    IDRYE = Int32(0)

    # Critical fuel change % to trigger activity fuels state
    SLCRIT = 10.0f0

    return nothing
end
