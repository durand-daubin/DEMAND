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

capture log close

log using "$logd/DDR-3.2.2-Data-Analysis-v`version'.smcl", replace

* control flow
local do_agg 0

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

label li OCCUP

tab occup survey

* code 'office work' - plenty of room for mis-categorisation here!
recode occup (-9 -7=.) (1/9 = 1) (else=0), gen(office_worker)

lab def office_worker 0 "Not an office worker" 1 "Office worker"
lab val office_worker office_worker

if `do_agg' {
	preserve
		* average the work hours across all diary days
		* probably should be over working days only?
		* hold on to by vars we need later
		collapse (mean) `workvars' , by(pid survey emp occup workhrs office_worker)
		
		* how many 'workers' in each survey?
		tab survey emp 
		
		* hours worked etc for those in/out of work
		bysort emp: tabstat `workvars', by(survey)
			
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
	
	restore
}

* MTUS episode data to look at location etc
* UK only

keep pid diarypid workhrs emp office_worker propwt

merge 1:m diarypid using "$droot/MTUS/World 6/processed/MTUS-adult-episode-UK-only-wf.dta"


recode main (7 8 9 11 12 13 = 1) (else = 0), gen(work_m)
recode sec (7 8 9 11 12 13 = 1) (else = 0), gen(work_s)

egen work = rowtotal(work_*)

* this will have a value of 0 if no work, 1 if work as main or sec and 2 if work as main AND sec
* recode slightly
recode work (2=1)

svyset [iw = propwt]

** descriptives
local tvars "eloc mtrav"
			
* tabout does not do 3 way tables but we can fool it into creating them using
* http://www.ianwatson.com.au/stata/tabout_tutorial.pdf p35

local count = 0
local filemethod = "replace"
levelsof office_worker, local(levels)
*di "* levels: `levels'"
local labels: value label office_worker
*di "* labels: `labels'"
foreach v of local tvars {
	foreach l of local levels {	
		if `count' > 0 {
			* we already made one pass so now append
			local filemethod = "append"	
			*local heading = "h1(nil) h2(nil)"
		}
		local vlabel : label `labels' `l'
		di "* Level: `l' (`vlabel')"
		* if episode = work
		qui: tabout `v' survey if work == 1 & office_worker == `l' using "$logd/MTUS_`v'_work_by_year.txt", `filemethod' ///
			h3("Worker: `vlabel'") ///
			cells(col se) ///
			format(3) ///
			svy 
		local count = `count' + 1
	}
}


* sample rows
li day month year id s_starttime main sec eloc mtrav in 1/5


log close
