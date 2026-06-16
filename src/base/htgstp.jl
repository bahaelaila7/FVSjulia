# htgstp.jl — HTGSTP: height growth stop / top-kill (keywords 110/111)
# Translated from: htgstp.f (200 lines)
#
# Processes HTGSTOP (act=110) and TOPKILL (act=111) keyword activities.
# For each tree in the selected height range with selected species:
#   - HTGSTOP: multiplies HTG by a Batchelor-normal factor PKIL
#   - TOPKILL:  physically reduces HT(I) by TOPK, adjusts ICR and IMC

function HTGSTP()
    myact = Int32[110, 111]
    ntodo_ref = Ref(Int32(0))
    OPFIND(Int32(2), myact, ntodo_ref)
    ntodo = ntodo_ref[]
    if ntodo == 0; return nothing; end

    for itodo in 1:Int(ntodo)
        idt_r  = Ref(Int32(0)); iact_r = Ref(Int32(0))
        np_r   = Ref(Int32(0))
        OPGET(Int32(itodo), Int32(6), idt_r, iact_r, np_r, WK6)
        if iact_r[] < 0; continue; end
        OPDONE(Int32(itodo), IY[Int(ICYC)])

        ispc_v = Int(floor(WK6[1]))
        ht1    = WK6[2]; ht2 = WK6[3]
        prb    = WK6[4]; aveprb = WK6[5]; stdpbr = WK6[6]
        iact   = Int(iact_r[])

        # Species loop bounds
        is1, is2 = if ispc_v <= 0
            1, MAXSP
        else
            ispc_v, ispc_v
        end

        for isv in is1:is2
            i1 = ISCT[isv, 1]
            if i1 == 0; continue; end
            i2 = ISCT[isv, 2]

            # Species group filter
            if ispc_v < 0
                igrp  = -ispc_v
                iulim = Int(ISPGRP[igrp, 1]) + 1
                found = false
                for ig in 2:iulim
                    if isv == Int(ISPGRP[igrp, ig]); found = true; break; end
                end
                if !found; continue; end
            end

            for k in i1:i2
                i = Int(IND1[k])
                h = HT[i]
                brk = BRATIO(isv, DBH[i], h)
                if h <= ht1 || h > ht2; continue; end

                # Probability check
                if prb <= Float32(0.99999)
                    x_ref = Ref(Float32(0))
                    RANN(x_ref)
                    if x_ref[] > prb; continue; end
                end

                pkil = BACHLO(aveprb, stdpbr)
                if pkil <= Float32(0); continue; end

                if iact == 110  # HTGSTOP
                    if pkil >= Float32(1); pkil = Float32(1); end
                    HTG[i] = HTG[i] * pkil
                    ABIRTH[i] = Float32(0)
                else            # TOPKILL
                    if pkil > Float32(0.8); pkil = Float32(0.8); end
                    topk  = h * pkil
                    toph  = h - topk
                    itrc2 = Int(floor(toph * Float32(100) + Float32(0.5)))
                    itrc1 = Int(ITRUNC[i])
                    if itrc1 > 0
                        if itrc1 > itrc2; ITRUNC[i] = Int32(itrc2); end
                        HT[i] = toph
                        continue
                    end
                    # Not yet top-killed
                    d = DBH[i] * brk
                    if h < Float32(25) || d < Float32(6)
                        HT[i] = toph
                    else
                        # Compute diameter at topkill using Behre hyperboloid
                        af = CFV[i] / (Float32(0.00545415) * d * d * h)
                        af = Float32(0.44244) - (Float32(0.99167)/af) -
                             (Float32(1.43237)*log(af)) +
                             (Float32(1.68581)*sqrt(af)) -
                             (Float32(0.13611)*af*af)
                        dtk = topk / h
                        dtk = (dtk / (af*dtk + Float32(1) - af)) * d
                        if dtk < Float32(4)
                            HT[i] = toph
                        else
                            ITRUNC[i] = Int32(itrc2)
                            NORMHT[i] = Int32(floor(h * Float32(100) + Float32(0.5)))
                            IMC[i] = Int32(3)
                            HT[i] = toph
                        end
                    end
                    # Adjust crown ratio
                    iod = Int(ICR[i])
                    if iod < 0; continue; end
                    cn  = (Float32(iod) / Float32(100) * h) - h + toph
                    new = Int(floor(cn / toph * Float32(100) + Float32(0.5)))
                    if new < 5; new = 5; end
                    ICR[i] = Int32(-new)
                    if IMC[i] == 1; IMC[i] = Int32(2); end
                end
            end
        end
    end
    return nothing
end
