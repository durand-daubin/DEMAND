* Process Loughbourough 1 minute resolution data

* http://discover.ukdataservice.ac.uk/catalogue?sn=6583

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

local projroot "`where'/Work/Projects/RCUK-DEMAND/Theme 1"
local idpath "`where'/Work/Data/Social Science Datatsets/6583 - One-Minute Resolution Domestic Electricity Use Data 2008-2009/"
local do_path "`projroot'/do_files"
local rpath "`projroot'/results/UKDA-6583-1-min"

* v1.0 = census day 2008
local vers "v1.0"

capture log close
set more off

log using "`rpath'/DEMAND-Diversity-UKDA-6583-1-min-res-data-`vers'-$S_DATE.smcl", replace

clear all

* control what is run
local do_basics 1

************************
* start with survey data working file
use "`idpath'/processed/UKDA-6583-survey-data-wf.dta", clear

* keep useful variables
keep hh_id ba_*

* add energy data (filled, full) but spring 2008 only
merge 1:m hh_id using "`idpath'/processed/UKDA-6583_power_all_years_all_hhs_long_fillfull_wf_Feb_Jun_2008.dta"

/*
NB: User Guide states
DATETIME_GMT  - The time stamp of the meter reading as Greenwich Mean Time (GMT).
DATETIME_LOCAL  - The time stamp of the reading taking British Summer Time (BST) into account.
IMPORT_KW  The mean power demand during the one?minute period starting at the time stamp.
The date time fields are formatted as <YEAR>/<MONTH>/<DAY> <HOUR>:<MINUTE>.
Where data is not available for a given minute, no row exists in the file. 
Note that no data is available for two of the meters in 2009, and hence two of the files are empty.
*/

*****************
* Do some missing data checks

* this should alreay be set
* xtset hh_id timestamp_gmt, delta(1 minute)
* make sure

xtset
 
if `do_basics' == 1 {
	
	di "* -> Running basic tod analysis as do_basics = `do_basics' "
	*****************
	* collapse to 15 mins keeping dow
	
	
	* March - but exclude 30th as clocks changed ('census day')
	keep if tin(1mar2008 00:00,29mar2008 00:00)
	collapse (count) n_obs=import_kw n_hhids=hh_id ///
		(sum) sum_power=import_kw n_zeros=import_kw_z ba_missing_obs ///
		(mean) mean_power=import_kw (sd) sd_power=import_kw ///
		(p50) p50_power= import_kw (p5) p5_power=import_kw (p25) p25_power=import_kw ///
		(p75) p75_power=import_kw (p95) p95_power=import_kw ///
		, by(ba_15m_slot ba_dow)
		
	sort ba_dow ba_15m_slot
	
	lab def ba_dayofweek 1 "Monday" 2 "Tuesday" 3 "Wednesday" 4 "Thursday" 5 "Friday" 6 "Saturday" 7 "Sunday"
	lab val ba_dow ba_dayofweek
	
	by ba_dow : egen ba_slot_n = seq()
	lab var ba_slot_n "15 minute time slot"

	* simple line
	twoway line mean_power p50_power ba_slot_n, name(line_tod_power_mar08) by(ba_dow, note("Date: March 1-29 2008")) ///
		yaxis(1) ytitle("Kw") xtitle("Time of Day") `xldformat' `yld1format' ///
		legend(size(vsmall)) ///
		|| scatter sd_power ba_slot_n, msize(tiny) yaxis(2) `yld2format'
	graph export "`rpath'/graphs/line_power_sd_15m_dow_mar08.png", replace
		
	* put mean & sd & median over 5% - 95% (middle 90%) range
	twoway rarea p5_power p95_power ba_slot_n, name(rarea_tod_powerp5_95_mar08) color(dimgray) by(ba_dow, note("Date: March 1-29 2008")) ///
		yaxis(1) ytitle("Kw") xtitle("Time of Day") `xldformat' `yld1format' ///
		legend(size(vsmall)) ///
		|| line mean_power p50_power ba_slot_n ///
		|| scatter sd_power ba_slot_n, msize(tiny) yaxis(2) `yld2format'
	graph export "`rpath'/graphs/rarea_p5-95power_15m_dow_mar08.png", replace
	
	* put mean & sd & median over 25% - 75% (middle 50%) range
	twoway rarea p25_power p75_power ba_slot_n, name(rarea_tod_p25_75power_mar08) color(dimgray) by(ba_dow, note("Date: March 1-29 2008")) ///
		yaxis(1) ytitle("Kw") xtitle("Time of Day") `xldformat' `yld1format' ///
		legend(size(vsmall)) ///
		|| line mean_power p50_power ba_slot_n ///
		|| scatter sd_power ba_slot_n, msize(tiny) yaxis(2) `yld2format'	
	graph export "`rpath'/graphs/rarea_p25-75power_15m_dow_mar08.png", replace

	di "* keep Wednesday & Sunday"
	
	keep if ba_dow == 3 | ba_dow == 7
	
	* re-drawn & simplify for DECC meeting 10/12/2013
	twoway line p50_power ba_slot_n, name(line_tod_mar08_for_DECC) by(ba_dow, note("Date: March 1-29 2008")) ///
		yaxis(1) ytitle("Kw") xtitle("Time of Day") `xldformat' `yld1format' ///
		legend(size(vsmall)) ///
		|| scatter sd_power ba_slot_n, msize(tiny) yaxis(2) `yld2format'	
	graph export "`rpath'/graphs/line_tod_mar08_for_DECC.png", replace
	
	* dump data for excel charting
	outsheet ba_15m_slot p50_power sd_power ba_dow using "`rpath'/data-sheet.txt", replace 
	
	/*
	***************
	* re-do just for 'census day'
	
	preserve
	
		* Try census day only (= Sunday)
		keep if tin(30mar2008 00:00,30mar2008 23:59)
		collapse (count) n_obs=import_kw n_hhids=hh_id ///
			(sum) sum_power=import_kw n_zeros=import_kw_z ba_missing_obs ///
			(mean) mean_power=import_kw ba_accom ba_npeople (sd) sd_power=import_kw ///
			(p50) p50_power= import_kw (p5) p5_power=import_kw (p25) p25_power=import_kw ///
			(p75) p75_power=import_kw (p95) p95_power=import_kw ///
			, by(ba_15m_slot ba_dow)
		
		*xtset hh_id ddate_gmt
		* need to convert ddate_gmt hh_id ba_hh_slot to a time
		
		sort ba_dow ba_15m_slot
		by ba_dow : egen ba_slot_n = seq()
		lab var ba_slot_n "15 minute time slot"
		
		* simple line
		twoway line mean_power p50_power ba_slot_n, name(line_power_census08) ///
			yaxis(1) ytitle("Kw") xtitle("Time of Day") `xldformat' `yld1format' ///
			legend(size(vsmall)) note("Date: March 30 (Sunday) 2008") ///
			|| scatter sd_power ba_slot_n, msize(tiny) yaxis(2) `yld2format'
		graph export "`rpath'/graphs/line_power_sd_15m_30_3_08.png", replace
	
		* put mean & sd & median over 25% - 75% (middle 50%) range
		twoway rarea p5_power p95_power ba_slot_n, name(rarea_p5_95_power_census08) color(dimgray) yaxis(1) ///
			ytitle("Kw") xtitle("Time of Day") `xldformat' `yld1format' color(dimgray) ///
			legend(size(vsmall)) note("Date: March 30 (Sunday) 2008") ///
			|| line mean_power p50_power ba_slot_n ///
			|| scatter sd_power ba_slot_n, msize(tiny) yaxis(2) `yld2format'
		graph export "`rpath'/graphs/rarea_p5_95power_15m_30_3_08.png", replace
		
		twoway rarea p25_power p75_power ba_slot_n, name(rarea_p25_75_power_census08) color(dimgray) yaxis(1) ytitle("Kw") xtitle("Time of Day") `xldformat' `yld1format' color(dimgray) ///
			legend(size(vsmall)) note("Date: March 30 (Sunday) 2008") ///
			|| line mean_power p50_power ba_slot_n ///
			|| scatter sd_power ba_slot_n, msize(tiny) yaxis(2) `yld2format'
		graph export "`rpath'/graphs/rarea_p25_75power_15m_30_3_08.png", replace
	
	restore
	*/
}

/*
keep hh_id ba_hh_slot mean_power

reshape wide mean_power, i(hh_id) j(ba_hh_slot) string

* match back to survey data
merge 1:1 hh_id using "`idpath'/processed/survey-data.dta"

*/

**********************
* Models

* 1 Try 1/2 hour slot values

* 2 Try lag values


log close
