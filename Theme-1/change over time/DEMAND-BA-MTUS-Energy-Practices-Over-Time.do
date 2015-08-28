*******************************************
* Script to use a number of datasets to examine:
* - changing energy-demanding practices from 1975 to 2005
* uses:
* - MTUS World 6 time-use data (www.timeuse.org/mtus UK subset) - data already in long format (but episodes)

* This work was funded by RCUK through the End User Energy Demand Centres Programme via the
* "DEMAND: Dynamics of Energy, Mobility and Demand" Centre (www.demand.ac.uk, gow.epsrc.ac.uk/NGBOViewGrant.aspx?GrantRef=EP/K011723/1)

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

* Requires: tabout

clear all

* change these to run this script on different PC
* use globals so can re-run parts of the script

global where "~/Documents/Work"
global droot "$where/Data/Social Science Datasets"

* MTUS
global mtuspath "$droot/MTUS/World 6/processed"

* SPRG
global sprgpath "$where/Projects/ESRC-SPRG/WP4-Micro_water/data/sprg_survey/data/safe/v6"

* where to put results
global proot "$where/Papers and Conferences/Energy Through Time"


* version
global version = "v3.0"
* changes new act coding method to avoid messing up later codes

*global version = "v2.0"

* global version = "v1.0"
* weights the final counts

global rpath "$proot/results/$version"

capture log close _all

log using "$rpath/DEMAND_BA_MTUS_Energy_Practices_Over_Time_$version.smcl", replace name(main)

* which subgroup of mtus are we interested in?
global mtusfilter "_all"

* control what gets done
* if you run all of these the script will take some time to run
local do_aggregated = 0 // table of minutes per main activity
local do_classes = 0 // big tables of all activity classes, eloc and mtrav by time of day
local do_halfhours = 0 // tabout tables for each time use act/practice - takes a long time
local do_demogs = 1 // tables of prevalence of acts by income and age etc

*local do_half_hour_by_day_year = 0 // create tables for all years for all acts - takes a very long time & breaks memory!

* original activities (from MTUS 69 codes)
* 4 18 20 21 57 58 59 60 61 62 63 64 65 66 67 68
* add any of them in to refresh the results
local old_acts "4 18 20 21"

* these are the ones we will invent to catch particular acts/practices
* 100 101 102 1021 103 104 105 106
* add any of them in to refresh the results
local new_acts "100 101 102 1021 103 104 105 106" // see above

local all_acts = "`old_acts' `new_acts'"

* run the constructor to add all activities to the looping list
foreach a of local all_acts {
	local main_acts = "`main_acts' main`a'"
	local sec_acts = "`sec_acts' sec`a'"
}


* make script run without waiting for user input
set more off

**********************************
* Codes of interest
local main4l "4 Wash, dress, care for self"
local main18l "18 Food preparation, cooking"
local main20l "20 Cleaning"
local main21l "21 Laundry, ironing, clothing repair"
local main57l "57 Listen to music or other audio content"
local main58l "58 Listen to radio"
local main59l "59 Watch TV, video, DVD, streamed film at home"
local main60l "60 Computer games at home"
local main61l "61 E-mail, surf internet, computing at home"
local main62l "62 No activity, imputed or recorded transport"
local main63l "63 Travel to or from work"
local main64l "64 Education travel"
local main65l "65 Voluntary,civic,religious travel"
local main66l "66 Child, adult care travel"
local main67l "67 Shop, person or hhld care travel"
local main68l "68 Other travel"
* new derived codes
local main100l "100 Eating at home"
local main101l "101 Car travel"
local main102l "102 Car travel ending at home"
local main1021l "1021 Car travel ending anywhere"
local main103l "103 TV, video, DVD, computer games at home"
local main104l "104 Computer,Internet at home"
local main105l "105 Cooking late supper at home"
local main106l "106 Cooking Sunday lunch at home"


if `do_aggregated' {
	di "* Use the aggregated file to test the mins per day for these acts for each survey as context"
	use "$mtuspath/MTUS-adult-aggregate-UK-only-wf.dta", clear

	svyset [iw=propwt]

	* create a bespoke survey which merges 1983 & 1987
	* has the advantage of providing all seasons for '1985'
	recode survey (1974=1974 "1974") (1983/1987=1985 "1985") (1995 = 1995 "1995") (2000=2000 "2000") (2005=2005 "2005"), gen(ba_survey)

	foreach act of local old_acts {
		di "* Mean minutes per day - `main`act'l'"
		qui: tabout ba_survey ///
			using "$rpath/MTUS_aggregate_uk_`main`act'l'_mean_mins_by_ba_survey_$version.txt", replace ///
			h3("Survey: `vlabel'") ///
			cells(mean main`act' se) /// can't do secondary act as not in this aggregate file
			format(3) ///
			sum svy
	}
}


*************************
* sampled data
* this requires the 10 minute sampling process implemented in
* https://github.com/dataknut/MTUS/blob/master/process-MTUS-W6-convert-to-X-min-samples-v1.0-adult.do
* to have been run over the MTUS first with X set to 10

* use the sampled data
use "$mtuspath/MTUS-adult-episode-UK-only-wf-10min-samples-long-v1.0.dta", clear

* merge in key variables from survey data
* hhtype empstat emp unemp student retired propwt survey day month year hhldsize famstat ba_4hrspaidwork
merge m:1 diarypid using "$mtuspath/MTUS-adult-aggregate-UK-only-wf.dta", keepusing(sex age mtus_* empstat ba_hhsize ba_nchild ba_age_r ba_birth_cohort income propwt) ///
	gen(m_aggvars)

* fix
lab def ba_age_r 16 "16-24" 25 "25-34" 35 "35-44" 45 "45-54" 55 "55-64" 65 "65-74" 75 "75+"
lab val ba_age_r ba_age_r

keep if m_aggvars == 3

* set up half-hour variable
gen ba_hourt = hh(s_starttime)
gen ba_minst = mm(s_starttime)

gen ba_hh = 0 if ba_minst < 30
replace ba_hh = 30 if ba_minst > 29
gen ba_sec = 0
* sets date to 1969!
gen s_halfhour = hms(ba_hourt, ba_hh, ba_sec)
lab var s_halfhour "Episode starts during the half hour following"
format s_halfhour %tcHH:MM

* seasons
recode mtus_month (3 4 5 = 1 "Spring") (6 7 8 = 2 "Summer") (9 10 11 = 3 "Autumn") (12 1 2 = 4 "Winter"), gen(season)
* check
bysort mtus_year: tab mtus_month season

* create a bespoke survey which merges 1983 & 1987
* has the advantage of providing all seasons for '1985'
recode survey (1974=1974 "1974") (1983/1987=1985 "1985") (1995 = 1995 "1995") (2000=2000 "2000") (2005=2005 "2005"), gen(ba_survey)

* this is the number of 10 minute samples by survey & day of the week
tab ba_survey s_dow [iw=propwt]

* simple 'Activity Class' categorisation for year on year comparison as MTUS has 69 or 41 codes which are hard to visualise
* this is a DEMAND (energy) oriented classification
* there are an infinite number of ways of doing this - labels give 'justification'
recode pact (2 3 55 = 1 "Sleep/rest") ///
	(1 4 19 20 21 22 23 27 28 30 31 32 46 54 = 2 "Personal, child, adult or household care/chores") ///
	(5 6 18 = 3 "Cooking or eating") ///
	(7 8 9 10 11 12 13 14 = 4 "Work or work related") ///
	(15 16 17 29 = 5 "Education or related") ///
	(24 25 26 = 6 "Shopping/service use") ///
	(33 34 35 36 37 38 39 40 41 48 49 50 51 52 53 = 7 "Voluntary, civic, watching sport, leisure or social activities") ///
	(42 43 44 45 47 = 8 "Sport or exercise") ///
	(56 57 58 59 60 61 = 9 "Media use incl. TV, radio, PC, internet") ///
	(62 63 64 65 66 67 68 = 10 "Travel") ///
	(69 = 11 "Not recorded") (nonmissing = 12 "Not coded"), gen(ba_p_class)

recode sact (2 3 55 = 1 "Sleep/rest") ///
	(1 4 19 20 21 22 23 27 28 30 31 32 46 54 = 2 "Personal, child, adult or household care/chores") ///
	(5 6 18 = 3 "Cooking or eating") ///
	(7 8 9 10 11 12 13 14 = 4 "Work or work related") ///
	(15 16 17 29 = 5 "Education or related") ///
	(24 25 26 = 6 "Shopping/service use") ///
	(33 34 35 36 37 38 39 40 41 48 49 50 51 52 53 = 7 "Voluntary, civic, watching sport, leisure or social activities") ///
	(42 43 44 45 47 = 8 "Sport or exercise") ///
	(56 57 58 59 60 61 = 9 "Media use incl. TV, radio, PC, internet") ///
	(62 63 64 65 66 67 68 = 10 "Travel") ///
	(69 = 11 "Not recorded") (nonmissing = 12 "Not coded"), gen(ba_s_class)

*test
tab pact ba_p_class, mi
tab sact ba_s_class, mi

* set survey
svyset [iw=propwt]

if `do_classes' {
	* push into own log file to make tables easier to find
	local nlog "$rpath/DEMAND_BA_MTUS_Energy_Practices_Over_Time_activity_classes_$version.smcl"
	di "* running do_halfhours to `nlog'"
	log off main
	log using "`nlog'", replace  name(do_classes)

	di "* Produce tables of primary activity classes, secondary activity classes, location & mode of travel per halfhour per survey"
	local vars "ba_p_class ba_s_class eloc mtrav"

	preserve
		keep s_halfhour ba_survey `vars' propwt

		levelsof ba_survey, local(levels)
		foreach l of local levels {
			di "********************"
			di "* Doing tables for `l'"
			foreach v of local vars {
				di "* -> Doing tables of `v' for `l'"
				* using tab is a lot quicker than the survey option on tabout but have to manually copy :-(
				* could just as easily use bysort for this
				* do not set to 'at home' only as we want a sense of what is changing overall
				tab s_halfhour `v' [iw=propwt] if ba_survey == `l', row nof
			}
		}
	restore
	log off do_classes
	log on main
}

* create old acts (simple)
foreach a of local old_acts {
	local temp "p s"
	foreach t of local temp {
		gen `t'act_`a' = 0
		replace `t'act_`a' = 1 if `t'act == `a'
	}
}

* Now create new pact/sact codes which will be picked up later in the loops
* use fake numbers otherwise it fails

* 100 eating at home
gen pact_100 = 0
gen sact_100 = 0
replace pact_100 = 1 if (pact == 5 | pact == 6) & eloc == 1
replace sact_100 = 1 if (sact == 5 | sact == 6) & eloc == 1

* 101: Car travel
gen pact_101 = 0
gen sact_101 = 0
replace pact_101 = 1 if mtrav == 1
replace sact_101 = 1 if mtrav == 1

* 102: Car travel ending at home
* needs ts to be set so we can use lag
tsset diarypid s_starttime, delta(10 mins)
* now = at home, last was car travel
gen pact_102 = 0
gen sact_102 = 0
replace pact_102 = 1 if L.mtrav == 1 & eloc == 1
replace sact_102 = 1 if L.mtrav == 1 & eloc == 1

* 1021: Car travel ending anywhere
* now = at home, last was car travel
gen pact_1021 = 0
gen sact_1021 = 0
replace pact_1021 = 1 if L.mtrav == 1 & eloc != 8
replace sact_1021 = 1 if L.mtrav == 1 & eloc != 8


* 103: TV/video/DVD/computer games at home
gen pact_103 = 0
gen sact_103 = 0
replace pact_103 = 1 if (pact == 59 | pact == 60) & eloc == 1
replace sact_103 = 1 if (sact == 59 | sact == 60) & eloc == 1

* 104: Computer/Internet at home
gen pact_104 = 0
gen sact_104 = 0
replace pact_104 = 1 if pact == 61 & eloc == 1
replace sact_104 = 1 if sact == 61 & eloc == 1

* 105: Cooking late supper at home
gen pact_105 = 0
gen sact_105 = 0
replace pact_105 = 1 if pact == 18 & eloc == 1 & ba_hourt > 21 & ba_hourt <= 23
replace sact_105 = 1 if sact == 18 & eloc == 1 & ba_hourt > 21 & ba_hourt <= 23

* 106: Cooking lunch at home
gen pact_106 = 0
gen sact_106 = 0
replace pact_106 = 1 if pact == 18 & eloc == 1 & ba_hourt > 11 & ba_hourt <= 14 & s_dow == 0
replace sact_106 = 1 if sact == 18 & eloc == 1 & ba_hourt > 11 & ba_hourt <= 14 & s_dow == 0

* loop over the acts of interest to construct 'all'
foreach act of local all_acts {
	di "Processing: `act' = `main`act'l'"
	gen all_`act' = 0
	replace all_`act' = 1 if pact_`act' == 1 | sact_`act' == 1
	lab var all_`act' "All: `main`act'l'"
	tab all_`act' s_dow
}

* drop primary & secondary vars as take space & are unused

drop pact_* sact_*

if `do_halfhours' {
	* push into own log file
	local nlog "$rpath/DEMAND_BA_MTUS_Energy_Practices_Over_Time_acts_halfhours_$version.smcl"
	di "* running do_halfhours to `nlog'"
	log off main
	log using "`nlog'", replace  name(do_halfhours)

	* keep just the variables we need to save memory
	* others: month cday diary sex age year season eloc mtrav
	
	keep s_halfhour ba_survey all_* diarypid s_dow propwt ba_p_class ba_survey ba_age_r income

	* loop over acts producing stats
	* use tabout method for results by day/year
	* produce stats per half hour
	foreach act of local all_acts {
		di "***********************************"
		di "* Act: `act' (`main`act'l')"

		di "* proportion (uses mean of 1/0) of acts that are `act' (`main`act'l')"
		qui: tabout s_halfhour ba_survey ///
			using "$rpath/MTUS_sampled_`main`act'l'_by_halfhour_per_year_mean_$version.txt", replace ///
			cells(mean all_`act' se) ///
			format(3) ///
			svy sum

		preserve
			* keep what we want _ speeds up tabout
			keep if all_`act' == 1
			di "* col % of `act' (`main`act'l') _ when is it done?"
			qui: tabout s_halfhour ba_survey  ///
				using "$rpath/MTUS_sampled_`main`act'l'_by_halfhour_per_year_col_pc_$version.txt", replace ///
				cells(col se) ///
				format(3) ///
				svy

			di "* Freq of `act' (`main`act'l') - when is it done by day?"
			local count = 0
			* by day of week
			local filemethod = "replace"
			levelsof s_dow, local(levels)
			*di "* levels: `levels'"
			local labels: value label s_dow
			*di "* labels: `labels'"
			local heading "h1(`main`act'l')"
			foreach l of local levels {
				if `count' > 0 {
					* we already made one pass so now append
					local filemethod = "append"
					*ocal heading = "h1(nil) h2(nil)"
				}
				local vlabel : label `labels' `l'
				di "* -> Level: `l' (`vlabel') of `main`act'l'"
				* use freq as can then summarise across all days
				qui: tabout s_halfhour ba_survey if s_dow == `l' ///
					using "$rpath/MTUS_sampled_`main`act'l'_by_halfhour_per_year_day_col_freq_$version.txt", `filemethod' ///
					h3("Day: `vlabel'") ///
					cells(freq) ///
					format(3) ///
					svy
				local count = `count' + 1
			}
		restore
	}
	log off do_halfhours
	log on main
}

if `do_demogs' {
	local nlog "$rpath/DEMAND_BA_MTUS_Energy_Practices_Over_Time_demogs_$version.smcl"
	di "* running do_demogs to `nlog'"
	log off main
	log using "`nlog'", replace  name(do_demogs)
	di "* do age/income analysis of defined acts"
	di "* this needs to be a count of people reporting acts (not counts of acts)"
	preserve
		* prep for collapse
		foreach v of varlist all_* {
			gen `v'_sum = `v'
			gen `v'_count = `v'
		}
		* collapse to halfhours and count the number of 10 minute smaple points at which the act is recorded
		* NB - we should expect 1974 to record a lower incidence of everything as it was a 1/2 hour diary
		* the others are 10 or 15 minutes
		collapse (sum) all_*_sum (count) all_*_count, by(diarypid ba_survey s_halfhour)
		* the max value will be 3 (3 * 10 minute smaple points in each half hour)

		* to nullify the 1974 1/2 hour effect (and the 1987 15 minute effect) we will add up the number of half-hours in which the act was recorded

		* was it recorded?
		foreach v of varlist all_*_sum {
			gen `v'c = 0
			replace `v'c = 1 if `v' > 0
		}

		* now add them up by collapsing again to person level leaving in ba_survey as a check
		* this should have a max of 48 (act was observed in every 1/2 hour)
		collapse (sum) all_*_sumc , by(diarypid ba_survey)

	  	* put some of the survey variables back in
		merge 1:1 diarypid using "$mtuspath/MTUS-adult-aggregate-UK-only-wf.dta", keepusing(ba_age_r income propwt ba_birth_cohort sex)

		
		* relabel
		lab val ba_age_r ba_age_r

		foreach p of local new_acts {
			di "* Act: `p' (`main`p'l')"
			di "* Basic test"
			tab all_`p'_sumc
			di "* Distribution by ba_survey, age & income"

			*bysort ba_survey: table all_`act' ba_age_r [iw=propwt], by(income)
			local count = 0
			* by day of week
			local filemethod = "replace"
			levelsof ba_survey, local(levels)
			*di "* levels: `levels'"
			local labels: value label ba_survey
			*di "* labels: `labels'"
			local heading "h1(`main`p'l')"
			foreach l of local levels {
				if `count' > 0 {
					* we already made one pass so now append
					local filemethod = "append"
					*ocal heading = "h1(nil) h2(nil)"
				}
				local vlabel : label `labels' `l'
				di "* -> Level: `l' of `main`p'l'"
				* use mean as indicator of prevalence in each age/income cell for each year
				* age
				qui: tabout ba_age_r income if ba_survey == `l' ///
					using "$rpath/MTUS_`main`p'l'_by_age_year_income_$version.txt", `filemethod' ///
					h3("Year: `vlabel'") ///
					cells(mean all_`p'_sumc se) ///
					format(3) ///
					sum svy
				* age cohorts
				qui: tabout ba_birth_cohort income if ba_survey == `l' ///
					using "$rpath/MTUS_`main`p'l'_by_birth_cohort_year_income_$version.txt", `filemethod' ///
					h3("Year: `vlabel'") ///
					cells(mean all_`p'_sumc se) ///
					format(3) ///
					sum svy

				local count = `count' + 1
			}
		}
	restore
	log off do_demogs
	log on main
}


if `do_half_hour_by_day_year' {
	local nlog "$rpath/DEMAND_BA_MTUS_Energy_Practices_Over_Time_half_hour_by_day_year_$version.smcl"
	di "* running do_half_hour_by_day_year to `nlog'"
	log off main
	log using "`nlog'", replace  name(do_half_hour_by_day_year)

	di "* create half_hour by day tables for each year"
	foreach v of varlist all_* {
		levelsof ba_survey, local(levels)
		foreach l of local levels {
			qui: tabout s_halfhour s_dow if ba_survey == `l' ///
				using "$rpath/MTUS_`v'_by_day_`l'_$version.txt", replace ///
				cells(mean `v') ///
				format(3) ///
				sum svy
		}
	}
	log off do_half_hour_by_day_year
	log on main
}

 
di "* --> Done!"

log close main
