# PRGPRM.F77 — Program parameters (sn variant values)
# Fortran PARAMETER statements → Julia const

const MAXTRE  = Int32(3000)   # Max tree records per stand
const MAXTP1  = MAXTRE + Int32(1)
const MAXPLT  = Int32(500)    # Max individual plots
const MAXSP   = Int32(90)     # Max species: sn=90 (base=23); earlier note was wrong
const MAXCYC  = Int32(40)     # Max simulation cycles
const MAXCY1  = MAXCYC + Int32(1)
const MAXSTR  = Int32(20)     # Max site trees
const MXFRCDS = Int32(20)     # Max forest codes
