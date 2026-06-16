# base/dball.f — DBALL: add all-subroutines debug entry
# Translated from: bin/FVSsn_buildDir/dball.f (27 lines)
#
# If ICYC is out of range: re-initialize the stack and add ALLSUB for all cycles.
# Otherwise: add ALLSUB for the specific cycle ICYC.

function DBALL(icyc::Int32)
    irc = Ref(Int32(0))
    if icyc < Int32(1) || icyc > Int32(MAXCYC)
        DBINIT()
        DBADD(ALLSUB, Int32(6), Int32(0), irc)
    else
        DBADD(ALLSUB, Int32(6), icyc, irc)
    end
    return nothing
end
