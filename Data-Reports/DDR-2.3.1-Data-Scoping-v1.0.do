**************************************************************
* Data Exploration for DEMAND Theme 2.3 - older people's mobile lives
* - focus on leisure and longer duration/special travel

* This work was funded by RCUK through the End User Energy Demand Centres Programme via the
* "DEMAND: Dynamics of Energy, Mobility and Demand" Centre (www.demand.ac.uk, http://gtr.rcuk.ac.uk/project/0B657D54-247D-4AD6-9858-64E411D3D06C)

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

local where = "/Users/ben/Documents/Work"local droot = "`where'/Data/Social Science Datatsets/"

local proot "`where'/Projects/RCUK-DEMAND/Data Reports/Project 2.3 older people mobile lives"

local logd = "`proot'/results"

local version "1.0"
* version 1.0
* household level analysis

capture log close

log using "`logd'/DDR-2.3.1-Data-Scoping-v`version'.smcl", replace

set more off

* Start with MTUS survey data

use "`droot'/MTUS/World 6/processed/MTUS-adult-aggregate-wf.dta", clear

* there will be multiple diary days in some surveys
duplicates report pid

duplicates drop pid, force

tab countrya

tab survey countrya

* UK = 37
* how many 'older people' in each survey?
* NB: this will be duplicated by
tab survey ba_age_r if countrya == 37

* MTUS episode data to look at location etc
* UK only
use "`droot'/MTUS/World 6/processed/MTUS-adult-episode-UK-only-wf.dta", clear

* descriptives
tab main eloc
tab eloc survey
tab mtrav survey
tab main eloc
tab mtrav
tabstat time, by(mtrav) s(mean n min max p5 p50 p95)
li day month year id s_starttime main sec eloc mtrav in 1/5

use "`droot'/Time Use 2000/processed/diary_data_8_long_v1.0.dta"

* more detailed time use activities
tab pact
* much more codes for location
tab wher

log close
