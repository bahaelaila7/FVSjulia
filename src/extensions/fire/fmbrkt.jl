# fmbrkt.f — Bark thickness for fire-caused mortality (SN-specific)
# FMBRKT: returns bark char depth in inches from DBH and species index
# ISP=5 (shortleaf pine) uses Harmon 1984 equation

function FMBRKT(dbh::Real, isp::Integer)::Float32
    # 39 bark thickness coefficients indexed by EQNUM(ISP)
    B1 = Float32[
        0.019, 0.022, 0.024, 0.025, 0.026, 0.027, 0.028, 0.029, 0.030,
        0.031, 0.032, 0.033, 0.034, 0.035, 0.036, 0.037, 0.038, 0.039, 0.040,
        0.041, 0.042, 0.043, 0.044, 0.045, 0.046, 0.047, 0.048, 0.049, 0.050,
        0.052, 0.055, 0.057, 0.059, 0.060, 0.062, 0.063, 0.068, 0.072, 0.081]

    # 90-entry map from SN species index to B1 coefficient index
    EQNUM = Int32[
        30,  # 1  fir sp.
        17,  # 2  redcedar
        13,  # 3  spruce sp.
        14,  # 4  sand pine
        16,  # 5  shortleaf pine
        31,  # 6  slash pine
        14,  # 7  spruce pine
        28,  # 8  longleaf pine
        19,  # 9  table mountain pine
        24,  # 10 pitch pine
        35,  # 11 pond pine
        24,  # 12 eastern white pine
        30,  # 13 loblolly pine
        12,  # 14 virginia pine
         4,  # 15 baldcypress
        21,  # 16 pondcypress
        18,  # 17 hemlock
         8,  # 18 Florida maple
        13,  # 19 boxelder
         7,  # 20 red maple
        10,  # 21 silver maple
        12,  # 22 sugar maple
        15,  # 23 buckeye/horsechestnut
        12,  # 24 birch sp.
         9,  # 25 sweet birch
         9,  # 26 american hornbeam
        19,  # 27 hickory sp.
        16,  # 28 catalpa
        15,  # 29 hackberry sp.
        14,  # 30 eastern redbud
        20,  # 31 flowering dogwood
        20,  # 32 common persimmon
         4,  # 33 american beech
        21,  # 34 ash sp.
        21,  # 35 white ash
        14,  # 36 black ash
        18,  # 37 green ash
        17,  # 38 honeylocust
        17,  # 39 loblolly-bay
        17,  # 40 silverbell
        21,  # 41 american holly
        20,  # 42 butternut
        20,  # 43 black walnut
        15,  # 44 sweet gum
        20,  # 45 yellow-poplar
        18,  # 46 magnolia sp.
        15,  # 47 cucumbertree
        12,  # 48 southern magnolia
        19,  # 49 sweetbay
        12,  # 50 bigleaf magnolia
        22,  # 51 apple sp.
        17,  # 52 mulberry sp.
         9,  # 53 water tupelo
        18,  # 54 black gum
        16,  # 55 swamp tupelo
        16,  # 56 e. hophornbeam
        15,  # 57 sourwood
        17,  # 58 redbay
        12,  # 59 sycamore
        19,  # 60 cottonwood
        18,  # 61 bigtooth aspen
         9,  # 62 black cherry
        19,  # 63 white oak
        19,  # 64 scarlet oak
        23,  # 65 southern red oak
        23,  # 66 cherrybark oak
        16,  # 67 turkey oak
        15,  # 68 laurel oak
        18,  # 69 overcup oak
        16,  # 70 blackjack oak
        25,  # 71 swamp chestnut oak
        21,  # 72 chinkapin oak
        15,  # 73 water oak
        28,  # 74 chestnut oak
        21,  # 75 northern red oak
        16,  # 76 shumard oak
        23,  # 77 post oak
        24,  # 78 black oak
        22,  # 79 live oak
        28,  # 80 black locust
        19,  # 81 willow
        14,  # 82 sassafras
        17,  # 83 basswood
        18,  # 84 elm sp.
        10,  # 85 winged elm
        10,  # 86 american elm
        11,  # 87 slippery elm
        17,  # 88 softwoods misc.
        24,  # 89 hardwoods misc.
        24]  # 90 unknown/not listed

    local d::Float32 = Float32(dbh)

    # Special case: shortleaf pine (ISP=5) — Harmon (1984) Ecology 65(3)
    if isp == 5
        local bkt::Float32 = (0.07f0 + 0.09f0 * d * 2.54f0 - 0.0001f0 * d * d * 2.54f0 * 2.54f0) / 2.54f0
        return max(0.0f0, bkt)
    end

    return d * B1[EQNUM[isp]]
end
