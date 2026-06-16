# base/dbscan.f — DBSCAN: search SUBNAM debug stack for name+cycle match
# Translated from: bin/FVSsn_buildDir/dbscan.f (40 lines)
#
# Searches the packed SUBNAM buffer for an entry matching:
#   SUBIN[1..NC] + ' ' + <2-digit ICYC> + ' '
# Also searches for the same name with cycle 0 (matches any cycle).
# Sets LDEBG=true if found.

function DBSCAN(ldebg::Ref{Bool}, subin::AbstractString, nc::Int32, icyc::Int32)
    ldebg[] = false
    if nc > Int32(0) && nc <= MAXLEN && ITOP > Int32(0)
        # Build CHECK bytes: name + ' ' + 2-digit-cycle + ' '  (NC+4 bytes)
        n = Int(nc)
        chk = fill(UInt8(' '), n + 4)
        for i in 1:n
            chk[i] = UInt8(subin[i])
        end
        # chk[n+1] = ' '  (already filled)
        cyc_s = CH2NUM(icyc)
        chk[n+2] = UInt8(cyc_s[1])          # IS
        chk[n+3] = UInt8(cyc_s[2])          # IE
        # chk[n+4] = ' '  (terminal, already filled)
        ie = n + 4

        subnam_str = String(copy(SUBNAM))    # view as string for substring search
        check_str  = String(chk[1:ie])

        # Check for exact ICYC match
        ip = findfirst(check_str, subnam_str)

        # Also check for cycle-0 match (any-cycle entry)
        cyc0 = CH2NUM(0)
        chk[n+2] = UInt8(cyc0[1])
        chk[n+3] = UInt8(cyc0[2])
        check0 = String(chk[1:ie])
        iq = findfirst(check0, subnam_str)

        if ip !== nothing || iq !== nothing
            ldebg[] = true
        end
    end
    return nothing
end
