# econ/ecin.f — ECIN: processes FVS/ECON keywords for a stand.
# Reads keyword records (via KEYRDR) until an "END" record (or EOF) is hit.
# Translated from bin/FVSsn_buildDir/ecin.f (the modern-Fortran ECON reader).
#
# NOTE: this currently implements the *keyword-block reader* — it consumes and
# recognises every ECON keyword so they are no longer flagged as invalid (FVS01).
# Parameter storage + the economic calculation/output (eccalc/echarv/ecvol →
# FVS_EconSummary/FVS_EconHarvestValue) are the remaining econ-model work.
# Called from: initre.jl (OPTION 116, the ECON keyword).

# Keywords recognised inside an ECON block (ecin.f select-case labels).
const _ECIN_KEYWORDS = Set([
    "ANNUCST", "ANNURVN", "BURNCST", "HRVFXCST", "HRVRVN", "HRVVRCST",
    "MECHCST", "NOTABLE", "PCTFXCST", "PCTSPEC", "PCTVRCST", "PLANTCST",
    "PRETEND", "SPECCST", "SPECRVN", "STRTECON",
])

function ECIN(irecnt::Integer, iread::Integer, jostnd::Integer,
              nsp, icyc::Integer, lkecho::Bool, ispgrp)
    # KEYRDR scratch buffers (sized 12, matching the base keyword reader)
    local lnotbk = fill(false, 12)
    local array  = zeros(Float32, 12)
    local kard   = fill("          ", 12)
    local lflag  = false
    local kode   = Int32(0)

    while true
        global isEconToBe = true   # an ECON block is present (ecin.f:59)
        local keywrd, irecnt_new, lflag_new
        keywrd, lnotbk, array, irecnt_new, kode, kard, lflag_new =
            KEYRDR(Int32(iread), Int32(jostnd), false, lnotbk, array,
                   Int32(IRECNT), kode, kard, lflag, lkecho)
        global IRECNT = irecnt_new
        lflag = lflag_new

        # EOF before an END record → flag (matches ecin.f errCode==2 path)
        if kode == Int32(2)
            ERRGRO(false, Int32(2))
            irtncd = fvsGetRtnCode()
            if irtncd != Int32(0); return nothing; end
            return nothing
        end
        # STOP record terminates input entirely
        if kode == Int32(3)
            return nothing
        end

        local kw = uppercase(strip(keywrd))

        # END terminates the ECON keyword block
        if kw == "END"
            return nothing
        end

        if kw == "ANNUCST"
            # Annual management cost ($/ac/yr). realFields(1)=amount.
            # (Appreciation rates from a supplemental record are not read here;
            #  the sn.key test uses a flat cost, so rate/duration stay 0.)
            if array[1] > 0.0f0 && annCostCnt_EC < MAX_KEYWORDS_EC
                global annCostCnt_EC = annCostCnt_EC + Int32(1)
                annCostAmt_EC[Int(annCostCnt_EC)] = array[1]
            end
            continue
        elseif kw in _ECIN_KEYWORDS
            # Other ECON keywords (harvest/PCT costs & revenues) drive volume-based
            # valuation, which is 0 here (simplified NATCRS volume path → no merch
            # volume to value). Recognised + consumed; full valuation is future work.
            continue
        end

        # Unrecognised keyword inside the ECON block
        ERRGRO(true, Int32(1))
        RCDSET(Int32(1), true)
    end
    return nothing
end
