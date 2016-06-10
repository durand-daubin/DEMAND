*******************************************
* DEMAND Project (www.demand.ac.uk)
* Analysis for paper developed from BEHAVE 2014 conference presentation (http://www.slideshare.net/ben_anderson/behave-practices-hunting5) with mathieu.durand-daubin@edf.fr

* Use MTUS (see http://www.timeuse.org/mtus/) to get episodes of cooking & eating
* Use this to work out what kinds of 'dinner' we have & classify the diary days accordingly
* match the diary days/diarists back to the 10 minute sampled MTUS data to produce time use graphs etc
/*   

Copyright (C) 2014  University of Southampton

Author: Ben Anderson (b.anderson@soton.ac.uk, @dataknut, https://github.com/dataknut) 
	[Energy & Climate Change, Faculty of Engineering & Environment, University of Southampton]

based on concept & logic devised by mathieu.durand-daubin@edf.fr

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
local where "~/Documents/Work"
local droot "`where'/Data/Social Science Datatsets/MTUS/World 6/"
* location of time-use diary data
local dpath "`droot'/processed"

local proot "`where'/Projects/RCUK-DEMAND/Theme 1"
local rpath "`proot'/papers/Practice Hunting-Dinner"

* MTUS codes:
* meals at work or school = 5 (not available in all surveys)
* meals or snacks in other places = 6
* food preparation, cooking = 18
* restaurant, cafe, bar, pub = 39 (but may not be eating?!)
* out with friends could be eating = 48 (but check location as might also be at home)
* eloc = location

local version = "v1.1"
* version 1.1 - uses 10 minute sampled version of MTUS data
* version 1 - uses ONS TU 2005 data

* switch graphs on/off
local do_graphs = 0
local do_tables = 0

set more off

capture log close

log using "`rpath'/DEMAND-BA-MTUS-dinner-hunting-`version'.smcl", replace

* start with MTUS data
* NB this is a UK only subsample with some derived variables added

use "`dpath'/MTUS-adult-episode-UK-only-wf.dta", clear
* data in long/episode format

gen ba_weekday = 0
replace ba_weekday = 1 if ba_dow < 6

* sleep (surely everyone reports it?!) - use this as a checker later on
gen sleep_all = 0
replace sleep_all = 1 if main == 2 | sec == 2

* set up eating dummies
* There could be several sequential episodes of eating if something else changed e.g. 
* - primary <-> secondary
* - location changed 
* both of which we might care about
gen eat_p = 0
replace eat_p = 1 if main == 5 | main == 6
gen eat_s = 0
replace eat_s = 1 if sec == 5 | sec == 6

gen eat_all = 0
replace eat_all = 1 if eat_p == 1 | eat_s == 1

* calculate duration
bysort survey diarypid: gen eat_duration = time if eat_all == 1
* count back & forward maxcount episodes to check if they are also eating 
* indicates something changed - primary/secondary act or location or who with etc
* add on duration if previous and subsequent episodes are also eat and location is unchanged
* NB: if you make maxcount > 1 then you could have episodes of eating separated by a long episode of something else e.g. breakfast -> work -> lunch
* might be best to check the duration of the episode in between if you do this (or even check what it was e.g. cooking)
local maxcount = 1
foreach n of numlist 1/`maxcount' {
	local prev = `n' - 1
	di "* Now = `n', previous = `prev'"
	di "* Before"
	su eat_duration
	bysort survey diarypid: replace eat_duration = eat_duration + time[_n-`n'] if eat_all == 1 & ///
		eat_all[_n-`n'] == 1 & eloc == eloc[_n-`n']
	bysort survey diarypid: replace eat_duration = eat_duration + time[_n+`n'] if eat_all == 1 & ///
		eat_all[_n+`n'] == 1 & eloc == eloc[_n+`n']
	di "* After"
	su eat_duration
}

* same for cooking
* There could be several sequential episodes of cooking if something else changed e.g. 
* - primary <-> secondary
* - location changed 
* both of which we might care about
gen cook_p = 0
replace cook_p = 1 if main == 18
gen cook_s = 0
replace cook_s = 1 if sec == 18

gen cook_all = 0
replace cook_all = 1 if cook_p == 1 | cook_s == 1

* calculate duration
bysort survey diarypid: gen cook_duration = time if cook_all == 1

local maxcount = 1
* check n-maxcount & n+ maxcount episode for cooking in the same location & add duration
foreach n of numlist 1/`maxcount' {
	local prev = `n' - 1
	di "* Now = `n', previous = `prev'"
	di "* Before"
	su cook_duration
	bysort survey diarypid: replace cook_duration = cook_duration + time[_n-`n'] if cook_all == 1 & ///
		cook_all[_n-`n'] == 1 & eloc == eloc[_n-`n']
	bysort survey diarypid: replace cook_duration = cook_duration + time[_n+`n'] if cook_all == 1 & ///
		cook_all[_n+`n'] == 1 & eloc == eloc[_n+`n']
	di "* After"
	su cook_duration
}

tab ba_weekday ba_dow

* if try to tab by survey & start time you get jitter/spikes due to different time slot durations used in each year
* so use the halfhour start time variable created previously (same as Mathieu)
table s_halfhour eat_all survey

if `do_graphs' {
	graph bar (mean) eat_all, over(s_halfhour) by(survey) name(bar_eat_all)
	graph export "`rpath'/bar_eat_all_by_survey.png", replace
	graph bar (mean) cook_all, over(s_halfhour) by(survey) name(bar_cook_all) 
	graph export "`rpath'/bar_cook_all_by_survey.png", replace
	
	* both the following are disrupted by the time intervals used in the diary itself
	histogram eat_duration, by(survey) name(histo_eat_duration)
	graph export "`rpath'/histo_eat_duration_by_survey.png", replace

	histogram cook_duration, by(survey) name(histo_cook_duration)
	graph export "`rpath'/histo_cook_duration_by_survey.png", replace
}

* dump these means out so can graph in excel as lines (easier to see)
* this will give the mean number of episodes in the half hour
if `do_tables' {
	qui: tabout s_halfhour survey using "`rpath'/MTUS-UK-Adults-eat_all-by-survey-halfhour.txt", cells(mean eat_all) sum replace
	qui: tabout s_halfhour survey using "`rpath'/MTUS-UK-Adults-eat_all-by-survey-halfhour.txt", cells(mean cook_all) sum replace
}

* so we need to start UK dinner earlier - about 17:00
* but end about 22:00?

* check for non-eaters, non-cookers & non-sleepers
* NB not eating/cooking/sleeping at all will be more likely to show up in the years with just 1 diary day (1995, 2005)
preserve
	collapse (mean) eat_all cook_all sleep, by(survey persid ba_dow)
	* how many don't eat?
	table ba_dow eat_all survey if eat_all == 0, mi
	* how many don't cook?
	table ba_dow cook_all survey if cook_all == 0, mi
	* how many don't sleep?
	table ba_dow sleep_all survey if sleep_all == 0, mi
restore

* now find the cooking that came before the dinner (if there was any)

* this keeps the eating and cooking episodes only
keep if eat_all == 1 | cook_all == 1
* make sure they're in order
sort diarypid epnum

* keep badcase to be able to distinguish between bad cases and non-eaters below
keep countrya survey swave msamp hldid persid day diarypid pid epnum age s_* ba_* badcase main sec eloc eat* cook* 
* don't do dinner skip here as this is setting any kind of eat to 'dinner_skip'

li diarypid epnum s_starttime main sec eat_all cook_all in 1/10

************************************************
* Define dinner - varies by survey (& year?)
* UK: define dinner as starting to eat 17:00 - 22:00
* should we define an end time?
* should it vary by year, or anything else??
gen ba_hour = hh(s_starttime)
gen dinner = 1 if eat_all == 1 & ba_hour >= 17 & ba_hour <= 22
table ba_hour survey dinner 

* which dinners have cooking at home before or during them?
bysort diarypid: gen dinner_cook = 1 if dinner == 1 & eloc == 1 ///
	& (cook_all[_n-1] == 1 | cook_all == 1)
gen dinner_cook_dur = eat_duration if dinner_cook == 1
table ba_hour survey dinner_cook

* and which don't - i.e. no cooking before and no cooking during
bysort diarypid: gen dinner_nocook = 1 if dinner == 1 & eloc == 1 ///
	& (cook_all[_n-1] != 1 | cook_all != 1)
gen dinner_nocook_dur = eat_duration if dinner_nocook == 1
table ba_hour survey dinner_nocook

* who goes out for dinner?
* NB this can include cooking beforehand to take out, or cooking & eating elsewhere?
* this is going to be underestimated as we never have eating defined as a primary or secondary activity when 
* the primary or secondary activity is "restaurant, cafe, bar, pub" 
* (which should really have been coded as location not activity!)

* dinner not at home, with the episode prior being cooking at home
bysort diarypid: gen dinner_out_cook = 1 if dinner == 1 & eloc != 1 ///
	& (cook_all[_n-1] == 1 & eloc[_n-1] == 1)
gen dinner_out_cook_dur = eat_duration if dinner_out_cook == 1
table ba_hour survey dinner_out_cook

* dinner out with no cooking at home
bysort diarypid: gen dinner_out_nocook = 1 if dinner == 1 & eloc != 1 ///
	& (cook_all[_n-1] != 1 & eloc[_n-1] == 1)
gen dinner_out_nocook_dur = eat_duration if dinner_out_cook == 1
table ba_hour survey dinner_out_nocook

local vars "dinner dinner_out_cook dinner_out_nocook dinner_cook dinner_nocook"
foreach v of local vars {
	bysort diarypid: egen `v'_n = count(`v')
}
su *_n

* now collect together the dinners
* add in a check variable
collapse (mean) dinner* eat_all, by(diarypid age survey) // Takes the mean value of dinner and should be a whole number as it is per diary day
su dinner*
* there can be several dinners in one diary - e.g. one cooked at home and then eating out later (or vice versa)
tab dinner_cook dinner_nocook
tab dinner_out_nocook dinner_nocook
tab dinner_cook dinner_out_nocook

* mostly they are few except for the cook/no cook

gen no_eat = 0
replace no_eat = 1 if eat_all == 0
lab def no_eat 0 "Ate during the day" 1 "Didn't eat at all"
lab val no_eat no_eat

tab dinner no_eat, mi

* we assume that dinner_cook takes precedence over the others so set this code last
* ? we could investigate the sequences to take the longest duration

* these are the exact results:
gen dinner_categories = 0 if no_eat == 1 // no eating at all!
replace dinner_categories = 1 if dinner != 1 & no_eat != 1 // no dinner but did eat
replace dinner_categories = 2 if dinner == 1 //temp
* test
tab dinner_categories, mi
* complete dinner detail
replace dinner_categories = 2 if dinner_nocook == 1 // dinner without cooking
replace dinner_categories = 3 if dinner_cook == 1 // dinner with cooking
replace dinner_categories = 4 if dinner_out_nocook == 1 // dinner out with no prior cooking
replace dinner_categories = 5 if dinner_out_cook == 1 // dinner out with prior cooking
lab def dinner_categories 0 "No eat" 1 "No dinner (but did eat)" 2 "Dinner without cooking" 3 "Dinner with cooking" 4 "Dinner out, no cooking" 5 "Dinner out, prior cooking"
lab val dinner_categories dinner_categories

tab dinner_categories, mi
tab dinner_categories survey, mi

rename age age_check
* merge back to MTUS to get weight and 'badcase'
merge m:1 diarypid using "`dpath'/MTUS-adult-aggregate-UK-only-wf.dta", gen(m_mtus)

* check the matches were OK
su age age_check
pwcorr age age_check

drop dinner_*dur dinner_*n dinner_out* dinner_cook dinner_nocook eat_all

keep if badcase == 0

table dinner_categories survey m_mtus, mi
* so non-matches seem to be 1995

table ba_age_r dinner_categories survey [iw= propwt]
table ba_dow dinner_categories survey [iw= propwt]

* use MTUS weight
svyset [iw= propwt]

local tvars "ba_dow sex ba_age_r civstat student empstat income"
foreach v of local tvars {
di "* Testing `v' and dinner_categories for 2005"
	svy: tab dinner_categories `v' if survey == 2005, col
}

* check before merge
tab dinner_categories survey, mi

* there are a few undefined in each year

* link to original MTUS data but in 10 min samples for easy graphing
merge 1:m diarypid using "`dpath'/MTUS-adult-episode-UK-only-wf-10min-samples-long-v1.0.dta", gen(m_10minsample) // diarypid should match all

* shouldn't have bad cases but just in case...
keep if badcase == 0

* code eating
gen eat = 0
replace eat = 1 if pact == 5 | sact == 5 | pact == 6 | sact == 6

* code cooking
gen cook = 0
replace cook = 1 if pact == 18 | sact == 18

* code pub etc (may not be eating)
gen pub = 0
replace pub = 1 if pact == 39 | sact == 39

****************************
* run analysis just for 2005
****************************
keep if survey == 2005

* in case not already set
svyset [iw=propwt]
format s_starttime %tcHH:mm

tab dinner_categories, mi

/* skip until we've got the categories fixed

* cook
qui: tabout s_starttime dinner_categories using "`rpath'/dinner_categories-cook-by-halfhour-weekdays-`version'.txt", c(mean cook) format(4) sum svy replace
* eat
qui: tabout s_starttime dinner_categories using "`rpath'/dinner_categories-eat-by-halfhour-weekdays-`version'.txt", c(mean eat) format(4) sum svy replace
* pub
qui: tabout s_starttime dinner_categories using "`rpath'/dinner_categories-pub-by-halfhour-weekdays-`version'.txt", c(mean pub) format(4) sum svy replace

* create tables for profiles for each type for 2005
local d0 "No-eat"
local d1 "No-Dinner"
local d2 "No-Cook-Dinner"
local d3 "Cook-Dinner"
local d4 "No-Cook-Dinner-Out"
local d5 "Cook-Dinner-Out"

forvalues c = 0/5 {
	di "* Creating tables for dinner_category: `c' (`d`c'')"
	qui: tabout s_starttime pact if dinner_categories  == `c' & ba_weekday == 1 using "`rpath'/dinner_categories-`c'-all-main-acts-by-halfhour-weekdays-`version'.txt" [iw=propwt], replace
}
*/

log close
