# econ/ecsetp.f + ecstatus.f + eccalc.f — ECON start setup + per-cycle cost/revenue.
#
# Scope: the sn.key test exercises only ANNUCST (a flat annual management cost) with
# no discount rate (no STRTECON) and no merchantable-volume-based revenue/cost
# (Julia's simplified NATCRS volume path produces no merch volume, so the Fortran's
# harvest/PCT valuation is 0 here too). This implements that path faithfully:
#   ECSETP  registers a default ECON_START_YEAR event at the inventory year when no
#           STRTECON keyword is present (ecsetp.f:32-35).
#   ECSTATUS consumes that event to set econStartYear (+ discount rate) (ecstatus.f).
#   ECCALC  accumulates annual costs per cycle and writes one FVS_EconSummary row.
# Full discounting/SEV/IRR and volume-based valuation are future work (need the NVEL
# volume library); they are NULL/0 for this test, matching the Fortran baseline.

_ec_pv(amt::Real, time::Integer, rate::Real) =
    amt <= 0.0f0 ? 0.0f0 : Float32(amt) / (1.0f0 + Float32(rate))^Int(time)

# ecinit.f — reset ECON control + accumulators before each stand (called from INITRE).
# Essential so an Econ block on one stand doesn't leak to the next.
function ECINIT(args...)
    global discountRate  = 0.0f0
    global econStartYear = Int32(-9999)
    global noOutputTables = false
    global isEconToBe    = false
    global isFirstEcon   = true
    global doSev         = false
    global sevInput      = 0.0f0
    global annCostCnt_EC = Int32(0)
    global annRevCnt_EC  = Int32(0)
    fill!(annCostAmt_EC, 0.0f0)
    fill!(annRevAmt_EC, 0.0f0)
    global costUndisc = 0.0f0; global costDisc = 0.0f0
    global revUndisc  = 0.0f0; global revDisc  = 0.0f0
    global startYear_EC = Int32(0)
    fill!(undiscCost, 0.0f0); fill!(undiscRev, 0.0f0)
    global isPretendActive = false
    global pretendStartYear = Int32(0)
    global pretendEndYear   = Int32(0)
    return nothing
end

# ecsetp.f — called from FVS (cycle 0) after all keywords are read.
function ECSETP(iy::AbstractVector)
    if !isEconToBe
        global econStartYear = Int32(9999)
        return nothing
    end
    # No STRTECON keyword → register a default ECON start at the inventory year.
    if econStartYear == Int32(-9999)
        local parms = zeros(Float32, 3)
        local kode = Ref(Int32(0))
        OPNEW(kode, Int32(iy[1]), ECON_START_YEAR_ACT, Int32(3), parms)
        global econStartYear = Int32(9999)
    end
    return nothing
end

# ecstatus.f — called from GRINCR (before & after cuts) each cycle.
function ECSTATUS(icyc::Integer, ncyc::Integer, iy::AbstractVector, beforecuts::Integer)
    if !isEconToBe; return nothing; end

    if econStartYear > iy[Int(icyc)]
        local econStart = Int32[ECON_START_YEAR_ACT]
        local evntCnt = Ref(Int32(0))
        OPFIND(Int32(1), econStart, evntCnt)
        if evntCnt[] > 0
            local idt = Int32(0)
            local strtparms = zeros(Float32, 3)
            for i in 1:Int(evntCnt[])
                local iactk, idt_i, np = OPGET(Int32(i), Int32(3), strtparms)
                idt = idt_i
                OPDONE(Int32(i), Int32(idt_i))
            end
            global econStartYear    = idt
            global pretendStartYear = econStartYear
            global discountRate     = strtparms[1]
            global sevInput         = strtparms[2]
            global doSev            = strtparms[3] > 0.0f0
        end
    end
    # PRETEND handling is not exercised by the sn.key test.
    if Int(beforecuts) == 0
        global isPretendActive = false
    end
    return nothing
end

# eccalc.f — called from GRADD each cycle.
function ECCALC(iy::AbstractVector, icyc::Integer, jsp, mgmid::AbstractString,
                nplt::AbstractString, ititle::AbstractString)
    # ECON not yet active this cycle
    if econStartYear >= iy[Int(icyc)+1]
        return nothing
    end

    local beginAnalYear::Int32
    local endAnalYear::Int32
    if isFirstEcon
        global isFirstEcon  = false
        global startYear_EC = econStartYear
        beginAnalYear = econStartYear
        endAnalYear   = iy[Int(icyc)+1] - Int32(1)
        global rate_EC = discountRate / 100.0f0
        # Create the (possibly empty) harvest table when requested (ECONRPTS 2).
        if IDBSECON == Int32(2)
            DBSECHARV_open()
        end
    else
        beginAnalYear = iy[Int(icyc)]
        endAnalYear   = iy[Int(icyc)+1] - Int32(1)
    end

    local beginTime = Int(beginAnalYear - startYear_EC + Int32(1))
    local endTime   = Int(endAnalYear   - startYear_EC + Int32(1))
    (beginTime < 1 || endTime > MAX_YEARS_EC) && return nothing

    # ── calcEcon (cost-only path) ──
    # Annual cost from each ANNUCST keyword, each year of the cycle (rate 0 → flat).
    for i in 1:Int(annCostCnt_EC)
        for j in beginTime:endTime
            undiscCost[j] += annCostAmt_EC[i]
        end
    end

    # Accumulate undiscounted & discounted cost/revenue (saved across cycles).
    for i in beginTime:endTime
        global costUndisc = costUndisc + undiscCost[i]
        global revUndisc  = revUndisc  + undiscRev[i]
        global costDisc   = costDisc + _ec_pv(undiscCost[i], i - 1, rate_EC)
        global revDisc    = revDisc  + _ec_pv(undiscRev[i],  i,     rate_EC)
    end

    local pretend = isPretendActive ? "YES" : "NO "
    local pnv = revDisc - costDisc

    # B/C ratio is computed whenever discounted cost > 0; IRR/RRR/SEV/forest/repro
    # are not calculable here (no revenue, no SEV input) → NULL.
    local bcCalc = costDisc > 0.01f0
    local bcRatio = bcCalc ? revDisc / costDisc : 0.0f0

    DBSECSUM(nplt, beginAnalYear, Int32(endTime), pretend,
             costUndisc, revUndisc, costDisc, revDisc, pnv,
             0.0f0, false,           # IRR
             bcRatio, bcCalc,        # BC ratio
             0.0f0, false,           # RRR
             0.0f0, false,           # SEV
             0.0f0, false,           # Value_of_Forest
             0.0f0, false,           # Value_of_Trees
             Int32(0), Int32(0),     # Mrch cubic / board-foot volume
             discountRate, 0.0f0, false)  # discount rate, given SEV
    return nothing
end
