**************************************************************
* Data Exploration for DEMAND Theme 3.1 - adaptive infrastructures
* - focus on Stocksbridge & Stevenage (case studies)
* - trends in take-up of gas & electricity appliances

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
local gisroot "`where'/Data/GIS data/UK Census"
local croot = "`where'/Data/Social Science Datatsets/UK Census"
local imdroot "`where'/Data/Social Science Datatsets/Indices of Deprivation"
local lcfsroot = "`where'/Data/Social Science Datatsets/Expenditure and Food Survey/processed"

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
	save "`where'/Projects/RCUK-DEMAND/Data Reports/Project 3.1 Adapting Infrastructure/data/2011_LSOA_LUT.dta", replace
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

******************************
* Test NAPTAN

******************************
* Test IMD access to services scores over time
use "`imdroot'/English ID 2004/Sub-Domains.dta", clear
merge 1:1 zonecode using "`imdroot'/English ID 2007/Sub-Domains of the Access Domain IMD 2007.dta", ///
	gen(m_imd2007) keepusing(imd2007_geog*)
merge 1:1 zonecode using "`imdroot'/English ID 2010/ID-2010-indices-domains.dta", ///
	gen(m_imd2010) keepusing(imd2010_geog*)
graph matrix  imd2004_geog_barriers_score imd2007_geog_barriers_score imd2010_geog_barriers_score if laname == "Stevenage", half

su imd2004_geog_barriers_score imd2007_geog_barriers_score imd2010_geog_barriers_score if laname == "Stevenage"

* well they correlate but why are the 2010 score different in magnitude?


********************************************
* trends in take-up of gas & electricuty appliances - regional if possible
* test LC&FS

use "`lcfsroot'/EFS-2001-2010-extract-BA.dta", clear

/*
a101            byte   %8.0g       a101       telephone and\or mobile in household
a103            byte   %8.0g       a103       gas electric supplied to accomodation
a108            byte   %8.0g       a108       washing machine in household
*/
local vars "a101 a103 a108"
tabstat a101 a103 a108, by(survey_year) c(v)

/*
a150            byte   %8.0g       a150       central heating by electricity
a151            byte   %8.0g       a151       central heating by gas
a152            byte   %8.0g       a152       central heating by oil
a153            byte   %8.0g       a153       central heating by solid fuel
a154            byte   %8.0g       a154       central heating by solid fuel and oil
a155            byte   %8.0g       a155       central heating by calor gas
a156            byte   %8.0g       a156       other gas central heating
*/
local vars "`vars' a150 a151 a152 a153 a154 a155 a156"
tabstat a150 a151 a152 a153 a154 a155 a156, by(survey_year) c(v)

/*
a164            byte   %8.0g       a164       fridge-freezer or deep freezer in hhold
a167            byte   %8.0g       a167       tumble dryer in household
a168            byte   %8.0g       a168       microwave oven in household
a169            byte   %8.0g       a169       dishwasher in household
*/
local vars "`vars' a164 a167 a168 a169"
tabstat a164 a167 a168 a169, by(survey_year) c(v)

/*
a170            byte   %8.0g       a170       compact disc player in household
a171            byte   %8.0g       a171       tv set in household (not after 2009)
a172            byte   %8.0g       a172       internet connection in household
a190            byte   %8.0g       a190       internet access via home computer
a191            byte   %8.0g       a191       internet access via digital tv
a192            byte   %8.0g       a192       internet access via mobile phone
a193            byte   %8.0g       a193       internet access via games console
a194            byte   %8.0g       a194       internet access via other method
a195            byte   %8.0g       a195       www access via home computer (not after 2002-2003)
*/
local vars "`vars' a170 a171 a172 a190 a191 a192 a193 a194 a195"
tabstat a170 a171 a172 a190 a191 a192 a193 a194 a195, by(survey_year) c(v)

/*
a1641           byte   %8.0g       a1641      satellite receiver in household
a1642           byte   %8.0g       a1642      cable receiver in household
a1643           byte   %8.0g       a1643      satellite receiver in household
a1644           byte   %10.0g                 TV connection by Broadband (from 2003-2004)
a1645           byte   %10.0g                 TV received by Aerial (from 2003-2004)
a1661           byte   %8.0g       a1661      home computer in household
a1701           byte   %8.0g       a1701      dvd player in household (from 2002-2003)
a1711           byte   %8.0g       LABA       Television in household (replaces a171)
*/
local vars "`vars' a1641 a1642 a1643 a1644 a1645 a1661 a1701 a1711"
tabstat a1641 a1642 a1643 a1644 a1645 a1661 a1701 a1711, by(survey_year) c(v)

* purchases of all of the above via diary
/*
c53131t         double %9.0g                  gas cookers
c53132t         double %9.0g                  electric cookers, combined gas electric

c53141t         double %9.0g                  heaters, air conditioners, shower units
ck1313          double %9.0g                  central heating installation (diy)
ck1315t         double %9.0g                  purchase of materials for capital
                                                improvements
*/
local vars "`vars' c53131t c53132t c53141t ck1313 ck1315t"
tabstat c53131t c53132t c53141t ck1313 ck1315t, by(survey_year) c(v)

desc `vars'

log close
