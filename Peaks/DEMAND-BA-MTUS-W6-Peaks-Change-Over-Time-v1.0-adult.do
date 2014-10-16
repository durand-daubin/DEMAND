* Use MTUS World 6 time-use data (UK subset) to examine:
* - distributions of activities at coarse level 1974 -> 2005
* - focus on the components of 'peak demand'

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

capture log close

log using "`rpath'/DEMAND-BA-MTUS-W6-Peaks-Change-Over-Time-`version'-adult.smcl", replace

* control what happens
local do_halfhour_episodes 0

* make script run without waiting for user input
set more off

**********************************
* all codes of interest

* start with processing the aggregate (survey) data
use "`dpath'/MTUS-adult-aggregate-UK-only-wf.dta", clear

* drop all bad cases
keep if badcase == 0

* set as survey data for descriptives
svyset [iw=propwt]

* keep only 1974 & 2005 for simplicity
* keep if survey == 1974 | survey == 2005
* no, let's keep them all for birth cohort analysis!

* keep whatever sample we define above
keep `filter'

* number of diary days by hh type
svy: tab hhtype survey, col count

* number of diary days by number of days covered
* 1995 & 2005 = 1 day diary
* 2005 = 2 day diary
* all others = 7 day diary so 'rare' activities more likely to be recorded
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
keep sex age main7 main8 hhtype empstat emp unemp student retired propwt survey hhldsize famstat nchild *pid ba*

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

*********************
* Peaks - half hourly analysis
* logic: the time use diaries rarely have the same duration of recorded time slot, 1974 = 30 mins, 2005 = 10 mins for example
* To make comparison easier we need to use the lowest common multiple - in this case 30 minutes
* We have already set up a variable (s_halfhour) which is the stata episode start-time converted into a stata half hour
* i.e. if s_starttime = 21:24 s_halfhour =  21:00, if s_starttime = 21:44 s_halfhour =  21:30 etc

* Note that where the diary has episodes shorter than 30 minutes we may get more than 1 episode reported per half hour

if `do_halfhour_episodes' {
	local surveys "1974 1983 1987 1995 2000 2005"
	
	foreach s of local surveys {
		* This will record all episodes that started within the half hour but it won't catch episodes that started before and
		* ar elong-lasting. So it is good for looking at the distribution of episodes that are short
		tabout s_halfhour main if survey == `s' using "`rpath'/`s'-main-by-halfhours-alldays.txt" [iw=propwt], replace
	}
}
* to convert to slots we have to do something different: sample
* choose the sampling point (i.e. slot duration)
local slot 10

* remember that each diary starts at 04:00

foreach h of numlist 0(1)23 {
	local realh = `h' + 4
	if `realh' > 23 {
		local realh = `realh' - 24
	}
	di "* Checking diary hour = `h' (which is actually `realh')"
	foreach m of numlist 0(`slot')60 {
		* if we hit 60 we're on the hour so skip to next hour loop
		if `m' != 60 {
			* convert h & m to total mins since start
			local mins = (`h' * 60) + `m'
			* di "* Checking diary hour `h' (actually `realh') : diary minute `m' (start mins = `mins')"
			* if the activity started at or before 'now' and it finishes after now then record it (we don't care when it finishes)
			gen slotp`mins' = main if ba_startm <= `mins' & end > `mins'
			lab var slotp`mins' "Main act at `realh':`m'"
			lab val slotp`mins' MAIN
			gen slots`mins' = sec if ba_startm <= `mins' & end > `mins'
			lab var slots`mins' "Sec act at `realh':`m'"
			lab val slots`mins' SEC
			* this will create missing if location is missing
			gen slotloc`mins' = eloc if ba_startm <= `mins' & end > `mins'
			lab var slotloc`mins' "Location act at `realh':`m'"
			lab val slotloc`mins' eloc
		}
	}			
}

* collapse these to single values per diarypid (they should be unique within diarypid)
* this creates a wide form file
* survey is not needed as it is part of diarypid but it helps when analysing the data
collapse (mean) slot*, by(diarypid survey)

* now convert this wide file back to long
reshape long slotp slots slotloc, i(diarypid survey)

rename slotp main
lab val main MAIN
rename slots sec
lab val sec SEC
rename slotloc loc
lab val loc ELOC

rename _j t_slot
* t_slot will now be each slot which is `slot' minutes long
gen min = mod(t_slot,60)
gen t_hour = ceil(t_slot/60)

save "`dpath'/MTUS-adult-aggregate-UK-only-wf-10min-samples-long.dta", replace

* t_hour = 0 and t_hour = 24 are the same
replace t_hour = 0 if t_hour == 24
tab t_hour
* fix the following hour problem
replace t_hour = t_hour + 1 if t_min == 0

li t_slot t_hour min in 1/24



log close
