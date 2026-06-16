# spdecd.f — SPDECD: decode species code (numeric, alpha, or group)
# Translated from: bin/FVSsn_buildDir/spdecd.f (128 lines)
#
# Julia calling convention (from initre.jl):
#   is = SPDECD(ipos, NSP, JOSTND, IRECNT, keywrd, array, kard)
# Returns ISP: 1..MAXSP = single species, 0 = "ALL", <0 = group index, -999 = error
# Side effects: array[ipos] = Float32(ISP), kard[ipos] = 2-char alpha code

function SPDECD(ipos::Int32, cnsp::Matrix{String}, jostnd::Int32, irecnt::Int32,
                keywrd::AbstractString, array::Vector{Float32}, kard::Vector{String})::Int32

    isp = Int32(trunc(array[ipos]))

    # check for species group name via SGDECD
    iflag = Ref(Int32(0))
    ispc  = Ref(isp)
    kref  = Ref(kard[ipos])
    SGDECD(ispc, kref, iflag)
    if iflag[] != Int32(0)
        array[ipos] = Float32(ispc[])
        kard[ipos]  = kref[]
        return ispc[]
    end
    isp = ispc[]

    if isp >= Int32(0) && isp <= Int32(MAXSP)
        if isp == Int32(0)
            # try alpha decode from KARD[ipos]
            k    = kard[ipos]
            temp = "ALL "   # default = ALL (species code 0)
            got_temp = false
            for i in 1:min(10, length(k))
                if k[i:i] != " "
                    # check for literal '0' → means "ALL"
                    found_zero = false
                    sub = ""
                    for j in 1:min(3, length(k) - i + 1)
                        ch = k[i+j-1:i+j-1]
                        if ch == "0"
                            temp = "ALL "
                            found_zero = true
                            break
                        end
                        sub = sub * uppercase(ch)
                    end
                    if !found_zero
                        temp = rpad(sub, 4)[1:4]
                        got_temp = true
                    end
                    break
                end
            end

            if strip(temp) != "ALL"
                # right-justify one-char codes
                t2 = length(strip(temp)) == 1 ? " " * strip(temp) : rpad(strip(temp), 2)[1:2]
                found_spc = false
                for i in 1:MAXSP
                    c2 = length(cnsp[i,1]) >= 2 ? cnsp[i,1][1:2] : rpad(cnsp[i,1], 2)[1:2]
                    if t2 == c2
                        isp = Int32(i)
                        found_spc = true
                        break
                    end
                end
                if !found_spc
                    KEYDMP(jostnd, irecnt, keywrd, array, kard)
                    if strip(keywrd) == "SPGROUP"
                        ERRGRO(true, Int32(29))
                    else
                        ERRGRO(true, Int32(4))
                    end
                    kard[ipos] = rpad(temp, 10)[1:10]
                    return Int32(-999)
                end
            end

            kard[ipos]  = rpad(temp, 10)[1:10]
            array[ipos] = Float32(isp)
        else
            # numeric species code in array[ipos]: load alpha code into kard
            isp         = Int32(trunc(array[ipos]))
            kard[ipos]  = length(cnsp[isp,1]) >= 2 ? cnsp[isp,1][1:2] : cnsp[isp,1]
        end
    else
        KEYDMP(jostnd, irecnt, keywrd, array, kard)
        if strip(keywrd) == "SPGROUP"
            ERRGRO(true, Int32(29))
        else
            ERRGRO(true, Int32(4))
        end
        return Int32(-999)
    end

    return isp
end
