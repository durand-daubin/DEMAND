**************************************************************
* Data Exploration for DEMAND Theme 2.3 - older people's mobile lives
* - focus on leisure and longer duration/special travel

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

local where = "/Users/ben/Documents/Work"local droot = "`where'/Data/Social Science Datatsets/"

local proot "`where'/Projects/RCUK-DEMAND/Data Reports/Project 2.3 older people mobile lives"

local logd = "`proot'/results"

local version "1.0"
* version 1.0
* household level analysis

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
* UK only
use "`droot'/MTUS/World 6/processed/MTUS-adult-episode-UK-only-wf.dta", clear

* descriptives
tab main eloc
tab eloc survey
tab mtrav survey
tab main eloc
tab mtrav
tabstat time, by(mtrav) s(mean n min max p5 p50 p95)
li day month year id s_starttime main sec eloc mtrav in 1/5

****************************
* ONS TU 2000
* https://www.esds.ac.uk/findingData/snDescription.asp?sn=4504
use "`droot'/Time Use 2000/processed/diary_data_8_long_v1.0.dta"

* more detailed time use activities
tab pact
* much more codes for location
tab wher

* episodes file - but still in wide format!
* use "`droot'/Time Use 2000/processed/diary_data_8_long_v1.0.dta"

****************************
* ONS TU 2005
* https://www.esds.ac.uk/findingData/snDescription.asp?sn=5592
use "`droot'/Time Use 2005/processed/timeusefinal_for_archive_diary_long_v2.0.dta"

tab pact 
tab lact

label li pact144

****************************
* EFS/LCFS
* https://www.esds.ac.uk/findingData/snDescription.asp?sn=7472
use "`droot'/Expenditure and Food Survey/processed/EFS-2001-2010-extract-BA.dta", clear

/*
* XXXc = child
* XXXw = internet
* XXXt = total

a325            byte   %8.0g       a325       purchase via internet - package holidays
a328            byte   %8.0g       a328       purchase via internet - flights from uk

b480            double %9.0g                  holiday package within united kingdom
b481            double %9.0g                  holiday package outside united kingdom

c96111c         byte   %8.0g                  package holidays in the uk, accommodation
c96111w         byte   %8.0g                  package holidays in the uk, accomodation - internet

c96112c         byte   %8.0g                  package holidays abroad, accommodation
c96112w         byte   %8.0g                  package holidays abroad, accomodation - internet

cc5413          double %9.0g                  non-package holiday, other travel insurance
cc5413c         byte   %8.0g                  non-package holiday, other travel insurance
cc5413t         double %9.0g                  non-package holiday, other travel insurance

c73311          double %9.0g                  air fares (within uk)
c73311c         byte   %8.0g                  air fares (within uk)
c73311t         double %9.0g                  air fares (within uk)
c73311w         double %10.0g                 air-fares (within uk) - internet

c73312          double %9.0g                  air fares (international)
c73312c         byte   %8.0g                  air fares (international)
c73312t         double %9.0g                  air fares (international)
c73312w         double %10.0g                 air-fares (international) - internet

c_age 
*/

* selected vars
* ignore children, separate total & internet if interested
local all_vars "a325 a328 b480 b481 c96111w c96112w cc5413t c73311t c73311w c73312t c73312w"

* check availability of variables over time
tabstat `all_vars', by(survey_year)

tab c_age

* survey responses
* package holidays
tabstat a325 /// purchase via internet - package holidays
	a328 /// purchase via internet - flights from uk
	b480 /// holiday package within united kingdom
	b481 /// holiday package outside united kingdom
	if c_age > 4, by(survey_year) 

* diary responses - holidays
tabstat c96111* /// package holidays in the uk, accommodation
	c96112* /// package holidays abroad, accommodation
	cc5413* /// non-package holiday, other travel insurance
	if c_age > 4, by(survey_year)

* diary responses - air fares
tabstat c73311* /// air fares (within uk)
	c73312* /// air fares (international)
	if c_age > 4, by(survey_year)

local all_vars "a325 a328 b480 b481 c96111w c96112w cc5413t c73311t c73311w c73312t c73312w"
drop *_z
* switch to looking at % who reported expenditure on these items (not value of expenditure)
foreach v of local all_vars {
	di "* % zero analysis: `v'"
	* do it this way round then the mean = proportion who report
	gen `v'_z = 1
	replace `v'_z = 0 if `v' == 0
	*table survey_year if c_age > 4 , c(mean `v'_z)
	*tabout survey_year c_age [iw=weighta] using "`logd'/`v'_z_mean.txt", cells(mean `v'_z se) format(3) sum svy replace
} 
tabstat *_z if c_age > 4, by(survey_year)

* look at % expenditure
foreach v of local zvars {
	di "* % expenditure analysis: `v'"
	* % of all expenditure
	gen `v'_pr = `v'/p630p
	table survey_year c_age [iw=weighta] , c(mean `v'_pr)
	tabout survey_year c_age [iw=weighta] using "`logd'/`v'_pr_mean.txt", cells(mean `v'_pr se) format(3) sum svy replace
} 

****************************
* Taking Part
* https://www.esds.ac.uk/findingData/snDescription.asp?sn=7371
use "`droot'/DCMS Taking Part/UKDA-7371-stata9_se/stata9_se/taking_part_y8_adult_archive.dta", clear

desc holiday*
desc herwher*

egen c_age = cut(age1), at(16,25,35,45,55,65,75,150)

tab ageb1 herwhere6 if age1 > 54
tab ageb1 herwhere7 if age1 > 54

****************************
* International Passenger Survey
* https://www.esds.ac.uk/findingData/snDescription.asp?sn=7534
use "`droot'/UK International Passenger Survey/UKDA-7534-stata11/stata11/qcontq12014cust.dta", clear", clear

* age only collected (coded?) for arrivals in the UK?!
* try to isolate UK residents
tab Age Flow if county != ., mi
tab Purpose if county !=., mi

****************************
* BHPS
* https://www.esds.ac.uk/findingData/snDescription.asp?sn=5151
* last wave
use "`droot'/BHPS/waves-1-18/stata/rindresp.dta"
egen c_age = cut(rage), at(16,25,35,45,55,65,75,150)
tab c_age

****************************
* USOC
* https://www.esds.ac.uk/findingData/snDescription.asp?sn=6849
* first wave
use "`droot'/USOC/UKDA-6614-W1-3-stata12_se/stata12_se/a_indresp.dta"
tab a_agegr10_dv

****************************
* NTS
* https://www.esds.ac.uk/findingData/snDescription.asp?sn=5340
* first wave
* analsyed using NESTAR - what a fabtastic tool for avoiding data downlaods!!
* http://nesstar.ukdataservice.ac.uk/

****************************
* ELSA
* https://www.esds.ac.uk/findingData/snDescription.asp?sn=5050
* Wave 6 for age distributions
use "`droot'/English Longitudinal Study of Ageing/UKDA-5050-w0-w6/stata11_se/wave_6_ifs_derived_variables.dta"

egen c_age = cut(age), at(16,25,35,45,55,65,75,150)

* elsa = sample membership (as partners/carers etc also interviewd)
tab c_age elsa

keep idauniq c_age elsa

* look for useful variables

set maxvar 10000 /// there are a lot of variables!

merge 1:1 idauniq using "`droot'/English Longitudinal Study of Ageing/UKDA-5050-w0-w6/stata11_se/elsa_w6_data_for_archive.dta"

tab scptr3
tab c_age scptr3 if elsa == 1
tab c_age scptr4 if elsa == 1

tab sccomm 

* duration of any travel
* sccomh sccmi 
gen ba_travel_duration = (sccomh*60) + sccmi if sccomh >=0 & sccmi >=0
* test
tabstat ba_travel_duration, by(sccomm) s(mean min max n)

tabstat ba_travel_duration if elsa == 1, by(c_age) s(n mean min p50 max)
* now include all respondents (not just those who travelled)
gen ba_travel_duration_all = 0
replace ba_travel_duration_all = ba_travel_duration if ba_travel_duration != .
tabstat ba_travel_duration_all if elsa == 1, by(c_age) s(n mean min p50 max)

log close
