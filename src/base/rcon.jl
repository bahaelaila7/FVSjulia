# rcon.jl — RCON: load site-dependent model coefficients
# Translated from: base/rcon.f (61 lines)
#
# Called from CRATET before calibration. Calls the CONS entry points
# in each growth model to compute species-specific constants from site variables.

function RCON()
    debug = DBCHK(false, "RCON", Int32(4), ICYC)
    DGCONS()
    HTCONS()
    REGCON()
    MORCON()
    CRCONS()
    if !debug; return nothing; end

    @printf(io_units[Int(JOSTND)], "\n DEBUG TABLE SHOWING VALUES OF MODEL CONSTANTS BY SPECIES\n")
    @printf(io_units[Int(JOSTND)], "DGCON    ")
    for i in 1:Int(MAXSP); @printf(io_units[Int(JOSTND)], "  %10.4f", DGCON[i]); end
    @printf(io_units[Int(JOSTND)], "\n")
    @printf(io_units[Int(JOSTND)], "ATTEN    ")
    for i in 1:Int(MAXSP); @printf(io_units[Int(JOSTND)], "  %10.4f", ATTEN[i]); end
    @printf(io_units[Int(JOSTND)], "\n")
    @printf(io_units[Int(JOSTND)], "HTCON    ")
    for i in 1:Int(MAXSP); @printf(io_units[Int(JOSTND)], "  %10.4f", HTCON[i]); end
    @printf(io_units[Int(JOSTND)], "\n")
    @printf(io_units[Int(JOSTND)], "RHCON    ")
    for i in 1:Int(MAXSP); @printf(io_units[Int(JOSTND)], "  %10.4f", RHCON[i]); end
    @printf(io_units[Int(JOSTND)], "\n")
    @printf(io_units[Int(JOSTND)], "CRCON    ")
    for i in 1:Int(MAXSP); @printf(io_units[Int(JOSTND)], "  %10.4f", CRCON[i]); end
    @printf(io_units[Int(JOSTND)], "\n")
    @printf(io_units[Int(JOSTND)], "\n H2COF=%10.4f,  HDGCOF=%10.4f\n", H2COF, HDGCOF)
    return nothing
end

# REGCON implemented in base/regent.jl
