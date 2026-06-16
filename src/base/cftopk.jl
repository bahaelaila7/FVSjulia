# cftopk.jl — CFTOPK: correct cubic foot volumes for broken/damaged tops
# Translated from: cftopk.f (136 lines), originally from IE variant
#
# Corrects TCF (total cubic), MCF (merchantable cubic), SCF (sawtimber cubic)
# for top-kill. Uses Behre hyperbola taper model (BEHPRM + BEHRE).
# ITHT is truncation height × 100 (e.g., 5000 = 50 ft from ground).

function CFTOPK(ispc::Integer, d::Real, h::Real,
                tcf_ref::Ref{Float32}, mcf_ref::Ref{Float32}, scf_ref::Ref{Float32},
                vmax::Real, lcone::Bool, bark::Real, itht::Integer)

    tcf = tcf_ref[]; mcf = mcf_ref[]; scf = scf_ref[]
    d_f = Float32(d); h_f = Float32(h); bark_f = Float32(bark)

    if tcf > Float32(0)
        lcone_r = Ref(lcone)
        BEHPRM(vmax, d_f, h_f, bark_f, lcone_r)
        volt = BEHRE(Float32(0), Float32(1))
        htrunc = Float32(itht) / Float32(100)
        pht = Float32(1) - htrunc / h_f
        if pht < Float32(0); pht = Float32(0); end
        dtrunc = pht / (AHAT * pht + BHAT)
        if !lcone_r[]
            voltk = BEHRE(pht, Float32(1))
            tcf = tcf * voltk / volt
        else
            tcf = tcf * (Float32(1) - pht^3)
        end
    end

    if mcf > Float32(0)
        stump = Float32(1) - STMP[ispc] / h_f
        dmrch = TOPD[ispc] / d_f
        htmrch = (BHAT * dmrch) / (Float32(1) - AHAT * dmrch)
        volt = BEHRE(htmrch, stump)
        if !lcone
            if dtrunc > dmrch
                voltk = BEHRE(pht, stump)
                mcf = mcf * voltk / volt
            end
        else
            s3 = stump^3
            volm = s3 - htmrch^3
            if dtrunc > dmrch
                voltk = s3 - pht^3
                mcf = mcf * voltk / volm
            end
        end
        if mcf > tcf; mcf = tcf; end
        if mcf < Float32(0); mcf = Float32(0); end

        if scf > Float32(0)
            stump = Float32(1) - SCFSTMP[ispc] / h_f
            dmrch = SCFTOPD[ispc] / d_f
            htmrch = (BHAT * dmrch) / (Float32(1) - AHAT * dmrch)
            volt = BEHRE(htmrch, stump)
            if !lcone
                if dtrunc > dmrch
                    voltk = BEHRE(pht, stump)
                    scf = scf * voltk / volt
                end
            else
                s3 = stump^3
                volm = s3 - htmrch^3
                if dtrunc > dmrch
                    voltk = s3 - pht^3
                    scf = scf * voltk / volm
                end
            end
            if scf > mcf; scf = mcf; end
            if scf < Float32(0); scf = Float32(0); end
        end
    end

    tcf_ref[] = tcf; mcf_ref[] = mcf; scf_ref[] = scf
    return nothing
end
