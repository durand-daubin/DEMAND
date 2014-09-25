* Process MTUS World 6 time-use data for easier use in stata

* data already in long format (but episodes)
* creates UK only files
* adds STATA format times & dates to episodes
* loops over adult & child data

* b.anderson@soton.ac.uk
* (c) University of Southampton
* Creative Commons Attribution-NonCommercial 4.0 International (CC BY-NC 4.0) license applies
* http://creativecommons.org/licenses/by-nc/4.0/

clear all

* change these to run this script on different PC
local where "/Users/ben/Documents/Work"
local proot "`where'/Data/Social Science Datatsets/MTUS/World 6"
* /Users/ben/Documents/Work/Data/Social Science Datatsets/MTUS/World 6/MTUS_W6_UK_only.DTA
* location of time-use diary data
local dpath "`proot'"

* which files to process?
local files "MTUS-adult-episode MTUS-child-episode"

* version
local v = "v1.0"

capture log close

* make script run without waiting for user input
set more off

foreach f of local files {
	* get original diary data (these are episodes)
	di "***********"
	di "* Processing `f'"
	
	use "`dpath'/`f'.dta", clear
	
	* keep UK data
	keep if countrya == 37
	
	* Sunday = 1 in this data!
	recode day (1=7) (2=1) (3=2) (4=3) (5=4) (6=5) (7=6), gen(ba_dow) 
	
	lab def ba_dow  1 "Monday" 2 "Tuesday" 3 "Wednesday" 4 "Thursday" 5 "Friday" 6 "Saturday" 7 "Sunday"
	lab val ba_dow ba_dow
	lab var ba_dow "Day of week diary started (from day)"
	tab day ba_dow
	
	* start and end are minutes from the beginning of the diary - these vary across the surveys but for the UK they are all 04:00
	* check this - epnum = 1st episode
	tab survey clockst if epnum == 1
	
	* what kind of patterns do we have for start times?
	tab start survey
	*  mostly bunched around 00 10, 20, 30 etc as expected due to survey desing but some have start = t + 1 (so start has been coded
	* as minute = 0 instead of minute = 0)
	
	* fix this to make life easier
	gen ba_startm = start
	lab var ba_startm "Corrected episode start minute (from 'start')"
	
	**
	* 1974 1 = 0 and then mostly 30, 60, 70, 80, 90 (1/2 hours as per documentation) but NB there are some in-betweens
	replace ba_startm = ba_start-1 if start == 1 & survey == 1974
	
	* 1983 is 15 mins but have +1 for all periods (so 16, 31, 61)
	* fix the start = 1
	replace ba_startm = ba_start-1 if start == 1 & survey == 1983
	* fix the rest
	foreach v of numlist 15(15)1440 {
		*di "* check `v'"
		qui: replace ba_startm = `v' if start == `v' + 1 & survey == 1983
	}
	
	**
	* 1987 appears to be 15 minutes but some in betweens on 5 minutes
	
	**
	* 1995 15 mins but has +1 (so 16,31,46 etc)
	replace ba_startm = ba_start-1 if start == 1 & survey == 1995
	foreach v of numlist 15(15)1440 {
		*di "* check `v'"
		qui: replace ba_startm = `v' if start == `v' + 1 & survey == 1995
	}
	**
	* 2000 10 minutes, clean so no processing required
	
	**
	* 2005 10 minutes, clean so no processing required
	
	* recheck
	tab ba_startm survey
	
	* create a 'real' time for use in STATA's ts commands
	* use the fixed start mins & time (= duration)
	gen ba_mins = mod(ba_startm,60)
	gen ba_hours = floor(ba_startm/60)
	
	* ba_hours is 4 hours too small (diaries started at 4)
	replace ba_hours = ba_hours + 4
	* but we will now have 03:00 being 27 as activities after 00:00 are recorded for 'tomnorrow'
	* we will set them to 'this morning' instead.
	* NB: this can lead to odd discontinuities at 04:00 on charts but overall it makes the data easier to understand
	replace ba_hours = ba_hours - 24 if ba_hours > 23
	
	* create the time by concatenating hours & minutes
	egen ba_starttime = concat(ba_hours ba_mins), punct(":")
	* make the STATA time a double to ensure proper rounding
	gen double s_starttime = clock(ba_starttime,"hm")
	format s_starttime %tcHH:MM
	lab var s_starttime "Episode start (STATA time)"
	
	* 'time' is the duration in minutes
	* STATA wants it in milliseconds
	gen duration_ms = msofminutes(time)
	
	* use it to create the endtime in STATA
	gen double s_endtime = s_starttime + duration_ms
	format s_endtime %tcHH:MM
	lab var s_endtime "Episode end (STATA time)"
	
	* Note that both these times will have no meaningful date
	* "Living on STATA time" with apologies to Danny Flowers & Eric Clapton.
	
	* Create the correct s_datetime using year, cday, month but NOT
	* splitting diaries over two days so use the corrected dates
	* this would help with seasonal adjustment etc
	* -9 or -8 = unknown, applies mostly to 2005 data
	* set to missing (we could do slightly better by randomly allocating using the day of the week but...)
	replace cday = . if cday == -9 | cday == -8
	egen ba_date = concat(year month cday) if cday != ., punct(.) 
	
	* build the date as a string
	egen ba_datetime_st = concat (ba_date ba_starttime), punct(" ")
	* convert to STATA datetime
	gen double s_datetime_st = clock(ba_datetime_st, "YMDhm")
	* now use the duration in milliseconds to create the end time
	gen double s_datetime_end = s_datetime_st + duration_ms
	* format them to look pretty
	format s_datetime_st s_datetime_end %tc
	lab var s_datetime_st "Episode start (STATA datetime)"
	lab var s_datetime_end "Episode end (STATA datetime)"
	
	li clockst time main ba_startm s_*time* in 1/24
	* NB it is important to note that this will have set the time for activities recorded after midnight on cday + 1 
	* as happening in the morning of cday
	* NB: this can lead to odd discontinuities at 04:00 on charts but overall it makes the data easier to understand
	
	* check times were fixed
	tab s_starttime survey
	
	* the following code creates a time from clockst for comparison which is slightly problematic as it wraps early morning activities onto the morning 
	* BEFORE the diary started (at 04:00)
	* clockst = time episode starts in 24 hours with 2.1 = 2:10; 2.2 = 2:20 etc
	tab clockst
	* there are some odd long decimals so round everything to 2 dp (i.e. whole minutes) first
	
	gen mins_f = round(mod(clockst,1),0.01)
	gen clockst_mins = mins_f * 100
	
	gen clockst_hours = floor(clockst)
	
	egen t_clocksttime = concat(clockst_hours clockst_mins), punct(":") 
	gen double s_clocksttime = clock(t_clocksttime,"hm")
	format s_clocksttime %tcHH:MM
	lab var s_clocksttime "Episode start (from clockst)"
	
	gen double s_clockstendtime = s_clocksttime + duration_ms
	format s_clockstendtime %tcHH:MM
	lab var s_clockstendtime "Episode end (from clockst)"
	
	* check
	li clockst *start* *end* in 1/10 
	
	* create a half-hour variable to put start (and end) times into 1/2 hour buckets for ease of ongoing analysis & graphing
	* this also unifies the MTUS periods as different recording periods were used in a number of the surveys
	* and the lowest common multiple is 30 minutes!
	
	gen ba_hourt = hh(s_starttime)
	gen ba_minst = mm(s_starttime)
	
	gen ba_hh = 0 if ba_minst < 30
	replace ba_hh = 30 if ba_minst > 29
	gen ba_sec = 0
	* sets date to 1969!
	gen s_halfhour = hms(ba_hourt, ba_hh, ba_sec)
	lab var s_halfhour "Episode starts during the half hour following"
	format s_halfhour %tcHH:MM

	* where is location missing?
	gen missing_loc = 0
	replace missing_loc = 1 if eloc == -8
	lab var missing_loc "Location is missing/unknown"
	
	* we could delete badcases (see documentation) but let's keep for now
	* drop if badcase == 1 // [good cases = 0]
	
	* create a uniq id for each person and then each diary day
	* this is useful for bug checking
	
	egen pid = group(countrya survey swave msamp hldid persid)
	tabstat pid, by(survey) s(min max)
	
	* use this to match to the aggregated survey data cases
	egen diarypid = group(countrya survey swave msamp hldid persid day)
	tabstat diarypid, by(survey) s(min max)
	
	* tell stata this is a panel time series dataset
	xtset diarypid s_starttime, delta(5 min)
	
	* drop variables we don't need
	drop ba_min* ba_hour* ba_starttime ba_date ba_datetime_st t_clocksttime duration_ms mins_f clockst_mins clockst_hours
	
	compress
	
	* save
	save "`dpath'/processed/`f'-UK-only-wf.dta", replace
}
* done!
