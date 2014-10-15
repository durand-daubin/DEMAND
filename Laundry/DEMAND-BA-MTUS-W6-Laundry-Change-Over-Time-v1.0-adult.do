* Use MTUS World 6 time-use data (UK subset) to examine:
* - distributions of laundry in 1975 & 2005
* - changing laundry practices

* data already in long format (but episodes)

* b.anderson@soton.ac.uk
* (c) University of Southampton

* This work was funded by RCUK through the End User Energy Demand Centres Programme via the
* "DEMAND: Dynamics of Energy, Mobility and Demand" Centre (www.demand.ac.uk, gow.epsrc.ac.uk/NGBOViewGrant.aspx?GrantRef=EP/K011723/1)


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
local version = "v1.2-all-hhs"
local filter "_all"
* weights the final counts

*local version "v1.1-singles"
*local filter "if hhtype == 1"
* single person hhs only

*local version "v1.1-all-hhs-sanity-check"
*local filter "_all"
* counts if 1 or more acts (sanity check)

*local version = "v1.1-all-hhs"
* local filter "_all"
* adds in secondary acts
 
* local version = "v1.0-main"
* counts main acts only

capture log close

log using "`rpath'/DEMAND-BA-MTUS-W6-Laundry-Change-Over-Time-`version'-adult.smcl", replace

* make script run without waiting for user input
set more off

**********************************
* codes of interest
* 1974:	Main/Sec21 Laundry, ironing, clothing repair <- 50 Other essential domestic work (i.e. NOT preparing meals or routine housework)
* 	so laundry in 1974 may be over-estimated
* BUT 1975 is partly a 7 day diary - so more likely to detect laundry?

* 2005:	Main/Sec21 Laundry, ironing, clothing repair <- Pact=7 (washing clothes)

* start with processing the aggregate (survey) data
use "`dpath'/MTUS-adult-aggregate-UK-only-wf.dta", clear

* drop all bad cases
keep if badcase == 0

* set as survey data for descriptives
svyset [iw=propwt]

* keep only 1974 & 2005 for simplicity
* keep if survey == 1974 | survey == 2005
* no, let's keep them all for birth cohort analysis!

* this is minutes per day not episodes
* check 18 (Cooking) & 20 (Cleaning) & 22 (maintain home/vehicle) against laundry
* seems to under-report laundry in 1974, esp for women?
svy: mean main18 main20 main21 main22, over(survey sex)

* keep whatever sample we define above
keep `filter'

* number of diary days by hh type
svy: tab hhtype survey, col count

* number of diary days by number of days covered
* 1974 = 7 day dairy
svy: tab id survey, col count

* hh size recode & test
recode hhldsize (1=1) (2=2) (3=3) (4=4) (5/max=5), gen(ba_hhsize)
lab var ba_hhsize "Recoded household size"
lab def ba_hhsize 1 "1" 2 "2" 3 "3" 4 "4" 5 "5+"
lab var ba_hhsize ba_hhsize
svy: tab ba_hhsize survey, col count

* main7 & main8 = paid work
gen ba_4hrspaidwork = 0
* mark those who worked more than 4 hours that day
replace ba_4hrspaidwork = 1 if main7 > 240

*************************
* merge in the episode data
* egen diarypid = group(countrya survey swave msamp hldid persid day)
* egen pid = group(countrya survey swave msamp hldid persid)

* keep only the vars we want to keep memory required low
keep sex age main7 main8 main18 main20 main21 main22 hhtype empstat emp unemp student retired propwt survey hhldsize famstat nchild *pid ba*

* number of diary-days
svy: tab survey, obs

merge 1:m diarypid using "`dpath'/MTUS-adult-episode-UK-only-wf.dta", ///
	gen(m_aggvars)

* won't match the dropped years	& badcases
tab m_aggvars survey

* keep the matched cases
keep if m_aggvars == 3

* number of episodes per day
svy: tab day survey, obs col

* check durations - shows how long the episodes tend to be in each survey
gen duration = s_endtime - s_starttime
format duration %tcHH:MM
tab duration survey [iw=propwt], col nof

* set up n child & n people variables
recode nchild (0=0) (1=1) (2=2) (3/max=3), gen(ba_nchild)
lab var ba_nchild "Recoded nchild"
lab def ba_nchild 0 "0" 1 "1" 2 "2" 3 "3+"
lab val ba_nchild ba_nchild
recode hhldsize (0=0) (1=1) (2=2) (3=3) (4=4) (5/max=5), gen(ba_npeople)
lab def ba_npeople 0 "0" 1 "1" 2 "2" 3 "3" 4 "4" 5 "5+"
lab val ba_npeople ba_npeople

egen ba_age_r = cut(age), at(16,24,34,44,54,64,74,84)
lab var ba_age_r "Recoded age -> decades"
gen ba_birthyear = year - age

egen ba_birth_cohort = cut(ba_birthyear), at(1890,1900,1910,1920,1930,1940,1950,1960,1970,1980)
tab ba_birth_cohort survey
* NB - max age = 80 so older cohorts missing from 2005

* weekday variable
gen ba_weekday = 0
replace ba_weekday = 1 if ba_dow < 6

***
* Laundry

* define laundry
gen laundry_p = 0
lab var laundry_p "Main act = laundry (21)"
replace laundry_p = 1 if main == 21

gen laundry_s = 0
lab var laundry_s "Secondary act = laundry (21)"
replace laundry_s = 1 if sec == 21

gen laundry_all = 0
replace laundry_all = 1 if laundry_p == 1 | laundry_s == 1

* check % episodes which are laundry
* NB reporting frame shorter in 2005 (10 mins) so may be higher frequency (e.g. interruption in 10-20 mins coded)
* row %
svy: tab survey laundry_p, row se ci
svy: tab survey laundry_s, row se ci
* all
* counts (for checking with weighted tables)
svy: tab survey laundry_all, count se ci
* row %
svy: tab survey laundry_all, row se ci

* check duration of laundry
* before we do this mere together episodes that are contiguous (e.g. laundry (s) then laundry(p) -> 1 episode)
* same approach as for dinner
* calculate duration
gen laundry_duration = duration if laundry_all == 1
format laundry_duration %tcHH:MM
* count back & forward maxcount episodes within the same diary day to check if they are also laundry 
* indicates something changed - primary/secondary act or location or who with etc
* add on duration if previous and subsequent episodes are also laundry and location is unchanged
* NB: if you make maxcount > 1 then you could have episodes of eating separated by a long episode of something else
local maxcount = 1
foreach n of numlist 1/`maxcount' {
	local prev = `n' - 1
	di "* Now = `n', previous = `prev'"
	di "* Before"
	su laundry_duration
	bysort survey diarypid: replace laundry_duration = laundry_duration + duration[_n-`n'] if laundry_all == 1 & ///
		laundry_all[_n-`n'] == 1 & eloc == eloc[_n-`n']
	bysort survey diarypid: replace laundry_duration = laundry_duration + duration[_n+`n'] if laundry_all == 1 & ///
		laundry_all[_n+`n'] == 1 & eloc == eloc[_n+`n']
	di "* After"
	su laundry_duration
}


* Means are probably not going to tell us much given the differences in recording frames
* Use tables instead as durations are so 'rounded'
table laundry_duration sex survey [iw=propwt]

* leave this empty to skip the (time consuming) aggregations & table outputs
local vars "21"
local l5 "meals_work"
local l6 "meals_oth"
local l18 "food_prep"
local l21 "laundry"
local l59 "tv_video"
local l60 "computer_games"
local l61 "computer_internet"

*************************
* Aggregation to half hours
* logic: the time use diaries rarely have the same duration of recorded time slot, 1974 = 30 mins, 2005 = 10 mins for example
* To make comparison easier we need to use the lowest common multiple - in this case 30 minutes
* We have already set up a variable (s_halfhour) which is the stata episode start-time converted into a stata half hour
* i.e. if s_starttime = 21:24 s_halfhour =  21:00, if s_starttime = 21:44 s_halfhour =  21:30 etc

* Note that where the diary has episodes shorter than 30 minutes we may get more than 1 episode of laundry reported per half hour
* Check
duplicates tag s_halfhour diarypid laundry_all, gen(laundry_dup_flag)
table laundry_dup_flag laundry_all survey

* We'd expect them all to occur in 2005 but they don't suggesting the 1974 -> MTUS conversion process has creates
* some episodes shorter than 30 minutes
* In any case we do need to watch out for situations where we sum the number of episodes per halfhour as 
* we may have more episodes in 2005 due to the smaller recording time frame.

* count laundry episodes that start in a given half hour by survey & sex
table s_halfhour sex survey if laundry_all  == 1 [iw=propwt]

* repeat by day 
by survey: table s_halfhour day laundry_all [iw=propwt]

* age cohort differences by sex
bysort sex: table ba_birth_cohort laundry_all survey [iw=propwt]

stop 
*************************
* sequences
* we can't use the lag notation and xtset as there are various time periods represented in the data
* and we would need to set up some fake (or real!) dates to attach the start times to.
* we could do this but we don't really need to.

* we want to use episodes not time slots (as we are ignoring duration here)

* make sure we do this within diaries
bysort survey diarypid: gen before_laundry_m = main[_n-1] if laundry_m == 1
bysort survey diarypid: gen after_laundry_m = main[_n+1] if laundry_m == 1

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
