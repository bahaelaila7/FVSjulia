# opcact.jl — OPCACT: store a character string associated with an activity
# Translated from: opcact.f (78 lines)

function OPCACT(kode_ref::Ref{Int32}, cstr::AbstractString)
    io = io_units[Int32(JOSTND)]
    ldeb = DBCHK(false, "OPCACT", Int32(6), ICYC)
    if ldeb
        @printf(io, " IN OPCACT: ICACT=%4d MXCACT=%6d LOPEVN=%s IMPL=%4d IEPT=%5d CSTR=%s\n",
            ICACT, MXCACT, LOPEVN, IMPL, IEPT, cstr)
    end

    nchar = length(cstr)
    if nchar + Int(ICACT) > Int(MXCACT)
        kode_ref[] = Int32(1)
        ERRGRO(true, Int32(10))
        @printf(io, " ISSUED IN OPCACT CANNOT ADD ACTIVITY STRING\n")
        return nothing
    end

    kode_ref[] = Int32(1)
    i = LOPEVN ? Int(IEPT) + 1 : Int(IMGL) - 1
    IACT[i, 5] = ICACT

    for ch in cstr
        CACT[Int(ICACT)] = ch
        global ICACT = ICACT + Int32(1)
    end
    # Null-terminate
    CACT[Int(ICACT)] = '\0'
    global ICACT = ICACT + Int32(1)
    return nothing
end
