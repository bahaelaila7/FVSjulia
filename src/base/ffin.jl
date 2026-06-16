# base/ffin.jl — FFIN: schedule FERTILIZER keyword activity
# Translated from: bin/FVSsn_buildDir/ffin.f (59 lines)
#
# Called from INITRE when FERTILIZER keyword is encountered.
# Schedules activity code 260 (fertilizer) via OPNEW or OPNEWC.
# Note: only 200 lbs nitrogen is supported; other amounts → warning + 200 lbs assumed.

function FFIN(jostnd::Integer, irecnt::Integer, keywrd::AbstractString,
              array::AbstractVector{Float32}, lnotbk::AbstractVector,
              kard::AbstractVector, iprmpt::Integer, icyc::Integer,
              iread::Integer, lkecho::Bool)
    io = io_units[Int32(jostnd)]

    idt = Int32(1)
    if lnotbk[1]; idt = Int32(trunc(array[1])); end

    if iprmpt > 0
        if iprmpt != 2
            KEYDMP(jostnd, irecnt, keywrd, array, kard)
            ERRGRO(true, Int32(25))
        else
            kode_r = Ref(Int32(0))
            OPNEWC(kode_r, jostnd, iread, Int(idt), Int32(260),
                   keywrd, kard, iprmpt, irecnt, icyc)
            irtncd = fvsGetRtnCode()
            if irtncd != Int32(0); return nothing; end
        end
        return nothing
    end

    # Non-prompt mode
    if !lnotbk[2]; array[2] = Float32(200); end
    if array[2] != Float32(200)
        if lkecho
            @printf(io, "             ONLY TREATMENTS WITH 200 POUNDS NITROGEN CAN BE REPRESENTED.  PARAMETER CHANGED ACCORDINGLY.\n")
        end
        array[2] = Float32(200)
    end
    if !lnotbk[5]; array[5] = Float32(1); end

    kode_r = Ref(Int32(0))
    OPNEW(kode_r, Int(idt), Int32(260), Int32(4), view(array, 2:length(array)))
    if kode_r[] > Int32(0); return nothing; end

    @printf(io, "\n %-8s   DATE/CYCLE=%5d; APPLY %6.0f POUNDS NITROGEN, %6.0f POUNDS PHOSPHORUS, AND %6.0f POUNDS POTASSIUM PER ACRE.\n",
            keywrd, idt, array[2], array[3], array[4])
    @printf(io, "             THE EFFECT OF THIS APPLICATION IS MULTIPLIED BY %10.4f\n", array[5])

    if array[3] > Float32(0) || array[4] > Float32(0)
        @printf(io, "             TREATMENTS WITH PHOSPHORUS AND POTASSIUM CAN NOT BE REPRESENTED.  THESE VALUES WILL BE IGNORED.\n")
    end
    if array[2] != Float32(200)
        @printf(io, "             TREATMENTS WITH OTHER THAN 200 POUNDS NITROGEN CAN NOT BE REPRESENTED; 200 POUNDS IS ASSUMED.\n")
    end
    return nothing
end
