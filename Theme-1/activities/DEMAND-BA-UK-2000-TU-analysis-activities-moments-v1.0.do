* Exploratory analysis for DEMAND
* Uses ONS Time Use 2000/1 survey to look at a moment in time

* Data available from http://discover.ukdataservice.ac.uk/catalogue/?sn=5592

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

* Saturday morning at 11:00

clear all

* change these to run this script on different PC
local where "~/Documents/Work"
local projroot "`where'/Projects/RCUK-DEMAND"
local rpath "`projroot'/Theme 1/results/ONS TU 2000"

* location of time-use diary data
local dpath "`where'/Data/Social Science Datatsets/Time Use 2000/stata/2003 release/stata8_se/"

* use the ungrossed non-response weight
* this just corrects for survey/diary non-response - we don;t need to gorss up to the population
* as we're not interested in total minutes etc
local wt = "wtdry_ug"

* version
* 1.0 = no seasonal or regional analysis
local v = "1.0"

capture log close

* save log file (with version)
log using "`rpath'/BA-UK-2000-TU-analysis-activities-moments-v`v'.smcl", replace

* use this to switch on/off the summarising below
local do_collapse 1

* make script run without waiting for user input
set more off

* get diary data
use "`dpath'/diary_data_8.dta", clear

* keep the ones deemed fit for analysis by the ONS (see user guide)
tab dry_ind

drop if dry_ind != 1

* check age distributions
tab dagegrp
* so is all sample - including children

* create our own dow to check

* see help datetime##s7
egen timestamp = concat(dday dmonth dyear), punct(/)

gen ba_ddate_stata = date(timestamp,"DMY")

lab var ba_ddate_stata "Date of diary (from "
format ba_ddate_stata %td

* Day of week
gen ba_stata_dow = dow(ba_ddate_stata)
* why does Sunday = 0??

recode ba_stata_dow (0=7), gen(ba_dow)
lab def ba_dow  1 "Monday" 2 "Tuesday" 3 "Wednesday" 4 "Thursday" 5 "Friday" 6 "Saturday" 7 "Sunday"
lab val ba_dow ba_dow
lab var ba_dow "Day of week (from date)"
drop ba_stata_dow

* check unweighted & weighted n per weekday
* NB - remember this includes all respondents and that respondents (should have) completed
* 1 diary for a weekday and 1 diary for a weekend day

* unweighted
tab ddayofwk ba_dow, mi
* so c 2,000 diaries on each weekday but nearly 5,000 on each weekend day (why?)

* weighted
tab ddayofwk ba_dow [iw= `wt'], mi

* so c 2,900 (weighted) diaries per day

* keep Saturday morning at 11:00 adults only
keep if ba_dow == 6 & dtype == 1
keep sn* dtype dday dmonth dyear ddayofwk ba_* *_043

* How many respondents per Saturday?
tab ba_ddate_stata

preserve
	collapse (count) obs=ba_dow (mean) ba_dow, by(ba_ddate_stata)
	su obs, de
	collapse (count) obs, by(ba_dow)
restore

* and per month just of Saturdays?
tab dmonth

* Saturday @ 11:00 = slot 43
* collapse to each Saturday
* contract ba_ddate_stata act1_043, percent(_pc)

* collapse to all saturdays per month
contract dmonth act1_043, freq(pact)

reshape wide pact, i(dmonth) j(act1_043)

*tsset ba_ddate_stata

*keep if tin(01jul2000, 01jul2001)

lab var pact110 "sleep"
lab var pact310 "wash and dress"

graph bar pact*, over(dmonth) title("11:00 Saturday") ytitle("N") stack

export excel using "`rpath'/ONS-TU-2000-activity-saturdays.xls", firstrow(varlabels) replace



log close


