# fmhide.f — Debug/checking output for snag volumes and CWD
# FMHIDE: prints per-snag density/volume by DBH class (<12" / >=12") + CWDNEW
# Called from: FMMAIN (only when JCOUT > 0)

function FMHIDE(istd::Integer, iyr::Integer)
    if JCOUT <= 0; return nothing; end

    local totd = zeros(Float32, 2)
    local totv = zeros(Float32, 2)

    for i in 1:Int(NSNAG)
        if (DENIS[i] + DENIH[i]) <= 0.0f0; continue; end

        local snvih_ref = Ref(Float32(0))
        local snvis_ref = Ref(Float32(0))

        if DENIH[i] > 0.0f0
            FMSVOL(Int32(i), HTIH[i], snvih_ref, false, Int32(0))
            snvih_ref[] *= DENIH[i]
        end
        if DENIS[i] > 0.0f0
            FMSVOL(Int32(i), HTIS[i], snvis_ref, false, Int32(0))
            snvis_ref[] *= DENIS[i]
        end

        local jcl::Int = DBHS[i] < 12.0f0 ? 1 : 2
        totd[jcl] += DENIS[i] + DENIH[i]
        totv[jcl] += snvis_ref[] + snvih_ref[]
    end

    local jcout_io = get(io_units, Int32(JCOUT), stdout)
    @printf(jcout_io, "%4d %4d %6.1f %6.1f %6.0f %6.0f ",
            iyr, istd, totd[1], totd[2], totv[1], totv[2])
    for i in 1:11; @printf(jcout_io, "%7.2f ", CWDNEW[1, i]); end
    for i in 1:11; @printf(jcout_io, "%6.2f ", CWDNEW[2, i]); end
    println(jcout_io)

    for i in 1:Int(MXFLCL)
        CWDNEW[1, i] = 0.0f0
        CWDNEW[2, i] = 0.0f0
    end
    return nothing
end
