# base/stash.jl — STASH/DSTASH/CHSTSH/CHDSTH: binary checkpoint I/O
# Translated from: bin/FVSsn_buildDir/stash.f (109 lines)
#
# Fortran unformatted binary records: each WRITE(unit) emits a 4-byte record
# length prefix, the data, and a 4-byte suffix. Julia mirrors this with
# write_fortran_record / read_fortran_record helpers so that restart files
# written here are byte-compatible with the Fortran binary.

function _write_fortran_record(io::IO, data::AbstractArray)
    nbytes = Int32(length(data) * sizeof(eltype(data)))
    write(io, nbytes)
    write(io, data)
    write(io, nbytes)
end

function _write_fortran_record(io::IO, data::AbstractVector{UInt8})
    nbytes = Int32(length(data))
    write(io, nbytes)
    write(io, data)
    write(io, nbytes)
end

function _read_fortran_record!(io::IO, data::AbstractArray)
    nbytes_hdr = read(io, Int32)
    read!(io, data)
    _nbytes_ftr = read(io, Int32)
    return nothing
end

function _read_fortran_record!(io::IO, data::AbstractVector{UInt8})
    nbytes_hdr = read(io, Int32)
    read!(io, data)
    _nbytes_ftr = read(io, Int32)
    return nothing
end

# STASH: write a Float32 array to the stash file (unit jstash)
function STASH(buffer::AbstractVector{Float32}, ilimit::Integer)
    io = get(io_units, Int32(jstash), nothing)
    if io === nothing; return nothing; end
    _write_fortran_record(io, view(buffer, 1:Int(ilimit)))
    return nothing
end

# CHSTSH: write a character (UInt8) array to the stash file
function CHSTSH(cbuff::AbstractVector{UInt8}, lncbuf::Integer)
    io = get(io_units, Int32(jstash), nothing)
    if io === nothing; return nothing; end
    _write_fortran_record(io, view(cbuff, 1:Int(lncbuf)))
    return nothing
end

# DSTASH: read a Float32 array from the restart file (unit jdstash).
# If seekReadPos > 0 attempts a seek to that position before reading.
function DSTASH(buffer::AbstractVector{Float32}, ipnt::Integer)
    global seekReadPos, fvsRtnCode
    io = get(io_units, Int32(jdstash), nothing)
    if io === nothing
        fvsRtnCode = Int32(2)
        return nothing
    end

    if seekReadPos > Int32(0)
        try
            sz = filesize(io)
            if seekReadPos > sz
                fvsRtnCode = Int32(2)
                return nothing
            end
            seek(io, Int(seekReadPos) - 1)   # Fortran POS is 1-based byte offset
        catch
            fvsRtnCode = Int32(2)
            return nothing
        end
        global seekReadPos = Int32(-1)
    end

    try
        _read_fortran_record!(io, view(buffer, 1:Int(ipnt)))
    catch
        fvsRtnCode = Int32(2)
    end
    return nothing
end

# CHDSTH: read a character (UInt8) array from the restart file
function CHDSTH(cbuff::AbstractVector{UInt8}, ipnt::Integer)
    global fvsRtnCode
    io = get(io_units, Int32(jdstash), nothing)
    if io === nothing
        fvsRtnCode = Int32(2)
        return nothing
    end
    try
        _read_fortran_record!(io, view(cbuff, 1:Int(ipnt)))
    catch
        fvsRtnCode = Int32(2)
    end
    return nothing
end
