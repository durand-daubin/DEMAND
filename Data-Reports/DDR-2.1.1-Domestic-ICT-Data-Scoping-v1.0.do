**************************************************************
* Data Exploration for DEMAND Theme 2.1 - Domestic ICT
* - http://www.demand.ac.uk/research-themes/theme-2-how-end-use-practices-change/2-1-domestic-it-use/
* - focus on use of ICT in and around the home (& on the move?)

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

* these willbe true across all scripts so globals = OK
global where = "~/Documents/Work"
global droot = "$where/Data/Social Science Datatsets"


* these will be true only of this script so use locals
local proot "$where/Projects/RCUK-DEMAND/Data Reports/Project 2.1 Domestic ICT"
local logd = "$proot/results"

local version "1.0"
* version 1.0

capture log close

log using "`logd'/DDR-2.3.1-Data-Scoping-v`version'.smcl", replace

set more off

****************************
* MTUS data
* www.timeuse.org/mtus

use "$droot/MTUS/World 6/processed/MTUS-adult-aggregate-wf.dta", clear

* there will be multiple diary days in some surveys
duplicates report pid

duplicates drop pid, force

tab countrya

tab survey countrya

* UK = 37
* how many 'older people' in each survey?
* NB: this will be duplicated by
tab survey ba_age_r if countrya == 37

* MTUS episode data to look at location etc
* use original file
use "$droot/MTUS/World 6/MTUS-adult-episode.dta", clear

* descriptives
* change values < 1 (i.e. missing) to missing
local tvars "alone eloc"
mvdecode `tvars', mv(-9/-1)

gen alone_count = 0 if alone == .
replace alone_count = 1 if alone != .
tab alone alone_count, mi

gen eloc_count = 0 if eloc == .
replace eloc_count = 1 if eloc != .
tab eloc eloc_count, mi

* this is quite slow
local tvars "alone_count eloc_count"
foreach v of local tvars {
	di "Testing if we know about `v'"
	table survey country, c(mean `v')
}

li day month year id start epnum main sec eloc alone in 1/5

* get list of main acts
lab li MAIN
lab li SEC

tab main year if countrya == 37

****************************
* ONS TU 2000
* https://www.esds.ac.uk/findingData/snDescription.asp?sn=4504
use "$droot/UK Time Use 2000/processed/diary_data_8_long_v1.0.dta", clear

* more detailed time use activities
* trick to get tabstat to give us full results even if codes missing for secondary acts
gen pact_count = 1 if pact !=.
gen sact_count = 1 if sact !=.

label li act1_144

table pact, c(sum pact_count sum sact_count)

****************************
* Home OnLine 1999-2001
* http://discover.ukdataservice.ac.uk/catalogue/?sn=4607

* not an episode file
use "$droot/BT Digital Living/HoL Survey/Corrected diary files/afinal_slots_corr.dta", clear
desc awpri*
tabstat awpri*, s(N mean) c(s)
desc awsec*
tabstat awsec*, s(N mean) c(s)

****************************
* e-Living 2002
* http://discover.ukdataservice.ac.uk/catalogue/?sn=4728 
use "$droot/eLiving/stata6/eliv-w2-converted-time-use-slots.dta", clear

* why have the labels disappeared?
label def country 1 "UK" 2 "Italy" 3 "Germany" 4 "Norway" 5 "Bulgaria" 6 "Israel"

lab var bcountry "w2: country"

lab val bcountry country

lab def age10lab 0 "0-15" 1 "16-24" 2 "25-34" 3 "35-44" 4 "45-54" 5 "55-64" 6 "65-74" 7 "75+"
lab val brage10 age10lab

tab brage10 bcountry

desc bact*r
tabstat bact*r, by(bcountry) c(s)

****************************
* ONS TU 2005
* https://www.esds.ac.uk/findingData/snDescription.asp?sn=5592
use "$droot/UK Time Use 2005/processed/timeusefinal_for_archive_diary_long_v2.0.dta"

* recode missing
mvdecode *act, mv(-9/-1)

gen pact_count = 1 if pact != .
gen sact_count = 1 if sact != .

* list the labels
label li pact144

* how many of each kind of episode do we have?
table pact, c(sum pact_count sum sact_count)

****************************
* Trajectory 
* See https://docs.google.com/document/d/1S7A1-SIf0Vvqbl04XLb1clm9_mO9VBjWG5xr9B3eBdU/edit
use "~/Documents/Work/Projects/RCUK-DEMAND/Theme 1/data/Time Use/Trajectory-Oxford/Trajectory data 650, Feb 2014-purchased-labelled-long.dta", clear

* Are there more episodes on one day than another?
tab dtskwd

* what acts do we have?
lab li TS144_MA

tab pact 

****************************
* EFS/LCFS
* https://www.esds.ac.uk/findingData/snDescription.asp?sn=7472
use "$droot/Expenditure and Food Survey/processed/EFS-2001-2010-extract-BA.dta", clear

* summarise all spend
desc *t
preserve
	collapse (mean) *t
	outsheet using "`proot'/LCFS-all-COICOP-all-years.csv", comma replace
restore

* summarise all internet spend
desc *w
tab survey_year
collapse (mean) *w, by(survey_year)

* extract table easily
xpose, clear
outsheet using "`proot'/LCFS-internet-COICOP-all-years.csv", comma replace

***************************
* EFUS - DECC's follow-up to the English Housing Survey 2011
* http://discover.ukdataservice.ac.uk/catalogue/?sn=7471
* March 2014 version
* really should just match all of them together - won;t make a very big file!
use "$droot/EFUS-2011/November 2014/stata11/matching_file/matching_file.dta", clear

* quite amazingly this data does not seem to have any of the EHS variables attached to it (in this version)
* so we have virtually no data on the occupants at all
merge 1:1 interview_id using "$droot/EFUS-2011/November 2014/stata11/interview/alternative_heating_derived.dta", nogen
* merge 1:1 interview_id using "$droot/EFUS-2011/November 2014/stata11/interview/alternative_heating.dta", nogen // this has data for multiple rooms per house
merge 1:1 interview_id using "$droot/EFUS-2011/November 2014/stata11/interview/conservatories.dta", nogen
merge 1:1 interview_id using "$droot/EFUS-2011/November 2014/stata11/interview/cooking_and_appliances.dta", nogen
merge 1:1 interview_id using "$droot/EFUS-2011/November 2014/stata11/interview/dwelling_improvements.dta", nogen
merge 1:1 interview_id using "$droot/EFUS-2011/November 2014/stata11/interview/hot_water.dta", nogen
merge 1:1 interview_id using "$droot/EFUS-2011/November 2014/stata11/interview/interview_weight.dta", nogen
merge 1:1 interview_id using "$droot/EFUS-2011/November 2014/stata11/interview/lighting.dta", nogen
merge 1:1 interview_id using "$droot/EFUS-2011/November 2014/stata11/interview/main_heating_derived.dta", nogen
* merge 1:1 interview_id using "$droot/EFUS-2011/November 2014/stata11/interview/main_heating.dta", nogen // this has data for multiple rooms per house
merge 1:1 interview_id using "$droot/EFUS-2011/November 2014/stata11/interview/monitoring.dta", nogen
merge 1:1 interview_id using "$droot/EFUS-2011/November 2014/stata11/interview/mop_and_tariffs.dta", nogen
merge 1:1 interview_id using "$droot/EFUS-2011/November 2014/stata11/interview/overheating_and_cooling.dta", nogen
merge 1:1 interview_id using "$droot/EFUS-2011/November 2014/stata11/interview/rooms.dta", nogen
merge 1:1 interview_id using "$droot/EFUS-2011/November 2014/stata11/interview/supplementary_heating_derived.dta", nogen
* merge 1:1 interview_id using "$droot/EFUS-2011/November 2014/stata11/interview/supplementary_heating.dta", nogen // this has data for multiple rooms per house
merge m:1 meter_id using "$droot/EFUS-2011/November 2014/stata11/meter_reading/meter_read_weight.dta", nogen
merge m:1 meter_id using "$droot/EFUS-2011/November 2014/stata11/meter_reading/metered_consumption.dta", nogen
merge m:1 temperature_id using "$droot/EFUS-2011/November 2014/stata11/temperature/mean_room_temperatures.dta", nogen
merge m:1 temperature_id using "$droot/EFUS-2011/November 2014/stata11/temperature/temperature_heating_patterns.dta", nogen
merge m:1 temperature_id using "$droot/EFUS-2011/November 2014/stata11/temperature/temperature_meter_reading_weight.dta", nogen
merge m:1 temperature_id using "$droot/EFUS-2011/November 2014/stata11/temperature/temperature_weight.dta", nogen

save "$droot/EFUS-2011/processed/efus-2011-nov2014-merged.dta", replace

gen monitor_sample = 0
replace monitor_sample = 1 if emonitor_id != ""

* TV
tab q103 monitor_sample, col

* tenure?
tab q01 monitor_sample, col

* landlord?
tab q02 monitor_sample, col

* still same hh as EHS?
tab q03 monitor_sample, col

***************************
* CER data (Irish Smart Meter Trials)
* http://www.ucd.ie/issda/data/commissionforenergyregulationcer/
use "/$droot/CER Smart Metering Project/data/Smart meters Residential pre-trial survey data.dta", clear

lookfor tv
lookfor internet

***************************
* EDRP data
* http://discover.ukdataservice.ac.uk/catalogue/?sn=7591
import excel "/$droot/EDRP/UKDA-7591-CSV/csv/edrp_geography_data.xlsx", clear firstrow 

save "/$droot/EDRP/UKDA-7591-CSV/csv/edrp_geography_data.dta", replace

tab ACORN_Category

***************************
* UoS-E data
* 
* use original survey as we've left a lot of variables out
use "/$droot/CBIES-Soton-Energy-Communities/surveys/energy 090713-original-safe.dta", clear

lookfor tv
lookfor computer
lookfor laptop
lookfor phone
lookfor dvd

use "/$droot/CBIES-Soton-Energy-Communities/surveys/network 090713-safe.dta", clear

* check smart plug labels
use "/$droot/CBIES-Soton-Energy-Communities/UoS-E October 2011 safe package/v2/power/UoS-E-October-2011-safe-package-SmartPlug-30sec-1-28-Oct-2011-v2.dta",clear

tab devicename

log close
