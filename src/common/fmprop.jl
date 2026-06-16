# FMPROP.F77 — Fire carbon fate of harvest products
# Fortran COMMON /FMBLK2/ → module-level globals

# FAPROP(region, year 0-100, data_type, product, wood_type)
# I: 1:2 region; J: 1:101 years 0-100; K: 1:3 data (inuse/landfill/energy)
# M: 1:2 product (pulp/sawlog); N: 1:2 wood type (softwood/hardwood)
const FAPROP = zeros(Float32, 2, 101, 3, 2, 2)

# Species grouping for Jenkins biomass equations
const BIOGRP = zeros(Int32, MAXSP)
