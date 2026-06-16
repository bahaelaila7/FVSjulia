# oplist.jl — OPLIST: write activity schedule / disposition summary
# Translated from: oplist.f (341 lines)
#
# If lfirst=true: write initial schedule; if false: write final disposition.

# Extension keyword name stubs (return "*UNKNOWN" until extensions are translated)
function ESKEY(key::Integer, kw_ref::Ref{String}); kw_ref[] = "*UNKNOWN"; return nothing; end
function TMKEY(key::Integer, kw_ref::Ref{String}); kw_ref[] = "*NO DFTM"; return nothing; end  # exdftm.f NODFTM
function MPKEY(key::Integer, kw_ref::Ref{String}); kw_ref[] = "*NO MPB "; return nothing; end  # exmpb.f NOMPB
function CVKEY(key::Integer, kw_ref::Ref{String}); kw_ref[] = "*NO COVR"; return nothing; end  # excov.f NOCOV
function DBSKEY(key::Integer, kw_ref::Ref{String}); kw_ref[] = "*UNKNOWN"; return nothing; end
function CLKEY(key::Integer, kw_ref::Ref{String}); kw_ref[] = "*NO CLIM"; return nothing; end  # exclim.f NOCLIM
function BRKEY(key::Integer, kw_ref::Ref{String}); kw_ref[] = "*NO BRUS"; return nothing; end  # exbrus.f NOBR
function MISKEY(key::Integer, kw_ref::Ref{String}); kw_ref[] = "*NO MIST"; return nothing; end  # exmist.f NOMIS
function BWEKEY(key::Integer, kw_ref::Ref{String}); kw_ref[] = "*NO WSBE"; return nothing; end  # exbudl.f NOKEY
function DFBKEY(key::Integer, kw_ref::Ref{String}); kw_ref[] = "*NO DFB "; return nothing; end  # exdfb.f NODFB
function BMKEY(key::Integer, kw_ref::Ref{String});  kw_ref[] = "**NO BM "; return nothing; end  # exbm.f NOBM
function RDKEY(key::Integer, kw_ref::Ref{String});  kw_ref[] = "*NO RROT"; return nothing; end  # exrd.f NORR
function FMKEY(key::Integer, kw_ref::Ref{String}); kw_ref[] = "*UNKNOWN"; return nothing; end   # fire: overridden by fmin.jl
function ECKEY(key::Integer, kw_ref::Ref{String}); kw_ref[] = "*UNKNOWN"; return nothing; end
# DBSCMPU — implemented in extensions/dbs/dbsqlite.jl
function ECOPLS(kw::AbstractString, id::Integer, prm::AbstractVector{Float32}, j1::Integer, j2::Integer)
    return nothing
end

const _OPLIST_NTRSLT = 148
const _OPLIST_ITRSL1 = Int32[
    33, 80, 81, 82, 90, 91, 92, 93, 94, 95,
    96, 97, 98, 99, 100, 101, 102, 110, 111, 120,
    198, 199, 200, 201, 202, 203, 204, 205, 206, 215,
    216, 217, 218, 222, 223, 224, 225, 226, 227, 228,
    229, 230, 231, 232, 233, 234, 235, 236, 237, 248,
    249, 250, 260, 427, 428, 429, 430, 431, 432, 440,
    442, 443, 444, 445, 450, 491, 492, 493, 555, 810,
    811, 900, 1001, 1002, 1003, 1004, 1005, 1006, 1007, 1008,
    1009, 2001, 2002, 2003, 2004, 2005, 2006, 2007, 2008, 2009,
    2150, 2151, 2152, 2153, 2154, 2155, 2156, 2157, 2158, 2159,
    2160, 2208, 2209, 2210, 2320, 2401, 2402, 2403, 2414, 2415,
    2416, 2417, 2430, 2431, 2432, 2433, 2501, 2505, 2506, 2507,
    2512, 2520, 2521, 2522, 2523, 2525, 2529, 2530, 2538, 2539,
    2548, 2549, 2550, 2553, 2554, 2605, 2606, 2607, 2608, 2609,
    2701, 2702, 2703, 2704, 2801, 2802, 2803, 2804,
]

const _OPLIST_ITRSL2 = Int32[
    33, 17, 96, 102, 3, 58, 62, 70, 59, 207,
    45, 88, 110, 111, 118, 616, 603, 38, 37, 138,
    135, 92, 48, 49, 71, 103, 107, 120, 144, 41,
    42, 43, 44, 23, 24, 25, 26, 27, 28, 29,
    30, 112, 115, 35, 122, 124, 129, 136, 141, 128,
    108, 78, 34, 216, 211, 212, 202, 203, 229, 213,
    215, 93, 145, 146, 226, 204, 230, 205, 406, 306,
    336, 512, 901, 902, 903, 904, 905, 906, 910, 911,
    916, 1001, 1004, 1005, 1002, 1007, 1010, 1011, 1023, 1024,
    1114, 1108, 1114, 1109, 1116, 1114, 1114, 1124, 1114, 1124,
    1114, 1208, 1209, 1210, 1320, 1401, 1402, 1403, 1414, 1415,
    1416, 1417, 1430, 1431, 1432, 1433, 1501, 1505, 1506, 1507,
    1512, 1520, 1521, 1522, 1523, 1525, 1533, 1534, 1538, 1539,
    1548, 1549, 1550, 1553, 1554, 1601, 1602, 1603, 1604, 1605,
    1301, 1302, 1303, 1304, 703, 704, 705, 706,
]

const _OPLIST_TAB2 = ("CMPU","BASE","ESTB","DFTM","MPB ","COVR",
                       "DBS ","CLIM","    ","RUST","MIST","WSBE","DFB ",
                       "WPBM","RDIS","FIRE","ECON")

function OPLIST(lfirst::Bool, nplt::AbstractString, mgmid::AbstractString, ititle::AbstractString)
    io = io_units[Int32(JOSTND)]
    imgl1 = Int(IMGL)

    if !lfirst && imgl1 == 1; return nothing; end

    titl = lfirst ? "SCHEDULE" : "SUMMARY "
    @printf(io, "\n\n%54sACTIVITY %s\n\nSTAND ID= %-26s    MGMT ID= %-4s    %-72s\n\n%s\n",
        "", titl, nplt, mgmid, ititle, repeat("-", 130))

    if lfirst
        @printf(io, "\nCYCLE  DATE  EXTENSION  KEYWORD   DATE  PARAMETERS:\n-----  ----  ---------  --------  ----  %s\n",
            repeat("-", 90))
    else
        @printf(io, "\nCYCLE  DATE  EXTENSION  KEYWORD   DATE  ACTIVITY DISPOSITION  PARAMETERS:\n-----  ----  ---------  --------  ----  %s  %s\n",
            repeat("-", 20), repeat("-", 68))
    end

    # Save and re-sort by accomplishment date if summary mode
    iopcyhld = copy(IOPCYC)
    if !lfirst
        i1 = imgl1 - 1
        for i in 1:i1
            IOPCYC[i] = IDATE[i]
            if IACT[i, 4] > 0; IDATE[i] = IACT[i, 4]; end
        end
        OPSORT(Int32(i1), IDATE, ISEQ, IOPSRT, true)
        OPCYCL(NCYC, IY)
        DBSCMPU()
        for i in 1:i1
            IDATE[i] = IOPCYC[i]
            IOPCYC[i] = iopcyhld[i]
        end
    end

    idispo = ("DELETED OR CANCELED ", "NOT DONE            ")
    line   = true

    for icy in 1:Int(NCYC)
        i1 = Int(IMGPTS[icy, 1])
        if i1 <= 0
            if line; @printf(io, "\n"); end
            line = false
            @printf(io, "%4d%7d\n", icy, Int(IY[icy]))
            continue
        end
        line = true
        @printf(io, "\n%4d%7d\n", icy, Int(IY[icy]))
        i2 = Int(IMGPTS[icy, 2])

        for ii in i1:i2
            i = Int(IOPSRT[ii])
            iactk = Int(IACT[i, 1])
            idt   = Int(IDATE[i])

            # Binary search for activity code in translation table
            key_ref = Ref(Int32(0))
            OPBISR(Int32(_OPLIST_NTRSLT), _OPLIST_ITRSL1, Int32(iactk), key_ref)
            key = Int(key_ref[])

            keywrd = "*UNKNOWN"
            loc    = 2
            if key > 0
                key = Int(_OPLIST_ITRSL2[key])
                loc = (key ÷ 100) + 1
                key2 = key < 200 ? mod(key, 200) : mod(key, 100)
                kw_ref = Ref("")
                if loc == 1 || loc == 2
                    if iactk == 33
                        idx_c = Int(floor(PARMS[Int(IACT[i, 2]) + 1]))
                        if idx_c > 500; idx_c -= 500; end
                        keywrd = length(CTSTV5) >= idx_c ? CTSTV5[idx_c] : "*UNKNOWN"
                        loc = 1
                    else
                        keywrd = length(TABLE) >= key2 ? TABLE[key2] : "*UNKNOWN"
                        loc = 2
                    end
                elseif loc == 3;  ESKEY(key2, kw_ref);  keywrd = kw_ref[]
                elseif loc == 4;  TMKEY(key2, kw_ref);  keywrd = kw_ref[]
                elseif loc == 5;  MPKEY(key2, kw_ref);  keywrd = kw_ref[]
                elseif loc == 6;  CVKEY(key2, kw_ref);  keywrd = kw_ref[]
                elseif loc == 7;  DBSKEY(key2, kw_ref); keywrd = kw_ref[]
                elseif loc == 8;  CLKEY(key2, kw_ref);  keywrd = kw_ref[]
                elseif loc == 10; BRKEY(key2, kw_ref);  keywrd = kw_ref[]
                elseif loc == 11; MISKEY(key2, kw_ref); keywrd = kw_ref[]
                elseif loc == 12; BWEKEY(key2, kw_ref); keywrd = kw_ref[]
                elseif loc == 13; DFBKEY(key2, kw_ref); keywrd = kw_ref[]
                elseif loc == 14; BMKEY(key2, kw_ref);  keywrd = kw_ref[]
                elseif loc == 15; RDKEY(key2, kw_ref);  keywrd = kw_ref[]
                elseif loc == 16; FMKEY(key2, kw_ref);  keywrd = kw_ref[]
                elseif loc == 17; ECKEY(key2, kw_ref);  keywrd = kw_ref[]
                end
            end

            tab2_str = 1 <= loc <= length(_OPLIST_TAB2) ? _OPLIST_TAB2[loc] : "    "
            j1 = Int(IACT[i, 2])

            if lfirst
                if j1 <= 0
                    @printf(io, "%16s%4s%25s%8s%6d\n", "", tab2_str, "", keywrd, idt)
                else
                    j2 = loc == 1 ? j1 : Int(IACT[i, 3])
                    pstr = join([@sprintf("%11.4f", PARMS[j]) for j in j1:j2], "")
                    @printf(io, "%16s%4s%25s%8s%6d%s\n", "", tab2_str, "", keywrd, idt, pstr)
                end
            else
                id_done = Int(IACT[i, 4])
                k = id_done <= 0 ? id_done + 2 : 0
                if j1 <= 0
                    if k == 0
                        @printf(io, "%16s%4s%25s%8s%6d  DONE IN%5d\n",
                            "", tab2_str, "", keywrd, idt, id_done)
                    else
                        @printf(io, "%16s%4s%25s%8s%6d  %s\n",
                            "", tab2_str, "", keywrd, idt, idispo[k])
                    end
                else
                    j2 = loc == 1 ? j1 : Int(IACT[i, 3])
                    pstr = join([@sprintf("%11.4f", PARMS[j]) for j in j1:j2], "")
                    if k == 0
                        @printf(io, "%16s%4s%25s%8s%6d  DONE IN%5d%s\n",
                            "", tab2_str, "", keywrd, idt, id_done, pstr)
                    else
                        @printf(io, "%16s%4s%25s%8s%6d  %s%s\n",
                            "", tab2_str, "", keywrd, idt, idispo[k], pstr)
                    end
                end
                ECOPLS(keywrd, id_done, PARMS, j1, j1 <= 0 ? j1 : Int(IACT[i, 3]))
            end
        end
    end
    @printf(io, "%s\n", repeat("-", 130))
    return nothing
end
