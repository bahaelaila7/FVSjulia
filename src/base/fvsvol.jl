# fvsvol.jl — NATCRS / OCFVOL / OBFVOL / GETEQN
# Translated from: fvsvol.f (667 lines)
#
# NATCRS: calls VOLINITNVB (NVEL library) for variant-specific cubic/board volumes (METHC=6/10)
# OCFVOL: old cubic volume — variant-specific special calculation (SN returns 0 by default)
# OBFVOL: old board foot volume — variant-specific (SN returns 0 by default)
# GETEQN: returns volume equation numbers and DIB top diameters for a tree

# ---------------------------------------------------------------------------
# Shared common for FVSVOLCOM (local to this file)
# ---------------------------------------------------------------------------
_fvsvol_iregn = Ref(Int32(0))
_fvsvol_forst = Ref("  ")
_fvsvol_voleq = Ref("           ")
_fvsvol_mtopp = Ref(Float32(0))
_fvsvol_mtops = Ref(Float32(0))
_fvsvol_prod  = Ref("  ")

# ---------------------------------------------------------------------------
# NATCRS: National Cruise System volume (METHC=6 or 10)
# ---------------------------------------------------------------------------
function NATCRS(tcf_ref::Ref{Float32}, mcf_ref::Ref{Float32}, scf_ref::Ref{Float32},
                bbfv_ref::Ref{Float32}, ispc::Integer, d::Real, h::Real,
                tkill::Bool, cratio::Integer, bark::Real, itrnc::Integer,
                vmax_ref::Ref{Float32}, bfmax_ref::Ref{Float32},
                rcull::Real, decay::Integer, wdstms::Integer, biodryin,
                livedead::AbstractString, ctkflg_ref::Ref{Bool}, btkflg_ref::Ref{Bool},
                it::Integer)

    tcf_ref[] = Float32(0); mcf_ref[] = Float32(0); scf_ref[] = Float32(0)
    bbfv_ref[] = Float32(0); vmax_ref[] = Float32(0); bfmax_ref[] = Float32(0)
    ctkflg_ref[] = false; btkflg_ref[] = false

    # VOLINITNVB (NVEL library) not yet translated.
    # Fallback: use Jenkins equations for biomass components.
    biomas = biodryin  # should be AbstractVector{Float32} of length 15
    if biomas isa AbstractVector && length(biomas) >= 8
        # Get FIA species code for this species slot
        ifiasp = 0
        if ispc >= 1 && ispc <= Int(MAXSP)
            try; ifiasp = parse(Int, strip(FIAJSP[ispc])); catch; end
        end

        # Call Jenkins with FIA code and DBH (inches)
        jnkbms = zeros(Float32, 8)
        JENKINS(ifiasp > 0 ? ifiasp : 8, Float32(d), jnkbms)

        # Look up carbon ratio from WDBKWT
        carb_ratio = Float32(0.5)
        if ifiasp > 0
            lo = 1; hi = Int(WDBKWT_TOTSPC)
            while lo <= hi
                mid = (lo + hi) >>> 1
                code = Int(WDBKWT[mid, 1])
                if code == ifiasp; carb_ratio = Float32(WDBKWT[mid, 12]); break
                elseif code < ifiasp; lo = mid + 1
                else; hi = mid - 1
                end
            end
        end

        # Map Jenkins 8-component output to NVB 15-component biomas array
        # NVB layout: 1=abvgrd(no fol), 2=stem wood, 3=stem bark, 4=stump wood,
        #   5=stump bark, 6=sawtimber wood, 7=sawtimber bark, 8=topwood wood,
        #   9=topwood bark, 10=tip wood, 11=tip bark, 12=branches, 13=foliage,
        #   14=top+limb, 15=carbon
        abt      = jnkbms[1]          # above-ground total (lbs, with foliage)
        fol      = jnkbms[4]          # foliage (lbs)
        branches = jnkbms[6]          # branches (lbs)
        stemwd   = jnkbms[2]          # stem wood (lbs)
        stembk   = jnkbms[3]          # stem bark (lbs)
        agb_nofol = abt - fol         # above-ground excluding foliage

        if length(biomas) >= 15
            biomas[1]  = agb_nofol    # above-ground (no foliage)
            biomas[2]  = stemwd       # stem wood
            biomas[3]  = stembk       # stem bark
            biomas[4]  = Float32(0)   # stump wood (not computed)
            biomas[5]  = Float32(0)   # stump bark
            biomas[6]  = stemwd       # sawtimber wood (approximate with stem wood)
            biomas[7]  = stembk       # sawtimber bark
            biomas[8]  = Float32(0)   # topwood wood
            biomas[9]  = Float32(0)   # topwood bark
            biomas[10] = Float32(0)   # tip wood
            biomas[11] = Float32(0)   # tip bark
            biomas[12] = branches     # branches
            biomas[13] = fol          # foliage
            biomas[14] = branches + fol  # top and limb (crown)
            biomas[15] = abt * carb_ratio  # carbon content
        end
    end
    return nothing
end

# ---------------------------------------------------------------------------
# OCFVOL: old cubic foot volume (METHC=8 or variant special)
# ---------------------------------------------------------------------------
function OCFVOL(vn_ref::Ref{Float32}, vm_ref::Ref{Float32},
                ispc::Integer, d::Real, h::Real, tkill::Bool, bark::Real,
                itrnc::Integer, vmax_ref::Ref{Float32}, lcone_ref::Ref{Bool},
                ctkflg_ref::Ref{Bool}, it::Integer)

    debug = DBCHK(false, "FVSVOL", Int32(6), ICYC)
    d_f = Float32(d); h_f = Float32(h)
    vn_ref[] = Float32(0); vm_ref[] = Float32(0)
    ctkflg_ref[] = false

    if VARACD == "AK"
        FVSBRUCEDEMARS(vn_ref, vm_ref, vmax_ref, d_f, h_f, Int32(ispc), Float32(bark), lcone_ref, ctkflg_ref)
    elseif VARACD == "CR"
        FVSHANNBARE(vn_ref, vm_ref, vmax_ref, Int32(ispc), d_f, h_f, ctkflg_ref)
    elseif VARACD == "NC"
        FVSSIERRALOG(vn_ref, vm_ref, vmax_ref, Int32(ispc), d_f, h_f, Float32(bark), lcone_ref, ctkflg_ref)
    elseif VARACD == "CS" || VARACD == "LS" || VARACD == "NE"
        vn_ref[] = Float32(0); vm_ref[] = Float32(0)
        if it > 0 && (IMC[it] < 3) && d_f >= DBHMIN[ispc]
            TWIGCF(Int32(ispc), h_f, d_f, vn_ref, vm_ref, Int32(it))
        end
    else
        # SN and all other variants: return 0
        vn_ref[] = Float32(0); vmax_ref[] = Float32(0); vm_ref[] = Float32(0)
    end

    ctkflg_ref[] = vn_ref[] > Float32(0)
    if vn_ref[] <= Float32(0); vn_ref[] = Float32(0); end
    if vm_ref[] <= Float32(0); vm_ref[] = Float32(0); end
    vmax_ref[] = vn_ref[]
    return nothing
end

# ---------------------------------------------------------------------------
# OBFVOL: old board foot volume (METHB=8 or variant special)
# ---------------------------------------------------------------------------
function OBFVOL(bbfv_ref::Ref{Float32}, ispc::Integer, d::Real, h::Real,
                tkill::Bool, bark::Real, itrnc::Integer, vmax_ref::Ref{Float32},
                lcone_ref::Ref{Bool}, btkflg_ref::Ref{Bool}, it::Integer)

    debug = DBCHK(false, "FVSVOL", Int32(6), ICYC)
    d_f = Float32(d); h_f = Float32(h)
    bbfv_ref[] = Float32(0); btkflg_ref[] = false

    if VARACD == "AK"
        if d_f >= Float32(9) && h_f > Float32(40)
            vvn_r = Ref(Float32(0)); bbf_r = Ref(Float32(0))
            FVSOLDGRO(Int32(ispc), vvn_r, d_f, h_f, bbf_r)
            bbfv_ref[] = bbf_r[]
        end
    elseif VARACD == "CR"
        HANNBAREBF(bbfv_ref, Int32(ispc), d_f, h_f, vmax_ref[], btkflg_ref)
    elseif VARACD == "NC"
        itd = Int(round(BFTOPD[ispc] + Float32(0.5)))
        if itd > 100; itd = 100; end
        bv_r = Ref(Float32(0))
        LOGS(d_f, h_f, Int32(itd), Int32(itd), DBHMIN[ispc], BFMIND[ispc],
             Int32(ispc), BFSTMP[ispc], bv_r, Int32(JOSTND))
        bbfv_ref[] = bv_r[]
    elseif VARACD == "CS" || VARACD == "LS" || VARACD == "NE"
        bbfv_ref[] = Float32(0)
        if it > 0 && d_f >= BFMIND[ispc] && IMC[it] <= 1
            TWIGBF(Int32(ispc), h_f, d_f, vmax_ref[], bbfv_ref)
        end
    else
        bbfv_ref[] = Float32(0)
    end

    btkflg_ref[] = bbfv_ref[] > Float32(0)
    if bbfv_ref[] <= Float32(0); bbfv_ref[] = Float32(0); end
    return nothing
end

# ---------------------------------------------------------------------------
# GETEQN: return volume equation IDs and top DIB diameters
# ---------------------------------------------------------------------------
function GETEQN(ispc::Integer, d::Real, h::Real,
                eqnc_ref::Ref{String}, eqnb_ref::Ref{String},
                tdibc_ref::Ref{Float32}, tdibb_ref::Ref{Float32})
    eqnc_ref[] = VEQNNC[ispc]
    eqnb_ref[] = VEQNNB[ispc]
    tdibc_ref[] = TOPD[ispc]  * BRATIO(Int32(ispc), Float32(d), Float32(h))
    tdibb_ref[] = BFTOPD[ispc] * BRATIO(Int32(ispc), Float32(d), Float32(h))
    return nothing
end

# Stubs for variant-specific volume functions not yet translated
FVSBRUCEDEMARS(vn,vm,vmax,d,h,sp,bk,lc,cf)       = nothing
FVSHANNBARE(vn,vm,vmax,sp,d,h,cf)                 = nothing
HANNBAREBF(bbfv,sp,d,h,vmax,btf)                  = nothing
FVSSIERRALOG(vn,vm,vmax,sp,d,h,bk,lc,cf)         = nothing
FVSOLDGRO(sp,vvn,d,h,bbf)                         = nothing
LOGS(d,h,itd1,itd2,dbhmin,bfmind,sp,bfstmp,bv,jo) = nothing
TWIGCF(sp,h,d,vn,vm,it)                           = nothing
TWIGBF(sp,h,d,vmax,bbfv)                          = nothing
