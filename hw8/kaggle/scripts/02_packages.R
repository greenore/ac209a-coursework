## Set Java path if necessary
if (Sys.info()["sysname"] == "Windows" & Sys.getenv("JAVA_HOME") == "") {
  java_path <- "C:/Program Files (x86)/Java/jre7"
  Sys.setenv(JAVA_HOME = java_path)
  cat(paste("Set Java path to", java_path))
}

## CRAN packages
extraction_packages <- c("readr")
transformation_packages <- c("stringr", "dplyr", "tidyr", "sqldf", "lubridate")
visualization_packages <- c("ggplot2", "devEMF", "RColorBrewer", "maptools",
                            "classInt", "rgeos", "beeswarm")

required_packages <- c(extraction_packages, transformation_packages, visualization_packages)
packagesCRAN(required_packages, update = setMissingVar(var_name = "update_package", value = FALSE))

## Github packages
requiredPackages <- c("transformR", "visualizeR")
packagesGithub(requiredPackages, repo_name = "greenore", update = setMissingVar(var_name = "update_package", value = FALSE))

## Clear Workspace
rm(list = ls())
