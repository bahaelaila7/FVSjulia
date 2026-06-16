# svcuts.f — SVCUTS: update SVS visualization after harvest, compress object list (101 lines)
# Called from CUTS after trees are removed.

function SVCUTS(ivac::Integer, ssng::AbstractVector{Float32},
                dsng::AbstractVector{Float32}, ctcrwn::AbstractVector{Float32})
    # Remove harvested trees from the SVS standing-live list
    SVRMOV(WK3, 4, ssng, dsng, ctcrwn, IY[Int(ICYC)])
    # Write post-cutting visualization
    SVOUT(IY[Int(ICYC)], 2, "Post cutting")

    ivac == 0 && return nothing

    # Build a flag array: ICUTFG[i] < 0 if tree i was completely removed
    icutfg = zeros(Int32, MAXTRE)
    for i in 1:Int(ITRN)
        ii = Int(IND2[i])
        if ii < 0
            icutfg[-ii] = Int32(ii)
        else
            icutfg[ii]  = Int32(0)
        end
    end

    # Compress NSVOBJ by dropping records that point to removed trees
    iput = 0
    for isvobj in 1:Int(NSVOBJ)
        ldrop = false
        if IOBJTP[isvobj] != Int32(4)
            if IOBJTP[isvobj] == Int32(0) ||
               (IOBJTP[isvobj] == Int32(1) && icutfg[Int(IS2F[isvobj])] < 0)
                ldrop = true
            end
        end
        if ldrop
            if iput == 0; iput = isvobj; end
        else
            if iput > 0 && iput < isvobj
                IS2F[iput]   = IS2F[isvobj]
                XSLOC[iput]  = XSLOC[isvobj]
                YSLOC[iput]  = YSLOC[isvobj]
                IOBJTP[iput] = IOBJTP[isvobj]
                iput += 1
            end
        end
    end
    if iput > 0; global NSVOBJ = Int32(iput - 1); end
    return nothing
end
