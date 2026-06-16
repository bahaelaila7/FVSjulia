# prtexm.jl — PRTEXM: print example-tree/stand-attribute table from binary file
# Translated from: prtexm.f (156 lines)
#
# Reads unformatted (binary) records written by the example-tree pass, prints
# formatted table to unit IPRINT.  Record types:
#   0 = stand identifier (first record)
#   1 = stand attribute, no residual follows
#   2 = stand attribute, residual record follows
#   3 = residual record (only after type-2)
#   4 = year + period-length record
#   5 = example tree records (6 per record)

function PRTEXM(input::Integer, iprint::Integer, ititle::AbstractString)
    if input == 0 || iprint == 0; return nothing; end

    io_in  = get(io_units, Int32(input),  nothing)
    io_out = get(io_units, Int32(iprint), stdout)
    if io_in === nothing || !isopen(io_in); return nothing; end
    seekstart(io_in)

    ifrac = Int32[10, 30, 50, 70, 90, 100]
    is    = false   # sample trees reselected flag

    # Read first record: stand identifier (type=0)
    buf = read(io_in, 4 + 26 + 4)   # IRT(Int32) + NPLT(26 chars) + MGTID(4 chars)
    if length(buf) < 34; return nothing; end
    irt  = reinterpret(Int32, buf[1:4])[1]
    nplt = String(buf[5:30])
    mgtid= String(buf[31:34])
    if irt != 0
        ERRGRO(false, Int32(19)); rtncd = Ref(Int32(0)); fvsGetRtnCode(rtncd)
        if rtncd[] != 0; return nothing; end
    end

    GHEADS(nplt, mgtid, Int32(0), Int32(iprint), ititle)
    @goto label_125

    @label label_90
    # Read type-1 or type-2 stand attribute record: IRT + I1 + A5(5)
    buf2 = read(io_in, 4 + 4 + 20)   # IRT + I1 + 5*Float32
    if length(buf2) < 28; @goto label_155; end
    irt = reinterpret(Int32, buf2[1:4])[1]
    i1  = reinterpret(Int32, buf2[5:8])[1]
    a5  = reinterpret(Float32, buf2[9:28])
    if irt != 1 && irt != 2
        ERRGRO(false, Int32(19)); rtncd = Ref(Int32(0)); fvsGetRtnCode(rtncd)
        if rtncd[] != 0; return nothing; end
    end

    if VARACD ∈ ("CS","LS","NE","ON")
        @printf(io_out, "%73s%3d%6s%4.1f%4s%6.0f%4s%5.0f%6s%5.1f\n",
            "", i1, "", a5[1], "", a5[2], "", a5[3], "", a5[4])
        if irt == 1; @goto label_125; end
        buf3 = read(io_in, 4 + 20)
        if length(buf3) < 24; @goto label_155; end
        irt = reinterpret(Int32, buf3[1:4])[1]
        a5r = reinterpret(Float32, buf3[5:24])
        if irt != 3
            ERRGRO(false, Int32(19)); rtncd = Ref(Int32(0)); fvsGetRtnCode(rtncd)
            if rtncd[] != 0; return nothing; end
        end
        @printf(io_out, "%69sRESIDUAL:%4s%4.1f%4s%6.0f%4s%5.0f%6s%5.1f\n",
            "", "", a5r[1], "", a5r[2], "", a5r[3], "", a5r[4])
    else
        @printf(io_out, "%73s%3d%6s%4.1f%4s%6.0f%4s%5.0f%6s%5.1f%3s%6.1f\n",
            "", i1, "", a5[1], "", a5[2], "", a5[3], "", a5[4], "", a5[5])
        if irt == 1; @goto label_125; end
        buf3 = read(io_in, 4 + 20)
        if length(buf3) < 24; @goto label_155; end
        irt = reinterpret(Int32, buf3[1:4])[1]
        a5r = reinterpret(Float32, buf3[5:24])
        if irt != 3
            ERRGRO(false, Int32(19)); rtncd = Ref(Int32(0)); fvsGetRtnCode(rtncd)
            if rtncd[] != 0; return nothing; end
        end
        @printf(io_out, "%69sRESIDUAL:%4s%4.1f%4s%6.0f%4s%5.0f%6s%5.1f%3s%6.1f\n",
            "", "", a5r[1], "", a5r[2], "", a5r[3], "", a5r[4], "", a5r[5])
    end

    @label label_125
    # Read type-4 year+period record: IRT + I2(2)
    buf4 = read(io_in, 4 + 8)
    if length(buf4) < 12; @goto label_165; end
    irt = reinterpret(Int32, buf4[1:4])[1]
    i2  = reinterpret(Int32, buf4[5:12])
    if irt != 4
        ERRGRO(false, Int32(19)); rtncd = Ref(Int32(0)); fvsGetRtnCode(rtncd)
        if rtncd[] != 0; return nothing; end
    end

    if i2[1] < 0
        i2v = [-i2[1], i2[2]]
        is  = true
        @printf(io_out, "\n%4d **%39s(%3d YRS)\n\n", i2v[1], "", i2v[2])
    else
        @printf(io_out, "\n%4d%42s(%3d YRS)\n\n", i2[1], "", i2[2])
    end

    # Read type-5 example-tree record
    # 6 species codes (CHARACTER*3), 6 DBHs, 6 HTs, 6 ICRs, 6 DGs, 6 PCTs, 6 PRBs
    buf5 = read(io_in, 4 + 18 + 6*4 + 6*4 + 6*4 + 6*4 + 6*4 + 6*4)
    if length(buf5) < 4 + 18 + 120; @goto label_155; end
    irt    = reinterpret(Int32, buf5[1:4])[1]
    ionsp  = [String(buf5[5+3*(j-1):7+3*(j-1)]) for j in 1:6]
    off    = 4 + 18
    dbhio  = reinterpret(Float32, buf5[off+1:off+24]);  off += 24
    htio   = reinterpret(Float32, buf5[off+1:off+24]);  off += 24
    ioicr  = reinterpret(Int32,   buf5[off+1:off+24]);  off += 24
    dgio   = reinterpret(Float32, buf5[off+1:off+24]);  off += 24
    pctio  = reinterpret(Float32, buf5[off+1:off+24]);  off += 24
    prbio  = reinterpret(Float32, buf5[off+1:off+24])
    if irt != 5
        ERRGRO(false, Int32(19)); rtncd = Ref(Int32(0)); fvsGetRtnCode(rtncd)
        if rtncd[] != 0; return nothing; end
    end

    for j in 1:6
        @printf(io_out, "%7s%3d%5s%3s%5s%6.2f%3s%6.2f%3s%3d%3s%6.2f%4s%5.1f%1s%7.2f\n",
            "", ifrac[j], "", ionsp[j], "", dbhio[j], "", htio[j],
            "", ioicr[j], "", dgio[j], "", pctio[j], "", prbio[j])
    end
    @goto label_90

    @label label_155
    ERRGRO(false, Int32(19))
    rtncd = Ref(Int32(0)); fvsGetRtnCode(rtncd)
    if rtncd[] != 0; return nothing; end

    @label label_160
    ERRGRO(true, Int32(20))

    @label label_165
    seekstart(io_in)
    if is
        @printf(io_out, "\n** NOTE:  DUE TO HARVEST, COMPRESSION, OR REGENERATION ESTABLISHMENT, NEW SAMPLE TREES WERE SELECTED.\n")
    end
    return nothing
end
