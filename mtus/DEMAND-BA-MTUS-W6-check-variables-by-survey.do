* Check MTUS World 6 time-use data (UK subset) for variables available in each year

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
local dpath "`droot'"
local dfile "MTUS-adult-episode-UK-only"

local proot "`where'/Projects/RCUK-DEMAND/Theme 1"
local rpath "`proot'/results/MTUS"

* version
local version = "v1.0"

capture log close

log using "`rpath'/DEMAND-BA-MTUS-W6-check-variables-by-survey-UK-`version'-adult.smcl", replace

* make script run without waiting for user input
set more off

* start with MTUS data
* NB this is a UK only subsample with some derived variables added

use "`dpath'/processed/MTUS-adult-episode-UK-only-wf.dta", clear
* data in long/episode format

gen ba_weekday = 0
replace ba_weekday = 1 if ba_dow < 6

* set up a half-hour variable
* this is set to the half hour in which the episode starts
gen ba_hour = hh(s_starttime)
gen ba_mins = mm(s_starttime)

gen ba_hh = 0 if ba_mins < 30
replace ba_hh = 30 if ba_mins > 29
gen ba_sec = 0
* sets date to 1969!
gen s_halfhour = hms(ba_hour, ba_hh, ba_sec)
format s_halfhour %tcHH:MM
lab var s_halfhour "Half hour in which episode starts (STATA time)"

* drop bad cases
keep if badcase == 0

* sleep (surely everyone reports it?!) - use this as a checker later on
gen sleep = 0
replace sleep = 1 if main == 2 | sec == 2

* Eating
* note that this could have several sequential episodes of eating if something else changed e.g. primary <-> secondary
gen eat_m = 0
replace eat_m = 1 if main == 5 | main == 6
gen eat_s = 0
replace eat_s = 1 if sec == 5 | sec == 6
gen eat_all = 0
replace eat_all = 1 if eat_m == 1 | eat_s == 1

* NB - definitions (see documentation)
* 1975
* - Main/Sec5	Meals at work or school	
*					49  Meal break at work* - Main/Sec6	Other meals	
*					34 Eat meals, snacks 
*					35 Meal break, dinner break
*					38 Drink tea, coffee etc, at home
*					39 Drink alcohol, at home
* - Main/Sec18	Food preparation/ cooking	
*					53  Prepare meals or snacks
* - Main/Sec39	Restaurant, cafŽ, bar, pub*					75 At pub*					77 At restaurant
*					38 Drink tea, coffee etc, not at home 
*					39 Drink alcohol, not at home
* - Main/Sec48	Receive or visit friends
*					66 Entertain visitors at home 
*					71 Visit friends or relatives

* 1995

* 2000

* 2005 
* NB - some of these codes are NOT available in the version of the ONS 2005 survey which is at http://discover.ukdataservice.ac.uk/catalogue/?sn=5592
* - Main/Sec5	Meals at work or school	
*					Not possible to distinguish
* - Main/Sec6	Other meals	
*					ONS Pact=4 (eating/drinking) and lact=1 (home) or missing
* - Main/Sec18	Food preparation/ cooking*					ONS Pact=5 (preparing food)
* - Main/Sec39	Restaurant, cafŽ, bar, pub	
*					ONS Pact=4 (eating/drinking) and lact=2 (elsewhere)
* - Main/Sec48	Receive or visit friends	
*					ONS Pact=23 (spend time with friends/family at home) or 24 (going out with friends/family)

* check for location & activity combinations overall
local surveys "1974 1983 1987 1995 2000 2005"
foreach s of local surveys {
	* this highlights that 'resteraunt/pub' is used as an activity coding _instead_ of 'eating'. Grrrr
	tabout main eloc using "`rpath'/MTUS-W6-UK-adults-`s'-main-act-by-location.txt" if survey == `s', replace
	* what was done with eating and where?
	tabout main eloc using "`rpath'/MTUS-W6-UK-adults-`s'-eat_a-main-by-location.txt" if survey == `s' & eat_a == 1, replace
}
* check specifically for eating
* leave out 1995 as no secondary acts were collected
local surveys "1974 1983 1987 2000 2005"
foreach s of local surveys {
	* secondary acts by location
	tabout sec eloc using "`rpath'/MTUS-W6-UK-adults-`s'-secondary-act-by-location.txt" if survey == `s', replace
	* seocndary acts by location if main = eat
	tabout sec eloc using "`rpath'/MTUS-W6-UK-adults-`s'-eat_m-sec-by-location.txt" if survey == `s' & eat_m == 1, replace
	* main acts by location if secondary = eat
	tabout main eloc using "`rpath'/MTUS-W6-UK-adults-`s'-eat_s-main-by-location.txt" if survey == `s' & eat_s == 1, replace
}
* set up eating dummies
* 5 = meals at work or school -> not set for 2005* 6 = meals or snacks in other places
* 18 = food preparation, cooking
* 39 = restaurant, café, bar, pub -> seperate activity not a location!

* NB
* 48 = receive or visit friends



log close
