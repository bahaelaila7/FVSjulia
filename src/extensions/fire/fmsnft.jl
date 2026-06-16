# SUBROUTINE FMSNFT(IFFEFT)
# Translated from: fmsnft.f (92 lines), FIRE-SN single-stand version
#
# Calculates a categorical FFE forest type (1-9) from the FIA forest type
# code (IFORTP) and stand composition. Used by FMCBA and FMCFMD to select
# default surface fuel levels and fuel model logic.
# Called from: FMCBA, FMCFMD

function FMSNFT(iffeft_ref::Ref{Int32})
    iffeft_ref[] = Int32(0)
    local iffeft::Int32

    if IFORTP ∈ (Int32(997), Int32(504), Int32(505), Int32(510), Int32(512),
                 Int32(515), Int32(519), Int32(520))
        iffeft = Int32(1)   # hardwood
    elseif IFORTP ∈ (Int32(103), Int32(104), Int32(141), Int32(142),
                     Int32(996), Int32(401), Int32(403), Int32(404), Int32(405),
                     Int32(406), Int32(407), Int32(409)) ||
           (Int32(161) <= IFORTP <= Int32(168))
        # Pine / mixed; compute pine vs non-pine BA split
        local pineba::Float32  = 0.0f0
        local npineba::Float32 = 0.0f0
        for i in 1:ITRN
            local x::Float32 = FMPROB[i] * DBH[i] * DBH[i] * 0.0054542f0
            sp = Int(ISP[i])
            if 4 <= sp <= 14   # pine species 4-14
                pineba  += x
            else
                npineba += x
            end
        end
        iffeft = Int32(0)
        if (pineba + npineba) > 0.0f0
            ratio = pineba / (pineba + npineba)
            if ratio <= 0.50f0
                iffeft = Int32(2)   # hardwood/pine
            elseif ratio <= 0.70f0
                iffeft = Int32(3)   # pine/hardwood
            else
                iffeft = Int32(4)   # pine
            end
        end
        if IFORTP == Int32(162)
            if ATAVH > 50.0f0 && ISTCL >= Int32(3)
                iffeft = Int32(5)   # pine bluestem
            end
        end
    elseif IFORTP ∈ (Int32(501), Int32(503))
        if ATAVH > 30.0f0 && ISTCL >= Int32(3)
            iffeft = Int32(6)   # oak savannah
        else
            iffeft = Int32(1)   # hardwood
        end
    elseif IFORTP ∈ (Int32(181), Int32(402))
        iffeft = Int32(7)   # eastern redcedar
    elseif IFORTP ∈ (Int32(602), Int32(605), Int32(701), Int32(706),
                     Int32(708), Int32(807))
        iffeft = Int32(8)   # saint francis types
    elseif IFORTP == Int32(999)
        iffeft = Int32(9)   # nonstocked
    else
        iffeft = Int32(1)   # hardwood (default)
    end

    iffeft_ref[] = iffeft
    return nothing
end
