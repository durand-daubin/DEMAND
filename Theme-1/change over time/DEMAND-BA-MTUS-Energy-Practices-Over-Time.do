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
local do_halfhour_samples = 1

* make script run without waiting for user input
set more off

**********************************
* Codes of interest
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

* 57 58 59 60 61 62 63 64 65 66 67 68
global acts "18 20 21"

local main_acts ""
local sec_acts ""

foreach a of global acts {
	local main_acts = "`main_acts' main`a'"
	local sec_acts = "`sec_acts' sec`a'"
}
* start with processing the aggregate (survey) data
use "$mtuspath/MTUS-adult-aggregate-UK-only-wf.dta", clear

* drop all bad cases
keep if badcase == 0

* set as survey data for descriptives
svyset [iw=propwt]

* keep only 1974 & 2005 for simplicity
* keep if survey == 1974 | survey == 2005
* no, let's keep them all for birth cohort analysis!

* this is minutes per day not episodes
* check 18 (Cooking) & 20 (Cleaning) & 22 (maintain home/vehicle) against laundry
* seems to under-report laundry in 1974, esp for women?
tabstat `main_acts', by(survey)

* keep whatever sample we define above
keep $mtusfilter

* number of diary days by hh type
* svy: tab hhtype survey, col count

* number of diary days by number of days covered
svy: tab id survey, col count
* 1974 - 1987 = 7 day diaries but NB 1983/4 diary day may need to be fixed

* number of diary-days
svy: tab survey, obs

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

	* this is the number of 10 minute samples by survey & day of the week
	tab survey s_dow [iw=propwt]

	* loop over the acts of interest
	foreach act of global acts {
		di "Processing: `act' = `main`act'l'"
		gen pri_`act' = 0
		lab var pri_`act' "Main act: `main`act'l'"
		replace pri_`act' = 1 if pact == `act'
	
		gen sec_`act' = 0
		lab var sec_`act' "Secondary act: `main`act'l'"
		replace sec_`act' = 1 if pact == `act'
	
		gen all_`act' = 0
		replace all_`act' = 1 if pri_`act' == 1 | sec_`act' == 1
		lab var all_`act' "All: `main`act'l'"
	
		* check % samples which are act
		* NB reporting frame longer in 1974 (30 mins) so may be higher frequency (e.g. interruption in 10-20 mins coded)
		di "* main"
		tab survey  pri_`act' [iw=propwt]
		di "* secondary"
		tab survey  sec_`act' [iw=propwt]
		di "* all"
		tab survey  all_`act' [iw=propwt]	
	}
	
	* keep just the variables we need to save memory
	* others: month cday diary sex age year season eloc mtrav
	keep s_halfhour survey all_* diarypid s_dow propwt

	* set survey
	svyset [iw=propwt]

	* loop over acts producing stats
	* use tabout method for results by day/year
	* produce stats per half hour
	foreach act of global acts {
		di "* Distribution by survey"
		di "* primary `act' (`main`act'l')"
		
		* proportion of acts that are activity 
		qui: tabout s_halfhour survey ///
			using "$rpath/MTUS_sampled_mean_`act'_by_halfhour_per_year_$version.txt", replace ///
			cells(mean all_`act' se) ///
			format(3) ///
			svy sum
		
		preserve
			* keep what we want - speeds up tabout
			keep if all_`act' == 1

			* col % of act - when is it done?
			qui: tabout s_halfhour survey  ///
				using "$rpath/MTUS_sampled_col_pc_`act'__by_halfhour_per_year_$version.txt", replace ///
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
			foreach l of local levels {	
				if `count' > 0 {
					* we already made one pass so now append
					local filemethod = "append"	
					*local heading = "h1(nil) h2(nil)"
				}
				local vlabel : label `labels' `l'
				di "*-> Level: `l' (`vlabel')"
				* use freq as can then summarise across all days
				qui: tabout s_halfhour survey if s_dow == `l' ///
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
