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

* SPRG
global sprgpath "$where/Projects/ESRC-SPRG/WP4-Micro_water/data/sprg_survey/data/safe/v6"

* where to put results
global proot "$where/Projects/RCUK-DEMAND/Theme 1"
global rpath "$proot/results/MTUS"

* version
global version = "v1.0"
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
local main57l "57: Listen to music or other audio content"local main58l "58: Listen to radio"local main59l "59: Watch TV, video, DVD, streamed film"local main60l "60: Computer games"local main61l "61: E-mail, surf internet, computing"
local main62l "62: No activity, imputed or recorded transport"local main63l "63: Travel to/from work"local main64l "64: Education travel"local main65l "65: Voluntary/civic/religious travel"local main66l "66: Child/adult care travel"local main67l "67: Shop, person/hhld care travel"local main68l "68: Other travel"

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
* 1974 = 7 day dairy
svy: tab id survey, col count

* keep only the vars we want to keep memory required low
keep sex age `main_acts' hhtype empstat emp unemp student retired propwt survey day month year ///
	hhldsize famstat nchild *pid ba*

* number of diary-days
svy: tab survey, obs

*************************
* sampled data
* this requires the 10 minute sampling process implemented in 
* https://github.com/dataknut/MTUS/blob/master/process-MTUS-W6-convert-to-X-min-samples-v1.0-adult.do
* to have been run over the MTUS first with X set to 10

preserve

if `do_halfhour_samples' {
	* merge in the sampled data
	* do analysis by collapsing 10 minute sampled data to half hours
	merge 1:m diarypid using "$mtuspath/MTUS-adult-episode-UK-only-wf-10min-samples-long-v1.0.dta", ///
		gen(m_aggvars)
		
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
	
	* this is the number of 10 minute samples by survey & day of the week
	tab survey day [iw=propwt]

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
	
		* keep 1974 & 2005 only
		keep if survey == 1974 | survey == 2005
	}
	* collapse to add up the sampled laundry by half hour
	* use the byvars we're interested in (or could re-merge with aggregated file)
	collapse (sum) pri_* sec_* all_* (mean) propwt, by(diarypid pid survey day month year s_halfhour ///
		ba_birth_cohort ba_age_r ba_nchild sex emp empstat nchild)
	* because the different surveys have different reporting periods we need to just count at least 1 laundry in the half hour
	lab val emp EMP
	lab val empstat EMPSTAT
	local prim "pri sec all"
	* count any occurence of the act
	foreach a of local prim {
		foreach act of global acts {
			gen `a'_any_`act' = 0
			replace `a'_any_`act' = 1 if `a'_`act' > 0
			lab var `a'_any_`act' "`main`act'l'"
		}
	}
	
	* the number of half hour data points by survey & day
	tab survey day [iw=propwt]
	
	* set survey
	svyset [iw=propwt]
	
	* seasons
	recode month (3 4 5 = 1 "Spring") (6 7 8 = 2 "Summer") (9 10 11 = 3 "Autumn") (12 1 2 = 4 "Winter"), gen(season)
	* check
	* tab month season

	* loop over acts producing stats
	foreach act of global acts {
		di "* Distribution by survey (includes all acts)"
		di "* primary `act' (`main`act'l')"
		svy: tab survey pri_any_`act', row ci nomarg // leave out marginal totals
	
		di "* secondary `act' (`main`act'l')"
		svy: tab survey sec_any_`act', row ci nomarg
	
		di "* all `act' (`main`act'l')"
		svy: tab survey all_any_`act', row ci nomarg
		tabout s_halfhour survey using "$rpath/all_any_`act'_mean_by_time_year.txt", ///
			c(mean all_any_`act' se) svy sum sebnone format(4) replace

		tabout s_halfhour season using "$rpath/all_any_`act'_mean_1974_by_time_season.txt" if survey == 1974, ///
			c(mean all_any_`act' se) svy sum sebnone format(4) replace
		
		tabout s_halfhour season using "$rpath/all_any_`act'_mean_2005_by_time_season.txt" if survey == 2005, ///
			c(mean all_any_`act' se) svy sum sebnone format(4) replace

		di "** Distributions for just reported `act' (`main`act'l')"
		di "* all days by gender - `act' (`main`act'l')"
		svy: tab sex survey if all_any_`act' == 1, col se nomarg
		di "* all days by age range - `act' (`main`act'l')"
		svy: tab ba_age_r survey if all_any_`act' == 1, col se nomarg
		di "* all days by time - `act' (`main`act'l')"
		svy: tab s_halfhour survey if all_any_`act' == 1, col se nomarg
		* all days by time & survey (sum)
		* how to get tabout to produce weighted sum/count?
		* won't use iweight
		* tabout s_halfhour survey using "$rpath/all_any_`act'_sum_by_time_year.txt" ///
		*	if all_any_`act' == 1 [iw=propwt], ///
		*	c(sum all_any_`act') sum format(4) replace
	}
	
	* set time variable so can select by time
	xtset diarypid s_halfhour, delta(30 mins)
	
	* do timings analysis e.g. time of day laundry types		
} 
restore

* we're back to the main survey aggregate file here.
* drop diary duplicates to get file of individuals & do some basic stats

duplicates drop pid, force

* create working age variable
gen ba_working_age = 0
replace ba_working_age = 1 if age > 18 // OK, it should be 16 but...
* women
replace ba_working_age = 0 if age > 60 & sex == 2
* men
replace ba_working_age = 0 if age > 65 & sex == 1
* check
table ba_age_r ba_working_age sex

* Propoprtion of women in work
svy: tab empstat if ba_working_age == 1 & sex == 2, row ci


log close
