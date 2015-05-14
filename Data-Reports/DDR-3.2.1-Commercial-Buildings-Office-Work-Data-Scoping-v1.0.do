/**************************************************************
* Data Exploration for DEMAND Theme 3.2 - Commercial Buildings (& office work)
* - http://www.demand.ac.uk/research-themes/theme-3-managing-infrastructures-of-supply-and-demand/3-2-negotiating-needs-and-expectations-in-commercial-buildings/
* - focus on 'office work' in commercial buildings

* This work was funded by RCUK through the End User Energy Demand Centres Programme via the
* "DEMAND: Dynamics of Energy, Mobility and Demand" Centre 
* www.demand.ac.uk
* http://gtr.rcuk.ac.uk/project/0B657D54-247D-4AD6-9858-64E411D3D06C   

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

global where = "/Users/ben/Documents/Work"global droot = "$where/Data/Social Science Datatsets/"

global proot "$where/Projects/RCUK-DEMAND/Data Reports/Project 3.2 Commercial Buildings"

global logd = "$proot/results"

local version "1.0"
* version 1.0
* household level analysis

capture log close

log using "$logd/DDR-3.2.1-Data-Scoping-v`version'.smcl", replace

set more off

****************************
* MTUS data
* www.timeuse.org/mtus

use "$droot/MTUS/World 6/processed/MTUS-adult-aggregate-wf.dta", clear

tab survey countrya

* UK = 37
keep if countrya == 37

* there will be multiple diary days in some surveys
* need to average these to get mean minutes in work activities

/*
variable name   type   format      label      variable label
--------------------------------------------------------------------------------------------------------------------------------------
main5           int    %8.0g       LABC       meals at work or school
main7           int    %8.0g       LABC       paid work-main job (not at home)
main8           int    %8.0g       LABC       paid work at home
main11          int    %8.0g       LABC       travel as a part of work
main12          int    %8.0g       LABC       work breaks
main13          int    %8.0g       LABC       other time at workplace
*/

* work variables
local workvars = "main5 main7 main8 main11 main12 main13"
desc `workvars'

* turn all -ve values into missing
quietly mvdecode _all, mv(-9/-1)

* hold on to by vars we need later
collapse (mean) `workvars' , by(pid survey emp occup workhrs)

* how many 'workers' in each survey?
tab survey emp 

* hours worked etc for those in/out of work
bysort emp: tabstat `workvars', by(survey)

label li OCCUP

tab occup survey

* code 'office work' - plenty of room for mis-categorisation here!
recode occup (-9 -7=.) (1/9 = 1) (else=0), gen(office_worker)

* how may were there in each survey?
tab survey office_worker

* hours worked for those in work
* survey data
table survey office_worker if emp == 1, c(mean workhrs p50 workhrs iqr workhrs n workhrs)

* avg hours work
egen diary_avg_workmins_per_week = rowtotal(main5 main7 main8 main11 main12 main13)
* huge assumption here about multiplying up
gen diary_avg_workhours_per_week = (diary_avg_workmins_per_week/60)*5

* diary (mean per day)
table survey office_worker if emp == 1, c(mean diary_avg_workhours_per_week p50 diary_avg_workhours_per_week iqr diary_avg_workhours_per_week n diary_avg_workhours_per_week)

* do the reverse - another huge assumption
gen workmins_per_day = (workhrs * 60)/5

* compare diary & survey response
li survey emp occup diary_avg_workhours_per_week workhrs ///
	diary_avg_workmins_per_week workmins_per_day ///
	in 1/10

tabstat diary_avg_workhours_per_week workhrs ///
	diary_avg_workmins_per_week workmins_per_day if emp == 1, ///
	by(survey) s(mean n min max)

* they won't exactly match but they should be the same order of magnitude
* 1974 works well as it was a 7 day diary...

bysort survey: pwcorr diary_avg_workhours_per_week workhrs ///
	diary_avg_workmins_per_week workmins_per_day if emp == 1
	
* MTUS episode data to look at location etc
* UK only
keep pid workhrs emp office_worker

merge 1:m pid using "$droot/MTUS/World 6/processed/MTUS-adult-episode-UK-only-wf.dta"

recode main (7 8 9 11 12 13 = 1) (else = 0), gen(work_m)
recode sec (7 8 9 11 12 13 = 1) (else = 0), gen(work_s)

egen work = rowtotal(work_*)

* descriptives
tab eloc survey if emp == 1 & work == 1, mi
tab mtrav survey if emp == 1 & work == 1, mi

* sample rows
li day month year id s_starttime main sec eloc mtrav in 1/5

****************************
* ONS TU 2000
* https://www.esds.ac.uk/findingData/snDescription.asp?sn=4504
use "$droot/UK Time Use 2000/processed/Individual_data_5_v1.0.dta", clear

tabout soc using "$logd/UK-ONS-2000-TU-occ-detail.txt", replace

use "$droot/UK Time Use 2000/processed/diary_data_8_long_v1.0.dta", clear

/*
        1000 unspecified employment
        1110 working time in main job
        1120 coffee and other breaks in main job
        1210 working time in second job
        1220 coffee and other breaks in second job
        1300 unspecified activities related to employment
        1310 lunch break
        1390 other specified activities related to employment
*/
recode pact (1000 1110 1120 1210 1220 1300 1310 1390 = 1) (else = 0), gen(work_m)
recode sact (1000 1110 1120 1210 1220 1300 1310 1390 = 1) (else = 0), gen(work_s)

egen work = rowtotal(work_*)

tab wher if work == 1, mi

tabout pact using "$logd/UK-ONS-2000-TU-pact-detail.txt", replace
tabout pact if work == 1 using "$logd/UK-ONS-2000-TU-pact-detail-work.txt", replace


* episodes file - but still in wide format!
* use "`droot'/Time Use 2000/processed/diary_data_8_long_v1.0.dta"

****************************
* ONS TU 2005
* https://www.esds.ac.uk/findingData/snDescription.asp?sn=5592
use "$droot/UK Time Use 2005/processed/timeusefinal_for_archive_survey_v2.0.dta", clear


use "$droot/UK Time Use 2005/processed/timeusefinal_for_archive_diary_long_v2.0.dta", clear

tab pact 
tab lact

label li pact144


****************************
* BHPS
* https://www.esds.ac.uk/findingData/snDescription.asp?sn=5151
* last wave
use "$droot/BHPS/waves-1-18/stata/rindresp.dta", clear

* time of day usually work
tab rjbtime

* occupation (lots!)
* see http://www.ons.gov.uk/ons/guide-method/classifications/current-standard-classifications/soc2010/index.html
tab rjbsoc00

****************************
* USOC
* https://www.esds.ac.uk/findingData/snDescription.asp?sn=6849
* first wave
use "$droot/USOC/UKDA-6614-W1-3-stata12_se/stata12_se/a_indresp.dta"

* condensed SEG
tab a_jbseg_dv 

****************************
* LFS
* http://discover.ukdataservice.ac.uk/series/?sn=2000026
* 1975
use "$droot/Labour Force Survey/1975/stata/lfs75.dta", clear

* variables have no names - labels = var names!
* documentation = scanned but searchable, includes occupation type

* 1981
use "$droot/Labour Force Survey/1981/stata/lfs81", clear
* coded & labeled OK

* keep respondents only & of working age
keep if RECTYP == 1 & AGES > 4 & AGES < 14
* worker status
tab SOCCLAS
label li SOCCLAS
* working from home
tab HOME
* location
tab PLWORK

* industry (more detail available via IND, INDCLAS etc)
tab INDDIV


* 2013 (annual Eurostat version)
use "$droot/Labour Force Survey/2013/stata/uk2013yv2_annual.dta", clear

* no labels!!
* used nesstar version instead

log close
