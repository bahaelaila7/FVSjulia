# base/opmerg.jl — OPMERG: merge caller's activity list with current-cycle schedule
# Translated from: bin/FVSsn_buildDir/opmerg.f (88 lines)
#
# Fills IPTODO[1..NTODO] with pointers to activities in IOPCYC that match
# any code in MYACTS, then sorts by (date, sequence).

function OPMERG(nmya::Integer, myacts::AbstractVector{Int32}, ntodo_ref::Ref{Int32})
    ntodo = Int32(0)

    if IMG1 == Int32(0); ntodo_ref[] = ntodo; return; end
    if nmya == 0;        ntodo_ref[] = ntodo; return; end

    ipa = Int(IOPCYC[Int(IMG2)])
    if myacts[1] > IACT[ipa, 1]; ntodo_ref[] = ntodo; return; end
    ipa = Int(IOPCYC[Int(IMG1)])
    if myacts[nmya] < IACT[ipa, 1]; ntodo_ref[] = ntodo; return; end

    imya = 1
    my   = myacts[1]

    for ii in Int(IMG1):Int(IMG2)
        ipa = Int(IOPCYC[ii])
        if IACT[ipa, 4] != Int32(0); continue; end
        ia = IACT[ipa, 1]

        # inner: advance imya until my >= ia
        while true
            if my > ia; @goto next_sched; end
            if my == ia; @goto match; end
            # my < ia: advance imya
            imya += 1
            if imya > nmya; @goto done; end
            my = myacts[imya]
        end

        @label match
        ntodo += Int32(1)
        if ntodo > MXPTDO_OP
            ERRGRO(true, Int32(10))
            @printf(stderr,
                    "ISSUED IN OPMERG ADDING ACTIVITY EXCEEDS LIMIT\n")
            @goto done
        end
        IPTODO[Int(ntodo)] = Int32(ipa)
        @label next_sched
    end

    @label done
    if ntodo == Int32(0); ntodo_ref[] = ntodo; return; end
    OPSORT(ntodo, IDATE, ISEQ, IPTODO, false)
    ntodo_ref[] = ntodo
    return nothing
end
