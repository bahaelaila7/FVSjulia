# ch4bsr.f — CH4BSR: Character*4 keyed binary search (103 lines)
# ch4srt.f — CH4SRT: Character*4 indirect index sort / quickersort (111 lines)
# Used by MPB bark beetle dispersal model.

# CH4BSR: search for string F in array A using ascending-order index IORD.
# Sets ip_ref[] = position in A where F was found, or 0 if not found.
function CH4BSR(n::Integer, a::AbstractVector{<:AbstractString},
                iord::AbstractVector{Int32}, f::AbstractString,
                ip_ref::Ref{Int32})
    imid = 1
    i1   = Int(iord[1])

    if f > a[i1]
        imid = n
        in_  = Int(iord[n])
        if f < a[in_]
            itop = 1
            ibot = n
            @label label_20
            imid = (ibot + itop) ÷ 2
            im   = Int(iord[imid])
            if f > a[im]
                @goto label_30
            end
            ibot = imid - 1
            ib   = Int(iord[ibot])
            if f <= a[ib]
                @goto label_20
            end
            @goto label_40
            @label label_30
            itop = imid + 1
            it   = Int(iord[itop])
            if f >= a[it]
                @goto label_20
            end
        end
    end

    @label label_40
    ip_final = Int(iord[imid])
    ip_ref[] = (f == a[ip_final]) ? Int32(ip_final) : Int32(0)
    return nothing
end

# CH4SRT: indirect quicksort of character*4 array A via index array INDEX[1..n].
# If lseq=true, initialize INDEX[1..n] = 1..n before sorting.
# After call, A[INDEX[1]] <= ... <= A[INDEX[n]].
function CH4SRT(n::Integer, a::AbstractVector{<:AbstractString},
                index::AbstractVector{Int32}, lseq::Bool)
    if lseq
        for i in 1:n
            index[i] = Int32(i)
        end
    end
    n < 2 && return nothing

    ipush = zeros(Int32, 33)
    itop  = 0
    il    = 1
    iu    = n

    @label label_30
    if iu <= il
        @goto label_40
    end
    indil = Int(index[il])
    indiu = Int(index[iu])
    if iu > il + 1
        @goto label_50
    end
    if a[indil] <= a[indiu]
        @goto label_40
    end
    index[il] = Int32(indiu)
    index[iu] = Int32(indil)

    @label label_40
    if itop == 0; return nothing; end
    il   = Int(ipush[itop - 1])
    iu   = Int(ipush[itop])
    itop -= 2
    @goto label_30

    @label label_50
    ip    = (il + iu) ÷ 2
    indip = Int(index[ip])
    t     = a[indip]
    index[ip] = Int32(indil)
    kl = il
    ku = iu

    @label label_60
    kl += 1
    if kl > ku; @goto label_90; end
    indkl = Int(index[kl])
    if a[indkl] <= t; @goto label_60; end

    @label label_70
    indku = Int(index[ku])
    if ku < kl; @goto label_100; end
    if a[indku] < t; @goto label_80; end
    ku -= 1
    @goto label_70

    @label label_80
    index[kl] = Int32(indku)
    index[ku] = Int32(indkl)
    ku -= 1
    @goto label_60

    @label label_90
    indku = Int(index[ku])

    @label label_100
    index[il] = Int32(indku)
    index[ku] = Int32(indip)
    if ku <= ip
        @goto label_110
    end
    jl = il
    ju = ku - 1
    il = ku + 1
    @goto label_120

    @label label_110
    jl = ku + 1
    ju = iu
    iu = ku - 1

    @label label_120
    itop += 2
    ipush[itop - 1] = Int32(jl)
    ipush[itop]     = Int32(ju)
    @goto label_30
end
