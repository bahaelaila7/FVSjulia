# sn/grohed.f — GROHED: write FVS header for Southern variant
# Translated from: bin/FVSsn_buildDir/grohed.f (37 lines)
#
# Overrides the stub GROHED defined in base/keywd.jl.
# Writes variant name, revision date, and run date/time.

function GROHED(iunit::Int32)
    rev = Ref("")
    REVISE(VARACD, rev)

    dat = Ref("")
    tim = Ref("")
    GRDTIM(dat, tim)

    @printf(io_units[iunit],
        "\n\n     FOREST VEGETATION SIMULATOR     VERSION %-8s -- SOUTHERN U.S. PROGNOSIS%*sRV:%-10s%11s  %-8s\n",
        SVN_VERSION, max(0, 97 - 6 - 8 - 31 - length(SVN_VERSION)), "",
        rev[], dat[], tim[])
    return nothing
end
