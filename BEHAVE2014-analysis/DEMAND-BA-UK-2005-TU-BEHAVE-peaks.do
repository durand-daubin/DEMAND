* DEMAND Project (www.demand.ac.uk)
* Analyse ONS Time Use 2005 dataset
* Analysis for BEHAVE 2014 conference presentation on components of peak


* b.anderson@soton.ac.uk
* (c) University of Southampton
* Creative Commons Attribution-NonCommercial 4.0 International (CC BY-NC 4.0) license applies
* http://creativecommons.org/licenses/by-nc/4.0/

clear all

* change these to run this script on different PC
local where "/Users/ben/Documents/Work"
local droot "`where'/Data/Social Science Datatsets/Time Use 2005/UKDA-5592-stata8/stata8/"

local proot "`where'/Projects/RCUK-DEMAND/Theme 1"
local rpath "`proot'/results/ONS TU 2005"

local version = "v1.0"

set more off

capture log close

log using "`rpath'/DEMAND-BA-UK-2005-TU-BEHAVE-peaks-`version'.smcl", replace

use "`droot'/timeusefinal_for_archive.dta", clear

* there should be a lot of code here, where has it gone?!

log close
