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
global version = "v1.2-at-home"
* assumes "other location" = someone else's house (as it is not laundrette and "other person's house" is not defined for 1974 & 2005

* global version = "v1.1-at-home"
* excludes any laundry "not at home or someone else's home" (eloc = 1 or 2)

* global version = "v1.0-all-locs"
* weights the final counts

* which subgroup of mtus are we interested in?
global mtusfilter "_all"

capture log close

log using "$rpath/DEMAND-BA-MTUS-W6-Laundry-Change-Over-Time-$version-adult.smcl", replace

* control what gets done
local do_halfhour_samples = 1

* make script run without waiting for user input
set more off

**********************************
**********************************
* LCFS data for tumble dryer uptake levels to 2005
use "$efspath/EFS-2005-2006-extract-BA.dta", clear
lookfor tumble weight
tab year a167 [iw=weighta], row

* 2005 only
tab a167 c_nchild [iw=weighta] if year == 2005, col
tab a167 c_nearners [iw=weighta] if year == 2005, col
tab a167 c_empl [iw=weighta] if year == 2005, col

**********************************
**********************************
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
**********************************
* MTUS
* codes of interest
* 1974:	Main/Sec21 Laundry, ironing, clothing repair <- 50 Other essential domestic work (i.e. NOT preparing meals or routine housework)
* 	so laundry in 1974 may be over-estimated
* BUT 1975 is partly a 7 day diary - so more likely to detect laundry?

* 2005:	Main/Sec21 Laundry, ironing, clothing repair <- Pact=7 (washing clothes)

**********
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

* change order of income variable
recode income (-9=4)
lab def INCOME 4 "Not known", add


* keep only the vars we want to keep memory required low
keep sex age main7 main21 hhtype empstat income emp unemp student retired propwt survey day month year ///
	hhldsize famstat nchild hhldsize *pid ba*

* number of diary-days
svy: tab survey, obs

**********
* use raw data to assess raw episodes
preserve

	use "$mtuspath/MTUS-adult-episode-UK-only-wf.dta", clear

restore
**********
* switch to sampled data
* this requires the 10 minute sampling process implemented in 
* https://github.com/dataknut/MTUS/blob/master/process-MTUS-W6-convert-to-X-min-samples-v1.0-adult.do
* to have been run over the MTUS first with X set to 10

if `do_halfhour_samples' {
	* merge in the sampled data
	* do analysis by collapsing 10 minute sampled data to half hours
	merge 1:m diarypid using "$mtuspath/MTUS-adult-episode-UK-only-wf-10min-samples-long-v1.0.dta", ///
		gen(m_aggvars)
	
	* which years could we use?
	* NB - we need full years or at least quarters/all seasons for laundry as it may well be seasonally variant.
	tab month survey [iw=propwt]
	
	* 1974 = Feb, Mar & Aug,Sept -> has winter & summer
	* 1984 = winter only
	* 1987 = early summer only
	* 1995 = May
	* 2000 = all year
	* 2005 = each season (March, June, Sept, Nov)
	
	* keep 1974 & 2005 only as problems with coverage in all others
	* could pool 1984 & 1987 but 1995 useless (May!)
	keep if survey == 1974 | survey == 2005
	
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
 
 	* distribution of locations
	svy: tab eloc survey,  count col
	
	* laundry done at home or elsewhere?
	svy: tab eloc survey,  count col
	
	* a lot of 1974 done at 'other locations'?

	* can we work out where?
	bysort survey: tab sact pact if eloc == 9 & laundry_all == 1
	* a bit - for the most part there is no recorded secondary actitivy if main = laundry
	bysort survey: tab mtrav if eloc == 9 & laundry_all == 1
	* that doesn't help - all not travelling
	* NB "someone else's home is not set for 1974/2005" - maybe these are the 'other' locations?
	
	gen laundry_rh = 0
	replace laundry_rh = 1 if laundry_all == 1 & (eloc == 1 | eloc == 2) // definitely at home
	
	gen laundry_sh = 0
	replace laundry_sh = 1 if laundry_all == 1 & (eloc == 5) // definitely at shops/services
	
	gen laundry_oth = 0
	replace laundry_oth = 1 if laundry_all == 1 & (eloc == 9) // definitely at other location

	* set defined locations
	gen laundry_h = 0
	replace laundry_h = 1 if laundry_all == 1 & (eloc == 1 | eloc == 2 | eloc == 9) // specifically at home or someone else's home (the latter not set in 1974/2005)
	* we'll also assume that visiting/receiving friends whilst laundry is at someone's home - doesn't really matter whose for this paper
	replace laundry_h = 1 if laundry_all == 1 & (pact == 48 | sact == 48)
	lab var laundry_h "Any act = laundry (21) at someone's home"	

	gen laundry_nh = 0
	replace laundry_nh = 1 if laundry_all == 1 & (eloc != 1 & eloc != 2 & eloc != 9) & (pact != 48 & sact != 48)
	lab var laundry_nh "Any act = laundry (21) not at home"
	
	* this is the number of 10 minute samples by survey & day of the week
	tab survey day [iw=propwt]
	
	di "* check % of sampled X minute points which are laundry"
	di "* NB reporting frame longer in 1974 (30 mins) so may be higher frequency (e.g. interruption in 10-20 mins coded)"
	di "* all"
	tab survey laundry_all [iw=propwt], row
	di "* home ($version)"
	tab survey laundry_h [iw=propwt], row
	di "* not at home ($version)"
	tab survey laundry_nh [iw=propwt], row
			
	*********************
	* collapse to add up the sampled laundry by half hour
	* use the byvars we're interested in (or could re-merge with aggregated file)
	* because the different surveys have different reporting periods we need to just count at least 1 laundry in the half hour
		
	collapse (sum) laundry_* (mean) propwt, by(diarypid pid survey day month year s_halfhour ///
		ba_birth_cohort ba_age_r ba_nchild sex emp empstat nchild income hhldsize)

		lab val emp EMP
		lab val empstat EMPSTAT
		
		* set the weight
		svyset [iw=propwt]
		
		* the number of half hour data points by survey & day
		svy: tab survey day		
		
		*  do original locations
		local acts "all rh sh oth"

		foreach a of local acts {
			di "* Adding up 'at least 1' & basic stats for laundry_`a' ($version)"
			gen any_laundry_`a' = 0
			replace any_laundry_`a' = 1 if laundry_`a' > 0
			lab var any_laundry_`a' "`a' $version"
			di "* overall prevalence of 'any laundry in a half hour' - any_laundry_`a' ($version)"
			di "* counts (any_laundry_`a' $version)"
			svy: tab any_laundry_`a' survey, count format(%9.2f)
			di "* proportions (any_laundry_`a' $version)"
			svy: tab any_laundry_`a' survey, col ci
			di "* proportions by sex (any_laundry_`a' == 1 $version)" 
			svy: tab sex survey if any_laundry_`a' == 1, col ci
		}
		di "* test who does laundry at 'other locations' at half hour level"
		logit any_laundry_oth i.sex i.ba_age_r i.ba_nchild hhldsize i.empstat i.income if survey == 1974, cluster(pid)
		
		* now do the defined/derived locations
		local acts "h nh"
		foreach a of local acts {
			di "* Adding up 'at least 1' & basic stats for laundry_`a' ($version)"
			gen any_laundry_`a' = 0
			replace any_laundry_`a' = 1 if laundry_`a' > 0
			lab var any_laundry_`a' "`a' $version"
			di "* overall prevalence of 'any laundry in a half hour' - any_laundry_`a' ($version)"
			di "* counts (any_laundry_`a' $version)"
			svy: tab any_laundry_`a' survey, count format(%9.2f)
			di "* proportions (any_laundry_`a' $version)"
			svy: tab any_laundry_`a' survey, col ci
			di "* proportions by sex (any_laundry_`a' == 1 $version)" 
			svy: tab sex survey if any_laundry_`a' == 1, col ci
		}

		
	
			  
		* loop through locations
		local acts "all h nh"
		foreach a of local acts {
			di "*****************************"
			di "*****************************"
			
			di "*****************************"
			di "* 'at least 1 reported reported laundry instance' for: any_laundry_`a'"
			svy: tab any_laundry_`a' survey , col ci
	
			di "*******"
			di "* Tables for: any_laundry_`a' = 1"
			di "* Income"
			svy: tab income survey if any_laundry_`a' == 1, col ci
			
			di "*******"
			di "* Sex"
			svy: tab sex survey if any_laundry_`a' == 1, col ci		
			di "* Sex & age"
			di "* 1974 (if any_laundry_`a' = 1)"
			svy: tab ba_age_r sex if any_laundry_`a' == 1 & survey == 1974, ci row
			di "* 2005 (if any_laundry_`a' = 1)"
			svy: tab ba_age_r sex if any_laundry_`a' == 1 & survey == 2005, ci row
		
			di "*******"
			di "* Days by survey for any_laundry_`a' = 1 - Fig 2"
			svy: tab day survey if any_laundry_`a' == 1, ci col
	
			di "*******"
			di "* Days by gender & survey for any_laundry_`a' =1 - used for Fig 3 "
			table day sex survey if any_laundry_`a' == 1 [iw=propwt]
		
			di "*******"
			di "* Employment status by survey for any_laundry_`a' = 1"
			table empstat survey if any_laundry_`a' == 1 [iw=propwt]
	
			di "*******"
			di "* Days by survey & employment status if female for any_laundry_`a' = 1 - used for Figs 4 & 5"
			bysort survey: table day empstat if sex == 2 & any_laundry_`a' == 1 [iw=propwt]
	
		}
		
		* set time variable so can select by time
		xtset diarypid s_halfhour, delta(30 mins) format(%tcHH:MM)
	
		* time of day comparisons
		local acts "all h nh"
		foreach a of local acts {
			di "*****************************"
			di "* Tables for: any_laundry_`a'"
			table s_halfhour survey any_laundry_`a' [iw=propwt]
		
			di "* days by half hour for: any_laundry_`a'"
			table s_halfhour survey day [iw=propwt], by(any_laundry_`a')	
	
			/* seasons - leave out for now (small N)
			recode month (3 4 5 = 1 "Spring") (6 7 8 = 2 "Summer") (9 10 11 = 3 "Autumn") (12 1 2 = 4 "Winter"), gen(season)
			* check
			* tab month season
			table s_halfhour survey season [iw=propwt], by(any_laundry_`a')
			
			* by employment status - not used (small n esp if just for women)
			di "* by half hour & employment status for women for: any_laundry_`a'"
			table s_halfhour empstat survey if sex == 2 [iw=propwt], by(any_laundry_`a')
		
			di "*repeat by day for 2005 for: any_laundry_`a'"
			table s_halfhour empstat day if survey == 2005 & sex == 2 [iw=propwt], by(any_laundry_`a')
			*/
		}
		local acts "h"
		foreach a of local acts {
			* analysis by laundry type
			preserve
				gen laundry_timing_`a' = 5 if any_laundry_`a' == 1 // other
				replace laundry_timing_`a' = 1 if any_laundry_`a' == 1 & day == 1 & tin(08:00, 12:00) // sunday morning
				replace laundry_timing_`a' = 2 if any_laundry_`a' == 1 & day > 1 & day < 6 & tin(09:00, 12:00) // weekday morning
				replace laundry_timing_`a' = 3 if any_laundry_`a' == 1 & day > 1 & day < 6 & tin(17:00, 20:00) // weekday evening peak
				replace laundry_timing_`a' = 4 if any_laundry_`a' == 1 & tin(00:00, 01:30) // night-time
				replace laundry_timing_`a' = 4 if any_laundry_`a' == 1 & tin(22:30, 23:30) // night-time
			
				tab laundry_timing_`a', gen(laundry_timing_`a')
			
				* check for missing	
				table s_halfhour laundry_timing_`a' any_laundry_`a'
				tab laundry_timing_`a' survey, mi
				
				lab def laundry_timing 1 "Sunday morning 09:00-12:00" 2 "Weekday morning 09:00-12:00" 3 "Weekday evening peak 17:00-20:00" 4 "Night-time 22:30-01:30" 5 "Other"
				lab val laundry_timing_`a' laundry_timing
				tab laundry_timing_`a' survey [iw=propwt], col
				svy:tab laundry_timing_`a' survey, col ci
				*table laundry_timing_`a' ba_age_r survey [iw=propwt], col
				table laundry_timing_`a' empstat survey [iw=propwt], col
				*table laundry_timing_`a' ba_nchild survey [iw=propwt], col
				
				di "* collapse to single person record"
				* note that this does not mean classifying 1 person to 1 'type' - a person can display multiple laundry types
				* remember 1974/5 = 1 week diary
			
				collapse (sum) laundry_timing_* any_laundry_* (mean) propwt, by(pid survey ///
					ba_birth_cohort ba_age_r ba_nchild sex emp empstat nchild hhldsize)
					
					recode any_laundry_all any_laundry_h any_laundry_nh (1/max=1)
					recode laundry_timing_`a'1 (1/max=1)
					recode laundry_timing_`a'2 (1/max=1)
					recode laundry_timing_`a'3 (1/max=1)
					recode laundry_timing_`a'4 (1/max=1)
					recode laundry_timing_`a'5 (1/max=1)
					
					di "* how many people are in multiple types? (nlaundry_types_`a' $version)"
					egen nlaundry_types_`a' = rowtotal(laundry_timing_`a'*)
					svy: tab nlaundry_types_`a' survey, col
					
					* what % of respondents in each?
					svy: mean laundry_timing_`a'*, over(survey)
					* % of launderers
					svy: mean laundry_timing_`a'* if any_laundry_all == 1, over(survey)
					
					foreach v of numlist 1/4 {
						logit laundry_timing_`a'`v' sex ib4.empstat i.ba_age_r i.ba_nchild hhldsize if survey == 1974
						est store laundry_timing_`a'`v'_1974
						logit laundry_timing_`a'`v' sex ib4.empstat i.ba_age_r i.ba_nchild hhldsize if survey == 2005
						est store laundry_timing_`a'`v'_2005
					}
					estout laundry_timing_`a'*_2005 using "$rpath/laundry_type_`a'_1974_$version-regressions.txt", cells("b ci_l ci_u se p _star") stats(N r2_p chi2 p ll) replace
					estout laundry_timing_`a'*_2005 using "$rpath/laundry_type_`a'_2005_$version-regressions.txt", cells("b ci_l ci_u se p _star") stats(N r2_p chi2 p ll) replace
			restore
		}
} 


* go back to the main survey aggregate file
use "$mtuspath/MTUS-adult-aggregate-UK-only-wf.dta", clear

* drop all bad cases
keep if badcase == 0

* set as survey data for descriptives
svyset [iw=propwt]

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
svy: tab survey empstat if ba_working_age == 1 & sex == 2, row

di "Done!"

log close
