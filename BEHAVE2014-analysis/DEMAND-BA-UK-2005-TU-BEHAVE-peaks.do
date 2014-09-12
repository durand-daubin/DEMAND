* DEMAND Project (www.demand.ac.uk)
* Analyse ONS Time Use 2005 dataset
* Analysis for BEHAVE 2014 conference presentation on components of peak


* b.anderson@soton.ac.uk
* (c) University of Southampton
* Creative Commons Attribution-NonCommercial 4.0 International (CC BY-NC 4.0) license applies
* http://creativecommons.org/licenses/by-nc/4.0/

clear all

* change these to run this script on different PC
local where "/Users/ben/Documents/Work"
local droot "`where'/Data/Social Science Datatsets/Time Use 2005/UKDA-5592-stata8/stata8/"

local proot "`where'/Projects/RCUK-DEMAND/Theme 1"
local rpath "`proot'/results/ONS TU 2005"

local version = "v1.0"

set more off

capture log close

log using "`rpath'/DEMAND-BA-UK-2005-TU-BEHAVE-peaks-`version'.smcl", replace

use "`droot'/timeusefinal_for_archive.dta", clear

gen ba_hour = hh(s_faketime)
gen ba_mins = mm(s_faketime)

gen ba_hh = 0 if ba_mins < 30
replace ba_hh = 30 if ba_mins > 29
gen ba_sec = 0
* sets date to 1969!
gen s_halfhour = hms(ba_hour, ba_hh, ba_sec)
format s_halfhour %tcHH:MM
tab s_faketime ba_hour 

gen weekday = 0 
replace weekday = 1 if day != 1 & day!=7

* create tables 
* yes, stata could create these as charts but I like to import to excel & fiddle :-)

* age
tabout pact s_halfhour using "`rpath'/main-acts-by-s_halfhour-16-65-weekdays.txt" [iw=propwt] if ageh <= 10 & weekday == 1, replace
tabout pact s_halfhour using "`rpath'/main-acts-by-s_halfhour-65+-weekdays.txt" [iw=propwt] if ageh > 10 & weekday == 1, replace
* gender
tabout pact s_halfhour using "`rpath'/main-acts-by-s_halfhour-men-weekdays.txt" [iw=propwt] if respsex == 1 & weekday == 1, replace //men
tabout pact s_halfhour using "`rpath'/main-acts-by-s_halfhour-women-weekdays.txt" [iw=propwt] if respsex == 2 & weekday == 1, replace //women
* day of week
tabout pact s_halfhour using "`rpath'/main-acts-by-s_halfhour-sunday.txt" [iw=propwt] if day == 1, replace //Sunday
tabout pact s_halfhour using "`rpath'/main-acts-by-s_halfhour-monday.txt" [iw=propwt] if day == 2, replace //Monday
tabout pact s_halfhour using "`rpath'/main-acts-by-s_halfhour-friday.txt" [iw=propwt] if day == 6, replace //Friday
tabout pact s_halfhour using "`rpath'/main-acts-by-s_halfhour-saturday.txt" [iw=propwt] if day == 7, replace //Saturday


log close
