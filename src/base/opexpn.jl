# base/opexpn.f — OPEXPN: expand all-cycle activities to per-cycle copies
# Translated from: bin/FVSsn_buildDir/opexpn.f (250 lines)
#
# Activities with IDATE<=0 are "all-cycle" placeholders.
# Duplicates them for each simulation cycle, then re-sorts.
# Modifies globals: IDATE, ISEQ, IOPSRT, IACT, PARMS, IMPL, IMGL, ISEQDN, NCYC.
#
# Control flow note: avoids @goto-into-loops by using break+flag pattern for
# overflow detection (mirrors Fortran GOTO 200 / GOTO 300).

function OPEXPN(iout::Int32, _ncyc_param::Int32, iy::AbstractVector{Int32})
    img2 = Int(IMGL) - 1
    if img2 <= 0; return nothing; end

    # STEP01: convert cycle-number dates → actual years; set ISEQ[i]=i; sort.
    for i in 1:img2
        iy1 = Int(IDATE[i])
        if iy1 <= Int(MAXCYC) && iy1 > 0
            if Int(iy[iy1]) > 0; iy1 = Int(iy[iy1]); end
        end
        IDATE[i] = Int32(iy1)
        ISEQ[i]  = Int32(i)
    end
    global ISEQDN = Int32(IMGL)
    OPSORT(Int32(img2), IDATE, ISEQ, IOPSRT, true)

    # STEP02: find IPSYR = first sorted index with IDATE > 0.
    ipsyr = 0; isyr = 0
    for i in 1:img2
        ig = Int(IOPSRT[i])
        if Int(IDATE[ig]) <= 0; continue; end
        ipsyr = i
        isyr  = Int(IDATE[ig])
        break
    end

    if ipsyr == 1; return nothing; end   # no all-cycle activities

    # After this point we may need to run STEP05+STEP06 (label_300).
    # img3 tracks the last written activity slot; ipsyr_saved for STEP05.
    img3      = img2
    ipsyr_saved = ipsyr   # 0 or >1 — needed in STEP05 loop
    overflow  = false
    ic_overflow = 0       # cycle number at which overflow occurred

    if ipsyr == 0
        # ─────────────────────────────────────────────────────────────────────
        # ALL activities are all-cycle.
        # ─────────────────────────────────────────────────────────────────────
        isyr = Int(iy[1])
        for i in 1:img2; IDATE[i] = Int32(isyr); end
        if Int(NCYC) == 1; return nothing; end   # IMGL already correct

        ic_max = div(Int(MAXACT), img2)
        if ic_max < Int(NCYC)
            @printf(io_units[iout],
                "\n%3d CYCLES REQUESTED, %3d CYCLES POSSIBLE.  PROJECTION WILL END IN %4d\n",
                NCYC, ic_max, iy[ic_max + 1])
            ERRGRO(true, Int32(10))
            @printf(io_units[iout],
                " ISSUED IN OPEXPN: IC, NCYC, MAXACT, IMG2 = %d %d %d %d\n",
                ic_max, NCYC, MAXACT, img2)
            global NCYC = Int32(ic_max)
        end

        for ic2 in 2:Int(NCYC)
            isyr2 = Int(iy[ic2])
            j_base = (ic2 - 1) * img2
            for ip in 1:img2
                img3_new = j_base + ip
                IDATE[img3_new]  = Int32(isyr2)
                ISEQ[img3_new]   = Int32(img3_new)
                IOPSRT[img3_new] = Int32(img3_new)
                for k in 1:5; IACT[img3_new, k] = IACT[ip, k]; end
                img3 = img3_new
                if Int(IACT[img3_new, 2]) <= 0; continue; end
                for i in Int(IACT[img3_new, 2]):Int(IACT[img3_new, 3])
                    PARMS[IMPL] = PARMS[i]
                    global IMPL += Int32(1)
                    if Int(IMPL) > Int(ITOPRM)
                        ic_overflow = ic2; overflow = true; break
                    end
                end
                if overflow; break; end
                IACT[img3_new, 2] = Int32(Int(IMPL) - (Int(IACT[img3_new,3]) - Int(IACT[img3_new,2]) + 1))
                IACT[img3_new, 3] = Int32(Int(IMPL) - 1)
            end
            if overflow; break; end
        end

        if !overflow
            global IMGL = Int32(img3 + 1)
            return nothing
        end
        # overflow: fall through to STEP05/STEP06 with ipsyr_saved=0
    else
        # ─────────────────────────────────────────────────────────────────────
        # IPSYR > 1: mix of all-cycle + dated activities.  STEP03/STEP04.
        # ─────────────────────────────────────────────────────────────────────
        img1  = ipsyr
        ipsyr_saved = ipsyr - 1   # number of all-cycle entries to copy
        k_ptr = img1              # pointer into sorted list

        for ic in 1:Int(NCYC)
            iy1_c = Int(iy[ic])
            iy2_c = Int(iy[ic + 1])
            ip1   = 0

            # find cycle boundary in sorted list
            for ip in k_ptr:img2
                ips = Int(IOPSRT[ip])
                ipy = Int(IDATE[ips])
                if !(ipy < iy1_c || ipy >= iy2_c)
                    if ip1 == 0; ip1 = ip; end
                end
                if ipy < iy2_c; continue; end
                k_ptr = ip
                break
            end

            # copy all-cycle activities for this cycle
            for i in 1:ipsyr_saved
                j_src = Int(IOPSRT[i])
                img3 += 1
                if img3 > Int(MAXACT); ic_overflow = ic; overflow = true; break; end
                IDATE[img3]  = Int32(iy1_c)
                ISEQ[img3]   = Int32(img3)
                IOPSRT[img3] = Int32(img3)
                for l in 1:5; IACT[img3, l] = IACT[j_src, l]; end
                if Int(IACT[img3, 2]) <= 0; continue; end
                for ip in Int(IACT[img3, 2]):Int(IACT[img3, 3])
                    PARMS[IMPL] = PARMS[ip]
                    global IMPL += Int32(1)
                    if Int(IMPL) > Int(ITOPRM)
                        ic_overflow = ic; overflow = true; break
                    end
                end
                if overflow; break; end
                IACT[img3, 2] = Int32(Int(IMPL) - (Int(IACT[img3,3]) - Int(IACT[img3,2]) + 1))
                IACT[img3, 3] = Int32(Int(IMPL) - 1)
            end
            if overflow; break; end
        end
    end

    # ─────────────────────────────────────────────────────────────────────────
    # Overflow handler (Fortran label_200): back up to last complete cycle.
    # ─────────────────────────────────────────────────────────────────────────
    if overflow
        ic_done = ic_overflow - 1
        img3   -= 1
        @printf(io_units[iout],
            "\n%3d CYCLES REQUESTED, %3d CYCLES POSSIBLE.  PROJECTION WILL END IN %4d\n",
            NCYC, ic_done, iy[ic_done + 1])
        ERRGRO(true, Int32(10))
        @printf(io_units[iout],
            " ISSUED IN OPEXPN: IMG3 %d HAS EXCEEDED MAXACT %d OR IMPL %d HAS EXCEEDED ITOPRM %d\n",
            img3, MAXACT, IMPL, ITOPRM)
        global NCYC = Int32(ic_done)
    end

    # ─────────────────────────────────────────────────────────────────────────
    # STEP05 (Fortran label_300): overwrite all-cycle slots with entries from
    # the bottom of the expanded list (so no duplicate all-cycle placeholders).
    # ─────────────────────────────────────────────────────────────────────────
    img2_final = img3
    global ISEQDN = Int32(img2_final + 1)
    for j in 1:ipsyr_saved
        i_src = Int(IOPSRT[j])
        for k in 1:5; IACT[i_src, k] = IACT[img2_final, k]; end
        IDATE[i_src] = IDATE[img2_final]
        ISEQ[i_src]  = ISEQ[img2_final]
        img2_final  -= 1
    end

    # STEP06: re-sort.
    OPSORT(Int32(img2_final), IDATE, ISEQ, IOPSRT, false)
    global IMGL = Int32(img2_final + 1)
    return nothing
end
