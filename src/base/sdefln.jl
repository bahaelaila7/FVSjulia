# base/sdefln.jl — SDEFLN: set species-level log-linear defect correction equation
# Translated from: bin/FVSsn_buildDir/sdefln.f (80 lines)
#
# Processes BFFDLN / MCFDLN keywords (board foot / cubic foot defect correction).
# Updates B0[is] and B1[is] for the specified species (or all species).
# Returns IS (species code; -999 if invalid) as return value.

function SDEFLN(lnotbk::AbstractVector,
                array::AbstractVector{Float32},
                keywrd::AbstractString,
                b0::AbstractVector{Float32},
                b1::AbstractVector{Float32},
                kard::AbstractVector)::Int32
    is = SPDECD(Int32(1), NSP, JOSTND, IRECNT, keywrd, array, kard)
    if is == Int32(-999); return is; end

    io = io_units[JOSTND]
    @printf(io, "\n %-8s   COEFFICIENTS FOR LOG-LINEAR FORM AND DEFECT CORRECTION EQUATION\n", keywrd)

    if is < Int32(0)
        igrp = -Int(is)
        iulim = Int(ISPGRP[igrp, 1]) + 1
        igsp  = Int32(0)
        for ig in 2:iulim
            igsp = Int(ISPGRP[igrp, ig])
            if lnotbk[2]; b0[igsp] = array[2]; end
            if lnotbk[3]; b1[igsp] = array[3]; end
        end
        ilen = Int(ISPGRP[igrp, 92])
        ilen = max(1, min(ilen, length(String(kard[1]))))
        @printf(io, "             SPECIES= %s (CODE= %2d); B0=%8.5f; B1=%8.5f\n",
                String(kard[1])[1:ilen], is, b0[Int(igsp)], b1[Int(igsp)])

    elseif is == Int32(0)
        for k in 1:Int(MAXSP)
            if lnotbk[2]; b0[k] = array[2]; end
            if lnotbk[3]; b1[k] = array[3]; end
        end
        @printf(io, "             FOR ALL SPECIES THE FOLLOWING COEFFICIENTS HAVE BEEN SPECIFIED:\n")
        for i in 2:3
            js = i - 2
            if lnotbk[i]
                @printf(io, "                       B%1d= %8.5f\n", js, array[i])
            end
        end

    else
        if lnotbk[2]; b0[Int(is)] = array[2]; end
        if lnotbk[3]; b1[Int(is)] = array[3]; end
        @printf(io, "             SPECIES= %3s (CODE= %2d); B0=%8.5f; B1=%8.5f\n",
                String(kard[1])[1:min(3,length(String(kard[1])))], is,
                b0[Int(is)], b1[Int(is)])
    end

    return is
end
