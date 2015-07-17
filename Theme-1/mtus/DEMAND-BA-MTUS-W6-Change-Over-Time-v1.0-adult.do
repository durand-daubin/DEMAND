**************************************************************
* Process MTUS World 6 time-use data (adults) for easier use in stata
* - www.timeuse.org/mtus

* data already in long format (but episodes)

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
local where "~/Documents/Work"
local droot "`where'/Data/Social Science Datatsets/MTUS/World 6"
* location of time-use diary data
local dpath "`droot'"
local dfile "MTUS-adult-episode-UK-only"

local proot "`where'/Projects/RCUK-DEMAND/Theme 1"
local rpath "`proot'/results/MTUS"

* version
local version = "v1.0"

capture log close

log using "`rpath'/DEMAND-BA-MTUS-W6-Change-Over-Time-`version'-adult.smcl", replace

* make script run without waiting for user input
set more off

* get processed diary data
use "`dpath'/`dfile'-wf.dta", clear

* merge selected variables from aggregated data
* merge m:1 countrya survey swave msamp hldid persid id using "`dpath'/MTUS-adult-aggregate-UK-only.dta", ///
*	keepusing(main7 main8 empstat emp unemp student retired) gen(m_aggvars)
* this appears not to match 1995 & 2005??
* tab m_aggvars survey

gen ba_weekday = 0
replace ba_weekday = 1 if ba_dow < 6

* main7 & main8 = paid work
*gen ba_4hrspaidwork = 0
* mark those who worked more than 4 hours that day
*replace ba_4hrspaidwork = 1 if main7 > 240

* n episodes
tab day survey, mi

* leave this empty to skip the (time consuming) aggregations & table outputs
local vars "21"
local l5 "meals_work"
local l6 "meals_oth"
local l18 "food_prep"
local l21 "laundry"
local l59 "tv_video"
local l60 "computer_games"
local l61 "computer_internet"

* logic = sample at small minute intervals (e.g. 5) - what was happening?
* 5 is a good number as most diaries are in multiples of 5 (10, 15, 30 etc)
* if activity was happening record 1
* then aggregate to e.g. half hours
* NB: 
* summing the '1's is dodgy 
* - in a 10 min diary laundry might just fill 1 10 min slot -> sum = 1
* - in a 1/2 hour diary a 1 might mean all 30 minutes
* => register a 1 as "at least 1 instance recorded in this half hour"

local slot = 5
foreach v of local vars {
	preserve
		* remove bad cases
		keep if badcase == 0
		di "* Checking for `v' (`l`v'')"
		foreach m of numlist 0(`slot')1440 {
			*di "* Checking `m' for `v' (`l`v'')"
			local h = `m'/`slot'
			gen any_`l`v''`h' = 0
			* this will catch any instance of laundry which starts in the half hour
			* creates a new variable for each slot
			* gen any_laundry0 = 1 if main == 21 & start_mins_from00 >= 0 & end_mins_from00 <= 60
			* we're in a period of v 'now'
			qui: replace any_`l`v''`h' = 1 if main == `v' & `m' >= ba_startm & `m' <= end
		}
		* summarise to half hours from whatever we created above
		* we used 5 mins so n slots = 288
		* n per half hour = 6
		foreach hh of numlist 0(6)282 {
			gen anyhh_`l`v''`hh' = 0
			*di "* checking `l`v'' (base half hour = `hh')"
			foreach s of numlist 0(1)5 {
				local sl = `hh' + `s'
				*di "checking slot `sl' (base = `hh')"
				* record 1 if any `v'
				qui: replace anyhh_`l`v''`hh' = 1 if any_`l`v''`sl' == 1 
			}
		}
		* collapse to diaryid for sequence analysis (i.e. at half hour level)
		* include the by variables we'll need to do the subsequent collapse for the table
		collapse (sum) anyhh_`l`v''* (count) count=epnum, by(age sex day survey diarypid)
		save "`rpath'/MTUS-W6-Adult-UK-only-`version'-`l`v''halfhour.dta", replace
		local byvars "survey day"
		* collapse to make tables
		collapse (sum) anyhh_`l`v''* (count) count=sex, by(`byvars')
		sort survey day
		outsheet using "`rpath'/DEMAND-BA-MTUS-W6-Change-Over-Time-`version'-`l`v''halfhour-adult-`byvars'.txt", replace
		di "`v' (`l`v'') results saved"
	restore
}

* badcase == 0 [good cases]

* tabstat anyhh_laundry* if badcase == 0 & survey==1974, by(day) s(sum) c(s)
* tabstat anyhh_laundry* if badcase == 0 & survey==2005, by(day) s(sum) c(s)

* tabstat anyhh_meals_oth* if badcase == 0 & survey==1974 & eloc == 1, by(day) s(sum) c(s)
* tabstat anyhh_meals_oth* if badcase == 0 & survey==2005 & eloc == 1, by(day) s(sum) c(s)

* sequences
* we can't use the lag notation and xtset as there are various time periods represented in the data
* and we want to use episodes not time slots (as we are ignoring duration here)

gen any_laundry = 0
replace any_laundry = 1 if main == 21
* make sure we do this within diaries
bysort diarypid: gen before_laundry = main[_n-1] if any_laundry == 1
bysort diarypid: gen after_laundry = main[_n+1] if any_laundry == 1

lab val before_laundry after_laundry MAIN

tab before_laundry if badcase == 0
tab before_laundry survey if badcase == 0, col nof

tab after_laundry if badcase == 0
tab after_laundry survey if badcase == 0, col nof

* try using the sqset commands
* use the half hour data
use "~/Documents/Work/Projects/RCUK-DEMAND/Theme 1/results/MTUS/MTUS-W6-Adult-UK-only-v1.0-laundryhalfhour.dta", clear

* turn it round
reshape long anyhh_laundry, i(diarypid) j(hhslot)

* tell it to look at sequences of laundry
sqset anyhh_laundry diarypid hhslot

* top 20 sequences
sqtab survey, ranks(1/20) 

log close
