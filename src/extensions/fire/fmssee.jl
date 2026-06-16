# SUBROUTINE FMSSEE(IT,JSP,D,H,SNUM,ITYP,DEBUG,IOUT)
# Translated from: fmssee.f (83 lines)
#
# Records new-snag height ranges and density by species+DBH class so FMSADD
# knows which classes to split into two height classes.
# Called from: FMSCUT, FMKILL, CRATET

function FMSSEE(it::Integer, jsp::Integer, d::Real, h::Real, snum::Real,
                ityp::Integer, debug::Bool, iout::Integer)
    if !LFMON; return nothing; end
    if debug
        @printf(get(io_units, Int32(iout), stdout),
                " IN FMSSEE, IT=%4d JSP=%3d D=%7.3f H=%7.3f SNUM=%7.3f ITYP=%3d\n",
                it, jsp, d, h, snum, ityp)
    end
    if snum <= 0.0f0; return nothing; end

    SNGNEW[it] = Float32(snum)

    local dbhcl::Int32 = d >= 36.0f0 ? Int32(19) : Int32(floor(d / 2.0f0 + 1.0f0))

    if Float32(h) > MAXHT[jsp, dbhcl]; MAXHT[jsp, dbhcl] = Float32(h); end
    if Float32(h) < MINHT[jsp, dbhcl]; MINHT[jsp, dbhcl] = Float32(h); end
    DSPDBH[jsp, dbhcl] += Float32(snum)

    if ityp == 4; SNGNEW[it] = 0.0f0; end
    return nothing
end
