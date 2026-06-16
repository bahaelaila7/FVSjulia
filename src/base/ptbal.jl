# base/ptbal.jl — PTBAL: compute point basal area in larger trees
# Translated from: bin/FVSsn_buildDir/ptbal.f (174 lines)
#
# For each sample point, fills PTBALT[i] = BA of trees larger than tree i
# within the same point, and PTBAA[ip] = total point BA estimate.
# Called from DENSE after WK5[i] = DBH[i]² * PROB[i] has been loaded.
#
# The Fortran uses EQUIVALENCE(WK6, IPNDX) to share memory; we use a
# local Int32 array instead.

function PTBAL()
    debug = DBCHK("PTBAL", Int32(5))
    io    = get(io_units, Int(JOSTND), stdout)

    if debug
        @printf(io, " ENTERING SUBROUTINE PTBAL CYCLE=%5d; ITRN=%5d; VARACD=%s\n",
                ICYC, ITRN, VARACD)
    end

    if VARACD in ("CS","LS","NE","ON")
        fill!(PTBALT, Float32(0)); fill!(PTBAA, Float32(0))
        if debug
            @printf(io, " EASTERN TWIGS VARIANT, PBA VALUES ZERO, LEAVING PTBAL\n")
        end
        return nothing
    end

    # Western/Southern variant
    if ITRN <= Int32(0)
        fill!(PTBALT, Float32(0)); fill!(PTBAA, Float32(0))
        if debug
            @printf(io, " WESTERN/SOUTHERN VARIANT, NO TREES, PBA VALUES ZERO, LEAVING PTBAL\n")
        end
        return nothing
    end

    # Find maximum ITRE value = actual point count NP
    np = -1
    for i in 1:Int(ITRN)
        ii = Int(IND[i])
        if ITRE[ii] > np; np = Int(ITRE[ii]); end
    end

    if debug
        @printf(io, " ENTERING SUBROUTINE PTBAL NP=%4d; IREC2=%5d; PI=%6.1f; GROSPC=%8.3f\n",
                np, IREC2, PI, GROSPC)
    end

    # Local index array (replaces Fortran EQUIVALENCE(WK6,IPNDX))
    ipndx = zeros(Int32, Int(MAXPLT))

    if np > 1
        for ip in 1:np
            ipndx[ip] = Int32(0)
        end
        for i in 1:Int(ITRN)
            ii = Int(IND[i])
            ip = Int(ITRE[ii])
            ipndx[ip] += Int32(1)
        end
        # Running cumulative (reserve room in IND2)
        for ip in 2:np
            ipndx[ip] += ipndx[ip-1]
        end
        # Build sorted pointer list (IND is sorted descending by DBH)
        for i in Int(ITRN):-1:1
            ii  = Int(IND[i])
            ip  = Int(ITRE[ii])
            IND2[ipndx[ip]] = Int32(ii)
            ipndx[ip] -= Int32(1)
        end
    else
        # Single point: copy IND → IND2
        for i in 1:Int(ITRN)
            IND2[i] = IND[i]
        end
        ipndx[1] = Int32(0)
    end

    # Compute BA in larger trees within each point
    for ip in 1:np
        n = if ip == np
            Int(ITRN) - Int(ipndx[ip])
        else
            Int(ipndx[ip+1]) - Int(ipndx[ip])
        end
        xbalt = Float32(0)
        for i in (Int(ipndx[ip])+1):(Int(ipndx[ip])+n)
            PTBALT[IND2[i]] = xbalt
            xbalt += WK5[Int(IND2[i])] * Float32(0.005454154) * Float32(PI) / GROSPC
        end
        PTBAA[ip] = xbalt
    end

    if debug
        for ii in 1:Int(ITRN)
            i = Int(IND2[ii])
            @printf(io, " IN PTBAL: I,ITRE,DBH,WK5,PTBALT,PROB,PTBAA=%5d%5d%10.3f%10.3f%10.3f%10.3f%10.3f\n",
                    i, ITRE[i], DBH[i], WK5[i], PTBALT[i], PROB[i], PTBAA[Int(ITRE[i])])
        end
        @printf(io, " WESTERN/SOUTHERN VARIANT, PBA VALUES SET, LEAVING PTBAL.\n")
    end

    return nothing
end
