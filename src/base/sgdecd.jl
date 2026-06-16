# sgdecd.f — SGDECD: decode species group name
# Translated from: bin/FVSsn_buildDir/sgdecd.f (88 lines)
#
# ISPC  = numeric species code (passed by reference; modified if group found)
# KARD  = 10-char string representation of species field (modified on match)
# IFLAG = 0 if not a group; 1 if found
# Uses NAMGRP / NSPGRP from contrl.jl

function SGDECD(ispc::Ref{Int32}, kard::Ref{String}, iflag::Ref{Int32})
    s = ispc[]

    if s > Int32(0)
        iflag[] = Int32(0)
        return nothing
    end

    if s < Int32(0)
        # negative index means it's already a group
        kard[] = rpad(NAMGRP[-s], 10)[1:10]
        iflag[] = Int32(1)
        return nothing
    end

    # s == 0: check if KARD contains an alpha group name
    k = kard[]
    # find first non-blank position and extract up to 10 chars
    temp = "          "
    found = false
    for i in 1:min(10, length(k))
        c = k[i:i]
        if c != " "
            # copy from position i, up to 10-i+1 chars
            n = min(10, length(k) - i + 1)
            temp = uppercase(k[i:i+n-1])
            temp = rpad(temp, 10)[1:10]
            found = true
            break
        end
    end

    if !found
        iflag[] = Int32(0)
        return nothing
    end

    temp = rpad(temp, 10)[1:10]

    # 'ALL' is species code zero, not a valid group name
    if strip(temp) == "ALL"
        iflag[] = Int32(0)
        return nothing
    end

    # search NAMGRP for match
    for i in 1:NSPGRP
        if rpad(temp, 10)[1:10] == rpad(NAMGRP[i], 10)[1:10]
            ispc[] = Int32(-i)
            iflag[] = Int32(1)
            kard[]  = temp
            return nothing
        end
    end

    iflag[] = Int32(0)
    return nothing
end
