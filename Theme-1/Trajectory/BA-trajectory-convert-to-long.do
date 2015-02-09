* (c) b.anderson@soton.ac.uk
* code to convert trajectory time use data to long form

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

local where "/Users/ben/Documents"
local droot "`where'/Work/Projects/RCUK-DEMAND/Theme 1/data/Time Use/Trajectory-Oxford"

use "`droot'/Geography of Time - final data-half.dta", clear

* the first line is the variable labels (annoying!)
drop in 1

set more off

*do "`droot'/apply-labels.do"

foreach t of numlist 1/9 {
	rename TS00`t'_MA pact`t'
	rename TS00`t'_LAT lat`t'
	rename TS00`t'_LONG lon`t'
	rename TS00`t'_TP tp`t'
}

foreach t of numlist 10/99 {
	rename TS0`t'_MA pact`t'
	rename TS0`t'_LAT lat`t'
	rename TS0`t'_LONG lon`t'
	rename TS0`t'_TP tp`t'
}

* ignore the 145th time slot!
* diary runs 02:00 - 02:00 (not 01:50) for some reason
foreach t of numlist 100/144 {
	rename TS`t'_MA pact`t'
	rename TS`t'_LAT lat`t'
	rename TS`t'_LONG lon`t'
	rename TS`t'_TP tp`t'
}

* convert to long format and set up stata time variable
* create a uniq id (for matching)
egen serial = concat(subsid responseid), punct("_")
* for xt commands - can't be a string for some reason
egen xtserial = concat(subsid responseid), punct("0")
destring xtserial, force replace

save "`droot'/Trajectory data 650, Feb 2014-purchased-labelled.dta", replace

* keep the key variables only
keep *serial pact* lat* lon* tp* dtskwd dscity C*

reshape long pact lat lon tp, i(serial)

rename _j t_slot
* t_slot now has values 1 -> 144 (10 minute slots)
lab var t_slot "Time slot number (1-144)"
lab var serial "Case ID"
lab var pact "Primary act recorded"
destring lat, replace force
lab var lat "Latitude recorded"
destring lon, replace force
lab var lon "Longitude recorded"

* calculate minute from slot (end of slot)
gen min = mod(t_slot,6)
gen t_min = "50" if min == 0
replace t_min = "00" if min == 1
replace t_min = "10" if min == 2
replace t_min = "20" if min == 3
replace t_min = "30" if min == 4
replace t_min = "40" if min == 5

* which hour is it?
gen t_hour = ceil(t_slot/6)
* diary starts at 02:00
* NB this puts > 01:00 to the start of the diary day - remember this if doing sequences through 02:00
* also some charts will show discontinuities at 02:00
* 24 = 00
* 25 = 01
* set correct hour
replace t_hour = t_hour + 1
* set 25 to 01
replace t_hour = 1 if t_hour == 25
replace t_hour = 0 if t_hour == 24
* check
li t_slot t_hour min t_min in 1/12

* now turn this into a real hour
gen d_hour = t_hour
lab var d_hour "Hour"
gen d_min = t_min
lab var d_min "Minute"

tostring t_hour, replace force
foreach h of numlist 1/9 {
	replace t_hour = "0`h'" if t_hour == "`h'"
}


* create a text time variable
egen t_time = concat(t_hour t_min), punct(":")
lab var t_time "Time of day (10 mins)"

destring t_min, force replace
destring t_hour, force replace

recode t_min (0/29 = "00") (30/59 = "30"), gen(t_hhmin)
egen t_halfhour = concat(t_hour t_hhmin), punct(":")
lab var t_halfhour "Time of day (half hours)"

* create a fake stata time - NB this sets date to 1/1/1960!
gen double s_starttime = clock(t_time,"hm")
format s_starttime %tcHH:MM
lab var s_starttime "Time of day slot starts"

* create a fake stata time - NB this sets date to 1/1/1960!
gen double s_halfhour = clock(t_halfhour,"hm")
format s_halfhour %tcHH:MM
lab var s_halfhour "Time of day (half hours)"

li s_* t_* d_* in 1/10

drop d_* t_*

compress

save "`droot'/Trajectory data 650, Feb 2014-purchased-labelled-long.dta", replace

