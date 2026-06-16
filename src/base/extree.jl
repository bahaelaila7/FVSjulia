# extree.jl — EXTREE: assign example trees to output arrays
# Translated from: extree.f (62 lines)

function EXTREE()
    if ITRN == 0
        @goto label_20
    end
    for i in 1:6
        ins1 = Int(INS[i])
        imci = Int(IMC[ins1])
        isp1 = Int(ISP[ins1])
        IONSP[i] = NSP[isp1, imci][1:3]
        DBHIO[i] = DBH[ins1]
        HTIO[i]  = HT[ins1]
        IOICR[i] = ICR[ins1]
        DGIO[i]  = DG[ins1]
        PCTIO[i] = PCT[ins1]
        PRBIO[i] = PROB[ins1] / TRM
    end
    return nothing

    @label label_20
    for i in 1:6
        IONSP[i] = "---"
        DBHIO[i] = Float32(0)
        HTIO[i]  = Float32(0)
        IOICR[i] = Int32(0)
        DGIO[i]  = Float32(0)
        PCTIO[i] = Float32(0)
        PRBIO[i] = Float32(0)
    end
    return nothing
end
