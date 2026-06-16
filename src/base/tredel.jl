# base/tredel.jl — TREDEL: delete tree records by filling vacancies from end
# Translated from: bin/FVSsn_buildDir/tredel.f (124 lines)
#
# Vacancies in index[] are marked with negative values by the caller.
# ivact = number of negative (vacant) entries.
# Deleted records are moved to the bottom (not discarded) so volumes etc.
# remain accessible.

function TREDEL(ivact::Integer, index::AbstractVector{Int32})
    if ITRN <= Int32(0)
        @goto label_50
    end

    # (A) Sort index ascending so vacancy pointers are at the top (most negative first)
    IQRSRT(index, Int(ITRN))

    # (B) Notify SVS extension (stubs when not active)
    SVTDEL(index, ivact)
    SVCMP1()

    # (C) Initialize pointers: iv → end of vacancy list, ir → end of tree list
    iv = Int(ivact) + 1
    ir = Int(ITRN) + 1

    @label label_10
    iv -= 1
    if iv < 1; @goto label_20; end

    ir -= 1
    if ir <= Int(ivact); @goto label_20; end

    ivac = Int(-index[iv])
    irec = Int(index[ir])
    if ivac > irec; @goto label_20; end

    # (F) Move tree at position irec to vacancy at ivac
    TREMOV(ivac, irec)
    RDTDEL(ivac, irec)    # western root disease
    BRTDEL(ivac, irec)    # blister rust
    FMTDEL(ivac, irec)    # fire model
    SVCMP2(ivac, irec)    # SVS

    @goto label_10

    @label label_20
    SVCMP3()

    global ITRN = ITRN - Int32(ivact)

    @label label_50
    global IREC1 = ITRN
    return nothing
end
