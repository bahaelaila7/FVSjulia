# base/putgetsubs.jl — BFREAD/BFWRIT/CHREAD/CHWRIT/LFREAD/LFWRIT/IFREAD/IFWRIT
# Translated from: bin/FVSsn_buildDir/putgetsubs.f (266 lines)
#
# Buffered I/O helpers for the FVS stop/restart (stash) mechanism.
# Used by PUTSTD (serialize) and GETSTD (deserialize) to pack/unpack all
# simulation arrays into a binary stash file via STASH/DSTASH.
#
# ibegin semantics:
#   1 = first call (reset buffer pointer)
#   2 = middle call
#   3 = last call (flush buffer)

# ---------------------------------------------------------------------------
# BFREAD: read ILEN Float32 values from buffer; reload from stash when empty
function BFREAD(buffer::AbstractVector{Float32}, ipnt_ref::Ref{Int32},
                ilimit::Integer, varble::AbstractVector{Float32},
                ilen::Integer, ibegin::Integer)
    if ibegin == 1; ipnt_ref[] = Int32(ilimit); end
    if ilen < 1; return nothing; end
    for iword in 1:ilen
        if ipnt_ref[] >= Int32(ilimit)
            DSTASH(buffer, Int(ilimit))
            if fvsRtnCode != Int32(0); return nothing; end
            ipnt_ref[] = Int32(0)
        end
        ipnt_ref[] += Int32(1)
        varble[iword] = buffer[ipnt_ref[]]
    end
    return nothing
end

# BFWRIT: write ILEN Float32 values to buffer; flush to stash when full
function BFWRIT(buffer::AbstractVector{Float32}, ipnt_ref::Ref{Int32},
                ilimit::Integer, varble::AbstractVector{Float32},
                ilen::Integer, ibegin::Integer)
    if ibegin == 1; ipnt_ref[] = Int32(0); end
    if ilen >= 1
        for iword in 1:ilen
            if ipnt_ref[] >= Int32(ilimit)
                STASH(buffer, Int(ilimit))
                ipnt_ref[] = Int32(0)
            end
            ipnt_ref[] += Int32(1)
            buffer[ipnt_ref[]] = varble[iword]
        end
    end
    if ibegin == 3; STASH(buffer, Int(ilimit)); end
    return nothing
end

# ---------------------------------------------------------------------------
# CHREAD: read one character from a character buffer; reload from stash when needed
function CHREAD(cbuff::AbstractVector{UInt8}, ipnt_ref::Ref{Int32},
                lncbuf::Integer, cvarbl_ref::Ref{UInt8}, ibegin::Integer)
    if ibegin == 1; ipnt_ref[] = Int32(lncbuf); end
    if ipnt_ref[] >= Int32(lncbuf)
        CHDSTH(cbuff, Int(lncbuf))
        if fvsRtnCode != Int32(0); return nothing; end
        ipnt_ref[] = Int32(0)
    end
    ipnt_ref[] += Int32(1)
    cvarbl_ref[] = cbuff[ipnt_ref[]]
    return nothing
end

# CHWRIT: write one character to a character buffer; flush when full
function CHWRIT(cbuff::AbstractVector{UInt8}, ipnt_ref::Ref{Int32},
                lncbuf::Integer, cvarbl::UInt8, ibegin::Integer)
    if ibegin == 1; ipnt_ref[] = Int32(0); end
    if ipnt_ref[] >= Int32(lncbuf)
        CHSTSH(cbuff, Int(lncbuf))
        ipnt_ref[] = Int32(0)
    end
    ipnt_ref[] += Int32(1)
    cbuff[ipnt_ref[]] = cvarbl
    if ibegin == 3
        if ipnt_ref[] < Int32(lncbuf)
            for i in (Int(ipnt_ref[]) + 1):Int(lncbuf)
                cbuff[i] = UInt8(' ')
            end
        end
        CHSTSH(cbuff, Int(lncbuf))
    end
    return nothing
end

# ---------------------------------------------------------------------------
# LFREAD: read ILEN Bool values via Float32 bit reinterpretation
function LFREAD(buffer::AbstractVector{Float32}, ipnt_ref::Ref{Int32},
                ilimit::Integer, lvar::AbstractVector{Bool},
                ilen::Integer, ibegin::Integer)
    if ibegin == 1; ipnt_ref[] = Int32(ilimit); end
    if ilen < 1; return nothing; end
    for iword in 1:ilen
        if ipnt_ref[] >= Int32(ilimit)
            DSTASH(buffer, Int(ilimit))
            if fvsRtnCode != Int32(0); return nothing; end
            ipnt_ref[] = Int32(0)
        end
        ipnt_ref[] += Int32(1)
        # EQUIVALENCE (LSTOR, RSTOR): reinterpret Float32 bits as logical (non-zero = .TRUE.)
        lvar[iword] = reinterpret(Int32, buffer[ipnt_ref[]]) != Int32(0)
    end
    return nothing
end

# LFWRIT: write ILEN Bool values via Float32 bit reinterpretation
function LFWRIT(buffer::AbstractVector{Float32}, ipnt_ref::Ref{Int32},
                ilimit::Integer, lvar::AbstractVector{Bool},
                ilen::Integer, ibegin::Integer)
    if ibegin == 1; ipnt_ref[] = Int32(0); end
    if ilen >= 1
        for iword in 1:ilen
            if ipnt_ref[] >= Int32(ilimit)
                STASH(buffer, Int(ilimit))
                ipnt_ref[] = Int32(0)
            end
            ipnt_ref[] += Int32(1)
            # EQUIVALENCE (RSTOR, LSTOR): .TRUE. = 1, .FALSE. = 0 in F77
            buffer[ipnt_ref[]] = reinterpret(Float32, lvar[iword] ? Int32(1) : Int32(0))
        end
    end
    if ibegin == 3; STASH(buffer, Int(ilimit)); end
    return nothing
end

# ---------------------------------------------------------------------------
# IFREAD: read ILEN Int32 values via Float32 bit reinterpretation
function IFREAD(buffer::AbstractVector{Float32}, ipnt_ref::Ref{Int32},
                ilimit::Integer, ivar::AbstractVector{Int32},
                ilen::Integer, ibegin::Integer)
    if ibegin == 1; ipnt_ref[] = Int32(ilimit); end
    if ilen < 1; return nothing; end
    for iword in 1:ilen
        if ipnt_ref[] >= Int32(ilimit)
            DSTASH(buffer, Int(ilimit))
            if fvsRtnCode != Int32(0); return nothing; end
            ipnt_ref[] = Int32(0)
        end
        ipnt_ref[] += Int32(1)
        # EQUIVALENCE (RSTOR, ISTOR): reinterpret Float32 bits as Int32
        ivar[iword] = reinterpret(Int32, buffer[ipnt_ref[]])
    end
    return nothing
end

# IFWRIT: write ILEN Int32 values via Float32 bit reinterpretation
function IFWRIT(buffer::AbstractVector{Float32}, ipnt_ref::Ref{Int32},
                ilimit::Integer, ivar::AbstractVector{Int32},
                ilen::Integer, ibegin::Integer)
    if ibegin == 1; ipnt_ref[] = Int32(0); end
    if ilen >= 1
        for iword in 1:ilen
            if ipnt_ref[] >= Int32(ilimit)
                STASH(buffer, Int(ilimit))
                ipnt_ref[] = Int32(0)
            end
            ipnt_ref[] += Int32(1)
            # EQUIVALENCE (RSTOR, ISTOR)
            buffer[ipnt_ref[]] = reinterpret(Float32, ivar[iword])
        end
    end
    if ibegin == 3; STASH(buffer, Int(ilimit)); end
    return nothing
end
