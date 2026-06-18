# base/estab_helpers.jl — small helpers for ESTAB (establishment tree creation)
# Translated from: essubh.f, esprep.f, estime.f, esetpr.f, esgent.f
# (ESCOMN renames: Fortran TIME→TIME_ES, BAA→BAA_ES.)

# ESSUBH — assign height to a planted/subsequent tree from the site curve.
# On entry TRAGE = tree age from keyword; on exit TRAGE = years planting→cycle end.
function ESSUBH(i::Integer, hht_ref::Ref{Float32}, emsqr::Real, dilate::Real,
                delay_ref::Ref{Float32}, elev::Real, ihtser::Integer,
                gentim::Real, trage_ref::Ref{Float32})
    hht_ref[] = 0.0f0
    n = Int(floor(delay_ref[] + 0.5f0))
    if n < -3; n = -3; end
    delay = Float32(n)
    itime = Int(floor(TIME_ES + 0.5f0))
    if n > itime; delay = TIME_ES; end
    age = TIME_ES - delay - Float32(gentim) + trage_ref[]
    if age < 1.0f0; age = 1.0f0; end
    trage_ref[] = TIME_ES - delay
    delay_ref[]  = delay
    aget_r = Ref(age); h_r = Ref(0.0f0); htmax_r = Ref(0.0f0); htg1_r = Ref(0.0f0)
    HTCALC(Int32(1), Int32(i), aget_r, h_r, htmax_r, htg1_r, JOSTND, false)
    hht_ref[] = h_r[]
    return nothing
end

# ESPREP — default site-prep probabilities.
function ESPREP(iser::Integer, pnone_ref::Ref{Float32},
                pmech_ref::Ref{Float32}, pburn_ref::Ref{Float32})
    pnone_ref[] = 0.75f0
    pmech_ref[] = 0.20f0
    pburn_ref[] = 0.05f0
    return nothing
end

const _ESTIME_SQRVEC = Float32[1.0, .41421, .31784, .26795, .23607, .21342,
    .19626, .18268, .17157, .16228, .15435, .14748, .14145, .13611, .13133,
    .12702, .12311, .11954, .11626, .11324]

# ESTIME — define TIME/WSBW variables for the regen model (budworm history off for snt01).
function ESTIME(ievtyr::Integer, kdt::Integer)
    global BWB4 = 0.0f0; global BWAF = 0.0f0; global SQBWAF = 0.0f0
    if NBWHST > Int32(0)
        for iyr in (Int(ievtyr)-5):(Int(ievtyr)-1)
            for ii in 1:Int(NBWHST)
                if iyr >= IBWHST[1, ii] && iyr <= IBWHST[2, ii]
                    global BWB4 = BWB4 + 1.0f0; break
                end
            end
        end
        for iyr in Int(ievtyr):Int(kdt)
            for ii in 1:Int(NBWHST)
                if iyr >= IBWHST[1, ii] && iyr <= IBWHST[2, ii]
                    global BWAF   = BWAF + 1.0f0
                    global SQBWAF = SQBWAF + _ESTIME_SQRVEC[iyr - Int(ievtyr) + 1]
                    break
                end
            end
        end
    end
    global SQREGT = sqrt(TIME_ES) - SQBWAF
    global REGT   = TIME_ES - BWAF
    return nothing
end

# ESETPR — set site preparation (BURNPREP=491 / MECHPREP=493). For snt01 neither
# keyword exists, so this zeros everything and returns.
function ESETPR(meth_ref::Ref{Int32}, zmech_ref::Ref{Float32}, zburn_ref::Ref{Float32},
                pnone_ref::Ref{Float32}, pmech_ref::Ref{Float32}, pburn_ref::Ref{Float32},
                ialn::AbstractVector{Int32}, idsdat::Integer, kdt::Integer, ip_ref::Ref{Int32})
    meth_ref[] = Int32(0)
    zmech_ref[] = 0.0f0; zburn_ref[] = 0.0f0
    pnone_ref[] = 0.0f0; pmech_ref[] = 0.0f0; pburn_ref[] = 0.0f0
    for i in 1:3; ialn[i] = Int32(0); end
    prms = zeros(Float32, 3)

    # --- BURNPREP (491) ---
    i = 0; last_idt = Int32(0)
    while true
        i += 1
        idt_r = Ref(Int32(0)); nprms_r = Ref(Int32(0)); kode_r = Ref(Int32(0))
        OPGET2(Int32(491), idt_r, idsdat, kdt, Int32(i), Int32(3), nprms_r, prms, kode_r)
        if kode_r[] > Int32(0); break; end
        last_idt = idt_r[]
        ip_ref[] = Int32(0); zburn_ref[] = Float32(idt_r[])
        if nprms_r[] > Int32(0)
            pburn_ref[] = prms[1] / 100.0f0; ialn[3] = Int32(1); continue
        end
        meth_ref[] = Int32(3)
        OPDON2(Int32(491), last_idt, idsdat, kdt, Int32(i), Ref(Int32(0)))
        @goto burndone
    end
    i -= 1
    if i != 0
        OPDON2(Int32(491), last_idt, idsdat, kdt, Int32(i), Ref(Int32(0)))
        while true
            i -= 1
            if i <= 0; break; end
            OPDON2(Int32(491), Int32(-1), idsdat, kdt, Int32(i), Ref(Int32(0)))
        end
    end
    @label burndone

    # --- MECHPREP (493) ---
    i = 0; last_idt = Int32(0)
    while true
        i += 1
        idt_r = Ref(Int32(0)); nprms_r = Ref(Int32(0)); kode_r = Ref(Int32(0))
        OPGET2(Int32(493), idt_r, idsdat, kdt, Int32(i), Int32(3), nprms_r, prms, kode_r)
        if kode_r[] > Int32(0); break; end
        last_idt = idt_r[]
        ip_ref[] = Int32(0); zmech_ref[] = Float32(idt_r[])
        if nprms_r[] > Int32(0)
            pmech_ref[] = prms[1] / 100.0f0; ialn[2] = Int32(1); continue
        end
        meth_ref[] = Int32(2)
        OPDON2(Int32(493), last_idt, idsdat, kdt, Int32(i), Ref(Int32(0)))
        break
    end
    i -= 1
    if i != 0
        OPDON2(Int32(493), last_idt, idsdat, kdt, Int32(i), Ref(Int32(0)))
        while true
            i -= 1
            if i <= 0; break; end
            OPDON2(Int32(493), Int32(-1), idsdat, kdt, Int32(i), Ref(Int32(0)))
        end
    end
    return nothing
end

# ESGENT — use REGENT to add height increment to newly-regenerated trees.
function ESGENT(itrnin::Integer)
    global IREC1 = ITRN
    SPESRT()
    REGENT(true, Int32(itrnin))
    for i in Int(itrnin):Int(ITRN)
        n = Int(ISP[i])
        htemp = HT[i] + HTG[i]
        HTG[i] = HTG[i] * WK4[i]
        HT[i]  = HT[i] + HTG[i]
        if WK4[i] < 1.0f0
            if HT[i] < 4.5f0
                DBH[i] = 0.1f0 + 0.001f0 * HT[i]; DG[i] = 0.0f0
            else
                DBH[i] = DBH[i] * (HT[i] / htemp); DG[i] = DBH[i] * (HT[i] / htemp)
            end
        end
        if HT[i] > HHTMAX[n]; HT[i] = HHTMAX[n]; end
        if IMC[i] != Int32(1); continue; end
        SUMPX[n] += PROB[i] * HT[i]
        SUMPI[n] += PROB[i]
    end
    return nothing
end
