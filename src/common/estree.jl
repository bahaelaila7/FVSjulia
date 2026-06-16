# ESTREE.F77 — Establishment tree status (year when mortality can begin)
# Fortran COMMON /ESTREE/ → module-level globals

const IESTAT = zeros(Int32, MAXTRE)   # year when mortality begins on regen-size trees
