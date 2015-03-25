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

local where = "/Users/ben/Documents/Work"local droot = "`where'/Data/Social Science Datatsets"

local proot "`where'/Projects/RCUK-DEMAND/Data Reports/Project 2.1 Domestic ICT"

local logd = "`proot'/results"

local version "1.0"
* version 1.0

capture log close

log using "`logd'/DDR-2.3.1-Data-Scoping-v`version'.smcl", replace

set more off

****************************
* MTUS data
* www.timeuse.org/mtus

use "`droot'/MTUS/World 6/processed/MTUS-adult-aggregate-wf.dta", clear

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
use "`droot'/MTUS/World 6/MTUS-adult-episode.dta", clear

* descriptives
* change values < 1 (i.e. missing) to missing
local tvars "alone eloc"
mvdecode `tvars', mv(-9/-1)

* this is quite slow
/*
foreach v of local tvars {
	di "Testing `v'"
	table survey country, c(mean `v')
}
*/
li day month year id start epnum main sec eloc alone in 1/5

* get list of main acts
lab li MAIN
lab li SEC

tab main year if countrya == 37

****************************
* ONS TU 2000
* https://www.esds.ac.uk/findingData/snDescription.asp?sn=4504
use "`droot'/UK Time Use 2000/processed/diary_data_8_long_v1.0.dta", clear

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
use "`droot'/BT Digital Living/HoL Survey/Corrected diary files/afinal_slots_corr.dta", clear
desc awpri*
tabstat awpri*, s(N mean) c(s)
desc awsec*
tabstat awsec*, s(N mean) c(s)

****************************
* e-Living 2002
* http://discover.ukdataservice.ac.uk/catalogue/?sn=4728 
use "`droot'/eLiving/stata6/eliv-w2-converted-time-use-slots.dta", clear

* why have the labels disappeared?
label def country 1 "UK" 2 "Italy" 3 "Germany" 4 "Norway" 5 "Bulgaria" 6 "Israel"lab var bcountry "w2: country"lab val bcountry country

lab def age10lab 0 "0-15" 1 "16-24" 2 "25-34" 3 "35-44" 4 "45-54" 5 "55-64" 6 "65-74" 7 "75+"lab val brage10 age10lab

tab brage10 bcountry

desc bact*r
tabstat bact*r, by(bcountry) c(s)

****************************
* ONS TU 2005
* https://www.esds.ac.uk/findingData/snDescription.asp?sn=5592
use "`droot'/UK Time Use 2005/processed/timeusefinal_for_archive_diary_long_v2.0.dta"

* recode missing
mvdecode *act, mv(-9/-1)

gen pact_count = 1 if pact != .
gen sact_count = 1 if sact != .

label li pact144

table pact, c(sum pact_count sum sact_count)

****************************
* Trajectory 
* See https://docs.google.com/document/d/1S7A1-SIf0Vvqbl04XLb1clm9_mO9VBjWG5xr9B3eBdU/edit
use "/Users/ben/Documents/Work/Projects/RCUK-DEMAND/Theme 1/data/Time Use/Trajectory-Oxford/Trajectory data 650, Feb 2014-purchased-labelled-long.dta", clear

tab dtskwd

lab li TS144_MA

tab pact 

****************************
* EFS/LCFS
* https://www.esds.ac.uk/findingData/snDescription.asp?sn=7472
use "`droot'/Expenditure and Food Survey/processed/EFS-2001-2010-extract-BA.dta", clear

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


log close
