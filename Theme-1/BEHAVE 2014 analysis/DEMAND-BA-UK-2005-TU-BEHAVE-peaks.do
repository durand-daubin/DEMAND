* DEMAND Project (www.demand.ac.uk)
* Analyse ONS Time Use 2005 dataset
* Data available from http://discover.ukdataservice.ac.uk/catalogue/?sn=5592

* Analysis for BEHAVE 2014 conference presentation on components of peak

* local version = "v1.0"

local version = "v2.0"
* switched to v2 of the 2005 time use data to enable analysis of more categories - especially cooking during peaks


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
local droot "`where'/Data/Social Science Datatsets/Time Use 2005"

local proot "`where'/Projects/RCUK-DEMAND/Theme 1"
local rpath "`proot'/results/ONS TU 2005"

set more off

capture log close

log using "`rpath'/DEMAND-BA-UK-2005-TU-BEHAVE-peaks-`version'.smcl", replace

use "`droot'/processed/timeusefinal_for_archive_diary_long_v2.0.dta", clear

* merge in the survey file
merge m:1 serial using "`droot'/processed/timeusefinal_for_archive_survey_v2.0.dta", keepusing(ageh respsex)

gen weekday = 0 
replace weekday = 1 if s_dow != 1 & s_dow!=7

* create tables 
* yes, stata could create these as charts but I like to import to excel & fiddle :-)

* at home only
* age
tabout pact s_halfhour using "`rpath'/main-acts-at-home-by-s_halfhour-16-65-weekdays-`version'.txt" [iw=net_wgt ] if lact == 1 & ageh <= 10 & weekday == 1, replace
tabout pact s_halfhour using "`rpath'/main-acts-at-home-by-s_halfhour-65+-weekdays-`version'.txt" [iw=net_wgt ] if lact == 1 & ageh > 10 & weekday == 1, replace
* gender
tabout pact s_halfhour using "`rpath'/main-acts-at-home-by-s_halfhour-men-weekdays-`version'.txt" [iw=net_wgt ] if lact == 1 & respsex == 1 & weekday == 1, replace //men
tabout pact s_halfhour using "`rpath'/main-acts-at-home-by-s_halfhour-women-weekdays-`version'.txt" [iw=net_wgt ] if lact == 1 & respsex == 2 & weekday == 1, replace //women

levelsof(s_dow), local(days)

foreach d of local days {
	di "* testing day `d'"
	qui: tabout pact s_halfhour using "`rpath'/main-acts-at-home-by-s_halfhour-all-day-`d'-`version'.txt" [iw=net_wgt ] if lact == 1 & s_dow == `d', replace
}

log close
