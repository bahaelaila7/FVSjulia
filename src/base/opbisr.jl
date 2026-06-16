# opbisr.jl — OPBISR: binary search in ascending integer array
# Translated from: opbisr.f (40 lines)
#
# Finds position of integer IF_ in sorted array IA of length N.
# Returns position in ip_ref, or 0 if not found.

function OPBISR(n::Integer, ia::AbstractVector{Int32}, if_::Integer, ip_ref::Ref{Int32})
    n_i   = Int(n)
    if_i  = Int(if_)

    imid = 1
    if if_i <= Int(ia[1])
        @goto label_40
    end
    imid = n_i
    if if_i >= Int(ia[n_i])
        @goto label_40
    end
    itop = 1
    ibot = n_i
    while true
        imid = (ibot + itop) ÷ 2
        if if_i >= Int(ia[imid])
            itop = imid + 1
            if if_i < Int(ia[itop])
                @goto label_40
            end
        else
            ibot = imid - 1
            if if_i > Int(ia[ibot])
                @goto label_40
            end
        end
    end
    @label label_40
    ip_ref[] = (if_i == Int(ia[imid])) ? Int32(imid) : Int32(0)
    return nothing
end
