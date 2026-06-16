# opsame.jl — OPSAME: delete duplicate activity groups in event monitor branching
# Translated from: opsame.f (176 lines)
# Called from EVMON to prune activity groups with identical activities.

function OPSAME(mae_ref::Ref{Int32}, maelnk::AbstractMatrix{Int32},
                iout::Integer, ldeb::Bool)
    mae = Int(mae_ref[])
    if mae <= 1; return nothing; end

    io = io_units[Int32(iout)]
    idel = 0

    for i1 in 1:(mae-1)
        j1 = Int(maelnk[1, i1])
        if ldeb; @printf(io, " IN OPSAME: I1,J1=%4d%4d\n", i1, j1); end
        if j1 == 0; continue; end
        if IEVACT[j1, 6] != 0; continue; end

        mf1 = Int(IEVACT[j1, 4])
        mf2 = Int(IEVACT[j1, 5])
        nmf = mf1 - mf2 + 1

        for i2 in (i1+1):mae
            j2 = Int(maelnk[1, i2])
            if ldeb; @printf(io, " IN OPSAME: I2,J2=%4d%4d\n", i2, j2); end
            if j2 == 0; continue; end
            if IEVACT[j2, 6] != 0; continue; end
            ms1 = Int(IEVACT[j2, 4])

            # Both empty sets
            if mf1 == 0 && ms1 == 0
                @goto label_35
            end

            ms2 = Int(IEVACT[j2, 5])
            nms = ms1 - ms2 + 1
            if nmf != nms; continue; end

            # Compare activities one by one
            mfa = mf1 + 1; msa = ms1 + 1
            equal = true
            for ia in 1:nmf
                mfa -= 1; msa -= 1
                if IACT[mfa, 1] != IACT[msa, 1]; equal = false; break; end
                ipf1 = Int(IACT[mfa, 2])
                if ipf1 < 0; equal = false; break; end
                ipf2 = Int(IACT[mfa, 3])
                ips1 = Int(IACT[msa, 2])
                if ips1 < 0; equal = false; break; end
                ips2 = Int(IACT[msa, 3])
                npf  = ipf2 - ipf1 + 1
                nps  = ips2 - ips1 + 1
                if npf != nps; equal = false; break; end
                if npf == 0; continue; end
                ips  = ips1 - 1
                for ipf in ipf1:ipf2
                    ips += 1
                    if PARMS[ipf] != PARMS[ips]; equal = false; break; end
                end
                if !equal; break; end
            end
            if !equal; continue; end

            @label label_35
            if ldeb; @printf(io, " IN OPSAME: LBSETS=%s\n", LBSETS); end

            if LBSETS
                if ldeb
                    @printf(io, " IN OPSAME: AGLSET(J1)=%s\n", AGLSET[j1][1:LENAGL[j1]])
                    @printf(io, " IN OPSAME: AGLSET(J2)=%s\n", AGLSET[j2][1:LENAGL[j2]])
                end
                lnunin = Ref(Int32(0))
                kode   = Ref(Int32(0))
                LBUNIN(LENAGL[j1], AGLSET[j1], LENAGL[j2], AGLSET[j2],
                       lnunin, WKSTR1, kode)
                if kode[] > 0; continue; end
                LENAGL[j1] = lnunin[]
                AGLSET[j1] = WKSTR1
            end

            maelnk[1, i2] = Int32(0)
            idel += 1
            if ldeb
                @printf(io, " IN OPSAME: AGLSET(J1)=%s\n", AGLSET[j1][1:LENAGL[j1]])
                @printf(io, " IN OPSAME: KODE,IDEL=%4d%4d\n", 0, idel)
            end
        end
    end

    if idel == 0; return nothing; end

    if idel == mae
        mae_ref[] = Int32(0)
        return nothing
    end

    # Compress maelnk
    idel2 = 0
    for i in 1:mae
        if maelnk[1, i] > 0
            idel2 += 1
            maelnk[1, idel2] = maelnk[1, i]
            maelnk[2, idel2] = maelnk[2, i]
        end
    end
    mae_ref[] = Int32(idel2)
    return nothing
end
