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

gen ba_hour = hh(s_starttime)
gen ba_mins = mm(s_starttime)

gen ba_hh = 0 if ba_mins < 30
replace ba_hh = 30 if ba_mins > 29
gen ba_sec = 0
* sets date to 1969!
gen s_halfhour = hms(ba_hour, ba_hh, ba_sec)
format s_halfhour %tcHH:MM

* drop bad cases
keep if badcase == 0

* sleep (surely everyone reports it?!) - use this as a checker later on
gen sleep = 0
replace sleep = 1 if main == 2 | sec == 2

* check overall
local surveys "1974 1983 1987 1995 2000 2005"
foreach s of local surveys {
	tabout main eloc using "`rpath'/MTUS-W6-UK-adults-`s'-main-act-by-location.txt" if survey == `s', replace
}

* set up eating dummies
* 5 meals at work or school -> not set for 2005* 6 meals or snacks in other places
* 18 food preparation, cooking
* 39 restaurant, café, bar, pub -> seperate activity not a location!

* NB
* 48 receive or visit friends

* note that this could have several sequential episodes of eating if something else changed e.g. primary <-> secondary
gen eat = 0
replace eat = 1 if main == 5 | sec == 5 | main == 6 | sec == 6


log close
