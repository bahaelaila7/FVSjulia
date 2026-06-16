# blkdat.f — SN variant BLOCK DATA translated to Julia initialization function
# Fortran: BLOCK DATA BLKDAT → Julia function BLKDAT!() called at module init

"""
    BLKDAT!()

Initialize all FVSsn species data, coefficient defaults, and IO unit assignments.
Equivalent to Fortran BLOCK DATA BLKDAT in sn/blkdat.f.
Must be called once during module initialization, before any simulation begins.
"""
function BLKDAT!()

# ---------------------------------------------------------------------------
# COR2, HCOR2, RCOR2, BKRAT — initialized to 1.0 or 0.0
# ---------------------------------------------------------------------------
fill!(COR2,  Float32(1.0))
fill!(HCOR2, Float32(1.0))
fill!(RCOR2, Float32(1.0))
fill!(BKRAT, Float32(0.0))

# ---------------------------------------------------------------------------
# Tree record format string (used by INTREE to parse .tre file)
# ---------------------------------------------------------------------------
global TREFMT = "(I4,T1,I7,F6.0,I1,A3,F4.1,F3.1,2F3.0,F4.1,I1,3(I2,I2),2I1,I2,2I3,2I1,F3.0)"

# ---------------------------------------------------------------------------
# Control defaults
# ---------------------------------------------------------------------------
global YR     = Float32(5.0)
global IRECNT = Int32(0)
global ICCODE = Int32(0)

# IO unit assignments (override contrl.jl defaults per BLOCK DATA)
global IREAD  = Int32(15)
global ISTDAT = Int32(2)
global JOLIST = Int32(3)
global JOSTND = Int32(16)
global JOSUM  = Int32(4)
global JOTREE = Int32(8)

# ---------------------------------------------------------------------------
# Establishment model — XMIN: min probability value by species (NSPSPE=72)
# ---------------------------------------------------------------------------
XMIN[1:72] .= Float32.([
   0.50, 2.08, 0.50, 1.00, 1.32, 2.51, 0.50, 2.53, 2.75, 0.50,
   5.05, 0.50, 4.70, 0.50, 1.33, 1.33, 0.66, 2.40, 1.35, 1.35,
   2.03, 0.50, 0.50, 0.50, 0.50, 2.08, 0.51, 0.63, 2.08, 2.08,
   2.08, 2.08, 0.50, 0.50, 0.50, 0.92, 0.50, 5.98, 0.94, 2.08,
   0.50, 3.28, 3.28, 1.33, 0.89, 1.53, 1.38, 3.59, 3.59, 3.59,
   2.08, 2.08, 4.15, 3.59, 3.59, 2.08, 2.08, 2.08, 0.89, 0.50,
   0.50, 0.50, 1.38, 1.38, 1.38, 0.50, 2.75, 2.75, 0.50, 2.75,
   0.50, 1.38
])

# DBHMID: midpoint DBH per stump DBH class (NDBHCL=10)
DBHMID[1:10] .= Float32.([1.0, 3.0, 5.0, 7.0, 9.0, 12.0, 16.0, 20.0, 24.0, 28.0])

# ISPSPE: sprouting species indices (NSPSPE=72)
ISPSPE[1:72] .= Int32.([
    5,15,16,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,
   34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,
   52,53,54,55,56,57,59,60,61,62,63,64,65,66,67,68,69,70,
   71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87
])

# BNORML: normal distribution discretization (20 values)
BNORML[1:20] .= Float32.([
    1.0,   1.0,   1.0,   1.046, 1.093, 1.139, 1.186, 1.232,
    1.278, 1.325, 1.371, 1.418, 1.464, 1.510, 1.557, 1.603,
    1.649, 1.696, 1.742, 1.789
])

# HHTMAX: max height for establishment by species (90 species)
HHTMAX[1:11] .= Float32.([23.0, 27.0, 21.0, 21.0, 22.0, 20.0, 24.0, 18.0, 18.0, 17.0, 22.0])
HHTMAX[12:90] .= Float32(20.0)

# IFORCD / IFORST: national forest codes and forest type codes (MXFRCDS=20)
IFORCD[1:20] .= Int32.([103,104,105,106,621,110,113,114,116,117,
                         118,109,111,112,412,402,108,102,115,  0])
IFORST[1:20] .= Int32.([  3,  4,  5,  4,  7, 10,  4, 14, 16, 17,
                            4,  9, 11, 12, 19, 20, 11,  9, 12,  4])

# OCURHT, OCURNF zeroed out (already zeros from array initialization)
fill!(OCURHT, Float32(0.0))
fill!(OCURNF, Float32(0.0))

# ---------------------------------------------------------------------------
# Species codes for 90 Southern variant species
# JSP = 4-char alpha code, FIAJSP = 3-char FIA SPCD, PLNJSP = 6-char PLANTS
# NSP(I,1..3) = species-tree class codes (suffix 1, 2, or 3)
# ---------------------------------------------------------------------------
_jsp = [
    "FR  ","JU  ","PI  ","PU  ","SP  ","SA  ","SR  ","LL  ","TM  ","PP  ",
    "PD  ","WP  ","LP  ","VP  ","BY  ","PC  ","HM  ","FM  ","BE  ","RM  ",
    "SV  ","SM  ","BU  ","BB  ","SB  ","AH  ","HI  ","CA  ","HB  ","RD  ",
    "DW  ","PS  ","AB  ","AS  ","WA  ","BA  ","GA  ","HL  ","LB  ","HA  ",
    "HY  ","BN  ","WN  ","SU  ","YP  ","MG  ","CT  ","MS  ","MV  ","ML  ",
    "AP  ","MB  ","WT  ","BG  ","TS  ","HH  ","SD  ","RA  ","SY  ","CW  ",
    "BT  ","BC  ","WO  ","SO  ","SK  ","CB  ","TO  ","LK  ","OV  ","BJ  ",
    "SN  ","CK  ","WK  ","CO  ","RO  ","QS  ","PO  ","BO  ","LO  ","BK  ",
    "WI  ","SS  ","BD  ","EL  ","WE  ","AE  ","RL  ","OS  ","OH  ","OT  "
]
for i in 1:90; JSP[i] = _jsp[i]; end

_fiajsp = [
    "010","057","090","107","110","111","115","121","123","126",
    "128","129","131","132","221","222","260","311","313","316",
    "317","318","330","370","372","391","400","450","460","471",
    "491","521","531","540","541","543","544","552","555","580",
    "591","601","602","611","621","650","651","652","653","654",
    "660","680","691","693","694","701","711","721","731","740",
    "743","762","802","806","812","813","819","820","822","824",
    "825","826","827","832","833","834","835","837","838","901",
    "920","931","950","970","971","972","975","299","998","999"
]
for i in 1:90; FIAJSP[i] = _fiajsp[i]; end

_plnjsp = [
    "ABIES ","JUNIP ","PICEA ","PICL  ","PIEC2 ","PIEL  ","PIGL2 ",
    "PIPA2 ","PIPU5 ","PIRI  ","PISE  ","PIST  ","PITA  ","PIVI2 ",
    "TADI2 ","TAAS  ","TSUGA ","ACBA3 ","ACNE2 ","ACRU  ","ACSA2 ",
    "ACSA3 ","AESCU ","BETUL ","BELE  ","CACA18","CARYA ","CATAL ",
    "CELTI ","CECA4 ","COFL2 ","DIVI5 ","FAGR  ","FRAXI ","FRAM2 ",
    "FRNI  ","FRPE  ","GLTR  ","GOLA  ","HALES ","ILOP  ","JUCI  ",
    "JUNI  ","LIST2 ","LITU  ","MAGNO ","MAAC  ","MAGR4 ","MAVI2 ",
    "MAMA2 ","MALUS ","MORUS ","NYAQ2 ","NYSY  ","NYBI  ","OSVI  ",
    "OXAR  ","PEBO  ","PLOC  ","POPUL ","POGR4 ","PRSE2 ","QUAL  ",
    "QUCO2 ","QUFA  ","QUPA5 ","QULA2 ","QULA3 ","QULY  ","QUMA3 ",
    "QUMI  ","QUMU  ","QUNI  ","QUPR2 ","QURU  ","QUSH  ","QUST  ",
    "QUVE  ","QUVI  ","ROPS  ","SALIX ","SAAL5 ","TILIA ","ULMUS ",
    "ULAL  ","ULAM  ","ULRU  ","2TN   ","2TB   ","2TREE "
]
for i in 1:90; PLNJSP[i] = _plnjsp[i]; end

# JTYPE — valid habitat type codes (122 entries)
_jtype = Int32.([
    10,100,110,130,140,160,170,180,190,200,
   210,220,230,250,260,280,290,310,320,330,
   340,350,360,370,380,400,410,420,430,440,
   450,460,470,480,500,501,502,505,506,510,
   515,516,520,529,530,540,545,550,555,560,
   565,570,575,579,590,600,610,620,630,635,
   640,650,660,670,675,680,685,690,700,701,
   710,720,730,740,750,770,780,790,800,810,
   820,830,840,850,860,870,890,900,910,920,
   925,930,940,950,999,
   zeros(Int32, 27)...
])
for i in 1:122; JTYPE[i] = _jtype[i]; end

# NSP — species-tree class codes (suffix 1, 2, 3)
for i in 1:90
    code = rstrip(_jsp[i])
    NSP[i, 1] = "$(code)1"
    NSP[i, 2] = "$(code)2"
    NSP[i, 3] = "$(code)3"
end

# ---------------------------------------------------------------------------
# SIGMAR — diameter growth regression std errors (90 species)
# ---------------------------------------------------------------------------
SIGMAR[1:90] .= Float32.([
    0.451100, 0.529700, 0.451100, 0.542800, 0.498700,
    0.525100, 0.436700, 0.441000, 0.469300, 0.552500,
    0.592100, 0.493700, 0.468700, 0.469300, 0.551100,
    0.626700, 0.451100, 0.563200, 0.560800, 0.593000,
    0.593000, 0.475500, 0.537300, 0.569600, 0.569600,
    0.603200, 0.499300, 0.440100, 0.527600, 0.545300,
    0.538200, 0.516000, 0.480500, 0.595800, 0.422800,
    0.485600, 0.485600, 0.468200, 0.590800, 0.599600,
    0.546900, 0.571000, 0.571000, 0.577900, 0.518100,
    0.572700, 0.512600, 0.570300, 0.572700, 0.570300,
    0.505600, 0.505600, 0.569800, 0.535600, 0.588800,
    0.577300, 0.504700, 0.568700, 0.557000, 0.440100,
    0.440100, 0.578100, 0.440700, 0.382700, 0.430500,
    0.400000, 0.495700, 0.558600, 0.465900, 0.464900,
    0.491300, 0.505600, 0.466400, 0.429300, 0.404800,
    0.407400, 0.485300, 0.421900, 0.663500, 0.518700,
    0.450800, 0.450400, 0.549600, 0.644700, 0.528600,
    0.536400, 0.535000, 0.529700, 0.577300, 0.557600
])

# ---------------------------------------------------------------------------
# Other scalar defaults
# ---------------------------------------------------------------------------
global REGNBK  = Float32(2.999)
global S0      = Float64(55329.0)
global SS      = Float32(55329.0)
global LSCRN   = false
global JOSCRN  = Int32(6)
global JOSUME  = Int32(13)
global KOLIST  = Int32(27)
global FSTOPEN = false

return nothing
end # function BLKDAT!
