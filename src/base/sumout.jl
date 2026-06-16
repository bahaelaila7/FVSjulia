# sumout.jl — SUMOUT: write stand summary statistics table
# Translated from: sumout.f (233 lines, vbase)
#
# Writes one row per simulation period into:
#   jstnd2 (formatted "printed" copy with headings)
#   jsum2  (machine-readable copy, no headings)
#
# IOSUM layout (columns):
#  1=year 2=age 3=TPA 4=total cuft 5=merch cuft 6=merch bdft
#  7=removed TPA 8=removed total cuft 9=removed merch cuft 10=removed merch bdft
#  11=AT BA 12=AT CCF 13=AT avg dom HT 14=period length 15=accretion 16=mortality
#  17=sample wt 18=forest type 19=size class 20=stocking class
#  21=cubic saw volume 22=removed cubic saw volume

const _SUMOUT_ROW_FMT = Printf.Format(
    "%4d%4d%6d%4d%5d%4d%4d%5.1f" *
    "%6d%6d%6d%6d%6d%6d%6d%6d%6d" *
    "%4d%5d%4d%4d%5.1f  %6d%5d%6d  %6.1f %3d %1d%1d\n"
)

function SUMOUT(iosum::AbstractMatrix{Int32}, i20::Integer, icallf::Integer,
                joprt::Integer, jstnd2::Integer, jsum2::Integer,
                leng::Integer, mgmid::AbstractString, nplt::AbstractString,
                samwt::Real, ititle::AbstractString, iptinv::Integer)

    lprt = jstnd2 > 0
    ldsk = jsum2  > 0
    if !(lprt || ldsk); return nothing; end

    rev_ref = Ref("          ")
    REVISE(VARACD, rev_ref)
    rev = rev_ref[]

    dat_r = Ref("          ")
    tim_r = Ref("        ")
    GRDTIM(dat_r, tim_r)
    dat = dat_r[]; tim = tim_r[]

    cisn = "           "   # legacy PPE field, kept blank

    if ldsk
        io_jsum = get(io_units, Int32(jsum2), nothing)
        if io_jsum === nothing || !isopen(io_jsum)
            # Try to open a .sum file next to the keyword file
            kwdfil = "FVSout.sum"
            io_jsum = open(kwdfil, "w")
            io_units[Int32(jsum2)] = io_jsum
        end
        @printf(io_jsum, "-999%5d %-26s %-4s%15.7E %-2s %-10s %-8s %-10s %-11s%3d\n",
            leng, nplt, mgmid, Float32(samwt), VARACD, dat, tim, rev, cisn, iptinv)
    end

    if lprt
        io_j = get(io_units, Int32(jstnd2), stdout)
        @printf(io_j, "\nSTAND ID: %-26s    MGMT ID: %-4s    %s\n\n",
            nplt, mgmid, strip(ititle))

        @printf(io_j, "%s\n", repeat(" ", 41) * "SUMMARY STATISTICS (PER ACRE OR STAND BASED ON TOTAL STAND AREA)")
        @printf(io_j, "%s\n", repeat("-", 146))
        @printf(io_j, "%22s%s%29s%15s%23s%5s%3s%19s\n",
            "START OF SIMULATION PERIOD", repeat(" ",23),
            "REMOVALS", repeat(" ",15), "AFTER TREATMENT",
            repeat(" ",5), "GROWTH THIS PERIOD", "")
        @printf(io_j, "%9s%s%1s%s%1s%s%3s%s\n",
            "NO OF", repeat(" ",14), "TOP", repeat(" ",6),
            "TOTAL MERCH SAWLG MERCH NO OF TOTAL MERCH SAWLG MERCH",
            repeat(" ",14), "TOP  RES  PERIOD ACCRE MORT   MERCH FOR SS", "")
        @printf(io_j, "%s\n",
            "YEAR AGE TREES  BA  SDI CCF HT  QMD  CU FT CU FT CU FT BD FT TREES " *
            "CU FT CU FT CU FT BD FT  BA  SDI CCF HT   QMD  YEARS   PER  YEAR   CU FT TYP ZT")
        @printf(io_j, "%s\n",
            "---- --- ----- --- ---- --- --- ---- " *
            join(fill("-----", 9), " ") * " " *
            "--- ---- --- --- ----   ------ ---- -----   ----- ------")
    end

    i12 = Int(i20) - 8
    for ii in 1:Int(leng)
        # Extract row
        yr_v   = Int(iosum[1, ii])
        age_v  = Int(iosum[2, ii])
        tpa_v  = Int(iosum[3, ii])
        ba_bt  = Int(IOLDBA[ii])
        sdi_bt = Int(ISDI_S[ii])
        ccf_bt = Int(IBTCCF[ii])
        avh_bt = Int(IBTAVH[ii])
        qmd_bt = QSDBT[ii]
        cuft4  = Int(iosum[4, ii])
        cuft5  = Int(iosum[5, ii])
        cusaw21= Int(iosum[21, ii])
        cuft6  = Int(iosum[6, ii])
        tpa7   = Int(iosum[7, ii])
        cuft8  = Int(iosum[8, ii])
        cuft9  = Int(iosum[9, ii])
        cusaw22= Int(iosum[22, ii])
        cuft10 = Int(iosum[10, ii])
        ba11   = Int(iosum[11, ii])
        sdi12  = Int(ISDIAT[ii])
        ccf12  = Int(iosum[12, ii])
        avh13  = Int(iosum[13, ii])
        qmd_at = QDBHAT[ii]
        plen14 = Int(iosum[14, ii])
        acc15  = Int(iosum[15, ii])
        mor16  = Int(iosum[16, ii])
        mai    = BCYMAI[ii]
        ft18   = Int(iosum[18, ii])
        sz19   = Int(iosum[19, ii])
        st20   = Int(iosum[20, ii])

        if lprt
            io_j = get(io_units, Int32(jstnd2), stdout)
            Printf.format(io_j, _SUMOUT_ROW_FMT,
                yr_v, age_v, tpa_v, ba_bt, sdi_bt, ccf_bt, avh_bt, qmd_bt,
                cuft4, cuft5, cusaw21, cuft6, tpa7, cuft8, cuft9, cusaw22, cuft10,
                ba11, sdi12, ccf12, avh13, qmd_at,
                plen14, acc15, mor16, mai, ft18, sz19, st20)
        end
        if ldsk
            io_jsum = io_units[Int32(jsum2)]
            Printf.format(io_jsum, _SUMOUT_ROW_FMT,
                yr_v, age_v, tpa_v, ba_bt, sdi_bt, ccf_bt, avh_bt, qmd_bt,
                cuft4, cuft5, cusaw21, cuft6, tpa7, cuft8, cuft9, cusaw22, cuft10,
                ba11, sdi12, ccf12, avh13, qmd_at,
                plen14, acc15, mor16, mai, ft18, sz19, st20)
        end

        if icallf == 0
            DBSSUMRY(iosum[1,ii], iosum[2,ii], nplt,
                iosum[3,ii], IOLDBA[ii], ISDI_S[ii], IBTCCF[ii], IBTAVH[ii], QSDBT[ii],
                iosum[4,ii], iosum[5,ii], iosum[21,ii],
                iosum[6,ii], iosum[7,ii], iosum[8,ii], iosum[9,ii],
                iosum[22,ii], iosum[10,ii],
                iosum[11,ii], ISDIAT[ii], iosum[12,ii], iosum[13,ii], QDBHAT[ii],
                iosum[14,ii], iosum[15,ii], iosum[16,ii], BCYMAI[ii],
                iosum[18,ii], iosum[19,ii], iosum[20,ii])
        end
    end

    if !ldsk; return nothing; end
    io_joprt = get(io_units, Int32(joprt), stdout)
    @printf(io_joprt, "\nNOTE:%3d LINES OF SUMMARY DATA HAVE BEEN WRITTEN TO THE FILE REFERENCED BY LOGICAL UNIT%3d\n",
        leng, jsum2)
    return nothing
end
