# volkey.f — VOLKEY: process volume/defect keywords (247 lines)
# Keywords: 215=MCDEFECT, 216=BFDEFECT, 217=VOLUME, 218=BFVOLUME
# Modifies VOLSTD arrays: BFMIND/BFTOPD/BFSTMP/FRMCLS/METHB/METHC/DBHMIN/TOPD/STMP/
#   SCFMIND/SCFTOPD/SCFSTMP/BFDEFT/CFDEFT (all in common/volstd.jl)

function VOLKEY(debug::Bool)
    myacts = Int32[215, 216, 217, 218]

    if ICYC == 0
        @goto label_9960
    end

    ntodo_r = Ref(Int32(0))
    OPFIND(4, myacts, ntodo_r)
    ntodo = ntodo_r[]
    if ntodo <= 0
        @goto label_9960
    end

    kdt_r   = Ref(Int32(0))
    iactk_r = Ref(Int32(0))
    np_r    = Ref(Int32(0))
    prms    = zeros(Float32, 10)

    for i in 1:ntodo
        OPGET(i, 12, kdt_r, iactk_r, np_r, prms)
        np    = np_r[]
        iactk = iactk_r[]

        if np < 6
            OPDEL1(i)
            continue
        end

        inum = 219 - Int(iactk)

        # --- 9905: BFVOLUME keyword (activity 218, inum=1) ---
        if inum == 1
            OPDONE(i, IY[Int(ICYC)])
            ispc = Int(round(prms[1]))
            if ispc < 0
                igrp  = -ispc
                iulim = Int(ISPGRP[igrp, 1]) + 1
                for ig in 2:iulim
                    igsp = Int(ISPGRP[igrp, ig])
                    BFMIND[igsp] = prms[2]
                    BFTOPD[igsp] = prms[3]
                    BFSTMP[igsp] = prms[4]
                    FRMCLS[igsp] = prms[5]
                    METHB[igsp]  = Int32(round(prms[6]))
                end
            elseif ispc == 0
                for j in 1:Int(MAXSP)
                    BFMIND[j] = prms[2]
                    BFTOPD[j] = prms[3]
                    BFSTMP[j] = prms[4]
                    FRMCLS[j] = prms[5]
                    METHB[j]  = Int32(round(prms[6]))
                end
            else
                BFMIND[ispc] = prms[2]
                BFTOPD[ispc] = prms[3]
                BFSTMP[ispc] = prms[4]
                FRMCLS[ispc] = prms[5]
                METHB[ispc]  = Int32(round(prms[6]))
            end

        # --- 9915: VOLUME keyword (activity 217, inum=2) ---
        elseif inum == 2
            if LFIANVB
                continue
            end
            OPDONE(i, IY[Int(ICYC)])
            ispc = Int(round(prms[1]))
            if ispc < 0
                igrp  = -ispc
                iulim = Int(ISPGRP[igrp, 1]) + 1
                for ig in 2:iulim
                    igsp = Int(ISPGRP[igrp, ig])
                    DBHMIN[igsp]  = prms[2]
                    TOPD[igsp]    = prms[3]
                    STMP[igsp]    = prms[4]
                    FRMCLS[igsp]  = prms[5]
                    METHC[igsp]   = Int32(round(prms[6]))
                    SCFMIND[igsp] = prms[7]
                    SCFTOPD[igsp] = prms[8]
                    SCFSTMP[igsp] = prms[9]
                end
            elseif ispc == 0
                for j in 1:Int(MAXSP)
                    DBHMIN[j]  = prms[2]
                    TOPD[j]    = prms[3]
                    STMP[j]    = prms[4]
                    FRMCLS[j]  = prms[5]
                    METHC[j]   = Int32(round(prms[6]))
                    SCFMIND[j] = prms[7]
                    SCFTOPD[j] = prms[8]
                    SCFSTMP[j] = prms[9]
                end
            else
                DBHMIN[ispc]  = prms[2]
                TOPD[ispc]    = prms[3]
                STMP[ispc]    = prms[4]
                FRMCLS[ispc]  = prms[5]
                METHC[ispc]   = Int32(round(prms[6]))
                SCFMIND[ispc] = prms[7]
                SCFTOPD[ispc] = prms[8]
                SCFSTMP[ispc] = prms[9]
            end

        # --- 9925: BFDEFECT keyword (activity 216, inum=3) ---
        elseif inum == 3
            OPDONE(i, IY[Int(ICYC)])
            ispc = Int(round(prms[1]))
            if ispc < 0
                igrp  = -ispc
                iulim = Int(ISPGRP[igrp, 1]) + 1
                for ig in 2:iulim
                    igsp = Int(ISPGRP[igrp, ig])
                    BFDEFT[2, igsp] = prms[2]
                    BFDEFT[3, igsp] = prms[3]
                    BFDEFT[4, igsp] = prms[4]
                    BFDEFT[5, igsp] = prms[5]
                    BFDEFT[6, igsp] = prms[6]
                    BFDEFT[7, igsp] = prms[6]
                    BFDEFT[8, igsp] = prms[6]
                    BFDEFT[9, igsp] = prms[6]
                end
            elseif ispc == 0
                for j in 1:Int(MAXSP)
                    BFDEFT[2, j] = prms[2]
                    BFDEFT[3, j] = prms[3]
                    BFDEFT[4, j] = prms[4]
                    BFDEFT[5, j] = prms[5]
                    BFDEFT[6, j] = prms[6]
                    BFDEFT[7, j] = prms[6]
                    BFDEFT[8, j] = prms[6]
                    BFDEFT[9, j] = prms[6]
                end
            else
                BFDEFT[2, ispc] = prms[2]
                BFDEFT[3, ispc] = prms[3]
                BFDEFT[4, ispc] = prms[4]
                BFDEFT[5, ispc] = prms[5]
                BFDEFT[6, ispc] = prms[6]
                BFDEFT[7, ispc] = prms[6]
                BFDEFT[8, ispc] = prms[6]
                BFDEFT[9, ispc] = prms[6]
            end

        # --- 9935: MCDEFECT keyword (activity 215, inum=4) ---
        elseif inum == 4
            if LFIANVB
                continue
            end
            OPDONE(i, IY[Int(ICYC)])
            ispc = Int(round(prms[1]))
            if ispc < 0
                igrp  = -ispc
                iulim = Int(ISPGRP[igrp, 1]) + 1
                for ig in 2:iulim
                    igsp = Int(ISPGRP[igrp, ig])
                    CFDEFT[2, igsp] = prms[2]
                    CFDEFT[3, igsp] = prms[3]
                    CFDEFT[4, igsp] = prms[4]
                    CFDEFT[5, igsp] = prms[5]
                    CFDEFT[6, igsp] = prms[6]
                    CFDEFT[7, igsp] = prms[6]
                    CFDEFT[8, igsp] = prms[6]
                    CFDEFT[9, igsp] = prms[6]
                end
            elseif ispc == 0
                for j in 1:Int(MAXSP)
                    CFDEFT[2, j] = prms[2]
                    CFDEFT[3, j] = prms[3]
                    CFDEFT[4, j] = prms[4]
                    CFDEFT[5, j] = prms[5]
                    CFDEFT[6, j] = prms[6]
                    CFDEFT[7, j] = prms[6]
                    CFDEFT[8, j] = prms[6]
                    CFDEFT[9, j] = prms[6]
                end
            else
                CFDEFT[2, ispc] = prms[2]
                CFDEFT[3, ispc] = prms[3]
                CFDEFT[4, ispc] = prms[4]
                CFDEFT[5, ispc] = prms[5]
                CFDEFT[6, ispc] = prms[6]
                CFDEFT[7, ispc] = prms[6]
                CFDEFT[8, ispc] = prms[6]
                CFDEFT[9, ispc] = prms[6]
            end
        end
    end

    @label label_9960
    if debug
        for i in 1:Int(MAXSP)
            @printf(io_units[Int32(JOSTND[])], " BFMIND=%10.2f BFTOPD=%10.2f BFSTMP=%10.2f SPECIES=%3d\n",
                    BFMIND[i], BFTOPD[i], BFSTMP[i], i)
        end
    end
    return nothing
end
