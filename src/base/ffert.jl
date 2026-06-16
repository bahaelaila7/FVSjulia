# ffert.jl — FFERT: fertilization growth adjustment (keyword 260)
# Translated from: ffert.f (184 lines)
#
# Computes diameter and height growth ratios from N/P/K fertilizer application
# and applies them as multiplicative adjustments to DG and HTG for each tree.
# Called from TREGRO (not yet translated).
#
# COMMON /FFCOM/ is module-level state (initialized cycle 1).

# Module-level SAVE state for FFERT (mirrors COMMON /FFCOM/)
const _FFERT_STATE = Ref((iffdat = Int32(-1), ffprms = Float32[0f0, 0f0, 0f0, 0f0]))

function FFERT()
    debug = DBCHK(false, "FFERT", Int32(5), ICYC)

    # Initialize on cycle 1
    if ICYC <= 1
        _FFERT_STATE[] = (iffdat = Int32(-1), ffprms = Float32[0f0, 0f0, 0f0, 0f0])
    end

    st = _FFERT_STATE[]
    iffdat = st.iffdat
    ffprms = copy(st.ffprms)

    myacts = Int32[260]
    ntodo_ref = Ref(Int32(0))
    OPFIND(Int32(1), myacts, ntodo_ref)
    ntodo = ntodo_ref[]

    if ntodo > 0
        idt_r  = Ref(Int32(0)); iactk_r = Ref(Int32(0))
        np_r   = Ref(Int32(0))
        OPGET(Int32(ntodo), Int32(4), idt_r, iactk_r, np_r, ffprms)
        if iactk_r[] < 0; @goto label_100; end
        iffdat = IY[Int(ICYC)]
        OPDONE(Int32(ntodo), IY[Int(ICYC)])
        if ntodo > 1
            for ii in 1:(ntodo-1)
                OPDEL1(Int32(ii))
            end
        end
    else
        if iffdat < 0; @goto label_100; end
    end

    let
        ifstrt = Int(IY[Int(ICYC)]) - Int(iffdat)
        if ifstrt > 10; @goto label_100; end
        iffin  = ifstrt + Int(IFINT)
        if iffin > 10; iffin = 10; end
        iflen  = iffin - ifstrt
        if iflen <= 0; @goto label_100; end
        if iflen != 10
            @printf(io_units[Int(JOSTND)],
                "\n ***** WARNING: FERTILIZER EFFECT IS BEING APPLIED FOR %2d OF %2d YEARS.  BIASED ESTIMATES MAY RESULT.\n",
                iflen, Int(IFINT))
            RCDSET(Int32(1), true)
        end

        # Habitat check (SN variant only uses habitat codes 520 and 530)
        if ICL5 != 520 && ICL5 != 530
            @printf(io_units[Int(JOSTND)],
                "\n ***** WARNING: HABITAT CODE:%4d IS OUTSIDE THE RANGE OF THE FERTILIZER MODEL.\n", ICL5)
            RCDSET(Int32(1), true)
        end

        # Species composition check (DF and GF contribution)
        cdfgf = (RELDSP[3] + RELDSP[4]) / RELDEN
        if cdfgf < Float32(0.5)
            @printf(io_units[Int(JOSTND)],
                "\n ***** WARNING: SPECIES COMPOSITION IS OUTSIDE THE RANGE OF THE FERTILIZER MODEL.\n")
            RCDSET(Int32(1), true)
        end

        iflen_f = Float32(iflen)
        feff    = ffprms[4]

        for ispc in 1:MAXSP
            i1 = ISCT[ispc, 1]
            if i1 == 0; continue; end
            i2 = ISCT[ispc, 2]
            for i3 in i1:i2
                i = Int(IND1[i3])
                d = DBH[i]
                barks = BRATIO(ispc, d, HT[i])
                if d <= Float32(0); continue; end

                bal  = (Float32(1) - PCT[i] / Float32(100)) * BA
                rdds = exp(Float32(0.1108) * log(d) + Float32(0.003004) * bal / log(d + Float32(1)))
                if rdds > Float32(2.6); rdds = Float32(2.6); end

                dib   = d * barks
                dds   = Float32(2) * dib * DG[i] + DG[i] * DG[i]
                ddsit = (dds / YR) * (rdds * iflen_f * feff + Float32(Int(IFINT)) - iflen_f)
                ddsyr = ddsit * YR / Float32(Int(FINT))
                DG[i] = sqrt(dib*dib + ddsyr) - dib

                rht    = Float32(1.1626)
                htgit  = (HTG[i] / YR) * (rht * iflen_f * feff + Float32(Int(IFINT)) - iflen_f)
                HTG[i] = htgit * YR / Float32(Int(FINT))

                if debug
                    @printf(io_units[Int(JOSTND)],
                        " IN FFERT I=%4d, ISPC=%3d, DBH=%7.2f, DG(I)=%7.4f, HTG(I)=%7.4f, RDDS=%7.2f\n",
                        i, ispc, d, DG[i], HTG[i], rdds)
                end
            end
        end
    end

    @label label_100
    _FFERT_STATE[] = (iffdat = iffdat, ffprms = ffprms)
    return nothing
end
