# base/dbadd.f — DBADD: add a subroutine name + cycle to SUBNAM debug stack
# Translated from: bin/FVSsn_buildDir/dbadd.f (39 lines)
#
# Each entry in SUBNAM is NC+4 bytes:
#   SUBIN[1..NC]  ' '  <2-digit ICYC>  ' '
# ITOP advances to the position of the final ' '.

function DBADD(subin::AbstractString, nc::Int32, icyc::Int32, irc::Ref{Int32})
    iplen = ITOP + nc + 4
    if iplen < MAXTOP
        for i in 1:Int(nc)
            global ITOP += Int32(1)
            SUBNAM[ITOP] = UInt8(subin[i])
        end
        global ITOP += Int32(1)
        SUBNAM[ITOP] = UInt8(' ')          # separator after name
        global ITOP += Int32(3)
        SUBNAM[ITOP] = UInt8(' ')          # terminal space (position NC+4)
        is_pos = Int(ITOP) - 2             # IS = NC+2
        ie_pos = Int(ITOP) - 1             # IE = NC+3
        cyc_s = CH2NUM(icyc)               # 2-char cycle string (e.g. " 5" or "10")
        SUBNAM[is_pos] = UInt8(cyc_s[1])
        SUBNAM[ie_pos] = UInt8(cyc_s[2])
        irc[] = Int32(0)
    else
        irc[] = Int32(2)
    end
    return nothing
end
