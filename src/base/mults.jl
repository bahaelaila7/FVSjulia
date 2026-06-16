# base/mults.jl — MULTS: apply species multiplier keywords
# Translated from: bin/FVSsn_buildDir/mults.f (90 lines)
#
# KIND codes: 1=BAIMULT, 2=HTGMULT, 3=REGHMULT, 4=MORTMULT,
#             5=ESTBMULT, 6=REGDMULT, 7=MANAGED
# Activity codes: 91,92,93,94,95,96,82 (one per KIND in that order)
# Modifies XMULT in-place for the matching species.

const _MULTS_ACTS = Int32[91, 92, 93, 94, 95, 96, 82]

function MULTS(kind::Integer, idt::Integer, xmult::AbstractVector{Float32})
    if kind < 1 || kind > 7; return nothing; end

    ntodo = OPFIND(Int32(1), Int32[_MULTS_ACTS[kind]])
    if ntodo == Int32(0); return nothing; end

    prm = zeros(Float32, 2)
    for i in 1:Int(ntodo)
        iactk, idt_done, np = OPGET(i, 2, prm)
        if iactk < Int32(0); continue; end
        OPDONE(i, Int(idt))

        if kind == 7
            xmult[1] = prm[1]
            continue
        end

        isp = Int(trunc(prm[1]))
        if isp < 0
            igrp = -isp
            iulim = Int(ISPGRP[igrp, 1]) + 1
            for ig in 2:iulim
                ispg = Int(ISPGRP[igrp, ig])
                xmult[ispg] = prm[2]
            end
        elseif isp == 0
            for k in 1:Int(MAXSP)
                xmult[k] = prm[2]
            end
        else
            xmult[isp] = prm[2]
        end
    end
    return nothing
end
