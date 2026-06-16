# mrules.f — regional merchandizing rule defaults (498 lines)
# All scalar output args are Refs (Fortran pass-by-reference).

function MRULES(regn::Integer, forst::AbstractString, voleq::AbstractString,
                dbhob::Real,
                cor_ref::Ref{Char},
                evod_ref::Ref{Int32},
                opt_ref::Ref{Int32},
                maxlen_ref::Ref{Float32},
                minlen_ref::Ref{Float32},
                merchl_ref::Ref{Float32},
                minlent_ref::Ref{Float32},
                mtopp_ref::Ref{Float32},
                mtops_ref::Ref{Float32},
                stump_ref::Ref{Float32},
                trim_ref::Ref{Float32},
                btr_ref::Ref{Float32},
                dbtbh_ref::Ref{Float32},
                minbfd_ref::Ref{Float32},
                prod::AbstractString)

    # Working copies (Fortran modifies local variables then returns via implicit pass-by-ref)
    cor     = cor_ref[]
    evod    = evod_ref[]
    opt     = opt_ref[]
    maxlen  = maxlen_ref[]
    minlen  = minlen_ref[]
    merchl  = merchl_ref[]
    minlent = minlent_ref[]
    mtopp   = mtopp_ref[]
    mtops   = mtops_ref[]
    stump   = stump_ref[]
    trim_v  = trim_ref[]
    btr     = btr_ref[]
    dbtbh   = dbtbh_ref[]
    minbfd  = minbfd_ref[]

    # Save input tree-level variables before regional defaults overwrite them
    treestump = stump
    treemtopp = mtopp
    treemtops = mtops
    treebtr   = btr
    treedbtbh = dbtbh

    if btr > 0f0 && dbtbh <= 0f0
        dbtbh = Float32(dbhob) - Float32(dbhob) * btr / 100f0
    end

    mdl = length(voleq) >= 6 ? voleq[4:6] : ""

    if regn == 1
        if mdl == "FW2" || mdl == "fw2" || mdl == "FW3" || mdl == "fw3" ||
                (length(voleq) >= 3 && voleq[1:3] == "NVB")
            cor    = 'Y'
            evod   = Int32(2)
            maxlen = 16f0
            minlen = 2f0
            minlent = 16f0
            opt    = Int32(22)
            if stump <= 0f0; stump = 1f0; end
            if mtopp <= 0f0; mtopp = 5.6f0; end
            if mtops <= 0f0; mtops = 4f0; end
            trim_v = 0.5f0
            merchl = 8f0
            if prod == "08"
                merchl = 16f0
                minlen = 16f0
            end
            minbfd = 1f0
        else
            cor    = 'Y'
            evod   = Int32(2)
            maxlen = 20f0
            minlen = 10f0
            minlent = 2f0
            opt    = Int32(12)
            if stump <= 0f0; stump = 1f0; end
            if mtopp <= 0f0; mtopp = 5.6f0; end
            if mtops <= 0f0; mtops = 4f0; end
            trim_v = 0.5f0
            merchl = 10f0
            minbfd = 1f0
        end

    elseif regn == 2
        cor    = 'Y'
        evod   = Int32(2)
        maxlen = 16f0
        minlen = 2f0
        minlent = 2f0
        opt    = Int32(22)
        if stump <= 0f0; stump = 1f0; end
        if mtopp <= 0f0; mtopp = 6f0; end
        if mtops <= 0f0; mtops = 4f0; end
        trim_v = 0.5f0
        merchl = 8f0
        minbfd = 1f0

    elseif regn == 3
        cor    = 'Y'
        evod   = Int32(2)
        maxlen = 16f0
        minlen = 2f0
        minlent = 2f0
        opt    = Int32(22)
        minbfd = 1f0
        trim_v = 0.5f0
        merchl = 8f0

        if prod == "01" || prod == "08"
            minlen  = 10f0
            minlent = 10f0
            if prod == "01" && stump <= 0f0; stump = 1f0; end
            if prod == "01" && mtopp <= 0f0; mtopp = 6f0; end
            if mtops <= 0f0; mtops = 4f0; end
            merchl = 10f0
            if prod == "08"
                if stump <= 0f0; stump = 0.5f0; end
                if mtopp <= 0f0; mtopp = 4f0; end
            end
        elseif prod == "14"
            minlen  = 10f0
            minlent = 10f0
            if stump <= 0f0; stump = 0.5f0; end
            if mtopp <= 0f0; mtopp = 4f0; end
            if mtops <= 0f0; mtops = 1f0; end
            merchl = 10f0
        elseif prod == "20"
            if stump <= 0f0; stump = 0.5f0; end
            if mtopp <= 0f0; mtopp = 1f0; end
            if mtops <= 0f0; mtops = 1f0; end
        elseif prod == "07"
            minlent = 4f0
            minlen  = 4f0
            if stump <= 0f0; stump = 0.5f0; end
            if mtopp <= 0f0; mtopp = 2f0; end
            if mtops <= 0f0; mtops = 2f0; end
        else
            minlen  = 10f0
            minlent = 10f0
            if stump <= 0f0; stump = 0.5f0; end
            if mtopp <= 0f0; mtopp = 4f0; end
            if mtops <= 0f0; mtops = 4f0; end
            merchl = 10f0
        end

        if stump <= 0f0; stump = 1f0; end
        if mtopp  <= 0f0; mtopp = 6f0; end
        if mtops  <= 0f0; mtops = 4f0; end

    elseif regn == 4
        cor    = 'Y'
        evod   = Int32(2)
        maxlen = 16f0
        minlen = 2f0
        minlent = 2f0
        opt    = Int32(22)
        if stump <= 0f0; stump = 1f0; end
        if mtopp <= 0f0; mtopp = 6f0; end
        if mtops <= 0f0; mtops = 4f0; end
        trim_v = 0.5f0
        merchl = 8f0
        minbfd = 1f0

    elseif regn == 5
        cor    = 'Y'
        evod   = Int32(2)
        maxlen = 16f0
        minlen = 2f0
        minlent = 2f0
        opt    = Int32(22)
        if stump <= 0f0; stump = 1f0; end
        if mtopp <= 0f0; mtopp = 6f0; end
        if mtops <= 0f0; mtops = 4f0; end
        trim_v = 0.5f0
        merchl = 8f0
        minbfd = 1f0

    elseif regn == 6 || regn == 11
        cor    = 'N'
        evod   = Int32(2)
        maxlen = 16f0
        minlen = 2f0
        minlent = 2f0
        opt    = Int32(23)
        if stump <= 0f0; stump = 0f0; end
        if mtopp <= 0f0; mtopp = 2f0; end
        if mtops <= 0f0; mtops = 2f0; end
        trim_v = 0.5f0
        merchl = 8f0
        minbfd = 1f0

    elseif regn == 7
        cor    = 'N'
        evod   = Int32(2)
        maxlen = 16f0
        minlen = 2f0
        minlent = 2f0
        opt    = Int32(23)
        if stump <= 0f0; stump = 1f0; end
        if mtopp <= 0f0; mtopp = Float32(round(0.184f0 * Float32(dbhob) + 2.24f0)) end
        if mtops <= 0f0; mtops = 2f0; end
        trim_v = 0.5f0
        merchl = 8f0
        minbfd = 1f0

    elseif regn == 8 && (mdl == "CLK" || (length(voleq) >= 3 && voleq[1:3] == "NVB"))
        cor    = 'Y'
        evod   = Int32(2)
        maxlen = 8f0
        minlen = 2f0
        minlent = 2f0
        merchl = 8f0
        if prod == "08"; merchl = 12f0; end
        opt    = Int32(22)
        spp = try; parse(Int, strip(voleq[8:10])); catch; 0; end
        if mtopp <= 0f0
            if prod == "08"
                mtopp = 0.1f0
            else
                mtopp = spp < 300 ? 7f0 : 9f0
            end
        end
        if mtops <= 0f0; mtops = 4f0; end
        trim_v = 0.5f0
        if stump <= 0f0
            stump = prod == "01" ? 1f0 : 0.5f0
        end

    elseif regn == 9 && (mdl == "CLK" || (length(voleq) >= 3 && voleq[1:3] == "NVB"))
        cor    = 'Y'
        evod   = Int32(2)
        maxlen = 8f0
        minlen = 2f0
        minlent = 4f0
        merchl = 8f0
        opt    = Int32(22)
        spp = try; parse(Int, strip(voleq[8:10])); catch; 0; end
        if mtopp <= 0f0
            mtopp = spp < 300 ? 7.6f0 : 9.6f0
        end
        if mtops <= 0f0; mtops = 4f0; end
        trim_v = 0.3f0
        if stump <= 0f0
            stump = prod == "01" ? 1f0 : 0.5f0
        end

    elseif regn == 10
        cor    = 'Y'
        evod   = Int32(2)
        maxlen = 16f0
        minlen = 8f0
        minlent = 8f0
        opt    = Int32(23)
        if stump <= 0f0; stump = 1f0; end
        if mtopp <= 0f0; mtopp = 6f0; end
        if mtops <= 0f0; mtops = 4f0; end
        trim_v = 0.5f0
        merchl = 8f0
        minbfd = 1f0

    else
        cor    = 'Y'
        evod   = Int32(2)
        maxlen = 16f0
        minlen = 2f0
        minlent = 2f0
        opt    = Int32(22)
        if stump <= 0f0; stump = 1f0; end
        if mtopp <= 0f0; mtopp = 6f0; end
        if mtops <= 0f0; mtops = 4f0; end
        trim_v = 0.5f0
        merchl = 8f0
        minbfd = 1f0
    end

    # Apply user-modified merch rules (set via MRULE keyword → MRULEMOD='Y')
    if MRULEMOD[] == 'Y'
        if NEWEVOD[]    > 0;    evod   = NEWEVOD[];    end
        if NEWOPT[]     > 0;    opt    = NEWOPT[];     end
        if NEWMAXLEN[]  > 0.1f0; maxlen  = NEWMAXLEN[];  end
        if NEWMINLEN[]  > 0.1f0; minlen  = NEWMINLEN[];  end
        if NEWMERCHL[]  > 0.1f0; merchl  = NEWMERCHL[];  end
        if NEWMINLENT[] > 0.1f0; minlent = NEWMINLENT[]; end
        if NEWMTOPP[]   > 0.1f0 && treemtopp <= 0f0; mtopp = NEWMTOPP[];   end
        if NEWMTOPS[]   > 0.1f0 && treemtops <= 0f0; mtops = NEWMTOPS[];   end
        if NEWSTUMP[]   > 0.1f0 && treestump <= 0f0; stump = NEWSTUMP[];   end
        if NEWTRIM[]    > 0.1f0; trim_v  = NEWTRIM[];  end
        if NEWBTR[]     > 0.01f0 && treebtr   <= 0f0; btr   = NEWBTR[];    end
        if NEWDBTBH[]   > 0.01f0 && treedbtbh <= 0f0; dbtbh = NEWDBTBH[];  end
        if NEWMINBFD[]  > 0.1f0; minbfd  = NEWMINBFD[]; end
        if NEWBTR[] > 0.01f0 && NEWDBTBH[] <= 0f0
            dbtbh = Float32(dbhob) - Float32(dbhob) * NEWBTR[] / 100f0
        end
        MRULEMOD[] = 'N'
    end

    if mtops > mtopp; mtops = mtopp; end

    cor_ref[]    = cor
    evod_ref[]   = evod
    opt_ref[]    = opt
    maxlen_ref[] = maxlen
    minlen_ref[] = minlen
    merchl_ref[] = merchl
    minlent_ref[] = minlent
    mtopp_ref[]  = mtopp
    mtops_ref[]  = mtops
    stump_ref[]  = stump
    trim_ref[]   = trim_v
    btr_ref[]    = btr
    dbtbh_ref[]  = dbtbh
    minbfd_ref[] = minbfd
    return nothing
end
