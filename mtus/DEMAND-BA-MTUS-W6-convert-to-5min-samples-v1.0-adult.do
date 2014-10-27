**************************************************************
* Covert MTUS World 6 time-use data (UK subset) to a slot-based file using sampling
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

* logic = sample at small minute intervals (e.g. 5) - what was happening?
* 5 is a good number as most diaries are in multiples of 5 (10, 15, 30 etc)
* if activity was happening record 1
* then aggregate to e.g. half hours
* NB: do not sum the '1's as a large sum may simply indicate a diary where slots were 1/2 an hour - so the activity would have to fill the 1/2 hour
* and we'd get many 'laundry' acts - compared to 10 min diary where laundry might just fill 1 10 min slot
* instead register a 1 as 'at least 1 instance recorded in this half hour

local slot = 5
* use max to control
local max = 69
* use the new MTUS 69 category codes
foreach c of numlist 1/`max' {
	*preserve
		* remove bad cases and keep only records of this activity
		keep if badcase == 0 & main == `c'
		gen slot = 0
		gen min = 0
		gen act = .
		di "* Checking for category: `c'"
		foreach m of numlist 0(`slot')1440 {
			*di "* Checking `m' for `c'"
			local h = `m'/`slot'
			*replace slot = `m'
			*replace min = `h'
			replace slot = `h' if main == `c' & `m' >= ba_startm & `m' <= end
			replace act = `c' if main == `c' & `m' >= ba_startm & `m' <= end
		}
		stop
		* summarise to 15 mins from whatever we created above
		local sumto = 15
		* we used 5 mins so n slots = 288
		* n per 15 mins = 3
		foreach hh of numlist 0(3)282 {
			gen any`sumto'_`c'_min`hh' = 0
			*di "* checking `c' (base period = `hh')"
			* this will record a 1 (yes) if there is any recorded c in this period
			foreach s of numlist 0(1)2 {
				local sl = `hh' + `s'
				*di "checking slot `sl' (base = `hh')"
				* record 1 if any `c' in this 5 minutes
				qui: replace any`sumto'_`c'_min`hh' = 1 if any_`c'_min`sl' == 1 
			}
		}
		
		* collapse to 15 mins
		* if we do this to 5 mins it takes a long time
		* inlcude the by variables we'll need to do the subsequent collapse for the table
		collapse (sum) any`sumto'_`c'_min*, by(age sex day survey diarypid)
		save "`droot'/tmp/MTUS-W6-Adult-UK-only-`version'-main_act`c'-`slot'mins.dta", replace
		* turn it round
*		reshape long any_`c'_min, i(diarypid) j(hhslot)
		
		
		di "Category `c' results saved"
	restore
}
stop

* use the 5 min data code 1
use "`droot'/tmp/MTUS-W6-Adult-UK-only-`version'-main_act1-5mins.dta", clear
foreach c of numlist 1/`max' {
	merge 1:1 using `droot'/tmp/MTUS-W6-Adult-UK-only-`version'-main_act1-5mins.dta, gen(_m`c')
}
save "`droot'/tmp/MTUS-W6-Adult-UK-only-`version'-main_acts-5mins.dta", replace





* tell it to look at sequences of laundry
sqset anyhh_laundry diarypid hhslot

* top 20 sequences
sqtab survey, ranks(1/20) 

log close
