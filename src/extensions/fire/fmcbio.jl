# fmcbio.f — Jenkins et al. biomass equations for aboveground, merchantable, and root biomass
# FMCBIO: called from FMSADD, FMSCUT, FMCRBOUT
# D in inches, returns ABIO/MBIO/RBIO in short tons/tree via Ref

function FMCBIO(d::Real, ksp::Integer, abio_ref::Ref{Float32},
                mbio_ref::Ref{Float32}, rbio_ref::Ref{Float32})
    debug = DBCHK("FMCBIO", 6, ICYC)
    if debug
        @printf(get(io_units, Int32(JOSTND), stdout), " ENTERING FMCBIO CYCLE = %2d\n", ICYC)
    end

    # Aboveground coefficients — 10 Jenkins species groups:
    # cedar/larch, Douglas-fir, fir/hemlock, pine, spruce,
    # aspen/alder/cottonwood/willow, soft maple/birch, mixed hardwood,
    # hard maple/oak/hickory/beech, woodland juniper/oak/mesquite
    B0A = Float32[-2.0336, -2.2304, -2.5384, -2.5356, -2.0773,
                  -2.2094, -1.9123, -2.4800, -2.0127, -0.7152]
    B1A = Float32[ 2.2592,  2.4435,  2.4814,  2.4349,  2.3323,
                    2.3867,  2.3651,  2.4835,  2.4342,  1.7029]
    # Merchantable and belowground coefficients — softwood (1) / hardwood (2)
    B0M = Float32[-0.3737, -0.3065]
    B1M = Float32[-1.8055, -5.4240]
    B0B = Float32[-1.5619, -1.6911]
    B1B = Float32[ 0.6614,  0.8160]

    local igrp::Int = Int(BIOGRP[ksp])
    local jgrp::Int = igrp > 5 ? 2 : 1

    local dcm::Float32   = Float32(d) * INtoCM
    local kgtoti::Float32 = TMtoTI / 1000.0f0

    local abio::Float32 = 0.0f0
    local mbio::Float32 = 0.0f0
    local rbio::Float32 = 0.0f0

    if dcm > 0.0f0
        if dcm >= 2.5f0
            abio = exp(B0A[igrp] + B1A[igrp] * log(dcm))
            rbio = abio * exp(B0B[jgrp] + B1B[jgrp] / dcm)
        else
            # Scale linearly from a 2.5 cm tree; use belowground proportion at 2.5 cm
            abio = exp(B0A[igrp] + B1A[igrp] * log(2.5f0))
            abio = abio * (dcm / 2.5f0)
            rbio = abio * exp(B0B[jgrp] + B1B[jgrp] / 2.5f0)
        end

        if Float32(d) >= DBHMIN[ksp]
            mbio = abio * exp(B0M[jgrp] + B1M[jgrp] / dcm)
        end

        abio *= kgtoti
        mbio *= kgtoti
        rbio *= kgtoti
    end

    abio_ref[] = abio
    mbio_ref[] = mbio
    rbio_ref[] = rbio
    return nothing
end
