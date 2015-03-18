**************************************************************
* Data Exploration for DEMAND Theme 3.1 - adaptive infrastructures
* - focus on Stocksbridge & Stevenage

* This work was funded by RCUK through the End User Energy Demand Centres Programme via the
* "DEMAND: Dynamics of Energy, Mobility and Demand" Centre (www.demand.ac.uk, http://gtr.rcuk.ac.uk/project/0B657D54-247D-4AD6-9858-64E411D3D06C)

/*   

Copyright (C) 2014  University of Southampton

Author: Ben Anderson (b.anderson@soton.ac.uk, @dataknut, https://github.com/dataknut) 
	[Energy & Climate Change, Faculty of Engineering & Environment, University of Southampton]

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License 
(http://choosealicense.com/licenses/gpl-2.0/), or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

#YMMV - http://en.wiktionary.org/wiki/YMMV

*/

local where = "/Users/ben/Documents/Work"local proot "`where'/Projects/RCUK-DEMAND/Data Reports/Project 3.1 Adapting Infrastructure"
local gisroot "`where'/Data/GIS data/UK Census/"
local croot = "`where'/Data/Social Science Datatsets/UK Census"

local logd = "`proot'/results"

local version "1.0"
* version 1.0
* household level analysis

capture log close

log using "`logd'/DDR-3.1.1-Data-Scoping-v`version'.smcl", replace

set more off

****************************
* Census LUT data
* source: https://geoportal.statistics.gov.uk/geoportal/catalog/content/filelist.page

* use a pre-built 2011 England & Wales OA look up table which has OAs as smallest zone
use "`gisroot'/Census_LUTS/2011/EngWales/oacode_2011_lookups.dta", clear

*gen count = 1

gen case_studies = 0
replace case_studies = 1 if regexm(laname_2011,"Stevenage")
replace case_studies = 2 if regexm(parncp11nm,"Stocksbridge")
lab def case_studies 0 "Not a case study area" 1 "Stevenage" 2 "Stocksbridge"
lab val case_studies case_studies

* check at OA level
tab parncp11nm laname_2011 if regexm(laname_2011,"Stevenage") // should be no parishes in Stevenage
tab parncp11nm laname_2011 if regexm(laname_2011,"Sheffield")

* add in basic Census data on central heating
merge 1:1 zonecode using "`croot'/2011Data/EW/oa/processed/2011-EW_OA_cent_heating_basic.dta", gen(m_census_oas)
li oa11cd zonecode parncp11nm lad11nm m_census_oas n_* if m_census_oas != 3
* the master contained one row which was not an OA
* the using (Census) contained one non-matching OA? need to check & fix!!
keep if m_census_oas == 3
lab val case_studies case_studies
tabstat n_hh_spaces n_central_heat n_no_central_heat, by(case_studies) s(sum mean n min max) format(%9.0f)

preserve
	* sequentially collapse to LOSA & MSOA level
	* need to add MSOA
	merge 1:1 oa11cd using "`gisroot'/Census_LUTS/2011/EngWales/OA11_LSOA11_MSOA11_LAD11_EW_LU.zip Folder/OA11_LSOA11_MSOA11_LAD11_EW_LUv2.dta", ///
		keepusing(msoa11cd msoa11nm) gen(m_msoa)
	li oa11cd zonecode parncp11nm lad11nm m_census_oas n_* if m_msoa != 3
	keep if m_msoa == 3
	* same OA not matching?
	
	* now collapse to LSOA 
	collapse (sum) count n* (mean) case_studies, ///
		by(lsoacode_2011 lsoaname_2011 msoa11cd msoa11nm parncp11cd parncp11nm lad11cd lad11nm)
	tab case_studies
	gen pc_central_heat = n_central_heat/n_hh_spaces
	gen pc_no_central_heat = n_no_central_heat/n_hh_spaces
	lab val case_studies case_studies
	tabstat n_hh_spaces pc_central_heat pc_no_central_heat, by(case_studies) s(sum mean n min max) format(%9.0f)
	
	* Now MSOA level
	collapse (sum) count n* (mean) case_studies, ///
		by(msoa11cd msoa11nm parncp11cd parncp11nm lad11cd lad11nm)
	tab case_studies
	gen pc_central_heat = n_central_heat/n_hh_spaces
	gen pc_no_central_heat = n_no_central_heat/n_hh_spaces
	lab val case_studies case_studies
	tabstat n_hh_spaces pc_central_heat pc_no_central_heat, by(case_studies) s(sum mean n min max) format(%9.0f)

* restore as MSOAs do NOT necessarily nest within parishes
restore

* Parish level
collapse (sum) count n* (mean) case_studies, ///
	by(parncp11cd parncp11nm lad11cd lad11nm)
tab case_studies
gen pc_central_heat = n_central_heat/n_hh_spaces
gen pc_no_central_heat = n_no_central_heat/n_hh_spaces
lab val case_studies case_studies
tabstat n_hh_spaces pc_central_heat pc_no_central_heat, by(case_studies) s(sum mean n min max) format(%9.0f)

* LA level
collapse (sum) count n* (mean) case_studies, ///
	by(lad11cd lad11nm)
tab case_studies
gen pc_central_heat = n_central_heat/n_hh_spaces
gen pc_no_central_heat = n_no_central_heat/n_hh_spaces
lab val case_studies case_studies
tabstat n_hh_spaces pc_central_heat pc_no_central_heat, by(case_studies) s(sum mean n min max) format(%9.0f)

log close
