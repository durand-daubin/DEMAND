* Process Loughbourough 1 minute resolution data
* b.anderson@soton.ac.uk
local where "/Users/ben/Documents"

local projroot "`where'/Work/Projects/RCUK-DEMAND/Theme 1"
local idpath "`where'/Work/Data/Social Science Datatsets/6583 - One-Minute Resolution Domestic Electricity Use Data 2008-2009/"
local do_path "`projroot'/do_files"
local rpath "`projroot'/results/UKDA-6583-1-min"

* v1.0 = census day 2008
local vers "v1.0"

capture log close
set more off

log using "`rpath'/DEMAND-Clock-change-UKDA-6583-1-min-res-data-`vers'-$S_DATE.smcl", replace

clear all

* control what is run
local do_basics = 0
local do_clockchange = 1

************************
* start with survey data
use "`idpath'/processed/survey-data-wf.dta", clear

* add energy data (filled but not full fill)
merge 1:m hh_id using "`idpath'/processed/meter_all_years_all_hhs_long_fillfull_wf.dta"

/*
NB: User Guide states
DATETIME_GMT  - The time stamp of the meter reading as Greenwich Mean Time (GMT).DATETIME_LOCAL  - The time stamp of the reading taking British Summer Time (BST) into account.IMPORT_KW  The mean power demand during the one?minute period starting at the time stamp.The date time fields are formatted as <YEAR>/<MONTH>/<DAY> <HOUR>:<MINUTE>.Where data is not available for a given minute, no row exists in the file. 
Note that no data is available for two of the meters in 2009, and hence two of the files are empty.
*/

*****************
* Do some missing data checks
* should already be set
* xtset hh_id timestamp_gmt, delta(1 minute)

* next command will fail if not

preserve
	* compare 24/3 with 31/3 (after clocks changed)
	* argh! 24/3 was Easter monday (bank holiday)!

	keep if tin(24mar2008 00:00,31mar2008 23:59)
	
	* that keeps a week, keep Monday
	keep if ba_dow == 1
	
	* reduce to 15 min hour data per household (to simulate smart meters)
	collapse (count) n_obs=import_kw ///
			(sum) n_zeros=import_kw_z ba_missing_obs ///
			(mean) mean_power=import_kw ba_accom ba_npeople ///
			(sd) sd_power=import_kw ///
			(p5) p5_power=import_kw (p25) p25_power=import_kw ///
			(p50) p50_power= import_kw  ///
			(p75) p75_power=import_kw (p95) p95_power=import_kw ///
			, by(ddate_gmt ba_15m_slot)
	
	sort ddate_gmt ba_15m_slot
	by ddate_gmt : egen ba_slot_n = seq()
	lab var ba_slot_n "15 minute time slot"
	
	format ddate_gmt %td
	twoway rarea p25_power p75_power ba_slot_n, name(compare_24_31_march) ///
		by(ddate_gmt, cols(1) note("Times in GMT, clocks changed 30th March")) color(dimgray) ///
		|| scatter p50_power ba_slot_n, msize(tiny) ///
		xline(24 48 72, lstyle(foreground)) ///
		text(1 24 "06:00", place(e)) text(1 48 "12:00", place(e)) text(1 72 "18:00", place(w)) ///
		xline(22 74, lcolor(blue) lstyle(grid)) ///
		text(1.5 22 "sunrise", place(w)) text(1.5 74 "sunset", place(e))
	
restore

preserve
	keep if tin(27mar2008 00:00,03apr2008 23:59)
	
	* that keeps a week, keep thursday
	keep if ba_dow == 4
	
	tab ba_dow
	
	* reduce to 15 min hour data per household (to simulate smart meters)
	collapse (count) n_obs=import_kw ///
			(sum) n_zeros=import_kw_z ba_missing_obs ///
			(mean) mean_power=import_kw ba_accom ba_npeople ///
			(sd) sd_power=import_kw ///
			(p5) p5_power=import_kw (p25) p25_power=import_kw ///
			(p50) p50_power= import_kw  ///
			(p75) p75_power=import_kw (p95) p95_power=import_kw ///
			, by(ddate_gmt ba_15m_slot)
	
	sort ddate_gmt ba_15m_slot
	by ddate_gmt : egen ba_slot_n = seq()
	lab var ba_slot_n "15 minute time slot"
	
	format ddate_gmt %td
	twoway rarea p25_power p75_power ba_slot_n, name(compare_27_mar_3_apr) ///
		by(ddate_gmt, cols(1) note("Times in GMT, clocks changed 30th March")) color(dimgray) ///
		|| scatter p50_power ba_slot_n, msize(tiny) ///
		xline(24 48 72, lstyle(foreground)) ///
		text(1 24 "06:00", place(e)) text(1 48 "12:00", place(e)) text(1 72 "18:00", place(w)) ///
		xline(22 74, lcolor(blue) lstyle(grid)) ///
		text(1.5 22 "sunrise", place(w)) text(1.5 74 "sunset", place(e))

restore

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
