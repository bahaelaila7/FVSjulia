# fmfint.f — BEHAVE fire spread rate and intensity calculator
# FMFINT: Byram intensity + flame length for one or more fuel models (weighted)
# Called from: FMBURN, FMPOFL, FMCFIR

function FMFINT(iyr::Integer, byram_ref::Ref{Float32}, flame_ref::Ref{Float32},
                ftyp::Integer, hpa_ref::Ref{Float32}, icall::Integer)
    debug = DBCHK("FMFINT", 6, ICYC)
    if debug
        @printf(io_units[JOSTND],
            " ENTERING FMFINT CYCLE = %2d FTYP=%2d FWIND=%7.3f\n MOIS=%10.3f%10.3f%10.3f%10.3f%10.3f%10.3f%10.3f\n",
            ICYC, ftyp, FWIND,
            MOIS[1,1], MOIS[1,2], MOIS[1,3], MOIS[1,4], MOIS[1,5],
            MOIS[2,1], MOIS[2,2])
    end

    local ttheta::Float32 = FMSLOP > 1.0f0 ? FMSLOP / 100.0f0 : FMSLOP

    local rhop::Float32   = 32.0f0
    local tmin::Float32   = 0.0555f0
    local silfre::Float32 = 0.01f0

    byram_ref[] = 0.0f0
    flame_ref[] = 0.0f0
    SSIGMA[ftyp] = 0.0f0
    SRHOBQ[ftyp] = 0.0f0
    SXIR[ftyp]   = 0.0f0
    SIRXI[ftyp]  = 0.0f0
    SPHIS[ftyp]  = 0.0f0
    SFRATE[ftyp] = 0.0f0
    SCBE[ftyp]   = 0.0f0

    local irtncd_ref = Ref(Int32(0))

    for inb in 1:Int(MXFMOD)
        local lhv::Float32 = FMOD[inb] == 106 ? 9000.0f0 :
                              (IFLOGIC == Int32(2) ? ULHV : 8000.0f0)

        if ftyp == 2 && icall == 1
            if inb >= 2; @goto label_810; end
            FMGFMV(Int32(iyr), Int32(10))
            fvsGetRtnCode(irtncd_ref)
            if irtncd_ref[] != 0; return; end
        else
            if FMOD[inb] == 0 || FWT[inb] <= 0.0f0; continue; end
            FMGFMV(Int32(iyr), Int32(FMOD[inb]))
            fvsGetRtncd = irtncd_ref
            fvsGetRtnCode(irtncd_ref)
            if irtncd_ref[] != 0; return; end
        end

        local large1::Int32 = ND
        local large2::Int32 = NL
        local ifines = Int32[1, NL > Int32(0) ? Int32(1) : Int32(0)]
        local noclas = Float32[Float32(ND), Float32(NL)]

        # Working arrays (indices 1..7)
        local isize = zeros(Int32, 2, 7)
        local g  = zeros(Float32, 2, 7)
        local gs = zeros(Float32, 2, 7)
        local a  = zeros(Float32, 2, 7)
        local f  = zeros(Float32, 2, 7)
        local wo = zeros(Float32, 2, 7)
        local qig = zeros(Float32, 2, 7)
        local bulk = zeros(Float32, 2, 7)
        local ai   = zeros(Float32, 2)
        local mcsa  = zeros(Float32, 2)
        local mdcsa = zeros(Float32, 2)
        local bse   = zeros(Float32, 2)
        local sigma1 = zeros(Float32, 2)
        local wo1   = zeros(Float32, 2)
        local ir    = zeros(Float32, 2)
        local barns = zeros(Float32, 2)
        local fx    = zeros(Float32, 2)

        for i in 1:2
            for j in 1:7
                bulk[i,j] = DEPTH > 0.0f0 ? Float32(FWG[i,j]) / DEPTH : 0.0f0
                isize[i,j] = Int32(j)
            end
        end

        local xir::Float32  = 0.0f0
        local rhobqig::Float32 = 0.0f0
        local xio::Float32  = 0.0f0
        local phis::Float32 = 0.0f0
        local r::Float32    = 0.0f0
        local c1::Float32   = 0.0f0
        local byramt::Float32 = 0.0f0
        local rate::Float32 = 0.0f0
        local gamma::Float32 = 0.0f0
        local sigma::Float32 = 0.0f0
        local at::Float32   = 0.0f0
        local lhv1::Float32 = 0.0f0
        FLAG[1] = Int32(0); FLAG[2] = Int32(0); FLAG[3] = Int32(0)
        local sum1::Float32 = 0.0f0
        local sum2::Float32 = 0.0f0
        local sum3::Float32 = 0.0f0
        local sum4::Float32 = 0.0f0

        # Sort fuel components by size (finest first), dead and live separately
        for i in 1:2
            local jmax::Int32 = Int32(round(noclas[i]))
            if jmax > 1
                for j in 1:(jmax-1)
                    local km::Int32 = jmax - Int32(j)
                    for k in 1:Int(km)
                        local ida::Int32 = isize[i, k]
                        local idb::Int32 = isize[i, k+1]
                        local siza::Float32 = Float32(MPS[i, ida])
                        local sizb::Float32 = Float32(MPS[i, idb])
                        if siza < sizb
                            isize[i, k+1] = ida
                            isize[i, k]   = idb
                        end
                    end
                end
            end
        end

        # Fix ordering if live woody empty but herbs present, or dead herbs and empty dead classes
        let ida = isize[2,1]; idb = isize[2,2]
            if FWG[2, ida] <= 0.0f0; isize[2,2] = ida; isize[2,1] = idb; end
        end
        let ida = isize[1,3]; idb = isize[1,4]
            if FWG[1, ida] <= 0.0f0; isize[1,4] = ida; isize[1,3] = idb; end
        end
        let ida = isize[1,2]; idb = isize[1,3]
            if FWG[1, ida] <= 0.0f0; isize[1,3] = ida; isize[1,2] = idb; end
        end

        # Delete large logs from fire spread (MPS >= 16)
        for i in 1:2
            local kmax::Int32 = Int32(round(noclas[i]))
            if kmax < 1; continue; end
            for k in 1:Int(kmax)
                local j::Int32 = isize[i, k]
                if Float32(MPS[i, j]) >= 16.0f0
                    noclas[i] = Float32(k - 1)
                    break
                end
            end
        end

        local n1::Int32 = Int32(round(noclas[1]))
        local n2::Int32 = Int32(round(noclas[2]))
        noclas[1] = Float32(min(large1, n1))
        noclas[2] = Float32(min(large2, n2))

        # Compute weighting factors
        for i in 1:2
            local kmin::Int32 = ifines[i]
            local kmax::Int32 = Int32(round(noclas[i]))
            if kmax != 0 && kmin <= kmax
                for k in Int(kmin):Int(kmax)
                    local j::Int32 = isize[i, k]
                    gs[i,j] = Float32(MPS[i,j]) / rhop
                    a[i,j]  = FWG[i,j] * gs[i,j]
                    gs[i,j] = exp(-138.0f0 / (Float32(MPS[i,j]) + 1f-9))
                    ai[i]  += a[i,j]
                    wo[i,j] = FWG[i,j] * (1.0f0 - tmin)
                end
                for k in Int(kmin):Int(kmax)
                    local j::Int32 = isize[i, k]
                    if ai[i] != 0.0f0; f[i,j] = a[i,j] / ai[i]; end
                end
            end
        end

        at   = ai[1] + ai[2]
        fx[1] = ai[1] / (at + 1f-9)
        fx[2] = 1.0f0 - fx[1]

        # Weighted dead fine moisture and live extinction moisture
        local fined::Float32 = 0.0f0
        local finel::Float32 = 0.0f0
        local wdfmn::Float32 = 0.0f0
        local findm::Float32 = 0.0f0

        for i in 1:2
            local n::Int32 = ifines[i]
            local jm::Int32 = Int32(round(noclas[i]))
            if jm > 0 && n <= jm
                if i == 1
                    for jk in Int(n):Int(jm)
                        local jj::Int32 = isize[i, jk]
                        local sa::Float32 = Float32(MPS[i, jj])
                        local ep::Float32 = sa != 0.0f0 ? exp(-138.0f0 / sa) : 0.0f0
                        local wtfac::Float32 = FWG[i, jj] * ep
                        local m_idx = jj == Int32(4) ? 1 : Int(jj)
                        local wmfac::Float32 = wtfac * MOIS[i, m_idx]
                        fined += wtfac
                        wdfmn += wmfac
                    end
                    if fined != 0.0f0; findm = wdfmn / fined; end
                else
                    for jk in Int(n):Int(jm)
                        local jj::Int32 = isize[i, jk]
                        local sa::Float32 = Float32(MPS[i, jj])
                        local ep::Float32 = sa != 0.0f0 ? exp(-500.0f0 / sa) : 0.0f0
                        finel += FWG[i, jj] * ep
                    end
                end
            end
        end

        if finel != 0.0f0
            local factor::Float32 = fined / finel
            local xmoisl::Float32 = 2.9f0 * factor * (1.0f0 - findm / MEXT[1]) - 0.226f0
            if xmoisl < MEXT[1]; xmoisl = MEXT[1]; end
            MEXT[2] = xmoisl
        else
            MEXT[2] = 100.0f0
        end

        # Intermediate computations per dead/live category
        for i in 1:2
            local aa1::Float32 = 0.0f0; local aa2::Float32 = 0.0f0
            local aa3::Float32 = 0.0f0; local aa4::Float32 = 0.0f0
            local aa5::Float32 = 0.0f0; lhv1 = 0.0f0
            local jm::Int32 = Int32(round(noclas[i]))
            local n::Int32  = ifines[i]
            if jm != 0 && n <= jm
                for k in Int(n):Int(jm)
                    local j::Int32 = isize[i, k]
                    local ax::Float32 = f[i, j]
                    local sigm::Float32 = Float32(MPS[i, j])
                    if sigm < 48.0f0;    aa5 += a[i,j]
                    elseif sigm < 96.0f0;  aa4 += a[i,j]
                    elseif sigm < 192.0f0; aa3 += a[i,j]
                    elseif sigm < 1200.0f0; aa2 += a[i,j]
                    else;                  aa1 += a[i,j]
                    end
                    local mois_j = (i == 1 && j == Int32(4)) ? MOIS[i,1] : MOIS[i, Int(j)]
                    qig[i,j]  = 250.0f0 + 1116.0f0 * mois_j
                    mcsa[i]  += ax * mois_j
                    bse[i]   += ax * silfre
                    sigma1[i] += ax * sigm
                    lhv1     += ax * lhv
                    sum4 += bulk[i,j] * FWG[i,j]
                    sum1 += FWG[i,j]
                    sum2 += FWG[i,j] / rhop
                    sum3 += fx[i] * f[i,j] * qig[i,j] * gs[i,j]
                end
                for k in Int(n):Int(jm)
                    local j::Int32 = isize[i, k]
                    local sigm::Float32 = Float32(MPS[i, j])
                    if ai[i] == 0.0f0; ai[i] += 1f-9; end
                    if sigm < 48.0f0;    g[i,j] = aa5 / ai[i]
                    elseif sigm < 96.0f0;  g[i,j] = aa4 / ai[i]
                    elseif sigm < 192.0f0; g[i,j] = aa3 / ai[i]
                    elseif sigm < 1200.0f0; g[i,j] = aa2 / ai[i]
                    else;                  g[i,j] = aa1 / ai[i]
                    end
                    wo1[i] += g[i,j] * wo[i,j]
                end
                local beta = mcsa[i] / (MEXT[i] + 1f-9)
                mdcsa[i] = 1.0f0 - beta * (2.59f0 - beta * (5.11f0 - beta * 3.52f0))
                if MEXT[i] < mcsa[i]; mdcsa[i] = 0.0f0; end
                if bse[i] != 0.0f0; barns[i] = 0.174f0 / (bse[i]^0.19f0); end
                if barns[i] > 1.0f0; barns[i] = 1.0f0; end
                sigma += fx[i] * sigma1[i]
                ir[i]  = wo1[i] * lhv1 * mdcsa[i] * barns[i]
            end
        end

        if mdcsa[1] <= 0.0f0; FLAG[1] = Int32(1); end

        if mdcsa[1] > 0.0f0
            local rhop1::Float32 = sum1 / DEPTH
            local beta1::Float32 = sum2 / DEPTH
            if sigma == 0.0f0; sigma = 1f-9; end
            local best::Float32 = 3.348f0 / (sigma^0.8189f0)
            local rat::Float32  = beta1 / (best + 1f-9)
            local a1::Float32   = 133.0f0 / (sigma^0.7913f0)
            local v::Float32    = sigma^1.5f0
            gamma = (v * (rat^a1) * exp(a1 * (1.0f0 - rat))) / (495.0f0 + 0.0594f0 * v)
            ir[1] = gamma * ir[1]
            ir[2] = gamma * ir[2]
            xir   = ir[1] + ir[2]
            rhobqig = rhop1 * sum3
            local b_val::Float32 = (0.792f0 + 0.681f0 * sqrt(sigma)) * (0.1f0 + beta1)
            xio  = (xir * exp(b_val)) / (192.0f0 + 0.2595f0 * sigma)
            if beta1 != 0.0f0
                phis = 5.275f0 * ttheta * ttheta / (beta1^0.3f0)
            end
            local xm1::Float32 = 0.02526f0 * (sigma^0.54f0)
            local xn1::Float32 = 0.715f0 * exp(-0.000359f0 * sigma)
            c1 = 7.47f0 * exp(-0.133f0 * (sigma^0.55f0))
            if rat != 0.0f0; c1 = c1 / (rat^xn1); end
            local wmax::Float32 = 0.9f0 * xir
            local w::Float32    = FWIND * 88.0f0
            local phiw::Float32 = c1 * (w^xm1)
            r = xio * (1.0f0 + phis + phiw) / (rhobqig + 1f-9)
            byramt = xir * r * 384.0f0 / sigma
            if w != 0.0f0 && sigma < 175.0f0; FLAG[3] = Int32(1); end
            if w > wmax; FLAG[2] = Int32(1); end
        end

        if ftyp != 2 || icall == 2
            flame_ref[] += (0.45f0 * (byramt / 60.0f0)^0.46f0) * FWT[inb]
            byram_ref[] += byramt * FWT[inb]
            SSIGMA[ftyp] += sigma   * FWT[inb]
            SRHOBQ[ftyp] += rhobqig * FWT[inb]
            SXIR[ftyp]   += xir     * FWT[inb]
            SIRXI[ftyp]  += xio     * FWT[inb]
            SPHIS[ftyp]  += phis    * FWT[inb]
            SFRATE[ftyp] += r       * FWT[inb]
            SCBE[ftyp]   += c1      * FWT[inb]
        else
            flame_ref[] = 0.45f0 * (byramt / 60.0f0)^0.46f0
            byram_ref[] = byramt
            SSIGMA[ftyp] = sigma
            SRHOBQ[ftyp] = rhobqig
            SXIR[ftyp]   = xir
            SIRXI[ftyp]  = xio
            SPHIS[ftyp]  = phis
            SFRATE[ftyp] = r
            SCBE[ftyp]   = c1
            @goto label_810
        end
    end  # inb loop

    @label label_810
    # Final flame length from Byram (NLC 21 Aug 2003)
    flame_ref[] = 0.45f0 * (byram_ref[] / 60.0f0)^0.46f0

    if SSIGMA[ftyp] != 0.0f0
        hpa_ref[] = SXIR[ftyp] * 384.0f0 / SSIGMA[ftyp]
    else
        hpa_ref[] = 0.0f0
    end

    if debug
        @printf(io_units[JOSTND], " EXIT FMFINT CYCLE = %2d FLAME,BYRAM,HPA=%14.7e%14.7e%14.7e\n",
                ICYC, flame_ref[], byram_ref[], hpa_ref[])
    end
    return nothing
end
