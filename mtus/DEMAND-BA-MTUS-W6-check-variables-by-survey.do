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
* 7 day / one week in three of the four waves, only 2 days (Monday & Tuesday) in the 4-10 September wave remain, other data from this wave no longer exists
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

* 1983
* 7-day
* - MAIN/SEC 5	meals at work or school	
*					0103   Scheduled break at work (meal) if time=15 minutes*					1502   Drinking non-alcoholic beverages + location in workplace or school*					0402   Lunch break at educational establishment Ð school* - MAIN/SEC 6	other meals or snacks	
*					1501   Eating at home*					1502   Drinking non-alcoholic beverages + location not at workplace, school, or restaurant
* - MAIN/SEC 18	food preparation, cooking	
*					0601   Food preparation*					0602   Bake, freeze foods, make jams, pickles, preserves, dry herbs*					0604   Make a cup of tea, coffee
* - MAIN/SEC 39	restaurant, cafŽ, bar, pub	
*					2701   At the pub*					2702   Play pub games (eg darts, billiards, video games)*					2703   Wine bar, drink at restaurant*					2801   Eat out at restaurant, cafe*					2802   Eat out, fast food*					2803   Eat out, not specified*					2804   Eat meal at pub (not snack)
* - MAIN/SEC 48	receive or visit friends	
*					2901   Eating out at a colleague's, relative's, friend's house*					2902   Visiting friends, relatives*					3801   Entertaining at home

* 1987
* 7 day
* - MAIN/SEC5	Meals at work or school	
*					402 lunch break at education establishment*				If at workplace (from location)*					1501 eat at home *					1502 drink non-alcoholic beverages* - MAIN/SEC6	Other meals or snacks	
*				If not at workplace, restaurant, bar (from location)*					1501 eat at home *					1502 drink non-alcoholic beverages
* - MAIN/SEC18	Food preparation, cook	
*					601 food preparation*					602 bake, freezing, jam/pickling, drying food*					604 make cup of tea, coffee etc*					4001 home brewing, wine making
* - MAIN/SEC39	Restaurant, cafŽ, bar, pub	
*					2701 at the pub*					2703 wine bar, at bar in restaurant *					2801 eat out at restaurant or cafŽ*					2802 eat out at fast food or takeaway*					2803 eat out not specified*					2804 eat full meal at pub (not bar snacks)*				If at restaurant or pub (from location)*					1501 eat at home *					1502 drink non-alcoholic beverages
* - MAIN/SEC48	Receive or visit friends	
*					2901 eat out at friendÕs house*					2902 visit friends or relations *					3801 entertain at home*				If with people from outside household in home or at other personÕs home*					3802 alcohol, smoke, drugs
					
* 1995 - 1 day (no secondary activities recorded nor was location)
* - MAIN5	meals at work or school	
*					Not possible to create* - MAIN6	other meals or snacks	  
*					4 Eating/home* - MAIN18	food preparation, cooking	  
*					3 Cooking
* - MAIN39	restaurant, cafŽ, bar, pub	
*					23 Eating out
* - MAIN48	receive or visit friends	
*					24 Socializing

* 2000 - 2 days (1 weekday, 1 weekend)
* - Main/Sec5	Meals at work or school	
*					210 Eating (at work or school Ð wher=4)*					1310 Lunch break* - Main/Sec6	Other meals	
*					210 Eating not coded in categories 5 or 38 (38 = Other public event, venue)* - Main/Sec18	Food preparation/ cooking	
*					3100 Unspecified food management*					3110 Food preparation*					3120 Baking*					3140 Preserving* - Main/Sec39	Restaurant, cafŽ, bar, pub	
*					(at restaurant/cafe/pub Ð wher=6)*					210 Eating*					5000 Unspecified social life and entertainment*					5100 Unspecified social life*					5110 Socialising with household members*					5120 Visiting and receiving visitors* - Main/Sec48	Receive or visit friends	
*					5100 Unspecified social life*					5120 Visiting and receiving visit*					5190 Other specified social life

* 2005 - 1 day
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
