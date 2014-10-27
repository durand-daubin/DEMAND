* Analyse sequences in ONS 2005 (long)

* data already in long format

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
local droot "`where'/Data/Social Science Datatsets/Time Use 2005"
* location of time-use diary data
local dpath "`droot'/processed"

local proot "`where'/Projects/RCUK-DEMAND/Theme 1"
local rpath "`proot'/results/ONS TU 2005"

local version = "v1.0"

set more off

capture log close

log using "`rpath'/DEMAND-BA-UK-2005-TU-sequence-analysis-`version'.smcl", replace

use "`dpath'/timeusefinal_for_archive_diary_long_v2.0.dta", clear

gen ba_weekday = 0
replace ba_weekday = 1 if s_dow > 0 & s_dow < 6

tab ba_weekday s_dow

format s_faketime %tcHH:MM
lab var s_faketime "Time of day"
			
* labels
lab def t_month 2 "February" 6 "June" 9 "September" 11 "November"
lab val t_month t_month

gen s_hour = hh(s_faketime)
gen s_mins = mm(s_faketime)

* day of week & time of day
gen ba_daytime = 0
replace ba_daytime = 1 if s_hour > 7 & s_hour < 23

tab ba_daytime ba_weekday, mi

sqset pact serial s_faketime

* table of all sequences
sqtab, ranks(1/10)

* keep 07:00 - 23:00 only for now to avoid wrong day problems
preserve
	keep if ba_daytime == 1 & ba_weekday == 1
	tab ba_daytime ba_weekday, mi
	* table of all sequences during day on weekdays
	sqtab, ranks(1/10)
restore

log close
