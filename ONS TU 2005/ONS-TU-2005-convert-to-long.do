* Convert ONS 2005 time-use data to long format, set stata dates/times and separate time diary data from survey data

* b.anderson@soton.ac.uk
* (c) University of Southampton
* Creative Commons Attribution-NonCommercial 4.0 International (CC BY-NC 4.0) license applies
* http://creativecommons.org/licenses/by-nc/4.0/

clear all

* change these to run this script on different PC
local where "/Users/ben/Documents/Work"
local proot "`where'/Data/Social Science Datatsets/Time Use 2005"
* location of time-use diary data
local dpath "`proot'/UKDA-5592-stata8-v2/stata8"


* version
* local v = "v1.0"
* original

* using updated UKDA time use file (v2) June 2007, (2nd Edition)
* has more detailed codes
* http://discover.ukdataservice.ac.uk/catalogue/?sn=5592
local v = "v2.0"

capture log close

local do_collapse 1

* make script run without waiting for user input
set more off

* get diary data
use "`dpath'/timeusefinal_for_archive2.dta", clear

* according to the userguide code DiaryDay 1 might be Sunday!
recode diaryday (1=7) (2=1) (3=2) (4=3) (5=4) (6=5) (7=6), gen(ba_dow)

lab def ba_dow  1 "Monday" 2 "Tuesday" 3 "Wednesday" 4 "Thursday" 5 "Friday" 6 "Saturday" 7 "Sunday"
lab val ba_dow ba_dow
lab var ba_dow "Day of week (from diaryday)"

tab diaryday ba_dow

***************
* save out a survey file with no time use data - can merge back in later
preserve
	drop pact* sact* lact* aprim* asec* p_* s_* loc* comp*
	compress
	save "`proot'/processed/timeusefinal_for_archive_survey_`v'.dta", replace
	* save a .csv version for R
	export using "`proot'/processed/timeusefinal_for_archive_survey_`v'.csv", comma nolabel replace
restore

* keep the diary data only

keep serial net_wgt month ba_dow pact* sact* lact* 

****************
* convert to long format and set up stata time variables
reshape long pact sact lact, i(serial)

rename _j t_slot
* t_slot now has values 1 -> 144 (10 minute slots)

* calculate minute from slot (end of slot)
gen min = mod(t_slot,6)
gen t_min = 0 if min == 0
replace t_min = 10 if min == 1
replace t_min = 20 if min == 2
replace t_min = 30 if min == 3
replace t_min = 40 if min == 4
replace t_min = 50 if min == 5

* which hour is it?
gen t_hour = ceil(t_slot/6)
* diary starts at 04:00
* NB this puts > 00:00 to the start of the diary day - remember this if doing sequences through 04:00
* also some charts will show discontinuities at 04:00
replace t_hour = t_hour + 3
* fix the 'following hour' problem
replace t_hour = t_hour + 1 if t_min == 0

* fix dates
* Feb: we are going to assume this was the first full week of feb where Monday was the 7th
gen t_day = ba_dow + 6 if month == 1

* June: we are going to assume this was the first full week of june where Monday was the 6th
replace t_day = ba_dow + 5 if month == 2

* Sept: we are going to assume this was the first full week of sept where Monday was the 5th
replace t_day = ba_dow + 4 if month == 3

* Nov: we are going to assume this was the first full week of nov where Monday was the 7th
replace t_day = ba_dow + 6 if month == 4

* fix the '> 24' problem
* make it tomorrow
replace t_day = t_day + 1 if t_hour >= 24
* make it in the morning (tomorrow)
replace t_hour = t_hour - 24 if t_hour >= 24
		
gen t_month = 2 if month == 1
replace t_month = 6 if month == 2
replace t_month = 9 if month == 3
replace t_month = 11 if month == 4

gen t_year = 2005
gen t_sec = 0
gen double s_datetime=  mdyhms(t_month,t_day,t_year,t_hour, t_min, t_sec)
format s_datetime %tc
gen s_dow = dow(dofc(s_datetime))
lab def s_dow 0 "Sunday" 1 "Monday" 2 "Tuesday" 3 "Wednesday" 4 "Thursday" 5 "Friday" 6 "Saturday"
lab var s_dow "Day of week (STATA form)"
lab val s_dow s_dow
tab s_dow ba_dow
* NB: s_dow is the ACTUAL day, ba_dow is the day the diary started!
lab var s_datetime "Date & time slot starts"

destring t_min, force replace
destring t_hour, force replace

recode t_min (0/29 = "00") (30/59 = "30"), gen(t_hhmin)
egen t_halfhour = concat(t_hour t_hhmin), punct(":")
lab var t_halfhour "Time of day (half hours)"

* create a fake stata time
egen t_time = concat(t_hour t_min), punct(":")
gen double s_starttime = clock(t_time,"hm")
format s_starttime %tcHH:MM
lab var s_starttime "Time slot starts"

* create a fake half hour
gen double s_halfhour = clock(t_halfhour,"hm")
format s_halfhour %tcHH:MM
lab var s_halfhour "Time of day (half hours)"

lab var lact "Location"
lab var pact "Primary activity"
lab var sact "Secondary activity"

lab var t_slot "Diary slot (144 * 10 mins)"
lab var t_month "Month diary completed"

*sort t_time
li t_slot month t_month ba_dow s_* in 1/10

* run checks
tab month t_month
tab s_dow ba_dow

* where is location missing?
gen missing_loc = 0
replace missing_loc = 1 if lact == -1
lab var missing_loc "Location missing"

* where are secondary acts missing?
gen missing_sec = 0
replace missing_sec = 1 if sact == -1
lab var missing_sec "Secondary act missing"

keep serial net_wgt t_slot t_month s_* pact sact lact missing_loc missing_sec

order serial net_wgt t_month t_slot s_*

xtset serial s_datetime, delta(10 minutes)

compress

* save it!
save "`proot'/processed/timeusefinal_for_archive_diary_long_`v'.dta", replace
* save a .csv version for R
export using "`proot'/processed/timeusefinal_for_archive_diary_long_`v'.csv", comma nolabel replace


di "* -> done!"
