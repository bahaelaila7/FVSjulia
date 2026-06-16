# extensions/fire/fmsvsync.jl — FMSVSYNC: sync fire-model snag counts with SVS objects
# Translated from fire/fmsvsync.f (127 lines)
# Compares fire-model snag densities vs standing SVS snag objects; debug diff printout.

function FMSVSYNC()
    debug = DBCHK(false, "FMSVSYNC", Int32(8), ICYC)
    debug && @printf(io_units[JOSTND], " IN FMSVSYNC, JSVOUT=%4d\n", JSVOUT)

    JSVOUT == Int32(0) && return

    curfmsn = zeros(Float32, 19, MAXSP)
    cursvsn  = zeros(Int32,   19, MAXSP)
    fmtotal  = 0f0
    svtotal  = 0

    for i in 1:Int(NSNAG)
        dbhcl = Int(DBHS[i] / 2f0 + 1f0)
        dbhcl > 19 && (dbhcl = 19)
        curfmsn[dbhcl, SPS[i]] += DENIS[i] + DENIH[i]
        dbhcl >= 2 && (fmtotal += DENIS[i] + DENIH[i])
    end

    for i in 1:Int(NSVOBJ)
        IOBJTP[i] != 2 && continue
        FALLDIR[IS2F[i]] != -1 && continue
        dbhcl = Int(ODIA[IS2F[i]] / 2f0 + 1f0)
        dbhcl > 19 && (dbhcl = 19)
        cursvsn[dbhcl, ISNSP[IS2F[i]]] += 1
        dbhcl >= 2 && (svtotal += 1)
    end

    if debug
        for s in 1:MAXSP, d in 2:19
            if curfmsn[d,s] + cursvsn[d,s] > 0f0
                @printf(io_units[JOSTND], " Species=%d DBHClass=%3d CURFM=%8.3f CURSVSN=%4d\n",
                        s, d, curfmsn[d,s], cursvsn[d,s])
            end
        end
        @printf(io_units[JOSTND], " TOTAL DIFF=%10.3f\n", Float32(svtotal) - fmtotal)
    end
    return
end
