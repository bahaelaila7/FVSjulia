# sn/findag.f — FINDAG: find effective tree age from height using HTCALC mode 0
# Translated from: bin/FVSsn_buildDir/findag.f (69 lines)
#
# Called from CRATET and COMCUP.
# Sets SITAGE = age corresponding to height H.
# If H >= HTMAX, recalculates using HM1 = HTMAX - 1.1 ft (stable range).

function FINDAG(i::Int32, ispc::Int32, d1::Float32, d2::Float32, h::Float32,
                sitage::Ref{Float32}, sitht::Ref{Float32},
                agmax1::Float32, htmax1::Float32, htmax2::Float32, debug::Bool)
    mode0  = Int32(0)
    sitht[] = h

    aget_r  = Ref(Float32(0.0))
    h_r     = Ref(h)
    htmax_r = Ref(Float32(0.0))
    htg1_r  = Ref(Float32(0.0))
    HTCALC(mode0, ispc, aget_r, h_r, htmax_r, htg1_r, JOSTND, debug)

    if htmax_r[] - h <= Float32(1.0)
        hm1    = htmax_r[] - Float32(1.1)
        mode0  = Int32(0)
        sitht[] = hm1
        aget_r[]  = Float32(0.0)
        h_r[]     = hm1
        htmax_r[] = Float32(0.0)
        htg1_r[]  = Float32(0.0)
        HTCALC(mode0, ispc, aget_r, h_r, htmax_r, htg1_r, JOSTND, debug)
    end

    sitage[] = aget_r[]

    if debug
        @printf(io_units[JOSTND],
            " LEAVING SUBROUTINE FINDAG I,ISPC,SITAGE,SITHT= %5d%5d%10.4f%10.4f\n",
            i, ispc, sitage[], sitht[])
    end
    return nothing
end
