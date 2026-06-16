# base/prtrls.jl — PRTRLS: print/write tree lists + DBSTRLS/DBSATRTLS/DBSCUTS/DBS_FIAVBC_TRLS
# Translated from:
#   bin/FVSsn_buildDir/prtrls.f         (180 lines) — activity-driven tree list driver
#   bin/FVSsn_buildDir/dbstrls.f        (459 lines) — write FVS_TreeList to SQLite
#   bin/FVSsn_buildDir/dbsatrtls.f      (252 lines) — write FVS_ATRTList to SQLite
#   bin/FVSsn_buildDir/dbscuts.f        (251 lines) — write FVS_CutList to SQLite
#   bin/FVSsn_buildDir/dbs_fiavbc_trls.f (447 lines) — write FVS_FIAVBC_TreeList to SQLite

# ---------------------------------------------------------------------------
# DBSTRLS: write FVS_TreeList to SQLite (from dbstrls.f)
# IWHO: 1 = normal treelist call from fvs.f, 2 = cut tree call from cuts.f,
#        3 = after-treatment call from cuts.f
# KODE is set to 0 if this is a database-only redirect (no flat-file output)
# ---------------------------------------------------------------------------
function DBSTRLS(iwho::Integer, kode_ref::Ref{Int32}, tem::Float32)
    if ITREELIST == Int32(0) || iwho != 1
        return nothing
    end

    if ITREELIST == Int32(2)
        kode_ref[] = Int32(0)
    end

    DBSCASE(Int32(1))

    db = _dbs_out_db[]
    if db === nothing; return nothing; end

    idcmp1 = Int32(10000000)
    idcmp2 = Int32(20000000)
    tblname = "FVS_TreeList"

    if !_dbs_table_exists(db, tblname)
        _dbs_exec(db, """
            CREATE TABLE $tblname (
              CaseID text not null,
              StandID text not null,
              Year int null,
              PrdLen int null,
              TreeId text null,
              TreeIndex int null,
              SpeciesFVS text null,
              SpeciesPLANTS text null,
              SpeciesFIA text null,
              TreeVal int null,
              SSCD int null,
              PtIndex int null,
              TPA real null,
              MortPA real null,
              DBH real null,
              DG real null,
              Ht real null,
              HtG real null,
              PctCr int null,
              CrWidth real null,
              MistCD int null,
              BAPctile real null,
              PtBAL real null,
              TCuFt real null,
              MCuFt real null,
              SCuFt real null,
              BdFt real null,
              MDefect int null,
              BDefect int null,
              TruncHt int null,
              EstHt real null,
              ActPt int null,
              Ht2TDCF real null,
              Ht2TDBF real null,
              TreeAge real null
            );""")
        _dbs_exec(db, "CREATE INDEX IF NOT EXISTS idx_trls_stand ON $tblname(CaseID,StandID,Year);")
    else
        # ensure SCuFt column exists (added with NVB upgrade 2024)
        try; _dbs_exec(db, "ALTER TABLE $tblname ADD COLUMN SCuFt real"); catch; end
    end

    caseid_s  = CASEID
    standid_s = rstrip(NPLT)
    iyear     = Int(IY[ICYC + 1])

    stmt = SQLite.Stmt(db, """
        INSERT INTO $tblname
          (CaseID,StandID,Year,PrdLen,TreeId,TreeIndex,
           SpeciesFVS,SpeciesPLANTS,SpeciesFIA,
           TreeVal,SSCD,PtIndex,TPA,MortPA,DBH,DG,Ht,HtG,
           PctCr,CrWidth,MistCD,BAPctile,PtBAL,
           TCuFt,MCuFt,SCuFt,BdFt,
           MDefect,BDefect,TruncHt,EstHt,ActPt,Ht2TDCF,Ht2TDBF,TreeAge)
        VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
        """)

    idmr_ref = Ref{Int32}(Int32(0))

    DBInterface.execute(db, "BEGIN;")
    for ispc in 1:MAXSP
        i1 = ISCT[ispc, 1]
        i1 == 0 && continue
        i2 = ISCT[ispc, 2]
        for i3 in i1:i2
            i = Int(IND1[i3])

            p  = Float64(PROB[i] / GROSPC)
            dp = ICYC > 0 ? Float64(WK2[i] / GROSPC) : 0.0

            # Build tree ID string
            idt = IDTREE[i]
            if idt > idcmp2
                tid = @sprintf("CM%06d", idt - idcmp2)
            elseif idt > idcmp1
                tid = @sprintf("ES%06d", idt - idcmp1)
            else
                tid = string(idt)
            end

            MISGET(i, idmr_ref)
            idmr = Int(idmr_ref[])

            cw   = Float64(CRWDTH[i])
            icdf = div(mod(DEFECT[i], 10000), 100)
            ibdf = mod(DEFECT[i], 100)
            iptbal = round(Int, PTBALT[i])

            itrnk = div(ITRUNC[i] + 5, 100)

            estht = NORMHT[i] != 0 ? Float64((NORMHT[i] + 5) / 100) : Float64(HT[i])
            treage = LBIRTH[i] ? Float64(ABIRTH[i]) : 0.0

            dgi = Float64(DG[i])
            if ICYC == 0 && tem == Float32(0.0)
                dgi = Float64(WORK1[i])
            end

            sp_fvs   = rstrip(JSP[ISP[i]])
            sp_plants = rstrip(PLNJSP[ISP[i]])
            sp_fia   = rstrip(FIAJSP[ISP[i]])

            DBInterface.execute(stmt, [
                caseid_s, standid_s, iyear, Int(IFINT),
                tid, i,
                sp_fvs, sp_plants, sp_fia,
                Int(IMC[i]), Int(ISPECL[i]), Int(ITRE[i]),
                p, dp,
                Float64(DBH[i]), dgi, Float64(HT[i]), Float64(HTG[i]),
                Int(ICR[i]), cw, idmr,
                Float64(PCT[i]), Float64(iptbal),
                Float64(CFV[i]), Float64(MCFV[i]), Float64(SCFV[i]), Float64(BFV[i]),
                icdf, ibdf, itrnk,
                estht, Int(IPVEC[ITRE[i]]),
                Float64(HT2TD[i, 2]), Float64(HT2TD[i, 1]),
                treage
            ])
        end
    end

    # Cycle-0: also write dead trees at bottom of treelist
    if !(IREC2 >= MAXTP1 || ICYC >= 1)
        for i in IREC2:MAXTRE
            p = Float64(PROB[i] / GROSPC) / (FINT / FINTM)
            dp = p
            p  = 0.0

            idt = IDTREE[i]
            if idt > idcmp2
                tid = @sprintf("CM%06d", idt - idcmp2)
            elseif idt > idcmp1
                tid = @sprintf("ES%06d", idt - idcmp1)
            else
                tid = string(idt)
            end

            MISGET(i, idmr_ref); idmr = Int(idmr_ref[])
            cw     = Float64(CRWDTH[i])
            icdf   = div(mod(DEFECT[i], 10000), 100)
            ibdf   = mod(DEFECT[i], 100)
            iptbal = round(Int, PTBALT[i])
            itrnk  = div(ITRUNC[i] + 5, 100)
            estht  = NORMHT[i] != 0 ? Float64((NORMHT[i] + 5) / 100) : Float64(HT[i])
            treage = LBIRTH[i] ? Float64(ABIRTH[i]) : 0.0
            dgi    = Float64(DG[i])
            if ICYC == 0 && tem == Float32(0.0); dgi = Float64(WORK1[i]); end

            sp_fvs    = rstrip(JSP[ISP[i]])
            sp_plants = rstrip(PLNJSP[ISP[i]])
            sp_fia    = rstrip(FIAJSP[ISP[i]])

            DBInterface.execute(stmt, [
                caseid_s, standid_s, iyear, Int(IFINT),
                tid, i,
                sp_fvs, sp_plants, sp_fia,
                Int(IMC[i]), Int(ISPECL[i]), Int(ITRE[i]),
                p, dp,
                Float64(DBH[i]), dgi, Float64(HT[i]), Float64(HTG[i]),
                Int(ICR[i]), cw, idmr,
                Float64(PCT[i]), Float64(iptbal),
                Float64(CFV[i]), Float64(MCFV[i]), Float64(SCFV[i]), Float64(BFV[i]),
                icdf, ibdf, itrnk,
                estht, Int(IPVEC[ITRE[i]]),
                Float64(HT2TD[i, 2]), Float64(HT2TD[i, 1]),
                treage
            ])
        end
    end

    DBInterface.execute(db, "COMMIT;")
    SQLite.close(stmt)
    return nothing
end

# ---------------------------------------------------------------------------
# DBSATRTLS: write FVS_ATRTList to SQLite (from dbsatrtls.f, 252 lines)
# Called from PRTRLS with IWHO=3 (after-treatment tree list)
# ---------------------------------------------------------------------------
function DBSATRTLS(iwho::Integer, kode_ref::Ref{Int32}, tem::Float32)
    if IATRTLIST == Int32(0) || iwho != 3
        return nothing
    end

    if IATRTLIST == Int32(2)
        kode_ref[] = Int32(0)
    end

    DBSCASE(Int32(1))

    db = _dbs_out_db[]
    if db === nothing; return nothing; end

    idcmp1 = Int32(10000000)
    idcmp2 = Int32(20000000)
    tblname = "FVS_ATRTList"

    if !_dbs_table_exists(db, tblname)
        _dbs_exec(db, """
            CREATE TABLE $tblname (
              CaseID text not null,
              StandID text not null,
              Year int null,
              PrdLen int null,
              TreeId text null,
              TreeIndex int null,
              SpeciesFVS text null,
              SpeciesPLANTS text null,
              SpeciesFIA text null,
              TreeVal int null,
              SSCD int null,
              PtIndex int null,
              TPA real null,
              MortPA real null,
              DBH real null,
              DG real null,
              Ht real null,
              HtG real null,
              PctCr int null,
              CrWidth real null,
              MistCD int null,
              BAPctile real null,
              PtBAL real null,
              TCuFt real null,
              MCuFt real null,
              SCuFt real null,
              BdFt real null,
              MDefect int null,
              BDefect int null,
              TruncHt int null,
              EstHt real null,
              ActPt int null,
              Ht2TDCF real null,
              Ht2TDBF real null,
              TreeAge real null
            );""")
        try; _dbs_exec(db, "ALTER TABLE $tblname ADD COLUMN SCuFt real"); catch; end
    end

    caseid_s  = CASEID
    standid_s = rstrip(NPLT)
    jyr       = Int(IY[ICYC])

    stmt = SQLite.Stmt(db, """
        INSERT INTO $tblname
          (CaseID,StandID,Year,PrdLen,TreeId,TreeIndex,
           SpeciesFVS,SpeciesPLANTS,SpeciesFIA,
           TreeVal,SSCD,PtIndex,TPA,MortPA,DBH,DG,Ht,HtG,
           PctCr,CrWidth,MistCD,BAPctile,PtBAL,
           TCuFt,MCuFt,SCuFt,BdFt,
           MDefect,BDefect,TruncHt,EstHt,ActPt,Ht2TDCF,Ht2TDBF,TreeAge)
        VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
        """)

    idmr_ref = Ref{Int32}(Int32(0))

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
            if idt > idcmp2
                tid = @sprintf("CM%06d", idt - idcmp2)
            elseif idt > idcmp1
                tid = @sprintf("ES%06d", idt - idcmp1)
            else
                tid = string(idt)
            end

            MISGET(i, idmr_ref); idmr = Int(idmr_ref[])
            cw     = Float64(CRWDTH[i])
            icdf   = div(mod(DEFECT[i], 10000), 100)
            ibdf   = mod(DEFECT[i], 100)
            iptbal = round(Int, PTBALT[i])
            itrnk  = div(ITRUNC[i] + 5, 100)
            estht  = NORMHT[i] != 0 ? Float64((NORMHT[i] + 5) / 100) : Float64(HT[i])
            treage = LBIRTH[i] ? Float64(ABIRTH[i]) : 0.0
            dgi    = Float64(DG[i])

            sp_fvs    = rstrip(JSP[ISP[i]])
            sp_plants = rstrip(PLNJSP[ISP[i]])
            sp_fia    = rstrip(FIAJSP[ISP[i]])

            DBInterface.execute(stmt, [
                caseid_s, standid_s, jyr, Int(IFINT),
                tid, i,
                sp_fvs, sp_plants, sp_fia,
                Int(IMC[i]), Int(ISPECL[i]), Int(ITRE[i]),
                p, 0.0,
                Float64(DBH[i]), dgi, Float64(HT[i]), Float64(HTG[i]),
                Int(ICR[i]), cw, idmr,
                Float64(PCT[i]), Float64(iptbal),
                Float64(CFV[i]), Float64(MCFV[i]), Float64(SCFV[i]), Float64(BFV[i]),
                icdf, ibdf, itrnk,
                estht, Int(IPVEC[ITRE[i]]),
                Float64(HT2TD[i, 2]), Float64(HT2TD[i, 1]),
                treage
            ])
        end
    end
    DBInterface.execute(db, "COMMIT;")
    SQLite.close(stmt)
    return nothing
end

# ---------------------------------------------------------------------------
# DBSCUTS: write FVS_CutList to SQLite (from dbscuts.f, 251 lines)
# Called from PRTRLS with IWHO=2 (cut tree list)
# WK3(I) holds the cut TPA for each tree.
# ---------------------------------------------------------------------------
function DBSCUTS(iwho::Integer, kode_ref::Ref{Int32})
    if ICUTLIST == Int32(0) || iwho != 2
        return nothing
    end

    if ICUTLIST == Int32(2)
        kode_ref[] = Int32(0)
    end

    DBSCASE(Int32(1))

    db = _dbs_out_db[]
    if db === nothing; return nothing; end

    idcmp1 = Int32(10000000)
    idcmp2 = Int32(20000000)
    tblname = "FVS_CutList"

    if !_dbs_table_exists(db, tblname)
        _dbs_exec(db, """
            CREATE TABLE $tblname (
              CaseID text not null,
              StandID text not null,
              Year int null,
              PrdLen int null,
              TreeId text null,
              TreeIndex int null,
              SpeciesFVS text null,
              SpeciesPLANTS text null,
              SpeciesFIA text null,
              TreeVal int null,
              SSCD int null,
              PtIndex int null,
              TPA real null,
              MortPA real null,
              DBH real null,
              DG real null,
              Ht real null,
              HtG real null,
              PctCr int null,
              CrWidth real null,
              MistCD int null,
              BAPctile real null,
              PtBAL real null,
              TCuFt real null,
              MCuFt real null,
              SCuFt real null,
              BdFt real null,
              MDefect int null,
              BDefect int null,
              TruncHt int null,
              EstHt real null,
              ActPt int null,
              Ht2TDCF real null,
              Ht2TDBF real null,
              TreeAge real null
            );""")
        try; _dbs_exec(db, "ALTER TABLE $tblname ADD COLUMN SCuFt real"); catch; end
    end

    caseid_s  = CASEID
    standid_s = rstrip(NPLT)
    jyr       = Int(IY[ICYC])

    stmt = SQLite.Stmt(db, """
        INSERT INTO $tblname
          (CaseID,StandID,Year,PrdLen,TreeId,TreeIndex,
           SpeciesFVS,SpeciesPLANTS,SpeciesFIA,
           TreeVal,SSCD,PtIndex,TPA,MortPA,DBH,DG,Ht,HtG,
           PctCr,CrWidth,MistCD,BAPctile,PtBAL,
           TCuFt,MCuFt,SCuFt,BdFt,
           MDefect,BDefect,TruncHt,EstHt,ActPt,Ht2TDCF,Ht2TDBF,TreeAge)
        VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
        """)

    idmr_ref = Ref{Int32}(Int32(0))

    DBInterface.execute(db, "BEGIN;")
    for ispc in 1:MAXSP
        i1 = ISCT[ispc, 1]
        i1 == 0 && continue
        i2 = ISCT[ispc, 2]
        for i3 in i1:i2
            i = Int(IND1[i3])
            p = Float64(WK3[i] / GROSPC)
            p <= 0.0 && continue

            idt = IDTREE[i]
            if idt > idcmp2
                tid = @sprintf("CM%06d", idt - idcmp2)
            elseif idt > idcmp1
                tid = @sprintf("ES%06d", idt - idcmp1)
            else
                tid = string(idt)
            end

            MISGET(i, idmr_ref); idmr = Int(idmr_ref[])
            cw     = Float64(CRWDTH[i])
            icdf   = div(mod(DEFECT[i], 10000), 100)
            ibdf   = mod(DEFECT[i], 100)
            iptbal = round(Int, PTBALT[i])
            itrnk  = div(ITRUNC[i] + 5, 100)
            estht  = NORMHT[i] != 0 ? Float64((NORMHT[i] + 5) / 100) : Float64(HT[i])
            treage = LBIRTH[i] ? Float64(ABIRTH[i]) : 0.0
            dgi    = Float64(DG[i])

            sp_fvs    = rstrip(JSP[ISP[i]])
            sp_plants = rstrip(PLNJSP[ISP[i]])
            sp_fia    = rstrip(FIAJSP[ISP[i]])

            DBInterface.execute(stmt, [
                caseid_s, standid_s, jyr, Int(IFINT),
                tid, i,
                sp_fvs, sp_plants, sp_fia,
                Int(IMC[i]), Int(ISPECL[i]), Int(ITRE[i]),
                p, 0.0,
                Float64(DBH[i]), dgi, Float64(HT[i]), Float64(HTG[i]),
                Int(ICR[i]), cw, idmr,
                Float64(PCT[i]), Float64(iptbal),
                Float64(CFV[i]), Float64(MCFV[i]), Float64(SCFV[i]), Float64(BFV[i]),
                icdf, ibdf, itrnk,
                estht, Int(IPVEC[ITRE[i]]),
                Float64(HT2TD[i, 2]), Float64(HT2TD[i, 1]),
                treage
            ])
        end
    end
    DBInterface.execute(db, "COMMIT;")
    SQLite.close(stmt)
    return nothing
end

# ---------------------------------------------------------------------------
# PRTRLS: activity-driven tree list driver (from prtrls.f, 180 lines)
#
# IWHO=1 — normal cycle call (activity 80 = TREELIST)
# IWHO=2 — after-cut call (activity 199 = CUTLIST)
# IWHO=3 — after-treatment call (activity 198 = ATRTLIST)
#
# The Fortran also writes formatted text tree lists to file. We implement
# only the SQLite path here (DBSTRLS/DBSATRTLS/DBSCUTS); text output is
# deferred pending full FORMAT translation.
# ---------------------------------------------------------------------------
function PRTRLS(iwho::Integer)
    myact = Int32[80, 199, 198]
    myact_v = Int32[myact[iwho]]   # 1-element vector for OPFIND(nmya=1, ...)

    ntodo_ref = Ref{Int32}(Int32(0))
    OPFIND(Int32(1), myact_v, ntodo_ref)
    ntodo = ntodo_ref[]
    ntodo == 0 && return nothing

    # Duplicate detection: store up to 5 unique requests per cycle
    dupchk = zeros(Float32, 5, 5)
    numreq = 0

    tem = zeros(Float32, 6)
    idt_ref = Ref{Int32}(Int32(0))
    iactk_ref = Ref{Int32}(Int32(0))
    nprms_ref = Ref{Int32}(Int32(0))

    for itodo in 1:ntodo
        OPGET(Int32(itodo), Int32(6), idt_ref, iactk_ref, nprms_ref, tem)
        iactk_ref[] < 0 && continue

        nprms = nprms_ref[]

        # Duplicate check (skip if > 1 request)
        if ntodo > 1
            if itodo == 1
                dupchk[1, 1] = tem[1]; dupchk[1, 2] = tem[2]
                dupchk[1, 3] = tem[3]; dupchk[1, 4] = tem[4]
                dupchk[1, 5] = tem[6]
                numreq = 1
            else
                is_dup = false
                for ii in 1:numreq
                    if tem[1] == dupchk[ii,1] && tem[2] == dupchk[ii,2] &&
                       tem[3] == dupchk[ii,3] && tem[4] == dupchk[ii,4] &&
                       tem[6] == dupchk[ii,5]
                        is_dup = true; break
                    end
                end
                is_dup && continue
                if numreq < 5
                    numreq += 1
                    dupchk[numreq, 1] = tem[1]; dupchk[numreq, 2] = tem[2]
                    dupchk[numreq, 3] = tem[3]; dupchk[numreq, 4] = tem[4]
                    dupchk[numreq, 5] = tem[6]
                end
            end
        end

        # Determine report year and mark done
        if iwho == 1
            jyr = Int(IY[ICYC + 1])
            if LSTART
                nprms >= 3 && tem[3] == Float32(1.0) && continue
                nprms >= 3 && tem[3] == Float32(2.0) && OPDONE(Int32(itodo), jyr)
            else
                nprms >= 3 && tem[3] == Float32(2.0) && continue
                OPDONE(Int32(itodo), jyr - 1)
            end
        elseif iwho == 2
            jyr = Int(IY[ICYC])
            LSTART || OPDONE(Int32(itodo), jyr)
        else
            jyr = Int(IY[ICYC])
            LSTART || OPDONE(Int32(itodo), jyr)
        end

        # Call SQLite output functions
        dbskode = Ref{Int32}(Int32(1))
        DBSTRLS(iwho, dbskode, tem[6])
        dbskode[] == Int32(0) && return nothing

        dbskode[] = Int32(1)
        DBSATRTLS(iwho, dbskode, tem[6])
        dbskode[] == Int32(0) && return nothing

        dbskode[] = Int32(1)
        DBSCUTS(iwho, dbskode)
        dbskode[] == Int32(0) && return nothing

        # Text output: open file if KOLIST > 0; currently no-op pending FORMAT translation
        kolist = Int(floor(tem[1]))
        if kolist != 0
            openIfClosed(Int32(abs(kolist)), "trl")
        end
    end
    return nothing
end

# ---------------------------------------------------------------------------
# DBS_FIAVBC_TRLS: write FVS_FIAVBC_TreeList to SQLite (from dbs_fiavbc_trls.f, 447 lines)
# Outputs per-tree biomass + carbon from the FIAVBC Jenkins/CRM calculations.
# Called from FVS! at each reporting year when IVBCTRELST != 0.
# ---------------------------------------------------------------------------
function DBS_FIAVBC_TRLS()
    IVBCTRELST == Int32(0) && return nothing
    if !LFIANVB
        ERRGRO(true, Int32(52))
        return nothing
    end

    DBSCASE(Int32(1))

    db = _dbs_out_db[]
    db === nothing && return nothing

    idcmp1 = Int32(10000000)
    idcmp2 = Int32(20000000)
    tblname = "FVS_FIAVBC_TreeList"

    if !_dbs_table_exists(db, tblname)
        _dbs_exec(db, """
            CREATE TABLE $tblname (
              CaseID text not null,
              StandID text not null,
              PtIndex int null,
              ActPt int null,
              Year int null,
              TreeId text null,
              TreeIndex int null,
              SpeciesFVS text null,
              SpeciesPLANTS text null,
              SpeciesFIA text null,
              TPA real null,
              MortTPA real null,
              DBH real null,
              Ht real null,
              EstHt real null,
              TruncHt int null,
              PctCr int null,
              Cull real null,
              WdldStem int null,
              DecayCd int null,
              CarbFrac real null,
              TCuFt real null,
              MCuFt real null,
              SCuFt real null,
              AbvGrdBio real null,
              MerchBio real null,
              SawBio real null,
              FoliBio real null,
              AbvGrdCarb real null,
              MerchCarb real null,
              SawCarb real null,
              FoliCarb real null
            );""")
    end

    caseid_s  = CASEID
    standid_s = rstrip(NPLT)
    iyear     = Int(IY[ICYC + 1])

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

    itplab = 1

    DBInterface.execute(db, "BEGIN;")
    for ispc in 1:MAXSP
        i1 = ISCT[ispc, 1]
        i1 == 0 && continue
        i2 = ISCT[ispc, 2]
        for i3 in i1:i2
            i = Int(IND1[i3])

            p  = Float64(PROB[i] / GROSPC)
            dp = ICYC > 0 ? Float64(WK2[i] / GROSPC) : 0.0

            idt = IDTREE[i]
            if idt > idcmp2
                tid = @sprintf("CM%06d", idt - idcmp2)
            elseif idt > idcmp1
                tid = @sprintf("ES%06d", idt - idcmp1)
            else
                tid = string(idt)
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
                p, dp,
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

    # Cycle-0: also write dead trees at bottom of treelist
    if IVBCTRELST != Int32(0) && !(IREC2 >= MAXTP1 || itplab == 3 || ICYC >= 1)
        for i in IREC2:MAXTRE
            p   = Float64(PROB[i] / GROSPC) / (Float64(FINT) / Float64(FINTM))
            dp  = p
            p   = 0.0
            tid = string(IDTREE[i])

            itrnk = div(Int(ITRUNC[i]) + 5, 100)
            estht = NORMHT[i] > Int32(0) ? Float64((NORMHT[i] + 5) / 100) : 0.0

            sp_fvs    = rstrip(JSP[ISP[i]])
            sp_plants = rstrip(PLNJSP[ISP[i]])
            sp_fia    = rstrip(FIAJSP[ISP[i]])

            DBInterface.execute(stmt, [
                caseid_s, standid_s,
                Int(ITRE[i]), Int(IPVEC[ITRE[i]]),
                iyear, tid, i,
                sp_fvs, sp_plants, sp_fia,
                p, dp,
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

    DBInterface.execute(db, "COMMIT;")
    SQLite.close(stmt)
    return nothing
end
