# extensions/fire/fmsvtobj.jl — FMSVTOBJ: pre-fire SVS object snapshot + snag status update
# Translated from fire/fmsvtobj.f (89 lines)
# Called from FMEFF. Copies IOBJTP→IOBJTPTMP, IS2F→IS2FTMP,
# then converts standing green/red snags to burned status for crowning/torching fires.

function FMSVTOBJ(iftyp::Integer)
    for i in 1:Int(NSVOBJ)
        IOBJTPTMP[i] = IOBJTP[i]
        IS2FTMP[i]   = IS2F[i]
    end

    for i in 1:Int(NSVOBJ)
        if IOBJTP[i] == 2
            f = IS2F[i]
            if FALLDIR[f] == -1
                # standing snag: only convert for crowning (1) or torching (2)
                if iftyp == 1 || iftyp == 2
                    if     ISTATUS[f] == 2; ISTATUS[f] = 5
                    elseif ISTATUS[f] == 3; ISTATUS[f] = 6
                    elseif ISTATUS[f] == 4; ISTATUS[f] = 6
                    end
                end
            else
                # lying snag: always convert to burned
                if     ISTATUS[f] == 2; ISTATUS[f] = 5
                elseif ISTATUS[f] == 3; ISTATUS[f] = 6
                elseif ISTATUS[f] == 4; ISTATUS[f] = 6
                end
            end
        end
    end
    return
end
