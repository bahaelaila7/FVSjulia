# fmssum.f — Snag summary report at FVS cycle boundaries
# FMSSUM: accumulates hard/soft snag TPA by 6 DBH-threshold classes + total
# SNPRCL(1:6) = DBH breakpoints for snag reporting classes
# Called from: FMMAIN

function FMSSUM(iyr::Integer)
    if ISNGSM == -1 || iyr != IFMYR1; return nothing; end

    local thd = zeros(Float32, 7)
    local tsf = zeros(Float32, 7)

    for ii in 1:Int(NSNAG)
        tsf[7] += DENIS[ii]
        if HARD[ii]
            thd[7] += DENIH[ii]
        else
            tsf[7] += DENIH[ii]
        end
        for i in 1:6
            if DBHS[ii] >= SNPRCL[i]
                tsf[i] += DENIS[ii]
                if HARD[ii]
                    thd[i] += DENIH[ii]
                else
                    tsf[i] += DENIH[ii]
                end
            end
        end
    end
    local thdsf::Float32 = thd[7] + tsf[7]

    local dbskode_ref = Ref(Int32(1))
    DBSFMSSNAG(iyr, NPLT,
               thd[1], thd[2], thd[3], thd[4], thd[5], thd[6], thd[7],
               tsf[1], tsf[2], tsf[3], tsf[4], tsf[5], tsf[6], tsf[7],
               thdsf, dbskode_ref[])
    if dbskode_ref[] == 0; return nothing; end

    local jout_ref = Ref(Int32(0))
    GETLUN(jout_ref)
    local jout::Int32 = jout_ref[]
    local jout_io = get(io_units, jout, stdout)

    if ISNGSM == 0
        local id_ref = Ref(Int32(0))
        GETID(id_ref)
        global ISNGSM = id_ref[]
        local s6 = [Int(SNPRCL[i]) for i in 1:6]
        @printf(jout_io, "\n%6d \$#*%%\n\n%s\n", ISNGSM, "-"^114)
        @printf(jout_io, "%42s\n", "******  FIRE MODEL VERSION 1.0 ******")
        @printf(jout_io, "%s SNAG SUMMARY REPORT (BASED ON STOCKABLE AREA) %s\n",
                "-"^46, "-"^21)
        @printf(jout_io, " STAND ID: %-26s    MGMT ID: %s\n", NPLT, MGMID)
        @printf(jout_io, "%s HARD SNAGS/ACRE %s  %s SOFT SNAGS/ACRE %s   GRAND\n",
                "-"^7, "-"^15, " ", "-"^7)
        @printf(jout_io, "YEAR  ")
        for _ in 1:2; for i in 1:6; @printf(jout_io, " >=%2d\" ", s6[i]); end; @printf(jout_io, " TOTAL "); end
        println(jout_io)
        @printf(jout_io, "---- ")
        for _ in 1:2; for i in 1:7; @printf(jout_io, " ------"); end; end
        println(jout_io, "  ------")
        @printf(jout_io, "%s\$#*%%\n", " "^1)
    end

    @printf(jout_io, " %5d %4d ", ISNGSM, iyr)
    for i in 1:7; @printf(jout_io, " %6.1f", thd[i]); end
    for i in 1:7; @printf(jout_io, " %6.1f", tsf[i]); end
    @printf(jout_io, "  %6.1f\n", thdsf)
    return nothing
end
