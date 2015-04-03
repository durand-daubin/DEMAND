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

log using "$rpath/DEMAND-BA-MTUS-Energy-Practices-Over-Time-`version'.smcl", replace

* control what gets done
local do_halfhour_samples = 1

* make script run without waiting for user input
set more off

**********************************
* Codes of interest
* Main/Sec21 Laundry, ironing, clothing repair
* 

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

/* already done in input file

* hh size recode & test
recode hhldsize (1=1) (2=2) (3=3) (4=4) (5/max=5), gen(ba_hhsize)
lab var ba_hhsize "Recoded household size"
lab def ba_hhsize 1 "1" 2 "2" 3 "3" 4 "4" 5 "5+"
lab var ba_hhsize ba_hhsize

* svy: tab ba_hhsize survey, col count

* main7 & main8 = paid work
gen ba_4hrspaidwork = 0
* mark those who worked more than 4 hours that day
replace ba_4hrspaidwork = 1 if main7 > 240

* set up n child & n people variables
recode nchild (0=0) (1=1) (2=2) (3/max=3), gen(ba_nchild)
lab var ba_nchild "Recoded nchild"
lab def ba_nchild 0 "0" 1 "1" 2 "2" 3 "3+"
lab val ba_nchild ba_nchild
recode hhldsize (0=0) (1=1) (2=2) (3=3) (4=4) (5/max=5), gen(ba_npeople)
lab def ba_npeople 0 "0" 1 "1" 2 "2" 3 "3" 4 "4" 5 "5+"
lab val ba_npeople ba_npeople

* age categories
egen ba_age_r = cut(age), at(16,24,34,44,54,64,74,84)
lab var ba_age_r "Recoded age -> decades"
tab ba_age_r

* age cohorts
gen ba_birthyear = year - age
egen ba_birth_cohort = cut(ba_birthyear), at(1890,1900,1910,1920,1930,1940,1950,1960,1970,1980)
tab ba_birth_cohort survey
* NB - max age = 80 so older cohorts missing from 2005

* weekday variable
gen ba_weekday = 0
replace ba_weekday = 1 if day > 1 & day < 7

*/


* keep only the vars we want to keep memory required low
keep sex age main7 main21 hhtype empstat emp unemp student retired propwt survey day month year ///
	hhldsize famstat nchild *pid ba*

* number of diary-days
svy: tab survey, obs

preserve

if `do_halfhour_episodes' {
	*************************
	* merge in the episode data
	* do analysis at episode level
	* egen diarypid = group(countrya survey swave msamp hldid persid day)
	* egen pid = group(countrya survey swave msamp hldid persid)
	merge 1:m diarypid using "$mtuspath/MTUS-adult-episode-UK-only-wf.dta", ///
		gen(m_aggvars)
	
	* won't match the dropped years	& badcases
	tab m_aggvars survey
	
	* keep the matched cases
	keep if m_aggvars == 3
	
	* number of episodes per day
	svy: tab day survey, obs col
	
	* overall durations
	gen duration = s_endtime - s_starttime
	format duration %tcHH:MM
	tab duration survey [iw=propwt]

	***************
	* Laundry
	
	* define laundry
	gen laundry_p = 0
	lab var laundry_p "Main act = laundry (21)"
	replace laundry_p = 1 if main == 21
	
	gen laundry_s = 0
	lab var laundry_s "Secondary act = laundry (21)"
	replace laundry_s = 1 if sec == 21
	
	gen laundry_all = 0
	replace laundry_all = 1 if laundry_p == 1 | laundry_s == 1
	
	* check % episodes which are laundry
	* NB reporting frame shorter in 2005 (10 mins) so may be higher frequency (e.g. interruption in 10-20 mins coded)
	* row %
	tab survey laundry_p [iw=propwt]
	tab survey laundry_s [iw=propwt]
	* all
	tab survey laundry_all [iw=propwt]
	
	* check duration of laundry
	* before we do this mere together episodes that are contiguous (e.g. laundry (s) then laundry(p) -> 1 episode)
	* same approach as for dinner
	* calculate duration
	gen laundry_duration = duration if laundry_all == 1
	format laundry_duration %tcHH:MM
	* count back & forward maxcount episodes within the same diary day to check if they are also laundry 
	* indicates something changed - primary/secondary act or location or who with etc
	* add on duration if previous and subsequent episodes are also laundry and location is unchanged
	* NB: if you make maxcount > 1 then you could have episodes of eating separated by a long episode of something else
	local maxcount = 1
	
	* This is vital - we have to have the episodes in diary & time order!
	sort diarypid start

	foreach n of numlist 1/`maxcount' {
		local prev = `n' - 1
		di "* Now = `n', previous = `prev'"
		di "* Before"
		su laundry_duration
		bysort survey diarypid: replace laundry_duration = laundry_duration + duration[_n-`n'] if laundry_all == 1 & ///
			laundry_all[_n-`n'] == 1 & eloc == eloc[_n-`n']
		bysort survey diarypid: replace laundry_duration = laundry_duration + duration[_n+`n'] if laundry_all == 1 & ///
			laundry_all[_n+`n'] == 1 & eloc == eloc[_n+`n']
		di "* After"
		su laundry_duration
	}
	
	
	* Means are probably not going to tell us much given the differences in recording frames
	* Use table instead as durations are so 'rounded'
	* even so have to allow for differences in recording frames
	table laundry_duration sex survey [iw=propwt]
	
	* age cohort differences in incidence of laundry
	table ba_birth_cohort laundry_all survey [iw=propwt]
	
	
	* leave this empty to skip the (time consuming) aggregations & table outputs
	local vars "21"
	local l5 "meals_work"
	local l6 "meals_oth"
	local l18 "food_prep"
	local l21 "laundry"
	local l59 "tv_video"
	local l60 "computer_games"
	local l61 "computer_internet"
	
	*************************
	* Aggregation to half hours
	* logic: the time use diaries rarely have the same duration of recorded time slot, 1974 = 30 mins, 2005 = 10 mins for example
	* To make comparison easier we need to use the lowest common multiple - in this case 30 minutes
	* We have already set up a variable (s_halfhour) which is the stata episode start-time converted into a stata half hour
	* i.e. if s_starttime = 21:24 s_halfhour =  21:00, if s_starttime = 21:44 s_halfhour =  21:30 etc
	
	* Note that where the diary has episodes shorter than 30 minutes we may get more than 1 episode of laundry 
	* reported per half hour
	* Check
	duplicates tag s_halfhour diarypid laundry_all, gen(laundry_dup_flag)
	table laundry_dup_flag laundry_all survey
	
	* We'd expect them all to occur in 2005 but they don't suggesting the 1974 -> MTUS conversion process has creates
	* some episodes shorter than 30 minutes
	* In any case we do need to watch out for situations where we sum the number of episodes per halfhour as 
	* we may have more episodes in 2005 due to the smaller recording time frame.
	
	* Note that where the diary has episodes shorter than 30 minutes we may get more than 1 episode reported per half hour
	* We will also miss longer episodes that started this half-hour and are continuing in the next half hour
	
	* This will record all episodes that started within the half hour but it won't catch episodes that started before and
	* are long-lasting. So it is good for looking at the distribution of episodes that are short, like laundry (mostly)
	* It does NOT work for longer-lasting episodes like sleep or paid work
	di "* Tables for all days"
	* All years, all days
	table s_halfhour survey laundry_all [iw=propwt]
	
	* Separate days
	table survey day [iw=propwt], by(laundry_all)
	
	* days by half hour
	table s_halfhour survey day [iw=propwt], by(laundry_all)	
}

restore

*preserve
*************************
* sampled data
* this requires the 10 minute sampling process implemented in XXX to have been run over the MTUS first

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
	
	* this is the number of 10 minute samples by survey & day of the week
	tab survey day [iw=propwt]
	
	* check % samples which are laundry
	* NB reporting frame longer in 1974 (30 mins) so may be higher frequency (e.g. interruption in 10-20 mins coded)
	di "* main"
	tab survey laundry_p [iw=propwt]
	di "* secondary"
	tab survey laundry_s [iw=propwt]
	di "* all"
	tab survey laundry_all [iw=propwt]
	
	* keep 1974 & 2005 only
	keep if survey == 1974 | survey == 2005
	
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
	* the distribution of laundry by survey
	di "* primary"
	svy: tab survey any_laundry_p, row ci
	
	di "* secondary"
	svy: tab survey any_laundry_p, row ci
	
	di "* all"
	svy: tab survey any_laundry_all, row ci
	
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

	* set time variable so can select by time
	xtset diarypid s_halfhour, delta(30 mins)
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
*restore

*************************
* sequences
if `do_sequences' {
	* back to the episodes
	merge 1:m diarypid using "$mtuspath/MTUS-adult-episode-UK-only-wf.dta", ///
		gen(m_aggvars)
	* this won't have matched the dropped years	& badcases
	* tab m_aggvars survey
	
	* keep the matched cases
	keep if m_aggvars == 3
	
	* define laundry
	gen laundry_p = 0
	lab var laundry_p "Main act = laundry (21)"
	replace laundry_p = 1 if main == 21
	
	gen laundry_s = 0
	lab var laundry_s "Secondary act = laundry (21)"
	replace laundry_s = 1 if sec == 21
	
	gen laundry_all = 0
	replace laundry_all = 1 if laundry_p == 1 | laundry_s == 1

	* we can't use the lag notation and xtset as there are various time periods represented in the data
	* and we would need to set up some fake (or real!) dates to attach the start times to.
	* we could do this but we don't really need to.
	
	* we want to use episodes not time slots (as we are ignoring duration here)

	* This is vital - we have to have the episodes in diary & time order!
	sort diarypid start
	
	* we are NOT going to worry about sequential episodes which are both laundry_all as this will indicate
	* that something changed - most likely a switch of laundry from primary to secondary activity (or vice versa)
	* this may be of interest in itself

	local acts "all"
	foreach a of local acts {
		* make sure we do this within diaries otherwise we might get a 'before' or 'after' belonging to a previous day (for multi day diaries)
		* or to someone else (for 1 day diaries or the first day)!
		
		qui: by diarypid: gen before_laundry_`a' = main[_n-1] if laundry_`a' == 1
		qui: by diarypid: gen after_laundry_`a' = main[_n+1] if laundry_`a' == 1
		
		lab val before_laundry_`a' after_laundry_`a' MAIN
		 
		qui: tabout before_laundry_`a' survey [iw=propwt] using "$rpath/before-laundry-by-survey.txt", replace
		qui: tabout after_laundry_`a' survey [iw=propwt] using "$rpath/after-laundry-by-survey.txt", replace
	}
	tab laundry_all
	* create a sequence variable (horrible kludge but hey, it works :-)
	egen laundry_seq = concat(before_laundry_all laundry_all after_laundry_all) if laundry_all == 1 , punct("_") 
	
	* get frequencies of sequencies (this will be a very big table)
	* the few which have missing (.) before laundry indicate nothing recorded before hand which seems a bit odd?
	
	tab laundry_seq
	
	preserve
		* contract doesn't like iw - only allows fw (which need to be integers)
		* so these will be unweighted
		contract laundry_seq survey, nomiss
		qui: tab laundry_seq
		
		qui: return li
		di "For laundry_seq after contract : N = " r(N) ", r = " r(r)

		* reshape it to get the frequencies per survey into columns
		qui: reshape wide _freq, i(laundry_seq) j(survey)
		qui: return li
		
		li in 1/5
		outsheet using "$rpath/laundry-sequences-by-survey-wide.txt", replace
		* totals
		* the number of different sequences will probably vary by sample size - more potential variation
		su _freq*, sep(0)
		tabstat _freq*, s(n sum)
		* top in 1974?
		gsort - _freq1974
		li in 1/10, sep(0)
		* top in 2005?
		gsort - _freq2005
		li in 1/10, sep(0)
		
		
	restore
	
	/*
		* try using the sqset commands
		
		* tell it to look at sequences
		sqset main diarypid s_starttime
			
		* top 20 sequences
		sqtab survey if before_laundry ! = 1 | after_laundry ! = 1, ranks(1/20) 
	*/	
} 

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

* Propoprtion of women in work
tab survey empstat [iw=propwt] if ba_working_age == 1 & sex == 2, row


log close
