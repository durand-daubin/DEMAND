* Process MTUS World 6 time-use data (UK subset) for easier use in stata

* data already in long format (but episodes)

* b.anderson@soton.ac.uk
* (c) University of Southampton
* Creative Commons Attribution-NonCommercial 4.0 International (CC BY-NC 4.0) license applies
* http://creativecommons.org/licenses/by-nc/4.0/

clear all

* change these to run this script on different PC
local where "/Users/ben/Documents/Work"
local droot "`where'/Data/Social Science Datatsets/MTUS/World 6"
* location of time-use diary data
local dpath "`droot'/processed"
local dfile "MTUS-adult-episode-UK-only"

local proot "`where'/Projects/RCUK-DEMAND/Theme 1"
local rpath "`proot'/results/MTUS"

* version
*local version "v1.1-singles"
*local filter "if hhtype == 1"
* single person hhs only

*local version "v1.1-all-hhs-sanity-check"
*local filter "_all"
* counts if 1 or more acts (sanity check)

local version = "v1.2-all-hhs"
* weights the final counts

*local version = "v1.1-all-hhs"
local filter "_all"
* adds in secondary acts
 
* local version = "v1.0-main"
* counts main acts only

capture log close

log using "`rpath'/DEMAND-BA-MTUS-W6-Laundry-Change-Over-Time-`version'-adult.smcl", replace

* make script run without waiting for user input
set more off

* start with processes aggregate data
use "`dpath'/MTUS-adult-aggregate-UK-only-wf.dta", clear

* drop all bad cases
keep if badcase == 0

* set as survey data for descriptives
svyset [iw=propwt]

* seems to under-report laundry in 1974, esp for women?
svy: mean main21, over(survey sex)

* keep only 1974 & 2005 for simplicity
keep if survey == 1974 | survey == 2005

* keep whatever we define above
keep `filter'

* number of diary days
svy: tab hhtype survey, col count

* main7 & main8 = paid work
gen ba_4hrspaidwork = 0
* mark those who worked more than 4 hours that day
replace ba_4hrspaidwork = 1 if main7 > 240


*************************
* merge episode data
* egen diarypid = group(countrya survey swave msamp hldid persid day)
* egen pid = group(countrya survey swave msamp hldid persid)

keep sex age main7 main8 main21 hhtype empstat emp unemp student retired propwt survey hhldsize famstat nchild *pid

* number of diary-days

svy: tab survey, obs

merge 1:m diarypid using "`dpath'/MTUS-adult-episode-UK-only-wf.dta", ///
	gen(m_aggvars)

* won't match the dropped years	& badcases
tab m_aggvars survey

keep if m_aggvars == 3

* number of episodes
svy: tab survey, obs

gen any_laundry_m = 0
lab var any_laundry_m "Main act = laundry (21)"
replace any_laundry_m = 1 if main == 21

gen any_laundry_s = 0
lab var any_laundry_s "Secondary act = laundry (21)"
replace any_laundry_s = 1 if sec == 21

egen any_laundry_all = rowtotal(any_laundry_*)

svy: tab survey any_laundry_m, row se ci
svy: tab survey any_laundry_s, row se ci
* all
svy: tab survey any_laundry_all, count se ci
svy: tab survey any_laundry_all, row se ci

gen ba_weekday = 0
replace ba_weekday = 1 if ba_dow < 6

* n episodes
tab day survey, mi

* descriptives

* check durations
gen duration = s_endtime - s_starttime
format duration %tcHH:MM
svy: tab duration if survey == 1974
svy: tab duration if survey == 2005

* is this meaningful? Need to check if new episode is still laundry (could have new secondary act)
svy: mean duration if main == 21, over(survey sex) 
svy: mean duration if sec == 21, over(survey sex) 

* check incidence of laundry & gender split
svy: tab survey sex if main == 21, row count
svy: tab survey sex if sec == 21, row count

recode nchild (0=0) (1=1) (2=2) (3/max=3), gen(ba_nchild)
lab def ba_nchild 0 "0" 1 "1" 2 "2" 3 "3+"
lab val ba_nchild ba_nchild
recode hhldsize (0=0) (1=1) (2=2) (3=3) (4=4) (5/max=5), gen(ba_npeople)
lab def ba_npeople 0 "0" 1 "1" 2 "2" 3 "3" 4 "4" 5 "5+"
lab val ba_npeople ba_npeople

local vars "ba_npeople famstat ba_nchild"
foreach v of local vars {
	di "* -> Testing `v'"
	svy: mean any_laundry_all, over(survey ba_npeople)
}

* leave this empty to skip the (time consuming) aggregations & table outputs
local vars "21"
local l5 "meals_work"
local l6 "meals_oth"
local l18 "food_prep"
local l21 "laundry"
local l59 "tv_video"
local l60 "computer_games"
local l61 "computer_internet"

* logic = sample at small minute intervals (e.g. 5) - what was happening?
* 5 is a good number as most diaries are in multiples of 5 (10, 15, 30 etc)
* if activity was happening record 1
* then aggregate to e.g. half hours
* NB: 
* summing the '1's is dodgy 
* - in a 10 min diary laundry might just fill 1 10 min slot -> sum = 1
* - in a 1/2 hour diary a 1 might mean all 30 minutes
* => register a 1 as "at least 1 instance recorded in this half hour"

* NB - this has much the same effect as tabulating by start_time except that this squishes out all the within-half-hour mess from 2005

local slot = 5
foreach v of local vars {
	preserve
		svy: tab survey any_laundry_all, row count
		
		di "* Checking for `v' (`l`v'')"
		foreach m of numlist 0(`slot')1440 {
			*di "* Checking `m' for `v' (`l`v'')"
			local h = `m'/`slot'
			gen any_`l`v''`h' = 0
			* this will catch any instance of laundry which starts in the half hour
			* creates a new variable for each slot
			* gen any_laundry0 = 1 if main == 21 & start_mins_from00 >= 0 & end_mins_from00 <= 60
			* we're in a period of v 'now'
			* (main == `v' | sec == `v')
			qui: replace any_`l`v''`h' = 1 if (main == `v' | sec == `v') & `m' >= ba_startm & `m' <= end
		}
		* summarise to half hours from whatever we created above
		* we used 5 mins so n slots = 288
		* n per half hour = 6
		foreach hh of numlist 0(6)282 {
			gen anyhh_`l`v''`hh' = 0
			*di "* checking `l`v'' (base half hour = `hh')"
			foreach s of numlist 0(1)5 {
				local sl = `hh' + `s'
				*di "checking slot `sl' (base = `hh')"
				* record 1 if any `v'
				qui: replace anyhh_`l`v''`hh' = 1 if any_`l`v''`sl' >= 1 
			}
		}
		* collapse to diaryid for sequence analysis (i.e. at half hour level)
		* include the by variables we'll need to do the subsequent collapse for the table
		collapse (sum) anyhh_`l`v''* (count) count=epnum (mean) propwt, by(age sex day survey diarypid)
		save "`rpath'/MTUS-W6-Adult-UK-only-`version'-`l`v''halfhour.dta", replace
		local byvars "survey day sex"
		* collapse to make tables
		collapse (sum) anyhh_`l`v''* [iw=propwt], by(`byvars')
		aorder survey sex day
		sort survey sex day
		outsheet using "`rpath'/DEMAND-BA-MTUS-W6-Change-Over-Time-`version'-`l`v''halfhour-adult-`byvars'.txt", replace
		di "`v' (`l`v'') results saved"
	restore
}

* badcase == 0 [good cases]

* tabstat anyhh_laundry* if badcase == 0 & survey==1974, by(day) s(sum) c(s)
* tabstat anyhh_laundry* if badcase == 0 & survey==2005, by(day) s(sum) c(s)

* tabstat anyhh_meals_oth* if badcase == 0 & survey==1974 & eloc == 1, by(day) s(sum) c(s)
* tabstat anyhh_meals_oth* if badcase == 0 & survey==2005 & eloc == 1, by(day) s(sum) c(s)

* sequences
* we can't use the lag notation and xtset as there are various time periods represented in the data
* and we would need to set up some fake (or real!) dates to attach the start times to.
* we could do this but we don't really need to.

* we want to use episodes not time slots (as we are ignoring duration here)

* make sure we do this within diaries
bysort diarypid: gen before_laundry_m = main[_n-1] if any_laundry_m == 1
bysort diarypid: gen after_laundry_m = main[_n+1] if any_laundry_m == 1

lab val before_laundry after_laundry MAIN

tab before_laundry
tab before_laundry survey

tab after_laundry
tab after_laundry survey, col nof

/*
* try using the sqset commands
* use the half hour data
use "/Users/ben/Documents/Work/Projects/RCUK-DEMAND/Theme 1/results/MTUS/MTUS-W6-Adult-UK-only-v1.0-laundryhalfhour.dta", clear

* turn it round
reshape long anyhh_laundry, i(diarypid) j(hhslot)

* tell it to look at sequences of laundry
sqset anyhh_laundry diarypid hhslot

* top 20 sequences
sqtab survey, ranks(1/20) 
*/

log close
