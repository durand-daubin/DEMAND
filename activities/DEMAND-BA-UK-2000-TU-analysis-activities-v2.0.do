* Exploratory analysis for DEMAND Research Centre Theme 1

* Uses ONS Time Use 2005 survey

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
local where "/Users/ben/Documents/Work"
local proot "`where'/Projects/RCUK-DEMAND/Theme 1"
local rpath "`proot'/results/ONS TU 2000"

local droot "`where'/Data/Social Science Datatsets/Time Use 2000/"
* location of time-use diary data
local dpath "`droot'/processed"

local dfile "diary_data_8"

* version
* local version = "v1.0"
* calculated at 10 minute intervals

*local version = "v2.0"
* calculated at 1/2 hour intervals

local version = "v3.0"
* calculated at 1/2 hour intervals & svyset uses sn1 & weight
* NB: could use population grossing weights to scale up to UK population?

* use the ungrossed non-response weight
* this just corrects for survey/diary non-response - we don't need to gross up to the population
* as we're not interested in total minutes etc
local wt "wtdry_ug"
* define the svyset form to account for clustered sampling (sn1 = point number) and weight
* we do not need to account for household clustering as we are using single person households
local svydesign "sn1 [iw=`wt']"

* control flow
local do_tabouts = 1
local do_demogs = 0

capture log close

* save log file (with version)
log using "`rpath'/DEMAND-BA-UK-2000-TU-analysis-activities-`version'.smcl", replace

* make script run without waiting for user input
set more off

* get diary data in long form - i.e. already coverted from original so that
*  id = panel variable and time of day converted to 'real time'
*  most survey variables kept out to keep file size small (will merge in later)
use "`dpath'/`dfile'_long_v1.0.dta", clear

* check unweighted & weighted n per weekday
* NB - remember this includes all respondents and that respondents (should have) completed
* 1 diary for a weekday and 1 diary for a weekend day

* unweighted
tab s_dow ba_dow, mi

* weighted
tab s_dow ba_dow [iw= `wt'], mi

* create weekday flag
* which you use matters!
* the first is the _actual_ day of the week the slot occurs on
gen s_weekday_flag = 0
replace s_weekday_flag = 1 if s_dow > 0 & s_dow < 6
lab var s_weekday_flag "Weekday (day of diary slot)"
* the second is the day the diary started which could have been yesterday at 04:00!
gen ba_weekday_flag = 0
replace ba_weekday_flag = 1 if ba_dow < 6
lab var ba_weekday_flag "Weekday (day diary started)"

* check
tab ba_weekday_flag s_weekday_flag

* create the fake half-hour time
gen d_halfhour = "30"
replace d_halfhour = "00" if d_min < 30

gen t_hour = d_hour if d_hour > 9
tostring t_hour, replace force
gen temph = d_hour if d_hour < 10
tostring temph, replace force
gen t = "0"
egen temphs = concat(t temph) if d_hour < 10

replace t_hour = temphs if d_hour < 10

egen shh_faketime = concat(t_hour d_halfhour), punct(":")

lab var shh_faketime "Time of day (half hours)"

* check
tab shh_faketime ba_dow
* NB - this shows how the weekend diaries 'carry over' into Monday morning & the weekday diaries into Saturday morning
tab shh_faketime s_dow
drop t_hour t temp*

di "* list all activity possibilities"
di "********* -> primary *********"
tab pact
di "********* -> secondary *********"
tab sact
* this gives us a massive list
/*
of interest here:

110 sleep (base category)

210 eating

3100 unspecified food management 
3110 food preparation
3120 baking
3130 dish washing
3320 ironing
3310 laundry

9950 filling in the time use diary

 */

local act210t "eating"
local act3100t "unsp_food_mgt"
local act3110t "food_prep"
local act3120t "baking"
local act3140t  "preserving"
local act3130t "dishwashing"

local act3310t "laundry"
local act3320t "ironing"

local activities "210 3110 3120 3130 3310 3320"

* put labels into a local so can re-use after collapse
* laundry at home
gen any_laundryah = 0
replace any_laundryah = 1 if (pact == 3310 | sact == 3310) & wher == 2
local any_laundryahl "Laundry (incl as 2nd act) at home"
lab var any_laundryah "`any_laundryahl'"
* food prep & baking - (not eating) at home
gen any_fdprp = 0
replace any_fdprp = 1 if (pact == 3110 | sact == 3110 | pact == 3120 | sact == 3120) & wher == 2
local any_fdprpl "Food prep & baking (incl as 2nd act) at home"
lab var any_fdprp "`any_fdprpl'"

gen any_foodprepah = 0
replace any_foodprepah = 1 if pact == 3110 | sact == 3110 & wher == 2

gen any_bakingah = 0
replace any_bakingah = 1 if pact == 3120 | sact == 3120 & wher == 2

gen any_eatah = 0
replace any_eatah = 1 if pact == 210 | sact == 210 & wher == 2

gen any_dishwah = 0
replace any_dishwah = 1 if pact == 3130 | sact == 3130 & wher == 2

gen any_presah = 0
replace any_presah = 1 if pact == 3140 | sact == 3140 & wher == 2

gen any_foodmgtah = 0
replace any_foodmgtah = 1 if pact == 3190 | sact == 3190 & wher == 2

* in-home media use
gen any_mediah = 0
replace any_mediah = 1 if (pact == 7230 | pact == 7231 | pact == 7239 | pact == 7240 | pact == 7241 | pact == 7249 | pact == 7250 | pact == 7251 | pact == 7259 ///
	| pact == 8210 | pact == 8211 | pact == 8212 | pact == 8219 | pact == 8220 | pact == 8221 | pact == 8222 | pact == 8229 ///
	| pact == 8300 | pact == 8310 | pact == 8311 | pact == 8312 | pact == 8319 | pact == 8320 ///
	| sact == 7230 | sact == 7231 | sact == 7239 | sact == 7240 | sact == 7241 | sact == 7249 | sact == 7250 | sact == 7251 | sact == 7259 ///
	| sact == 8210 | sact == 8211 | sact == 8212 | sact == 8219 | sact == 8220 | sact == 8221 | sact == 8222 | sact == 8229 ///
	| sact == 8300 | sact == 8310 | sact == 8311 | sact == 8312 | sact == 8319 | sact == 8320 ) ///
	 & wher == 2
local any_mediahl "TV/video, radio & computing incl games & as 2nd act) at home"
lab var any_mediah "`any_mediahl'"

* out-of-home media use
gen any_mediaoh = 0
* not elsewhere
replace any_mediaoh = 1 if (pact == 7230 | pact == 7231 | pact == 7239 | pact == 7240 | pact == 7241 | pact == 7249 | pact == 7250 | pact == 7251 | pact == 7259 ///
	| pact == 8210 | pact == 8211 | pact == 8212 | pact == 8219 | pact == 8220 | pact == 8221 | pact == 8222 | pact == 8229 ///
	| pact == 8300 | pact == 8310 | pact == 8311 | pact == 8312 | pact == 8319 | pact == 8320 ///
	| sact == 7230 | sact == 7231 | sact == 7239 | sact == 7240 | sact == 7241 | sact == 7249 | sact == 7250 | sact == 7251 | sact == 7259 ///
	| sact == 8210 | sact == 8211 | sact == 8212 | sact == 8219 | sact == 8220 | sact == 8221 | sact == 8222 | sact == 8229 ///
	| sact == 8300 | sact == 8310 | sact == 8311 | sact == 8312 | sact == 8319 | sact == 8320 ) ///
	 & wher !=2
local any_mediaohl "TV/video, radio & computing incl games & as 2nd act) outside home"
lab var any_mediaoh "`any_mediaohl'"

* actively not 'elsewhere'
gen at_homeact = 0
* -> at home & not asleep
replace at_homeact = 1 if wher == 2 
replace at_homeact = 0 if pact == 110 | sact == 110
local at_homeactl "At home & not asleep"
lab var at_homeact "`at_homeactl'"

local missing_locl "Missing location"

* now merge in ind survey data, keeping a few variables we want
merge m:1 sn1 sn2 sn3 using "`droot'/stata/2003 release/stata8_se/Individual_data_5.dta", keepusing(iage isex q1a q8c q15c hnumb num*) gen(m_ind_surv)

* keep only those that matched (there were respondents in survey for whom there is no diary data and there appear to be diaries for no known survey response)
keep if m_ind_surv == 3

* now merge in hh survey data, keeping a few variables we want
merge m:1 sn1 sn2 using "`droot'/stata/2003 release/stata8_se/hhld_data_6.dta", keepusing(hq4b_6 hq4b_7 hq4b_8 hq5*) gen(m_hh_surv)

* keep only those that matched (there were respondents in survey for whom there is no diary data and there appear to be diaries for no known survey response)
keep if m_hh_surv == 3

local wstatl "Work status"
* no paid work in 7 days of diary
gen wstat = 0 if q1a == 2
* paid work & working part time
replace wstat = 1 if q1a == 1 & q8c == 2
* paid work & working full time
replace wstat = 2 if q1a == 1 & q8c == 1
lab def wstat 0 "No paid work in 7 days" 1 "Paid work, part time" 2 "Paid work, full time"
lab var wstat "`wstatl'"
lab val wstat wstat

local agegrl "Age group"
recode iage (0/15=1) (16/18=2) (19/24=3) (25/64=4) (65/max=5), gen(agegr)
lab def agegr 1 "0-15" 2 "16-18" 3 "19-24" 4 "25-64" 5 "65+"
lab var agegr "`agegrl'"
lab val agegr agegr

* check work status on diary day using diary data
merge m:1 sn1 sn2 sn3 sn4 using "`droot'/stata/2003 release/stata8_se/diary_data_8.dta", gen(m_diary_data) keepusing(dml2_11)
keep if m_diary_data == 3

gen dwork_flag = 0
* set to 'worked' if minutes > 240 (4 hours)
replace dwork_flag = 1 if dml2_11 >= 240
lab var dwork_flag "Paid work > 240 minutes on diary day"

* tab work_flag wstat, mi
tabstat dml2_11, by(wstat)

local wstatl0 "no_work"
local wstatl1 "pt_work"
local wstatl2 "ft_work"

* single people only so don't need to control for household level clustering
svyset `svydesign'

if `do_tabouts' {
	preserve
		* reduce sample size to just singles
		keep if numadult == 1
		* collapse to half hours
		collapse (sum) any_*, by(sn1 sn2 sn3 sn4 shh_faketime s_dow numadult wstat agegr hq* wtdry_ug)
		
		* check
		su numadult
		
		if `r(mean)' != 1 {
			di "* STOP - not just single person households"
			stop
		} 
		else {
			di "* Just single person households"
		}
		
		* relabel vars why why why?
		lab var agegr "`agegrl'"
		lab val agegr agegr
		lab var wstat "`wstatl'"
		lab val wstat wstat

		* any_fdprp any_mediah any_mediaoh at_homeact
		* any_laundry -> would 
		local tvars "laundryah foodprepah bakingah eatah dishwah"
	
		* there could have been 0, 1, 2 or 3 instances recorded
		* proportion of half hour given over to laundry
		foreach v of local tvars {
			gen prop_`v' = 0
			replace prop_`v' = any_`v'/3
		
			renpfix any_`v' any_`v'c

			* any mention of laundry in that half hour?
			gen any_`v' = 0
			replace any_`v' = 1 if any_`v'c > 0
			* check
			tab any_`v'c any_`v'
		}
		
		di "******************"
		di "* using tabout & means"
		di "********* `wt`d'' ********"
		foreach v of local tvars {
			di "****** `v' *****" 
			* leave out 19-24 as not many of them and could be students etc
			*qui: tabout s_faketime any_laundry if s_weekday_flag == `d' & agegr == 3 [iw= `wt'] ///
			*	using "`rpath'/laundry_singles_19_24_`wt`d''_`version'.txt", svy c(row) format(4) replace
			di "*-> any_`v' by work status"
			svy: proportion any_`v', over(wstat)
			di "*-> any_`v' by age"
			svy: proportion any_`v', over(agegr)
			di "*-> any_`v' by day of the week"
			svy: proportion any_`v', over(s_dow)
			di "*-> any_`v' for agegr == 4 by wstat as a check"
			* check - these should produce the same point estimates & CIs, if so tabout approach should be OK
			svy: proportion any_`v' if wstat == 0 & agegr == 4, over(s_dow)
			svy: mean any_`v' if wstat == 0 & agegr == 4, over(s_dow)
			svy: tab s_dow any_`v' if wstat == 0 & agegr == 4, ci row
			tabout s_dow wstat if agegr == 4 ///
				using "`rpath'/any_`v'_singles_by_day_by_wstat_24_65_`version'.txt", svy sum c(mean any_`v' ci) format(4) replace
			* they do but NB tabout SE are not quite the same - might not be taking sn1 psu into account?
			
			local wstat "0 1 2"
			foreach w of local wstat {
				di "*-> any_`v' for agegr == 4 by wstat = `w' (`wstatl`w'')"
				di "*--> for main table - all ages - `wstatl`w''"
				qui: tabout agegr s_dow if wstat == `w' ///
					using "`rpath'/any_`v'_singles_all_`wstatl`w''_`version'.txt", svy sum c(mean any_`v' se) format(4) replace
				di "*--> for time of day charts - 25_64 - `wstatl`w''"
				qui: tabout shh_faketime s_dow if wstat == `w' & agegr == 4  ///
					using "`rpath'/any_`v'_singles_25_64_`wstatl`w''_`version'.txt", svy sum c(mean any_`v' se) format(4) replace

			}
			
			di "*-> any_`v' for agegr == 5"
			qui: tabout shh_faketime s_dow if agegr == 5  ///
				using "`rpath'/any_`v'_singles_65+_all_`version'.txt", svy sum c(mean any_`v' se) format(4) replace
		}	
		* save it for future use	
		compress
		save "`rpath'/`dfile'_long_v1.0_wf_shh_faketime_`version'.dta", replace
	restore		
}

if `do_demogs' {
	* collapse to 2 diary records per respondent (or 1 if they did 1 diary)
	preserve
		collapse (sum) any_* , by(sn1 sn2 sn3 sn4 numadult agegr wstat `wt' s_dow)
			tab wstat
			tab numadult
			table agegr wstat if numadult == 1 , by(s_dow)
			*svy: tab s_dow any_laundry if numadult == 1, row ci missing
			*svy: tab wstat any_laundry if numadult == 1, row ci missing
	
	restore
	
	
	* collapse to 1 record per respondent
	preserve
		collapse (count) nslots=sn4 (mean) any_* , by(sn1 sn2 sn3 numadult agegr wstat `wt')
			
			tab wstat
			tab numadult
			tab agegr wstat if numadult == 1 & agegr > 2, mi row
			tab agegr wstat if numadult == 1 & agegr > 2 [iw= `wt'], mi row
			* check
			svyset
			svy: mean any_* if numadult == 1 & agegr > 2, over(wstat)
	restore
}

* what happens at the same time as laundry?
gen with_laundry_as_p = sact if pact == 3310
lab var with_laundry_as_p "Activity done as 2nd act to laundry"
gen with_laundry_as_s = pact if sact == 3310
lab var with_laundry_as_s "Activity done as 1st act to laundry"
lab val with_laundry_as_p with_laundry_as_s act1_144

di "* check distributions of 'with laundry'"
svy: tab with_laundry_as_s agegr if numadult == 1, col
svy: tab with_laundry_as_p agegr if numadult == 1, col

*************************
* time series/panel stuff
* makes explicit use of the long format
* tell stata this is a panel time series
xtset xtserial s_datetime, delta(10 minutes)

* what happens after laundry?
* F. is the value after the current one
gen after_laundry = F.pact if any_laundry == 1
lab val after_laundry act1_144

svy: tab after_laundry agegr if numadult == 1

* what happens before laundry?
* L. is the value before (lag) the current one
gen before_laundry = L.pact if any_laundry == 1
lab val before_laundry act1_144

svy: tab before_laundry agegr if numadult == 1

* laundry durations - sequences!!
capture drop seql
gen seql = 0 if any_laundry == 0
lab var seql "Sequences of laundry (end point count)"
replace seql = 1 if any_laundry == 1

* this should count the consecutive sequences of laundry out to 20 (could go higher if needed)
* but 18 = 3 hours!!
foreach n of numlist 1/20 {
	replace seql = seql + 1 if any_laundry == 1 & L`n'.any_laundry == 1
}

* use svy prefix to make sure weight & sample structure used properly
* distribution across all ages - ignore sequences of 'no laundry'
svy: tab seql agegr if numadult == 1 & seql > 0, col

* check last two age groups - chisq diff?
svy: tab seql agegr if numadult == 1 & agegr > 3 & seql > 0, col
* check workstatus
svy: tab seql wstat if numadult == 1 & seql > 0, col
* check days of week
svy: tab seql s_dow if numadult == 1 & seql > 0, col
* does having a tumble drier matter?
svy: tab seql hq4b_7, col

* sequences of eating etc
* any_foodprepah any_bakingah any_eatah any_dishwah any_presah any_foodmgtah
local vars "foodprep baking eat dishw"
foreach v of local vars {
	gen after_`v'l1 = F.pact if any_`v'ah == 1
	gen after_`v'l2 = F.pact if L1.any_`v'ah == 1
	gen after_`v'l3 = F.pact if L2.any_`v'ah == 1
	gen after_`v'l4 = F.pact if L3.any_`v'ah == 1
	gen after_`v'l5 = F.pact if L3.any_`v'ah == 1
	gen after_`v'6 = F.pact if L3.any_`v'ah == 1
	lab val after_`v'* act1_144
}

* save for future use
compress
save "`rpath'/`dfile'_long_v1.0_wf_s_datetime_`version'.dta", replace

log close


