# fmprun.f — Add pruned crown material to CWD pools
# FMPRUN: called from CUTS; CTCRWN(I) is the fraction of crown pruned for tree I
# CWD(k,j,m,l): k=size, j=category, m=hard/soft, l=decay class
# CROWNW[i, 1] = size class 0 (foliage), CROWNW[i, 2:6] = sizes 1-5

function FMPRUN(ctcrwn::AbstractVector{<:Real})
    debug = DBCHK("FMPRUN", 6, ICYC)
    if debug
        @printf(get(io_units, Int32(JOSTND), stdout),
            " ENTERING FMPRUN CYCLE = %2d LFMON=%s\n", ICYC, LFMON)
    end

    if !LFMON; return nothing; end

    for i in 1:Int(ITRN)
        local idc::Int = Int(DKRCLS[ISP[i]])
        local x::Float32 = Float32(ctcrwn[i]) * P2T

        # Foliage (SIZE=0 → index 1)
        CWD[1, 10, 2, idc] += CROWNW[i, 1] * x

        # Woody sizes 1-5 → indices 2-6
        for isz in 1:5
            CWD[1, isz, 2, idc] += CROWNW[i, isz+1] * x
        end

        if debug
            @printf(get(io_units, Int32(JOSTND), stdout),
                " I=%4d CTCRWN=%5.3f DBH=%7.2f ISP=%3d IDC=%2d X=%10.4e CROWNW=%9.2f%9.2f%9.2f%9.2f%9.2f%9.2f\n",
                i, ctcrwn[i], DBH[i], ISP[i], idc, x,
                CROWNW[i,1], CROWNW[i,2], CROWNW[i,3],
                CROWNW[i,4], CROWNW[i,5], CROWNW[i,6])
        end
    end

    FMCROW()
    return nothing
end
