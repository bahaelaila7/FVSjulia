# keywd.jl — Keyword file reader and related utilities
# Translated from: keyrdr.f, fndkey.f, keyopn.f, keydmp.f

# ---------------------------------------------------------------------------
# COMMON /CKEYFN/ CKEYFN — keyword file name for output header
# ---------------------------------------------------------------------------
CKEYFN::String = repeat(' ', 110)   # CHARACTER*110

"""
    KEYRDR(inunit, iout, ldebug, array, irecnt, kode, kard, lflag, lkecho)
    → (keywrd, lnotbk, array, irecnt, kode, kard, lflag)

Read one keyword record from IO unit `inunit`.

Returns:
- `keywrd`  : 8-char keyword string (uppercased)
- `lnotbk`  : 12-element Bool vector, true if field is non-blank
- `array`   : 12-element Float32 vector of parsed numeric parameters
- `irecnt`  : updated record counter
- `kode`    :  0 = OK;  1 = blank/bad char;  2 = EOF;  3 = STOP
               <0 = PARMS statement starting at field abs(kode)
- `kard`    : 12-element Vector{String} of raw 10-char fields
- `lflag`   : updated heading-needed flag

ENTRY KEYFN(cfn): store keyword file name in CKEYFN.
"""
function KEYRDR(inunit::Int32, iout::Int32, ldebug::Bool,
                lnotbk::Vector{Bool}, array::Vector{Float32},
                irecnt_in::Int32, kode_in::Int32, kard::Vector{String},
                lflag_in::Bool, lkecho::Bool)
    irecnt = irecnt_in
    kode   = kode_in
    lflag  = lflag_in

    lcom = false
    keywrd = "        "

    @label label_5
    # Read one record
    record = ""
    try
        record = readline(io_units[inunit])
    catch
        kode = Int32(2)
        return keywrd, lnotbk, array, irecnt, kode, kard, lflag
    end
    # EOF detection: readline returns "" on EOF in Julia
    # Actually, it returns "" if the file is exhausted without a newline — use eof check
    if eof(io_units[inunit]) && isempty(record)
        kode = Int32(2)
        return keywrd, lnotbk, array, irecnt, kode, kard, lflag
    end
    irecnt += Int32(1)

    # Skip comment lines starting with '!'
    if !isempty(record) && record[1] == '!'
        @goto label_5
    end

    # Skip blank lines if heading has not yet been printed
    if lflag && strip(record) == ""
        @goto label_5
    end

    # Check for STOP keyword
    tmp = rpad(uppercase(length(record) >= 8 ? record[1:8] : record), 8)
    if tmp[1:4] == "STOP"
        if !lflag
            @printf(io_units[iout], "\n STOP\n")
        end
        kode = Int32(3)
        return keywrd, lnotbk, array, irecnt, kode, kard, lflag
    end

    # Print heading if needed
    if lflag
        GROHED(iout)
        cfn_trimmed = rstrip(CKEYFN)
        @printf(io_units[iout],
            "\n%s\n\n%49sOPTIONS SELECTED BY INPUT\n\nKEYWORD FILE NAME: %s\n%s\nKEYWORD    PARAMETERS:\n%s\n",
            repeat('-', 130),
            "", cfn_trimmed,
            repeat('-', 130),
            "--------   -----------------------------------------------------------------------------------------------------------------------")
        lflag = false
    end

    # Print comment / blank records
    if !isempty(record) && (record[1] == '*' || strip(record) == "")
        if !lcom
            @printf(io_units[iout], "\n\n")
            lcom = true
        end
        last_nb = ISTLNB(record)
        @printf(io_units[iout], "            %s\n",
            last_nb > 0 ? record[1:last_nb] : "")
        @goto label_5
    else
        lcom = false
    end

    # COMMENT keyword: echo until END
    if tmp[1:7] == "COMMENT"
        if lkecho
            @printf(io_units[iout], "\n%s\n", tmp)
        end
        @label label_14
        record2 = ""
        try
            record2 = readline(io_units[inunit])
        catch
            kode = Int32(2)
            return keywrd, lnotbk, array, irecnt, kode, kard, lflag
        end
        irecnt += Int32(1)
        tmp2 = rpad(length(record2) >= 4 ? record2[1:4] : record2, 4)
        tmp2u = uppercase(tmp2)
        if tmp2u[1:4] == "END "
            if lkecho
                @printf(io_units[iout], "\n%s\n", tmp2[1:4])
            end
            @goto label_5
        else
            if lkecho
                last_nb2 = ISTLNB(record2)
                @printf(io_units[iout], "            %s\n",
                    last_nb2 > 0 ? record2[1:last_nb2] : "")
            end
            @goto label_14
        end
    end

    # -----------------------------------------------------------------------
    # Scan for PARMS statement (a 'P' somewhere in columns 11-73)
    # -----------------------------------------------------------------------
    rec130 = rpad(record, 130)   # ensure length

    nf  = Int32(12)    # default: all 12 fields
    k   = 11
    found_parms = false
    while k <= 73
        # Search for P or p in rec130[k:73]
        search_range = rec130[k:min(73, length(rec130))]
        ip = findfirst(c -> c == 'P' || c == 'p', search_range)
        if ip !== nothing
            # Check if the 5 characters starting there are "PARMS"
            abs_pos = k + ip - 1
            if abs_pos + 4 <= length(rec130)
                candidate = uppercase(rec130[abs_pos:abs_pos+4])
                if candidate == "PARMS"
                    ip_field  = abs_pos - 11   # 0-based column offset after col 10
                    nf = Int32(div(ip_field, 10))
                    found_parms = true
                    break
                end
            end
            k = k + ip
        else
            break
        end
    end

    # -----------------------------------------------------------------------
    # Load keyword and decode 10-char parameter fields
    # -----------------------------------------------------------------------
    keywrd = rpad(length(rec130) >= 8 ? rec130[1:8] : rec130, 8)
    j = 1
    for fi in 1:nf
        j += 10
        col_end = min(j + 9, length(rec130))
        field   = (j <= length(rec130)) ? rpad(rec130[j:col_end], 10) : "          "
        kard[fi] = field

        # Parse numeric value from field (only if all chars are numeric/punctuation)
        array[fi] = Float32(0.0)
        valid = true
        for ch in field
            if isspace(ch); continue; end
            if !occursin(ch, " .+-eE0123456789")
                valid = false
                break
            end
        end
        if valid
            v = tryparse(Float32, strip(field))
            if v !== nothing
                array[fi] = v
            end
        end
    end

    keywrd = UPKEY(keywrd)
    kode = Int32(0)
    for fi in 1:nf
        lnotbk[fi] = strip(kard[fi]) != ""
    end

    if found_parms && nf < Int32(12)
        kode = -(nf + Int32(1))
        j2 = 1
        for fi in (nf+1):7
            lnotbk[fi] = false
            array[fi]  = Float32(0.0)
            j2 = fi * 10 + 1
            col_end = min(j2 + 9, length(rec130))
            kard[fi] = (j2 <= length(rec130)) ? rpad(rec130[j2:col_end], 10) : "          "
        end
    end

    if ldebug
        KEYDMP(iout, irecnt, keywrd, array, kard)
    end

    return keywrd, lnotbk, array, irecnt, kode, kard, lflag
end

"""
    KEYFN(cfn)

Store keyword file name in CKEYFN for output header (ENTRY point of KEYRDR).
"""
function KEYFN(cfn::AbstractString)
    global CKEYFN
    trimmed = rstrip(cfn)
    n = length(trimmed)
    maxlen = 110
    if n > maxlen
        CKEYFN = cfn[1:4] * "..." * cfn[n+8-maxlen:end]
    else
        CKEYFN = rpad(cfn, maxlen)
    end
    return nothing
end

"""
    FNDKEY(keywrd, table) → (number, kode)

Find `keywrd` in `table`. Returns `(position, 0)` on success, `(0, 1)` if not found.
Prints a message to JOSTND if not found.
"""
function FNDKEY(keywrd::AbstractString, table::AbstractVector{String},
                iout::Int32)::Tuple{Int32, Int32}
    for j in eachindex(table)
        if keywrd == table[j]
            return Int32(j), Int32(0)
        end
    end
    @printf(io_units[iout], "\n '%8s' :KEYWORD SPECIFIED\n", keywrd)
    return Int32(0), Int32(1)
end

# 7-arg Fortran-style FNDKEY: (number_r, keywrd, table, kwcnt, kode_r, lkecho, iout)
function FNDKEY(number_r::Ref{Int32}, keywrd::AbstractString,
                table::AbstractVector{String}, kwcnt::Integer,
                kode_r::Ref{Int32}, lkecho::Bool, iout::Integer)
    (num, kode) = FNDKEY(keywrd, table, Int32(iout))
    number_r[] = num
    kode_r[]   = kode
    return nothing
end

"""
    KEYOPN(iread, jostnd, irecnt, keywrd, array, kard)

Process the OPEN keyword. Reads the next record as a file name and opens
that file on the unit given by ARRAY(1).
"""
function KEYOPN(iread::Int32, jostnd::Int32, irecnt_in::Int32,
                keywrd::AbstractString, array::Vector{Float32},
                kard::Vector{String})
    irecnt = irecnt_in
    im_val = Int32(0)

    # Read filename record
    record = ""
    try
        record = readline(io_units[iread])
    catch
        ERRGRO(false, Int32(2))
        irtncd = fvsGetRtnCode()
        if irtncd != 0; return nothing; end
        return nothing
    end
    irecnt += Int32(1)

    if array[1] <= Float32(0.0)
        KEYDMP(jostnd, irecnt, keywrd, array, kard)
        ERRGRO(true, Int32(4))
        return nothing
    end

    iunit  = Int32(floor(array[1]))
    iznul  = Int32(0)
    cfour  = "ZERO"
    if array[2] != Float32(0.0)
        iznul = Int32(1)
        cfour = "NULL"
    end
    is_val = Int32(floor(array[3] + Float32(1.0)))
    if is_val <= Int32(0) || is_val > Int32(4)
        KEYDMP(jostnd, irecnt, keywrd, array, kard)
        ERRGRO(true, Int32(4))
        return nothing
    end

    cstat = ["UNKNOWN", "NEW", "OLD", "FRESH"][is_val]
    if is_val == Int32(4); is_val = Int32(5); end

    if array[4] > Float32(0.0); im_val = Int32(floor(array[4])); end
    iform = Int32(1)
    if array[5] > Float32(0.0); iform = Int32(2); end
    if iform == Int32(1) && im_val < Int32(150); im_val = Int32(150); end

    record_s, irlen = UNBLNK(record)

    # Check extension for .KCP / .ADD → force is=3 (OLD)
    extension = "   "
    for idx in irlen:-1:2
        if record_s[idx-1] == '.'
            ext_end = min(idx + 2, length(record_s))
            extension = uppercase(record_s[idx:ext_end])
            break
        end
    end
    if extension == "KCP" || extension == "ADD"
        is_val = Int32(3)
    end

    kode = MYOPEN(iunit, record_s, is_val, im_val, iznul, iform, Int32(1), Int32(0))

    @printf(io_units[jostnd],
        "\n%-8s   DATA SET REFERENCE NUMBER = %5d; BLANK=%4s; STATUS=%7s\n            MAXIMUM RECORD LENGTH (IGNORED ON SOME MACHINES) =%4d; FILE FORM=%2d (1=FORMATTED, 2=UNFORMATTED)\n            DATA SET NAME = %s\n",
        keywrd, iunit, cfour, cstat, im_val, iform,
        irlen > 0 ? record_s[1:irlen] : "")

    if kode == Int32(1)
        if extension == "KCP" || extension == "ADD"
            ERRGRO(true, Int32(31))
        else
            @printf(io_units[jostnd], "\n            **********   OPEN FAILED   **********\n")
        end
    end

    return nothing
end

"""
    KEYDMP(iout, irecnt, keywrd, array, kard)

Debug dump of a keyword record: record number, keyword, numeric parameters.
"""
function KEYDMP(iout::Int32, irecnt::Integer, keywrd::AbstractString,
                array::Vector{Float32}, kard::Vector{String})
    @printf(io_units[iout],
        "\n CARD NUM =%5d; KEYWORD FIELD = '%8s'\n      PARAMETERS ARE:",
        irecnt, keywrd)
    for v in array[1:12]
        @printf(io_units[iout], "%14.12g", v)
    end
    @printf(io_units[iout], "\n      COL 11 TO 130 ='")
    for f in kard[1:12]
        @printf(io_units[iout], "%10s", f)
    end
    @printf(io_units[iout], "'\n")
    return nothing
end

# GROHED is implemented in sn/grohed.jl (included after sn/blkdat.jl)
