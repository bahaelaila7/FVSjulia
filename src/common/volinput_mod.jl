# VOLINPUT_MOD — module-level volume/merch rule globals (volinput_mod.f)
# Fortran MODULE VOLINPUT_MOD translated as module-level Ref globals.
# Accessed by MRULES (mrules.jl) and merch keyword handlers.

const FORMCLASS  = Ref{Int32}(0)     # INTEGER
const MRULEMOD   = Ref{Char}('N')    # CHARACTER*1, default 'N'  — set to 'Y' by MRULE keyword
const NEWEVOD    = Ref{Int32}(0)
const NEWOPT     = Ref{Int32}(0)
const NEWMAXLEN  = Ref{Float32}(0f0)
const NEWMINLEN  = Ref{Float32}(0f0)
const NEWMINLENT = Ref{Float32}(0f0)
const NEWMERCHL  = Ref{Float32}(0f0)
const NEWMTOPP   = Ref{Float32}(0f0)
const NEWMTOPS   = Ref{Float32}(0f0)
const NEWSTUMP   = Ref{Float32}(0f0)
const NEWTRIM    = Ref{Float32}(0f0)
const NEWBTR     = Ref{Float32}(0f0)
const NEWDBTBH   = Ref{Float32}(0f0)
const NEWMINBFD  = Ref{Float32}(0f0)
const NEWCOR     = Ref{Char}('Y')    # CHARACTER*1, default 'Y'
