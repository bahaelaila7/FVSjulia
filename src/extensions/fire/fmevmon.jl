# fmevmon.f — Fire model event monitor functions
# Translated ENTRY points → separate Julia functions
# Called from: EVLDX (event monitor evaluator)

# FMEVFLM: potential flame length by severity (II=1..4)
function FMEVFLM(rval_ref::Ref{Float32}, ii::Integer, irc_ref::Ref{Int32})
    if IFMYR1 == -1
        irc_ref[] = Int32(1)
    else
        irc_ref[] = Int32(0)
        if     ii == 1; rval_ref[] = PFLAM[1]
        elseif ii == 2; rval_ref[] = PFLAM[3]
        elseif ii == 3; rval_ref[] = PFLAM[2]
        elseif ii == 4; rval_ref[] = PFLAM[4]
        end
    end
    return nothing
end

# FMEVMRT: potential fire mortality by severity (II=1..4)
function FMEVMRT(rval_ref::Ref{Float32}, ii::Integer, irc_ref::Ref{Int32})
    if IFMYR1 == -1
        irc_ref[] = Int32(1)
    else
        irc_ref[] = Int32(0)
        if     ii == 1; rval_ref[] = POTKIL[1] * 100.0f0
        elseif ii == 2; rval_ref[] = POTKIL[3] * 100.0f0
        elseif ii == 3; rval_ref[] = POTVOL[1]
        elseif ii == 4; rval_ref[] = POTVOL[2]
        end
    end
    return nothing
end

# FMEVFMD: fuel model number or weight (III=1→model, III=2→weight; II=1..4)
function FMEVFMD(rval_ref::Ref{Float32}, ii::Integer, iii::Integer, irc_ref::Ref{Int32})
    if IFMYR1 == -1
        irc_ref[] = Int32(1)
    else
        irc_ref[] = Int32(0)
        if iii == 1
            rval_ref[] = 0.0f0
            if FWT[ii] > 0.0f0; rval_ref[] = Float32(FMOD[ii]); end
        elseif iii == 2
            rval_ref[] = FWT[ii]
        end
    end
    return nothing
end

# FMEVCWD: total CWD load summed over all dimensions for class range [ilo, ihi]
function FMEVCWD(rval_ref::Ref{Float32}, ilo::Integer, ihi::Integer, irc_ref::Ref{Int32})
    if IFMYR1 == -1
        irc_ref[] = Int32(1)
    else
        irc_ref[] = Int32(0)
        local s::Float32 = 0.0f0
        for i in 1:2; for j in Int(ilo):Int(ihi); for k in 1:2; for m in 1:4
            s += CWD[i, j, k, m]
        end; end; end; end
        rval_ref[] = s
    end
    return nothing
end

# FMEVSNG: snag TPA/BA/volume filtered by species, DBH range, height range, hard/soft
function FMEVSNG(rval_ref::Ref{Float32}, ix::Integer, jx::Integer, kx::Integer,
                  xldbh::Real, xhdbh::Real, xlht::Real, xhht::Real, irc_ref::Ref{Int32})
    if IFMYR1 == -1
        irc_ref[] = Int32(1)
        return nothing
    end
    irc_ref[] = Int32(0)
    local xh::Float32 = 0.0f0; local xs::Float32 = 0.0f0
    rval_ref[] = 0.0f0
    if NSNAG < 1; return nothing; end

    for i in 1:Int(NSNAG)
        local isps::Int32 = SPS[i]
        local d::Float32  = DBHS[i]
        local lincl::Bool = _fmev_species_match(isps, Int(jx))
        if !lincl || !(d >= Float32(xldbh) && d < Float32(xhdbh)); continue; end

        # Initially-hard snags
        local hs_h::Float32 = HTIH[i]
        local tpa_h::Float32 = DENIH[i]
        if tpa_h > 0.0f0 && hs_h >= Float32(xlht) && hs_h < Float32(xhht)
            local x::Float32 = _fmev_snag_val(i, ix, d, hs_h)
            if HARD[i]; xh += x; else; xs += x; end
        end

        # Initially-soft snags
        local hs_s::Float32 = HTIS[i]
        local tpa_s::Float32 = DENIS[i]
        if tpa_s > 0.0f0 && hs_s >= Float32(xlht) && hs_s < Float32(xhht)
            local x2::Float32 = _fmev_snag_val(i, ix, d, hs_s)
            xs += x2
        end
    end

    if     kx == 1; rval_ref[] = xh
    elseif kx == 2; rval_ref[] = xs
    else;           rval_ref[] = xh + xs
    end
    return nothing
end

function _fmev_species_match(isps::Integer, jx::Integer)::Bool
    if jx == 0 || jx == Int(isps); return true; end
    if jx < 0
        local igrp::Int = -jx
        local iulim::Int = Int(ISPGRP[igrp, 1]) + 1
        for ig in 2:iulim
            if Int(isps) == Int(ISPGRP[igrp, ig]); return true; end
        end
    end
    return false
end

function _fmev_snag_val(i::Integer, ix::Integer, d::Float32, hs::Float32)::Float32
    local tpa::Float32 = (ix == 1 || ix == 2) ? 0.0f0 : 0.0f0
    # Get TPA from array based on ix context (just use density estimate)
    tpa = (DENIH[i] > 0.0f0) ? DENIH[i] : DENIS[i]
    if     ix == 1; return tpa
    elseif ix == 2; return tpa * d * d * 0.005454154f0
    else
        local x1_ref = Ref(Float32(0))
        FMSVOL(Int32(i), hs, x1_ref, false, Int32(0))
        return tpa * x1_ref[]
    end
end

# FMEVSAL: salvage volume filtered by species, DBH range
function FMEVSAL(rval_ref::Ref{Float32}, jx::Integer, xldbh::Real, xhdbh::Real, irc_ref::Ref{Int32})
    irc_ref[] = Int32(0)
    rval_ref[] = 0.0f0
    if NSNAGSALV < 1; return nothing; end

    for i in 1:Int(NSNAGSALV)
        local isps::Int32 = SPSSALV[i]
        local xd::Float32  = DBHSSALV[i]
        local htd::Float32 = HTDEADSALV[i]
        local lincl::Bool = _fmev_species_match(isps, Int(jx))
        if !lincl || !(xd >= Float32(xldbh) && xd < Float32(xhdbh)); continue; end

        local x1_ref = Ref(Float32(0))
        local hs_h::Float32 = HTIHSALV[i]
        local tpa_h::Float32 = SALVSPA[i, 1]
        local xh::Float32 = 0.0f0; local xs_f::Float32 = 0.0f0
        if tpa_h > 0.0f0
            FMSVL2(Int32(isps), xd, htd, hs_h, x1_ref, Int32(0), "D", false, false, Int32(JOSTND))
            xh = tpa_h * x1_ref[]
        end
        local hs_s::Float32 = HTISSALV[i]
        local tpa_s::Float32 = SALVSPA[i, 2]
        if tpa_s > 0.0f0
            FMSVL2(Int32(isps), xd, htd, hs_s, x1_ref, Int32(0), "D", false, false, Int32(JOSTND))
            xs_f = tpa_s * x1_ref[]
        end
        rval_ref[] += (xh + xs_f) * V2T[isps]
    end
    return nothing
end

# FMEVTYP: potential fire type (severe=1, moderate=2)
function FMEVTYP(rval_ref::Ref{Float32}, ii::Integer, irc_ref::Ref{Int32})
    if IFMYR1 == -1
        irc_ref[] = Int32(1)
    else
        irc_ref[] = Int32(0)
        rval_ref[] = POTTYP[ii]
    end
    return nothing
end

# FMTREM: record removed trees for fire event monitor accounting (called from CUTS)
function FMTREM(dsng1::AbstractVector{Float32}, ssng1::AbstractVector{Float32},
                 crrem::AbstractVector{Float32})
    if !LFMON; return nothing; end
    global ITRNL = ITRN
    for j in 1:Int(MAXTRE)
        PREMST[j] = 0.0f0; PREMCR[j] = 0.0f0
        DBHC[j] = 0.0f0; HTC[j] = 0.0f0; ISPCC[j] = Int32(0)
        for ij in 1:6; CROWNWC[j, ij] = 0.0f0; end
    end
    global LREMT  = true
    global ICYCRM = ICYC
    for i in 1:Int(ITRNL)
        PREMST[i] = max(0.0f0, WK3[i] - ssng1[i] - dsng1[i])
        PREMCR[i] = crrem[i]
        ISPCC[i]  = ISP[i]
        DBHC[i]   = DBH[i]
        HTC[i]    = HT[i]
        for j in 1:6; CROWNWC[i, j] = CROWNW[i, j]; end
        if PREMCR[i] < 1e-5f0; PREMCR[i] = 0.0f0; end
        if PREMST[i] < 1e-5f0; PREMST[i] = 0.0f0; end
    end
    return nothing
end

# FMEVTBM: tree biomass event monitor (standing/removed, live/dead, stem/crown/both)
function FMEVTBM(rval_ref::Ref{Float32}, istand::Integer, ityp::Integer, ipart::Integer,
                  jx::Integer, xldbh::Real, xhdbh::Real, xlht::Real, xhht::Real,
                  irc_ref::Ref{Int32})
    if IFMYR1 == -1; irc_ref[] = Int32(1); return nothing; end
    irc_ref[] = Int32(0)
    rval_ref[] = 0.0f0

    if ICYCRM != ICYC || !LREMT
        for i in 1:Int(MAXTRE); PREMST[i] = 0.0f0; PREMCR[i] = 0.0f0; end
    end

    local sngstm::Float32 = 0.0f0; local sngcrn::Float32 = 0.0f0
    local sngsrm::Float32 = 0.0f0
    local snbaih::Float32 = 0.0f0; local snbais::Float32 = 0.0f0
    local totba::Float32  = 0.0f0; local totsba::Float32 = 0.0f0
    local x1_ref = Ref(Float32(0))

    if NSNAG >= 1
        for i in 1:Int(NSNAG)
            local isps::Int32 = SPS[i]; local d::Float32 = DBHS[i]
            totba += 0.005454154f0 * d^2 * (DENIH[i] + DENIS[i])
            local lincl::Bool = _fmev_species_match(isps, Int(jx))
            if lincl && (DENIH[i] + DENIS[i]) > 0.0f0
                if d >= Float32(xldbh) && d < Float32(xhdbh)
                    if HTIH[i] >= Float32(xlht) && HTIH[i] < Float32(xhht) && DENIH[i] > 0.0f0
                        snbaih += 0.005454154f0 * d^2 * DENIH[i]
                        FMSVOL(Int32(i), HTIH[i], x1_ref, false, Int32(JOSTND))
                        sngstm += (x1_ref[] * DENIH[i]) * V2T[isps]
                    end
                    if HTIS[i] >= Float32(xlht) && HTIS[i] < Float32(xhht) && DENIS[i] > 0.0f0
                        snbais += 0.005454154f0 * d^2 * DENIS[i]
                        FMSVOL(Int32(i), HTIS[i], x1_ref, false, Int32(JOSTND))
                        sngstm += (x1_ref[] * DENIS[i]) * V2T[isps]
                    end
                end
            end
        end
    end
    totsba = snbaih + snbais

    # Snag crown (CWD2B + CWD2B2), proportioned by BA fraction
    for isz in 0:5; for idc in 1:4; for itm in 1:Int(TFMAX)
        sngcrn += P2T * (CWD2B[idc, isz+1, itm] + CWD2B2[idc, isz+1, itm])
    end; end; end
    if totba > 0.0f0; sngcrn *= totsba / totba; end

    # Salvage from FMSALV list
    if istand >= 0 && ityp != 0 && NSNAGSALV > 0
        for i in 1:Int(NSNAGSALV)
            local isps::Int32 = SPSSALV[i]; local xd::Float32 = DBHSSALV[i]
            local htd::Float32 = HTDEADSALV[i]
            local lincl::Bool = _fmev_species_match(isps, Int(jx))
            if lincl && xd >= Float32(xldbh) && xd < Float32(xhdbh)
                if HTIHSALV[i] >= Float32(xlht) && HTIHSALV[i] < Float32(xhht)
                    local xh::Float32 = 0.0f0; local xs_f::Float32 = 0.0f0
                    if SALVSPA[i,1] > 0.0f0
                        FMSVL2(Int32(isps), xd, htd, HTIHSALV[i], x1_ref, Int32(0), "D", false, false, Int32(JOSTND))
                        xh = SALVSPA[i,1] * x1_ref[]
                    end
                    if SALVSPA[i,2] > 0.0f0
                        FMSVL2(Int32(isps), xd, htd, HTISSALV[i], x1_ref, Int32(0), "D", false, false, Int32(JOSTND))
                        xs_f = SALVSPA[i,2] * x1_ref[]
                    end
                    sngsrm += (xh + xs_f) * V2T[isps]
                end
            end
        end
    end

    # Live removals
    local livsrm::Float32 = 0.0f0; local livcrm::Float32 = 0.0f0
    if ICYCRM == ICYC && istand >= 0 && ityp >= 0
        for i in 1:Int(ITRNL)
            local ispc::Int32 = ISPCC[i]; local d::Float32 = DBHC[i]; local h::Float32 = HTC[i]
            if !_fmev_species_match(ispc, Int(jx)); continue; end
            if d >= Float32(xldbh) && d < Float32(xhdbh) && h >= Float32(xlht) && h < Float32(xhht)
                local xneg::Float32 = -1.0f0; local vt_ref = Ref(Float32(0))
                FMSVL2(Int32(ispc), d, h, xneg, vt_ref, Int32(0), "L", false, false, Int32(JOSTND))
                livsrm += PREMST[i] * vt_ref[] * V2T[ispc]
                for j in 1:6; livcrm += CROWNWC[i, j] * P2T * PREMCR[i]; end
            end
        end
    end

    # Standing live
    local livslv::Float32 = 0.0f0; local livcrn::Float32 = 0.0f0; local totfol::Float32 = 0.0f0
    if istand != 0 && ityp >= 0
        for i in 1:Int(ITRN)
            local ispc::Int32 = ISP[i]; local d::Float32 = DBH[i]; local h::Float32 = HT[i]
            if !_fmev_species_match(ispc, Int(jx)); continue; end
            if d >= Float32(xldbh) && d < Float32(xhdbh) && h >= Float32(xlht) && h < Float32(xhht)
                local xneg2::Float32 = -1.0f0; local vt2_ref = Ref(Float32(0))
                FMSVL2(Int32(ispc), d, h, xneg2, vt2_ref, Int32(0), "L", false, false, Int32(JOSTND))
                livslv += FMPROB[i] * vt2_ref[] * V2T[ispc]
                for j in 1:6; livcrn += CROWNW[i, j] * P2T * FMPROB[i]; end
                totfol += CROWNW[i, 1] * P2T * FMPROB[i]   # xv[1] = foliage
            end
        end
    end

    # Compose result based on ISTAND/ITYP/IPART
    local rv::Float32 = 0.0f0
    if istand < 0    # standing only
        if   ityp < 0; rv = ipart < 0 ? sngstm : ipart == 0 ? sngcrn : sngstm + sngcrn
        elseif ityp == 0
            rv = ipart < 0 ? livslv : ipart == 0 ? livcrn : livslv + livcrn
            if ipart == 2; rv = totfol; end
        else; rv = ipart < 0 ? livslv + sngstm : ipart == 0 ? livcrn + sngcrn : livslv + livcrn + sngstm + sngcrn; end
    elseif istand == 0  # removed only
        if   ityp < 0; rv = ipart < 0 ? sngsrm : ipart == 0 ? 0.0f0 : sngsrm
        elseif ityp == 0; rv = ipart < 0 ? livsrm : ipart == 0 ? livcrm : livsrm + livcrm
        else; rv = ipart < 0 ? livsrm + sngsrm : ipart == 0 ? livcrm : livsrm + livcrm + sngsrm; end
    else   # both
        if   ityp < 0; rv = ipart < 0 ? sngstm + sngsrm : ipart == 0 ? sngcrn : sngstm + sngcrn + sngsrm
        elseif ityp == 0; rv = ipart < 0 ? livslv + livsrm : ipart == 0 ? livcrn + livcrm : livslv + livsrm + livcrn + livcrm
        else
            rv = ipart < 0 ? livslv + livsrm + sngstm + sngsrm :
                 ipart == 0 ? livcrn + sngcrn + livcrm :
                 livslv + livsrm + livcrn + livcrm + sngstm + sngsrm + sngcrn
        end
    end
    if (istand >= 0 || ityp != 0) && ipart == 2; rv = 0.0f0; end
    rval_ref[] = rv
    return nothing
end

# FMEVSRT: potential surface spread rate (II=moisture class index)
function FMEVSRT(rval_ref::Ref{Float32}, ii::Integer, irc_ref::Ref{Int32})
    if IFMYR1 == -1; irc_ref[] = Int32(1); else; irc_ref[] = Int32(0); rval_ref[] = POTFSR[ii]; end
    return nothing
end

# FMEVRIN: potential reaction intensity
function FMEVRIN(rval_ref::Ref{Float32}, ii::Integer, irc_ref::Ref{Int32})
    if IFMYR1 == -1; irc_ref[] = Int32(1); else; irc_ref[] = Int32(0); rval_ref[] = POTRINT[ii]; end
    return nothing
end

# FMEVCARB: carbon state variable (II=1..17)
function FMEVCARB(rval_ref::Ref{Float32}, ii::Integer, irc_ref::Ref{Int32})
    if IFMYR1 == -1
        irc_ref[] = Int32(1)
    else
        irc_ref[] = Int32(0)
        rval_ref[] = 0.0f0
        if ii >= 1 && ii <= 17; rval_ref[] = CARBVAL[ii]; end
    end
    return nothing
end

# FMDWD: down woody debris volume (IX=1) or cover (IX=2), by JX hard/soft and ILO..IHI size class
function FMDWD(rval_ref::Ref{Float32}, ix::Integer, jx::Integer, ilo::Integer, ihi::Integer, irc_ref::Ref{Int32})
    if IFMYR1 == -1; irc_ref[] = Int32(1); return nothing; end
    rval_ref[] = 0.0f0; irc_ref[] = Int32(0)
    local lo::Int = ilo > 1 ? Int(ilo) + 2 : Int(ilo)
    local hi::Int = ihi >= 1 ? Int(ihi) + 2 : Int(ihi)
    for i in lo:hi
        if ix == 1
            rval_ref[] += (jx == 0 ? CWDVOL[3,i,1,5] + CWDVOL[3,i,2,5] :
                           jx == 1 ? CWDVOL[3,i,2,5] : CWDVOL[3,i,1,5])
        else
            rval_ref[] += (jx == 0 ? CWDCOV[3,i,1,5] + CWDCOV[3,i,2,5] :
                           jx == 1 ? CWDCOV[3,i,2,5] : CWDCOV[3,i,1,5])
        end
    end
    return nothing
end

# FMEVMSN: max conifer (softwood) snag DBH
function FMEVMSN(rval_ref::Ref{Float32})
    rval_ref[] = 0.0f0
    for i in 1:Int(NSNAG)
        local ispc::Int32 = SPS[i]
        if LSW[ispc] && DBHS[i] > rval_ref[]; rval_ref[] = DBHS[i]; end
    end
    return nothing
end

# FMEVLSF: live surface fuel load (II=1=herbs, 2=shrubs, 3=total)
function FMEVLSF(rval_ref::Ref{Float32}, ii::Integer, irc_ref::Ref{Int32})
    if IFMYR1 == -1; irc_ref[] = Int32(1); return nothing; end
    irc_ref[] = Int32(0)
    if     ii == 1; rval_ref[] = FLIVE[1]
    elseif ii == 2; rval_ref[] = FLIVE[2]
    elseif ii == 3; rval_ref[] = FLIVE[1] + FLIVE[2]
    end
    return nothing
end
