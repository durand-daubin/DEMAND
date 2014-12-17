*******************************************
* DEMAND Project (www.demand.ac.uk)
* Analysis for paper developed from BEHAVE 2014 conference presentation (http://www.slideshare.net/ben_anderson/behave-practices-hunting5) with mathieu.durand-daubin@edf.fr

* Use MTUS (see http://www.timeuse.org/mtus/) to get episodes of cooking & eating
* Use this to work out what kinds of 'dinner' we have & classify the diary days accordingly
* match the diary days/diarists back to the original ONS TU 2005 data from the UK data archive (http://discover.ukdataservice.ac.uk/catalogue/?sn=5592) to see what the different dinner 'types' were doing through the day

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
local where "/Users/ben/Documents/Work"
local droot "`where'/Data/Social Science Datatsets/Time Use 2005"
* location of time-use diary data
local dpath "`droot'/processed"

local proot "`where'/Projects/RCUK-DEMAND/Theme 1"
local rpath "`proot'/papers/Practice Hunting-Dinner"

* ONS TU codes:
* meals at work or school = 5 (not available in all surveys)
* meals or snacks in other places = 6
* food preparation, cooking = 18
* restaurant, cafe, bar, pub = 39 (but may not be eating?!)
* out with friends could be = 48 (but check location as might also be at home)
* eloc = location

local version = "v2.0"
* uses updated version of ONS TU 2005 which includes eating & cooking seperately
* still can't tell where eating outside home takes place

set more off

capture log close

log using "`rpath'/DEMAND-BA-ONS-TU-2005-dinner-hunting-`version'.smcl", replace

* start with MTUS data
* NB this is a UK only subsample with some derived variables added

use "`dpath'/timeusefinal_for_archive_diary_long_v2.0.dta", clear
* data in long/episode format

gen ba_weekday = 0
replace ba_weekday = 1 if ba_dow < 6

* drop bad cases
keep if badcase == 0

* sleep (surely everyone reports it?!) - use this as a checker later on
gen sleep_all = 0
replace sleep_all = 1 if main == 2 | sec == 2

* set up eating dummies
* 5 not set for 2005
* There could be several sequential episodes of eating if something else changed e.g. 
* - primary <-> secondary
* - location changed 
* both of which we might care about
gen eat_p = 0
replace eat_p = 1 if main == 6 
gen eat_s = 0
replace eat_s = 1 if sec == 6

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
graph bar (mean) eat_all, over(s_halfhour) by(survey) name(bar_eat_all)
graph export "`rpath'/bar_eat_all_by_survey.png", replace
graph bar (mean) cook_all, over(s_halfhour) by(survey) name(bar_cook_all) 
graph export "`rpath'/bar_cook_all_by_survey.png", replace

* dump these means out so can graph in excel as lines (easier to see)
* this will give the mean number of episodes in the half hour
tabout s_halfhour survey using "`rpath'/MTUS-UK-Adults-eat_all-by-survey-halfhour.txt", cells(mean eat_all) sum replace
tabout s_halfhour survey using "`rpath'/MTUS-UK-Adults-eat_all-by-survey-halfhour.txt", cells(mean cook_all) sum replace

* both the following are disrupted by the time intervals used in the diary itself
histogram eat_duration, by(survey) name(histo_eat_duration)
graph export "`rpath'/histo_eat_duration_by_survey.png", replace

histogram cook_duration, by(survey) name(histo_cook_duration)
graph export "`rpath'/histo_cook_duration_by_survey.png", replace

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
sort survey persid id epnum

* keep badcase to be able to distinguish between bad cases and non-eaters below
keep survey persid id epnum s_* ba_* badcase main sec eloc eat* cook* 
* don't do dinner skip here as this is setting any kind of eat to 'dinner_skip'

stop

************************************************
* Define dinner - varies by survey?
* define dinner as starting to eat 17:00 - 22:00
* ?: should we define an end time?
gen dinner = 0 if eat_all == 1
replace dinner = 1 if eat_all == 1 & ba_hour >= 17 & ba_hour <= 22

* who goes out for dinner?
* this is going to be underestimated as we never have eating defined as a primary or secondary activity when 
* the primary or secondary activity is "restaurant, cafe, bar, pub" 
* (which should really have been coded as location not activity!)
gen dinner_out = 1 if dinner == 1 & eloc != 1
gen dinner_out_dur = eat_duration if dinner_out == 1

* so, which dinners have cooking at home before or during them?
by persid: gen dinner_cook = 1 if dinner == 1 & dinner_out != 1 & (cook[_n-1] == 1 | cook == 1) & eloc == 1
gen dinner_cook_dur = eat_duration if dinner_cook == 1

* and which don't - i.e. no cooking before and no cooking during
* inverse of the cook situation (we would need to allow for non-existing episodes before the eat otherwise)
by persid: gen dinner_nocook = 1 if dinner == 1 & dinner_cook != 1 & dinner_out != 1
gen dinner_nocook_dur = eat_duration if dinner_nocook == 1

keep if dinner == 1
local vars "dinner dinner_out dinner_cook dinner_nocook"
foreach v of local vars {
	by persid: egen `v'_n = count(`v')
}
su *_n

* now collect together the dinners
collapse (mean) dinner*, by(persid) // Takes the mean value of dinner
su dinner*
* there can be several dinners in one diary - e.g. one cooked at home and then eating out later (or vice versa)
tab dinner_cook dinner_nocook
tab dinner_out dinner_nocook
tab dinner_cook dinner_out

* mostly they are few except for the cook/no cook

* we assume that dinner_cook takes precedence over the others so set this caode last
* ? we could investigate the sequences to take the longest duration

* these are the exact results:
gen dinner_categories = 2 if dinner_nocook == 1 // dinner without cooking
replace dinner_categories = 3 if dinner_out == 1 // dinner out
replace dinner_categories = 1 if dinner_cook == 1 // dinner with cooking

tab dinner_categories, mi

* merge back to MTUS to get weight and 'badcase'
merge 1:1 persid using "`dpath'/MTUS-adult-aggregate-UK-only-wf-2005.dta", gen(m_mtus) keepusing(badcase day propwt)

* some of these will be bad cases
tab dinner m_mtus, mi

* gen as double so no rounding occurrs
gen double serial = persid

* link to original ONS data
merge 1:1 serial using "`where'/Data/Social Science Datatsets/Time Use 2005/UKDA-5592-stata8/stata8/timeusefinal_for_archive.dta", gen(m_onstu) // persid should match to serial in ONS data
* 87 cases not in MTUS even when 'bad cases' kept?

keep if badcase == 0

* no eating at all
gen no_eat = 0
replace no_eat = 1 if p_eat == 0 & s_eat == 0
tab no_eat

* now anyone without a dinner skipped it (some may have not eaten at all)
gen dinner_skip = 0
replace dinner_skip = 1 if dinner == . 

tab dinner_skip no_eat, mi

replace dinner_categories = 0 if dinner_skip == 1
replace dinner_categories = -1 if no_eat == 1
lab def dinner_categories -1 "No eat" 0 "No dinner" 1 "Dinner with cooking" 2 "Dinner no cooking" 3 "Dinner out"
lab val dinner_categories dinner_categories
tab day dinner_categories

* set as survey data for descriptives
* use MTUS weight
svyset [iw= propwt]

gen work_stat = yinact // all inactive on diary day
replace work_stat= 8 if stat == 1 & yinact == . // employed
replace work_stat= 9 if stat == 2 & yinact == . // self-employed
label copy yinact work_stat
label def work_stat 8 "Employed" 9 "Self-employed", modify
lab val work_stat work_stat

local tvars "day respsex agex respmar parent work_stat"
foreach v of local tvars {
di "* Testing `v' and dinner_categories"
	svy: tab dinner_categories `v', col
}

* check two differernt weights
su propwt net_wgt
pwcorr propwt net_wgt
* hmm, they don't really correlate

egen inc_quart = cut(sumgross), group(4)

tab dinner_categories inc_quart [iw = propwt]

keep serial persid dinner_categories propwt net_wgt badcase ageh respsex day

save "/tmp/temp-data.dta", replace 
* go back to long form data
use "`where'/Data/Social Science Datatsets/Time Use 2005/processed/timeusefinal_for_archive_diary_long_v1.0.dta", clear

merge m:1 serial using "/tmp/temp-data.dta"
* drop bad cases that came in from original data
keep if _merge == 3

gen ba_hour = hh(s_faketime)
gen ba_mins = mm(s_faketime)

gen ba_hh = 0 if ba_mins < 30
replace ba_hh = 30 if ba_mins > 29
gen ba_sec = 0
* sets date to 1969!
gen s_halfhour = hms(ba_hour, ba_hh, ba_sec)
format s_halfhour %tcHH:MM
tab s_faketime ba_hour 

* code eating - NB codes are DIFFERENT to MTUS!!
gen eat = 0
replace eat = 1 if pact == 3 | sact == 3

* check distribution of eating for dinner types by weight
tab s_halfhour dinner_categories if eat == 1 [iw=propwt]
tab s_halfhour dinner_categories if eat == 1 [iw= net_wgt]

gen weekday = 0 
replace weekday = 1 if day != 1 & day!=7

tab dinner_categories weekday

* create tables for profiles for each type
forvalues c = -1/3 {
	tabout pact s_halfhour if dinner_categories  == `c' & weekday == 1 using "`rpath'/dinner_categories-`c'-main-acts-by-halfhour-weekdays.txt" [iw=propwt], replace
}

log close
