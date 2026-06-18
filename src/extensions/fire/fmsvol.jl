# fmsvol.f — Snag volume calculation
# FMSVOL: volume up to height XHT for snag record II
# FMSVL2: same calculation for cut trees (ENTRY point → separate function)
# Dispatch: METHC(JS)==6/10 → NATCRS; ==8/5 → OCFVOL; else → CFVOL
# SN/CS/LS/NE: report MCF; if LMERCH: report SCF

function _fmsvol_shared(js::Integer, d::Float32, h::Float32, xht_in::Float32,
                        lmerch::Bool, cwn::Integer, livedead::String,
                        debug::Bool, iout::Integer, vol2ht_ref::Ref{Float32})
    local xht::Float32 = xht_in
    local ltkil::Bool = xht > -1.0f0
    if !ltkil; xht = h; end

    local bark::Float32 = BRATIO(js, d, h)
    local d2h::Float32  = d * d * h
    local iht::Int32    = Int32(floor(xht * 100.0f0))

    local tcf_ref  = Ref(Float32(0))
    local mcf_ref  = Ref(Float32(0))
    local scf_ref  = Ref(Float32(0))
    local bbfv_ref = Ref(Float32(0))
    local vmax_ref = Ref(Float32(0))
    local bfmax_ref = Ref(Float32(0))
    local lcone_ref = Ref(false)
    local ctkflg_ref = Ref(ltkil)
    local btkflg_ref = Ref(false)
    local biodry = zeros(Float32, 15)

    local ispc::Int32 = Int32(js)
    local it::Int32   = Int32(0)
    local cl::Float32 = 0.0f0
    local dcy::Int32  = Int32(0)
    local wstm::Int32 = Int32(0)

    if Int(METHC[ispc]) == 6 || Int(METHC[ispc]) == 10
        NATCRS(tcf_ref, mcf_ref, scf_ref, bbfv_ref, ispc, d, h, ltkil,
               Int32(cwn), bark, iht, vmax_ref, bfmax_ref,
               cl, dcy, wstm, biodry,
               livedead, ctkflg_ref, btkflg_ref, Int32(-1))
    elseif Int(METHC[ispc]) == 8 || Int(METHC[ispc]) == 5
        OCFVOL(tcf_ref, mcf_ref, ispc, d, h, ltkil, bark, iht,
               vmax_ref, lcone_ref, ctkflg_ref, it)
    else
        CFVOL(ispc, d, h, d2h, tcf_ref, mcf_ref, vmax_ref, ltkil,
              lcone_ref, bark, iht, ctkflg_ref)
    end

    if ctkflg_ref[] && ltkil
        CFTOPK(ispc, d, h, tcf_ref, mcf_ref, scf_ref,
               vmax_ref[], lcone_ref[], bark, iht)
    end

    # Minimum volume: cone with 1-inch base DBH
    local xmin::Float32 = 0.005454154f0 * h

    local vol2ht::Float32
    if VARACD == "CS" || VARACD == "LS" || VARACD == "NE" || VARACD == "SN"
        vol2ht = max(xmin, mcf_ref[])
        if lmerch; vol2ht = scf_ref[]; end
    else
        vol2ht = max(xmin, tcf_ref[])
        if lmerch; vol2ht = mcf_ref[]; end
    end

    if debug
        @printf(get(io_units, Int32(iout), stdout),
            " FMSVOL ISPC=%3d D=%7.3f H=%7.3f LCONE=%2s VN=%7.3f VOL2HT=%10.3f\n",
            ispc, d, h, string(lcone_ref[]), tcf_ref[], vol2ht)
    end

    vol2ht_ref[] = vol2ht
    return nothing
end

function FMSVOL(ii::Integer, xht::Real, vol2ht_ref::Ref{Float32}, debug::Bool, iout::Integer)
    local js::Int  = Int(SPS[ii])
    local d::Float32 = DBHS[ii]
    local h::Float32 = HTDEAD[ii]
    local lvd::String = LFIANVB ? "D" : " "
    _fmsvol_shared(js, d, h, Float32(xht), false, 0, lvd, debug, iout, vol2ht_ref)
    return nothing
end

function FMSVL2(jsp::Integer, xd::Real, xh::Real, xht::Real,
                vol2ht_ref::Ref{Float32}, crwnrto::Integer,
                livedead::Union{AbstractString,AbstractChar},
                lmerchin::Bool, debug::Bool, iout::Integer)
    local lvd::String = LFIANVB ? string(livedead) : " "   # string() handles Char or String
    _fmsvol_shared(Int(jsp), Float32(xd), Float32(xh), Float32(xht),
                   lmerchin, crwnrto, lvd, debug, iout, vol2ht_ref)
    return nothing
end
