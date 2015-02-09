* DEMAND Project (www.demand.ac.uk)

* Analysis for BEHAVE 2014 conference presentation with mathieu.durand-daubin@edf.fr

* Use MTUS (see http://www.timeuse.org/mtus/) version of ONS UK 2005 time use survey to get episodes of cooking & eating
* Use this to work out what kinds of 'dinner' we have & classify the diary days accordingly
* match the diary days/diarists back to the original ONS TU 2005 data from the UK data archive (http://discover.ukdataservice.ac.uk/catalogue/?sn=5592) to see what the different dinner 'types' were doing through the day

* Results presentation: http://www.slideshare.net/ben_anderson/behave-practices-hunting5

* This work was funded by RCUK through the End User Energy Demand Centres Programme via the
* "DEMAND: Dynamics of Energy, Mobility and Demand" Centre (www.demand.ac.uk, gow.epsrc.ac.uk/NGBOViewGrant.aspx?GrantRef=EP/K011723/1)

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
local droot "`where'/Data/Social Science Datatsets/MTUS/World 6/"
* location of time-use diary data
local dpath "`droot'/processed"

local proot "`where'/Projects/RCUK-DEMAND/Theme 1"
local rpath "`proot'/results/ONS TU 2005"

* main; sec:

* meals at work or school = 5
* meals or snacks in other places = 6
* food preparation, cooking = 18
* restaurant, café, bar, pub = 39 (but may not be eating?!)
* eloc = location

local version = "v1.0"

set more off

capture log close

log using "`rpath'/DEMAND-BA-UK-2005-TU-MTUS-BEHAVE-eating-`version'.smcl", replace

* start with MTUS data
* NB this is a UK only subsample with some derived variables added

use "`dpath'/MTUS-adult-episode-UK-only-wf.dta", clear
* data in long/episode format

gen ba_weekday = 0
replace ba_weekday = 1 if ba_dow < 6

gen ba_hour = hh(s_starttime)
gen ba_mins = mm(s_starttime)

gen ba_hh = 0 if ba_mins < 30
replace ba_hh = 30 if ba_mins > 29
gen ba_sec = 0
* sets date to 1969!
gen s_halfhour = hms(ba_hour, ba_hh, ba_sec)
format s_halfhour %tcHH:MM

* keep 2005
keep if survey == 2005

* drop bad cases
keep if badcase == 0

* sleep (surely everyone reports it?!) - use this as a checker later on
gen sleep = 0
replace sleep = 1 if main == 2 | sec == 2

* set up eating dummies
* 5 not set for 2005
* note that this could have several sequential episodes of eating if something else changed e.g. primary <-> secondary
gen eat = 0
replace eat = 1 if main == 6 | sec == 6

* calculate duration
bysort diarypid: gen eat_duration = time if eat == 1
su eat_duration
* add on duration if previous and subsequent episodes are also eat
bysort diarypid: replace eat_duration = eat_duration + time[_n-1] if eat == 1 & (main[_n-1] == 6 | sec[_n-1] == 6) & eloc == eloc[_n-1]
bysort diarypid: replace eat_duration = eat_duration + time[_n+1] if eat == 1 & (main[_n+1] == 6 | sec[_n+1] == 6) & eloc == eloc[_n+1]
su eat_duration

* same for cooking
gen cook = 0
replace cook = 1 if main == 18 | sec == 18
bysort diarypid: replace cook = 1 if cook == 1 & (main[_n-1] == 18 | sec[_n-1] == 18) & eloc == eloc[_n-1]
bysort diarypid: replace cook = 1 if cook == 1 & (main[_n+1] == 18 | sec[_n+1] == 18) & eloc == eloc[_n+1]

tab ba_weekday ba_dow

* check no obs:
tab s_halfhour if main == 5 & survey == 2005

* if try to tab by survey you get jitter/spikes due to different time slot durations used in each year
* so need to construct a halfhour variable (same as Mathieu)
tab s_halfhour eat if survey == 2005
tab s_halfhour cook if survey == 2005

table s_halfhour ba_dow if survey == 2005, c(mean eat)
graph bar (mean) eat, over(s_halfhour) name(bar_eat) 

* so we need to start UK dinner earlier - about 17:00
* but end about 22:00?

* check for non-eaters and non-sleepers
preserve
	collapse (mean) eat sleep, by(persid)
	* how many don't eat?
	tab eat if eat == 0, mi
	* how many don't sleep?
	tab sleep if sleep == 0, mi
restore

* now find the cooking that came before the dinner (if there was any)

* this keeps the eating and cooking episodes only
keep if eat == 1 | cook == 1
* make sure they're in order
sort persid epnum
* in this dataset there is 1 diary day per person so persid gives a uniq id
* this is not the case in other surveys - where there may be multiple days per diary so beware!
* keepo badcase to be able to distinguish between bad cases and non-eaters below
keep persid epnum s_* ba_* badcase main sec eloc eat* cook 
* don't do dinner skip here as this is setting any kind of eat to 'dinner_skip'

* define dinner as starting to eat 17:00 - 22:00
* ?: should we define an end time?
gen dinner = 0 if eat == 1
replace dinner = 1 if eat == 1 & ba_hour >= 17 & ba_hour <= 22

* who goes out for dinner?
* this is going to be underestimated as we never have eating defined as a primary or secondary activity when 
* the primary or secondary activity is "restaurant, cafe, bar, pub" 
* (which should really have been coded as location not activity!)
gen dinner_out = 1 if dinner == 1 & eloc != 1
gen dinner_out_dur = eat_duration if dinner_out == 1

* so, which dinners have cook before or during them?
by persid: gen dinner_cook = 1 if dinner == 1 & dinner_out != 1 & (cook[_n-1] == 1 | cook == 1)
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
