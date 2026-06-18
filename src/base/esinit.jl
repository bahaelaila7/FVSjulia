# base/esinit.jl — ESINIT / ESEZCR (regeneration establishment model init)
# Translated from: bin/FVSsn_buildDir/esinit.f (83 lines)
#
# ESINIT: called once from INITRE to initialize the regeneration model state.
# ESEZCR: ENTRY called from INITRE when the NOTREES keyword is entered.
#
# COMMON state lives in common/eshap.jl, common/escomn.jl, common/esrncm.jl,
# common/eswsbw.jl. ESBLKD's DATA defaults (ESS0/ESSS=55329, JOREGT=17) are
# already the module-load values of those globals.

function ESINIT()
    for i in 1:Int(MAXSP)
        HTADJ[i]  = Float32(0.0)
        XESMLT[i] = Float32(1.0)
    end
    global ITRNRM = Int32(0)
    global NBWHST = Int32(0)
    global STOADJ = Float32(0.0)
    global CONFID = Float32(5.0)
    global LINGRW = false
    global LAUTAL = false
    # esinit.f sets LSPRUT=.TRUE. — stump sprouting is enabled. For snt01 this is a
    # no-op (its cuts leave ITRNRM=0, so the ESNUTR sprout branch / ESUCKR returns
    # immediately), which is why earlier work could force it false without regressing
    # snt01. But the sn.key SHELTERWOOD stand DOES cut sproutable hardwoods, so real
    # sprouting (ESUCKR, base/esuckr.jl) is required to match the Fortran regen.
    global LSPRUT = true
    global IPRINT = Int32(1)
    global INADV  = Int32(0)
    global LOAD   = Int32(0)
    global IBLK   = Int32(0)
    global MINREP = Int32(50)
    global KDTOLD = Int32(-99)
    global IPINFO = Int32(0)
    global NTALLY = Int32(0)
    global IDSDAT = Int32(-9999)
    global IYRLRM = Int32(-9999)
    global XTES   = Float32(0.0)
    global THRES1 = Float32(0.10)
    global THRES2 = Float32(0.30)

    # Reset the establishment RNG to its seed (ESS0 = ESSS = 55329).
    x_ref = Ref(Float32(0))
    ESRNSD(false, x_ref)

    global NPTIDS = Int32(0)

    # Fortran opens the regen report file (unit JOREGT = KWDFIL//'_RegenRpt.txt').
    # Deferred: the report is not part of the .sum test and nothing writes to it
    # until ESOUT/ESTAB output is implemented (later chunk).
    return nothing
end

# ENTRY ESEZCR — invoked from INITRE for the NOTREES keyword (EZCRUISE option).
function ESEZCR(jstnd::Integer, lkecho::Bool)
    global INADV = Int32(1)
    if lkecho
        @printf(io_units[Int(jstnd)],
            "%s(EZCRUISE OPTION IN REGENERATION ESTABLISHMENT MODEL IS AUTOMATICALLY INVOKED.)\n",
            " "^11)
    end
    return nothing
end
