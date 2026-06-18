# check_sndb_counts.jl — Julia-native count regression for an sn.key SQLite db.
#
# Given an already-produced snout.db, asserts each expected table is present with
# the expected row count (baseline from the Fortran snout.txt.save). No sqlite3
# CLI and no Fortran rebuild needed. (Run the sim in a SUBPROCESS first — main()
# closes the IO units, so producing the db and checking it must be separate.)
#
# Usage:  julia --project tests/check_sndb_counts.jl <snout.db>
# Exit:   0 if every expected table is present with the expected count, else 1.

using SQLite, DBInterface

# (table, expected_rows). nothing = "table must exist, any row count".
const EXPECT = [
    ("FVS_ATRTList", 952), ("FVS_Down_Wood_Cov", 10), ("FVS_Mortality", 6),
    ("FVS_BurnReport", 1), ("FVS_Down_Wood_Vol", 10), ("FVS_PotFire_East", 10),
    ("FVS_Carbon", 10), ("FVS_EconHarvestValue", 0), ("FVS_SnagSum", 10),
    ("FVS_Cases", 4), ("FVS_EconSummary", 10), ("FVS_Summary", 33),
    ("FVS_Consumption", 1), ("FVS_Fuels", 10), ("FVS_TreeList", 6971),
    ("FVS_CutList", 426), ("FVS_Hrv_Carbon", 10),
    # presence-only (in the .tables list but not count-queried by snTablesTest.sql)
    ("FVS_Error", nothing), ("FVS_PotFire_Cond", nothing),
    ("FVS_InvReference", nothing), ("FVS_Summary2", nothing),
]

function main(dbpath)
    isfile(dbpath) || (println(stderr, "db not found: $dbpath"); return 1)
    db = SQLite.DB(dbpath)
    present = Set{String}()
    for r in DBInterface.execute(db, "SELECT name FROM sqlite_master WHERE type='table'")
        push!(present, r.name)
    end
    rowcount(t) = (n = 0; for r in DBInterface.execute(db, "SELECT count(*) AS n FROM \"$t\""); n = r.n; end; Int(n))

    npass = 0; nfail = 0
    for (t, exp) in EXPECT
        if !(t in present)
            println("  x ", rpad(t, 22), " MISSING")
            nfail += 1; continue
        end
        c = rowcount(t)
        if exp === nothing || c == exp
            println("  . ", rpad(t, 22), " rows=", c)
            npass += 1
        else
            println("  x ", rpad(t, 22), " rows=", c, " (expected ", exp, ")")
            nfail += 1
        end
    end
    println("\n", npass, "/", length(EXPECT), " expectations met")
    return nfail == 0 ? 0 : 1
end

exit(main(length(ARGS) >= 1 ? ARGS[1] : error("usage: check_sndb_counts.jl <snout.db>")))
