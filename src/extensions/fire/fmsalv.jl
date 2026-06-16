# fire/fmsalv.f — Remove existing snags per SALVAGE/SALVSP keywords
# Tracks removed volume (CUTVOL), density (SALVTPA), and computes CWDCUT
# for proportional removal of future crown debris from CWD2B.
# Called from: CUTS

function FMSALV(iyr::Integer, salvtpa_ref::Ref{Float32})
    debug = DBCHK("FMSALV", 6, ICYC)
    if debug
        @printf(get(io_units, Int32(JOSTND), stdout),
            " ENTERING FMSALV-ICYC= %d\n", ICYC)
    end

    global CWDCUT = 0.0f0
    local cutvol  = 0.0f0
    salvtpa_ref[] = 0.0f0
    global TONRMS = 0.0f0
    global NSNAGSALV = NSNAG

    for i in 1:Int(NSNAG)
        SALVSPA[i, 1] = 0.0f0
        SALVSPA[i, 2] = 0.0f0
        HTIHSALV[i]   = HTIH[i]
        HTISSALV[i]   = HTIS[i]
        SPSSALV[i]    = SPS[i]
        DBHSSALV[i]   = DBHS[i]
        HARDSALV[i]   = HARD[i]
        HTDEADSALV[i] = HTDEAD[i]
    end

    local myact = Int32[2501, 2520]
    local key = Int(OPFIND(Int32(2), myact))
    if key <= 0; return nothing; end

    # Compute total snag volume before any salvage (for CWDCUT proportion)
    local totvol  = 0.0f0
    local lmerch  = LVWEST
    local vol_ref = Ref(Float32(0))

    for i in 1:Int(NSNAG)
        if (DENIS[i] + DENIH[i]) > 0.0f0
            if DENIS[i] > 0.0f0
                vol_ref[] = 0.0f0
                FMSVOL(i, HTIS[i], vol_ref, false, Int32(0))
                totvol += DENIS[i] * vol_ref[]
            end
            if DENIH[i] > 0.0f0
                vol_ref[] = 0.0f0
                FMSVOL(i, HTIH[i], vol_ref, false, Int32(0))
                totvol += DENIH[i] * vol_ref[]
            end
        end
    end

    for jdo in 1:key
        local jyr_ref   = Ref(Int32(0))
        local iactk_ref = Ref(Int32(0))
        local nprm_ref  = Ref(Int32(0))
        local prms      = zeros(Float32, 7)
        OPGET(Int32(jdo), Int32(6), jyr_ref, iactk_ref, nprm_ref, prms)

        # SALVSP keyword: set species selection
        if Int(iactk_ref[]) == 2501
            global ISALVS = Int32(prms[1])
            global ISALVC = Int32(prms[2])
            OPDONE(Int32(jdo), Int32(iyr))
            continue
        end

        # SALVAGE keyword: process salvage parameters
        local mindbh = max(0.0f0, prms[1])
        local maxdbh = min(999.0f0, prms[2])
        local maxage = max(0.0f0, prms[3])
        if prms[4] > 2.0f0 || prms[4] < 0.0f0; prms[4] = 0.0f0; end
        local oksoft = Int(prms[4])
        local prop   = min(1.0f0, max(0.0f0, prms[5]))
        local proplv = min(1.0f0, max(0.0f0, prms[6]))

        local thisrm = 0.0f0
        for i in 1:Int(NSNAG)
            # Species inclusion check (ISALVS: 0=all; >0=exact match; <0=group)
            local lincl = false
            if Int(ISALVS) == 0 || Int(ISALVS) == Int(SPS[i])
                lincl = true
            elseif Int(ISALVS) < 0
                local igrp = -Int(ISALVS)
                local iulim = Int(ISPGRP[igrp, 1]) + 1
                for ig in 2:iulim
                    if Int(SPS[i]) == Int(ISPGRP[igrp, ig])
                        lincl = true; break
                    end
                end
            end

            if (DENIS[i] + DENIH[i]) <= 0.0f0; continue; end
            if Int(ISALVC) == 0 && !lincl; continue; end
            if Int(ISALVC) == 1 &&  lincl; continue; end
            if DENIH[i] <= 0.0f0 && oksoft == 1; continue; end
            if DENIS[i] <= 0.0f0 && oksoft == 2; continue; end
            if (iyr - Int(YRDEAD[i])) > Int(maxage) ||
               DBHS[i] >= maxdbh || DBHS[i] < mindbh
                continue
            end

            # Compute snag volumes
            local isoftv  = 0.0f0
            local isoftv2 = 0.0f0
            local isoftv_ref  = Ref(Float32(0))
            local isoftv2_ref = Ref(Float32(0))
            if DENIS[i] > 0.0f0
                FMSVOL(i, HTIS[i], isoftv_ref, false, Int32(0))
                isoftv = isoftv_ref[]
                FMSVL2(Int(SPS[i]), DBHS[i], HTDEAD[i], HTIS[i], isoftv2_ref,
                        Int32(0), 'D', lmerch, false, Int32(JOSTND))
                isoftv2 = isoftv2_ref[]
            end
            local ihardv  = 0.0f0
            local ihardv2 = 0.0f0
            local ihardv_ref  = Ref(Float32(0))
            local ihardv2_ref = Ref(Float32(0))
            if DENIH[i] > 0.0f0
                FMSVOL(i, HTIH[i], ihardv_ref, false, Int32(0))
                ihardv = ihardv_ref[]
                FMSVL2(Int(SPS[i]), DBHS[i], HTDEAD[i], HTIH[i], ihardv2_ref,
                        Int32(0), 'D', lmerch, false, Int32(JOSTND))
                ihardv2 = ihardv2_ref[]
            end

            # Determine what to cut based on hard/soft eligibility
            local cutdih = 0.0f0
            if DENIH[i] > 0.0f0 &&
               ((HARD[i] && oksoft != 2) || (!HARD[i] && oksoft != 1))
                cutdih = prop * DENIH[i]
            end
            local cutdis = 0.0f0
            if DENIS[i] > 0.0f0 && oksoft != 1
                cutdis = prop * DENIS[i]
            end

            # Remove snags
            DENIS[i] -= cutdis
            DENIH[i] -= cutdih
            SALVSPA[i, 1] += cutdih * (1.0f0 - proplv)
            SALVSPA[i, 2] += cutdis * (1.0f0 - proplv)
            if DENIS[i] < 0.0f0; DENIS[i] = 0.0f0; end
            if DENIH[i] < 0.0f0; DENIH[i] = 0.0f0; end

            cutvol        += (cutdis * isoftv + cutdih * ihardv)
            salvtpa_ref[] += cutdis + cutdih
            thisrm        += (cutdis * isoftv + cutdih * ihardv) * (1.0f0 - proplv)

            # Leave-behind proportion → CWD
            CWD1(i, cutdih * proplv, cutdis * proplv)

            # Removed tons
            global TONRMS += (cutdis * isoftv + cutdih * ihardv) *
                              V2T[Int(SPS[i])] * (1.0f0 - proplv)

            # Carbon fate pools (sawlog/pulp × SW/HW)
            local xc = (cutdis * isoftv2 + cutdih * ihardv2) *
                       V2T[Int(SPS[i])] * (1.0f0 - proplv)
            local kc = BIOGRP[Int(SPS[i])] > 5 ? 2 : 1
            local jc = DBHS[i] > CDBRK[kc] ? 2 : 1
            FATE[jc, kc, Int(ICYC)] += xc
        end

        # Record removed volume in activity schedule
        prms[7] = thisrm
        OPCHPR(Int32(jdo), Int32(7), prms)
        OPDONE(Int32(jdo), Int32(iyr))

        SVSALV(Int32(iyr), mindbh, maxdbh, maxage, Int32(oksoft), prop, proplv)
    end

    # CWDCUT = proportion of pre-salvage snag volume that was removed
    if totvol > 0.0f0
        global CWDCUT += cutvol / totvol
    end

    # Redistribute crown material from CWD2B into current CWD pools
    for kyr in 1:Int(TFMAX)
        local pdown = CWDCUT
        for dkcl in 1:4
            local down = pdown * CWD2B[dkcl, 1, kyr]   # size 0 → index 1 (foliage)
            CWD[1, 10, 2, dkcl] += down / 2000.0f0
            CWDNEW[1, 10]        += down / 2000.0f0
            CWD2B[dkcl, 1, kyr] -= down
            for sz in 1:5
                down = pdown * CWD2B[dkcl, sz+1, kyr]
                CWD[1, sz, 2, dkcl] += down / 2000.0f0
                CWDNEW[1, sz]        += down / 2000.0f0
                CWD2B[dkcl, sz+1, kyr] -= down
            end
        end
    end
    return nothing
end
