**************************************************************
* Process MTUS World 6 time-use data (children) for easier use in stata
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
local where "/Users/ben/Documents/Work"
local droot "`where'/Data/Social Science Datatsets/MTUS/World 6"
* location of time-use diary data
local dpath "`droot'"
local dfile "MTUS-child-episode-UK-only"

local proot "`where'/Projects/RCUK-DEMAND/Theme 1"
local rpath "`proot'/results/MTUS"

* version
local version = "v1.0"

capture log close

log using "`rpath'/DEMAND-BA-MTUS-W6-Change-Over-Time-`version'-child.smcl", replace

* make script run without waiting for user input
set more off

* get processed diary data
use "`dpath'/`dfile'-wf.dta", clear

* n episodes
tab day survey, mi

local vars "5 6 18 21 59 60 61"
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
* NB: do not sum the '1's as a large sum may simply indicate a diary where slots were 1/2 an hour - so the activity would have to fill the 1/2 hour
* and we'd get many 'laundry' acts - compared to 10 min diary where laundry might just fill 1 10 min slot
* instead register a 1 as 'at least 1 instance recorded in this half hour

local slot = 5
foreach v of local vars {
	preserve
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
		
		collapse (sum) anyhh_`l`v''* (count) count=sex, by(survey day)
		sort survey day
		outsheet using "`rpath'/DEMAND-BA-MTUS-W6-Change-Over-Time-`version'-`l`v''halfhour-child.txt", replace
		di "`v' (`l`v'') results saved"
	restore
}

* badcase == 0 [good cases]

* tabstat anyhh_laundry* if badcase == 0 & survey==1974, by(day) s(sum) c(s)
* tabstat anyhh_laundry* if badcase == 0 & survey==2005, by(day) s(sum) c(s)

* tabstat anyhh_meals_oth* if badcase == 0 & survey==1974 & eloc == 1, by(day) s(sum) c(s)
* tabstat anyhh_meals_oth* if badcase == 0 & survey==2005 & eloc == 1, by(day) s(sum) c(s)


log close
