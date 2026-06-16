# base/cutstk.jl — CUTSTK entry points: stocking calculation helpers
# Translated from: bin/FVSsn_buildDir/cutstk.f (110 lines)
#
# AUTSTK(fstock) — compute normal SDI stocking for automatic thins; returns fstock
# CLSSTK(...)    — compute TPA or BA stocking in a specified DBH/HT/species class

function AUTSTK()::Float32
    totba = Float32(0)
    temba = Float32(0)

    for i in 1:Int(ITRN)
        ispc = Int(ISP[i])
        tba  = Float32(0.0054542) * DBH[i] * DBH[i] * PROB[i]
        temba += tba * SDIDEF[ispc]
        totba += tba
    end

    if totba <= Float32(1) || temba <= Float32(1)
        return Float32(0)
    end

    tmpmax = temba / totba
    fstock = Float32(1) / (Float32(0.02483133) / tmpmax * Float32(2)^Float32(1.605))
    if RMSQD > Float32(2)
        fstock = Float32(1) / (Float32(0.02483133) / tmpmax * RMSQD^Float32(1.605))
    end
    return fstock
end

function CLSSTK(jtyp::Integer, jspcut::Integer,
                dl::Float32, du::Float32,
                hl::Float32, hu::Float32,
                jpnum::Integer)::Float32
    cstock = Float32(0)

    for ic in 1:Int(ITRN)
        if jpnum > 0 && ITRE[ic] != Int32(jpnum); continue; end

        lincl = false
        if (jspcut == 0 || jspcut == Int(ISP[ic])) && !LEAVESP[Int(ISP[ic])]
            lincl = true
        elseif jspcut < 0
            igrp  = -jspcut
            iulim = Int(ISPGRP[igrp, 1]) + 1
            for ig in 2:iulim
                if ISP[ic] == ISPGRP[igrp, ig] && !LEAVESP[Int(ISP[ic])]
                    lincl = true
                    break
                end
            end
        end

        if lincl
            d   = DBH[ic]
            h   = HT[ic]
            tpa = WK4[ic]
            if jpnum > 0
                tpa = tpa * (PI - Float32(NONSTK))
            end
            if d < dl || d >= du; continue; end
            if h < hl || h >= hu; continue; end
            if jtyp == 1
                cstock += tpa
            else
                cstock += tpa * (d * d * Float32(0.005454154))
            end
        end
    end
    return cstock
end
