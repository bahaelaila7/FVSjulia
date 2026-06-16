# Small utility subroutines
# Translated from: upcase.f, ch2num.f, upkey.f, unblnk.f, tresor.f,
#                  maical.f, dunn.f, behre.f, trnslo.f, cmrang.f,
#                  numlog.f

"""
    UPCASE!(c) → Char

Convert a single character to uppercase (in-place via return value).
Fortran: SUBROUTINE UPCASE(C) — mutates a single CHARACTER*1 argument.
In Julia, characters are immutable; callers use the return value.
"""
function UPCASE(c::Char)::Char
    return uppercase(c)
end

"""
    CH2NUM(icyc) → String

Write a two-digit integer into a CHARACTER*2 string.
"""
function CH2NUM(icyc::Integer)::String
    return @sprintf("%2d", icyc)
end

"""
    UPKEY!(keywrd) → String

Convert a keyword string (8 chars) to uppercase.
"""
function UPKEY(keywrd::AbstractString)::String
    return uppercase(keywrd)
end

"""
    UNBLNK!(record) → (String, Int)

Remove all blanks from a character string, left-justifying nonblank content.
Returns the modified string and IRLEN (length of the nonblank portion).
"""
function UNBLNK(record::AbstractString)
    result = replace(record, " " => "")
    irlen  = length(result)
    result = rpad(result, length(record))
    return result, irlen
end

"""
    TRESOR()

Sort and match tree IDs with internal FVS indices.
Dispatches to extension sort routines.
"""
function TRESOR()
    BRSOR()
    return nothing
end


"""
    DUNN(ss)

Stub: process Dunning site code information.
No-op for SN variant (IE variant uses this).
"""
function DUNN(ss::Float32)
    return nothing
end

"""
    BEHRE(l1, l2) → Float32

Calculate volume of a solid of revolution described by a Behre taper curve.
Uses AHAT and BHAT from coeffs.jl.
Result is off by factor π/A³ (cancels in VOLS ratios).
"""
function BEHRE(l1::Float32, l2::Float32)::Float32
    alb1 = AHAT * l1 + BHAT
    alb2 = AHAT * l2 + BHAT
    return alb2 - alb1 - Float32(2.0) * BHAT * (log(alb2) - log(alb1)) -
           BHAT * BHAT / alb2 + BHAT * BHAT / alb1
end

"""
    TRNSLO()

Decode the input slope value (%) to a ratio (0–1).
Clamps negative values to 0.
"""
function TRNSLO()
    global SLOPE = SLOPE / Float32(100.0)
    if SLOPE < Float32(0.0)
        SLOPE = Float32(0.0)
    end
    return nothing
end

"""
    CMRANG(len, indx, arr) → Float32

Find the maximum range of elements in `arr` indexed by `indx[1:len]`.
Part of the compression routine COMPRS.
"""
function CMRANG(len::Integer, indx::AbstractVector{Int32}, arr::AbstractVector{Float32})::Float32
    x1 = Float32(1e30)
    x2 = Float32(-1e30)
    for j in 1:len
        i = indx[j]
        if arr[i] < x1; x1 = arr[i]; end
        if arr[i] > x2; x2 = arr[i]; end
    end
    return x2 - x1
end

# ---------------------------------------------------------------------------
# String utilities
# ---------------------------------------------------------------------------

"""
    ISTFNB(string) → Int

Find the location of the first non-blank character. Returns 0 if all blank.
"""
function ISTFNB(str::AbstractString)::Int32
    for (i, c) in enumerate(str)
        if c != ' '
            return Int32(i)
        end
    end
    return Int32(0)
end

"""
    ISTLNB(string) → Int

Find the location of the last non-blank character. Returns 0 if all blank.
"""
function ISTLNB(str::AbstractString)::Int32
    n = length(str)
    for i in n:-1:1
        if str[i] != ' '
            return Int32(i)
        end
    end
    return Int32(0)
end

# ---------------------------------------------------------------------------
# Coordinate / geometric utilities
# ---------------------------------------------------------------------------

"""
    TRNASP()

Convert the input aspect from degrees to radians (in-place via ASPECT global).
"""
function TRNASP()
    global ASPECT = ASPECT * Float32(0.0174533)
    return nothing
end

# RCDSET: real implementation in base/lbops.jl

"""
    GETSED() → Float32

Generate a seed for the random number generator from the system clock.
"""
function GETSED()::Float32
    t = time()
    # Emulate Fortran logic: use time components to form an odd integer seed
    sec = floor(Int, mod(t, 60.0))
    min_ = floor(Int, mod(t / 60.0, 60.0))
    frac = floor(Int, mod(t * 100.0, 10.0))
    sed = Float32(abs((min_ * 10000 + sec * 100 + min_) / max(sec + 1, 1) *
                      Float32(min_ + 100 + frac) / 10.0))
    if mod(sed, Float32(2.0)) == Float32(0.0)
        sed += Float32(1.0)
    end
    return sed
end

# ---------------------------------------------------------------------------
# Volume utility
# ---------------------------------------------------------------------------

# DAMCDS: real implementation in base/damcds.jl

"""
    EVMKV(ctok)

Create a new user-defined Event Monitor variable named `ctok`.
"""
function EVMKV(ctok::AbstractString)
    global ITST5, LEVUSE
    if ITST5 < MXTST5_OP
        ITST5 += Int32(1)
        CTSTV5[ITST5] = ctok
        LTSTV5[ITST5] = false
        LEVUSE = true
    else
        ERRGRO(true, Int32(10))
        ERRGRO(true, Int32(12))
        @printf(io_units[Int32(6)], "ISSUED IN EVMKV\n")
    end
    return nothing
end

# LNKINT defined in base/lnk.jl (full implementation moved there)

# DBALL defined in base/dball.jl (full implementation there)

"""
    R6FIX!(dbhob, fclass, tlh, tth, httype, logvol)

Apply PNW board-foot appraisal correction factor to log volumes.
Used only in PNW volume equations.
"""
function R6FIX!(dbhob::Float32, fclass::Int32, tlh::Float32, tth::Float32,
                httype::Char, logvol::Matrix{Float32})
    if httype == 'l' || httype == 'L'
        tlhln = log(tlh * Float32(10.0))
        bf3216 = Float32(0.4017) + Float32(0.1450)*tlhln - Float32(0.0025)*dbhob - Float32(0.0009)*fclass
    else
        tthln = log(tth)
        bf3216 = Float32(0.1909) + Float32(0.0006)*dbhob + Float32(0.1349)*tthln - Float32(0.0002)*fclass
    end
    for i in 1:20
        logvol[1, i] = round(logvol[1, i] * bf3216)
    end
    return nothing
end

# numlog.f — NUMLOG: compute number of merchantable log segments (101 lines)
function NUMLOG(opt::Integer, evod::Integer, lmerch::Real, maxlen::Real,
                minlen::Real, trim::Real, numseg_ref::Ref{Int32})
    numseg = Int32(floor(lmerch / (maxlen + trim)))
    leftov = lmerch - (maxlen + trim) * Float32(numseg)

    if numseg > 0 || leftov >= minlen
        if opt < 20
            if leftov >= (trim + 0.5f0); numseg += Int32(1); end
        elseif opt == 21 || opt == 22
            if evod == 1 && leftov >= (trim + 0.5f0); numseg += Int32(1); end
            if evod == 2 && leftov >= (trim + 1.0f0); numseg += Int32(1); end
        elseif opt == 23
            if leftov >= (trim + minlen); numseg += Int32(1); end
        elseif opt == 24
            if leftov >= ((maxlen + trim) / 4.0f0); numseg += Int32(1); end
        end
    else
        numseg = Int32(0)
    end
    if numseg > 20; numseg = Int32(20); end
    numseg_ref[] = numseg
    return nothing
end
