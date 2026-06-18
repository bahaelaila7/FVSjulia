# db_compare.jl — compare two FVS SQLite output databases without the sqlite3 CLI.
#
# Compares: (1) which tables exist, (2) per-table row counts, (3) per-column
# values. Rows are aligned as a sorted multiset (coarse 3-sig-fig sort key) so
# per-run-varying columns (CaseID UUID, timestamps) and row ORDER don't cause
# false diffs; values are then compared with a relative+absolute tolerance that
# absorbs Float32 cross-compiler rounding noise.
#
# Usage:  julia --project db_compare.jl <julia.db> <fortran.db> [rtol] [atol]
# Exit:   0 if every shared table matches (presence + counts + values), else 1.

using SQLite, DBInterface

# Columns that legitimately differ between two runs — excluded from value diffs.
const SKIP_COLS = Set(["CaseID", "CreationDate", "TimeStamp", "KeywordFile",
                       "FVSVersion", "RunTitle", "RunDateTime"])

_tables(db) = (s = Set{String}();
    for r in DBInterface.execute(db, "SELECT name FROM sqlite_master WHERE type='table' AND name LIKE 'FVS_%'")
        push!(s, r.name)
    end; s)

function _columns(db, tbl)
    c = String[]
    for r in DBInterface.execute(db, "PRAGMA table_info(\"$tbl\")"); push!(c, String(r.name)); end
    c
end

_count(db, tbl) = (n = 0; for r in DBInterface.execute(db, "SELECT count(*) AS n FROM \"$tbl\""); n = r.n; end; Int(n))

# Normalize a raw cell to Float64 / Int / String (nulls → "").
function _cell(x)
    (x === missing || x === nothing) && return ""
    x isa AbstractFloat && return isfinite(x) ? Float64(x) : 0.0
    x isa Integer && return Int(x)
    return strip(string(x))
end

# Coarse sort key (floats → 3 sig figs) so rows matching within noise align,
# while genuinely-different rows sort apart.
function _sortkey(v)
    io = IOBuffer()
    for x in v
        x isa AbstractFloat ? print(io, x == 0 ? "0" : round(x, sigdigits=3), "|") :
                              print(io, x, "|")
    end
    String(take!(io))
end

function _rows(db, tbl, cols)
    sel = join("\"" .* cols .* "\"", ",")
    out = Vector{Vector{Any}}()
    for r in DBInterface.execute(db, "SELECT $sel FROM \"$tbl\"")
        push!(out, Any[_cell(getproperty(r, Symbol(c))) for c in cols])
    end
    sort!(out, by = _sortkey)
    out
end

# Numeric view of a cell (numbers as-is, null/"" as 0.0, other text → nothing).
_num(x) = x isa Number ? Float64(x) : (x == "" ? 0.0 : nothing)

# Cell equality: numeric (incl. null↔0) compared with Float32-noise tolerance;
# anything else compared exactly.
function _eq(a, b, rtol, atol)
    na = _num(a); nb = _num(b)
    (na !== nothing && nb !== nothing) && return isapprox(na, nb; rtol=rtol, atol=atol)
    return a == b
end

function compare(jlpath::AbstractString, ftpath::AbstractString;
                 rtol::Float64=1e-3, atol::Float64=0.05)
    jl = SQLite.DB(jlpath); ft = SQLite.DB(ftpath)
    jt = _tables(jl); ftn = _tables(ft)

    only_ft = sort(collect(setdiff(ftn, jt)))
    only_jl = sort(collect(setdiff(jt, ftn)))
    shared  = sort(collect(intersect(jt, ftn)))

    println("Tables: julia=$(length(jt)) fortran=$(length(ftn)) shared=$(length(shared))")
    isempty(only_ft) || println("  MISSING in julia : ", join(only_ft, ", "))
    isempty(only_jl) || println("  EXTRA   in julia : ", join(only_jl, ", "))

    nok = 0; nbad = 0
    for t in shared
        cj = Set(_columns(jl, t)); cf = _columns(ft, t)
        cols = [c for c in cf if c in cj && !(c in SKIP_COLS)]
        jc = _count(jl, t); fc = _count(ft, t)
        if jc != fc
            println("  ✗ $(rpad(t,22)) rows julia=$jc fortran=$fc")
            nbad += 1; continue
        end
        jr = _rows(jl, t, cols); fr = _rows(ft, t, cols)
        # Multiset match: bucket Fortran rows by their STABLE (non-float) columns
        # so Float32 noise in any column can't shift a row out of its bucket, then
        # greedily pair each Julia row to a tolerance-equal Fortran row in its bucket.
        stable = [k for k in 1:length(cols) if !any(r -> _cell(r[k]) isa AbstractFloat, jr)]
        bkey(row) = join((string(row[k]) for k in stable), "|")
        buckets = Dict{String,Vector{Int}}()
        for (i, row) in enumerate(fr); push!(get!(buckets, bkey(row), Int[]), i); end
        matched = falses(length(fr))
        firstbad = 0; ndiff = 0
        for (j, jrow) in enumerate(jr)
            found = false
            for idx in get(buckets, bkey(jrow), Int[])
                if !matched[idx] && all(k -> _eq(jrow[k], fr[idx][k], rtol, atol), 1:length(cols))
                    matched[idx] = true; found = true; break
                end
            end
            found || (ndiff += 1; firstbad == 0 && (firstbad = j))
        end
        if ndiff == 0
            println("  ✓ $(rpad(t,22)) rows=$jc values match (rtol $rtol)")
            nok += 1
        else
            # Identify which column most often drives the mismatch (diagnostic)
            cand = get(buckets, bkey(jr[firstbad]), Int[])
            badcols = String[]
            if !isempty(cand)
                idx = cand[1]
                badcols = [cols[k] for k in 1:length(cols)
                           if !_eq(jr[firstbad][k], fr[idx][k], rtol, atol)]
            end
            println("  ✗ $(rpad(t,22)) rows=$jc but $ndiff row(s) unmatched",
                    isempty(badcols) ? "" : "  (likely cols: $(join(badcols, ", ")))")
            nbad += 1
        end
    end
    ok = isempty(only_ft) && nbad == 0
    println("\nRESULT: $nok table(s) match, $nbad differ, $(length(only_ft)) missing  => ",
            ok ? "PASS" : "FAIL")
    return ok
end

if abspath(PROGRAM_FILE) == @__FILE__
    length(ARGS) >= 2 || (println(stderr, "usage: db_compare.jl <julia.db> <fortran.db> [rtol] [atol]"); exit(2))
    rtol = length(ARGS) >= 3 ? parse(Float64, ARGS[3]) : 1e-3
    atol = length(ARGS) >= 4 ? parse(Float64, ARGS[4]) : 0.05
    exit(compare(ARGS[1], ARGS[2]; rtol=rtol, atol=atol) ? 0 : 1)
end
