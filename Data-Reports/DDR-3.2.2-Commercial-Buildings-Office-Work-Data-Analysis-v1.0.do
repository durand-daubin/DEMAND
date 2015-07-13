/*
*************************************************************
Data Exploration for DEMAND Theme 3.2 - Commercial Buildings (& office work)
 - http://www.demand.ac.uk/research-themes/theme-3-managing-infrastructures-of-supply-and-demand/3-2-negotiating-needs-and-expectations-in-commercial-buildings/
 - focus on 'office work' in commercial buildings

This work was funded by RCUK through the End User Energy Demand Centres Programme via the
"DEMAND: Dynamics of Energy, Mobility and Demand" Centre
www.demand.ac.uk
http://gtr.rcuk.ac.uk/project/0B657D54-247D-4AD6-9858-64E411D3D06C

Most recent version of this script will be found at
https://github.com/dataknut/DEMAND/blob/master/Data-Reports/DDR-3.2.2-Commercial-Buildings-Office-Work-Data-Analysis-v1.0.do

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

local version "1.0" // version control managed via github
* version 1.0

capture log close

log using "$logd/DDR-3.2.2-Data-Analysis-v`version'.smcl", replace

* control flow
local do_agg 1
local do_episodes 1
local do_sampled 1

set more off

****************************
* MTUS data
* www.timeuse.org/mtus

use "$droot/MTUS/World 6/processed/MTUS-adult-aggregate-wf.dta", clear

tab survey countrya

* UK = 37
keep if countrya == 37

* create a bespoke survey which merges 1983 & 1987
* has the advantage of providing all seasons for '1985'
recode survey (1974=1974 "1974") (1983/1987=1985 "1985") (1995 = 1995 "1995") (2000=2000 "2000") (2005=2005 "2005"), gen(ba_survey)

tab survey ba_survey

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

tab occup ba_survey

* code 'office work' - plenty of room for mis-categorisation here!
recode occup (-9 -7=.) (1/9 = 1) (else=0), gen(office_worker)

lab def office_worker 0 "Not an office worker" 1 "Office worker"
lab val office_worker office_worker

if `do_agg' {
	preserve
		* average the work hours across all diary days
		* probably should be over working days only?
		* hold on to by vars we need later
		collapse (mean) `workvars' , by(pid ba_survey emp occup workhrs office_worker)

		* how many 'workers' in each survey?
		tab ba_survey emp

		* hours worked etc for those in/out of work
		bysort emp: tabstat `workvars', by(ba_survey)

		* how may were there in each survey?
		tab ba_survey office_worker

		* hours worked for those in work
		* survey data
		table ba_survey office_worker if emp == 1, c(mean workhrs p50 workhrs iqr workhrs n workhrs)

		* avg hours work
		egen diary_avg_workmins_per_week = rowtotal(main5 main7 main8 main11 main12 main13)
		* huge assumption here about multiplying up
		gen diary_avg_workhours_per_week = (diary_avg_workmins_per_week/60)*5

		* diary (mean per day)
		table ba_survey office_worker if emp == 1, c(mean diary_avg_workhours_per_week p50 diary_avg_workhours_per_week iqr diary_avg_workhours_per_week n diary_avg_workhours_per_week)

		* do the reverse - another huge assumption
		gen workmins_per_day = (workhrs * 60)/5

		* compare diary & survey response
		li ba_survey emp occup diary_avg_workhours_per_week workhrs ///
			diary_avg_workmins_per_week workmins_per_day ///
			in 1/10

		tabstat diary_avg_workhours_per_week workhrs ///
			diary_avg_workmins_per_week workmins_per_day if emp == 1, ///
			by(ba_survey) s(mean n min max)

		* they won't exactly match but they should be the same order of magnitude
		* 1974 works well as it was a 7 day diary...

		bysort ba_survey: pwcorr diary_avg_workhours_per_week workhrs ///
			diary_avg_workmins_per_week workmins_per_day if emp == 1

	restore
}

* MTUS episode data to look at location etc
* UK only

keep pid diarypid workhrs emp office_worker propwt ba_survey

if `do_episodes' {
	*preserve
		merge 1:m diarypid using "$droot/MTUS/World 6/processed/MTUS-adult-episode-UK-only-wf.dta"


		recode main (7 8 9 11 12 13 = 1) (else = 0), gen(work_m)
		recode sec (7 8 9 11 12 13 = 1) (else = 0), gen(work_s)

		egen work = rowtotal(work_*)

		* this will have a value of 0 if no work, 1 if work as main or sec and 2 if work as main AND sec
		* recode slightly
		recode work (2=1)

		svyset [iw = propwt]

		di "***************************"
		di "** descriptives by location"
		local tvars "eloc"

		* tabout does not do 3 way tables but we can fool it into creating them using
		* http://www.ianwatson.com.au/stata/tabout_tutorial.pdf p35

		local count = 0
		local filemethod = "replace"
		levelsof office_worker, local(levels)
		*di "* levels: `levels'"
		local labels: value label office_worker
		*di "* labels: `labels'"
		foreach v of local tvars {
			di "* Processing `v'"
			foreach l of local levels {
				if `count' > 0 {
					* we already made one pass so now append
					local filemethod = "append"
					*local heading = "h1(nil) h2(nil)"
				}
				local vlabel : label `labels' `l'
				di "*-> Level: `l' (`vlabel')"
				* if episode = work
				qui: tabout `v' ba_survey if work == 1 & office_worker == `l' ///
					using "$logd/MTUS_`v'_work_by_year.txt", `filemethod' ///
					h3("Worker: `vlabel'") ///
					cells(col se) ///
					format(3) ///
					svy
				local count = `count' + 1
			}
		}


		* sample rows
		li s_dow mtus_month mtus_year id s_starttime main sec eloc mtrav in 1/5

		* office work = at home or at work location (assume 'office')
		lab li ELOC
		gen office_work = 0
		replace office_work = 1 if work == 1 & office_worker == 1 & (eloc == 1 | eloc == 3)

		* keep office work - not interested in any comparions with not ofice work for now
		keep if office_work == 1

			di "***************************"
			di "* simple table by time for episodes"
		tabout s_halfhour ba_survey  ///
			using "$logd/MTUS_episodes_office_work_by_halfhour_per_year.txt", replace ///
			cells(col se) ///
			format(3) ///
			svy

		di "***************************"
		di "** prevalence of reporting of secondary acts by ba_survey"
		local count = 0
		local filemethod = "replace"
		levelsof ba_survey, local(levels)
		*di "* levels: `levels'"
		local labels: value label ba_survey
		*di "* labels: `labels'"
		foreach l of local levels {
			if `count' > 0 {
				* we already made one pass so now append
				local filemethod = "append"
				*local heading = "h1(nil) h2(nil)"
			}
			local vlabel : label `labels' `l'
			di "*-> Level: `l' (`vlabel')"
			* if episode = work
			qui: tabout main sec if ba_survey == `l' ///
				using "$logd/MTUS_office_work_sact_by_ba_survey.txt", `filemethod' ///
				h3("Year: `vlabel'") ///
				cells(col) ///
				format(3) ///
				svy
			local count = `count' + 1
		}

	restore
}

* switch to 'sampled' data
if `do_sampled' {
	merge 1:m diarypid using "$droot/MTUS/World 6/processed/MTUS-adult-episode-UK-only-wf-10min-samples-long-v1.0.dta"
	recode pact (7 8 9 11 12 13 = 1) (else = 0), gen(work_m)
	recode sact (7 8 9 11 12 13 = 1) (else = 0), gen(work_s)

	egen work = rowtotal(work_*)

	* this will have a value of 0 if no work, 1 if work as main or sec and 2 if work as main AND sec
	* recode slightly
	recode work (2=1)

	* office work = at home or at work location (assume 'office')
	lab li ELOC
	gen office_work = 0
	replace office_work = 1 if work == 1 & office_worker == 1 & (eloc == 1 | eloc == 3)

	svyset [iw = propwt]

	gen ba_hourt = hh(s_starttime)
	gen ba_minst = mm(s_starttime)

	gen ba_hh = 0 if ba_minst < 30
	replace ba_hh = 30 if ba_minst > 29
	gen ba_sec = 0
	* sets date to 1969!
	gen s_halfhour = hms(ba_hourt, ba_hh, ba_sec)
	lab var s_halfhour "Episode starts during the half hour following"
	format s_halfhour %tcHH:MM

	drop ba_hourt ba_minst ba_hh ba_sec

	* keep work
	keep if work == 1

	** simple tables by time for sampled data
	* proportion of work that is office work
	tabout s_halfhour ba_survey ///
		using "$logd/MTUS_sampled_pc_office_work_by_halfhour_per_year.txt", replace ///
		cells(mean office_work se) ///
		format(3) ///
		svy sum

	* keep office work - not interested in any comparions with not ofice work for now
	keep if office_work == 1

	* col % of office work - when is it done?
	tabout s_halfhour ba_survey ///
		using "$logd/MTUS_sampled_distn_office_work_by_halfhour_per_year.txt", replace ///
		cells(col se) ///
		format(3) ///
		svy

	* split by location
	* use tabout trick
	local count = 0
	local filemethod = "replace"
	levelsof eloc, local(levels)
	*di "* levels: `levels'"
	local labels: value label eloc
	*di "* labels: `labels'"
	foreach l of local levels {
		if `count' > 0 {
			* we already made one pass so now append
			local filemethod = "append"
			*local heading = "h1(nil) h2(nil)"
		}
		local vlabel : label `labels' `l'
		di "*-> Level: `l' (`vlabel')"
		* if episode = work
		qui: tabout s_halfhour ba_survey if eloc == `l' ///
			using "$logd/MTUS_sampled_office_work_by_halfhour_per_year_eloc_col_pct.txt", `filemethod' ///
			h3("Location: `vlabel'") ///
			cells(col se) ///
			format(3) ///
			svy

		qui: tabout s_halfhour ba_survey if eloc == `l' ///
			using "$logd/MTUS_sampled_office_work_by_halfhour_per_year_eloc_freq.txt", `filemethod' ///
			h3("Location: `vlabel'") ///
			cells(freq) ///
			format(3) ///
			svy
		local count = `count' + 1
	}
	* look at office work at home by day of week
		* use tabout trick
	local count = 0
	local filemethod = "replace"
	levelsof s_dow, local(levels)
	*di "* levels: `levels'"
	local labels: value label s_dow
	*di "* labels: `labels'"
	foreach l of local levels {
		if `count' > 0 {
			* we already made one pass so now append
			local filemethod = "append"
			*local heading = "h1(nil) h2(nil)"
		}
		local vlabel : label `labels' `l'
		di "*-> Level: `l' (`vlabel')"
		* if episode = work - at home
		qui: tabout s_halfhour ba_survey if s_dow == `l' & eloc == 1 ///
			using "$logd/MTUS_sampled_office_work_at_home_by_halfhour_per_year_day_col_pct.txt", `filemethod' ///
			h3("Location: `vlabel'") ///
			cells(col se) ///
			format(3) ///
			svy

		qui: tabout s_halfhour ba_survey if s_dow == `l' & eloc == 1 ///
			using "$logd/MTUS_sampled_office_work_at_home_by_halfhour_per_year_day_freq.txt", `filemethod' ///
			h3("Location: `vlabel'") ///
			cells(freq) ///
			format(3) ///
			svy

		* if episode = work - workplace
		qui: tabout s_halfhour ba_survey if s_dow == `l' & eloc == 3 ///
			using "$logd/MTUS_sampled_office_work_at_workplace_by_halfhour_per_year_day_col_pct.txt", `filemethod' ///
			h3("Location: `vlabel'") ///
			cells(col se) ///
			format(3) ///
			svy

		qui: tabout s_halfhour ba_survey if s_dow == `l' & eloc == 3 ///
			using "$logd/MTUS_sampled_office_work_at_workplace_by_halfhour_per_year_day_freq.txt", `filemethod' ///
			h3("Location: `vlabel'") ///
			cells(freq) ///
			format(3) ///
			svy
		local count = `count' + 1
	}

}

log close
