# SUBROUTINE FMCFMD(IYR, FMD)
# Translated from: fmcfmd.f (218 lines), FIRE-SN single-stand version
#
# Returns two types of information:
#   (a) Static fuel model: IFMD(1) with FWT(1)=1.0
#   (b) Dynamic fuel model: up to 4 candidate models + weightings for FMDYN
# For SN variant (hardwood/pine/mixed), selects from 14-class SN fuel model scheme.
# Called from: FMBURN

# Fuel model class count
const _FMCFMD_ICLSS = 14

# X-intercepts (SMALL=0 axis) and Y-intercepts (LARGE=0 axis) per model line
const _FMCFMD_XPTS = Float32[
    5., 15.,   # FMD  1
    5., 15.,   # FMD  2
    5., 15.,   # FMD  3
    5., 15.,   # FMD  4
    5., 15.,   # FMD  5
    5., 15.,   # FMD  6
    5., 15.,   # FMD  7
    5., 15.,   # FMD  8
    5., 15.,   # FMD  9
   10., 30.,   # FMD 10
   15., 30.,   # FMD 11
   30., 60.,   # FMD 12
   45.,100.,   # FMD 13
   30., 60.    # FMD 14
]

function FMCFMD(iyr::Integer, fmd_ref::Ref{Int32})
    local debug::Bool = false
    debug = DBCHK(false, "FMCFMD", Int32(6), ICYC)
    if debug
        @printf(get(io_units, Int32(JOSTND), stdout),
                " FMCFMD CYCLE= %2d IYR=%5d LUSRFM=%s\n", ICYC, iyr, LUSRFM)
    end

    if LUSRFM; return nothing; end

    if debug
        @printf(get(io_units, Int32(JOSTND), stdout),
                " FMCFMD CYCLE= %2d IYR=%5d HARVYR=%5d LDYNFM=%s PERCOV=%7.2f FMKOD=%4d SMALL=%7.2f LARGE=%7.2f\n",
                ICYC, iyr, HARVYR, LDYNFM, PERCOV, FMKOD, SMALL, LARGE)
    end

    # Determine FFE forest type (1-9)
    local iffeft_ref = Ref(Int32(0))
    FMSNFT(iffeft_ref)
    local iffeft::Int32 = iffeft_ref[]

    # Build candidate model weight vector (14 classes, all initially 0.0)
    local eqwt = zeros(Float32, _FMCFMD_ICLSS)

    # Low fuel model selection by forest type
    if iffeft ∈ (Int32(1), Int32(2), Int32(3))   # hardwood / hardwood-pine / pine-hardwood
        if SMALL > 6.0f0
            eqwt[5] = 1.0f0
        else
            local moiswt8::Float32 = 0.0f0
            local moiswt9::Float32 = 0.0f0
            if MOIS[1, 4] <= 0.15f0
                moiswt9 = 1.0f0
            elseif MOIS[1, 4] > 0.25f0
                moiswt8 = 1.0f0
            else
                moiswt9 = 1.0f0 - (MOIS[1, 4] - 0.15f0) / 0.1f0
                moiswt8 = 1.0f0 - (0.25f0 - MOIS[1, 4]) / 0.1f0
            end
            if SMALL <= 4.0f0
                eqwt[8] = moiswt8; eqwt[9] = moiswt9
            else
                eqwt[8] = (1.0f0 - (SMALL - 4.0f0) / 2.0f0) * moiswt8
                eqwt[9] = (1.0f0 - (SMALL - 4.0f0) / 2.0f0) * moiswt9
                eqwt[5] = 1.0f0 - (6.0f0 - SMALL) / 2.0f0
            end
        end
    elseif iffeft ∈ (Int32(4), Int32(8))   # pine / saint francis
        if MOIS[1, 4] <= 0.15f0
            eqwt[9] = 1.0f0
        elseif MOIS[1, 4] > 0.25f0
            eqwt[8] = 1.0f0
        else
            eqwt[9] = 1.0f0 - (MOIS[1, 4] - 0.15f0) / 0.1f0
            eqwt[8] = 1.0f0 - (0.25f0 - MOIS[1, 4]) / 0.1f0
        end
    elseif iffeft ∈ (Int32(5), Int32(6))   # pine bluestem / oak savannah
        eqwt[2] = 1.0f0
    elseif iffeft == Int32(7)   # eastern redcedar
        local rcht::Float32  = 0.0f0
        local rctpa::Float32 = 0.0f0
        for i in 1:ITRN
            if ISP[i] == Int32(2)   # redcedar
                rcht  += HT[i]
                rctpa += FMPROB[i]
            end
        end
        if rctpa > 0.0f0; rcht /= rctpa; end
        if rcht > 7.5f0
            eqwt[4] = 1.0f0
        elseif rcht <= 4.5f0
            eqwt[6] = 1.0f0
        else
            eqwt[6] = 1.0f0 - (rcht - 4.5f0) / 3.0f0
            eqwt[4] = 1.0f0 - (7.5f0 - rcht) / 3.0f0
        end
    else   # iffeft == 9 (nonstocked) or unhandled
        eqwt[6] = 1.0f0
    end

    # Models 10 and 12 always candidate for natural fuels
    eqwt[10] = 1.0f0
    eqwt[12] = 1.0f0
    # Models 11, 13, 14 not candidates for Ozark FFE
    eqwt[11] = 0.0f0; eqwt[13] = 0.0f0; eqwt[14] = 0.0f0

    # Integer tags (IPTR) = model number; ITYP = 0 (normal slope) for all
    local iptr = Int32[1,2,3,4,5,6,7,8,9,10,11,12,13,14]
    local ityp = zeros(Int32, _FMCFMD_ICLSS)
    # Fortran fills DATA ((XPTS(I,J),J=1,2),I=1,ICLSS) row-major: xpts[i,1]=x-int, xpts[i,2]=y-int
    local xpts = permutedims(reshape(_FMCFMD_XPTS, (2, _FMCFMD_ICLSS)))

    # Call FMDYN to resolve weights and set FMD (highest-weight model)
    FMDYN(SMALL, LARGE, ityp, xpts, eqwt, iptr, Int32(_FMCFMD_ICLSS), LDYNFM, fmd_ref)

    if debug
        @printf(get(io_units, Int32(JOSTND), stdout),
                " FMCFMD, FMD=%4d LDYNFM=%s\n", fmd_ref[], LDYNFM)
    end
    return nothing
end
