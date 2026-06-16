# sumhed.jl — SUMHED: write summary statistics header to screen output
# Translated from: sumhed.f (112 lines, vbase)

const _SUMHED_CRMT = ("SM","SP","BP","SF","LP")

function SUMHED()
    if !LSCRN; return nothing; end

    rev_ref = Ref("          ")
    REVISE(VARACD, rev_ref)
    rev = rev_ref[]

    io = io_units[Int32(JOSCRN)]

    if VARACD == "CR"
        crmt = 1 <= Int(IMODTY) <= 5 ? _SUMHED_CRMT[Int(IMODTY)] : "??"
        @printf(io, "\n                   CR-%s FVS VARIANT -- RV:%-10s\n\n", crmt, rev)
    else
        @printf(io, "\n                   %s FVS VARIANT -- RV:%-10s\n\n", VARACD, rev)
    end

    @printf(io, "\n         STAND = %-26s  MANAGEMENT CODE = %-4s\n", NPLT, MGMID)

    title = strip(ITITLE)
    if !isempty(title)
        # Centre the title in 80 cols
        pad = max(0, (81 - length(title)) ÷ 2)
        @printf(io, "%*s%s\n", pad + length(title), title, "")
    end

    if VARACD ∈ ("CS","LS","NE","SN")
        @printf(io, "\n               SUMMARY STATISTICS (BASED ON TOTAL STAND AREA)\n")
        @printf(io, "%-76s\n", repeat("-", 76))
        @printf(io, "        START OF SIMULATION PERIOD    REMOVALS/ACRE    AFTER TREATMENT GROWTH\n")
        @printf(io, "      %-28s %-17s %-16s CU FT\n", repeat("-",28), repeat("-",17), repeat("-",16))
        @printf(io, "      TREES         TOP      MERCH TREES MERCH SAWLG         TOP      PER YR\n")
        @printf(io, "YEAR /ACRE  BA SDI  HT  QMD CU FT /ACRE CU FT BD FT  BA SDI  HT  QMD ACC MOR\n")
        @printf(io, "%-21s %-5s %-5s\n", "---- ----- --- --- --- ---- ----- ----- ----- ----- ",
            "--- --- --- ----", "--- ---")
    else
        @printf(io, "\n               SUMMARY STATISTICS (BASED ON TOTAL STAND AREA)\n")
        @printf(io, "%-76s\n", repeat("-", 76))
        @printf(io, "        START OF SIMULATION PERIOD    REMOVALS/ACRE    AFTER TREATMENT GROWTH\n")
        @printf(io, "      %-28s %-17s %-16s CU FT\n", repeat("-",28), repeat("-",17), repeat("-",16))
        @printf(io, "      TREES         TOP      TOTAL TREES TOTAL MERCH         TOP      PER YR\n")
        @printf(io, "YEAR /ACRE  BA SDI  HT  QMD CU FT /ACRE CU FT BD FT  BA SDI  HT  QMD ACC MOR\n")
        @printf(io, "%-21s %-5s %-5s\n", "---- ----- --- --- --- ---- ----- ----- ----- ----- ",
            "--- --- --- ----", "--- ---")
    end
    return nothing
end
