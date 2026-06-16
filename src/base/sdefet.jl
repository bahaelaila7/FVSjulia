# sdefet.jl — SDEFET: process BFDEFECT / MCDEFECT keywords
# Translated from: sdefet.f (167 lines)

function SDEFET(lnotbk::AbstractVector{Bool}, array::AbstractVector{Float32},
                keywrd::AbstractString, lopevn::Bool, iactk::Integer,
                kard::AbstractVector{<:AbstractString}, iprmpt::Integer)

    io = io_units[Int32(JOSTND)]

    if iprmpt > 0
        idt = lnotbk[1] ? Int32(floor(array[1])) : Int32(1)
        if iprmpt != 2
            KEYDMP(JOSTND, IRECNT, keywrd, array, kard)
            ERRGRO(true, Int32(25))
        else
            kode = OPNEWC(JOSTND, IREAD, idt, Int32(iactk), keywrd, kard, iprmpt, IRECNT, ICYC)
            irtncd = Ref(Int32(0)); fvsGetRtnCode(irtncd)
            if irtncd[] != 0; return nothing; end
        end
        return nothing
    end

    is_ref = Ref(Int32(0))
    SPDECD(Int32(2), is_ref, NSP[:, 1], Int32(JOSTND), IRECNT, keywrd, array, kard)
    is = Int(is_ref[])
    if is == -999; return nothing; end

    xx = zeros(Float32, 6); yy = zeros(Float32, 6)
    xx[1] = Float32(0); yy[1] = Float32(0)
    n = 1
    for i in 3:7
        if lnotbk[i]
            n += 1
            xx[n] = Float32(i - 2) * Float32(5)
            yy[n] = array[i]
        end
    end
    if n <= 1
        KEYDMP(JOSTND, IRECNT, keywrd, array, kard)
        ERRGRO(true, Int32(4))
        return nothing
    end
    if n < 6
        for i in 3:7
            if !lnotbk[i]
                array[i] = ALGSLP(Float32(i - 2) * Float32(5), xx, yy, n)
            end
        end
    end

    if lnotbk[1] || lopevn
        idt = lnotbk[1] ? Int32(floor(array[1])) : Int32(1)
        kode_ref = Ref(Int32(0))
        OPNEW(kode_ref, idt, Int32(iactk), Int32(6), array[2:end])
        kard2 = collect(kard)
        kard2[2] = rpad(kard2[2][1:min(6,end)], 6) * @sprintf("%4d", idt)
        ilen = is < 0 ? ISPGRP(-is, Int32(92)) : 3
        @printf(io, "\n%-8s    DATE/CYCLE= %s; SPECIES=%-3s (CODE=%2d); 5 INCH TREES=%6.2f; 10 INCH TREES=%6.2f; 15 INCH TREES=%6.2f\n            20 INCH TREES=%6.2f;  25 INCH AND LARGER TREES=%6.2f\n",
            keywrd, kard2[2][7:10], kard2[2][1:ilen], is,
            array[3], array[4], array[5], array[6], array[7])
    else
        ilen = is < 0 ? ISPGRP(-is, Int32(92)) : 3
        @printf(io, "\n%-8s    DEFECT CHANGED; SPECIES=%-3s (CODE=%2d); 5 INCH TREES=%6.2f; 10 INCH TREES=%6.2f; 15 INCH TREES=%6.2f\n            20 INCH TREES=%6.2f;  25 INCH AND LARGER TREES=%6.2f\n",
            keywrd, kard[2][1:ilen], is, array[3], array[4], array[5], array[6], array[7])

        if is < 0
            igrp = -is
            iulim = Int(ISPGRP(igrp, Int32(1))) + 1
            for ig in 2:iulim
                igsp = Int(ISPGRP(igrp, Int32(ig)))
                if iactk == 215
                    for i in 2:6; CFDEFT[i, igsp] = array[i+1]; end
                    for i in 7:9; CFDEFT[i, igsp] = array[7]; end
                elseif iactk == 216
                    for i in 2:6; BFDEFT[i, igsp] = array[i+1]; end
                    for i in 7:9; BFDEFT[i, igsp] = array[7]; end
                end
            end
        else
            i1 = is == 0 ? 1 : is
            i2 = is == 0 ? Int(MAXSP) : is
            for isp in i1:i2
                for i in 2:6
                    if iactk == 216; BFDEFT[i, isp] = array[i+1]; end
                    if iactk == 215; CFDEFT[i, isp] = array[i+1]; end
                end
                BFDEFT[7, isp] = array[7]; BFDEFT[8, isp] = array[7]; BFDEFT[9, isp] = array[7]
                CFDEFT[7, isp] = array[7]; CFDEFT[8, isp] = array[7]; CFDEFT[9, isp] = array[7]
            end
        end
    end
    return nothing
end
