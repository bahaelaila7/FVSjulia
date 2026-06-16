# ptgdecd.f — PTGDECD: decode point group name
# Translated from: bin/FVSsn_buildDir/ptgdecd.f (70 lines)
#
# POINTNO = numeric point number; if alpha group name found, set to -group_index
# KARD    = 10-char field (modified to upper-stripped name on match)
# IFLAG   = 0 if not a group; 1 if found

function PTGDECD(pointno::Ref{Int32}, kard::Ref{String}, iflag::Ref{Int32})
    if pointno[] > Int32(0)
        iflag[] = Int32(0)
        return nothing
    end

    # POINTNO == 0: search for alpha group name in KARD
    k = kard[]
    temp = "          "
    for i in 1:min(10, length(k))
        if k[i:i] != " "
            n = min(10, length(k) - i + 1)
            temp = uppercase(k[i:i+n-1])
            temp = rpad(temp, 10)[1:10]
            break
        end
    end

    for i in 1:NPTGRP
        if rpad(temp, 10)[1:10] == rpad(PTGNAME[i], 10)[1:10]
            pointno[] = Int32(-i)
            iflag[]   = Int32(1)
            kard[]    = temp
            return nothing
        end
    end

    iflag[] = Int32(0)
    return nothing
end
