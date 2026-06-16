# extensions/fire/fire.jl — Fire and Fuels Extension (FFE)
# Translated from: fire/*.f (~60 files)
# Status: in progress — fmcblk, fminit, fmvinit translated; remainder stubbed in extstubs.jl

include("fmcblk.jl")    # BLOCK DATA FMCBLK: initialize FAPROP + BIOGRP
include("fmvinit.jl")   # FMVINIT: SN-variant fire model species init
include("fminit.jl")    # FMINIT + FMATV/FMSATV/FMLNKD: fire model init
include("fmmain.jl")    # FMMAIN: per-cycle fire driver (calls FMCBA/FMBURN/FMSNAG/FMCWD etc.)
include("fmoldc.jl")    # FMOLDC: record crown size for next-cycle litterfall
include("fmsdit.jl")    # FMSDIT: fire stand data init each cycle (called from GRINCR)
include("fmkill.jl")    # FMKILL: fire mortality → FVS mortality rates + snag model
include("fmcadd.jl")    # FMCADD: annual litterfall, crown breakage, CWD2B processing
include("fmsnag.jl")    # FMSNAG: annual snag dynamics (fall, height loss, hard→soft)
include("fmcba.jl")     # FMCBA + SNGCOE: live/dead fuel init + cover type + percent cover
include("fmtret.jl")    # FMTRET: fuel treatment (pile burn) + FMFMOV: FUELMOVE keyword
include("fmcwd.jl")     # FMCWD: annual CWD decay; CWD1/CWD2: fallen/broken snag → CWD; CWD3: cut tree → CWD
include("fmburn.jl")    # FMBURN: fire behavior + effects driver (SIMFIRE/FLAMEADJ/MOISTURE keywords)
include("fmssee.jl")    # FMSSEE: record new-snag height ranges + density by species+DBH class
include("fmsnft.jl")    # FMSNFT: FFE forest type (1-9) from FIA forest type code + composition
include("fmsfall.jl")   # FMSFALL: snag fall rate (post-burn exponential + normal proportional)
include("fmsngdk.jl")   # FMSNGDK: years since death for snag to become soft (by variant)
include("fmsnght.jl")   # FMSNGHT: snag height loss by top breakage (variant-specific)
include("fmcrow.jl")    # FMCROW: crown component weights (foliage + 5 woody sizes) via FMCROWE
include("fmcfmd.jl")    # FMCFMD: SN fuel model selector (14-class scheme) via FMDYN
include("fmdyn.jl")     # FMDYN + FMCHKFWT: dynamic fuel model weight interpolation
include("fmgfmv.jl")    # FMGFMV: load fuel model params into ND/NL/FWG/MPS/DEPTH/MEXT
include("fmcrowe.jl")   # FMCROWE: crown component weights (Jenkins/Loomis equations)
include("fmevmon.jl")   # FMEVMON entry points: FMEVFLM/FMEVMRT/FMEVFMD/FMEVCWD/FMEVSNG/etc.
include("fmsadd.jl")    # FMSADD: add new snags to snag list by species+DBH+height class
include("fmmois.jl")    # FMMOIS: preset SN moisture levels (Terrell & Vickers values)
include("fmfint.jl")    # FMFINT: BEHAVE Rothermel fire spread rate and intensity
include("fmcfir.jl")    # FMCFIR: crown fire type, torching/crowning indices
include("fmcons.jl")    # FMCONS: fuel consumption, smoke production, mineral soil exposure
include("fmeff.jl")     # FMEFF: per-tree fire mortality probability + crown material fate
include("fmfout.jl")    # FMFOUT: burn conditions, fuel consumption, mortality reports
include("fmcbio.jl")    # FMCBIO: Jenkins biomass for aboveground/merchantable/root
include("fmscro.jl")    # FMSCRO: crown material fall schedule → CWD2B/CWD2B2 future pools
include("fmbrkt.jl")    # FMBRKT: SN bark thickness for fire mortality (ISP=5: Harmon eq.)
include("fmsvol.jl")    # FMSVOL + FMSVL2: snag volume via NATCRS/OCFVOL/CFVOL dispatch
include("fmr6htls.jl")  # FMR6HTLS: R6 snag height loss by species group (PN/WC/BM/EC/OP)
include("fmr6sdcy.jl")  # FMR6SDCY: R6 snag hard→soft decay time (PN/WC/EC/BM/SO/AK)
include("fmhide.jl")    # FMHIDE: debug snag volume + CWD output (when JCOUT > 0)
include("fmtdel.jl")    # FMTDEL: copy fire tree arrays on tree deletion
include("fmtrip.jl")    # FMTRIP: copy/scale fire tree arrays on tree tripling
include("fmprun.jl")    # FMPRUN: add pruned crown material to CWD pools
include("fmssum.jl")    # FMSSUM: snag summary report at cycle boundaries
include("fmsoilheat.jl") # FMSOILHEAT: FOFEM soil heating interface (fm_fofem stub)
include("fmusrfm.jl")   # FMUSRFM: process FUELMODL/FUELTRET/FIRECALC keywords
include("fmcmpr.jl")    # FMCMPR: compress fire tree arrays (weighted-avg per compression class)
include("fmsalv.jl")    # FMSALV: remove snags per SALVAGE/SALVSP keywords → CWDCUT
include("fmscut.jl")    # FMSCUT: add cut-tree crowns/downed snags to CWD pools before CUTS
include("fmsout.jl")    # FMSOUT: snag list report (density/height/volume by species/age/DBH)
include("fmcrbout.jl")  # FMCRBOUT: stand carbon report (11 pools, Jenkins or FFE method)
include("fmchrvout.jl") # FMCHRVOUT: harvested products carbon report (6 fate indicators)
include("fmppput.jl")  # FMPPPUT: stop/restart PUT — serialize fire state to WK3 buffer
include("fmppget.jl")  # FMPPGET: stop/restart GET — deserialize fire state from WK3 buffer
include("fmdout.jl")   # FMDOUT: fuels/debris output (all-fuels + down wood volume + cover)
include("fmcfmd2.jl")  # FMCFMD2: departure-index dynamic fuel model selection; FMCFMD3: wrapper
include("fmpocr.jl")   # FMPOCR: crown base height (ACTCBH) + crown bulk density (CBD)
include("fmpofl.jl")   # FMPOFL: potential fire report; FMPOFL_FMPTRH: torching prob; FMPOFL_NPROB: normal CDF
include("fmphotocode.jl") # FMPHOTOCODE: photo-series char→integer code lookup tables (32 refs)
include("fmphotoval.jl")  # FMPHOTOVAL: photo-series tons/acre fuel load tables (REF1-REF32, 32 refs)
include("fmin.jl")        # FMIN: fire extension keyword processor (54 keywords); FMKEY, FMKEYDMP, FMKEYRDR
include("fmsvtobj.jl")    # FMSVTOBJ: snapshot SVS objects + convert snag status for fire
include("fmsvsync.jl")    # FMSVSYNC: sync fire-model snag counts with SVS objects
include("fmsvtree.jl")    # FMSVTREE: draw per-tree crown flame objects to SVS file
include("fmsvfl.jl")      # FMSVFL + FMGETFL: ground fire line + flame objects to SVS file
include("fmsvout.jl")     # FMSVOUT: fire SVS animation output driver (NFMSVPX frames)
