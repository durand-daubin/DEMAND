*******************************************
* Script to use a number of datasets to examine:
* - distributions of laundry in 1975 & 2005
* - changing laundry practices

* uses:
* - MTUS World 6 time-use data (www.timeuse.org/mtus UK subset) - data already in long format (but episodes)
* - EFS 2005-6 to analyse uptake of washers/dryers
* - SPRG water practices survey

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

* LCFS/EFS
global efspath "$droot/Expenditure and Food Survey/processed"

* MTUS
global mtuspath "$droot/MTUS/World 6/processed"

* SPRG
global sprgpath "$where/Projects/ESRC-SPRG/WP4-Micro_water/data/sprg_survey/data/safe/v6"

* where to put results
global proot "$where/Projects/RCUK-DEMAND/Theme 1"
global rpath "$proot/results/MTUS"

* version
global version = "v1.0-all-locs"
* weights the final counts

* which subgroup of mtus are we interested in?
global mtusfilter "_all"

capture log close

log using "$rpath/DEMAND-BA-MTUS-W6-Laundry-Change-Over-Time-$version-adult.smcl", replace

* control what gets done
local do_halfhour_samples = 1

* make script run without waiting for user input
set more off

**********
* LCFS data for tumble dryer uptake levels to 2005
use "$efspath/EFS-2005-2006-extract-BA.dta", clear
lookfor tumble weight
tab year a167 [iw=weighta], row

* 2005 only
tab a167 c_nchild [iw=weighta] if year == 2005, col
tab a167 c_nearners [iw=weighta] if year == 2005, col
tab a167 c_empl [iw=weighta] if year == 2005, col

**********
* SPRG data on laundry practices
use "$sprgpath/8369-clt-050312-v6-wf-safe.dta", clear

desc q27*

rename q27_sum sum_q27

* 1 = yes, 2 = no
recode q27* (2=0)

* use mean to get % who said yes to each
su q27* [iw=weight_respondent2], sep(0)

* mean number of 'yes' responses
su sum_q27 [iw=weight_respondent2]

* distribution
tab sum_q27 [iw=weight_respondent2]

**********************************
* codes of interest
* 1974:	Main/Sec21 Laundry, ironing, clothing repair <- 50 Other essential domestic work (i.e. NOT preparing meals or routine housework)
* 	so laundry in 1974 may be over-estimated
* BUT 1975 is partly a 7 day diary - so more likely to detect laundry?

* 2005:	Main/Sec21 Laundry, ironing, clothing repair <- Pact=7 (washing clothes)

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
svy: mean main18 main20 main21 main22, over(survey sex)

* keep whatever sample we define above
keep $mtusfilter

* number of diary days by hh type
* svy: tab hhtype survey, col count

* number of diary days by number of days covered
* 1974 = 7 day dairy
svy: tab id survey, col count


* keep only the vars we want to keep memory required low
keep sex age main7 main21 hhtype empstat emp unemp student retired propwt survey day month year ///
	hhldsize famstat nchild *pid ba*

* number of diary-days
svy: tab survey, obs


preserve
*************************
* sampled data
* this requires the 10 minute sampling process implemented in 
* https://github.com/dataknut/MTUS/blob/master/process-MTUS-W6-convert-to-X-min-samples-v1.0-adult.do
* to have been run over the MTUS first with X set to 10

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
	
	* define laundry
	gen laundry_p = 0
	lab var laundry_p "Main act = laundry (21)"
	replace laundry_p = 1 if pact == 21
	
	gen laundry_s = 0
	lab var laundry_s "Secondary act = laundry (21)"
	replace laundry_s = 1 if sact == 21
	
	gen laundry_all = 0
	replace laundry_all = 1 if laundry_p == 1 | laundry_s == 1
	
	lab var laundry_all "Any act = laundry (21)"
	
	* done at home or elsewhere?
	tab survey eloc if laundry_all == 1 [iw=propwt],  mi
	
	* a lot of 1974 done 'elsewhere'?
	
	* this is the number of 10 minute samples by survey & day of the week
	tab survey day [iw=propwt]
	
	* check % of sampled X minute points which are laundry
	* NB reporting frame longer in 1974 (30 mins) so may be higher frequency (e.g. interruption in 10-20 mins coded)
	di "* main"
	tab survey laundry_p [iw=propwt]
	di "* secondary"
	tab survey laundry_s [iw=propwt]
	di "* all"
	tab survey laundry_all [iw=propwt]
	
	* which years could we use?
	tab month survey [iw=propwt]
	
	* 1974 = Feb, Mar & Aug,Sept -> has winter & summer
	* 1984 = winter only
	* 1987 = early summer only
	* 1995 = May
	* 2000 = all year
	* 2005 = each season (March, June, Sept, Nov)
	
	* keep 1974 & 2005 only
	keep if survey == 1974 | survey == 2005
	
	* check for duplicates
	duplicates report diarypid ba_starttime
	* none
	
	duplicates report diarypid s_halfhour
	* three -> because each s_halfhour value can stand for x:10 x:20 x:30
	* collapse to add up the sampled laundry by half hour

	* use the byvars we're interested in (or could re-merge with aggregated file)
	collapse (sum) laundry_* (mean) propwt, by(diarypid pid survey day month year s_halfhour ///
		ba_birth_cohort ba_age_r ba_nchild sex emp empstat nchild)
	* because the different surveys have different reporting periods we need to just count at least 1 laundry in the half hour
	lab val emp EMP
	lab val empstat EMPSTAT
	local acts "p s all"
	foreach a of local acts {
		gen any_laundry_`a' = 0
		replace any_laundry_`a' = 1 if laundry_`a' > 0
	}
	* the number of half hour data points by survey & day
	tab survey day [iw=propwt]
	
	svyset [iw=propwt]
	* the distribution of laundry by survey and location
	di "* primary"
	svy: tab survey if any_laundry_p == 1, col ci
	
	di "* secondary"
	svy: tab survey if any_laundry_s == 1, col ci
	
	di "* all"
	svy: tab survey if any_laundry_all == 1, col ci
	
	* by gender for all laundry reported
	svy: tab survey sex if any_laundry_all == 1, ci row
	
	* gender & age
	svy: tab ba_age_r sex if any_laundry_all == 1 & survey == 1974, ci row
	svy: tab ba_age_r sex if any_laundry_all == 1 & survey == 2005, ci row
	
	* Separate days
	table survey day [iw=propwt], by(any_laundry_all)

	* days by gender
	table survey day sex [iw=propwt], by(any_laundry_all)
	
	* laundry by employment status if female
	table survey day empstat if sex == 2 & any_laundry_all == 1 [iw=propwt]
		
	* set time variable so can select by time & also tables should look nicer
	xtset diarypid s_halfhour, delta(30 mins) format(%tcHH:MM)

	di "* Tables for all days"
	* All years, all days
	table s_halfhour survey any_laundry_all [iw=propwt]
	
	* days by half hour
	table s_halfhour survey day [iw=propwt], by(any_laundry_all)	

	* seasons
	recode month (3 4 5 = 1 "Spring") (6 7 8 = 2 "Summer") (9 10 11 = 3 "Autumn") (12 1 2 = 4 "Winter"), gen(season)
	* check
	* tab month season
	table s_halfhour survey season [iw=propwt], by(any_laundry_all)
	
	* by half hour & employment status for women
	table s_halfhour empstat survey if sex == 2 [iw=propwt], by(any_laundry_all)
	
	*repeat by day for 2005
	table s_halfhour empstat day if survey == 2005 & sex == 2 [iw=propwt], by(any_laundry_all)
	
	* analysis by laundry type
	* sunday morning

	* only code for laundry within year
	gen laundry_timing = 5 if any_laundry_all == 1 // other
	replace laundry_timing = 1 if any_laundry_all == 1 & day == 1 & tin(08:00, 12:00) // sunday morning
	replace laundry_timing = 2 if any_laundry_all == 1 & day > 1 & day < 6 & tin(09:00, 12:00) // weekday morning
	replace laundry_timing = 3 if any_laundry_all == 1 & day > 1 & day < 6 & tin(17:00, 20:00) // weekday evening peak
	replace laundry_timing = 4 if any_laundry_all == 1 & tin(00:00, 01:30) // night-time
	replace laundry_timing = 4 if any_laundry_all == 1 & tin(22:30, 23:30) // night-time

	tab laundry_timing, gen(laundry_timing_)

	* check for missing	
	table s_halfhour laundry_timing any_laundry_all, mi
	
	lab def laundry_timing 1 "Sunday morning 09:00-12:00" 2 "Weekday morning 09:00-12:00" 3 "Weekday evening peak 17:00-20:00" 4 "Night-time 22:30-01:30" 5 "Other"
	lab val laundry_timing laundry_timing
	tab laundry_timing survey [iw=propwt], col
	svy:tab laundry_timing survey, col ci
	table laundry_timing ba_age_r survey [iw=propwt], col
	table laundry_timing empstat survey [iw=propwt], col
	table laundry_timing ba_nchild survey [iw=propwt], col
	
	* collapse to single person record
	* remember 1974/5 = 1 week diary
	collapse (sum) laundry_timing_* any_laundry_all (mean) propwt, by(pid survey ///
		ba_birth_cohort ba_age_r ba_nchild sex emp empstat nchild)
	recode any_laundry_all (1/max=1)
	recode laundry_timing_1 (1/max=1)
	recode laundry_timing_2 (1/max=1)
	recode laundry_timing_3 (1/max=1)
	recode laundry_timing_4 (1/max=1)
	recode laundry_timing_5 (1/max=1)
	
	*how many people are in multiple types?
	egen nlaundry_types = rowtotal( laundry_timing_*)
	svy: tab nlaundry_types survey, col
	
	* what % of respondents in each?
	svy: mean laundry_timing_*, over(survey)
	* % of launderers
	svy: mean laundry_timing_* if any_laundry_all == 1, over(survey)
	
	foreach v of numlist 1/4 {
		logit laundry_timing_`v' sex ib4.empstat i.ba_age_r i.ba_nchild if survey == 1974
		est store laundry_timing_`v'_1974
		logit laundry_timing_`v' sex ib4.empstat i.ba_age_r i.ba_nchild if survey == 2005
		est store laundry_timing_`v'_2005
	}
	estout laundry_*_2005 using "$rpath/laundry_type_1974_regressions.txt", cells("b ci_l ci_u se _star") stats(N r2_p chi2 p ll) replace
	estout laundry_*_2005 using "$rpath/laundry_type_2005_regressions.txt", cells("b ci_l ci_u se _star") stats(N r2_p chi2 p ll) replace
		
} 
restore

* we're back to the main survey aggregate file here.
* drop diary duplicates & do some basic stats

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

* Proportion of women in work
tab survey empstat [iw=propwt] if ba_working_age == 1 & sex == 2, row

di "Done!"

log close
