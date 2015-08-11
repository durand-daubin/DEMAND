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

clear all

* change these to run this script on different PC
* use globals so can re-run parts of the script

global where "~/Documents/Work"
global droot "$where/Data/Social Science Datatsets"

* MTUS
global mtuspath "$droot/MTUS/World 6/processed"

* SPRG
global sprgpath "$where/Projects/ESRC-SPRG/WP4-Micro_water/data/sprg_survey/data/safe/v6"

* where to put results
global proot "$where/Projects/RCUK-DEMAND/Theme 1"
global rpath "$proot/results/MTUS"

* version
global version = "v2.0"

* global version = "v1.0"
* weights the final counts

capture log close

log using "$rpath/DEMAND-BA-MTUS-Energy-Practices-Over-Time-$version.smcl", replace

* which subgroup of mtus are we interested in?
global mtusfilter "_all"

* control what gets done
local do_aggregated = 0 // table of minutes per main activity
local do_day = 0 // big tables of all (merged) acts, eloc and mtrav by time of day
local do_timeofday = 0 // tabout tables for each time use act/practice
local do_halfhour_all_acts = 0 // create tables for all years for all acts

* original activities (from MTUS 69 codes)
* 4 18 20 21 57 58 59 60 61 62 63 64 65 66 67 68
* add any of them in to refresh the results
local old_acts "21"

* these are the ones we will invent to catch particular acts/practices
* 100 101 102 103 104 105 106
* add any of them in to refresh the results
local new_acts "104" // see above

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
local main103l "103 TV, video, DVD, computer games at home"
local main104l "104 Computer,Internet at home"
local main105l "105 Cooking late supper at home"
local main106l "106 Cooking Sunday lunch at home"


if `do_aggregated' {
	* use the aggregated file to test the mins per day for these acts for each survey as context
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

* merge in the sampled data
* do analysis by collapsing 10 minute sampled data to half hours
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

* simple categorisation for year on year comparison as MTUS has 69 or 41 codes which are hard to visualise
* this is a DEMAND (energy) oriented classification
* do this BEFORE modifying any of the pact/sact codes!
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
	(69 = 11 "Not recorded") (nonmissing = 12 "Not coded"), gen(ba_pact)

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
		(69 = 11 "Not recorded") (nonmissing = 12 "Not coded"), gen(ba_sact)

*test
tab pact ba_pact, mi

* set survey
svyset [iw=propwt]

if `do_day' {
	* produce tables of merged primary acts, location & mode of travel per halfhour per survey
	local vars "ba_pact ba_sact eloc mtrav"

	preserve
		keep s_halfhour ba_survey `vars' propwt
		* use looped tabout method but alter to just use levels (= years) not label values as well

		* do not use full pact or sact as takes a LONG time and is impossible to visualise
		levelsof ba_survey, local(levels)
		foreach l of local levels {
			di "********************"
			di "* Doing tables for `l'"
			foreach v of local vars {
				di "* -> Doing tables of `v' for `l'"
				* using tab is a lot quicker than the survey option on tabout
				* do not set to 'at home' only as we want a sense of what is changing overall
				tab s_halfhour `v' [iw=propwt] if ba_survey == `l', row nof
			}
		}
	restore
}

* do any tests on the raw pact/sact values here BEFORE we start messing around with them

* OK, now:
* create new pact/sact codes which will be picked up later in the loops
* use fake numbers otherwise it fails

* 100 eating at home
replace pact = 100 if (pact == 5 | pact == 6) & eloc == 1
replace sact = 100 if (sact == 5 | sact == 6) & eloc == 1

* 101: Car travel
replace pact = 101 if mtrav == 1
replace sact = 101 if mtrav == 1

* 102: Car travel ending at home
* needs ts to be set so we can use lag
tsset diarypid s_starttime, delta(10 mins)
* now = at home, last was car travel
replace pact = 102 if L.mtrav == 1 & eloc == 1
replace sact = 102 if L.mtrav == 1 & eloc == 1

* 103: TV/video/DVD/computer games at home
replace pact = 103 if (pact == 59 | pact == 60) & eloc == 1
replace sact = 103 if (sact == 59 | sact == 60) & eloc == 1

* 104: Computer/Internet at home
replace pact = 104 if pact == 61 & eloc == 1
replace pact = 104 if sact == 61 & eloc == 1

* 105: Cooking late supper at home
replace pact = 105 if pact == 18 & eloc == 1 & ba_hourt > 21 & ba_hourt <= 23
replace sact = 105 if sact == 18 & eloc == 1 & ba_hourt > 21 & ba_hourt <= 23

* 106: Cooking lunch at home
replace pact = 106 if pact == 18 & eloc == 1 & ba_hourt > 11 & ba_hourt <= 14 & s_dow == 0
replace sact = 106 if sact == 18 & eloc == 1 & ba_hourt > 11 & ba_hourt <= 14 & s_dow == 0

* loop over the acts of interest to construct 'all'
foreach act of local all_acts {
	di "Processing: `act' = `main`act'l'"
	gen pri_`act' = 0
	lab var pri_`act' "Main act: `main`act'l'"
	replace pri_`act' = 1 if pact == `act'

	gen sec_`act' = 0
	lab var sec_`act' "Secondary act: `main`act'l'"
	replace sec_`act' = 1 if sact == `act'

	gen all_`act' = 0
	replace all_`act' = 1 if pri_`act' == 1 | sec_`act' == 1
	lab var all_`act' "All: `main`act'l'"
	tab all_`act' s_dow
}

* drop primary * secondary vars as we don't use them and they take up a lot of space
drop pri_*
drop sec_*

if `do_timeofday' {
	* keep just the variables we need to save memory
	* others: month cday diary sex age year season eloc mtrav
	keep s_halfhour ba_survey all_* diarypid s_dow propwt ba_pact ba_survey ba_age_r income

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
			* keep what we want - speeds up tabout
			keep if all_`act' == 1
			di "* col % of `act' (`main`act'l') - when is it done?"
			qui: tabout s_halfhour ba_survey  ///
				using "$rpath/MTUS_sampled_`main`act'l'_by_halfhour_per_year_col_pc_$version.txt", replace ///
				cells(col se) ///
				format(3) ///
				svy

			di "* freq of `act' (`main`act'l') - when is it done by day?"
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
				di "*-> Level: `l' (`vlabel') of `main`act'l'"
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
}

* do age/income analysis of defined acts
* this needs to be a count of people reporting acts (not counts of acts)
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
	merge 1:1 diarypid using "$mtuspath/MTUS-adult-aggregate-UK-only-wf.dta", keepusing(ba_age_r income propwt ba_birth_cohort)
	* relabel
	lab val ba_age_r ba_age_r

	foreach p of local new_acts {
		di "* Act: `p' (`main`p'l')"
		di "* Basic test"
		tab all_`p'
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
			di "*-> Level: `l' of `main`p'l'"
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

* create half-hour by day tables for each year
if `do_halfhour_all_acts' {
	foreach v of varlist all_* {
		levelsof ba_survey, local(levels)
		foreach l of local levels {
			qui: tabout s_halfhour s_dow if ba_survey == `l' ///
				using "$rpath/MTUS_`v'_by_day_`l'_$version.txt", replace ///
				cells(mean all_`p') ///
				format(3) ///
				sum svy
		}
	}
}

* laundry checks for age & employment etc
table ba_survey all_21 sex [iw=propwt]
table s_halfhour s_dow all_21 if empstat == 1 & ba_survey == 2005 & sex == 2 [iw=propwt]
 
di "*-->Done!"

log close
