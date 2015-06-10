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

global where "/Users/ben/Documents/Work"
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
* changed to tabout method for stats and not aggregating by half hour first (let tabout do th ejob of collapse)
* global version = "v1.0"
* weights the final counts
* which subgroup of mtus are we interested in?
global mtusfilter "_all"


capture log close

log using "$rpath/DEMAND-BA-MTUS-Energy-Practices-Over-Time-$version.smcl", replace

* control what gets done
local do_aggregated = 0
local do_halfhour_samples = 1
local do_day = 0

* make script run without waiting for user input
set more off

**********************************
* Codes of interest
local main4l "4: Wash/dress/care for self"
local main18l "18: Food preparation, cooking"
local main20l "20: Cleaning"
local main21l "21: Laundry, ironing, clothing repair"
local main57l "57: Listen to music or other audio content"
local main58l "58: Listen to radio"
local main59l "59: Watch TV, video, DVD, streamed film"
local main60l "60: Computer games"
local main61l "61: E-mail, surf internet, computing"
local main62l "62: No activity, imputed or recorded transport"
local main63l "63: Travel to/from work"
local main64l "64: Education travel"
local main65l "65: Voluntary/civic/religious travel"
local main66l "66: Child/adult care travel"
local main67l "67: Shop, person/hhld care travel"
local main68l "68: Other travel"
local main101l "101: Car travel"

* original activities (from MTUS 69 codes)
* 57 58 59 60 61 62 63 64 65 66 67 68
local o_acts "4 18 20 21"

if `do_aggregated' {
	* use the aggregated file to test the mins per day for these acts for each survey as context
	use "$mtuspath/MTUS-adult-aggregate-UK-only-wf.dta", clear

	svyset [iw=propwt]

	* create a bespoke survey which mereges 1983 & 1987
	* has the advantage of providing all seasons for '1985'
	recode survey (1974=1974 "1974") (1983/1987=1985 "1985") (1995 = 1995 "1995") (2000=2000 "2000") (2005=2005 "2005"), gen(ba_survey)

	foreach act of local o_acts {
		di "* Mean minutes per day - `main`act'l'"
		tabout ba_survey ///
		using "$rpath/MTUS_aggregate_uk_`act'_mean_mins_by_ba_survey_$version.txt", replace ///
		h3("Survey: `vlabel'") ///
		cells(mean main`act' se) /// can't do secondary act as not in this aggregate file
		format(3) ///
		sum svy
	}
}
* these are the ones we invented to catch particular acts/practices
local new_acts "101" // car travel

local all_acts = "`o_acts' `new_acts'"

* run the constructor to all activities to the looping list
foreach a of local all_acts {
	local main_acts = "`main_acts' main`a'"
	local sec_acts = "`sec_acts' sec`a'"
}

*************************
* sampled data
* this requires the 10 minute sampling process implemented in
* https://github.com/dataknut/MTUS/blob/master/process-MTUS-W6-convert-to-X-min-samples-v1.0-adult.do
* to have been run over the MTUS first with X set to 10

if `do_halfhour_samples' {
	* merge in the sampled data
	* do analysis by collapsing 10 minute sampled data to half hours
	use "$mtuspath/MTUS-adult-episode-UK-only-wf-10min-samples-long-v1.0.dta", clear

	* merge in key variables from survey data
	* hhtype empstat emp unemp student retired propwt survey day month year hhldsize famstat nchild
	merge m:1 diarypid using "$mtuspath/MTUS-adult-aggregate-UK-only-wf.dta", keepusing(sex age year propwt) ///
		gen(m_aggvars)

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
	recode month (3 4 5 = 1 "Spring") (6 7 8 = 2 "Summer") (9 10 11 = 3 "Autumn") (12 1 2 = 4 "Winter"), gen(season)
	* check
	tab month season

	* create new pact/sact codes which will be picked up later in the loops
	* use fake numbers otherwise it fails
	* car travel
	replace pact = 101 if mtrav == 1
	replace sact = 101 if mtrav == 1

	* create a bespoke survey which mereges 1983 & 1987 again
	recode survey (1974=1974 "1974") (1983/1987=1985 "1985") (1995 = 1995 "1995") (2000=2000 "2000") (2005=2005 "2005"), gen(ba_survey)

	* this is the number of 10 minute samples by survey & day of the week
	tab survey s_dow [iw=propwt]

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

		* check % samples which are act
		* NB reporting frame longer in 1974 (30 mins) so may be higher frequency (e.g. interruption in 10-20 mins coded)
		di "* main"
		tab ba_survey  pri_`act' [iw=propwt], row
		di "* secondary"
		tab ba_survey  sec_`act' [iw=propwt], row
		di "* all"
		tab ba_survey  all_`act' [iw=propwt], row
	}

	* keep just the variables we need to save memory
	* others: month cday diary sex age year season eloc mtrav
	keep s_halfhour survey all_* diarypid s_dow propwt mtrav eloc pact sact ba_survey

	* set survey
	svyset [iw=propwt]

	if `do_day' {
		* produce tables of all primary acts, location & mode of travel per halfhour per survey by weekdays vs weekend as context
		gen weekend = 0
		replace weekend = 1 if s_dow == 1 | s_dow == 6
		gen weekday = 1 if weekend == 0

		* use looped tabout method but alter to just use levels (= years) not label values as well
		local filemethod = "replace"
		levelsof ba_survey, local(levels)
		di "* levels: `levels'"

		local vars "pact lact mtrav"
		foreach v of local vars {
			local count = 0
			* by day of week

			foreach l of local levels {
				if `count' > 0 {
					* we already made one pass so now append
					local filemethod = "append"
					*ocal heading = "h1(nil) h2(nil)"
				}
				local vlabel `l'
				di "*-> Level: `l' (`vlabel')"
				* use row to give % in each halfhour per year
				qui: tabout s_halfhour `v' if ba_survey == `l' ///
					using "$rpath/MTUS_sampled_`v'_by_halfhour_per_year_col_$version.txt", `filemethod' ///
					h3("Survey: `vlabel'") ///
					cells(row) ///
					format(3) ///
					svy
				local count = `count' + 1
			}
		}
	}

	* loop over acts producing stats
	* use tabout method for results by day/year
	* produce stats per half hour
	foreach act of global acts {
		di "* Distribution by ba_survey"
		di "* primary `act' (`main`act'l')"

		* proportion of acts that are activity
		qui: tabout s_halfhour ba_survey ///
			using "$rpath/MTUS_sampled_mean_`act'_by_halfhour_per_year_$version.txt", replace ///
			cells(mean all_`act' se) ///
			format(3) ///
			svy sum

		preserve
			* keep what we want - speeds up tabout
			keep if all_`act' == 1

			* col % of act - when is it done?
			qui: tabout s_halfhour ba_survey  ///
				using "$rpath/MTUS_sampled_col_pc_`act'_by_halfhour_per_year_$version.txt", replace ///
				cells(col se) ///
				format(3) ///
				svy

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
				di "*-> Level: `l' (`vlabel')"
				* use freq as can then summarise across all days
				qui: tabout s_halfhour ba_survey if s_dow == `l' ///
					using "$rpath/MTUS_sampled_`act'_by_halfhour_per_year_day_col_freq_$version.txt", `filemethod' ///
					h3("Day: `vlabel'") ///
					cells(freq) ///
					format(3) ///
					svy
				local count = `count' + 1
			}
		restore
		* get rid of the variables we've used to save memory
		drop all_`act'
	}

}


log close
