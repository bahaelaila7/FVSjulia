# cutqfa.jl — CUTQFA / CYCQFA: Q-factor diameter-class thinning
# Translated from: cutqfa.f (338 lines)
#
# CUTQFA: precomputes residual TPA targets by diameter class for THINQFA.
# CYCQFA: called per-cycle by CUTS to retrieve diameter-class parameters.
#
# COMMON /QFACOM/ is module-level state shared between CUTQFA and CYCQFA.

const _QFACOM_NDCLS    = Ref(Int32(0))
const _QFACOM_ICOUNT   = Ref(Int32(1))
const _QFACOM_DCLS     = zeros(Float32, 30)
const _QFACOM_TPACLS   = zeros(Float32, 30, 4)
const _QFACOM_CLSTAR   = zeros(Float32, 30, 2)

function CUTQFA(valmin::Real, valmax::Real, ispcut::Integer, lzeide::Bool, icflag::Integer,
                ctpa::Real, cba::Real, csdi::Real, qfatar::Integer, qfac::Real, diacw::Real,
                jostnd1::Integer, debug1::Bool, ldelqfa_ref::Ref{Bool}, lqfa_ref::Ref{Bool})

    io = io_units[Int32(jostnd1)]
    if debug1
        @printf(io, " ENTERING CUTQFA\n")
        @printf(io, " VALMIN=%g VALMAX=%g ISPCUT=%d CTPA=%g CBA=%g CSDI=%g QFATAR=%d QFAC=%g DIACW=%g LZEIDE=%s\n",
            valmin, valmax, ispcut, ctpa, cba, csdi, qfatar, qfac, diacw, lzeide)
    end

    # Initialize arrays
    for i in 1:30
        _QFACOM_DCLS[i]    = Float32(0)
        for j in 1:4; _QFACOM_TPACLS[i,j] = Float32(0); end
        for j in 1:2; _QFACOM_CLSTAR[i,j] = Float32(0); end
    end

    lqfa_ref[]   = true
    cstocktpa    = Float32(0)
    ctpa_f       = Float32(ctpa)
    cba_f        = Float32(cba)
    csdi_f       = Float32(csdi)
    valmin_f     = Float32(valmin)
    valmax_f     = Float32(valmax)
    diacw_f      = Float32(diacw)
    qfac_f       = Float32(qfac)

    ndcls = Int(floor((valmax_f - valmin_f) / diacw_f))
    if ndcls > 30
        ldelqfa_ref[] = true
        @goto label_500
    end
    _QFACOM_NDCLS[] = Int32(ndcls)

    cls    = (valmax_f - valmin_f) / diacw_f
    remain = mod(cls, Float32(ndcls))
    if remain > 0.01f0
        @printf(io, "******THINQFA KEYWORD DIAMETER CLASSES NOT EQUAL, SMALLEST DIAMETER CLASS REMOVED\n")
    end
    if debug1; @printf(io, " NDCLS= %d\n", ndcls); end

    # Midpoints of diameter classes
    _QFACOM_DCLS[ndcls] = valmax_f - diacw_f / 2f0
    for i in ndcls-1:-1:1
        _QFACOM_DCLS[i] = _QFACOM_DCLS[i+1] - diacw_f
    end
    if debug1
        dcls_str = join([@sprintf("%g", _QFACOM_DCLS[i]) for i in 1:ndcls], " ")
        @printf(io, " NDCLS,DCLS(I)= %d %s\n", ndcls, dcls_str)
    end

    # Accumulate actual TPA and per-tree BA/SDI in each diameter class
    for i in 1:ndcls
        dlo = _QFACOM_DCLS[i] - diacw_f / 2f0
        dhi = _QFACOM_DCLS[i] + diacw_f / 2f0
        cstock_ref = Ref(Float32(0))
        CLSSTK(cstock_ref, Int32(1), Int32(ispcut), dlo, dhi, Int32(0), Float32(999), Int32(0))
        _QFACOM_TPACLS[i,1] = cstock_ref[]
        cstocktpa = cstock_ref[]

        if qfatar <= 0  # BA target
            CLSSTK(cstock_ref, Int32(2), Int32(ispcut), dlo, dhi, Int32(0), Float32(999), Int32(0))
            _QFACOM_CLSTAR[i,1] = _QFACOM_TPACLS[i,1] > 0 ?
                cstock_ref[] / _QFACOM_TPACLS[i,1] : Float32(0)
        elseif qfatar <= 1  # TPA target
            _QFACOM_CLSTAR[i,1] = _QFACOM_TPACLS[i,1] > 0 ?
                cstocktpa / _QFACOM_TPACLS[i,1] : Float32(0)
        else  # SDI target
            (sdic_v, sdic2_v, _a, _b) = SDICLS(Int32(ispcut), dlo, dhi, Int32(1), Int32(0))
            _QFACOM_CLSTAR[i,1] = _QFACOM_TPACLS[i,1] > 0 ?
                (lzeide ? sdic2_v : sdic_v) / _QFACOM_TPACLS[i,1] : Float32(0)
        end
    end

    if debug1
        tpa_str  = join([@sprintf("%g", _QFACOM_TPACLS[j,1]) for j in 1:ndcls], " ")
        cls_str  = join([@sprintf("%g", _QFACOM_CLSTAR[j,1]) for j in 1:ndcls], " ")
        @printf(io, " INITIAL TPA-TPACLS(J,1)= %s\n", tpa_str)
        @printf(io, " INITIAL BA OR SDI/TREE-CLSTAR(J,1)= %s\n", cls_str)
    end

    # Choose target
    ctar = qfatar <= 0 ? cba_f : (qfatar <= 1 ? ctpa_f : csdi_f)

    # Check if enough inventory to meet target
    suminv = Float32(0)
    for i in 1:ndcls
        suminv += _QFACOM_CLSTAR[i,1] * _QFACOM_TPACLS[i,1]
    end
    if debug1; @printf(io, " SUMINV=%g CTAR=%g\n", suminv, ctar); end
    if suminv < ctar
        ldelqfa_ref[] = true
        @goto label_500
    end

    # Set temp TPA and denominator
    for i in 1:ndcls
        _QFACOM_TPACLS[i,4] = _QFACOM_TPACLS[i,1]
    end
    dinom = Float32(0)
    for i in 1:ndcls
        dinom += _QFACOM_CLSTAR[i,1] / qfac_f^(i-1)
    end
    tpa1 = ctar / dinom

    # Iterative Q-factor convergence
    while true
        if debug1; @printf(io, " *** AFTER 200 TPA1=%g DINOM=%g CTAR=%g\n", tpa1, dinom, ctar); end

        for i in 1:ndcls
            _QFACOM_TPACLS[i,2] = tpa1 / qfac_f^(i-1)
            _QFACOM_TPACLS[i,3] = _QFACOM_TPACLS[i,4] - _QFACOM_TPACLS[i,2]
        end

        sumtar = Float32(0)
        for i in 1:ndcls
            sumtar += (_QFACOM_TPACLS[i,3] <= 0 ?
                _QFACOM_TPACLS[i,4] : _QFACOM_TPACLS[i,2]) * _QFACOM_CLSTAR[i,1]
        end

        dinom2 = Float32(0)
        for i in 1:ndcls
            if _QFACOM_TPACLS[i,3] > 0
                dinom2 += _QFACOM_CLSTAR[i,1] / qfac_f^(i-1)
                _QFACOM_TPACLS[i,4] = _QFACOM_TPACLS[i,3]
            else
                _QFACOM_TPACLS[i,4] = Float32(0)
            end
        end

        sum_v = Float32(0)
        for i in 1:ndcls
            if _QFACOM_TPACLS[i,3] > 0
                _QFACOM_CLSTAR[i,2] += _QFACOM_TPACLS[i,2] * _QFACOM_CLSTAR[i,1]
            else
                _QFACOM_CLSTAR[i,2] = _QFACOM_TPACLS[i,1] * _QFACOM_CLSTAR[i,1]
            end
            sum_v += _QFACOM_CLSTAR[i,2]
        end

        converged = qfatar <= 0 ? abs(cba_f  - sum_v) < 0.1f0 :
                    qfatar <= 1 ? abs(ctpa_f - sum_v) < 0.1f0 :
                                  abs(csdi_f - sum_v) < 0.1f0
        if converged; break; end

        if dinom2 > 0; tpa1 = (ctar - sumtar) / dinom2; end
        ctar = ctar - sumtar
        if abs(tpa1) <= 0.1f0; break; end
    end

    @label label_500
    if debug1; @printf(io, " ***AFTER 500-TPA1=%g\n", tpa1); end
    _QFACOM_ICOUNT[] = Int32(1)
    return nothing
end

function CYCQFA(valmin_ref::Ref{Float32}, valmax_ref::Ref{Float32},
                ctpa_ref::Ref{Float32}, cba_ref::Ref{Float32}, csdi_ref::Ref{Float32},
                qfatar::Integer, diacw::Real, icflag::Integer,
                jostnd1::Integer, debug1::Bool, lqfa_ref::Ref{Bool})

    io     = io_units[Int32(jostnd1)]
    diacw_f= Float32(diacw)
    ndcls  = Int(_QFACOM_NDCLS[])
    ic     = Int(_QFACOM_ICOUNT[])
    if debug1; @printf(io, " ENTERING CYCQFA-ICOUNT= %d\n", ic); end

    cba_ref[]  = Float32(0)
    ctpa_ref[] = Float32(0)
    csdi_ref[] = Float32(0)

    # Advance to first class with excess
    while ic <= ndcls
        excess = _QFACOM_TPACLS[ic,1] * _QFACOM_CLSTAR[ic,1] - _QFACOM_CLSTAR[ic,2]
        if excess > 1.0f-5
            valmin_ref[] = _QFACOM_DCLS[ic] - diacw_f / 2f0
            valmax_ref[] = _QFACOM_DCLS[ic] + diacw_f / 2f0
            if qfatar <= 0
                cba_ref[]  = _QFACOM_CLSTAR[ic,2]
            elseif qfatar <= 1
                ctpa_ref[] = _QFACOM_CLSTAR[ic,2]
            else
                csdi_ref[] = _QFACOM_CLSTAR[ic,2]
            end
            _QFACOM_ICOUNT[] = Int32(ic + 1)
            break
        end
        ic += 1
        _QFACOM_ICOUNT[] = Int32(ic)
    end

    # Check if more classes remain
    lqfa_ref[] = false
    for i in Int(_QFACOM_ICOUNT[]):ndcls
        e1 = _QFACOM_TPACLS[i,1] * _QFACOM_CLSTAR[i,1] - _QFACOM_CLSTAR[i,2]
        if debug1; @printf(io, " EXCESS1= %g\n", e1); end
        if e1 > 1.0f-5; lqfa_ref[] = true; break; end
    end
    if Int(_QFACOM_ICOUNT[]) > ndcls; lqfa_ref[] = false; end
    if debug1
        @printf(io, " LEAVING CYCQFA-ICOUNT= %d\n", _QFACOM_ICOUNT[])
        @printf(io, " VALMIN=%g VALMAX=%g CBA=%g CSDI=%g LQFA=%s\n",
            valmin_ref[], valmax_ref[], cba_ref[], csdi_ref[], lqfa_ref[])
    end
    return nothing
end
