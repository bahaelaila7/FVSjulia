# base/extstubs.jl — No-op stubs for extension functions not yet translated.
# These allow the core simulation to compile while Phase 3 (extensions) is pending.
# Extensions covered: Fire/FFE, Pest models (mistletoe, blister rust, root disease,
# bark beetle, budworm), Economics, Cover model, SVS visualization, DBS output,
# Establishment, and miscellaneous base helpers.

# ---------------------------------------------------------------------------
# Damage processing hooks (called from DAMPRO for each tree record)
# Extensions register their damage codes here; all no-ops until translated.
# ---------------------------------------------------------------------------
function MISDAM(itree::Integer, icodes::AbstractVector); return nothing; end  # mistletoe
function RDDAM(itree::Integer, icodes::AbstractVector);  return nothing; end  # root disease
function TMDAM(itree::Integer, icodes::AbstractVector);  return nothing; end  # tussock moth
function MPBDAM(itree::Integer, icodes::AbstractVector); return nothing; end  # mountain pine beetle
function DFBDAM(itree::Integer, icodes::AbstractVector); return nothing; end  # Douglas-fir beetle
function BRDAM(itree::Integer, icodes::AbstractVector);  return nothing; end  # blister rust
function BMDAM(itree::Integer, icodes::AbstractVector);  return nothing; end  # bark/misc

# ---------------------------------------------------------------------------
# Mistletoe extension (mistoe/)
# ---------------------------------------------------------------------------
function MISTOE(); return nothing; end
function MISGET(irec::Integer, idmr_ref::Ref{Int32}); idmr_ref[] = Int32(0); return nothing; end
function MISPUT(irec::Integer, idmr::Integer); return nothing; end
function MISCPF(args...); return nothing; end

# ---------------------------------------------------------------------------
# Western root disease (wrd/)
# ---------------------------------------------------------------------------
function RDTDEL(ivac::Integer, irec::Integer); return nothing; end
function RDTREG(); return nothing; end

# ---------------------------------------------------------------------------
# Blister rust (wpbr/)
# ---------------------------------------------------------------------------
function BRTDEL(ivac::Integer, irec::Integer); return nothing; end
function BRTREG(); return nothing; end

# ---------------------------------------------------------------------------
# Fire/FFE extension (fire/)
# ---------------------------------------------------------------------------
# FMMAIN implemented in extensions/fire/fmmain.jl
# Fire sub-routines called from FMMAIN (stubs until translated)
# FMCBA/SNGCOE implemented in extensions/fire/fmcba.jl (stub removed)
# FMBURN implemented in extensions/fire/fmburn.jl
# FMCFMD implemented in extensions/fire/fmcfmd.jl
# FMCFIR/FMEFF/FMFINT/FMFOUT/FMCONS/FMMOIS → extensions/fire/ (implemented)
# FMSOILHEAT → extensions/fire/fmsoilheat.jl
# FMBURN implemented in extensions/fire/fmburn.jl (stub removed)
# FMTRET implemented in extensions/fire/fmtret.jl
# FMFMOV implemented in extensions/fire/fmtret.jl
# FMBRKT → extensions/fire/fmbrkt.jl
# FMSVTOBJ → extensions/fire/fmsvtobj.jl
# FMSVOUT  → extensions/fire/fmsvout.jl
# FMGFMV → extensions/fire/fmgfmv.jl
# FMSCRO → extensions/fire/fmscro.jl
# FMCWD + CWD1/CWD2/CWD3 implemented in extensions/fire/fmcwd.jl
# FMSVL2 → extensions/fire/fmsvol.jl
# FMSVOL → extensions/fire/fmsvol.jl
# FMCBIO → extensions/fire/fmcbio.jl
# FMUSRFM → extensions/fire/fmusrfm.jl
# FMSOUT → extensions/fire/fmsout.jl
# FMSSUM → extensions/fire/fmssum.jl
# FMPOCR → extensions/fire/fmpocr.jl
# FMCFMD2 → extensions/fire/fmcfmd2.jl
# FMCFMD3 → extensions/fire/fmcfmd2.jl
# FMPOFL → extensions/fire/fmpofl.jl
# FMDOUT → extensions/fire/fmdout.jl
# FMCRBOUT  → extensions/fire/fmcrbout.jl
# FMCHRVOUT → extensions/fire/fmchrvout.jl
# FMSNAG → extensions/fire/fmsnag.jl
# FMCWD implemented in extensions/fire/fmcwd.jl
# FMSVSYNC → extensions/fire/fmsvsync.jl
# FMSVFL + FMGETFL → extensions/fire/fmsvfl.jl
# FMSVTREE → extensions/fire/fmsvtree.jl
# FMCADD implemented in extensions/fire/fmcadd.jl
# FMOLDC implemented in extensions/fire/fmoldc.jl
# FMKILL implemented in extensions/fire/fmkill.jl
# FMSDIT implemented in extensions/fire/fmsdit.jl
# FMCROW implemented in extensions/fire/fmcrow.jl
# FMSADD → extensions/fire/fmsadd.jl
# FMSNAG implemented in extensions/fire/fmsnag.jl
# FMSFALL implemented in extensions/fire/fmsfall.jl
# FMSNGHT implemented in extensions/fire/fmsnght.jl
# FMSNGDK implemented in extensions/fire/fmsngdk.jl
# CWD1/CWD2/CWD3 implemented in extensions/fire/fmcwd.jl (entry points of FMCWD)
# FMCBA implemented in extensions/fire/fmcba.jl
# FMSNFT implemented in extensions/fire/fmsnft.jl
# Stubs for functions called by the above implementations:
# FMCROWE → extensions/fire/fmcrowe.jl
# FMR6HTLS → extensions/fire/fmr6htls.jl
# FMR6SDCY → extensions/fire/fmr6sdcy.jl
# FMDYN → extensions/fire/fmdyn.jl
# FMPHOTOVAL → extensions/fire/fmphotoval.jl
# FMPRUN → extensions/fire/fmprun.jl
# FMSALV → extensions/fire/fmsalv.jl
# FMSCUT → extensions/fire/fmscut.jl
# SVSALV: remove snags from SVS object list during salvage (SVS not yet translated)
function SVSALV(iyr::Integer, mindbh::Real, maxdbh::Real, maxage::Real,
                oksoft::Integer, prop::Real, proplv::Real)
    return nothing
end
# FMTREM → extensions/fire/fmevmon.jl
# FMTDEL → extensions/fire/fmtdel.jl
# FMEVMSN → extensions/fire/fmevmon.jl
# FMATV / FMSATV implemented in extensions/fire/fminit.jl

# Fire event monitor functions → extensions/fire/fmevmon.jl:
# FMEVCWD, FMEVSNG, FMEVFLM, FMEVMRT, FMEVFMD, FMEVSAL, FMEVTBM
# FMEVCARB, FMEVSRT, FMEVRIN, FMEVMSN, FMEVTYP, FMEVLSF, FMEVTBM, FMDWD
# FMEVTYP → extensions/fire/fmevmon.jl
# FMEVLSF → extensions/fire/fmevmon.jl
# FMDWD   → extensions/fire/fmevmon.jl

# Climate extension viability query
function CLSPVIAB(isp::Integer, rval_ref::Ref{Float32}, irc_ref::Ref{Int32})
    rval_ref[] = Float32(0); irc_ref[] = Int32(1); return nothing; end

# Stop/restart extension helpers (PUTSTD/GETSTD parallel processing stubs)
# CVPUT has 5 args in putstd.f: (WK3, IPNT, ILIMIT, ICYC, ITRN)
function CVPUT(wk3::AbstractVector{Float32}, ipnt_ref::Ref{Int32}, ilimit::Integer, icyc::Integer, itrn::Integer); return nothing; end
function CVGET(wk3::AbstractVector{Float32}, ipnt_ref::Ref{Int32}, ilimit::Integer); return nothing; end
# MSPPPT: mistletoe stop/restart put (different from MSPPPUT)
function MSPPPT(wk3::AbstractVector{Float32}, ipnt_ref::Ref{Int32}, ilimit::Integer); return nothing; end
function CLACTV(lclm_ref::Ref{Bool}); lclm_ref[] = false; return nothing; end
function CLSETACTV(lclm::Bool); return nothing; end
function CLPUT(wk3::AbstractVector{Float32}, ipnt_ref::Ref{Int32}, ilimit::Integer); return nothing; end
function CLGET(wk3::AbstractVector{Float32}, ipnt_ref::Ref{Int32}, ilimit::Integer); return nothing; end
function CLGMULT(treemult::AbstractVector{Float32}); return nothing; end   # climate growth multiplier
function CLMORTS(); return nothing; end                                      # climate mortality adj
function MISACT(lmored_ref::Ref{Bool}); lmored_ref[] = false; return nothing; end
function MSPPPUT(wk3::AbstractVector{Float32}, ipnt_ref::Ref{Int32}, ilimit::Integer); return nothing; end
function MSPPGT(wk3::AbstractVector{Float32}, ipnt_ref::Ref{Int32}, ilimit::Integer); return nothing; end
function RDPPPUT(wk3::AbstractVector{Float32}, ipnt_ref::Ref{Int32}, ilimit::Integer); return nothing; end
function RDPPGT(wk3::AbstractVector{Float32}, ipnt_ref::Ref{Int32}, ilimit::Integer); return nothing; end
# FMPPPUT/FMPPGET → extensions/fire/fmppput.jl + fmppget.jl
function ECNPUT(wk3::AbstractVector{Float32}, ipnt_ref::Ref{Int32}, ilimit::Integer); return nothing; end
function ECNGET(wk3::AbstractVector{Float32}, ipnt_ref::Ref{Int32}, ilimit::Integer); return nothing; end
# DBSPPPUT/DBSPPGET: real implementations in extensions/dbs/dbsqlite.jl (loaded later)

# ---------------------------------------------------------------------------
# Mountain pine beetle / Douglas-fir beetle / budworm (pest models)
# ---------------------------------------------------------------------------
function MPBGO(lmpbgo::Ref{Bool}); lmpbgo[] = false; return nothing; end
function MPBCUP(); return nothing; end
function DFBGO(ldfbgo::Ref{Bool}); ldfbgo[] = false; return nothing; end
function DFBDRV(); return nothing; end
function DFBWIN(ldfbgo::Ref{Bool}); return nothing; end
function BWEGO(lbwego::Ref{Bool}); lbwego[] = false; return nothing; end
function BWECUP(); return nothing; end
function BWEPPATV(l::Ref{Bool}); l[] = false; return nothing; end   # budworm pattern at value
function BWEPPGT(r1, i1, i2, i3); return nothing; end               # budworm pattern get
function BWEPPPT(r1, i1, i2, i3); return nothing; end               # budworm pattern put
function DFTMGO(ltmgo::Ref{Bool}); ltmgo[] = false; return nothing; end
function TMCOUP(); return nothing; end
# ESNUTR → real implementation in base/esnutr.jl
function CLAUESTB(); return nothing; end

# ---------------------------------------------------------------------------
# SVS visualization extension (svs/)
# ---------------------------------------------------------------------------
function SVOUT(iyr::Integer, ipass::Integer, msg::AbstractString); return nothing; end
# SVCUTS implemented in base/svcuts.jl
function SVESTB(ipass::Integer); return nothing; end
function SVMORT(ipass::Integer, wk::AbstractVector{Float32}, iyr::Integer); return nothing; end
function SVTDEL(index::AbstractVector{Int32}, ivact::Integer); return nothing; end
function SVCMP1(); return nothing; end    # zero WORK1 tracking array (SVS disabled)
function SVCMP2(itarg::Integer, isour::Integer); return nothing; end  # register tree movement
function SVCMP3(); return nothing; end

# ---------------------------------------------------------------------------
# DBS/SQLite extension (dbsqlite/) — implemented in extensions/dbs/dbsqlite.jl
# ---------------------------------------------------------------------------
# DBSINIT       → dbsqlite.jl
# DBSCLOSE      → dbsqlite.jl
# DBSCASE       → dbsqlite.jl
# DBSSUMRY2     → dbsqlite.jl
# DBSCARBBIOSUMRY → dbsqlite.jl
# DBS_FIAVBC_ATRTLS → dbsqlite.jl
# DBS_FIAVBC_CUTLST → dbsqlite.jl
# DBSSUMRY → implemented in extensions/dbs/dbsqlite.jl

# ---------------------------------------------------------------------------
# Economics extension (econ/)
# ---------------------------------------------------------------------------
function ECHARV(args...); return nothing; end
function ECOUT(); return nothing; end
function ECREMS(); return nothing; end
function ECVOLS(); return nothing; end
function ECEND(); return nothing; end
function ECLBL(); return nothing; end
# ECCALC, ECSTATUS, ECSETP → real implementations in extensions/econ/eccalc.jl

# ---------------------------------------------------------------------------
# Cover model extension (cvextension/)
# ---------------------------------------------------------------------------
function CVGO(lcvatv::Ref{Bool}); lcvatv[] = false; return nothing; end
function CVGO(::Bool); return nothing; end
function CVBROW(lactive::Bool); return nothing; end
function CVCNOP(lactive::Bool); return nothing; end
function CVOUT(); return nothing; end
function CVACTV(lactv::Ref{Bool}); lactv[] = false; return nothing; end
function CVACTV(::Bool); return nothing; end

# ---------------------------------------------------------------------------
# FVSSTD — user volume standards
# ---------------------------------------------------------------------------
function FVSSTD(args...); return nothing; end

# ---------------------------------------------------------------------------
# Prune / stump-removal helpers
# ---------------------------------------------------------------------------
# ESTUMP implemented in base/estump.jl
function BMSLSH(args...); return nothing; end
# PRTRLS, DBSTRLS, DBSATRTLS, DBSCUTS — implemented in base/prtrls.jl

# ---------------------------------------------------------------------------
# Activity scheduling helpers
# ---------------------------------------------------------------------------
function GETISPRETENDACTIVE(lprtnd_ref::Ref{Bool}); lprtnd_ref[] = false; return nothing; end
# OPSTUS implemented in base/opstus.jl

# ---------------------------------------------------------------------------
# Event monitor — algebraic expression compiler / label set operations
# (ALGCMP, ALGEVL, ALGPTG, ALGSPP, ALGKEY, ALGEXP implemented in base/algmon.jl)
# (LB1MEM, LBMEMR, LBUNIN, LBINTR, LBTRIM, LBDSET, LBSPLR, LBAGLR, LBSTRD,
#  LBGET1, RCDSET implemented in base/lbops.jl)
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# Event monitor — EVMON, EVTACT/EVTHEN/EVALSO/EVEND, EVTSTV, etc.
# Full event monitor translation pending; stubs here allow compilation.
# ---------------------------------------------------------------------------
# EVMON implemented in base/evmon.jl
# COMCUP implemented in base/comcup.jl

# EVTACT/EVTHEN/EVALSO/EVEND — implemented in base/evtact.jl
function EVTACT(); return nothing; end

# EVTSTV, EVSET4, EVUST4, EVGET4, FISHER_SN, GETORGV, DBSEVM — implemented in base/evtstv.jl
# EVAGE, EVALNK, EVCOMP, EVIF, EVPOST, EVPRED/FISHER_SN, EVUSRV — implemented in base/evmon_support.jl
# ALGEVL implemented in base/algmon.jl
# LBINTR, LBTRIM implemented in base/lbops.jl
function EVALND(args...); return nothing; end
# EVLDX implemented in base/evldx.jl
# EVKEY: find user-defined variable CTOK in CTSTV5; set NUM=500+index if found (51 lines)
function EVKEY(ctok::AbstractString, num_ref::Ref{Int32}, irc_ref::Ref{Int32})
    if ITST5 <= Int32(0)
        irc_ref[] = Int32(1); return nothing
    end
    tok = rpad(ctok, 8)[1:8]
    for i in 1:Int(ITST5)
        if tok == rpad(CTSTV5[i], 8)[1:8]
            num_ref[] = Int32(500 + i)
            irc_ref[] = Int32(0)
            return nothing
        end
    end
    num_ref[] = Int32(0)
    irc_ref[] = Int32(1)
    return nothing
end

# ---------------------------------------------------------------------------
# Stand restructuring / growth helpers
# ---------------------------------------------------------------------------
# UPDATE implemented in base/update.jl
# HABTYP implemented in sn/habtyp.jl
# HTGSTP implemented in base/htgstp.jl
# RCON implemented in base/rcon.jl
# FFERT implemented in base/ffert.jl
# REGENT / REGCON implemented in base/regent.jl
# VOLS implemented in base/vols.jl

# ---------------------------------------------------------------------------
# NVEL volume library interface (calcdia.f, vollibcs.f, volinit.f)
# These dispatch into the NVEL library; stubbed pending volume lib translation.
# ---------------------------------------------------------------------------
function CALCDIA(args...); return nothing; end
function CALCDIA2(args...); return nothing; end
function calcdib_r(args...); return nothing; end
function calcdob_r(args...); return nothing; end
function fwdbt_r(args...);   return nothing; end

# ---------------------------------------------------------------------------
# Output helpers (implemented in their own files)
# ---------------------------------------------------------------------------
# LBSPLW implemented in base/lbsplw.jl
# SUMOUT implemented in base/sumout.jl
# SUMHED implemented in base/sumhed.jl
# OPLIST implemented in base/oplist.jl

# ---------------------------------------------------------------------------
# Statistical distribution helpers (implemented in their own files)
# ---------------------------------------------------------------------------
# SPESRT implemented in base/spesrt.jl

# ---------------------------------------------------------------------------
# Uneven-age / QFA management
# ---------------------------------------------------------------------------
# CUTQFA implemented in base/cutqfa.jl
# CYCQFA implemented in base/cutqfa.jl

# TRIPLE implemented in base/triple.jl
# REASS  implemented in base/triple.jl
# FFERT  implemented in base/ffert.jl
# TMBMAS, RDMN2, RDTRP are extension stubs (stubbed in grincr.jl)

# ---------------------------------------------------------------------------
# Activity cycle setup
# ---------------------------------------------------------------------------
# OPCSET implemented in base/opcset.jl
# IAPSRT implemented in base/iapsrt.jl

# ISPGRP is a 2D Int32 array (30, 92) defined in common/contrl.jl.
# Array indexing: ISPGRP[igrp, 1] = group size; ISPGRP[igrp, 2..n+1] = species indices.
# No function wrapper needed.

# ---------------------------------------------------------------------------
# Extension keyword readers — called from INITRE for each extension keyword.
# All are no-op stubs; full translations pending.
# ---------------------------------------------------------------------------
function BMIN(args...);   ERRGRO(true, Int32(11)); return nothing; end  # westwide bark beetle read (not linked)
function BRIN(args...);   ERRGRO(true, Int32(11)); return nothing; end  # blister rust read (not linked)
function BRINIT(args...); return nothing; end   # blister rust initialize
function BWEIN(args...);  return nothing; end   # budworm read (WSBWE not linked; no ERRGRO per exbudl.f)
function BWEINT(args...); return nothing; end   # budworm initialize
function CLIN(args...);   ERRGRO(true, Int32(11)); return nothing; end  # climate read (not linked)
function CLINIT(args...); return nothing; end   # climate initialize
function CVIN(args...);   ERRGRO(true, Int32(11)); return nothing; end  # cover model read (not linked)
function CVINIT(args...); return nothing; end   # cover model initialize
# DAMPRO implemented in base/dampro.jl
# DBSCASE  → implemented in extensions/dbs/dbsqlite.jl
# DBSINIT  → implemented in extensions/dbs/dbsqlite.jl
# DBSIN  → implemented in extensions/dbs/dbsqlite.jl
function DFBIN(args...);  ERRGRO(true, Int32(11)); return nothing; end  # Douglas-fir beetle read (not linked)
function DFBINT(args...); return nothing; end   # Douglas-fir beetle initialize
function DFTMIN(args...); ERRGRO(true, Int32(11)); return nothing; end  # DFTM moth read (not linked)
function ECAVAL(args...); return nothing; end   # economics evaluation
# ECIN → real implementation in extensions/econ/ecin.jl
# ECINIT → real implementation in extensions/econ/eccalc.jl
# ESEZCR, ESINIT → real implementations in base/esinit.jl
# ESIN → real implementation in base/esin.jl
# esin.f ENTRY ESNOAU — NOAUTOES keyword: disable automatic tallies, ingrowth & sprouting
function ESNOAU(paskey::AbstractString, lkecho::Bool)
    global LAUTAL = false
    global LINGRW = false
    global LSPRUT = false
    global STOADJ = Float32(0.0)
    if lkecho
        io = get(io_units, Int32(JOSTND), stdout)
        @printf(io, "\n%-8s   TALLIES AND INGROWTH WILL NOT BE ADDED AUTOMATICALLY.\n", paskey)
        @printf(io, "            NO SPROUTING WILL BE SIMULATED.\n")
    end
    return nothing
end
# ESPLT2 → real implementation in base/esplt.jl
# FFIN implemented in base/ffin.jl
# FMIN / FMKEY / FMKEYDMP / FMKEYRDR implemented in extensions/fire/fmin.jl
# FMINIT / FMATV / FMSATV / FMLNKD implemented in extensions/fire/fminit.jl
# ISSTAG/RQSSTG/KSSTAG implemented in base/isstag.jl
# LBDSET, LBSPLR, LBAGLR implemented in base/lbops.jl
function MISIN(args...);  ERRGRO(true, Int32(11)); return nothing; end  # mistletoe read (not linked)
function MISIN0(args...); return nothing; end   # mistletoe initialize (0)
function MISINT(args...); return nothing; end   # mistletoe initialize
function MPBIN(args...);  ERRGRO(true, Int32(11)); return nothing; end  # mountain pine beetle read (not linked)
function MPBINT(args...); return nothing; end   # mountain pine beetle initialize
function ORIN(args...);   return nothing; end   # ORGANON read (exorganon.f: IF(.TRUE.)RETURN, no ERRGRO)
function RDATV(lgo::Ref{Bool}, ltee::Ref{Bool})  # root disease at-value: sets both flags false (exrd.f)
    lgo[] = false; ltee[] = false; return nothing
end
function RDIN(args...);   ERRGRO(true, Int32(11)); return nothing; end  # root disease read (not linked)
function RDINIT(args...); return nothing; end   # root disease initialize
# SDEFET implemented in base/sdefet.jl
# SDEFLN implemented in base/sdefln.jl
function RDESIN(); return nothing; end  # stub: read establishment input
# SETCUBICDFLTS implemented in base/setcubicdflts.jl
function SVINIT(args...); return nothing; end   # SVS initialize
# SVKEY implemented in base/svkey.jl
function TMINIT(args...); return nothing; end   # tussock moth initialize

# ---------------------------------------------------------------------------
# SVS animation/visualization routines (called from svcuts.jl, svout.jl, etc.)
# ---------------------------------------------------------------------------
# SVRMOV: remove trees from SVS object list after mortality/harvest
# Returns early when JSVOUT==0 (SVS disabled), just like the Fortran.
function SVRMOV(remove::AbstractVector{Float32}, iswtch::Integer,
                ssng::AbstractVector{Float32}, dsng::AbstractVector{Float32},
                ctcrwn::AbstractVector{Float32}, icuryear::Integer)
    JSVOUT == Int32(0) && return nothing
    return nothing   # full SVS not yet translated
end

# SVSNAD: create SVS snag objects; SVCWD: create SVS coarse woody debris
function SVSNAD(args...); return nothing; end
function SVSNAGE(args...); return nothing; end
function SVCWD(iyear::Integer); return nothing; end

# ---------------------------------------------------------------------------
# Establishment model (estab extension — called from ESNUTR stub)
# ---------------------------------------------------------------------------
# ESTAB → real implementation in base/estab.jl
function ESADDT(icall::Integer); return nothing; end
# ESUCKR → real implementation in base/esuckr.jl
function ESCPRS(itrgt::Integer, debug::Bool); return nothing; end
function ESFLTR(); return nothing; end  # override no-op in fvs.jl for completeness

# SSTAGE / FMSSTAGE / UPDATECCCOEF implemented in base/sstage.jl

# ---------------------------------------------------------------------------
# Forest type / stand classification helpers
# ---------------------------------------------------------------------------
# FORTYP implemented in base/fortyp.jl
# STKVAL implemented in base/stkval.jl

# ---------------------------------------------------------------------------
# Example tree / summary output helpers
# ---------------------------------------------------------------------------
# PRTEXM implemented in base/prtexm.jl

# ---------------------------------------------------------------------------
# Establishment model helpers (estb extension — strp variant)
# ---------------------------------------------------------------------------

# ESMSGS: print habitat type group header for regeneration establishment model
function ESMSGS(joregt::Integer)
    io = get(io_units, Int32(joregt), stdout)
    @printf(io, "HABITAT TYPE GROUPS USED IN THE REGENERATION ESTABLISHMENT MODEL\n\n")
    @printf(io, "GROUP   HABITAT TYPES\n")
    @printf(io, "-----   %s\n\n", "-"^34)
    return nothing
end

# ESPREP → real implementation in base/estab_helpers.jl

# ESPRIN: schedule a site prep activity from keyword input
function ESPRIN(iactk::Integer, idsdat::Integer, irecnt::Integer, keywrd::AbstractString,
                array::AbstractVector{Float32}, lnotbk::AbstractVector{Bool},
                jostnd::Integer, kard::AbstractVector)
    if !lnotbk[1]
        idt = idsdat
        idt < 0 && begin; KEYDMP(jostnd, irecnt, keywrd, array, kard); ERRGRO(true, Int32(4)); return nothing; end
    else
        idt = Int32(floor(array[1]))
        if idsdat > 0 && idt > idsdat + 19
            KEYDMP(jostnd, irecnt, keywrd, array, kard); ERRGRO(true, Int32(4)); return nothing
        end
    end
    if !(0.0f0 <= array[2] <= 100.0f0)
        KEYDMP(jostnd, irecnt, keywrd, array, kard); ERRGRO(true, Int32(4)); return nothing
    end
    kode_ref = Ref(Int32(0))
    OPNEW(kode_ref, idt, iactk, 1, array[2])
    kode_ref[] > 0 && return nothing
    io = get(io_units, Int32(jostnd), stdout)
    @printf(io, "\n%-8s   DATE/CYCLE=%5d; %% PLOTS=%6.1f\n", keywrd, idt, array[2])
    return nothing
end

# ---------------------------------------------------------------------------
# DBS/SQLite fire-model link (dbsfmlink.f)
# ---------------------------------------------------------------------------
# DBSFMLINK: pass ICANPR from FFE to DBS extension without including DBSCOM in FFE
function DBSFMLINK(i::Integer)
    global ICANPR = Int32(i)
    return nothing
end

# ---------------------------------------------------------------------------
# Fire/Crown Fire Initiation Model stubs (excfim.f ENTRY points)
# ---------------------------------------------------------------------------
function FMCANC(iyr::Integer, fmois::Integer, cftmp::AbstractString,
                canburn_ref::Ref{Int32}, ros_ref::Ref{Float32},
                intsty_ref::Ref{Float32}, fcls_ref::Ref{Int32})
    return nothing
end

function FMCFIM(iyr::Integer, fmd::Integer, uwind::Real, ibyram::Real,
                flame_ref::Ref{Int32}, canburn_ref::Ref{Int32}, ros_ref::Ref{Float32})
    return nothing
end

# ECSETP → real implementation in extensions/econ/eccalc.jl

# ---------------------------------------------------------------------------
# Volume library stubs (bark/taper functions called from NVEL)
# ---------------------------------------------------------------------------
# BRK_UP: compute bark thickness ratio DBT/DOB at a given height (deferred: volume library)
function BRK_UP(jsp::Integer, geosub::AbstractString, dbhob::Real, tht::Real,
                dbtbh::Real, htup::Real, dib::Real, dob_ref::Ref{Float32},
                dbt_ref::Ref{Float32})
    dob_ref[] = Float32(dib)
    dbt_ref[] = 0.0f0
    return nothing
end

# SF_CORR: estimate correlation of dib errors at two heights (surface-fit taper)
function SF_CORR(jsp::Integer, geosub::AbstractString, totalh::Real, hi::Real, hj::Real)
    return 0.0f0
end

# EXCFIM (outer subroutine — stub, entries handled above)
function EXCFIM(); return nothing; end

# SVCDBH: debug dump of SVS crown/DBH objects (called from svrmov, svout, svstart in debug)
function SVCDBH(remove::AbstractVector{Float32}, k::Integer); return nothing; end

# ---------------------------------------------------------------------------
# exbm.f — Westwide Pine Beetle (BM) model stubs
# ---------------------------------------------------------------------------
function BMSDIT(); return nothing; end
function BMKILL(); return nothing; end
function BMSETP(); return nothing; end
function BMDRV();  return nothing; end
function BMPPIN(iread::Integer, irecnt::Integer, jopprt::Integer)
    io = get(io_units, Int32(jopprt), stdout)
    @printf(io, "\n%-8sRECORD: %6d **NO BM \n", "", irecnt)
    ERRGRO(true, Int32(11))
    return nothing
end
function BMPPPT(wk3::AbstractVector, i1::Integer, i2::Integer); return nothing; end
function BMPPGT(wk3::AbstractVector, i1::Integer, i2::Integer); return nothing; end
function BMLNKD(lactv_ref::Ref{Bool}); lactv_ref[] = false; return nothing; end
function BMDBS(i::Integer, iout::Integer); return nothing; end
function RRATV(lactv_ref::Ref{Bool}, ltee_ref::Ref{Bool})
    lactv_ref[] = false; ltee_ref[] = false; return nothing
end
function RRPPPT(r1::AbstractVector, i1::Integer, i2::Integer); return nothing; end
function RRPPGT(r1::AbstractVector, i1::Integer, i2::Integer); return nothing; end

# ---------------------------------------------------------------------------
# exbrus.f — White Pine Blister Rust (BR) model stubs
# ---------------------------------------------------------------------------
function BRCMPR(nclas::Integer, prob::AbstractVector, ind::AbstractVector, ind1::AbstractVector)
    return nothing
end
function BRESTB(time::Real, i1::Integer, i2::Integer); return nothing; end
function BRLNKD(lactv_ref::Ref{Bool}); lactv_ref[] = false; return nothing; end
function BRDBS(i::Integer, iout::Integer); return nothing; end
function BROUT(); return nothing; end
function BRPPPT(r1::AbstractVector, i1::Integer, i2::Integer); return nothing; end
function BRPPGT(r1::AbstractVector, i1::Integer, i2::Integer); return nothing; end
function BRSETP(); return nothing; end
function BRPR();   return nothing; end
function BRROUT(); return nothing; end
function BRSOR();  return nothing; end
# BRTRIP: real no-op in base/triple.jl

# ---------------------------------------------------------------------------
# exdfb.f — Douglas-Fir Beetle (DFB) model stubs
# ---------------------------------------------------------------------------
function DFBSCH(); return nothing; end
function DFBOUT(); return nothing; end
function DFBINV(); return nothing; end
function DFBLNKD(lactv_ref::Ref{Bool}); lactv_ref[] = false; return nothing; end
function DFBDBS(i::Integer, iout::Integer); return nothing; end
function DFBPPPT(r1::AbstractVector, i1::Integer, i2::Integer); return nothing; end
function DFBPPGT(r1::AbstractVector, i1::Integer, i2::Integer); return nothing; end

# ---------------------------------------------------------------------------
# exdftm.f — Douglas-Fir Tussock Moth (DFTM) model stubs
# ---------------------------------------------------------------------------
function TMOPS(); return nothing; end
function TMBMAS(); return nothing; end
function TMHED(nplt::AbstractString, mgmid::Integer); return nothing; end
function TMLNKD(lactv_ref::Ref{Bool}); lactv_ref[] = false; return nothing; end
function TMDBS(i::Integer, iout::Integer); return nothing; end
function TMOUT(); return nothing; end
function TMPPPT(r1::AbstractVector, i1::Integer, i2::Integer); return nothing; end
function TMPPGT(r1::AbstractVector, i1::Integer, i2::Integer); return nothing; end

# ---------------------------------------------------------------------------
# exmpb.f — Mountain Pine Beetle (MPB) model stubs
# ---------------------------------------------------------------------------
function MPBOPS(); return nothing; end
function MPBHED(nplt::AbstractString, mgmid::Integer); return nothing; end
function MPBDRV(); return nothing; end
function MPBKEY(key_ref::Ref{Int32}, keywrd_ref::Ref{String})
    keywrd_ref[] = "*NO MPB "; return nothing
end
function MPBLNKD(lactv_ref::Ref{Bool}); lactv_ref[] = false; return nothing; end
function MPBDBS(i::Integer, iout::Integer); return nothing; end
function MPBOUT(); return nothing; end
function MPSDLP(); return nothing; end
function MPBPPPT(r1::AbstractVector, i1::Integer, i2::Integer); return nothing; end
function MPBPPGT(r1::AbstractVector, i1::Integer, i2::Integer); return nothing; end

# ---------------------------------------------------------------------------
# exmist.f — Dwarf Mistletoe model stubs (remaining ENTRY points)
# ---------------------------------------------------------------------------
function MISCNT(mspcnt::AbstractVector{Int32})
    for i in 1:Int(MAXSP); mspcnt[i] = Int32(0); end
    return nothing
end
function MISINF(dmflag::Ref{Bool}); return nothing; end          # no-op: dmflag unchanged
function MISMRT(mflag::Ref{Bool}); return nothing; end           # no-op: mflag unchanged
function MISPRT(); return nothing; end
function MISPUTZ(itree::Integer, idmr1::Integer); return nothing; end
function MISRAN(iarray::AbstractVector{Int32}, isize::Integer); return nothing; end

# ---------------------------------------------------------------------------
# exrd.f — Western Root Disease model stubs (remaining ENTRY points)
# ---------------------------------------------------------------------------
function RDTRES(itn1::Integer, itn2::Integer); return nothing; end
function RDTRP(ltr_ref::Ref{Bool}); return nothing; end
function RDROUT(); return nothing; end
function RDPRIN(i::Integer); return nothing; end
function RDCMPR(i1::Integer, r1::AbstractVector, i2::AbstractVector, i3::AbstractVector)
    return nothing
end
function RDSTR(ii1::Integer, rr1::Real, rr2::Real); return nothing; end
function RDESCP(ii1::Integer, ii2_ref::Ref{Int32}); ii2_ref[] = Int32(ii1); return nothing; end
function RDESTB(i1::Integer, r1::AbstractVector); return nothing; end
function RDMN1(ii::Integer); return nothing; end
function RDMN2(old::Real); return nothing; end
function RDPR(); return nothing; end
function RDPPATV(ldum::Ref{Bool}); return nothing; end
function RDPPPT(wk3::AbstractVector, ipnt::Integer, ilimit::Integer); return nothing; end

# ---------------------------------------------------------------------------
# Establishment model — remaining helpers (ESTB/STRP extension)
# ---------------------------------------------------------------------------
# ESRANN: random number generator using ESRNCM state (Park-Miller, mod 2^31-1)
function ESRANN(sel_ref::Ref{Float32})
    global ESS0, ESS1
    ESS1 = mod(16807.0 * ESS0, 2147483647.0)
    sel_ref[] = Float32(ESS1 / 2147483648.0)
    ESS0 = ESS1
    return nothing
end
function ESRNSD(lset::Bool, seed_ref::Ref{Float32})
    global ESS0, ESSS
    if !lset
        seed_ref[] = Float32(ESSS)
        ESS0 = Float64(ESSS)
        return nothing
    end
    s = seed_ref[]
    if mod(s, 2.0f0) == 0.0f0; s += 1.0f0; end
    ESS0 = Float64(s)
    return nothing
end

# ESOUT: copy establishment output file to JOSTND (no-op when IPRINT==0 or stubbed)
function ESOUT(lfg_ref::Ref{Bool}); return nothing; end

# ESETPR, ESGENT, ESSUBH, ESTIME → real implementations in base/estab_helpers.jl

# ESPLT1 → real implementation in base/esplt.jl

# ---------------------------------------------------------------------------
# ORGANON extension stub — ORGTAB
# ---------------------------------------------------------------------------
function ORGTAB(jostnd::Integer, imodty::Integer); return nothing; end

# ---------------------------------------------------------------------------
# Volume library stubs (deferred)
# ---------------------------------------------------------------------------
# VOLUMELIB: main entry into volume library (NVEL); deferred — returns zeros.
function VOLUMELIB(args...);    return nothing; end
function DVEST(args...);        return nothing; end   # direct volume estimator
function GROSSVOL(args...);     return nothing; end   # gross volume by equation
function SCALEF(args...);       return nothing; end   # scaling factor
function VOLINIT(args...);      return nothing; end   # volume library initialization
function VOLINIT2(args...);     return nothing; end   # volume library init (v2)
function VOLLIB09(args...);     return nothing; end   # volume library v09
function VOLLIBCS(args...);     return nothing; end   # volume lib cross-section
function VOLLIBFIA(args...);    return nothing; end   # volume lib FIA equations
function VOLUMELIBRARY(args...); return nothing; end  # general volume library
# blmtap.f — taper/DIB equations for specific regions (deferred: volume library)
function BLMTAP(args...);  return nothing; end   # Behre's hyperbola taper
function BEHTAP(args...);  return nothing; end   # BEHTAP entry in blmtap.f
# blmvol.f — BLM/Pacific NW volume equations (deferred: volume library)
function BLMVOL(args...);  return nothing; end   # main BLM volume driver
function BLMGDIB(args...); return nothing; end   # BLM gross DIB
function BLMMLEN(args...); return nothing; end   # BLM merchantable length
function BLMTAPEQ(args...);return nothing; end   # BLM taper equation
function BLMTCUB(args...); return nothing; end   # BLM taper cubic volume
# crzbiomass.f — CRZ biomass (deferred: volume library)
function CRZBIOMASS(args...); return nothing; end
function CRZBIOMASSCS(args...); return nothing; end  # cross-section variant in vollibcs.f

# ---------------------------------------------------------------------------
# Mistletoe DBS output stubs (deferred: mistletoe model)
# ---------------------------------------------------------------------------
function DBSMIS1(args...); return nothing; end   # dbsmis.f: mistletoe tree list
function DBSMIS2(args...); return nothing; end   # dbsmis.f: mistletoe summary
function DBSMIS3(args...); return nothing; end   # dbsmis.f: mistletoe labels

# ---------------------------------------------------------------------------
# Establishment printing stub (deferred: establishment extension)
# ---------------------------------------------------------------------------
# ESSPRT/NSPREC/SPRTHT/ASSPTN → real implementations in base/essprt.jl

# ---------------------------------------------------------------------------
# Bool overloads for stubs that take Ref{Bool} but are called with Bool
# (Fortran passes LOGICAL by ref; Julia call sites sometimes use plain Bool)
# ---------------------------------------------------------------------------
CLACTV(::Bool)  = nothing
MISACT(::Bool)  = nothing
MPBGO(::Bool)   = nothing
DFBGO(::Bool)   = nothing
DFBWIN(::Bool)  = nothing
BWEGO(::Bool)   = nothing
BWEPPATV(::Bool)= nothing
DFTMGO(::Bool)  = nothing
BMLNKD(::Bool)  = nothing
RRATV(::Bool, ::Bool) = nothing
BRLNKD(::Bool)  = nothing
DFBLNKD(::Bool) = nothing
TMLNKD(::Bool)  = nothing
MPBLNKD(::Bool) = nothing
MISINF(::Bool)  = nothing
MISMRT(::Bool)  = nothing
RDTRP(::Bool)   = nothing
RDPPATV(::Bool) = nothing
ESOUT(::Bool)   = nothing
GETISPRETENDACTIVE(::Bool) = nothing
