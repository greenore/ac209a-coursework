#!/usr/bin/Rscript
# Purpose:         Kaggle Competition
# Date:            2016-11-16
# Author:          tim.hagmann@sanitas.com
# Machine:         SAN-NB0044 | Intel i7-3540M @ 3.00GHz | 16.00 GB RAM
# R Version:       R version 3.2.4 -- "Very Secure Dishes"
#
# Notes:           Parallelisation requires the "RevoUtilsMath" package (if
#                  necessary, copy it manually into packrat). On Windows install 
#                  RTools in order to build packages.
################################################################################

## Options
options(scipen = 10)
update_package <- FALSE
options(java.parameters = "-Xmx6g")

## Init files (always execute, eta: 10s)
source("scripts/01_init.R")                   # Helper functions to load packages
source("scripts/02_packages.R")               # Load all necessary packages
source("scripts/03_functions.R")              # Load project specific functions
source("scripts/04_data.R")
