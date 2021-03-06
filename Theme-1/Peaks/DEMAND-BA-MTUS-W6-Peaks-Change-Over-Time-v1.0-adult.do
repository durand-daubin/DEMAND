* Use MTUS World 6 time-use data (UK subset) to examine:
* - distributions of activities at coarse level 1974 -> 2005
* - focus on the components of 'peak demand'

* data already in long format (but episodes)

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
local do_halfhour_episodes = 1
local do_halfhour_samples = 1

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
replace ba_weekday = 1 if day > 1 & day < 7

* keep only the vars we want to keep memory required low
keep sex age main7 main8 hhtype empstat emp unemp student retired propwt survey hhldsize famstat nchild *pid ba*

* number of diary-days
svy: tab survey, obs

if `do_halfhour_episodes' {
	*************************
	* merge in the episode data
	* egen diarypid = group(countrya survey swave msamp hldid persid day)
	* egen pid = group(countrya survey swave msamp hldid persid)

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
		
	*********************
	* Peaks - half hourly analysis
	* logic: the time use diaries rarely have the same duration of recorded time slot, 1974 = 30 mins, 2005 = 10 mins for example
	* To make comparison easier we need to use the lowest common multiple - in this case 30 minutes
	* We have already set up a variable (s_halfhour) which is the stata episode start-time converted into a stata half hour
	* i.e. if s_starttime = 21:24 s_halfhour =  21:00, if s_starttime = 21:44 s_halfhour =  21:30 etc
	
	* Note that where the diary has episodes shorter than 30 minutes we may get more than 1 episode reported per half hour


	local surveys "1974 1983 1987 1995 2000 2005"
	
	foreach s of local surveys {
		* This will record all episodes that started within the half hour but it won't catch episodes that started before and
		* ar elong-lasting. So it is good for looking at the distribution of episodes that are short
		tabout s_halfhour main if survey == `s' using "`rpath'/`s'-main-by-halfhours-alldays.txt" [iw=propwt], replace
	}
}

*************************
* sampled data for comparison
if `do_halfhour_samples' {
	* merge in the sampled data
	merge 1:m diarypid using "`dpath'/MTUS-adult-episode-UK-only-wf-10min-samples-long.dta", ///
		gen(m_aggvars)
		
	* do any 10 minute analysis here...
	
	* if you want to do half hour analysis you will need to 
	* collapse to add up the sampled activities by half hour
	* this means (probably) you will need to first decide which you are interested in and set them as dummy variables
	* then count 'any'
	* see laundry script for examples
} 

log close
