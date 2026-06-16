# base/dbinit.f — DBINIT: initialize debug subroutine stack
# Translated from: bin/FVSsn_buildDir/dbinit.f (22 lines)

function DBINIT()
    global ALLSUB = "\$**SUB"
    global MAXTOP = Int32(255)
    global ITOP   = Int32(0)
    global MAXLEN = Int32(20)
    fill!(SUBNAM, UInt8(' '))
    return nothing
end
