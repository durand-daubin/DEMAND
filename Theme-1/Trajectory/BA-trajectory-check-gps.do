* (c) b.anderson@soton.ac.uk
* code to check trajectory time use data GPS 
* uses to long form

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

local where "~/Documents"
local droot "`where'/Work/Projects/RCUK-DEMAND/Theme 1/data/Time Use/Trajectory-Oxford"

clear all

use "`droot'/Trajectory data 650, Feb 2014-purchased-labelled-long.dta", clear

capture log close

log using "`droot'/BA-check-trajectory-gps.smcl", replace

set more off

* merge back in original file keeping the variables we want
merge m:1 serial using "`droot'/Trajectory data 650, Feb 2014-purchased-labelled.dta", keepusing(C* Q*)

local location = "lat lon"

* NB - remember that some of these diary days are pairs (1 weekday, 1 weekend day) for a given
* respondent.
* This is therefore analysis by diary day

* set up max/min, mdeviation, range

foreach l of local location {
	bysort xtserial: egen `l'_max = max(`l')
	bysort xtserial: egen `l'_min = min(`l')
	bysort xtserial: egen `l'_mdev = mdev(`l')
	gen `l'_range = `l'_max - `l'_min
	
	* set home lat/long
	gen home_`l' = `l' if t_time == "03:00"
	* create a constant across serial which is this value (could have used mean instead)
	bysort xtserial: egen home_`l'm = mode(home_`l')

	* calculate max distance from home - use absolute as don't care direction
	gen dist_from_home_`l' = abs(home_`l'm - `l')
	gen at_home_`l'1km = 0
	* these values are for lat (may need different values for lon - if precision matters)
	replace at_home_`l'1km = 1 if  dist_from_home_`l' < 0.01
	gen at_home_`l'100m = 0
	replace at_home_`l'100m = 1 if  dist_from_home_`l' < 0.001
}

gen travp_home1km_err = tp if tp != . & at_home_lat1km == 1
gen travp_home100m_err = tp if tp != . & at_home_lat100m == 1

gen at_home100m = 0
replace at_home100m = 1 if at_home_lat100m == 1 & at_home_lon100m == 1
lab var at_home100m "At home (within 100m of 03:00)"

gen at_home1km = 0
replace at_home1km = 1 if at_home_lat1km == 1 & at_home_lon1km == 1
lab var at_home1km "At home (within 1km of 03:00)"

tab dtskwd

gen weekday = 1
replace weekday = 0 if dtskwd == 1 | dtskwd == 7

preserve
	* weekdays
	keep if weekday == 1
	collapse (mean) lat_* lon_* at_home100m at_home1km , by(s_faketime C20)
	replace at_home100m = at_home100m*100
	replace at_home1km = at_home1km*100

	lab var at_home100m "% at home (within 100m of 03:00)"
	lab var at_home1km "% at home (within 1km of 03:00)"

	* trick stata into overlaying the different employment types
	xtset C20 s_faketime, delta(10 mins)
	xtline at_home*, byopts(note("Weekdays")) name(xtl_a_home_by_empl)
	graph export "`droot'/xtl_at_home_by_empl_weekdays_all.png", replace
restore

preserve
	* weekdays & day is typical
	keep if weekday == 1 & Q9 == 1
	collapse (mean) lat_* lon_* at_home100m at_home1km , by(s_faketime C20)
		replace at_home100m = at_home100m*100
	replace at_home1km = at_home1km*100

	lab var at_home100m "% at home (within 100m of 03:00)"
	lab var at_home1km "% at home (within 1km of 03:00)"

	* trick stata into overlaying the different employment types
	xtset C20 s_faketime, delta(10 mins)
	xtline at_home*, byopts(note("Weekdays, Q9 = 'typical day'")) name(xtl_a_home_by_emplt)
	graph export "`droot'/xtl_at_home_by_empl_weekdays_typical.png", replace
restore


preserve
	* keep daytime only (6:00-23:00)
	keep if d_hour >= 6 & d_hour <= 23
	* add up number of times at home during the day per respondent
	bysort serial: egen at_home1km_count = total(at_home1km)
	bysort serial: egen at_home100m_count = total(at_home100m)
	collapse (mean) at_home1km at_home100m *count (count) n_slots=lat , by(xtserial C20 Q9 dtskwd weekday)
		su n_slots
		gen at_home100m_pc = at_home100m_count/n_slots
		gen at_home1km_pc = at_home1km_count/n_slots
		su *_pc, de
		di "% of day at home if day is 'normal' and is a weekday"
		tabstat *_pc if weekday == 1 & Q9 == 1, by(C20)
		
		gen always_home100m = 0
		replace always_home100m = 1 if at_home100m_pc == 1 
		gen always_home1km = 0
		replace always_home1km = 1 if at_home1km_pc == 1
		di "*********************"
		di "* check always home"
		tab C20 always_home100m if weekday == 1 & Q9 == 1, row
		graph hbox at_home100m_pc if weekday == 1, over(C20) by(Q9) name(at_home100m_pc)
		graph export "`droot'/hbox_at_home100m_pc_weekdays_typical.png", replace
		tab C20 always_home1km if weekday == 1 & Q9 == 1, row
		graph hbox at_home1km_pc if weekday == 1, over(C20) by(Q9) name(at_home1km_pc)
		graph export "`droot'/hbox_at_home1km_pc_weekdays_typical.png", replace

		di "*********************"
		di "* N days by day of week & 'typical day'"
		tab C20 dtskwd if Q9 == 1
		table C20 dtskwd if Q9 == 1, c(mean at_home100m)
		table C20 dtskwd if Q9 == 1, c(mean at_home1km)
		
		tab Q9
restore

* draw xtlines for each diary day by employment status for those
* where this was a normal day
xtset xtserial s_faketime, delta(10 mins)
* cycle over weekdays so charts are legible
local weekdays "2 3 4 5 6"
local d2l "Mondays"
local d3l "Tuesdays"
local d4l "Wednesdays"
local d5l "Thursdays"
local d6l "Fridays"

foreach d of local weekdays {
	xtline at_home1*m if dtskwd == `d' & Q9 == 1 & C20 == 1, ///
		byopts(note("`d`d'l', full-time employed, day = typical, 1 = at home, 0 = not at home")) name(xtl_`d'_emplftwdtyp)
	graph export "`droot'/`d`d'l'_xtl_at_home_emplft_weekdays_typical.png", replace
	graph export "`droot'/`d`d'l'_xtl_at_home_emplft_weekdays_typical.pdf", replace
}

table s_faketime dtskwd if Q9 == 1 & C20 == 1, c(mean at_home100m)
table s_faketime dtskwd if Q9 == 1 & C20 == 1, c(mean at_home1km)

table C20 dtskwd if Q9 == 1 & d_hour >= 6 & d_hour <= 23, c(mean at_home100m)
table C20 dtskwd if Q9 == 1 & d_hour >= 6 & d_hour <= 23, c(mean at_home1km)

log close
