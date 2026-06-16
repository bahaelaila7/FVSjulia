# base/dbprse.f — DBPRSE: parse debug specification from a keyword continuation record
# Translated from: bin/FVSsn_buildDir/dbprse.f (63 lines)
#
# Reads lines from io_units[iread], parses space-delimited subroutine names,
# and adds each to the debug stack via DBADD.
# Returns IRC: 0=OK, 1=EOF/error, 2=stack full.

function DBPRSE(iread::Int32, record_in::AbstractString, jout::Int32, icyc::Int32)::Int32
    irc = Int32(0)
    io_in  = io_units[iread]
    io_out = io_units[jout]

    # outer loop: read continuation lines
    while true
        local_record = ""
        try
            local_record = readline(io_in)
        catch
            return Int32(1)
        end
        if eof(io_in) && isempty(local_record)
            return Int32(1)
        end
        record = local_record

        # echo at FORMAT T13 (12 spaces indent)
        nb = ISTLNB(record)
        @printf(io_out, "            %s\n", nb > 0 ? record[1:nb] : "")

        # find IE = last non-blank position
        ie = length(record)
        while ie > 1 && record[ie] == ' '
            ie -= 1
        end
        # if first char is blank and only 1 char, or all blank: nothing to parse
        if ie < 1 || (ie == 1 && record[1] == ' ')
            return irc
        end

        is = 0
        continuation = false

        # inner loop: parse space-separated tokens
        while true
            is += 1
            # skip leading blanks
            while is < ie && record[is] == ' '
                is += 1
            end

            ch = record[is]
            if ch == '&'
                continuation = true
                break
            end

            if ie < is
                return irc
            end

            # find end of token: next blank or end of trimmed record
            sub = record[is:ie]
            bp = findfirst(' ', sub)
            lp = bp !== nothing ? bp + is - 2 : ie

            nc = lp - is + 1
            iq = lp + 1

            if nc > Int(MAXLEN)
                lp = is + Int(MAXLEN) - 1
                nc = lp - is + 1
                iq = lp
            end

            token = uppercase(record[is:lp])
            irc_sub = Ref(Int32(0))
            DBADD(token, Int32(nc), icyc, irc_sub)
            irc = irc_sub[]
            if irc > Int32(0)
                return irc
            end

            is = iq
            if is >= ie
                return irc
            end
            # continue inner token loop
        end

        if !continuation
            break
        end
        # else: continuation character '&' → read next line (outer loop)
    end

    return irc
end
