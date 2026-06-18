# extensions/dbs/dbsqlite.jl — DBS/SQLite database output extension
# Translated from: dbsqlite/*.f (key files: dbsinit.f, dbsclose.f, dbscase.f,
#                  dbscarbbiosumry.f, dbssumry.f, dbsstats.f)
#
# Design: The Fortran DBS uses an external FSQL3 C library with integer handles.
# Here we use SQLite.jl directly with Ref{Union{SQLite.DB, Nothing}} module globals.
# IoutDBref = -1 (Fortran) → _dbs_out_db[] === nothing (Julia)

# ---------------------------------------------------------------------------
# Module-level DB connection references (replacing FSQL3 integer handles)
# ---------------------------------------------------------------------------
const _dbs_out_db = Ref{Union{SQLite.DB, Nothing}}(nothing)
const _dbs_in_db  = Ref{Union{SQLite.DB, Nothing}}(nothing)

# ---------------------------------------------------------------------------
# Helper: check if table exists
function _dbs_table_exists(db::SQLite.DB, tablename::AbstractString)::Bool
    # Fully iterate so the cursor is reset/finalized — a half-consumed SELECT
    # leaves the stmt in SQLITE_ROW state and blocks the next COMMIT
    # ("cannot commit transaction - SQL statements in progress").
    found = false
    for _ in DBInterface.execute(db,
        "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
        [tablename])
        found = true
    end
    return found
end

# Helper: check if a column exists on a table
function _dbs_column_exists(db::SQLite.DB, tablename::AbstractString, colname::AbstractString)::Bool
    # Fully iterate the PRAGMA cursor (same SQLITE_ROW/COMMIT hazard as above).
    found = false
    for row in DBInterface.execute(db, "PRAGMA table_info($tablename)")
        if String(row.name) == colname
            found = true
        end
    end
    return found
end

# Helper: add a column only if it is missing. Avoids a "duplicate column" error
# whose unfinalized failed statement would otherwise block the next COMMIT.
function _dbs_add_column(db::SQLite.DB, tablename::AbstractString,
                         colname::AbstractString, coltype::AbstractString)
    if !_dbs_column_exists(db, tablename, colname)
        _dbs_exec(db, "ALTER TABLE $tablename ADD COLUMN $colname $coltype")
    end
    return nothing
end

# Helper: execute SQL silently (ignore return value)
function _dbs_exec(db::SQLite.DB, sql::AbstractString)
    try
        DBInterface.execute(db, sql)
    catch e
        @warn "DBS SQL error: $e\nSQL: $sql"
    end
    return nothing
end

# ---------------------------------------------------------------------------
# DBSINIT: reset all DBS control flags (translated from dbsinit.f, 114 lines)
# ---------------------------------------------------------------------------
function DBSINIT()
    global CASEID    = ""
    global ISUMARY   = Int32(0)
    global ICOMPUTE  = Int32(0)
    global IATRTLIST = Int32(0)
    global ITREELIST = Int32(0)
    global ICUTLIST  = Int32(0)
    global IVBCSUM   = Int32(0)
    global IVBCTRELST= Int32(0)
    global IVBCCUTLST= Int32(0)
    global IVBCATRLST= Int32(0)
    global IDM1      = Int32(0)
    global IDM2      = Int32(0)
    global IDM3      = Int32(0)
    global IDM5      = Int32(0)
    global IDM6      = Int32(0)
    global IPOTFIRE  = Int32(0)
    global IPOTFIREC = Int32(0)
    global IFUELS    = Int32(0)
    global ITREEIN   = Int32(0)
    global IRGIN     = Int32(0)
    global IFUELC    = Int32(0)
    global ICMRPT    = Int32(0)
    global ICHRPT    = Int32(0)
    global ICLIM     = Int32(0)
    global IBURN     = Int32(0)
    global IMORTF    = Int32(0)
    global ISSUM     = Int32(0)
    global ISDET     = Int32(0)
    global IADDCMPU  = Int32(0)
    global I_CMPU    = Int32(0)
    global ISTRCLAS  = Int32(0)
    global IBMMAIN   = Int32(0)
    global IBMBKP    = Int32(0)
    global IBMTREE   = Int32(0)
    global IBMVOL    = Int32(0)
    global ICANPR    = Int32(0)
    global ISPOUT6   = Int32(0)
    global ISPOUT17  = Int32(0)
    global ISPOUT21  = Int32(0)
    global ISPOUT23  = Int32(0)
    global ISPOUT30  = Int32(0)
    global ISPOUT31  = Int32(0)
    global IDWDVOL   = Int32(0)
    global IDWDCOV   = Int32(0)
    global IRD1      = Int32(0)
    global IRD2      = Int32(0)
    global IRD3      = Int32(0)
    global ISTATS1   = Int32(0)
    global ISTATS2   = Int32(0)
    global IREG1     = Int32(0)
    global IREG2     = Int32(0)
    global IREG3     = Int32(0)
    global IREG4     = Int32(0)
    global IREG5     = Int32(0)
    return nothing
end

# DBSACTV: returns true (DBS extension is active)
function DBSACTV(lactv_ref::Ref{Bool})
    lactv_ref[] = true
    return nothing
end

# ---------------------------------------------------------------------------
# DBSCLOSE: close output and/or input database connections (from dbsclose.f)
# ---------------------------------------------------------------------------
function DBSCLOSE(lcout::Bool, lcin::Bool)
    if lcout && _dbs_out_db[] !== nothing
        try; close(_dbs_out_db[]); catch; end
        _dbs_out_db[] = nothing
    end
    if lcin && _dbs_in_db[] !== nothing
        try; close(_dbs_in_db[]); catch; end
        _dbs_in_db[] = nothing
    end
    return nothing
end

# ---------------------------------------------------------------------------
# DBSCASE: open/configure output database (simplified from dbscase.f, 324 lines)
#
# iforsure:
#   0 = connect if any table is turned on
#   1 = connect unconditionally
#   2 = update SamplingWt and Groups in FVS_Cases
# ---------------------------------------------------------------------------
function DBSCASE(iforsure::Integer)
    # Determine if any output is requested
    any_on = ISUMARY > Int32(0) || ITREELIST > Int32(0) ||
             IVBCSUM > Int32(0) || IVBCTRELST > Int32(0) ||
             ICUTLIST > Int32(0) || IATRTLIST > Int32(0) ||
             ISTATS1 > Int32(0) || ISTATS2 > Int32(0)

    if iforsure == Int32(2) && !isempty(strip(CASEID))
        # Update SamplingWt and Groups in existing case record
        db = _dbs_out_db[]
        if db !== nothing
            slset_val = LENSLS == Int32(-1) ? "" : strip(SLSET)
            sql = @sprintf("UPDATE FVS_Cases SET SamplingWt = %g, Groups = '%s', StandID = '%s' WHERE CaseID = '%s';",
                           SAMWT, slset_val, strip(NPLT), CASEID)
            _dbs_exec(db, sql)
        end
        return nothing
    end

    if iforsure == Int32(0) && !any_on
        return nothing
    end

    # Open the database if not already open
    if _dbs_out_db[] === nothing
        dbname = isempty(strip(DSNOUT)) ? "FVSOut.db" : strip(DSNOUT)
        try
            _dbs_out_db[] = SQLite.DB(dbname)
            # Enable WAL mode for better concurrent writes
            _dbs_exec(_dbs_out_db[], "PRAGMA journal_mode=WAL;")
        catch e
            @warn "DBS: cannot open database '$dbname': $e"
            return nothing
        end
    end

    db = _dbs_out_db[]
    if db === nothing; return nothing; end

    # If this case was already written (CASEID set), don't insert a duplicate
    # row — matches dbscase.f:173 "IF (CASEID.NE.'') RETURN". Without this guard
    # DBSCASE re-inserts FVS_Cases on every per-cycle call.
    if !isempty(strip(CASEID))
        return nothing
    end
    global CASEID = UUIDGEN()

    # Create FVS_Cases table if needed
    if !_dbs_table_exists(db, "FVS_Cases")
        _dbs_exec(db, """
            CREATE TABLE FVS_Cases (
              CaseID text not null,
              StandID text,
              MgmtID text,
              InvYear int,
              Groups text,
              SamplingWt real,
              ModelType text,
              Variant text,
              FVSVersion text,
              CreationDate text,
              TimeStamp text,
              KeywordFile text
            );""")
    end

    # Insert case record
    dat_r = Ref(""); tim_r = Ref("")
    GRDTIM(dat_r, tim_r)
    dat = dat_r[]; tim = tim_r[]
    rev_r = Ref("          ")
    REVISE(VARACD, rev_r)
    variant = strip(VARACD)
    rev_str = strip(rev_r[])
    sql = @sprintf("INSERT INTO FVS_Cases (CaseID, StandID, MgmtID, InvYear, Groups, SamplingWt, ModelType, Variant, FVSVersion, CreationDate, TimeStamp, KeywordFile) VALUES ('%s','%s','%s',%d,'%s',%g,'%s','%s','%s','%s','%s','%s');",
                   CASEID, strip(NPLT), strip(MGMID), Int(IY[max(1,Int(ICYC))]),
                   "", Float64(SAMWT), "FVS", variant, "FVSjulia", dat, "$(dat)T$(tim)", strip(keywordfile))
    _dbs_exec(db, sql)
    return nothing
end

# ---------------------------------------------------------------------------
# DBSCARBBIOSUMRY: write FVS_FIAVBC_Summary rows (translated from dbscarbbiosumry.f)
#
# One or two rows per cycle: row 0 = harvested + retained; row 1 = just retained.
# Pan reads FVS_FIAVBC_Summary.AbvGrdBio — this is the primary output.
# ---------------------------------------------------------------------------
function DBSCARBBIOSUMRY()
    if IVBCSUM == Int32(0); return nothing; end
    if !LFIANVB
        ERRGRO(true, Int32(52))
        return nothing
    end

    DBSCASE(Int32(1))
    db = _dbs_out_db[]
    if db === nothing; return nothing; end

    tablename = "FVS_FIAVBC_Summary"
    if !_dbs_table_exists(db, tablename)
        _dbs_exec(db, """
            CREATE TABLE $tablename (
              CaseID text not null,
              StandID text not null,
              Year int,
              RmvCode int,
              TCuFt real, MCuFt real, SCuFt real,
              AbvGrdBio real, MerchBio real, SawBio real, FoliBio real,
              AbvGrdCarb real, MerchCarb real, SawCarb real, FoliCarb real,
              RTCuFt real, RMCuFt real, RSCuFt real,
              RAbvGrdBio real, RMerchBio real, RSawBio real, RFoliBio real,
              RAbvGrdCarb real, RMerchCarb real, RSawCarb real, RFoliCarb real
            );""")
    end

    iyear = Int(IY[ICYC])
    ihrvc = Int32(0)

    if ICYC > NCYC
        dptcuft  = Float64(OCVCUR[7]  / GROSPC)
        dpmcuft  = Float64(OMCCUR[7]  / GROSPC)
        dpscuft  = Float64(OSCCUR[7]  / GROSPC)
        dpagbio  = Float64(OAGBIOCUR[7]  / GROSPC) / 2000
        dpmrbio  = Float64(OMERBIOCUR[7] / GROSPC) / 2000
        dpcsbio  = Float64(OCSAWBIOCUR[7]/ GROSPC) / 2000
        dpflbio  = Float64(OFOLIBIO[7]   / GROSPC) / 2000
        dpabcrb  = Float64(OAGCARBCUR[7] / GROSPC) / 2000
        dpmrcrb  = Float64(OMERCARBCUR[7]/ GROSPC) / 2000
        dpcscrb  = Float64(OCSAWCARBCUR[7]/GROSPC) / 2000
        dpfolcrb = Float64(OFOLICARB[7]  / GROSPC) / 2000
    else
        dptcuft  = Float64(TSTV1[4])
        dpmcuft  = Float64(TSTV1[5])
        dpscuft  = Float64(TSTV1[20])
        dpagbio  = Float64(TSTV1[51])
        dpmrbio  = Float64(TSTV1[52])
        dpcsbio  = Float64(TSTV1[53])
        dpflbio  = Float64(TSTV1[54])
        dpabcrb  = Float64(TSTV1[55])
        dpmrcrb  = Float64(TSTV1[56])
        dpcscrb  = Float64(TSTV1[57])
        dpfolcrb = Float64(TSTV1[58])
    end

    dprtcuft = 0.0; dprmcuft = 0.0; dprscuft = 0.0
    dpragbio = 0.0; dprmrbio = 0.0; dprcsbio = 0.0
    dpragcrb = 0.0; dprmrcrb = 0.0; dprcscrb = 0.0
    dprfolbio = 0.0; dprfolcrb = 0.0

    if ICYC <= NCYC
        dprtcuft = Float64(OCVREM[7]  / GROSPC)
        dprmcuft = Float64(OMCREM[7]  / GROSPC)
        dprscuft = Float64(OSCREM[7]  / GROSPC)
        dpragbio = Float64(OAGBIOREM[7]  / GROSPC) / 2000
        dprmrbio = Float64(OMERBIOREM[7] / GROSPC) / 2000
        dprcsbio = Float64(OCSAWBIOREM[7]/ GROSPC) / 2000
        dprfolbio= Float64(OFOLIBIOREM[7]/ GROSPC) / 2000
        dpragcrb = Float64(OAGCARBREM[7] / GROSPC) / 2000
        dprmrcrb = Float64(OMERCARBREM[7]/ GROSPC) / 2000
        dprcscrb = Float64(OCSAWCARBREM[7]/GROSPC) / 2000
        dprfolcrb= Float64(OFOLICARBREM[7]/GROSPC) / 2000
        if dprtcuft > 0.0; ihrvc = Int32(1); end
    end

    caseid_s = CASEID
    standid_s = strip(NPLT)
    insert_sql = """INSERT INTO $tablename
        (CaseID,StandID,Year,RmvCode,
         TCuFt,MCuFt,SCuFt,
         AbvGrdBio,MerchBio,SawBio,FoliBio,
         AbvGrdCarb,MerchCarb,SawCarb,FoliCarb,
         RTCuFt,RMCuFt,RSCuFt,
         RAbvGrdBio,RMerchBio,RSawBio,RFoliBio,
         RAbvGrdCarb,RMerchCarb,RSawCarb,RFoliCarb)
        VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)"""

    # Insert row (with harvest if any)
    for pass in 1:2
        stmt = SQLite.Stmt(db, insert_sql)
        DBInterface.execute(stmt, [
            caseid_s, standid_s, iyear, Int(ihrvc),
            dptcuft, dpmcuft, dpscuft,
            dpagbio, dpmrbio, dpcsbio, dpflbio,
            dpabcrb, dpmrcrb, dpcscrb, dpfolcrb,
            dprtcuft, dprmcuft, dprscuft,
            dpragbio, dprmrbio, dprcsbio, dprfolbio,
            dpragcrb, dprmrcrb, dprcscrb, dprfolcrb
        ])
        DBInterface.close!(stmt)

        if ihrvc == Int32(0); break; end   # no harvest — only one row needed
        # Second pass: row for retained (non-harvested) stand
        ihrvc    = Int32(2)
        dptcuft  = max(0.0, dptcuft  - dprtcuft)
        dpmcuft  = max(0.0, dpmcuft  - dprmcuft)
        dpscuft  = max(0.0, dpscuft  - dprscuft)
        dpagbio  = max(0.0, dpagbio  - dpragbio)
        dpmrbio  = max(0.0, dpmrbio  - dprmrbio)
        dpcsbio  = max(0.0, dpcsbio  - dprcsbio)
        dpabcrb  = max(0.0, dpabcrb  - dpragcrb)
        dpmrcrb  = max(0.0, dpmrcrb  - dprmrcrb)
        dpcscrb  = max(0.0, dpcscrb  - dprcscrb)
        dpflbio  = max(0.0, dpflbio  - dprfolbio)
        dpfolcrb = max(0.0, dpfolcrb - dprfolcrb)
        dprtcuft = 0.0; dprmcuft = 0.0; dprscuft = 0.0
        dpragbio = 0.0; dprmrbio = 0.0; dprcsbio = 0.0
        dpragcrb = 0.0; dprmrcrb = 0.0; dprcscrb = 0.0
        dprfolbio = 0.0; dprfolcrb = 0.0
    end

    return nothing
end

# ---------------------------------------------------------------------------
# DBSSUMRY: write FVS_Summary row per cycle (from dbssumry.f lines 1–225)
# Called from sumout.jl with scalar per-cycle summary statistics.
# ISUMARY==1 → write to FVS_Summary table.
# ---------------------------------------------------------------------------
function DBSSUMRY(iyear::Integer, iage::Integer, nplt::AbstractString,
                  itpa::Integer, iba::Integer, isdi::Integer, iccf::Integer,
                  itopht::Integer, fqmd::Real,
                  itcuft::Integer, imcuft::Integer, iscuft::Integer,
                  ibdft::Integer, irtpa::Integer, irtcuft::Integer,
                  irmcuft::Integer, irscuft::Integer, irbdft::Integer,
                  iatba::Integer, iatsdi::Integer, iatccf::Integer,
                  iattopht::Integer, fatqmd::Real,
                  iprdlen::Integer, iacc::Integer, imort::Integer,
                  ymai::Real, ifortp::Integer, iszcl::Integer, istcl::Integer)
    ISUMARY == Int32(1) || return nothing
    DBSCASE(Int32(1))
    db = _dbs_out_db[]
    db === nothing && return nothing

    if !_dbs_table_exists(db, "FVS_Summary")
        _dbs_exec(db, """
            CREATE TABLE FVS_Summary (
              CaseID text not null,
              StandID text not null,
              Year int, Age int,
              Tpa int, BA int, SDI int, CCF int, TopHt int, QMD real,
              TCuFt int, MCuFt int, SCuFt int, BdFt int,
              RTpa int, RTCuFt int, RMCuFt int, RSCuFt int, RBdFt int,
              ATBA int, ATSDI int, ATCCF int, ATTopHt int, ATQMD real,
              PrdLen int, Acc int, Mort int, MAI real,
              ForTyp int, SizeCls int, StkCls int
            );""")
        _dbs_add_column(db, "FVS_Summary", "SCuFt", "int")
        _dbs_add_column(db, "FVS_Summary", "RSCuFt", "int")
    end

    stmt = SQLite.Stmt(db, """
        INSERT INTO FVS_Summary
          (CaseID,StandID,Year,Age,Tpa,BA,SDI,CCF,TopHt,QMD,
           TCuFt,MCuFt,SCuFt,BdFt,
           RTpa,RTCuFt,RMCuFt,RSCuFt,RBdFt,
           ATBA,ATSDI,ATCCF,ATTopHt,ATQMD,
           PrdLen,Acc,Mort,MAI,ForTyp,SizeCls,StkCls)
        VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
        """)
    DBInterface.execute(stmt, [
        CASEID, rstrip(nplt), Int(iyear), Int(iage),
        Int(itpa), Int(iba), Int(isdi), Int(iccf), Int(itopht), Float64(fqmd),
        Int(itcuft), Int(imcuft), Int(iscuft), Int(ibdft),
        Int(irtpa), Int(irtcuft), Int(irmcuft), Int(irscuft), Int(irbdft),
        Int(iatba), Int(iatsdi), Int(iatccf), Int(iattopht), Float64(fatqmd),
        Int(iprdlen), Int(iacc), Int(imort), Float64(ymai),
        Int(ifortp), Int(iszcl), Int(istcl)
    ])
    DBInterface.close!(stmt)
    return nothing
end

# ---------------------------------------------------------------------------
# DBSSUMRY2: write FVS_Summary2 row (translated from dbssumry.f, lines 227–536)
# ISUMARY==2 → write to FVS_Summary2.  May insert two rows when harvest occurs:
#   RmvCode=0 (or 1) = total+harvest; RmvCode=2 = retained after thinning.
# ---------------------------------------------------------------------------
function DBSSUMRY2()
    ISUMARY == Int32(2) || return nothing

    # Per-cycle summary values
    iyear   = Int(IY[ICYC])
    iageout = Int(IOSUM[2, ICYC])
    iccf    = Int(IBTCCF[ICYC])
    itopht  = Int(IBTAVH[ICYC])
    iosdi   = Int(ISDI_S[ICYC])
    izsdi   = Int(round(Int32, SDIBC2))
    irsdi   = Int(round(Int32, SDIBC))
    dptpa   = Float64(OLDTPA / GROSPC)
    dpba    = Float64(OLDBA  / GROSPC)
    dpqmd   = Float64(ORMSQD)
    dpdr016 = Float64(ODR016)

    if ICYC > NCYC
        dptcuft = Float64(OCVCUR[7] / GROSPC)
        dpmcuft = Float64(OMCCUR[7] / GROSPC)
        dpscuft = Float64(OSCCUR[7] / GROSPC)
        dpbdft  = Float64(OBFCUR[7] / GROSPC)
    else
        dptcuft = Float64(TSTV1[4])
        dpmcuft = Float64(TSTV1[5])
        dpscuft = Float64(TSTV1[20])
        dpbdft  = Float64(TSTV1[6])
    end

    dptptpa   = dptpa   + Float64(TRTPA   / GROSPC)
    dptptcuft = dptcuft + Float64(TRTCUFT / GROSPC)
    dptpmcuft = dpmcuft + Float64(TRMCUFT / GROSPC)
    dptpscuft = dpscuft + Float64(TRSCUFT / GROSPC)
    dptpbdft  = dpbdft  + Float64(TRBDFT  / GROSPC)

    dprtpa   = 0.0; dprtcuft = 0.0; dprmcuft = 0.0
    dprscuft = 0.0; dprbdft  = 0.0

    iprdlen = Int(IOSUM[14, ICYC])
    sdix    = Int(round(Int32, BTSDIX))
    dprelden = BTSDIX > 0.0f0 ? Float64(iosdi) / Float64(BTSDIX) : 0.0
    dpacc   = 0.0
    dpmort  = 0.0
    dpmai   = Float64(BCYMAI[ICYC])
    ifrtp   = Int(IOSUM[18, ICYC])
    ihrvc   = 0

    if ICYC <= NCYC
        dpacc  = Float64(OACC[7]  / GROSPC)
        dpmort = Float64(OMORT[7] / GROSPC)
    end

    if ICYC <= NCYC
        dprtpa   = Float64(ONTREM[7] / GROSPC)
        dprtcuft = Float64(OCVREM[7] / GROSPC)
        dprmcuft = Float64(OMCREM[7] / GROSPC)
        dprscuft = Float64(OSCREM[7] / GROSPC)
        dprbdft  = Float64(OBFREM[7] / GROSPC)
        if dprtpa > 0.0
            ihrvc = 1
        else
            iprdlen = Int(IOSUM[14, ICYC])
            dpacc   = Float64(OACC[7]  / GROSPC)
            dpmort  = Float64(OMORT[7] / GROSPC)
            dpmai   = Float64(BCYMAI[ICYC])
        end
    end

    DBSCASE(Int32(1))
    db = _dbs_out_db[]
    db === nothing && return nothing

    tablename = "FVS_Summary2"
    if !_dbs_table_exists(db, tablename)
        _dbs_exec(db, """
            CREATE TABLE $tablename (
              CaseID text not null,
              StandID text not null,
              Year int, RmvCode int, Age int,
              Tpa real, TPrdTpa real, BA real,
              SDI int, ZeideSDI int, ReinekeSDI int, SDIMax int, RDSDI real,
              CCF int, TopHt int, QMD real, GMD real,
              TCuFt real, TPrdTCuFt real,
              MCuFt real, TPrdMCuFt real,
              SCuFt real, TPrdSCuFt real,
              BdFt real, TPrdBdFt real,
              RTpa real, RTCuFt real, RMCuFt real, RSCuFt real, RBdFt real,
              PrdLen int, Acc real, Mort real, MAI real,
              ForTyp int, SizeCls int, StkCls int
            );""")
    end

    insert_sql = """
        INSERT INTO $tablename
          (CaseID,StandID,Year,RmvCode,Age,Tpa,TPrdTpa,BA,SDI,
           ZeideSDI,ReinekeSDI,SDIMax,RDSDI,CCF,TopHt,QMD,GMD,
           TCuFt,TPrdTCuFt,MCuFt,TPrdMCuFt,SCuFt,TPrdSCuFt,BdFt,TPrdBdFt,
           RTpa,RTCuFt,RMCuFt,RSCuFt,RBdFt,
           PrdLen,Acc,Mort,MAI,ForTyp,SizeCls,StkCls)
        VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)"""

    for pass in 1:2
        if ihrvc == 1
            dptptpa   -= dprtpa
            dptptcuft -= dprtcuft
            dptpmcuft -= dprmcuft
            dptpscuft -= dprscuft
            dptpbdft  -= dprbdft
        end

        stmt = SQLite.Stmt(db, insert_sql)
        DBInterface.execute(stmt, [
            CASEID, strip(NPLT), iyear, ihrvc, iageout,
            dptpa, dptptpa, dpba,
            iosdi, izsdi, irsdi, sdix, dprelden,
            iccf, itopht, dpqmd, dpdr016,
            dptcuft, dptptcuft, dpmcuft, dptpmcuft,
            dpscuft, dptpscuft, dpbdft, dptpbdft,
            dprtpa, dprtcuft, dprmcuft, dprscuft, dprbdft,
            iprdlen, dpacc, dpmort, dpmai,
            ifrtp, Int(ISZCL), Int(ISTCL)
        ])
        DBInterface.close!(stmt)

        ihrvc == 0 && break   # no harvest — one row only

        # Second pass: retained-stand after-treatment statistics
        ihrvc    = 2
        iosdi    = Int(ISDIAT[ICYC])
        izsdi    = Int(round(Int32, SDIAC2))
        irsdi    = Int(round(Int32, SDIAC))
        iccf     = Int(round(Int32, ATCCF / GROSPC))
        itopht   = Int(round(Int32, ATAVH))
        dpqmd    = Float64(ATAVD)
        dpdr016  = Float64(ATDR016)
        dpba     = Float64(ATBA   / GROSPC)
        dptpa    = Float64(ATTPA  / GROSPC)
        dptcuft  = max(0.0, dptcuft - dprtcuft)
        dpmcuft  = max(0.0, dpmcuft - dprmcuft)
        dpscuft  = max(0.0, dpscuft - dprscuft)
        dpbdft   = max(0.0, dpbdft  - dprbdft)
        dprtpa   = 0.0; dprtcuft = 0.0; dprmcuft = 0.0
        dprscuft = 0.0; dprbdft  = 0.0
        sdix     = Int(round(Int32, ATSDIX))
        dprelden = BTSDIX > 0.0f0 ? Float64(iosdi) / Float64(BTSDIX) : 0.0
    end
    return nothing
end

# ---------------------------------------------------------------------------
# DBSSTATS: write FVS_Stats_Species / FVS_Stats_Stand (stub — handled in stats.jl)
# ---------------------------------------------------------------------------
# DBSSTATS is already implemented in base/stats.jl as a no-op stub.
# Full DBS stats translation pending.

# ---------------------------------------------------------------------------
# DBS_FIAVBC_ATRTLS: write FVS_FIAVBC_ATRTList to SQLite (dbs_fiavbc_atrtls.f, 319 lines)
# After-treatment tree list: same 32-column schema as FVS_FIAVBC_TreeList.
# Uses PROB (live TPA) like TRLS; no dead-tree section.
# ---------------------------------------------------------------------------
function DBS_FIAVBC_ATRTLS()
    IVBCATRLST == Int32(0) && return nothing
    if !LFIANVB
        ERRGRO(true, Int32(52))
        return nothing
    end

    DBSCASE(Int32(1))
    db = _dbs_out_db[]
    db === nothing && return nothing

    idcmp1   = Int32(10000000)
    idcmp2   = Int32(20000000)
    tblname  = "FVS_FIAVBC_ATRTList"

    if !_dbs_table_exists(db, tblname)
        _dbs_exec(db, """
            CREATE TABLE $tblname (
              CaseID text not null, StandID text not null,
              PtIndex int null, ActPt int null, Year int null,
              TreeId text null, TreeIndex int null,
              SpeciesFVS text null, SpeciesPLANTS text null, SpeciesFIA text null,
              TPA real null, MortTPA real null,
              DBH real null, Ht real null, EstHt real null, TruncHt int null, PctCr int null,
              Cull real null, WdldStem int null, DecayCd int null, CarbFrac real null,
              TCuFt real null, MCuFt real null, SCuFt real null,
              AbvGrdBio real null, MerchBio real null, SawBio real null, FoliBio real null,
              AbvGrdCarb real null, MerchCarb real null, SawCarb real null, FoliCarb real null
            );""")
    end

    caseid_s  = CASEID
    standid_s = rstrip(NPLT)
    iyear     = Int(IY[ICYC])   # after-treatment uses current cycle year

    stmt = SQLite.Stmt(db, """
        INSERT INTO $tblname
          (CaseID,StandID,PtIndex,ActPt,Year,TreeId,TreeIndex,
           SpeciesFVS,SpeciesPLANTS,SpeciesFIA,
           TPA,MortTPA,DBH,Ht,EstHt,TruncHt,PctCr,
           Cull,WdldStem,DecayCd,CarbFrac,
           TCuFt,MCuFt,SCuFt,
           AbvGrdBio,MerchBio,SawBio,FoliBio,
           AbvGrdCarb,MerchCarb,SawCarb,FoliCarb)
        VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
        """)

    DBInterface.execute(db, "BEGIN;")
    for ispc in 1:MAXSP
        i1 = ISCT[ispc, 1]
        i1 == 0 && continue
        i2 = ISCT[ispc, 2]
        for i3 in i1:i2
            i = Int(IND1[i3])
            p = Float64(PROB[i] / GROSPC)
            p <= 0.0 && continue

            idt = IDTREE[i]
            if idt > idcmp2;      tid = @sprintf("CM%06d", idt - idcmp2)
            elseif idt > idcmp1;  tid = @sprintf("ES%06d", idt - idcmp1)
            else;                  tid = string(idt)
            end

            itrnk  = div(Int(ITRUNC[i]) + 5, 100)
            estht  = NORMHT[i] > Int32(0) ? Float64((NORMHT[i] + 5) / 100) : 0.0
            sp_fvs    = rstrip(JSP[ISP[i]])
            sp_plants = rstrip(PLNJSP[ISP[i]])
            sp_fia    = rstrip(FIAJSP[ISP[i]])

            DBInterface.execute(stmt, [
                caseid_s, standid_s,
                Int(ITRE[i]), Int(IPVEC[ITRE[i]]),
                iyear, tid, i,
                sp_fvs, sp_plants, sp_fia,
                p, 0.0,
                Float64(DBH[i]), Float64(HT[i]), estht, itrnk, Int(ICR[i]),
                Float64(CULL[i]), Int(WDLDSTEM[i]), Int(DECAYCD[i]), Float64(CARB_FRAC[i]),
                Float64(CFV[i]), Float64(MCFV[i]), Float64(SCFV[i]),
                Float64(ABVGRD_BIO[i]), Float64(MERCH_BIO[i]),
                Float64(CUBSAW_BIO[i]), Float64(FOLI_BIO[i]),
                Float64(ABVGRD_CARB[i]), Float64(MERCH_CARB[i]),
                Float64(CUBSAW_CARB[i]), Float64(FOLI_CARB[i])
            ])
        end
    end
    DBInterface.close!(stmt)   # finalize prepared stmt before COMMIT (SQLite: no statements in progress)
    DBInterface.execute(db, "COMMIT;")
    return nothing
end

# ---------------------------------------------------------------------------
# DBS_FIAVBC_CUTLST: write FVS_FIAVBC_CutList to SQLite (dbs_fiavbc_cutlst.f, 319 lines)
# Cut tree list: same 32-column schema; uses WK3 (thinned TPA) not PROB.
# ---------------------------------------------------------------------------
function DBS_FIAVBC_CUTLST()
    IVBCCUTLST == Int32(0) && return nothing
    if !LFIANVB
        ERRGRO(true, Int32(52))
        return nothing
    end

    DBSCASE(Int32(1))
    db = _dbs_out_db[]
    db === nothing && return nothing

    idcmp1   = Int32(10000000)
    idcmp2   = Int32(20000000)
    tblname  = "FVS_FIAVBC_CutList"

    if !_dbs_table_exists(db, tblname)
        _dbs_exec(db, """
            CREATE TABLE $tblname (
              CaseID text not null, StandID text not null,
              PtIndex int null, ActPt int null, Year int null,
              TreeId text null, TreeIndex int null,
              SpeciesFVS text null, SpeciesPLANTS text null, SpeciesFIA text null,
              TPA real null, MortTPA real null,
              DBH real null, Ht real null, EstHt real null, TruncHt int null, PctCr int null,
              Cull real null, WdldStem int null, DecayCd int null, CarbFrac real null,
              TCuFt real null, MCuFt real null, SCuFt real null,
              AbvGrdBio real null, MerchBio real null, SawBio real null, FoliBio real null,
              AbvGrdCarb real null, MerchCarb real null, SawCarb real null, FoliCarb real null
            );""")
    end

    caseid_s  = CASEID
    standid_s = rstrip(NPLT)
    iyear     = Int(IY[ICYC])

    stmt = SQLite.Stmt(db, """
        INSERT INTO $tblname
          (CaseID,StandID,PtIndex,ActPt,Year,TreeId,TreeIndex,
           SpeciesFVS,SpeciesPLANTS,SpeciesFIA,
           TPA,MortTPA,DBH,Ht,EstHt,TruncHt,PctCr,
           Cull,WdldStem,DecayCd,CarbFrac,
           TCuFt,MCuFt,SCuFt,
           AbvGrdBio,MerchBio,SawBio,FoliBio,
           AbvGrdCarb,MerchCarb,SawCarb,FoliCarb)
        VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
        """)

    DBInterface.execute(db, "BEGIN;")
    for ispc in 1:MAXSP
        i1 = ISCT[ispc, 1]
        i1 == 0 && continue
        i2 = ISCT[ispc, 2]
        for i3 in i1:i2
            i = Int(IND1[i3])
            # WK3 holds removed TPA for the cut list
            p = Float64(WK3[i] / GROSPC)
            p <= 0.0 && continue

            idt = IDTREE[i]
            if idt > idcmp2;      tid = @sprintf("CM%06d", idt - idcmp2)
            elseif idt > idcmp1;  tid = @sprintf("ES%06d", idt - idcmp1)
            else;                  tid = string(idt)
            end

            itrnk  = div(Int(ITRUNC[i]) + 5, 100)
            estht  = NORMHT[i] > Int32(0) ? Float64((NORMHT[i] + 5) / 100) : 0.0
            sp_fvs    = rstrip(JSP[ISP[i]])
            sp_plants = rstrip(PLNJSP[ISP[i]])
            sp_fia    = rstrip(FIAJSP[ISP[i]])

            DBInterface.execute(stmt, [
                caseid_s, standid_s,
                Int(ITRE[i]), Int(IPVEC[ITRE[i]]),
                iyear, tid, i,
                sp_fvs, sp_plants, sp_fia,
                p, 0.0,
                Float64(DBH[i]), Float64(HT[i]), estht, itrnk, Int(ICR[i]),
                Float64(CULL[i]), Int(WDLDSTEM[i]), Int(DECAYCD[i]), Float64(CARB_FRAC[i]),
                Float64(CFV[i]), Float64(MCFV[i]), Float64(SCFV[i]),
                Float64(ABVGRD_BIO[i]), Float64(MERCH_BIO[i]),
                Float64(CUBSAW_BIO[i]), Float64(FOLI_BIO[i]),
                Float64(ABVGRD_CARB[i]), Float64(MERCH_CARB[i]),
                Float64(CUBSAW_CARB[i]), Float64(FOLI_CARB[i])
            ])
        end
    end
    DBInterface.close!(stmt)   # finalize prepared stmt before COMMIT (SQLite: no statements in progress)
    DBInterface.execute(db, "COMMIT;")
    return nothing
end

# ---------------------------------------------------------------------------
# DBSOPEN: open output and/or input SQLite database (from dbsopen.f)
# ---------------------------------------------------------------------------
function DBSOPEN(lcout::Bool, lcin::Bool, kode_ref::Ref{Int32})
    kode_ref[] = Int32(0)
    DBSCLOSE(lcout, lcin)

    if lcout
        dbname = isempty(strip(DSNOUT)) ? "FVSOut.db" : strip(DSNOUT)
        try
            _dbs_out_db[] = SQLite.DB(dbname)
            _dbs_exec(_dbs_out_db[], "PRAGMA journal_mode=WAL;")
        catch e
            @warn "DBS: cannot open output database '$dbname': $e"
            kode_ref[] = Int32(1)
            if !lcin; return nothing; end
        end
    end

    if lcin
        dbname = isempty(strip(DSNIN)) ? "FVS_Data.db" : strip(DSNIN)
        try
            _dbs_in_db[] = SQLite.DB(dbname)
        catch e
            @warn "DBS: cannot open input database '$dbname': $e"
            kode_ref[] = Int32(1)
            return nothing
        end
    end
    return nothing
end

# ---------------------------------------------------------------------------
# DBSIN: DBS keyword processor (translated from dbsin.f, 963 lines)
# Handles the 43 DBS keywords. Only the most commonly used are fully
# translated; all others are logged and skipped.
# ---------------------------------------------------------------------------
const _DBSIN_KWDS = [
    "END     ","DSNOUT  ","SQLOUT  ","SUMMARY ","COMPUTDB",
    "TREELIDB","STANDIN ","CLIMREDB","DRIVERS ","DSNIN   ",
    "STANDSQL","TREESQL ","POTFIRDB","FUELSOUT","DSNESTAB",
    "SQLIN   ","CUTLIDB ","MISRPTS ","FUELREDB","BURNREDB",
    "MORTREDB","SNAGSUDB","SNAGOUDB","STRCLSDB","PPBMMAIN",
    "PPBMTREE","PPBMBKP ","PPBMVOL ","CARBREDB","ECONRPTS",
    "ATRTLIDB","DWDVLDB ","DWDCVDB ","RDSUM   ","RDDETAIL",
    "RDBBMORT","CALBSTDB","INVSTATS","REGREPTS","VBCSUMDB",
    "VBCTRLDB","VBCCUTDB","VBCATRDB"
]

function DBSIN(keywrd_in::AbstractString, array::AbstractVector{Float32},
               isdsp::Integer, sdlo::Real, sdhi::Real,
               lnotbk::AbstractVector, lkecho::Bool)
    io = io_units[Int32(JOSTND)]
    keywrd = keywrd_in

    kode   = Int32(0)
    kard   = fill("          ", 12)
    lnb    = fill(false, 12)
    kw_arr = zeros(Float32, 12)

    while true
        # Read next DBS keyword record (returns tuple)
        keywrd, lnb, kw_arr, irecnt_new, kode, kard, lflag_new =
            KEYRDR(Int32(IREAD), Int32(JOSTND), false,
                   lnb, kw_arr, Int32(IRECNT), kode, kard, LFLAG, lkecho)
        global IRECNT = irecnt_new
        global LFLAG  = lflag_new

        if kode > Int32(0)
            if kode == Int32(2); ERRGRO(false, Int32(2))
            else;                ERRGRO(true,  Int32(6)); end
            if fvsGetRtnCode() != Int32(0); return nothing; end
            continue
        end

        # Identify keyword in DBS table
        num, fnd = FNDKEY(keywrd, _DBSIN_KWDS, Int32(JOSTND))

        if num == Int32(1)           # END
            if lkecho; @printf(io, "\n%-8s   END OF DATA BASE OPTIONS.\n", keywrd); end
            return nothing

        elseif num == Int32(2)       # DSNOUT
            if !isempty(strip(CASEID))
                ERRGRO(true, Int32(16))
                @printf(io, "             DSNOUT DATA BASE CAN NOT BE REDEFINED. DSN FOR OUTPUT REMAINS: %s\n", DSNOUT)
                readline(io_units[Int32(IREAD)])
                IRECNT += Int32(1)
                continue
            end
            dsnline = readline(io_units[Int32(IREAD)])
            global IRECNT = IRECNT + Int32(1)
            global DSNOUT = strip(dsnline)
            if lkecho; @printf(io, "\n%-8s   DSN FOR OUTPUT DATA BASE IS %s\n", keywrd, DSNOUT); end
            kode_r2 = Ref(Int32(0))
            DBSOPEN(true, false, kode_r2)
            global CASEID = ""
            if kode_r2[] != Int32(0)
                global ISUMARY   = Int32(0); global IVBCSUM    = Int32(0)
                global ITREELIST = Int32(0); global IVBCTRELST = Int32(0)
                @printf(io, "             ********  ERROR: OUTPUT OPEN FAILED FOR DSN:%s\n", DSNOUT)
            else
                DBSCASE(Int32(1))
            end

        elseif num == Int32(4)       # SUMMARY
            global ISUMARY = lnb[1] && kw_arr[1] == Float32(2) ? Int32(2) : Int32(1)
            if lkecho
                @printf(io, "\n%-8s   SUMMARY%s STATISTICS SENT TO DATABASE.\n",
                        keywrd, ISUMARY == Int32(2) ? " VERSION 2" : "")
            end

        elseif num == Int32(6)       # TREELIDB
            global ITREELIST = lnb[1] && kw_arr[1] > Float32(0) ? Int32(trunc(kw_arr[1])) : Int32(1)
            if lkecho; @printf(io, "\n%-8s   TREE INFORMATION SENT TO SPECIFIED DATABASE.\n", keywrd); end

        elseif num == Int32(17)      # CUTLIDB
            global ICUTLIST = Int32(1)
            if lkecho; @printf(io, "\n%-8s   CUT LIST SENT TO SPECIFIED DATABASE.\n", keywrd); end

        elseif num == Int32(31)      # ATRTLIDB
            global IATRTLIST = Int32(1)
            if lkecho; @printf(io, "\n%-8s   ADDITIONAL TREATMENT TREE LIST SENT TO DATABASE.\n", keywrd); end

        elseif num == Int32(40)      # VBCSUMDB
            global IVBCSUM = Int32(1)
            if lkecho; @printf(io, "\n%-8s   FIAVBC_SUMMARY STATISTICS SENT TO DATABASE (REQUIRES FIAVBC KEYWORD).\n", keywrd); end

        elseif num == Int32(41)      # VBCTRLDB
            global IVBCTRELST = Int32(1)
            if lkecho; @printf(io, "\n%-8s   FIAVBC_TREELIST SENT TO DATABASE (REQUIRES FIAVBC KEYWORD).\n", keywrd); end

        elseif num == Int32(42)      # VBCCUTDB
            global IVBCCUTLST = Int32(1)
            if lkecho; @printf(io, "\n%-8s   FIAVBC_CUTLIST SENT TO DATABASE (REQUIRES FIAVBC KEYWORD).\n", keywrd); end

        elseif num == Int32(43)      # VBCATRDB
            global IVBCATRLST = Int32(1)
            if lkecho; @printf(io, "\n%-8s   FIAVBC_ATRLIST SENT TO DATABASE (REQUIRES FIAVBC KEYWORD).\n", keywrd); end

        elseif num == Int32(13)      # POTFIRDB — FVS_PotFire_East + FVS_PotFire_Cond
            local lact = Ref(false); FMLNKD(lact)
            if lact[]
                global IPOTFIRE = Int32(1); global IPOTFIREC = Int32(1)
                if lkecho; @printf(io, "\n%-8s   POTENTIAL FIRE REPORT SENT TO DATABASE.\n", keywrd); end
            else; ERRGRO(true, Int32(11)); end

        elseif num == Int32(14)      # FUELSOUT — FVS_Fuels
            local lact = Ref(false); FMLNKD(lact)
            if lact[]
                global IFUELS = (lnb[1] && kw_arr[1] > Float32(1)) ? Int32(2) : Int32(1)
                if lkecho; @printf(io, "\n%-8s   ALL FUELS REPORT SENT TO DATABASE.\n", keywrd); end
            else; ERRGRO(true, Int32(11)); end

        elseif num == Int32(19)      # FUELREDB — FVS_Consumption
            local lact = Ref(false); FMLNKD(lact)
            if lact[]
                global IFUELC = (lnb[1] && kw_arr[1] > Float32(1)) ? Int32(2) : Int32(1)
                if lkecho; @printf(io, "\n%-8s   FUEL CONSUMPTION REPORT SENT TO DATABASE.\n", keywrd); end
            else; ERRGRO(true, Int32(11)); end

        elseif num == Int32(20)      # BURNREDB — FVS_BurnReport
            local lact = Ref(false); FMLNKD(lact)
            if lact[]
                global IBURN = (lnb[1] && kw_arr[1] > Float32(1)) ? Int32(2) : Int32(1)
                if lkecho; @printf(io, "\n%-8s   BURN CONDITIONS REPORT SENT TO DATABASE.\n", keywrd); end
            else; ERRGRO(true, Int32(11)); end

        elseif num == Int32(21)      # MORTREDB — FVS_Mortality
            local lact = Ref(false); FMLNKD(lact)
            if lact[]
                global IMORTF = (lnb[1] && kw_arr[1] > Float32(1)) ? Int32(2) : Int32(1)
                if lkecho; @printf(io, "\n%-8s   FIRE MORTALITY REPORT SENT TO DATABASE.\n", keywrd); end
            else; ERRGRO(true, Int32(11)); end

        elseif num == Int32(22)      # SNAGSUDB — FVS_SnagSum
            local lact = Ref(false); FMLNKD(lact)
            if lact[]
                global ISSUM = (lnb[1] && kw_arr[1] > Float32(1)) ? Int32(2) : Int32(1)
                if lkecho; @printf(io, "\n%-8s   SNAG SUMMARY REPORT SENT TO DATABASE.\n", keywrd); end
            else; ERRGRO(true, Int32(11)); end

        elseif num == Int32(29)      # CARBREDB — FVS_Carbon + FVS_Hrv_Carbon
            local lact = Ref(false); FMLNKD(lact)
            if lact[]
                global ICMRPT = (lnb[1] && kw_arr[1] > Float32(1)) ? Int32(2) : Int32(1)
                global ICHRPT = ICMRPT
                if lkecho; @printf(io, "\n%-8s   CARBON REPORT SENT TO DATABASE.\n", keywrd); end
            else; ERRGRO(true, Int32(11)); end

        elseif num == Int32(30)      # ECONRPTS — FVS_EconSummary (+ FVS_EconHarvestValue)
            global IDBSECON = Int32(2)
            global ISPOUT30 = Int32(0)
            if lnb[1] && Int(round(kw_arr[1])) == 1; global IDBSECON = Int32(1); end
            if lnb[2] && kw_arr[2] > Float32(0); global ISPOUT30 = Int32(round(kw_arr[2])); end
            if lkecho; @printf(io, "\n%-8s   ECON REPORTS SENT TO SPECIFIED DATABASE.\n", keywrd); end

        elseif num == Int32(32)      # DWDVLDB — FVS_Down_Wood_Vol
            local lact = Ref(false); FMLNKD(lact)
            if lact[]
                global IDWDVOL = (lnb[1] && kw_arr[1] > Float32(1)) ? Int32(2) : Int32(1)
                if lkecho; @printf(io, "\n%-8s   DOWN WOOD VOLUME REPORT SENT TO DATABASE.\n", keywrd); end
            else; ERRGRO(true, Int32(11)); end

        elseif num == Int32(33)      # DWDCVDB — FVS_Down_Wood_Cov
            local lact = Ref(false); FMLNKD(lact)
            if lact[]
                global IDWDCOV = (lnb[1] && kw_arr[1] > Float32(1)) ? Int32(2) : Int32(1)
                if lkecho; @printf(io, "\n%-8s   DOWN WOOD COVER REPORT SENT TO DATABASE.\n", keywrd); end
            else; ERRGRO(true, Int32(11)); end

        else
            # Unhandled DBS keyword — skip
            if lkecho; @printf(io, "\n%-8s   (DBS OPTION NOT YET TRANSLATED; IGNORED)\n", keywrd); end
        end
    end
end

# ---------------------------------------------------------------------------
# DBSSTANDIN: read stand data from input database (stub — 1092 lines)
# ---------------------------------------------------------------------------
function DBSSTANDIN(args...); return nothing; end

# ---------------------------------------------------------------------------
# DBSTREESIN: store initial tree records in DBS (stub — 251 lines)
# ---------------------------------------------------------------------------
function DBSTREESIN(args...); return nothing; end

# ---------------------------------------------------------------------------
# DBSFMCRPT: write one row to FVS_Carbon (from dbsfmcrpt.f, 164 lines)
# IYEAR  — calendar year
# NPLT   — stand ID (trimmed)
# VAR    — real array, VARDIM elements:
#   1=Aboveground_Total_Live, 2=Aboveground_Merch_Live, 3=Belowground_Live,
#   4=Belowground_Dead, 5=Standing_Dead, 6=Forest_Down_Dead_Wood,
#   7=Forest_Floor, 8=Forest_Shrub_Herb, 9=Total_Stand_Carbon,
#   10=Total_Removed_Carbon, 11=Carbon_Released_From_Fire
# KODE   — set to 0 if redirect-only (ICMRPT==2)
# ---------------------------------------------------------------------------
function DBSFMCRPT(iyear::Integer, nplt::AbstractString,
                   var::AbstractVector{Float32}, vardim::Integer,
                   kode_ref::Ref{Int32})
    ICMRPT == Int32(0) && return nothing
    ICMRPT == Int32(2) && (kode_ref[] = Int32(0))
    DBSCASE(Int32(1))
    db = _dbs_out_db[]
    db === nothing && return nothing

    if !_dbs_table_exists(db, "FVS_Carbon")
        _dbs_exec(db, """
            CREATE TABLE FVS_Carbon (
              CaseID text not null,
              StandID text not null,
              Year int null,
              Aboveground_Total_Live real null,
              Aboveground_Merch_Live real null,
              Belowground_Live real null,
              Belowground_Dead real null,
              Standing_Dead real null,
              Forest_Down_Dead_Wood real null,
              Forest_Floor real null,
              Forest_Shrub_Herb real null,
              Total_Stand_Carbon real null,
              Total_Removed_Carbon real null,
              Carbon_Released_From_Fire real null
            );""")
    end

    n = min(Int(vardim), length(var))
    vals = zeros(Float64, 11)
    for i in 1:n; vals[i] = Float64(var[i]); end

    stmt = SQLite.Stmt(db, """
        INSERT INTO FVS_Carbon
          (CaseID,StandID,Year,
           Aboveground_Total_Live,Aboveground_Merch_Live,
           Belowground_Live,Belowground_Dead,Standing_Dead,
           Forest_Down_Dead_Wood,Forest_Floor,Forest_Shrub_Herb,
           Total_Stand_Carbon,Total_Removed_Carbon,Carbon_Released_From_Fire)
        VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?)
        """)
    DBInterface.execute(stmt, [
        CASEID, rstrip(nplt), Int(iyear),
        vals[1], vals[2], vals[3], vals[4], vals[5],
        vals[6], vals[7], vals[8], vals[9], vals[10], vals[11]
    ])
    DBInterface.close!(stmt)
    return nothing
end

# ---------------------------------------------------------------------------
# DBSERROR: write an error/warning message to FVS_Error (from dbserror.f).
# Called from ERRGRO. No gating flag — writes whenever the output DB is open.
# ---------------------------------------------------------------------------
function DBSERROR(nplt::AbstractString, cmsg::AbstractString)
    DBSCASE(Int32(1))
    db = _dbs_out_db[]
    db === nothing && return nothing
    if !_dbs_table_exists(db, "FVS_Error")
        _dbs_exec(db, "CREATE TABLE FVS_Error (CaseID text not null,StandID text not null,Message text);")
    end
    stmt = SQLite.Stmt(db, "INSERT INTO FVS_Error (CaseID,StandID,Message) VALUES (?,?,?)")
    DBInterface.execute(stmt, Any[CASEID, rstrip(nplt), rstrip(cmsg)])
    DBInterface.close!(stmt)
    return nothing
end

# ---------------------------------------------------------------------------
# DBSPRS: tokenizer — returns text before first DELIMSTR, advances SOURCE past it.
# Translated from dbsprs.f (47 lines).
# ---------------------------------------------------------------------------
function DBSPRS(token_ref::Ref{String}, source_ref::Ref{String}, delim::AbstractString)
    src  = source_ref[]
    dlen = ncodeunits(delim)
    slen = ncodeunits(src)
    # skip leading delimiter characters
    ibeg = 1
    while ibeg <= slen - dlen + 1 && src[ibeg:ibeg+dlen-1] == delim
        ibeg += dlen
    end
    # advance until next delimiter
    iend = ibeg
    while iend <= slen - dlen + 1 && src[iend:iend+dlen-1] != delim
        iend += 1
    end
    if iend > slen - dlen + 1
        token_ref[]  = rstrip(src[ibeg:end])
        source_ref[] = ""
    else
        token_ref[]  = rstrip(src[ibeg:iend-1])
        source_ref[] = src[iend+dlen:end]
    end
    return nothing
end

# ---------------------------------------------------------------------------
# DBSPRSSQL: replace %KEYWORD% tokens in SQL string with runtime values.
# Translated from dbsprssql.f (122 lines).
# ORIGSTR is modified in-place (Ref); KODE→0 if any keywords found, else 1.
# ---------------------------------------------------------------------------
function DBSPRSSQL(sqlcmd_ref::Ref{String}, lsched::Bool, kode_ref::Ref{Int32})
    kode_ref[] = Int32(1)
    sql = sqlcmd_ref[]
    # Fast path: no % in string
    occursin('%', sql) || return nothing

    # Split on '%' — alternating: literal, keyword, literal, keyword, ...
    parts  = split(sql, '%')
    result = IOBuffer()
    for (i, part) in enumerate(parts)
        if isodd(i)
            write(result, part)          # literal segment
        else
            tok = uppercase(strip(part)) # keyword between %...%
            if isempty(tok)
                write(result, '%'); continue
            end
            kode_ref[] = Int32(0)
            rep = if tok == "STANDID"
                kode_ref[] = Int32(1)
                strip(NPLT) == "" ? "NULL" : strip(NPLT)
            elseif tok == "MGMTID"
                kode_ref[] = Int32(1)
                strip(MGMID) == "" ? "NULL" : strip(MGMID)
            elseif tok == "STAND_CN"
                kode_ref[] = Int32(1)
                strip(DBCN) == "" ? "NULL" : strip(DBCN)
            elseif tok == "VARIANT"
                kode_ref[] = Int32(1)
                VARACD
            elseif tok == "FVSCASE"
                DBSCASE(Int32(1))
                kode_ref[] = Int32(1)
                " " * strip(CASEID)
            else
                if lsched
                    iret_r = Ref(Int32(0)); irc_r = Ref(Int32(0))
                    ALGKEY(tok, length(tok), iret_r, irc_r)
                    rval = zeros(Float32, 1)
                    if irc_r[] == 0; EVLDX(rval, 1, iret_r[], irc_r); end
                    if iret_r[] == 0
                        kode_ref[] = Int32(1)
                        v = rval[1]
                        Float32(Int32(v)) == v ? @sprintf("%8d", Int32(v)) :
                                                  @sprintf("%14.7E", v)
                    else
                        kode_ref[] = Int32(1); " NULL"
                    end
                else
                    tok
                end
            end
            write(result, rep)
        end
    end
    sqlcmd_ref[] = String(take!(result))
    return nothing
end

# ---------------------------------------------------------------------------
# DBSCALIB: write calibration stats to FVS_CalibStats (from dbscalib.f, 202 lines)
# ICFROM==1 → large-tree (LG); ICFROM==2 → small-tree (SM).
# Writes one row per species with CORTEM!=1 or NUMCAL>=FNMIN.
# ---------------------------------------------------------------------------
function DBSCALIB(icfrom::Integer, cortem::AbstractVector{Float32},
                  numcal::AbstractVector{Int32}, stdrat::AbstractVector{Float32})
    ICALIB == Int32(0) && return nothing
    DBSCASE(Int32(1))
    db = _dbs_out_db[]
    db === nothing && return nothing

    if !_dbs_table_exists(db, "FVS_CalibStats")
        _dbs_exec(db, """
            CREATE TABLE FVS_CalibStats (
              CaseID text not null,
              StandID text not null,
              TreeSize text not null,
              SpeciesFVSnum int not null,
              SpeciesFVS    text not null,
              SpeciesPLANTS text not null,
              SpeciesFIA    text not null,
              NumTrees int null,
              ScaleFactor real null,
              StdErrRatio real null,
              WeightToInput real null,
              ReadCorMult real null);""")
    end

    tsz = icfrom == 1 ? "LG" : "SM"
    fnmin_thresh = Int(round(FNMIN))

    insert_sql = """
        INSERT INTO FVS_CalibStats
          (CaseID,StandID,TreeSize,SpeciesFVSnum,SpeciesFVS,SpeciesPLANTS,
           SpeciesFIA,NumTrees,ScaleFactor,StdErrRatio,WeightToInput,ReadCorMult)
        VALUES (?,?,?,?,?,?,?,?,?,?,?,?)"""

    _dbs_exec(db, "BEGIN;")
    for k in 1:Int(MAXSP)
        cortem[k] != Float32(1.0) || numcal[k] >= fnmin_thresh || continue

        ispec = Int(MAXSP); csp1 = JSP[MAXSP]; csp2 = PLNJSP[MAXSP]; csp3 = FIAJSP[MAXSP]
        for kk in 1:Int(MAXSP)
            IREF[kk] == Int32(k) || continue
            ispec = kk
            csp1  = JSP[kk]; csp2 = PLNJSP[kk]; csp3 = FIAJSP[kk]
            break
        end

        dcortem = Float64(cortem[k])
        if icfrom == 1
            dstdrat   = Float64(stdrat[k])
            dwci      = Float64(WCI[k])
            rcormult  = dwci > 0.0 ? exp(log(dcortem) / dwci) : dcortem
            stmt = SQLite.Stmt(db, insert_sql)
            DBInterface.execute(stmt, [
                CASEID, rstrip(NPLT), tsz,
                ispec, rstrip(csp1), rstrip(csp2), rstrip(csp3),
                Int(numcal[k]), dcortem, dstdrat, dwci, rcormult
            ])
            DBInterface.close!(stmt)
        else
            rcormult = dcortem
            stmt = SQLite.Stmt(db, insert_sql)
            DBInterface.execute(stmt, [
                CASEID, rstrip(NPLT), tsz,
                ispec, rstrip(csp1), rstrip(csp2), rstrip(csp3),
                Int(numcal[k]), dcortem, missing, missing, rcormult
            ])
            DBInterface.close!(stmt)
        end
    end
    _dbs_exec(db, "COMMIT;")
    return nothing
end

# ---------------------------------------------------------------------------
# DBSREFERENCE: write inventory reference data to FVS_InvReference
# (from dbsreference.f, 148 lines) — one row per active species.
# ---------------------------------------------------------------------------
function DBSREFERENCE()
    DBSCASE(Int32(1))
    db = _dbs_out_db[]
    db === nothing && return nothing

    if !_dbs_table_exists(db, "FVS_InvReference")
        _dbs_exec(db, """
            CREATE TABLE FVS_InvReference (
              CaseID text not null,
              StandID text not null,
              SpeciesNum int,
              SpeciesFVS text,
              SpeciesPlants text,
              SpeciesFIA text,
              SDIType text,
              SDIMax int,
              SiteIndex int,
              CFCruiseType text,
              CFVolEq text,
              CFMinDBH real,
              CFTopDia real,
              CFStump real,
              CFSawMinDBH real,
              CFSawTopDia real,
              CFSawStump real,
              BFVolEq text,
              BFMinDBH real,
              BFTopDia real,
              BFStump real);""")
    end

    cruisetype = CFCTYPE == "I" ? "FIA" : "FVS"
    sditype    = LZEIDE ? "  ZEIDE" : "REINEKE"

    insert_sql = """
        INSERT INTO FVS_InvReference
          (CaseID,StandID,SpeciesNum,SpeciesFVS,SpeciesPlants,SpeciesFIA,
           SDIType,SDIMax,SiteIndex,CFCruiseType,CFVolEq,
           CFMinDBH,CFTopDia,CFStump,CFSawMinDBH,CFSawTopDia,CFSawStump,
           BFVolEq,BFMinDBH,BFTopDia,BFStump)
        VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)"""

    for i in 1:Int(MAXSP)
        isempty(rstrip(JSP[i])) && continue
        stmt = SQLite.Stmt(db, insert_sql)
        DBInterface.execute(stmt, [
            CASEID, rstrip(NPLT),
            i, rstrip(JSP[i]), rstrip(PLNJSP[i]), rstrip(FIAJSP[i]),
            sditype, Int(round(SDIDEF[i], RoundNearestTiesAway)),
            Int(round(SITEAR[i], RoundNearestTiesAway)),   # Fortran NINT = ties away from zero
            cruisetype, rstrip(VEQNNC[i]),
            Float64(DBHMIN[i]), Float64(TOPD[i]), Float64(STMP[i]),
            Float64(SCFMIND[i]), Float64(SCFTOPD[i]), Float64(SCFSTMP[i]),
            rstrip(VEQNNB[i]),
            Float64(BFMIND[i]), Float64(BFTOPD[i]), Float64(BFSTMP[i])
        ])
        DBInterface.close!(stmt)
    end
    return nothing
end

# ---------------------------------------------------------------------------
# DBSSITEPREP: write regeneration site-prep data to FVS_Regen_SitePrep
# (from dbssiteprep.f, 132 lines) — called from sn/cratet.jl.
# ---------------------------------------------------------------------------
function DBSSITEPREP(noyear::Integer, mechyear::Integer, burnyear::Integer,
                     pctnone::Integer, pctmech::Integer, pctburn::Integer)
    IREG2 != Int32(1) && return nothing
    DBSCASE(Int32(1))
    db = _dbs_out_db[]
    db === nothing && return nothing

    if !_dbs_table_exists(db, "FVS_Regen_SitePrep")
        _dbs_exec(db, """
            CREATE TABLE FVS_Regen_SitePrep (
              CaseID text not null,
              StandID text not null,
              YearNone int null,
              YearMech int null,
              YearBurn int null,
              PcntNone int null,
              PcntMech int null,
              PcntBurn int null);""")
    end

    stmt = SQLite.Stmt(db, """
        INSERT INTO FVS_Regen_SitePrep
          (CaseID,StandID,YearNone,YearMech,YearBurn,PcntNone,PcntMech,PcntBurn)
        VALUES (?,?,?,?,?,?,?,?)""")
    try
        DBInterface.execute(stmt, [
            CASEID, rstrip(NPLT),
            Int(noyear), Int(mechyear), Int(burnyear),
            Int(pctnone), Int(pctmech), Int(pctburn)
        ])
    catch
        global IREG2 = Int32(0)
    end
    DBInterface.close!(stmt)
    return nothing
end

# ---------------------------------------------------------------------------
# DBSSTATS: write per-species or per-stand cruise stats to FVS_Stats_*
# (from dbsstats.f, 232 lines)
# TBL==1 → FVS_Stats_Species; TBL==2 → FVS_Stats_Stand.
# ---------------------------------------------------------------------------
function DBSSTATS(sp::AbstractString, tpa::Real, ba::Real, cf::Real, bf::Real,
                  bio::Real, carb::Real,
                  xbar::Real, s::Real, cv::Real, n::Real, siglevel::Real,
                  ul::Real, uu::Real, sep::Real, seu::Real,
                  label::AbstractString, itype::Integer, iyear::Integer)
    ISTATS1 != Int32(1) && return nothing
    DBSCASE(Int32(1))
    db = _dbs_out_db[]
    db === nothing && return nothing

    if itype != 2
        if !_dbs_table_exists(db, "FVS_Stats_Species")
            _dbs_exec(db, """
                CREATE TABLE FVS_Stats_Species (
                  CaseID text not null,
                  StandID text not null,
                  Year int null,
                  SpeciesFVS    text null,
                  SpeciesPLANTS text null,
                  SpeciesFIA    text null,
                  TreesPerAcre real,
                  BasalArea real,
                  CubicFeet real,
                  BoardFeet real,
                  FIA_AbvGrdBio real,
                  FIA_AbvGrdCarb real);""")
        end
        csp1 = "--"; csp2 = "--"; csp3 = "--"
        sp2 = length(sp) >= 2 ? sp[1:2] : sp
        for i in 1:Int(MAXSP)
            if sp2 == rstrip(JSP[i])
                csp1 = rstrip(JSP[i]); csp2 = rstrip(PLNJSP[i]); csp3 = rstrip(FIAJSP[i])
                break
            end
        end
        stmt = SQLite.Stmt(db, """
            INSERT INTO FVS_Stats_Species
              (CaseID,StandID,Year,SpeciesFVS,SpeciesPLANTS,SpeciesFIA,
               TreesPerAcre,BasalArea,CubicFeet,BoardFeet,FIA_AbvGrdBio,FIA_AbvGrdCarb)
            VALUES (?,?,?,?,?,?,?,?,?,?,?,?)""")
        try
            DBInterface.execute(stmt, [
                CASEID, rstrip(NPLT), Int(iyear),
                csp1, csp2, csp3,
                Float64(tpa), Float64(ba), Float64(cf), Float64(bf),
                Float64(bio), Float64(carb)
            ])
        catch
            global ISTATS1 = Int32(0)
        end
        DBInterface.close!(stmt)
    else
        ISTATS2 != Int32(1) && return nothing
        if !_dbs_table_exists(db, "FVS_Stats_Stand")
            _dbs_exec(db, """
                CREATE TABLE FVS_Stats_Stand (
                  CaseID text not null,
                  StandID text not null,
                  Year int null,
                  Characteristic text null,
                  Average real,
                  Standard_Dev real,
                  Coeff_of_Var real,
                  Sample_Size int,
                  Conf_Level_Percent int,
                  CI_LB real,
                  CI_UB real,
                  Samp_Error_Percent real,
                  Samp_Error_Units real);""")
        end
        stmt = SQLite.Stmt(db, """
            INSERT INTO FVS_Stats_Stand
              (CaseID,StandID,Year,Characteristic,Average,Standard_Dev,
               Coeff_of_Var,Sample_Size,Conf_Level_Percent,CI_LB,CI_UB,
               Samp_Error_Percent,Samp_Error_Units)
            VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)""")
        try
            DBInterface.execute(stmt, [
                CASEID, rstrip(NPLT), Int(iyear),
                strip(label),
                Float64(xbar), Float64(s), Float64(cv),
                Int(round(n)), Int(round(siglevel)),
                Float64(ul), Float64(uu),
                Float64(sep), Float64(seu)
            ])
        catch
            global ISTATS2 = Int32(0)
        end
        DBInterface.close!(stmt)
    end
    return nothing
end

# ---------------------------------------------------------------------------
# DBSSTRCLASS: write structural class data to FVS_StrClass
# (from dbsstrclass.f, 366 lines)
# ---------------------------------------------------------------------------
function DBSSTRCLASS(iyear::Integer, cnplt::AbstractString, rcode::Integer,
                     s1dbh::Real, s1nht::Integer, s1lht::Integer, s1sht::Integer,
                     s1cb::Integer, s1cc::Integer, s1ms1::AbstractString,
                     s1ms2::AbstractString, s1sc::Integer,
                     s2dbh::Real, s2nht::Integer, s2lht::Integer, s2sht::Integer,
                     s2cb::Integer, s2cc::Integer, s2ms1::AbstractString,
                     s2ms2::AbstractString, s2sc::Integer,
                     s3dbh::Real, s3nht::Integer, s3lht::Integer, s3sht::Integer,
                     s3cb::Integer, s3cc::Integer, s3ms1::AbstractString,
                     s3ms2::AbstractString, s3sc::Integer,
                     ns::Integer, totcov::Integer, sclass::AbstractString,
                     kode::Integer, ntrees::Integer)
    ISTRCLAS == Int32(0) && return nothing
    ntrees == 0 && return nothing
    DBSCASE(Int32(1))
    db = _dbs_out_db[]
    db === nothing && return nothing

    if !_dbs_table_exists(db, "FVS_StrClass")
        _dbs_exec(db, """
            CREATE TABLE FVS_StrClass (
              CaseID text not null, StandID text not null, Year int null,
              Removal_Code int null,
              Stratum_1_DBH real null, Stratum_1_Nom_Ht int null,
              Stratum_1_Lg_Ht int null, Stratum_1_Sm_Ht int null,
              Stratum_1_Crown_Base int null, Stratum_1_Crown_Cover int null,
              Stratum_1_SpeciesFVS_1 text null, Stratum_1_SpeciesFVS_2 text null,
              Stratum_1_SpeciesPLANTS_1 text null, Stratum_1_SpeciesPLANTS_2 text null,
              Stratum_1_SpeciesFIA_1 text null, Stratum_1_SpeciesFIA_2 text null,
              Stratum_1_Status_Code int null,
              Stratum_2_DBH real null, Stratum_2_Nom_Ht int null,
              Stratum_2_Lg_Ht int null, Stratum_2_Sm_Ht int null,
              Stratum_2_Crown_Base int null, Stratum_2_Crown_Cover int null,
              Stratum_2_SpeciesFVS_1 text null, Stratum_2_SpeciesFVS_2 text null,
              Stratum_2_SpeciesPLANTS_1 text null, Stratum_2_SpeciesPLANTS_2 text null,
              Stratum_2_SpeciesFIA_1 text null, Stratum_2_SpeciesFIA_2 text null,
              Stratum_2_Status_Code int null,
              Stratum_3_DBH real null, Stratum_3_Nom_Ht int null,
              Stratum_3_Lg_Ht int null, Stratum_3_Sm_Ht int null,
              Stratum_3_Crown_Base int null, Stratum_3_Crown_Cover int null,
              Stratum_3_SpeciesFVS_1 text null, Stratum_3_SpeciesFVS_2 text null,
              Stratum_3_SpeciesPLANTS_1 text null, Stratum_3_SpeciesPLANTS_2 text null,
              Stratum_3_SpeciesFIA_1 text null, Stratum_3_SpeciesFIA_2 text null,
              Stratum_3_Status_Code int null,
              Number_of_Strata int null,
              Total_Cover int null,
              Structure_Class text null);""")
    end

    # Resolve species codes for each stratum major species
    function _sp_codes(ms::AbstractString)
        ms2 = length(ms) >= 2 ? ms[1:2] : ms
        for i in 1:Int(MAXSP)
            rstrip(JSP[i]) == ms2 && return rstrip(JSP[i]), rstrip(PLNJSP[i]), rstrip(FIAJSP[i])
        end
        return "--", "--", "--"
    end
    s1f1, s1p1, s1i1 = _sp_codes(s1ms1)
    s1f2, s1p2, s1i2 = _sp_codes(s1ms2)
    s2f1, s2p1, s2i1 = _sp_codes(s2ms1)
    s2f2, s2p2, s2i2 = _sp_codes(s2ms2)
    s3f1, s3p1, s3i1 = _sp_codes(s3ms1)
    s3f2, s3p2, s3i2 = _sp_codes(s3ms2)

    stmt = SQLite.Stmt(db, """
        INSERT INTO FVS_StrClass
          (CaseID,StandID,Year,Removal_Code,
           Stratum_1_DBH,Stratum_1_Nom_Ht,Stratum_1_Lg_Ht,Stratum_1_Sm_Ht,
           Stratum_1_Crown_Base,Stratum_1_Crown_Cover,
           Stratum_1_SpeciesFVS_1,Stratum_1_SpeciesFVS_2,
           Stratum_1_SpeciesPLANTS_1,Stratum_1_SpeciesPLANTS_2,
           Stratum_1_SpeciesFIA_1,Stratum_1_SpeciesFIA_2,
           Stratum_1_Status_Code,
           Stratum_2_DBH,Stratum_2_Nom_Ht,Stratum_2_Lg_Ht,Stratum_2_Sm_Ht,
           Stratum_2_Crown_Base,Stratum_2_Crown_Cover,
           Stratum_2_SpeciesFVS_1,Stratum_2_SpeciesFVS_2,
           Stratum_2_SpeciesPLANTS_1,Stratum_2_SpeciesPLANTS_2,
           Stratum_2_SpeciesFIA_1,Stratum_2_SpeciesFIA_2,
           Stratum_2_Status_Code,
           Stratum_3_DBH,Stratum_3_Nom_Ht,Stratum_3_Lg_Ht,Stratum_3_Sm_Ht,
           Stratum_3_Crown_Base,Stratum_3_Crown_Cover,
           Stratum_3_SpeciesFVS_1,Stratum_3_SpeciesFVS_2,
           Stratum_3_SpeciesPLANTS_1,Stratum_3_SpeciesPLANTS_2,
           Stratum_3_SpeciesFIA_1,Stratum_3_SpeciesFIA_2,
           Stratum_3_Status_Code,
           Number_of_Strata,Total_Cover,Structure_Class)
        VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)""")
    try
        DBInterface.execute(stmt, [
            CASEID, rstrip(cnplt), Int(iyear), Int(rcode),
            Float64(s1dbh), Int(s1nht), Int(s1lht), Int(s1sht),
            Int(s1cb), Int(s1cc),
            s1f1, s1f2, s1p1, s1p2, s1i1, s1i2, Int(s1sc),
            Float64(s2dbh), Int(s2nht), Int(s2lht), Int(s2sht),
            Int(s2cb), Int(s2cc),
            s2f1, s2f2, s2p1, s2p2, s2i1, s2i2, Int(s2sc),
            Float64(s3dbh), Int(s3nht), Int(s3lht), Int(s3sht),
            Int(s3cb), Int(s3cc),
            s3f1, s3f2, s3p1, s3p2, s3i1, s3i2, Int(s3sc),
            Int(ns), Int(totcov), rstrip(sclass)
        ])
    catch
        global ISTRCLAS = Int32(0)
    end
    DBInterface.close!(stmt)
    return nothing
end

# DBSTRLS — implemented in base/prtrls.jl (which also contains DBSATRTLS, DBSCUTS)

# ---------------------------------------------------------------------------
# DBSCMPU: write COMPUTE keyword values to FVS_Compute table (dbscmpu.f, 252 lines)
# Called from oplist.jl after the activity schedule is printed.
# ---------------------------------------------------------------------------
function DBSCMPU()
    if ICOMPUTE[] == Int32(0) || ITST5[] == Int32(0); return nothing; end

    # Check if there are non-underscore variables (or if I_CMPU >= 1)
    has_non_us = false
    for i in 1:Int(ITST5[])
        if !(CTSTV5[i][1:1] == "_" && I_CMPU[] < Int32(1))
            has_non_us = true; break
        end
    end
    if !has_non_us; return nothing; end

    DBSCASE(Int32(1))
    db = _dbs_out_db[]
    db === nothing && return nothing

    tablename = "FVS_Compute"
    itst5 = Int(ITST5[])

    # Build column list for variables to include
    include_var = [!(CTSTV5[i][1:1] == "_" && I_CMPU[] < Int32(1)) for i in 1:itst5]

    if !_dbs_table_exists(db, tablename)
        colsql = join(["$(strip(CTSTV5[i])) real null" for i in 1:itst5 if include_var[i]], ", ")
        _dbs_exec(db, "CREATE TABLE $tablename (CaseID text not null, StandID text not null, Year int null, $colsql);")
    else
        for i in 1:itst5
            if include_var[i]
                _dbs_add_column(db, tablename, strip(CTSTV5[i]), "real null")
            end
        end
    end

    ncyc = Int(NCYC[])
    caseid  = strip(CASEID[])
    standid = strip(NPLT[])

    SQLite.transaction(db) do
        for icy in 1:ncyc
            # collect (kwname, value) pairs for COMPUTE activities (act code 33) in this cycle
            pairs_dict = Dict{String,Float64}()
            thisyr = -1
            local_yr = -1
            for ii in Int(IMGPTS[icy,1]):Int(IMGPTS[icy,2])
                i = Int(IOPSRT[ii])
                if IACT[i,1] == Int32(33) && IACT[i,4] > Int32(0)
                    yr = Int(IACT[i,4])
                    if thisyr == -1; thisyr = yr; end
                    if yr != thisyr
                        if !isempty(pairs_dict)
                            _insert_cmpu(db, tablename, caseid, standid, thisyr, pairs_dict)
                        end
                        pairs_dict = Dict{String,Float64}()
                        thisyr = yr
                    end
                    ix = Int(round(PARMS[Int(IACT[i,2])+1]))
                    if ix > 500; ix -= 500; end
                    if ix >= 1 && ix <= itst5
                        if !(CTSTV5[ix][1:1] == "_" && I_CMPU[] < Int32(1))
                            pairs_dict[strip(CTSTV5[ix])] = Float64(PARMS[Int(IACT[i,2])])
                        end
                    end
                end
            end
            if !isempty(pairs_dict)
                _insert_cmpu(db, tablename, caseid, standid, thisyr, pairs_dict)
            end
        end
    end
    return nothing
end

function _insert_cmpu(db::SQLite.DB, tablename::AbstractString,
                       caseid::AbstractString, standid::AbstractString,
                       year::Integer, pairs::Dict{String,Float64})
    isempty(pairs) && return
    colnames = collect(keys(pairs))
    colsql   = join(colnames, ",")
    valmarks = join(["?" for _ in 1:length(colnames)+3], ",")
    sql = "INSERT INTO $tablename (CaseID,StandID,Year,$colsql) VALUES ($valmarks);"
    vals = Any[caseid, standid, Int(year)]
    for k in colnames; push!(vals, pairs[k]); end
    try
        DBInterface.execute(db, sql, vals)
    catch e
        @warn "DBSCMPU insert error: $e"
    end
end

# ---------------------------------------------------------------------------
# DBSEXECSQL: execute a user SQL statement on an open DBS connection (150 lines).
# Translated from dbsexecsql.f.
# db  — SQLite.DB handle (nothing = no connection)
# sql — SQL command; may contain %KEYWORD% tokens for substitution
# lsched — true if called from event monitor (enables EM variable lookup)
# irc_ref — return code: 0=success, 1=error/skipped
# ---------------------------------------------------------------------------
function DBSEXECSQL(db::Union{SQLite.DB, Nothing}, sql::AbstractString,
                    lsched::Bool, irc_ref::Ref{Int32})
    irc_ref[] = Int32(1)
    db === nothing && return nothing

    # Substitute %KEYWORD% tokens
    sql_r = Ref(String(sql))
    kode_r = Ref(Int32(0))
    DBSPRSSQL(sql_r, lsched, kode_r)
    if kode_r[] == Int32(0)
        io = io_units[Int32(JOSTND)]
        @printf(io, "\n%12sSQL STMT: %s\n********   ERROR: SQLOUT/SQLIN PARSING FAILED. \n",
                "", sql_r[])
        RCDSET(Int32(2), true)
        return nothing
    end

    try
        result = DBInterface.execute(db, sql_r[])
        # For SELECT-like queries, populate event monitor variables from result columns
        for row in result
            for (colname, val) in pairs(row)
                cname = String(colname)[1:min(8, length(String(colname)))]
                iopkd = 0
                for i in 1:Int(ITST5)
                    if cname == CTSTV5[i]
                        iopkd = i; break
                    end
                end
                if iopkd == 0 && ITST5 < MXTST5_OP
                    global ITST5 = ITST5 + Int32(1)
                    CTSTV5[Int(ITST5)] = cname
                    LTSTV5[Int(ITST5)] = false
                    iopkd = Int(ITST5)
                end
                if iopkd > 0
                    if val === nothing || ismissing(val)
                        TSTV5[iopkd]  = Float32(0)
                        LTSTV5[iopkd] = false
                    else
                        TSTV5[iopkd]  = Float32(val)
                        LTSTV5[iopkd] = true
                    end
                end
            end
        end
        irc_ref[] = Int32(0)
    catch e
        io = io_units[Int32(JOSTND)]
        @printf(io, "\n%12sSQL STMT: %s\n********   ERROR: SQLOUT/SQLIN PREPARE FAILED. \n",
                "", sql_r[])
        RCDSET(Int32(2), true)
    end
    return nothing
end

# ---------------------------------------------------------------------------
# DBS stubs for fire model, economics, and regeneration output tables.
# These are called from fire/establishment extensions; all no-ops until
# the respective extensions are translated.
# ---------------------------------------------------------------------------
function DBSTALLY(args...); return nothing; end        # dbstally.f: regeneration tally
# Helper: create a DBS table from a column spec if missing, then INSERT one row.
# cols/vals are parallel; CaseID/StandID/Year handled by the caller's column list.
function _dbs_write_row(table::AbstractString, createcols::AbstractString,
                        colnames::AbstractString, vals::AbstractVector)
    DBSCASE(Int32(1))
    db = _dbs_out_db[]
    db === nothing && return false
    if !_dbs_table_exists(db, table)
        _dbs_exec(db, "CREATE TABLE $table ($createcols);")
    end
    qs = join(fill("?", length(vals)), ",")
    stmt = SQLite.Stmt(db, "INSERT INTO $table ($colnames) VALUES ($qs)")
    DBInterface.execute(stmt, vals)
    DBInterface.close!(stmt)
    return true
end

# dbsfuels.f → FVS_Fuels (19 fuel components)
function DBSFUELS(iyear, nplt, litter, duff, sdlt3, sdge3, sd3to6, sd6to12,
                  sdge12, herb, shrub, surftot, snaglt3, snagge3, foliage,
                  standlt3, standge3, standtot, biomass, consumed, removed, kode_ref)
    IFUELS == Int32(0) && return nothing
    IFUELS == Int32(2) && (kode_ref[] = Int32(0))
    _dbs_write_row("FVS_Fuels",
        "CaseID text not null,StandID text not null,Year int null," *
        "Surface_Litter real,Surface_Duff real,Surface_lt3 real,Surface_ge3 real," *
        "Surface_3to6 real,Surface_6to12 real,Surface_ge12 real,Surface_Herb real," *
        "Surface_Shrub real,Surface_Total real,Standing_Snag_lt3 real,Standing_Snag_ge3 real," *
        "Standing_Foliage real,Standing_Live_lt3 real,Standing_Live_ge3 real,Standing_Total real," *
        "Total_Biomass int,Total_Consumed int,Biomass_Removed int",
        "CaseID,StandID,Year,Surface_Litter,Surface_Duff,Surface_lt3,Surface_ge3," *
        "Surface_3to6,Surface_6to12,Surface_ge12,Surface_Herb,Surface_Shrub,Surface_Total," *
        "Standing_Snag_lt3,Standing_Snag_ge3,Standing_Foliage,Standing_Live_lt3," *
        "Standing_Live_ge3,Standing_Total,Total_Biomass,Total_Consumed,Biomass_Removed",
        Any[CASEID, rstrip(nplt), Int(iyear),
            Float64(litter), Float64(duff), Float64(sdlt3), Float64(sdge3),
            Float64(sd3to6), Float64(sd6to12), Float64(sdge12), Float64(herb),
            Float64(shrub), Float64(surftot), Float64(snaglt3), Float64(snagge3),
            Float64(foliage), Float64(standlt3), Int(standge3), Int(standtot),
            Int(biomass), Int(consumed), Int(removed)])
    return nothing
end

# dbsfmburn.f → FVS_BurnReport
function DBSFMBURN(iyear, nplt, m1, m10, m100, m1000, mduff, mwoody, mherb,
                   wind, slope, flame, scorch, ftype, fmod, fwt, kode_ref)
    IBURN == Int32(0) && return nothing
    IBURN == Int32(2) && (kode_ref[] = Int32(0))
    fm(i) = (length(fmod) >= i ? Int(fmod[i]) : 0)
    # Fortran dbsfmburn.f:149 stores weight as a rounded percent: INT(WT*100+0.5)
    fw(i) = (length(fwt)  >= i ? Float64(round(Int, fwt[i] * 100.0f0)) : 0.0)
    _dbs_write_row("FVS_BurnReport",
        "CaseID text not null,StandID text not null,Year int," *
        "One_Hr_Moisture real,Ten_Hr_Moisture real,Hundred_Hr_Moisture real," *
        "Thousand_Hr_Moisture real,Duff_Moisture real,Live_Woody_Moisture real," *
        "Live_Herb_Moisture real,Midflame_Wind real,Slope int,Flame_length real," *
        "Scorch_height real,Fire_Type text,FuelModl1 int,Weight1 real,FuelModl2 int," *
        "Weight2 real,FuelModl3 int,Weight3 real,FuelModl4 int,Weight4 real",
        "CaseID,StandID,Year,One_Hr_Moisture,Ten_Hr_Moisture,Hundred_Hr_Moisture," *
        "Thousand_Hr_Moisture,Duff_Moisture,Live_Woody_Moisture,Live_Herb_Moisture," *
        "Midflame_Wind,Slope,Flame_length,Scorch_height,Fire_Type,FuelModl1,Weight1," *
        "FuelModl2,Weight2,FuelModl3,Weight3,FuelModl4,Weight4",
        Any[CASEID, rstrip(nplt), Int(iyear),
            Float64(m1), Float64(m10), Float64(m100), Float64(m1000), Float64(mduff),
            Float64(mwoody), Float64(mherb), Float64(wind), Int(slope), Float64(flame),
            Float64(scorch), rstrip(String(ftype)),
            fm(1), fw(1), fm(2), fw(2), fm(3), fw(3), fm(4), fw(4)])
    return nothing
end

# dbsfmfuel.f → FVS_Consumption
function DBSFMFUEL(iyear, nplt, expos, conlit, conduff, conlt3, conge3, con3to6,
                   con6to12, conge12, conhs, concr, contot, pduff, pge3, pcrown,
                   smoke25, smoke10, kode_ref)
    IFUELC == Int32(0) && return nothing
    IFUELC == Int32(2) && (kode_ref[] = Int32(0))
    _dbs_write_row("FVS_Consumption",
        "CaseID text not null,StandID text not null,Year int null," *
        "Min_Soil_Exp real,Litter_Consumption real,Duff_Consumption real," *
        "Consumption_lt3 real,Consumption_ge3 real,Consumption_3to6 real," *
        "Consumption_6to12 real,Consumption_ge12 real,Consumption_Herb_Shrub real," *
        "Consumption_Crowns real,Total_Consumption real,Percent_Consumption_Duff real," *
        "Percent_Consumption_ge3 real,Percent_Trees_Crowning int,Smoke_Production_25 real," *
        "Smoke_Production_10 real",
        "CaseID,StandID,Year,Min_Soil_Exp,Litter_Consumption,Duff_Consumption," *
        "Consumption_lt3,Consumption_ge3,Consumption_3to6,Consumption_6to12," *
        "Consumption_ge12,Consumption_Herb_Shrub,Consumption_Crowns,Total_Consumption," *
        "Percent_Consumption_Duff,Percent_Consumption_ge3,Percent_Trees_Crowning," *
        "Smoke_Production_25,Smoke_Production_10",
        Any[CASEID, rstrip(nplt), Int(iyear),
            Float64(expos), Float64(conlit), Float64(conduff), Float64(conlt3),
            Float64(conge3), Float64(con3to6), Float64(con6to12), Float64(conge12),
            Float64(conhs), Float64(concr), Float64(contot), Float64(pduff),
            Float64(pge3), Int(pcrown), Float64(smoke25), Float64(smoke10)])
    return nothing
end

# dbsfmmort.f → FVS_Mortality (one row per species with kills + an "ALL" total row)
function DBSFMMORT(iyear, clskil, totcls, totbak, totvolk, kode_ref)
    IMORTF == Int32(0) && return nothing
    IMORTF == Int32(2) && (kode_ref[] = Int32(0))
    DBSCASE(Int32(1))
    db = _dbs_out_db[]
    db === nothing && return nothing
    tbl = "FVS_Mortality"
    if !_dbs_table_exists(db, tbl)
        _dbs_exec(db, "CREATE TABLE $tbl (CaseID text not null,StandID text not null," *
            "Year int null,SpeciesFVS text,SpeciesPLANTS text,SpeciesFIA text," *
            "Killed_class1 real,Total_class1 real,Killed_class2 real,Total_class2 real," *
            "Killed_class3 real,Total_class3 real,Killed_class4 real,Total_class4 real," *
            "Killed_class5 real,Total_class5 real,Killed_class6 real,Total_class6 real," *
            "Bakill real,Volkill real);")
    end
    local mxsp1 = size(totcls, 1)
    local totcol = size(totcls, 2)   # last column = total over classes
    cols = "CaseID,StandID,Year,SpeciesFVS,SpeciesPLANTS,SpeciesFIA," *
        "Killed_class1,Total_class1,Killed_class2,Total_class2,Killed_class3,Total_class3," *
        "Killed_class4,Total_class4,Killed_class5,Total_class5,Killed_class6,Total_class6,Bakill,Volkill"
    for j in 1:mxsp1
        totcls[j, totcol] <= 0.0f0 && continue
        sp1, sp2, sp3 = j == mxsp1 ? ("ALL", "ALL", "ALL") :
                        (rstrip(JSP[j]), rstrip(PLNJSP[j]), rstrip(FIAJSP[j]))
        stmt = SQLite.Stmt(db, "INSERT INTO $tbl ($cols) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)")
        DBInterface.execute(stmt, Any[CASEID, rstrip(NPLT), Int(iyear), sp1, sp2, sp3,
            Float64(clskil[j,1]), Float64(totcls[j,1]), Float64(clskil[j,2]), Float64(totcls[j,2]),
            Float64(clskil[j,3]), Float64(totcls[j,3]), Float64(clskil[j,4]), Float64(totcls[j,4]),
            Float64(clskil[j,5]), Float64(totcls[j,5]), Float64(clskil[j,6]), Float64(totcls[j,6]),
            Float64(totbak[j]), Float64(totvolk[j])])
        DBInterface.close!(stmt)
    end
    return nothing
end

# dbsfmpf.f → FVS_PotFire_East (one row per call)
function DBSFMPF(iyear, flsev, flmod, canht, cande, mbasev, mbamod, mvolsev,
                 mvolmod, smksev, smkmod,
                 fmod_mod=Int32[0,0,0,0], fwt_mod=Float32[0,0,0,0],
                 fmod_sev=Int32[0,0,0,0], fwt_sev=Float32[0,0,0,0])
    IPOTFIRE == Int32(0) && return nothing
    # Fuel weights stored as percent: INT(WT*100 + 0.5)  (dbsfmpf.f:231-240)
    pct(v) = Float64(round(Int, Float64(v) * 100.0))
    fm(v, i) = Int(i <= length(v) ? v[i] : 0)
    _dbs_write_row("FVS_PotFire_East",
        "CaseID text not null,StandID text not null,Year int," *
        "Flame_Len_Sev real,Flame_Len_Mod real,Canopy_Ht int,Canopy_Density real," *
        "Mortality_BA_Sev real,Mortality_BA_Mod real,Mortality_VOL_Sev real,Mortality_VOL_Mod real," *
        "Pot_Smoke_Sev real,Pot_Smoke_Mod real," *
        "Fuel_Mod1_Sev int,Fuel_Mod2_Sev int,Fuel_Mod3_Sev int,Fuel_Mod4_Sev int," *
        "Fuel_Wt1_Sev real,Fuel_Wt2_Sev real,Fuel_Wt3_Sev real,Fuel_Wt4_Sev real," *
        "Fuel_Mod1_Mod int,Fuel_Mod2_Mod int,Fuel_Mod3_Mod int,Fuel_Mod4_Mod int," *
        "Fuel_Wt1_Mod real,Fuel_Wt2_Mod real,Fuel_Wt3_Mod real,Fuel_Wt4_Mod real",
        "CaseID,StandID,Year,Flame_Len_Sev,Flame_Len_Mod,Canopy_Ht,Canopy_Density," *
        "Mortality_BA_Sev,Mortality_BA_Mod,Mortality_VOL_Sev,Mortality_VOL_Mod," *
        "Pot_Smoke_Sev,Pot_Smoke_Mod," *
        "Fuel_Mod1_Sev,Fuel_Mod2_Sev,Fuel_Mod3_Sev,Fuel_Mod4_Sev," *
        "Fuel_Wt1_Sev,Fuel_Wt2_Sev,Fuel_Wt3_Sev,Fuel_Wt4_Sev," *
        "Fuel_Mod1_Mod,Fuel_Mod2_Mod,Fuel_Mod3_Mod,Fuel_Mod4_Mod," *
        "Fuel_Wt1_Mod,Fuel_Wt2_Mod,Fuel_Wt3_Mod,Fuel_Wt4_Mod",
        Any[CASEID, rstrip(NPLT), Int(iyear),
            Float64(flsev), Float64(flmod), Int(round(canht)), Float64(cande),
            Float64(mbasev), Float64(mbamod), Float64(mvolsev), Float64(mvolmod),
            Float64(smksev), Float64(smkmod),
            fm(fmod_sev,1), fm(fmod_sev,2), fm(fmod_sev,3), fm(fmod_sev,4),
            pct(fwt_sev[1]), pct(fwt_sev[2]), pct(fwt_sev[3]), pct(fwt_sev[4]),
            fm(fmod_mod,1), fm(fmod_mod,2), fm(fmod_mod,3), fm(fmod_mod,4),
            pct(fwt_mod[1]), pct(fwt_mod[2]), pct(fwt_mod[3]), pct(fwt_mod[4])])
    return nothing
end

# dbsfmpfc.f → FVS_PotFire_Cond (one row per wind/moisture scenario)
# kode 1 → "Severe", 2 → "Moderate"
function DBSFMPFC(nplt::AbstractString, windsp::Real, temp::Integer,
                  m1::Real, m2::Real, m3::Real, m4::Real, m5::Real, m6::Real, m7::Real,
                  kode::Integer)
    IPOTFIREC == Int32(0) && return nothing
    fcond = kode == 1 ? "Severe" : "Moderate"
    _dbs_write_row("FVS_PotFire_Cond",
        "CaseID text not null,StandID text not null,Fire_Condition text," *
        "Wind_Speed real,Temperature int,One_Hr_Moisture real,Ten_Hr_Moisture real," *
        "Hundred_Hr_Moisture real,Thousand_Hr_Moisture real,Duff_Moisture real," *
        "Live_Woody_Moisture real,Live_Herb_Moisture real",
        "CaseID,StandID,Fire_Condition,Wind_Speed,Temperature,One_Hr_Moisture," *
        "Ten_Hr_Moisture,Hundred_Hr_Moisture,Thousand_Hr_Moisture,Duff_Moisture," *
        "Live_Woody_Moisture,Live_Herb_Moisture",
        Any[CASEID, rstrip(nplt), fcond, Float64(windsp), Int(temp),
            Float64(m1), Float64(m2), Float64(m3), Float64(m4),
            Float64(m5), Float64(m6), Float64(m7)])
    return nothing
end

# dbsfmssnag.f → FVS_SnagSum
function DBSFMSSNAG(iyear, nplt, h1, h2, h3, h4, h5, h6, h7,
                    s1, s2, s3, s4, s5, s6, s7, hstot, kode)
    ISSUM == Int32(0) && return nothing
    _dbs_write_row("FVS_SnagSum",
        "CaseID text not null,StandID text not null,Year int null," *
        "Hard_snags_class1 real,Hard_snags_class2 real,Hard_snags_class3 real," *
        "Hard_snags_class4 real,Hard_snags_class5 real,Hard_snags_class6 real," *
        "Soft_snags_class1 real,Soft_snags_class2 real,Soft_snags_class3 real," *
        "Soft_snags_class4 real,Soft_snags_class5 real,Soft_snags_class6 real," *
        "Hard_soft_snags_total real",
        "CaseID,StandID,Year,Hard_snags_class1,Hard_snags_class2,Hard_snags_class3," *
        "Hard_snags_class4,Hard_snags_class5,Hard_snags_class6,Soft_snags_class1," *
        "Soft_snags_class2,Soft_snags_class3,Soft_snags_class4,Soft_snags_class5," *
        "Soft_snags_class6,Hard_soft_snags_total",
        Any[CASEID, rstrip(nplt), Int(iyear),
            Float64(h1), Float64(h2), Float64(h3), Float64(h4), Float64(h5), Float64(h6),
            Float64(s1), Float64(s2), Float64(s3), Float64(s4), Float64(s5), Float64(s6),
            Float64(hstot)])
    return nothing
end

# dbsfmdwvol.f → FVS_Down_Wood_Vol (8 hard + 8 soft from a length-16 vector)
function DBSFMDWVOL(iyear, nplt, v, vdim, kode_ref)
    IDWDVOL == Int32(0) && return nothing
    IDWDVOL == Int32(2) && (kode_ref[] = Int32(0))
    g(i) = (length(v) >= i ? Float64(v[i]) : 0.0)
    _dbs_write_row("FVS_Down_Wood_Vol",
        "CaseID text not null,StandID text not null,Year int null," *
        "DWD_Volume_0to3_Hard real,DWD_Volume_3to6_Hard real,DWD_Volume_6to12_Hard real," *
        "DWD_Volume_12to20_Hard real,DWD_Volume_20to35_Hard real,DWD_Volume_35to50_Hard real," *
        "DWD_Volume_ge_50_Hard real,DWD_Volume_Total_Hard real," *
        "DWD_Volume_0to3_Soft real,DWD_Volume_3to6_Soft real,DWD_Volume_6to12_Soft real," *
        "DWD_Volume_12to20_Soft real,DWD_Volume_20to35_Soft real,DWD_Volume_35to50_Soft real," *
        "DWD_Volume_ge_50_Soft real,DWD_Volume_Total_Soft real",
        "CaseID,StandID,Year,DWD_Volume_0to3_Hard,DWD_Volume_3to6_Hard,DWD_Volume_6to12_Hard," *
        "DWD_Volume_12to20_Hard,DWD_Volume_20to35_Hard,DWD_Volume_35to50_Hard,DWD_Volume_ge_50_Hard," *
        "DWD_Volume_Total_Hard,DWD_Volume_0to3_Soft,DWD_Volume_3to6_Soft,DWD_Volume_6to12_Soft," *
        "DWD_Volume_12to20_Soft,DWD_Volume_20to35_Soft,DWD_Volume_35to50_Soft,DWD_Volume_ge_50_Soft," *
        "DWD_Volume_Total_Soft",
        Any[CASEID, rstrip(nplt), Int(iyear),
            g(1), g(2), g(3), g(4), g(5), g(6), g(7), g(8),
            g(9), g(10), g(11), g(12), g(13), g(14), g(15), g(16)])
    return nothing
end

# dbsfmdwcov.f → FVS_Down_Wood_Cov (7 hard + 7 soft from a length-14 vector)
function DBSFMDWCOV(iyear, nplt, v, vdim, kode_ref)
    IDWDCOV == Int32(0) && return nothing
    IDWDCOV == Int32(2) && (kode_ref[] = Int32(0))
    g(i) = (length(v) >= i ? Float64(v[i]) : 0.0)
    _dbs_write_row("FVS_Down_Wood_Cov",
        "CaseID text not null,StandID text not null,Year int null," *
        "DWD_Cover_3to6_Hard real,DWD_Cover_6to12_Hard real,DWD_Cover_12to20_Hard real," *
        "DWD_Cover_20to35_Hard real,DWD_Cover_35to50_Hard real,DWD_Cover_ge_50_Hard real," *
        "DWD_Cover_Total_Hard real,DWD_Cover_3to6_Soft real,DWD_Cover_6to12_Soft real," *
        "DWD_Cover_12to20_Soft real,DWD_Cover_20to35_Soft real,DWD_Cover_35to50_Soft real," *
        "DWD_Cover_ge_50_Soft real,DWD_Cover_Total_Soft real",
        "CaseID,StandID,Year,DWD_Cover_3to6_Hard,DWD_Cover_6to12_Hard,DWD_Cover_12to20_Hard," *
        "DWD_Cover_20to35_Hard,DWD_Cover_35to50_Hard,DWD_Cover_ge_50_Hard,DWD_Cover_Total_Hard," *
        "DWD_Cover_3to6_Soft,DWD_Cover_6to12_Soft,DWD_Cover_12to20_Soft,DWD_Cover_20to35_Soft," *
        "DWD_Cover_35to50_Soft,DWD_Cover_ge_50_Soft,DWD_Cover_Total_Soft",
        Any[CASEID, rstrip(nplt), Int(iyear),
            g(1), g(2), g(3), g(4), g(5), g(6), g(7),
            g(8), g(9), g(10), g(11), g(12), g(13), g(14)])
    return nothing
end

# dbsfmhrpt.f → FVS_Hrv_Carbon (6 carbon-fate components)
function DBSFMHRPT(iyear, nplt, v, vdim, kode_ref)
    ICHRPT == Int32(0) && return nothing
    ICHRPT == Int32(2) && (kode_ref[] = Int32(0))
    g(i) = (length(v) >= i ? Float64(v[i]) : 0.0)
    _dbs_write_row("FVS_Hrv_Carbon",
        "CaseID text not null,StandID text not null,Year int," *
        "Products real,Landfill real,Energy real,Emissions real," *
        "Merch_Carbon_Stored real,Merch_Carbon_Removed real",
        "CaseID,StandID,Year,Products,Landfill,Energy,Emissions," *
        "Merch_Carbon_Stored,Merch_Carbon_Removed",
        Any[CASEID, rstrip(nplt), Int(iyear), g(1), g(2), g(3), g(4), g(5), g(6)])
    return nothing
end

function DBSFMDSNAG(args...); return nothing; end      # dbsfmdsnag.f: fire dead snag output
# dbsecsum.f → FVS_EconSummary (one row per investment period).
# Costs/revenues bind only when >= 0; IRR/BC/RRR/SEV/forest/repro bind only when
# their *Calculated flag is true (else NULL) — matching the Fortran.
function DBSECSUM(stdid, beginAnalYear, period, pretend,
                  costUndisc, revUndisc, costDisc, revDisc, pnv,
                  irr, irrCalc, bcRatio, bcCalc, rrr, rrrCalc, sev, sevCalc,
                  forestValue, fvCalc, reprodValue, rvCalc,
                  ft3Volume, bfVolume, discountRate, sevInput, sevInputUsed)
    IDBSECON == Int32(0) && return nothing
    nn(c, v) = c ? Float64(v) : missing
    _dbs_write_row("FVS_EconSummary",
        "CaseID text not null,StandID text not null,Year int null,Period int null," *
        "Pretend_Harvest text null,Undiscounted_Cost real null,Undiscounted_Revenue real null," *
        "Discounted_Cost real null,Discounted_Revenue real null,PNV real null,IRR real null," *
        "BC_Ratio real null,RRR real null,SEV real null,Value_of_Forest real null," *
        "Value_of_Trees real null,Mrch_Cubic_Volume int null,Mrch_BoardFoot_Volume int null," *
        "Discount_Rate real null,Given_SEV real null",
        "CaseID,StandID,Year,Period,Pretend_Harvest,Undiscounted_Cost,Undiscounted_Revenue," *
        "Discounted_Cost,Discounted_Revenue,PNV,IRR,BC_Ratio,RRR,SEV,Value_of_Forest," *
        "Value_of_Trees,Mrch_Cubic_Volume,Mrch_BoardFoot_Volume,Discount_Rate,Given_SEV",
        Any[CASEID, rstrip(stdid), Int(beginAnalYear), Int(period), pretend,
            nn(costUndisc >= 0, costUndisc), nn(revUndisc >= 0, revUndisc),
            nn(costDisc >= 0, costDisc), nn(revDisc >= 0, revDisc), Float64(pnv),
            nn(irrCalc, irr), nn(bcCalc, bcRatio), nn(rrrCalc, rrr), nn(sevCalc, sev),
            nn(fvCalc, forestValue), nn(rvCalc, reprodValue),
            Int(ft3Volume), Int(bfVolume), Float64(discountRate),
            nn(sevInputUsed, sevInput)])
    return nothing
end

# dbsecharv.f → FVS_EconHarvestValue. DBSECHARV_open creates the (here empty) table.
function DBSECHARV_open()
    IDBSECON == Int32(0) && return nothing
    DBSCASE(Int32(1))
    db = _dbs_out_db[]
    db === nothing && return nothing
    if !_dbs_table_exists(db, "FVS_EconHarvestValue")
        _dbs_exec(db, "CREATE TABLE FVS_EconHarvestValue (" *
            "CaseID text not null,Year int not null,SpeciesFVS text null," *
            "SpeciesPLANTS text not null,SpeciesFIA text null,Min_DIB real null," *
            "Max_DIB real null,Min_DBH real null,Max_DBH real null,TPA_Removed int null," *
            "TPA_Value int null,Tons_Per_Acre int null,Ft3_Removed int null,Ft3_Value int null," *
            "Board_Ft_Removed int null,Board_Ft_Value int null,Total_Value int null);")
    end
    return nothing
end
DBSECHARV(args...) = nothing   # per-species insert (no merch volume here → no rows)
function DBSFMCANPR(args...); return nothing; end      # dbsfmcanpr.f: fire canopy report
function DBSSPRT(args...); return nothing; end         # dbssprt.f: establishment sprout report

# ---------------------------------------------------------------------------
# DBSPPPUT / DBSPPGET: serialize/restore DBS integer state to/from checkpoint
# Translated from dbsppput.f (104 lines) + dbsppget.f (149 lines)
# Called from putstd.jl / getstd.jl during FVS stand state checkpointing.
# ---------------------------------------------------------------------------
function DBSPPPUT(wk3::AbstractVector{Float32}, ipnt_ref::Ref{Int32}, ilimit::Integer)
    ints = Int32[
        ISUMARY, ICOMPUTE, ITREELIST, IPOTFIRE, IFUELS, ITREEIN, ICUTLIST,
        IDM1, IDM2, IDM3, IDM5, IDM6, IFUELC, IBURN, IMORTF,
        ISSUM, ISDET, ISTRCLAS, IBMMAIN, IBMBKP, IBMTREE, IBMVOL,
        IDBSECON, ISPOUT6, ISPOUT17, ISPOUT21, ISPOUT23, ISPOUT30, ISPOUT31,
        IATRTLIST, I_CMPU, IADDCMPU, ICMRPT, ICHRPT, ICANPR, irgin,
        IDWDVOL, IDWDCOV,
        Int32(_dbs_in_db[]  !== nothing ? 1 : 0),
        Int32(_dbs_out_db[] !== nothing ? 1 : 0),
        ICLIM, IRD1, IRD2, IRD3, ICALIB, ISTATS1, ISTATS2,
        IREG1, IREG2, IREG3, IREG4, IREG5, IPOTFIREC,
        IVBCSUM, IVBCTRELST, IVBCCUTLST, IVBCATRLST
    ]
    LENSTRINGS[1] = Int32(length(DSNIN))
    LENSTRINGS[2] = Int32(length(DSNOUT))
    LENSTRINGS[3] = Int32(length(KEYFNAME))
    IFWRIT(wk3, ipnt_ref, ilimit, ints, 57, 2)
    lenv = copy(LENSTRINGS)
    IFWRIT(wk3, ipnt_ref, ilimit, lenv, 3, 2)
    DBSCLOSE(true, true)
    return nothing
end

function DBSPPGET(wk3::AbstractVector{Float32}, ipnt_ref::Ref{Int32}, ilimit::Integer)
    ints = zeros(Int32, 57)
    IFREAD(wk3, ipnt_ref, ilimit, ints, 57, 2)
    global ISUMARY   = ints[ 1];  global ICOMPUTE   = ints[ 2]
    global ITREELIST = ints[ 3];  global IPOTFIRE   = ints[ 4]
    global IFUELS    = ints[ 5];  global ITREEIN    = ints[ 6]
    global ICUTLIST  = ints[ 7];  global IDM1       = ints[ 8]
    global IDM2      = ints[ 9];  global IDM3       = ints[10]
    global IDM5      = ints[11];  global IDM6       = ints[12]
    global IFUELC    = ints[13];  global IBURN      = ints[14]
    global IMORTF    = ints[15];  global ISSUM      = ints[16]
    global ISDET     = ints[17];  global ISTRCLAS   = ints[18]
    global IBMMAIN   = ints[19];  global IBMBKP     = ints[20]
    global IBMTREE   = ints[21];  global IBMVOL     = ints[22]
    global IDBSECON  = ints[23];  global ISPOUT6    = ints[24]
    global ISPOUT17  = ints[25];  global ISPOUT21   = ints[26]
    global ISPOUT23  = ints[27];  global ISPOUT30   = ints[28]
    global ISPOUT31  = ints[29];  global IATRTLIST  = ints[30]
    global I_CMPU    = ints[31];  global IADDCMPU   = ints[32]
    global ICMRPT    = ints[33];  global ICHRPT     = ints[34]
    global ICANPR    = ints[35];  global irgin      = ints[36]
    global IDWDVOL   = ints[37];  global IDWDCOV    = ints[38]
    global ICLIM     = ints[41];  global IRD1       = ints[42]
    global IRD2      = ints[43];  global IRD3       = ints[44]
    global ICALIB    = ints[45];  global ISTATS1    = ints[46]
    global ISTATS2   = ints[47];  global IREG1      = ints[48]
    global IREG2     = ints[49];  global IREG3      = ints[50]
    global IREG4     = ints[51];  global IREG5      = ints[52]
    global IPOTFIREC = ints[53];  global IVBCSUM    = ints[54]
    global IVBCTRELST= ints[55];  global IVBCCUTLST = ints[56]
    global IVBCATRLST= ints[57]

    lenv = zeros(Int32, 3)
    IFREAD(wk3, ipnt_ref, ilimit, lenv, 3, 2)
    LENSTRINGS[1] = lenv[1]; LENSTRINGS[2] = lenv[2]; LENSTRINGS[3] = lenv[3]

    DBSCLOSE(true, true)
    if ints[39] == Int32(1)
        kode_r = Ref{Int32}(Int32(0))
        DBSOPEN(false, true, kode_r)
    end
    if ints[40] == Int32(1)
        kode_r = Ref{Int32}(Int32(0))
        DBSOPEN(true, false, kode_r)
    end
    return nothing
end

# DBSCHPUT / DBSCHGET: serialize/restore DBS character state (DSNIN, DSNOUT, KEYFNAME, CASEID)
function DBSCHPUT(cbuff::AbstractVector{UInt8}, ipnt_ref::Ref{Int32}, lncbuf::Int32)
    for ch in DSNIN;    CHWRIT(cbuff, ipnt_ref, Int(lncbuf), UInt8(ch), 2); end
    for ch in DSNOUT;   CHWRIT(cbuff, ipnt_ref, Int(lncbuf), UInt8(ch), 2); end
    for ch in KEYFNAME; CHWRIT(cbuff, ipnt_ref, Int(lncbuf), UInt8(ch), 2); end
    for j in 1:36
        b = j <= ncodeunits(CASEID) ? UInt8(CASEID[j]) : UInt8(' ')
        CHWRIT(cbuff, ipnt_ref, Int(lncbuf), b, 2)
    end
    DBSCLOSE(true, true)
    return nothing
end

function DBSCHGET(cbuff::AbstractVector{UInt8}, ipnt_ref::Ref{Int32}, lncbuf::Int32)
    ch_ref = Ref(UInt8(' '))
    if LENSTRINGS[1] > 0
        bytes = UInt8[]
        for _ in 1:LENSTRINGS[1]
            CHREAD(cbuff, ipnt_ref, Int(lncbuf), ch_ref, 2)
            push!(bytes, ch_ref[])
        end
        global DSNIN = String(bytes)
    end
    if LENSTRINGS[2] > 0
        bytes = UInt8[]
        for _ in 1:LENSTRINGS[2]
            CHREAD(cbuff, ipnt_ref, Int(lncbuf), ch_ref, 2)
            push!(bytes, ch_ref[])
        end
        global DSNOUT = String(bytes)
    end
    if LENSTRINGS[3] > 0
        bytes = UInt8[]
        for _ in 1:LENSTRINGS[3]
            CHREAD(cbuff, ipnt_ref, Int(lncbuf), ch_ref, 2)
            push!(bytes, ch_ref[])
        end
        global KEYFNAME = String(bytes)
    end
    cid = zeros(UInt8, 36)
    for j in 1:36
        CHREAD(cbuff, ipnt_ref, Int(lncbuf), ch_ref, 2)
        cid[j] = ch_ref[]
    end
    global CASEID = rstrip(String(cid))
    return nothing
end
