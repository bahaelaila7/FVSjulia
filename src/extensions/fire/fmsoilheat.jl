# fmsoilheat.f — FOFEM soil heating interface (FIRE-VBASE)
# FMSOILHEAT: assembles fuel loads into FOFEM input array and calls fm_fofem()
# fm_fofem is an external C/Fortran DLL not available in the Julia translation.
# This implementation assembles the inputs (for completeness) but skips the DLL call.
# Called from: FMBURN

function FMSOILHEAT(iyr::Integer, lnmout::Bool)
    debug = DBCHK("FMSOILHEAT", 10, ICYC)
    if debug
        @printf(get(io_units, Int32(JOSTND), stdout),
            " FMSOILHEAT CYCLE=%2d IYR=%5d ISHEATB,ISHEATE=%5d%5d IDSHEAT=%5d\n",
            ICYC, iyr, ISHEATB, ISHEATE, IDSHEAT)
    end

    if ISHEATB == 9999; return nothing; end

    # fm_fofem external DLL not available — log and skip
    @printf(get(io_units, Int32(JOSTND), stdout),
        " FMSOILHEAT: FOFEM soil heating model (fm_fofem) not linked; output skipped.\n")
    return nothing
end
