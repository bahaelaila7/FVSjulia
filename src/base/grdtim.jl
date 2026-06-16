# grdtim.f — GRDTIM: return formatted date and time strings for output headers
# Translated from: bin/FVSsn_buildDir/grdtim.f (89 lines)

function GRDTIM(dat::Ref{String}, tim::Ref{String})
    now = Dates.now()
    dat[] = @sprintf("%02d-%02d-%04d", Dates.month(now), Dates.day(now), Dates.year(now))
    tim[] = @sprintf("%02d:%02d:%02d", Dates.hour(now), Dates.minute(now), Dates.second(now))
    return nothing
end
